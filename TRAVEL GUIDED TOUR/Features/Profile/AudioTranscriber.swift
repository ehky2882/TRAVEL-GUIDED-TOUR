import Foundation
import AVFoundation
#if canImport(Speech)
import Speech
#endif

/// Turning a tour's narration into a first draft of its transcript, on device.
///
/// Owner, 2026-08-20: *"drop the transcription window (can we auto-transcribe
/// now? if so it can spit out a window that the maker can edit on the next
/// step)"* — yes. iOS 26 shipped `SpeechAnalyzer` / `SpeechTranscriber`, which
/// is built for exactly this: **long-form recorded audio, transcribed on the
/// device**, where the older `SFSpeechRecognizer` was built for short live
/// dictation and capped around a minute. A tour's narration runs two or three.
///
/// **Nothing leaves the phone.** The model is downloaded once from Apple and
/// everything after that is local, which matters here more than it would in
/// most apps: the privacy policy's one surviving absolute claim is that
/// location never leaves the device, and narration is the maker's own voice.
/// It also means transcription costs nothing per tour and works on a plane.
///
/// ⚠️ **It needs its own permission**, `NSSpeechRecognitionUsageDescription`,
/// even though it is on-device — so a maker who records a tour now sees a
/// second prompt after the microphone one. That is a real cost and the reason
/// transcription is never started until there is audio to transcribe: asking
/// for speech recognition before anyone has spoken would be asking for
/// something we cannot yet use.
///
/// **Never blocks anything.** A transcript is optional in the wizard and stays
/// optional here: an unsupported language, a declined permission, a failed
/// download and a silent recording all end the same way — an empty box the
/// maker can type into. `failed` carries a sentence saying which, because a box
/// that is simply empty is indistinguishable from one that is broken.
@MainActor
@Observable
final class AudioTranscriber {

    /// Where a transcription has got to. The wizard renders each of these, so
    /// adding a case means teaching the step to say something about it.
    enum Phase: Equatable {
        case idle
        /// Fetching the language model. First run only, and it can be large —
        /// said out loud rather than hidden behind a spinner that looks stuck.
        case preparingModel
        case transcribing
        case done
        /// Ended without a transcript. The string is already a sentence a maker
        /// can read; see `AuthoringErrorText` for the same idea elsewhere.
        case failed(String)

        /// Whether this phase ended without a transcript. The step reads it to
        /// pick a colour, so it stays with the case rather than being
        /// re-derived at the call site.
        var isFailure: Bool {
            if case .failed = self { return true }
            return false
        }
    }

    /// The language to listen for, as a locale identifier — empty means follow
    /// the device.
    ///
    /// 🔴 THE DEVICE'S LANGUAGE IS A GUESS AT THE NARRATION'S, AND OFTEN A
    /// WRONG ONE. Tour makers are exactly the people whose phone language and
    /// speaking language differ: an English-set iPhone narrating Barcelona in
    /// Spanish is an ordinary case, not an exotic one. Running the wrong model
    /// does not fail — it returns confident nonsense, the same trap that made
    /// falling back to English unacceptable. So the language is a setting, it
    /// is stated on screen rather than assumed, and the maker can change it.
    var preferredLocaleID: String = ""

    private(set) var phase: Phase = .idle
    /// The words, as they are recognised. Written straight through so a long
    /// recording fills the box while it works rather than staying blank.
    private(set) var text: String = ""

    private var task: Task<Void, Never>?

    var isWorking: Bool {
        phase == .preparingModel || phase == .transcribing
    }

    /// Start over from a new recording. Cancels anything already running — a
    /// maker who re-records mid-transcription should not get the old take's
    /// words landing on top of the new one's.
    func transcribe(fileURL: URL) {
        task?.cancel()
        text = ""
        phase = .preparingModel
        task = Task { await run(fileURL: fileURL) }
    }

    func cancel() {
        task?.cancel()
        task = nil
        if isWorking { phase = .idle }
    }

    // MARK: - The work

    private func run(fileURL: URL) async {
        #if canImport(Speech)
        do {
            guard let locale = await usableLocale() else {
                phase = .failed("No transcription for this language. Pick another below, or type it yourself.")
                return
            }

            let transcriber = SpeechTranscriber(
                locale: locale,
                transcriptionOptions: [],
                // No volatile results: we want the settled text, not the
                // guesses it passes through on the way. A box that rewrites
                // itself as you watch reads as broken.
                reportingOptions: [],
                attributeOptions: []
            )

            // First run on a given language pulls the model down. Later runs
            // find it installed and fall straight through.
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await request.downloadAndInstall()
            }
            try Task.checkCancellation()

            phase = .transcribing
            let analyzer = SpeechAnalyzer(modules: [transcriber])

            // Collect while the analyzer runs, rather than after — the results
            // are an AsyncSequence and reading them is what drains it.
            let collector = Task { @MainActor in
                for try await result in transcriber.results where result.isFinal {
                    self.text += String(result.text.characters)
                }
            }

            let file = try AVAudioFile(forReading: fileURL)
            if let last = try await analyzer.analyzeSequence(from: file) {
                try await analyzer.finalizeAndFinish(through: last)
            } else {
                await analyzer.cancelAndFinishNow()
            }
            _ = try? await collector.value

            try Task.checkCancellation()
            text = Self.tidied(text)
            phase = text.isEmpty
                ? .failed("Nothing recognised. Check the language below, or type it yourself.")
                : .done
        } catch is CancellationError {
            phase = .idle
        } catch {
            phase = .failed("The transcript couldn't be made automatically. Type it yourself, or leave it blank.")
        }
        #else
        phase = .failed("Automatic transcription isn't available on this device.")
        #endif
    }

    #if canImport(Speech)
    /// The device's own language if the transcriber supports it, else nil.
    ///
    /// ⚠️ Deliberately does NOT fall back to English. The catalogue is written
    /// in Japanese, Arabic, Thai and Vietnamese among others, and running an
    /// English model over Japanese narration doesn't fail — it returns
    /// confident nonsense, which is worse than an empty box, because a maker
    /// might submit it.
    private func usableLocale() async -> Locale? {
        if !preferredLocaleID.isEmpty {
            // An explicit choice is honoured as given. It came from the list of
            // supported languages, so it needs no equivalence search.
            return Locale(identifier: preferredLocaleID)
        }
        return await SpeechTranscriber.supportedLocale(equivalentTo: Locale.current)
    }

    /// Every language the recogniser can handle, in the reader's own language,
    /// alphabetically. Read once and cached by the caller — it is a fixed list
    /// for a given OS, not something that changes while a maker is typing.
    static func supportedLocales() async -> [Locale] {
        await SpeechTranscriber.supportedLocales
            .sorted { displayName(of: $0) < displayName(of: $1) }
    }
    #else
    static func supportedLocales() async -> [Locale] { [] }
    #endif

    /// A language's name as a person reads it — "Spanish (Spain)", not
    /// "es_ES". Localised into the reader's own language.
    nonisolated static func displayName(of locale: Locale) -> String {
        Locale.current.localizedString(forIdentifier: locale.identifier)
            ?? locale.identifier
    }

    /// Just the language, without the region — "Spanish", not "Spanish
    /// (Spain)".
    ///
    /// ⚠️ What the button says, where the full name is what the menu says. Half
    /// a row is about fifteen characters at 13pt SF Mono, and "Cantonese
    /// (China)" is seventeen — it would truncate. Dropping the region is the
    /// right thing to lose: a region mismatch (en_GB against en_US) does not
    /// produce nonsense, and it is nonsense the name on screen exists to catch.
    nonisolated static func shortDisplayName(of locale: Locale) -> String {
        guard let code = locale.language.languageCode?.identifier,
              let name = Locale.current.localizedString(forLanguageCode: code)
        else { return displayName(of: locale) }
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    /// Collapse the runs of whitespace the recogniser leaves between segments.
    ///
    /// `nonisolated` so it can be tested without a main actor — it is pure
    /// string work and touches nothing on the instance.
    nonisolated static func tidied(_ raw: String) -> String {
        raw.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " *\n *", with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

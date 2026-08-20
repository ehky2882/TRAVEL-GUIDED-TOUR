import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

/// Narration for one tour — record it, import it, watch it upload, play back
/// what's attached.
///
/// 🔴 **ONE SKELETON, IN EVERY STATE.** Owner, 2026-08-20: *"all steps should
/// look like a version of 'reviewing a take'. it should not differ so much
/// which step you're on."* Before this the step was four unrelated screens:
/// two stacked buttons before you had anything, a timer-and-meter panel while
/// recording, that panel plus two more buttons afterwards, and a playback card
/// once audio was attached. Nothing kept its place, so every action
/// reorganised the screen under the maker's thumb.
///
/// Now the status line, the clock, the meter, the record button and Import are
/// **always drawn, always in the same place**. Only one row in the middle
/// changes, and its height is reserved whether or not it has anything in it —
/// the same discipline as the wizard's footer hint and the transcript's note.
/// A control that cannot be used is dimmed rather than removed, because a
/// disappearing control is what moves everything else.
///
/// One step of `CreateTourWizardView`, which is the only place a tour is made
/// or edited. It lives in its own file because the step owns a good deal of
/// state — an upload in flight, a failure holding on to its data, a recorder,
/// two players — and burying that in the wizard would make the wizard the
/// thing nobody wants to touch.
struct TourAudioSection: View {
    let tour: Tour

    /// Reports the upload as it happens, so a host that needs to gate on it
    /// can. The wizard uses this to keep Submit dimmed while narration is
    /// still in flight — you can walk on to Review mid-upload, you just
    /// can't submit a tour whose audio hasn't landed.
    var onUploadStateChange: ((AudioUploadState) -> Void)? = nil

    /// The file the maker just recorded or picked, while it is still on this
    /// device. The wizard transcribes from it.
    ///
    /// ⚠️ Reported when the audio is *in hand*, not when the upload finishes.
    /// Transcription is local and has nothing to wait for, and a maker on a
    /// slow connection would otherwise watch the transcript step stay empty
    /// for as long as the upload takes.
    var onAudioReady: ((URL) -> Void)? = nil

    @Environment(MakerTourService.self) private var makerTourService

    @State private var importingAudio = false
    @State private var recorder = AudioRecorder()
    @State private var takeReview = RecordingReviewPlayer()
    /// A take that has been made but not yet kept. Distinct from
    /// `attachedAudioURL`, which is what the tour already has.
    @State private var recordedURL: URL?
    @State private var permissionDenied = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var uploadTotalBytes: Int64 = 0
    /// A recording that was paid for in effort but didn't reach the server. Kept
    /// so "try again" is possible — a maker may not be able to record it twice.
    @State private var failedUpload: FailedAudioUpload?
    @State private var attachedAudioURL: URL?
    @State private var audioPreview = AuthoringAudioPreview()
    @State private var errorMessage: String?

    private var hasAudio: Bool { tour.totalDurationSeconds > 0 }

    /// Every button on this step, and the ✕ in the header, are this tall.
    ///
    /// Owner, 2026-08-20: *"whatever is the height of the 'x' button at the top
    /// should be the height of all buttons, including the record button."* Read
    /// from `AtlasChromeButton` rather than repeated, so there is one number.
    private var buttonHeight: CGFloat { AtlasChromeButton.diameter }

    var body: some View {
        VStack(spacing: AtlasSpacing.md) {
            statusRow
            clock
            AudioLevelMeter(levels: recorder.levels, isLive: recorder.isRecording)
            RecordButton(isRecording: recorder.isRecording, action: toggleRecording)
                .disabled(isUploading)
                .opacity(isUploading ? 0.4 : 1)
            actionPair
            importButton
            statusNote
        }
        .frame(maxWidth: .infinity)
        .fileImporter(
            isPresented: $importingAudio,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .task(id: tour.id) {
            attachedAudioURL = await makerTourService.stopAudioURL(tourId: tour.id)
        }
        .onDisappear {
            _ = recorder.stop()
            takeReview.stop()
            audioPreview.stop()
        }
    }

    // MARK: - The fixed parts

    /// What the step is doing, and the way out of a take.
    ///
    /// Discard sits here rather than in the pair below so that abandoning a
    /// take never competes for the same place as keeping it.
    private var statusRow: some View {
        HStack {
            Text(statusLabel)
                .font(AtlasTypography.caption)
                .foregroundStyle(recorder.isRecording ? AtlasColors.mapPin : AtlasColors.secondaryText)
            Spacer()
            Button("Discard") { discardTake() }
                .font(AtlasTypography.caption)
                .tint(AtlasColors.secondaryText)
                .disabled(!canDiscard)
                .opacity(canDiscard ? 1 : 0.35)
                .frame(height: buttonHeight)
        }
        .frame(height: buttonHeight)
    }

    private var canDiscard: Bool { recordedURL != nil || recorder.isRecording }

    private var statusLabel: String {
        if recorder.isRecording { return "RECORDING" }
        if recordedURL != nil    { return "YOUR TAKE" }
        if hasAudio              { return "NARRATION" }
        return "RECORD"
    }

    /// Always a clock, never blank — 00:00 before there is anything, counting
    /// while recording, the take's length after, the tour's duration once
    /// attached.
    private var clock: some View {
        Text(timeString(clockSeconds))
            .font(.system(size: 34, weight: .light, design: .monospaced))
            .foregroundStyle(AtlasColors.primaryText)
            .contentTransition(.numericText())
    }

    private var clockSeconds: TimeInterval {
        if recorder.isRecording { return recorder.elapsed }
        if recordedURL != nil    { return recorder.lastDuration }
        if hasAudio              { return TimeInterval(tour.totalDurationSeconds) }
        return 0
    }

    // MARK: - The pair

    /// 🔴 **TWO BUTTONS, ALWAYS, IN THE SAME PLACE.** Owner, 2026-08-20:
    /// *"should be more like the 'reviewing a take' screen and 'upload failed'
    /// screen. disable the buttons that are not relevant at that step."*
    ///
    /// The previous attempt reserved this row's *height* and left it empty when
    /// there was nothing to put in it, which still read as a different screen —
    /// a gap is as visible as a control. A disabled button says *this becomes
    /// available*; a blank space says nothing at all.
    ///
    /// The failed-upload state is the one that changes both labels, because
    /// after a failure the two things worth doing genuinely are try again and
    /// throw it away.
    @ViewBuilder
    private var actionPair: some View {
        if let failed = failedUpload {
            HStack(spacing: AtlasSpacing.sm) {
                AtlasPillButton(title: "Try again", systemImage: "arrow.clockwise",
                                filled: true) { retryUpload(failed) }
                AtlasPillButton(title: "Discard") { discardFailure() }
            }
        } else {
            HStack(spacing: AtlasSpacing.sm) {
                AtlasPillButton(title: isPlaying ? "Playing…" : "Play",
                                systemImage: isPlaying ? "pause.fill" : "play.fill",
                                enabled: playableURL != nil && !recorder.isRecording && !isUploading) {
                    togglePlayback()
                }
                AtlasPillButton(title: "Use recording", filled: true,
                                enabled: recordedURL != nil && !recorder.isRecording && !isUploading) {
                    guard let take = recordedURL else { return }
                    takeReview.stop()
                    uploadAudio(from: take)
                    recordedURL = nil
                }
            }
        }
    }

    /// A fresh take if there is one, otherwise whatever the tour already has.
    private var playableURL: URL? { recordedURL ?? attachedAudioURL }
    private var isPlaying: Bool { takeReview.isPlaying || audioPreview.isPlaying }

    /// A take plays through the review player, attached narration through the
    /// preview — two players because they hold different files, not because
    /// the button is two buttons.
    private func togglePlayback() {
        guard let url = playableURL else { return }
        if url == recordedURL {
            audioPreview.stop()
            takeReview.toggle(url: url)
        } else {
            takeReview.stop()
            audioPreview.toggle(url: url)
        }
    }

    /// Always present, because a maker whose narration is already on their
    /// computer shouldn't have to discover the option exists — and for a tour
    /// written in advance, importing is the primary action, not a lesser one.
    private var importButton: some View {
        AtlasPillButton(title: hasAudio ? "Replace with a file" : "Import audio file",
                        systemImage: "square.and.arrow.down",
                        enabled: !recorder.isRecording && !isUploading) {
            importingAudio = true
        }
    }

    /// One reserved place for everything the step has to say: upload progress,
    /// a failure, a refused microphone. Fixed height, so nothing above it moves
    /// when it starts or stops speaking.
    private var statusNote: some View {
        VStack(spacing: 6) {
            Text(noteText ?? " ")
                .font(AtlasTypography.caption)
                .foregroundStyle(noteIsProblem ? AtlasColors.mapPin : AtlasColors.tertiaryText)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
            ProgressView(value: isUploading ? uploadProgress : 0)
                .tint(AtlasColors.mapPin)
                .opacity(isUploading ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var noteIsProblem: Bool {
        permissionDenied || failedUpload != nil || errorMessage != nil
    }

    private var noteText: String? {
        if permissionDenied {
            return "Microphone access is off. Turn it on in Settings to record."
        }
        if let errorMessage { return errorMessage }
        if let failed = failedUpload { return failed.reason }
        if isUploading {
            let pct = Int(uploadProgress * 100)
            guard uploadTotalBytes > 0 else { return "Uploading narration — \(pct)%" }
            let sent = AtlasFormatters.fileSize(Int64(Double(uploadTotalBytes) * uploadProgress))
            let total = AtlasFormatters.fileSize(uploadTotalBytes)
            return "Uploading narration — \(pct)% · \(sent) of \(total)"
        }
        return nil
    }

    // MARK: - Recording

    private func toggleRecording() {
        if recorder.isRecording {
            recordedURL = recorder.stop()
        } else {
            takeReview.stop()
            audioPreview.stop()
            Task {
                let ok = await recorder.start()
                permissionDenied = !ok
                if ok { recordedURL = nil }
            }
        }
    }

    /// Throw the take away and go back to whatever the tour already had.
    private func discardTake() {
        _ = recorder.stop()
        takeReview.stop()
        recordedURL = nil
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: - Upload

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = AuthoringErrorText.message(for: error)
        case .success(let urls):
            guard let url = urls.first else { return }
            uploadAudio(from: url)
        }
    }

    private func uploadAudio(from url: URL) {
        errorMessage = nil
        failedUpload = nil
        onAudioReady?(url)
        isUploading = true
        uploadProgress = 0
        onUploadStateChange?(.uploading(0))
        Task {
            defer { isUploading = false }
            do {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }

                let data = try Data(contentsOf: url)
                let asset = AVURLAsset(url: url)
                let duration = try await asset.load(.duration)
                let seconds = max(1, Int(duration.seconds.rounded()))
                let filename = "audio.\(url.pathExtension.isEmpty ? "m4a" : url.pathExtension)"
                let contentType = UTType(filenameExtension: url.pathExtension)?
                    .preferredMIMEType ?? "audio/mpeg"

                uploadTotalBytes = Int64(data.count)
                try await send(data: data, filename: filename, contentType: contentType,
                               seconds: seconds)
            } catch {
                // Hold on to what we decoded so Try again doesn't need the file
                // back — an imported file's security-scoped URL may be gone by
                // then, and a recording may not be repeatable at all.
                failedUpload = FailedAudioUpload(
                    sourceURL: url,
                    reason: AuthoringErrorText.message(for: error)
                )
                onUploadStateChange?(.failed)
            }
        }
    }

    private func retryUpload(_ failed: FailedAudioUpload) {
        failedUpload = nil
        uploadAudio(from: failed.sourceURL)
    }

    /// Discarding a failed upload puts the host back to a settled state — it
    /// should stop reporting a failure nobody is going to retry.
    private func discardFailure() {
        failedUpload = nil
        onUploadStateChange?(.idle)
    }

    /// The upload itself, split out so `uploadAudio` and `retryUpload` share one
    /// path rather than drifting.
    private func send(data: Data, filename: String, contentType: String,
                      seconds: Int) async throws {
        try await makerTourService.attachAudio(
            to: tour,
            data: data,
            filename: filename,
            contentType: contentType,
            durationSeconds: seconds,
            onProgress: { fraction in
                Task { @MainActor in
                    uploadProgress = fraction
                    onUploadStateChange?(.uploading(fraction))
                }
            }
        )
        attachedAudioURL = await makerTourService.stopAudioURL(tourId: tour.id)
        onUploadStateChange?(.idle)
    }
}

/// Where an audio upload has got to, for a host that needs to gate on it.
enum AudioUploadState: Equatable {
    case idle
    case uploading(Double)
    case failed
}

/// An audio upload that failed after the file was already in hand.
struct FailedAudioUpload: Equatable {
    let sourceURL: URL
    /// Already human-readable — see `AuthoringErrorText`.
    let reason: String
}

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

    var body: some View {
        VStack(spacing: AtlasSpacing.md) {
            statusRow
            clock
            AudioLevelMeter(levels: recorder.levels, isLive: recorder.isRecording)
            RecordButton(isRecording: recorder.isRecording, action: toggleRecording)
                .disabled(isUploading)
                .opacity(isUploading ? 0.4 : 1)

            // The one row that changes, at a height that doesn't.
            middleRow
                .frame(minHeight: 49)

            importButton

            if permissionDenied {
                Text("Microphone access is off. Enable it in Settings to record.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
                    .multilineTextAlignment(.center)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
                    .multilineTextAlignment(.center)
            }
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
    /// Discard sits here rather than in the middle row so that abandoning a
    /// take never competes for the same place as keeping it.
    private var statusRow: some View {
        HStack {
            Text(statusLabel)
                .font(AtlasTypography.caption)
                .foregroundStyle(recorder.isRecording ? AtlasColors.mapPin : AtlasColors.secondaryText)
            Spacer()
            if recordedURL != nil || recorder.isRecording {
                Button("Discard") { discardTake() }
                    .font(AtlasTypography.caption)
                    .tint(AtlasColors.secondaryText)
            }
        }
        .frame(minHeight: 17)
    }

    private var statusLabel: String {
        if recorder.isRecording { return "RECORDING" }
        if recordedURL != nil    { return "YOUR TAKE" }
        if hasAudio              { return "NARRATION" }
        return "RECORD"
    }

    /// Always a clock, never blank — it reads 00:00 before there is anything,
    /// counts while recording, and holds the length afterwards.
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

    /// Always present, because a maker who has narration on their computer
    /// shouldn't have to discover that the option exists. Dimmed rather than
    /// hidden while it can't be used — hiding it is what moves the layout.
    private var importButton: some View {
        Button { importingAudio = true } label: {
            HStack {
                Spacer()
                Label(hasAudio ? "Replace with a file" : "Import audio file",
                      systemImage: "square.and.arrow.down")
                    .font(AtlasTypography.caption)
                Spacer()
            }
            .padding(.vertical, AtlasSpacing.md)
            .foregroundStyle(AtlasColors.primaryText)
            .overlay {
                RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                    .stroke(AtlasColors.secondaryText.opacity(0.4), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(recorder.isRecording || isUploading)
        .opacity(recorder.isRecording || isUploading ? 0.4 : 1)
    }

    // MARK: - The one row that changes

    /// Reserved height, five contents. In order of what most needs saying.
    @ViewBuilder
    private var middleRow: some View {
        if isUploading {
            uploadProgressCard
        } else if let failed = failedUpload {
            failedUploadCard(failed)
        } else if let take = recordedURL, !recorder.isRecording {
            HStack(spacing: AtlasSpacing.sm) {
                pillButton(takeReview.isPlaying ? "Playing…" : "Play",
                           systemImage: takeReview.isPlaying ? "pause.fill" : "play.fill",
                           filled: false) {
                    takeReview.toggle(url: take)
                }
                pillButton("Use recording", systemImage: nil, filled: true) {
                    takeReview.stop()
                    uploadAudio(from: take)
                    recordedURL = nil
                }
            }
        } else if hasAudio, !recorder.isRecording {
            // Nothing to keep or throw away — just the tour's own narration,
            // playable where the take's Play button would be.
            pillButton(audioPreview.isPlaying ? "Playing…" : "Play narration",
                       systemImage: audioPreview.isPlaying ? "pause.fill" : "play.fill",
                       filled: false) {
                if let url = attachedAudioURL { audioPreview.toggle(url: url) }
            }
            .disabled(attachedAudioURL == nil)
        }
        // Recording, or nothing recorded yet: the row is empty and keeps its
        // height, so the record button and Import never move.
    }

    private func pillButton(_ title: String, systemImage: String?,
                            filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(AtlasTypography.caption)
            .foregroundStyle(filled ? AtlasColors.background : AtlasColors.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AtlasSpacing.md)
            .background {
                if filled {
                    Capsule().fill(AtlasColors.mapPin)
                } else {
                    Capsule().stroke(AtlasColors.tertiaryText.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
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

    // MARK: - Upload and failure, in the middle row

    /// Real byte progress, not a spinner. Narration is the largest thing this
    /// app uploads, and an indeterminate spinner can't distinguish "nearly
    /// there" from "stalled".
    private var uploadProgressCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Narration")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
                Spacer()
                Text("\(Int(uploadProgress * 100))%")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .monospacedDigit()
            }
            ProgressView(value: uploadProgress)
                .tint(AtlasColors.mapPin)
            if uploadTotalBytes > 0 {
                Text("\(AtlasFormatters.fileSize(Int64(Double(uploadTotalBytes) * uploadProgress))) of \(AtlasFormatters.fileSize(uploadTotalBytes))")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        }
        .padding(AtlasSpacing.md)
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }

    /// A failed upload keeps the file and offers to try again, rather than
    /// dropping a recording the maker may not be able to make twice.
    private func failedUploadCard(_ failed: FailedAudioUpload) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Narration didn't upload")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.mapPin)
            Text(failed.reason)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
            HStack(spacing: AtlasSpacing.sm) {
                Button { retryUpload(failed) } label: {
                    Text("Try again")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.background)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(AtlasColors.mapPin, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button { discardFailure() } label: {
                    Text("Discard")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(AtlasColors.tertiaryText, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AtlasSpacing.md)
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
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

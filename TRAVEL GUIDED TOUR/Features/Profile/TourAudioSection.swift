import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

/// Narration for one tour — record it, import it, watch it upload, play back
/// what's attached.
///
/// One step of `CreateTourWizardView`, which is the only place a tour is made
/// or edited. It lives in its own file because the step owns a good deal of
/// state — an upload in flight, a failure holding on to its data, a preview
/// player — and burying that in the wizard would make the wizard the thing
/// nobody wants to touch.
struct TourAudioSection: View {
    let tour: Tour

    /// Reports the upload as it happens, so a host that needs to gate on it
    /// can. The wizard uses this to keep Submit dimmed while narration is
    /// still in flight — you can walk on to Review mid-upload, you just
    /// can't submit a tour whose audio hasn't landed.
    var onUploadStateChange: ((AudioUploadState) -> Void)? = nil

    @Environment(MakerTourService.self) private var makerTourService

    @State private var importingAudio = false
    @State private var showingRecorder = false
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
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            if hasAudio {
                attachedRow
            }

            if isUploading {
                uploadProgressCard
            } else if let failed = failedUpload {
                failedUploadCard(failed)
            } else {
                Button { showingRecorder = true } label: {
                    actionButton(hasAudio ? "Re-record audio" : "Record audio",
                                 systemImage: "mic.fill", primary: true)
                }
                .buttonStyle(.plain)

                Button { importingAudio = true } label: {
                    actionButton(hasAudio ? "Replace with a file" : "Import a file",
                                 systemImage: "square.and.arrow.down", primary: false)
                }
                .buttonStyle(.plain)

                Text("Record narration here, or import an audio file (m4a, mp3, wav).")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
            }
        }
        .fileImporter(
            isPresented: $importingAudio,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .sheet(isPresented: $showingRecorder) {
            AudioRecordSheet { url in uploadAudio(from: url) }
        }
        .task(id: tour.id) {
            attachedAudioURL = await makerTourService.stopAudioURL(tourId: tour.id)
        }
        .onDisappear { audioPreview.stop() }
    }

    // MARK: - Pieces

    /// Hear what's attached without re-recording it. Before this the editor
    /// could only tell you audio existed, never play it.
    private var attachedRow: some View {
        HStack(spacing: AtlasSpacing.md) {
            Button {
                if let url = attachedAudioURL { audioPreview.toggle(url: url) }
            } label: {
                Image(systemName: audioPreview.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AtlasColors.background)
                    .frame(width: 36, height: 36)
                    .background(AtlasColors.mapPin, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(attachedAudioURL == nil)
            .accessibilityLabel(audioPreview.isPlaying ? "Pause preview" : "Play the attached audio")

            Text(audioPreview.isPlaying
                 ? AtlasFormatters.duration(seconds: Int(audioPreview.elapsed))
                 : AtlasFormatters.duration(seconds: tour.totalDurationSeconds))
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .monospacedDigit()

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AtlasColors.mapPin)
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.vertical, 12)
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }

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

    /// A filled primary (record) or a bordered secondary (import).
    private func actionButton(_ title: String, systemImage: String, primary: Bool) -> some View {
        HStack {
            Spacer()
            Label(title, systemImage: systemImage)
                .font(AtlasTypography.caption)
            Spacer()
        }
        .padding(.vertical, AtlasSpacing.md)
        .foregroundStyle(primary ? AtlasColors.background : AtlasColors.primaryText)
        .background(primary ? AtlasColors.mapPin : Color.clear)
        .overlay {
            if !primary {
                RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                    .stroke(AtlasColors.secondaryText.opacity(0.4), lineWidth: 1)
            }
        }
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

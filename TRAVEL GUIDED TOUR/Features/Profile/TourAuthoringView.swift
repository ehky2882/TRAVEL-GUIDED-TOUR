import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

/// The authoring editor for one of the maker's own tours (V2 Step 4, increment
/// 2c). Reached by tapping an owned tour on the profile feed. This increment
/// adds the **audio** step (import + upload to Storage); photos, transcript, and
/// submit-for-review land in the following increments (shown here as disabled
/// "coming next" rows so the full flow is visible).
struct TourAuthoringView: View {
    let tourId: UUID

    @Environment(MakerTourService.self) private var makerTourService
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(\.dismiss) private var dismiss

    @State private var importingAudio = false
    @State private var showingRecorder = false
    @State private var isUploading = false
    @State private var transcriptText = ""
    @State private var isSavingTranscript = false
    @State private var isSubmitting = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showingDetailsEditor = false
    @State private var showingPhotoManager = false
    @State private var uploadProgress: Double = 0
    @State private var uploadTotalBytes: Int64 = 0
    /// A recording that was paid for in effort but didn't reach the server. Kept
    /// so "try again" is possible — a maker may not be able to record it twice.
    @State private var failedUpload: FailedAudioUpload?
    @State private var attachedAudioURL: URL?
    @State private var audioPreview = AuthoringAudioPreview()
    @State private var errorMessage: String?

    /// Live lookup so the view refreshes after an upload reloads `myTours`.
    private var makerTour: MakerTour? {
        makerTourService.myTours.first { $0.id == tourId }
    }
    private var hasAudio: Bool { (makerTour?.tour.totalDurationSeconds ?? 0) > 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                if let makerTour {
                    header(makerTour)
                    detailsSection(makerTour)
                    audioSection
                    photosSection(makerTour.tour)
                    transcriptSection
                    submitSection(makerTour)
                    deleteSection(makerTour.tour)
                } else {
                    Text("This tour is no longer available.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }
            .padding(AtlasSpacing.lg)
        }
        .background(AtlasColors.secondaryBackground)
        .navigationTitle("")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("EDIT TOUR")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        .onAppear { navState.push() }
        .onDisappear { navState.pop(); audioPreview.stop() }
        .fileImporter(
            isPresented: $importingAudio,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .sheet(isPresented: $showingRecorder) {
            AudioRecordSheet { url in
                if let tour = makerTour?.tour { uploadAudio(from: url, tour: tour) }
            }
        }
        .sheet(isPresented: $showingDetailsEditor) {
            if let makerTour {
                TourDetailsEditorView(tour: makerTour.tour, status: makerTour.status)
            }
        }
        .sheet(isPresented: $showingPhotoManager) {
            if let makerTour {
                PhotoManagerView(tour: makerTour.tour)
            }
        }
        .task(id: tourId) {
            transcriptText = await makerTourService.stopTranscript(tourId: tourId)
            attachedAudioURL = await makerTourService.stopAudioURL(tourId: tourId)
        }
        .confirmationDialog(
            "Delete this tour?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete tour", role: .destructive) {
                if let tour = makerTour?.tour { delete(tour) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func deleteSection(_ tour: Tour) -> some View {
        Button(role: .destructive) {
            showingDeleteConfirm = true
        } label: {
            HStack {
                Spacer()
                if isDeleting {
                    ProgressView()
                } else {
                    Label("Delete tour", systemImage: "trash")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.accent)
                }
                Spacer()
            }
            .padding(.vertical, AtlasSpacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                    .stroke(AtlasColors.accent.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDeleting)
        .padding(.top, AtlasSpacing.md)
    }

    private func delete(_ tour: Tour) {
        errorMessage = nil
        isDeleting = true
        Task {
            defer { isDeleting = false }
            do {
                try await makerTourService.deleteTour(tour)
                dismiss()
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    /// The tour's metadata, as tappable rows that open the details editor.
    ///
    /// Before this existed, everything shown here was set once on the create
    /// form and then frozen — a typo in a title could only be fixed by deleting
    /// the tour, taking its audio and photos with it.
    private func detailsSection(_ makerTour: MakerTour) -> some View {
        let tour = makerTour.tour
        let tagSummary = tour.tags.isEmpty ? "None" : tour.tags.joined(separator: " · ")
        return VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HStack {
                Text("DETAILS")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                Spacer()
                Text("Edit")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
            }

            Button { showingDetailsEditor = true } label: {
                VStack(spacing: 0) {
                    detailRow("TITLE", tour.title, isLast: false)
                    detailRow("SHORT DESCRIPTION",
                              tour.shortDescription.isEmpty ? "Not set" : tour.shortDescription,
                              isLast: false)
                    detailRow("TAGS", tagSummary, isLast: false, mono: true)
                    detailRow("LOCATION",
                              String(format: "%.4f, %.4f", tour.centroidLatitude, tour.centroidLongitude),
                              isLast: true, mono: true)
                }
                .background(AtlasColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit tour details")
            .accessibilityHint("Opens the editor for title, description, tags and location")
        }
    }

    private func detailRow(_ key: String, _ value: String, isLast: Bool, mono: Bool = false) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(key)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(AtlasColors.tertiaryText)
                Text(value)
                    .font(mono ? AtlasTypography.caption : AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(AtlasColors.divider)
                    .frame(height: 0.5)
                    .padding(.leading, AtlasSpacing.md)
            }
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("TRANSCRIPT")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            TextField("The words spoken in the audio", text: $transcriptText, axis: .vertical)
                .lineLimit(4...12)
                .font(AtlasTypography.caption)
                .padding(AtlasSpacing.md)
                .background(AtlasColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))

            Button { saveTranscript() } label: {
                audioButton(isSavingTranscript ? "Saving…" : "Save transcript",
                            systemImage: "checkmark", primary: false)
            }
            .disabled(isSavingTranscript)
        }
    }

    private func submitSection(_ makerTour: MakerTour) -> some View {
        let hasAudio = makerTour.tour.totalDurationSeconds > 0
        let hasHero = !makerTour.tour.heroImageURL.isEmpty
        let isDraft = makerTour.status == .draft
        let canSubmit = hasAudio && hasHero && isDraft && !isSubmitting
        return VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("SUBMIT")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            if isDraft {
                Button { submit(makerTour.tour) } label: {
                    audioButton(isSubmitting ? "Submitting…" : "Submit for review",
                                systemImage: "paperplane.fill", primary: true)
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)

                if !(hasAudio && hasHero) {
                    Text("Add audio and at least one photo before submitting.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
            } else {
                HStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundStyle(AtlasColors.mapPin)
                    Text("Submitted — \(makerTour.status.label). We'll review it and publish it.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
            }
        }
    }

    private func photosSection(_ tour: Tour) -> some View {
        let all = ([tour.heroImageURL] + (tour.additionalImageURLs ?? []))
            .filter { !$0.isEmpty }
        return VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("PHOTOS")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            if !all.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.sm) {
                        ForEach(Array(all.enumerated()), id: \.offset) { idx, url in
                            HeroImageView(imageName: url, height: 84,
                                          cornerRadius: 0, category: tour.primaryCategory)
                                .frame(width: 112)
                                .overlay(alignment: .bottomLeading) {
                                    if idx == 0 {
                                        Text("COVER")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundStyle(AtlasColors.background)
                                            .padding(.horizontal, 5).padding(.vertical, 2)
                                            .background(AtlasColors.mapPin)
                                            .padding(AtlasSpacing.xs)
                                    }
                                }
                        }
                    }
                }
            }

            Button { showingPhotoManager = true } label: {
                audioButton(all.isEmpty ? "Add photos" : "Manage photos",
                            systemImage: all.isEmpty ? "photo.badge.plus" : "square.grid.2x2",
                            primary: all.isEmpty)
            }
            .buttonStyle(.plain)

            Text(all.isEmpty
                 ? "Photos are framed to 1200×900. The first is the cover."
                 : "\(all.count) of \(PhotoManagerView.maxPhotos) · drag to reorder, the first is the cover.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
    }

    /// Styled audio-action button — a filled primary (record) or a bordered
    /// secondary (import).
    private func audioButton(_ title: String, systemImage: String, primary: Bool) -> some View {
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

    // MARK: - Sections

    private func header(_ makerTour: MakerTour) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text(makerTour.tour.title)
                .font(AtlasTypography.body)
                .textCase(.uppercase)
                .foregroundStyle(AtlasColors.primaryText)
            Text(makerTour.status.label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AtlasColors.background)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(makerTour.status.badgeColor)
                .clipShape(Capsule())
        }
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("AUDIO")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            if hasAudio, let seconds = makerTour?.tour.totalDurationSeconds {
                // Hear what's attached without re-recording it. Before this the
                // editor could only tell you audio existed, never play it.
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
                         : AtlasFormatters.duration(seconds: seconds))
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

            if isUploading {
                uploadProgressCard
            } else if let failed = failedUpload {
                failedUploadCard(failed)
            } else {
                Button { showingRecorder = true } label: {
                    audioButton(hasAudio ? "Re-record audio" : "Record audio",
                                systemImage: "mic.fill", primary: true)
                }
                .buttonStyle(.plain)

                Button { importingAudio = true } label: {
                    audioButton(hasAudio ? "Replace with a file" : "Import a file",
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

                Button { failedUpload = nil } label: {
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


    private func saveTranscript() {
        errorMessage = nil
        isSavingTranscript = true
        Task {
            defer { isSavingTranscript = false }
            do {
                try await makerTourService.setTranscript(tourId: tourId, text: transcriptText)
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    private func submit(_ tour: Tour) {
        errorMessage = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await makerTourService.submitForReview(tour: tour, transcript: transcriptText)
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    // MARK: - Import

    // MARK: - Audio import

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = AuthoringErrorText.message(for: error)
        case .success(let urls):
            guard let url = urls.first, let tour = makerTour?.tour else { return }
            uploadAudio(from: url, tour: tour)
        }
    }

    private func uploadAudio(from url: URL, tour: Tour) {
        errorMessage = nil
        failedUpload = nil
        isUploading = true
        uploadProgress = 0
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
                               seconds: seconds, tour: tour)
            } catch {
                // Hold on to what we decoded so Try again doesn't need the file
                // back — an imported file's security-scoped URL may be gone by
                // then, and a recording may not be repeatable at all.
                failedUpload = FailedAudioUpload(
                    sourceURL: url,
                    reason: AuthoringErrorText.message(for: error)
                )
            }
        }
    }

    /// Retry a failed upload from the original source.
    private func retryUpload(_ failed: FailedAudioUpload) {
        guard let tour = makerTour?.tour else { return }
        failedUpload = nil
        uploadAudio(from: failed.sourceURL, tour: tour)
    }

    /// The upload itself, split out so `uploadAudio` and `retryUpload` share one
    /// path rather than drifting.
    private func send(data: Data, filename: String, contentType: String,
                      seconds: Int, tour: Tour) async throws {
        try await makerTourService.attachAudio(
            to: tour,
            data: data,
            filename: filename,
            contentType: contentType,
            durationSeconds: seconds,
            onProgress: { fraction in
                Task { @MainActor in uploadProgress = fraction }
            }
        )
        attachedAudioURL = await makerTourService.stopAudioURL(tourId: tour.id)
    }

}

/// An audio upload that failed after the file was already in hand.
struct FailedAudioUpload: Equatable {
    let sourceURL: URL
    /// Already human-readable — see `AuthoringErrorText`.
    let reason: String
}

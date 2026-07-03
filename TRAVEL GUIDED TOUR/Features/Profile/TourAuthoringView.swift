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

    @State private var importingAudio = false
    @State private var showingRecorder = false
    @State private var isUploading = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var isUploadingPhotos = false
    @State private var transcriptText = ""
    @State private var isSavingTranscript = false
    @State private var isSubmitting = false
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
                    audioSection
                    photosSection(makerTour.tour)
                    transcriptSection
                    submitSection(makerTour)
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
        .onDisappear { navState.pop() }
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
        .onChange(of: photoItems) { _, items in
            handlePhotoSelection(items)
        }
        .task(id: tourId) {
            transcriptText = await makerTourService.stopTranscript(tourId: tourId)
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

            if isUploadingPhotos {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical, AtlasSpacing.md)
            } else {
                PhotosPicker(
                    selection: $photoItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    audioButton(all.isEmpty ? "Add photos" : "Add more photos",
                                systemImage: "photo.badge.plus", primary: all.isEmpty)
                }
            }

            Text("Photos are cropped to 1200×900. The first is the cover.")
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
                HStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AtlasColors.mapPin)
                    Text("Audio added · \(AtlasFormatters.duration(seconds: seconds))")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
            }

            if isUploading {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical, AtlasSpacing.md)
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
            }

            Text("Record narration here, or import an audio file (m4a, mp3, wav).")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)

            if let errorMessage {
                Text(errorMessage)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
            }
        }
    }

    private func saveTranscript() {
        errorMessage = nil
        isSavingTranscript = true
        Task {
            defer { isSavingTranscript = false }
            do {
                try await makerTourService.setTranscript(tourId: tourId, text: transcriptText)
            } catch {
                errorMessage = error.localizedDescription
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
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Import

    // MARK: - Photos

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty, let tour = makerTour?.tour else { return }
        errorMessage = nil
        isUploadingPhotos = true
        Task {
            defer { isUploadingPhotos = false; photoItems = [] }
            do {
                var datas: [Data] = []
                for item in items {
                    guard let raw = try await item.loadTransferable(type: Data.self),
                          let cropped = Self.cropTo1200x900(raw) else { continue }
                    datas.append(cropped)
                }
                if !datas.isEmpty {
                    try await makerTourService.attachPhotos(to: tour, images: datas)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Aspect-fill crop + resize to 1200×900, re-encoded as JPEG. Returns nil on
    /// non-UIKit platforms or undecodable data.
    nonisolated private static func cropTo1200x900(_ data: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        let target = CGSize(width: 1200, height: 900)
        let scale = max(target.width / image.size.width, target.height / image.size.height)
        let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (target.width - scaled.width) / 2,
                             y: (target.height - scaled.height) / 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: origin, size: scaled))
        }
        return rendered.jpegData(compressionQuality: 0.82)
        #else
        return nil
        #endif
    }

    // MARK: - Audio import

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first, let tour = makerTour?.tour else { return }
            uploadAudio(from: url, tour: tour)
        }
    }

    private func uploadAudio(from url: URL, tour: Tour) {
        errorMessage = nil
        isUploading = true
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

                try await makerTourService.attachAudio(
                    to: tour,
                    data: data,
                    filename: filename,
                    contentType: contentType,
                    durationSeconds: seconds
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

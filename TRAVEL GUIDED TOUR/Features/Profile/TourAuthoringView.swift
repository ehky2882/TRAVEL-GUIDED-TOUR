import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

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
    @State private var isUploading = false
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
                    comingNextRow("Photos", systemImage: "photo.on.rectangle")
                    comingNextRow("Transcript", systemImage: "text.alignleft")
                    comingNextRow("Submit for review", systemImage: "paperplane")
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

            Button {
                importingAudio = true
            } label: {
                HStack {
                    Spacer()
                    if isUploading {
                        ProgressView().tint(AtlasColors.background)
                    } else {
                        Label(hasAudio ? "Replace audio" : "Import audio",
                              systemImage: "square.and.arrow.down")
                            .font(AtlasTypography.caption)
                    }
                    Spacer()
                }
                .padding(.vertical, AtlasSpacing.md)
                .background(AtlasColors.mapPin)
                .foregroundStyle(AtlasColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
            }
            .disabled(isUploading)

            Text("Recording in the app is coming next; for now, import an audio file (m4a, mp3, wav).")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)

            if let errorMessage {
                Text(errorMessage)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
            }
        }
    }

    /// A disabled row for a step that lands in a later increment.
    private func comingNextRow(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
            Spacer()
            Text("COMING NEXT")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
    }

    // MARK: - Import

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

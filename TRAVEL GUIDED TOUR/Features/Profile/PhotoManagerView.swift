import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

/// Manage a tour's photos: reorder, remove, and choose which one is the cover.
///
/// **Why this exists.** Photos were append-only. There was no way to delete a
/// bad one, no way to change the cover after the first upload, and no cap — so a
/// mis-tap could put a blurry shot on the front of a tour permanently.
///
/// **Position one IS the cover.** One rule rather than a separate "set as cover"
/// action, the way the first frame of a carousel works elsewhere — dragging a
/// photo to the front is how you promote it, and there is nothing else to learn.
///
/// Edits are staged locally and committed on Done, so reordering three photos is
/// one write rather than three, and Cancel genuinely discards.
struct PhotoManagerView: View {
    let tour: Tour

    @Environment(MakerTourService.self) private var makerTourService
    @Environment(\.dismiss) private var dismiss

    /// The working order. Seeded from the tour, mutated by drag and remove.
    @State private var urls: [String]
    @State private var picked: [PhotosPickerItem] = []
    @State private var pendingCrop: [UIImage] = []
    @State private var showingCrop = false
    @State private var isBusy = false
    @State private var busyLabel = ""
    @State private var errorMessage: String?
    /// The tile a dragged photo is currently hovering over.
    @State private var dropTarget: String?

    /// Owner decision, 2026-08-17. Most live tours sit at hero plus two to five,
    /// so eight leaves room for a rich gallery without making a tour page a slog
    /// to swipe through. One constant — change it here.
    static let maxPhotos = 8

    private let columns = [
        GridItem(.flexible(), spacing: AtlasSpacing.sm),
        GridItem(.flexible(), spacing: AtlasSpacing.sm),
        GridItem(.flexible(), spacing: AtlasSpacing.sm)
    ]

    init(tour: Tour) {
        self.tour = tour
        _urls = State(initialValue: ([tour.heroImageURL] + (tour.additionalImageURLs ?? []))
            .filter { !$0.isEmpty })
    }

    private var original: [String] {
        ([tour.heroImageURL] + (tour.additionalImageURLs ?? [])).filter { !$0.isEmpty }
    }
    private var hasChanges: Bool { urls != original }
    private var remaining: Int { max(0, Self.maxPhotos - urls.count) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    Text("Drag to reorder. The first photo is the cover.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)

                    LazyVGrid(columns: columns, spacing: AtlasSpacing.sm) {
                        ForEach(Array(urls.enumerated()), id: \.element) { index, url in
                            tile(url: url, index: index)
                        }
                        if remaining > 0 { addTile }
                    }

                    if isBusy {
                        HStack(spacing: AtlasSpacing.sm) {
                            ProgressView()
                            Text(busyLabel)
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AtlasSpacing.sm)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.mapPin)
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        Text("\(urls.count) of \(Self.maxPhotos) used")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                        ProgressView(value: Double(urls.count), total: Double(Self.maxPhotos))
                            .tint(AtlasColors.mapPin)
                    }
                    .padding(.top, AtlasSpacing.sm)
                }
                .padding(AtlasSpacing.lg)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
            }
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PHOTOS")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commit() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.mapPin)
                        .disabled(isBusy)
                }
            }
            .onChange(of: picked) { _, items in loadPicked(items) }
            .sheet(isPresented: $showingCrop) {
                PhotoCropSheet(images: pendingCrop) { datas in
                    pendingCrop = []
                    upload(datas)
                }
            }
        }
    }

    // MARK: - Tiles

    private func tile(url: String, index: Int) -> some View {
        HeroImageView(imageName: url, height: 84, cornerRadius: 2,
                      category: tour.primaryCategory)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topLeading) {
                Text("\(index + 1)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 3))
                    .padding(5)
            }
            .overlay(alignment: .bottomLeading) {
                if index == 0 {
                    Text("COVER")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AtlasColors.background)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(AtlasColors.mapPin)
                        .padding(5)
                }
            }
            .overlay(alignment: .topTrailing) {
                Button { remove(url) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 21, height: 21)
                        .background(Color.black.opacity(0.62), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(5)
                .accessibilityLabel("Remove photo \(index + 1)")
            }
            // Highlight the tile a dragged photo would land on, so the drop
            // target is obvious before you let go.
            .overlay {
                if dropTarget == url {
                    Rectangle().stroke(AtlasColors.mapPin, lineWidth: 2)
                }
            }
            .draggable(url) {
                // Drag preview — deliberately the plain URL payload, so a drop
                // onto another app does something sane rather than nothing.
                HeroImageView(imageName: url, height: 60, cornerRadius: 2,
                              category: tour.primaryCategory)
                    .frame(width: 80)
            }
            .dropDestination(for: String.self) { items, _ in
                guard let source = items.first,
                      let from = urls.firstIndex(of: source),
                      let to = urls.firstIndex(of: url),
                      from != to
                else { return false }
                withAnimation(.snappy) {
                    let moved = urls.remove(at: from)
                    urls.insert(moved, at: to)
                }
                return true
            } isTargeted: { targeted in
                dropTarget = targeted ? url : nil
            }
    }

    private var addTile: some View {
        PhotosPicker(selection: $picked,
                     maxSelectionCount: remaining,
                     matching: .images) {
            RoundedRectangle(cornerRadius: 2)
                .stroke(AtlasColors.tertiaryText, lineWidth: 1)
                .frame(height: 84)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundStyle(AtlasColors.secondaryText)
                )
        }
        .disabled(isBusy)
    }

    // MARK: - Actions

    private func remove(_ url: String) {
        withAnimation(.snappy) { urls.removeAll { $0 == url } }
    }

    /// Decode the picked items, then hand them to the crop sheet. Decoding here
    /// rather than inside the cropper keeps the sheet a pure framing step.
    private func loadPicked(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        errorMessage = nil
        isBusy = true
        busyLabel = "Preparing photos…"
        Task {
            defer { isBusy = false; picked = [] }
            var loaded: [UIImage] = []
            for item in items.prefix(remaining) {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loaded.append(image)
                }
            }
            guard !loaded.isEmpty else {
                errorMessage = "Those photos couldn't be opened. Try picking them again."
                return
            }
            pendingCrop = loaded
            showingCrop = true
        }
    }

    private func upload(_ datas: [Data]) {
        guard !datas.isEmpty else { return }
        errorMessage = nil
        isBusy = true
        busyLabel = datas.count == 1 ? "Uploading photo…" : "Uploading \(datas.count) photos…"
        Task {
            defer { isBusy = false }
            do {
                let newURLs = try await makerTourService.uploadPhotos(for: tour, images: datas)
                // Appended, not committed — the user can still drag one to the
                // front before pressing Done.
                urls.append(contentsOf: newURLs)
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    /// Commit the working order in one write. Anything dropped is deleted from
    /// Storage rather than left as an orphan nothing references.
    private func commit() {
        guard hasChanges else { dismiss(); return }
        errorMessage = nil
        isBusy = true
        busyLabel = "Saving…"
        Task {
            defer { isBusy = false }
            do {
                try await makerTourService.setPhotos(for: tour, orderedURLs: urls)
                dismiss()
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }
}

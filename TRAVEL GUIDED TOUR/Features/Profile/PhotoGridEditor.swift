import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

/// The Photos step of the wizard: every slot a tour can hold, with adding,
/// framing, reordering and removing done in place.
///
/// **Why in place.** This used to be a separate sheet you opened from the step
/// — a whole extra screen to show a grid the step was already showing. Owner:
/// *"This additional page doesn't seem necessary. Should be able to do
/// everything from one page."* Right: the wizard is already a page per job, and
/// a job shouldn't need a page of its own inside it.
///
/// **So edits apply as you make them.** There is no Done to press, which means
/// there is no Cancel to undo — immediate is the only honest model here. The
/// old sheet staged changes and committed on Done, which bought one write for
/// "add three and drag one to the front"; a reorder is a single cheap write, so
/// that saving isn't worth a screen.
struct PhotoGridEditor: View {
    let tour: Tour

    /// Owner decision, 2026-08-19: seven, not eight. One cover plus six fills
    /// two clean rows of three underneath it; eight left the last row holding
    /// a single box.
    static let maxPhotos = 7

    @Environment(MakerTourService.self) private var makerTourService

    /// The working order. Held locally so a drag lands instantly rather than
    /// waiting on the network, then written straight through.
    @State private var urls: [String]
    @State private var picked: [PhotosPickerItem] = []
    /// Photos waiting to be framed. While this isn't empty the step shows the
    /// framing view in place of the grid — one page, two modes, no sheet.
    @State private var pendingCrop: [UIImage] = []
    @State private var isBusy = false
    @State private var busyLabel = ""
    @State private var errorMessage: String?
    /// Which tile a dragged photo would land on.
    @State private var dropTarget: String?
    /// The grid's real width, measured once. Slot heights come from it rather
    /// than from constants, so a slot is 4:3 on an SE as well as a 16 Pro —
    /// the trap that cropped the hero photograph 8% on one device and 23% on
    /// another. Zero until the first layout; the fallbacks below cover it.
    @State private var gridWidth: CGFloat = 0

    /// The cover slot, at the ratio photos are actually stored in.
    ///
    /// ⚠️ It used to be a flat 180pt, which against a 345pt width is 1.92:1 —
    /// a shape matching NOTHING. Not what the framing tool produces (4:3), not
    /// what the app displays (1:1). 180 was a round number.
    private var coverHeight: CGFloat {
        gridWidth > 0 ? gridWidth * 3 / 4 : 180
    }

    /// A thumbnail, three across, same 4:3.
    private var thumbHeight: CGFloat {
        guard gridWidth > 0 else { return 74 }
        return ((gridWidth - AtlasSpacing.sm * 2) / 3) * 3 / 4
    }

    init(tour: Tour) {
        self.tour = tour
        _urls = State(initialValue: ([tour.heroImageURL] + (tour.additionalImageURLs ?? []))
            .filter { !$0.isEmpty })
    }

    private var remaining: Int { max(0, Self.maxPhotos - urls.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            if pendingCrop.isEmpty {
                grid
            } else {
                PhotoFramingView(images: pendingCrop) { datas in
                    pendingCrop = []
                    upload(datas)
                } onCancel: {
                    pendingCrop = []
                }
            }

            if isBusy {
                HStack(spacing: AtlasSpacing.sm) {
                    ProgressView()
                    Text(busyLabel)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
            }

            // The count-and-reorder line moved to the wizard's footer hint,
            // which reserves its height whether or not it has anything to say.
            // "The first is the cover" went with it — the COVER badge on the
            // first slot teaches that better than a sentence does.
        }
        .onChange(of: picked) { _, items in loadPicked(items) }
    }

    // MARK: - Grid

    /// Every slot the tour could hold, so the shape of the finished thing is
    /// visible from the first photo — how many fit, and which one is the cover.
    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AtlasSpacing.sm), count: 3)
        return VStack(spacing: AtlasSpacing.sm) {
            slot(index: 0, height: coverHeight)
            LazyVGrid(columns: columns, spacing: AtlasSpacing.sm) {
                ForEach(1..<Self.maxPhotos, id: \.self) { index in
                    slot(index: index, height: thumbHeight)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { gridWidth = $0 }
    }

    /// 🔴 WHAT THE APP WILL ACTUALLY SHOW OF THIS PHOTO.
    ///
    /// Photos are framed and stored at **1200×900** — the framing tool says so
    /// — but `AtlasSpacing.heroAspectRatio` is **1.0**, so every hero and every
    /// carousel page in the app is a square taken from the middle. **25% of the
    /// width is thrown away**, and until now nothing told the maker: a tower
    /// comfortably in shot at 4:3 can be half gone in the app, with no error
    /// and nothing that looks broken. The same shape of failure as the ten
    /// Barcelona coordinates — correct-looking input, silently wrong output.
    ///
    /// So every slot draws the square, not just the cover (owner, 2026-08-20):
    /// the carousel crops the gallery images exactly as hard as the hero.
    ///
    /// This changes nothing about what is stored. The gallery still uses the
    /// full 4:3; the square is only what survives the hero-shaped surfaces.
    private func squareGuide(side: CGFloat, labelled: Bool) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .strokeBorder(AtlasColors.mapPin.opacity(0.85),
                          style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(width: side, height: side)
            .overlay(alignment: .top) {
                if labelled {
                    Text("SHOWN IN THE APP")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(AtlasColors.mapPin)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AtlasColors.background.opacity(0.85), in: Capsule())
                        .padding(.top, 5)
                }
            }
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func slot(index: Int, height: CGFloat) -> some View {
        if index < urls.count {
            filledSlot(url: urls[index], index: index, height: height)
        } else {
            emptySlot(index: index, height: height)
        }
    }

    private func filledSlot(url: String, index: Int, height: CGFloat) -> some View {
        HeroImageView(imageName: url, height: height,
                      cornerRadius: AtlasSpacing.sm, category: tour.primaryCategory)
            // Every slot, not only the cover — the carousel crops a gallery
            // photo exactly as hard as it crops the hero. Labelled only on the
            // cover; at thumbnail size the words would be bigger than the box.
            .overlay { squareGuide(side: height, labelled: index == 0) }
            .overlay(alignment: .bottomLeading) {
                if index == 0 {
                    Text("COVER")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AtlasColors.background)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(AtlasColors.mapPin)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .padding(AtlasSpacing.xs)
                }
            }
            .overlay(alignment: .topTrailing) {
                Button { remove(url) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 21, height: 21)
                        .background(Color.black.opacity(0.62), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(AtlasSpacing.xs)
                .accessibilityLabel("Remove photo \(index + 1)")
            }
            // Show where a dragged photo would land before you let go.
            .overlay {
                if dropTarget == url {
                    RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                        .stroke(AtlasColors.mapPin, lineWidth: 2)
                }
            }
            .draggable(url) {
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
                persist()
                return true
            } isTargeted: { targeted in
                dropTarget = targeted ? url : nil
            }
    }

    /// An empty box is the picker itself, so the next photo is one tap away
    /// wherever you are in the grid.
    private func emptySlot(index: Int, height: CGFloat) -> some View {
        let isNextUp = index == urls.count
        return PhotosPicker(selection: $picked,
                            maxSelectionCount: remaining,
                            matching: .images) {
            RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                .strokeBorder(isNextUp ? AtlasColors.mapPin : AtlasColors.divider,
                              style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(height: height)
                .overlay {
                    if isNextUp {
                        Image(systemName: "plus")
                            .font(.system(size: index == 0 ? 20 : 14))
                            .foregroundStyle(AtlasColors.mapPin)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if index == 0 {
                        Text("COVER")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AtlasColors.tertiaryText)
                            .padding(AtlasSpacing.xs)
                    }
                }
        }
        .disabled(isBusy || remaining == 0)
        .accessibilityLabel(index == 0 ? "Add a cover photo" : "Add a photo")
    }

    // MARK: - Actions

    private func remove(_ url: String) {
        withAnimation(.snappy) { urls.removeAll { $0 == url } }
        persist()
    }

    /// Decode the picked items, then hand them to the crop sheet. Decoding here
    /// rather than inside the cropper keeps that sheet a pure framing step.
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
                urls.append(contentsOf: newURLs)
                try await makerTourService.setPhotos(for: tour, orderedURLs: urls)
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    /// Write the order through. Anything dropped is deleted from Storage by
    /// `setPhotos` rather than left as an orphan nothing references.
    private func persist() {
        let ordered = urls
        Task {
            do {
                try await makerTourService.setPhotos(for: tour, orderedURLs: ordered)
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }
}

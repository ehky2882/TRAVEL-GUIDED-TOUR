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
///
/// **And no framing screen either** (owner, 2026-08-20). Picking a photo used
/// to hand you a full-step framing view with Skip and Use photo before the
/// photo had ever appeared in the grid — a confirmation of something you
/// hadn't seen in context yet. Photos now land centre-cropped and are adjusted
/// *in the slot*: tap one, pinch and drag, tap again. `PhotoFramingView` is
/// deleted; `PhotoCrop` holds the maths it was built around.
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

    /// 🔴 THE SLOT IS THE EDITOR. Tap a photo and it becomes adjustable where
    /// it sits — pinch to zoom, drag to reposition — and tapping it again puts
    /// the change back. There is no framing screen and no confirmation step
    /// (owner, 2026-08-20: *"in the current on-device version, there is
    /// another screen that asks for a confirmation of the photo. i don't like
    /// that. do everything from this screen"*). `PhotoFramingView` is deleted;
    /// its maths lives in `PhotoCrop`.
    ///
    /// ⚠️ Activation is required, and it is not ceremony — it is what stops
    /// two gestures meaning two things at once. A drag on an idle slot
    /// **reorders**; a drag on the active slot **pans**. Without the tap there
    /// is no way to tell which one a finger meant.
    @State private var activeURL: String?
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero

    /// Full-resolution photos as they were picked, held for as long as this
    /// step is on screen.
    ///
    /// ⚠️ Why it matters: what's on the server is already cropped to 1200×900,
    /// so adjusting a photo the maker uploaded in an earlier session can zoom
    /// *in* but can never recover the edges the first crop threw away. While
    /// the original is still here, adjustment is lossless. This is the honest
    /// limit of editing in place, and it is worth the trade — the alternative
    /// was a screen that made you commit before you had seen the photo in the
    /// grid at all.
    @State private var originals: [String: UIImage] = [:]
    /// Which of those are the photo as picked, rather than a copy fetched back
    /// from the server after an earlier session. Only these can be widened.
    @State private var pristine: Set<String> = []
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

    private var liveScale: CGFloat { max(1, min(scale * pinch, PhotoCrop.maxScale)) }
    private var liveOffset: CGSize {
        CGSize(width: offset.width + drag.width, height: offset.height + drag.height)
    }

    /// Whether adjusting `url` can still reach the whole photograph.
    private func isLossless(_ url: String) -> Bool { pristine.contains(url) }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            grid

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

            // ⚠️ Said, not hidden. A photo uploaded in an earlier session is
            // only on the server as the 1200×900 it was cropped to, so this
            // adjustment can zoom in but can never widen back out. Saying so is
            // the difference between a limit and a bug.
            if let activeURL, !isLossless(activeURL) {
                Text("Zoom and reposition only — the original isn't on this device any more.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
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

    @ViewBuilder
    private func filledSlot(url: String, index: Int, height: CGFloat) -> some View {
        let active = activeURL == url
        Group {
            if active, let image = originals[url] {
                // Being adjusted, from the photo as it was picked.
                PhotoCrop.layer(image, scale: liveScale, offset: liveOffset)
                    .frame(height: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
            } else {
                HeroImageView(imageName: url, height: height,
                              cornerRadius: AtlasSpacing.sm, category: tour.primaryCategory)
            }
        }
            // Every slot, not only the cover — the carousel crops a gallery
            // photo exactly as hard as it crops the hero. Labelled only on the
            // cover; at thumbnail size the words would be bigger than the box.
            .overlay { squareGuide(side: height, labelled: index == 0) }
            // The active slot is ringed, and says what a finger will now do.
            .overlay {
                if active {
                    RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                        .stroke(AtlasColors.mapPin, lineWidth: 2)
                }
            }
            .overlay(alignment: .top) {
                if active, index == 0 {
                    Text("PINCH TO ZOOM · DRAG TO MOVE")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(AtlasColors.background)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(AtlasColors.mapPin, in: Capsule())
                        .padding(.top, AtlasSpacing.xs)
                }
            }
            // 🔴 Gestures are attached ONLY while active. Idle, a drag belongs
            // to reordering; active, it belongs to the photograph. One finger,
            // two meanings, and the tap is what chooses between them.
            .gesture(active ? SimultaneousGesture(magnify, move) : nil)
            .onTapGesture { toggleActive(url) }
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
            // Reordering is the idle gesture. While this photo is being
            // adjusted its drag means pan, so the drag source goes away.
            .draggable(active ? "" : url) {
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

    /// Decode the picked photos, centre-crop them, and put them straight in
    /// the grid.
    ///
    /// No framing step on the way in. The centre crop is a *starting point*
    /// now, not a verdict — the photo lands in the grid and can be adjusted
    /// there — which is the whole reason the confirmation screen could go.
    /// The picked image is kept so that adjustment is lossless.
    private func loadPicked(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        errorMessage = nil
        isBusy = true
        busyLabel = items.count == 1 ? "Adding photo…" : "Adding \(items.count) photos…"
        Task {
            defer { isBusy = false; picked = [] }
            var loaded: [(image: UIImage, data: Data)] = []
            for item in items.prefix(remaining) {
                if let raw = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: raw),
                   let cropped = PhotoCrop.centreCrop(image) {
                    loaded.append((image, cropped))
                }
            }
            guard !loaded.isEmpty else {
                errorMessage = "Those photos couldn't be opened. Try picking them again."
                return
            }
            await upload(loaded)
        }
    }

    /// Send new photos up, then remember which original made which URL.
    private func upload(_ items: [(image: UIImage, data: Data)]) async {
        errorMessage = nil
        isBusy = true
        busyLabel = items.count == 1 ? "Uploading photo…" : "Uploading \(items.count) photos…"
        defer { isBusy = false }
        do {
            let newURLs = try await makerTourService.uploadPhotos(
                for: tour, images: items.map(\.data))
            for (url, item) in zip(newURLs, items) {
                originals[url] = item.image
                pristine.insert(url)
            }
            urls.append(contentsOf: newURLs)
            try await makerTourService.setPhotos(for: tour, orderedURLs: urls)
        } catch {
            errorMessage = AuthoringErrorText.message(for: error)
        }
    }

    // MARK: - Adjusting in place

    private var magnify: some Gesture {
        MagnificationGesture()
            .updating($pinch) { value, state, _ in state = value }
            .onEnded { scale = max(1, min(scale * $0, PhotoCrop.maxScale)) }
    }

    private var move: some Gesture {
        DragGesture()
            .updating($drag) { value, state, _ in state = value.translation }
            .onEnded {
                offset.width += $0.translation.width
                offset.height += $0.translation.height
            }
    }

    /// Tap to start adjusting a photo; tap again to put the change back.
    ///
    /// Tapping a *different* photo commits the one you were on first, so there
    /// is never a half-made adjustment sitting somewhere off screen — the same
    /// reason this step has no Done button: immediate is the only honest model
    /// when there is nothing to cancel back to.
    private func toggleActive(_ url: String) {
        if activeURL == url {
            commitActive()
            return
        }
        commitActive()
        scale = 1
        offset = .zero
        activeURL = url
        guard originals[url] == nil else { return }
        // Nothing held for this one — it was uploaded in an earlier session, so
        // the only copy is the already-cropped one on the server. Editing it
        // can zoom in but cannot recover what the first crop cut.
        Task {
            guard let remote = URL(string: url),
                  let (data, _) = try? await URLSession.shared.data(from: remote),
                  let image = UIImage(data: data)
            else { return }
            originals[url] = image
        }
    }

    /// Render whatever is on screen and put it back, if it changed.
    private func commitActive() {
        guard let url = activeURL else { return }
        activeURL = nil
        // An untouched photo is already exactly what is stored. Re-rendering it
        // would cost an upload and a JPEG generation to produce the same
        // picture, slightly worse.
        guard scale != 1 || offset != .zero,
              let image = originals[url],
              let index = urls.firstIndex(of: url),
              let data = PhotoCrop.render(image, scale: scale, offset: offset)
        else { return }

        let wasPristine = pristine.contains(url)
        isBusy = true
        busyLabel = "Saving framing…"
        Task {
            defer { isBusy = false }
            do {
                let uploaded = try await makerTourService.uploadPhotos(for: tour, images: [data])
                guard let replacement = uploaded.first else { return }
                // Carry the source across so a second adjustment is as good as
                // the first — otherwise every tweak would compound the crop.
                originals[replacement] = image
                if wasPristine { pristine.insert(replacement) }
                originals[url] = nil
                pristine.remove(url)
                urls[index] = replacement
                // `setPhotos` deletes what is no longer in the list, so the
                // photo being replaced is cleaned up rather than orphaned.
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

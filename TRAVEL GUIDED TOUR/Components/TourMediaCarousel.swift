import SwiftUI

/// Shared photo + video carousel for the tour-detail sheet and the
/// full player. Both surfaces used to build an identical inline
/// `TabView` over `[heroImageURL] + additionalImageURLs` (their code
/// comments explicitly said "mirrors the other exactly"); this extracts
/// that one carousel so they can't drift and so **video support lives in
/// one place**.
///
/// Layout: **`videoURLs` lead**, then the images (hero, then
/// `additionalImageURLs`) — owner decision, 2026-07-26. A tour that
/// carries a video opens on it, so the video *is* the hero; the still
/// `heroImageURL` becomes the next page. Videos originally rendered
/// last (2026-07-19); the owner moved them to the front once real video
/// content existed. When there's exactly one item (hero only, no extra
/// photos, no video) it renders a single `HeroImageView` with no paging
/// dots, exactly as before.
///
/// Note this only reorders the *carousel*. Every other surface — list
/// cards, placecards, the map, maker grids, the lock screen — still
/// shows `heroImageURL`, so a tour's still image remains its thumbnail
/// everywhere it's represented as one image.
///
/// The caller applies horizontal padding (both sites pad by
/// `AtlasSpacing.lg`), matching the pre-extraction behaviour.
struct TourMediaCarousel: View {
    let heroImageURL: String
    let additionalImageURLs: [String]?
    let videoURLs: [String]?
    /// nil sizes by the hero ratio (5:4) — see `atlasHeroSizing`. Every full-width
    /// hero passes nil; the parameter stays for any fixed-size use.
    let height: CGFloat?
    /// Placeholder tint category, used only on the single-image fallback
    /// (matches the previous `HeroImageView(category:)` call).
    var category: TourCategory? = nil

    /// One carousel page — an image URL or a video URL. `id` namespaces
    /// the two so ForEach/selection diffing is stable even if a URL
    /// happened to appear in both lists.
    enum Media: Identifiable, Equatable {
        case image(String)
        case video(String)

        var id: String {
            switch self {
            case .image(let u): return "img:\(u)"
            case .video(let u): return "vid:\(u)"
            }
        }
    }

    /// Carousel pages in display order: videos first, then the hero
    /// image, then the additional images. Pure + static so the ordering
    /// rule is unit-testable without building a view.
    static func orderedMedia(
        heroImageURL: String,
        additionalImageURLs: [String]?,
        videoURLs: [String]?
    ) -> [Media] {
        let videos = (videoURLs ?? []).map(Media.video)
        let images = ([heroImageURL] + (additionalImageURLs ?? [])).map(Media.image)
        return videos + images
    }

    private var items: [Media] {
        Self.orderedMedia(
            heroImageURL: heroImageURL,
            additionalImageURLs: additionalImageURLs,
            videoURLs: videoURLs
        )
    }

    /// The visible page's id. Seeded to the *first ordered page* — the
    /// leading video when the tour has one, else the hero image — so the
    /// carousel shows page 1 on the first frame with no blank flash
    /// while a `.onAppear` catches up.
    @State private var selection: String

    init(
        heroImageURL: String,
        additionalImageURLs: [String]?,
        videoURLs: [String]?,
        height: CGFloat?,
        category: TourCategory? = nil
    ) {
        self.heroImageURL = heroImageURL
        self.additionalImageURLs = additionalImageURLs
        self.videoURLs = videoURLs
        self.height = height
        self.category = category
        let ordered = Self.orderedMedia(
            heroImageURL: heroImageURL,
            additionalImageURLs: additionalImageURLs,
            videoURLs: videoURLs
        )
        // `ordered` always contains at least the hero image, so the
        // fallback is unreachable — kept so the init can't trap.
        self._selection = State(initialValue: ordered.first?.id ?? "img:\(heroImageURL)")
    }

    var body: some View {
        let media = items
        if media.count > 1 {
            TabView(selection: $selection) {
                ForEach(media) { item in
                    page(for: item)
                        .tag(item.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .atlasHeroSizing(height)
        } else {
            // Single item — always the hero image (every tour has one).
            HeroImageView(
                imageName: heroImageURL,
                height: height,
                category: category,
                zoomable: true,
                disableLoadAnimation: true
            )
        }
    }

    @ViewBuilder
    private func page(for item: Media) -> some View {
        switch item {
        case .image(let url):
            HeroImageView(
                imageName: url,
                height: height,
                zoomable: true,
                disableLoadAnimation: true
            )
        case .video(let url):
            GalleryVideoView(
                urlString: url,
                height: height,
                isActive: selection == item.id
            )
        }
    }
}

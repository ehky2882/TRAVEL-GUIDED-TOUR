import SwiftUI

/// Shared photo + video carousel for the tour-detail sheet and the
/// full player. Both surfaces used to build an identical inline
/// `TabView` over `[heroImageURL] + additionalImageURLs` (their code
/// comments explicitly said "mirrors the other exactly"); this extracts
/// that one carousel so they can't drift and so **video support lives in
/// one place**.
///
/// Layout: the images render first (hero, then `additionalImageURLs`),
/// then any `videoURLs` as extra swipeable pages at the end — owner
/// decision, 2026-07-19. When there's exactly one item (hero only, no
/// extra photos, no video) it renders a single `HeroImageView` with no
/// paging dots, exactly as before.
///
/// The caller applies horizontal padding (both sites pad by
/// `AtlasSpacing.lg`), matching the pre-extraction behaviour.
struct TourMediaCarousel: View {
    let heroImageURL: String
    let additionalImageURLs: [String]?
    let videoURLs: [String]?
    let height: CGFloat
    /// Placeholder tint category, used only on the single-image fallback
    /// (matches the previous `HeroImageView(category:)` call).
    var category: TourCategory? = nil

    /// One carousel page — an image URL or a video URL. `id` namespaces
    /// the two so ForEach/selection diffing is stable even if a URL
    /// happened to appear in both lists.
    private enum Media: Identifiable, Equatable {
        case image(String)
        case video(String)

        var id: String {
            switch self {
            case .image(let u): return "img:\(u)"
            case .video(let u): return "vid:\(u)"
            }
        }
    }

    private var items: [Media] {
        let images = ([heroImageURL] + (additionalImageURLs ?? [])).map(Media.image)
        let videos = (videoURLs ?? []).map(Media.video)
        return images + videos
    }

    /// The visible page's id. Seeded to the hero image (always the
    /// first page) so the carousel shows page 1 on the first frame —
    /// no blank flash while a `.onAppear` catches up.
    @State private var selection: String

    init(
        heroImageURL: String,
        additionalImageURLs: [String]?,
        videoURLs: [String]?,
        height: CGFloat,
        category: TourCategory? = nil
    ) {
        self.heroImageURL = heroImageURL
        self.additionalImageURLs = additionalImageURLs
        self.videoURLs = videoURLs
        self.height = height
        self.category = category
        self._selection = State(initialValue: "img:\(heroImageURL)")
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
            .frame(height: height)
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

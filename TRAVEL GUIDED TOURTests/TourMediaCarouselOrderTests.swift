import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers `TourMediaCarousel.orderedMedia` — the rule that decides what
/// the tour-detail / player carousel shows on page 1.
///
/// Videos lead, then the hero image, then the additional images (owner
/// decision, 2026-07-26): a tour that carries a video opens on it, so
/// the video *is* the hero. Before that, videos rendered last.
final class TourMediaCarouselOrderTests: XCTestCase {

    private let hero = "https://example.com/hero.webp"
    private let extra1 = "https://example.com/2.webp"
    private let extra2 = "https://example.com/3.webp"
    private let video = "https://example.com/clip.mp4"

    private func ordered(
        additional: [String]? = nil,
        videos: [String]? = nil
    ) -> [TourMediaCarousel.Media] {
        TourMediaCarousel.orderedMedia(
            heroImageURL: hero,
            additionalImageURLs: additional,
            videoURLs: videos
        )
    }

    // MARK: - Videos lead

    func testVideoLeadsWhenPresent() {
        let media = ordered(additional: [extra1, extra2], videos: [video])
        XCTAssertEqual(media.first, .video(video))
    }

    func testHeroImageFollowsTheVideo() {
        let media = ordered(additional: [extra1, extra2], videos: [video])
        XCTAssertEqual(media, [.video(video), .image(hero), .image(extra1), .image(extra2)])
    }

    func testMultipleVideosAllLeadInOrder() {
        let second = "https://example.com/clip2.mp4"
        let media = ordered(additional: [extra1], videos: [video, second])
        XCTAssertEqual(media, [.video(video), .video(second), .image(hero), .image(extra1)])
    }

    func testVideoLeadsEvenWithNoAdditionalImages() {
        let media = ordered(videos: [video])
        XCTAssertEqual(media, [.video(video), .image(hero)])
    }

    // MARK: - Image-only tours are unchanged

    func testImageOnlyTourStillLeadsWithHero() {
        let media = ordered(additional: [extra1, extra2], videos: nil)
        XCTAssertEqual(media, [.image(hero), .image(extra1), .image(extra2)])
    }

    func testEmptyVideoArrayBehavesLikeNil() {
        XCTAssertEqual(ordered(additional: [extra1], videos: []),
                       ordered(additional: [extra1], videos: nil))
    }

    func testHeroOnlyTourIsASingleImage() {
        XCTAssertEqual(ordered(), [.image(hero)])
    }

    // MARK: - Page identity

    /// `id` namespaces the two kinds so carousel selection diffing stays
    /// stable even if the same URL appeared in both lists.
    func testImageAndVideoIDsAreNamespacedApart() {
        let sameURL = "https://example.com/same"
        let media = TourMediaCarousel.orderedMedia(
            heroImageURL: sameURL,
            additionalImageURLs: nil,
            videoURLs: [sameURL]
        )
        XCTAssertEqual(media.map(\.id), ["vid:\(sameURL)", "img:\(sameURL)"])
        XCTAssertEqual(Set(media.map(\.id)).count, 2)
    }

    /// The carousel seeds its `selection` from `orderedMedia.first`, so
    /// a tour with a video must open on the video page, not the hero.
    func testFirstPageIDIsTheVideoWhenPresent() {
        XCTAssertEqual(ordered(additional: [extra1], videos: [video]).first?.id, "vid:\(video)")
        XCTAssertEqual(ordered(additional: [extra1]).first?.id, "img:\(hero)")
    }
}

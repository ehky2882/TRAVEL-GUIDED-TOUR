import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The rule that keeps a reused `HeroImageView` from showing the previous
/// tour's photograph.
///
/// Reported from a device: the "Continue listening" row read VIA 57 WEST
/// while showing the Colosseum. Title and image come from the *same* `Tour`
/// value, so the data could not disagree — the image was stale view state.
final class HeroImageCacheRuleTests: XCTestCase {

    /// The regression itself. Before the fix this path did nothing at all
    /// (`if ImageCache.shared.image(for: url) != nil { return }`), so a view
    /// already showing an old photograph kept it even though the new URL's
    /// image was sitting in the cache.
    func test_cacheHitWhileShowingAnotherImage_adoptsRatherThanKeeping() {
        XCTAssertEqual(
            HeroImageView.cacheAction(hasCacheHit: true, isShowingImage: true),
            .adopt
        )
    }

    /// A cache miss under a reused view: the photograph on screen belongs to
    /// a different URL, so it must go before the fetch. One placeholder frame
    /// is correct; the wrong photograph never is.
    func test_cacheMissWhileShowingAnotherImage_clearsFirst() {
        XCTAssertEqual(
            HeroImageView.cacheAction(hasCacheHit: false, isShowingImage: true),
            .clearThenFetch
        )
    }

    /// First appearance, warm cache — `init` already seeded the state, so
    /// adopting is a no-op and the frame-zero, no-flash path is preserved.
    func test_cacheHitOnFirstAppearance_adopts() {
        XCTAssertEqual(
            HeroImageView.cacheAction(hasCacheHit: true, isShowingImage: false),
            .adopt
        )
    }

    /// First appearance, cold cache — nothing to correct, just fetch.
    func test_cacheMissOnFirstAppearance_fetches() {
        XCTAssertEqual(
            HeroImageView.cacheAction(hasCacheHit: false, isShowingImage: false),
            .fetch
        )
    }

    /// A cache hit never clears, whatever is on screen: clearing on a hit
    /// would reintroduce the placeholder flash the pre-seeded `@State` exists
    /// to avoid.
    func test_cacheHitNeverClears() {
        for showing in [true, false] {
            XCTAssertEqual(
                HeroImageView.cacheAction(hasCacheHit: true, isShowingImage: showing),
                .adopt,
                "a cache hit must always adopt (isShowingImage: \(showing))"
            )
        }
    }
}

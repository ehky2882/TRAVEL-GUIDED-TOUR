import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Pins `AtlasNavigationState`'s depth counting, which decides whether the
/// bottom module wears Home's floating island or a detail screen's full-edge
/// form, and whether `ContentView` mounts the Home drawer at all.
///
/// WHY THIS FILE EXISTS
/// --------------------
/// Owner, on 1.1 (125): *"after I hit the city and it goes back to the map
/// view the bottom module is not fully built."* It was fully built — it was
/// wearing the wrong screen's layout. `SearchView` released its pushed state
/// in `onDisappear`, which fires only once the pop ANIMATION has finished, so
/// for ~0.5s after the map was already on screen `isShowingDetail` was still
/// true: the module stayed full-edge and the drawer stayed unmounted, then
/// both snapped in together.
///
/// The fix releases before `dismiss()`, which means release now happens twice
/// on that path — early, and again from `onDisappear`. These tests pin that
/// the pairing survives that, in both directions.
final class NavigationDepthPairingTests: XCTestCase {

    func test_pushThenPop_returnsToRoot() {
        let nav = AtlasNavigationState()
        XCTAssertFalse(nav.isShowingDetail)

        nav.push()
        XCTAssertTrue(nav.isShowingDetail)

        nav.pop()
        XCTAssertFalse(nav.isShowingDetail, "one push, one pop, back to root")
    }

    /// 🔴 THE REASON `SearchView` GUARDS ON ITS OWN FLAG RATHER THAN LEANING
    /// ON THIS CLAMP.
    ///
    /// A double pop is harmless at depth 1 — it clamps at zero. It is NOT
    /// harmless when another detail sits above: the second pop silently eats
    /// that screen's depth, and the module would flip to Home's island form
    /// while a detail is still on top. This documents the hazard the flag
    /// exists to prevent.
    func test_doublePop_atDepthOne_clampsRatherThanGoingNegative() {
        let nav = AtlasNavigationState()
        nav.push()
        nav.pop()
        nav.pop()

        XCTAssertEqual(nav.pushedDepth, 0, "never negative")
        XCTAssertFalse(nav.isShowingDetail)
    }

    func test_doublePop_withADetailStillPushed_wouldEatItsDepth() {
        let nav = AtlasNavigationState()
        nav.push()          // Search
        nav.push()          // something pushed over it
        nav.pop()
        nav.pop()           // the unpaired second release

        XCTAssertEqual(nav.pushedDepth, 0)
        XCTAssertFalse(nav.isShowingDetail,
                       "this is the WRONG state for a screen still on top — "
                       + "why release must be paired, not merely clamped")
    }

    /// Nested details must keep the module in detail form until the last one
    /// leaves — the Search -> Maker deep link stays on the Home tab, so the
    /// tab check alone would miss it.
    func test_nestedDetails_stayInDetailFormUntilTheLastPop() {
        let nav = AtlasNavigationState()
        nav.push()
        nav.push()

        nav.pop()
        XCTAssertTrue(nav.isShowingDetail, "one detail is still on top")

        nav.pop()
        XCTAssertFalse(nav.isShowingDetail)
    }
}

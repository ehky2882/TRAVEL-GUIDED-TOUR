import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers when the mini-player + tab bar paint edge-to-edge rather than as a
/// floating island.
///
/// The island form leaves 8pt side gaps and a transparent strip below, and
/// those gaps are deliberate: on a bare Home tab the map shows through them.
/// The consequence is that **anything covering the map must switch to the
/// edge-to-edge form**, or its own content shows through instead.
///
/// Reported on 1.1 (73): the place page's tour rows were visible under the
/// tab bar. The rule was right; the place layer simply wasn't one of its
/// inputs, because `PlaceView` never calls `navState.push()` and the place
/// presenter wasn't consulted.
@MainActor
final class BottomModuleGeometryTests: XCTestCase {

    private func extends(
        home: Bool = true,
        pushed: Bool = false,
        layer: Bool = false
    ) -> Bool {
        BottomModuleRoot.extendsToScreenEdges(
            isHomeTab: home,
            isShowingPushedDetail: pushed,
            isAnyLayerPresented: layer
        )
    }

    /// The one case that gets the island: Home, nothing over it.
    func test_bareHomeTab_isTheOnlyIslandCase() {
        XCTAssertFalse(extends(home: true, pushed: false, layer: false))
    }

    /// 🔴 The 1.1 (73) regression. A slide-up layer on the Home tab registers
    /// no pushed detail, so this is the only signal that it is on screen.
    func test_layerOnHomeTab_extendsToEdges() {
        XCTAssertTrue(extends(home: true, pushed: false, layer: true))
    }

    func test_pushedDetailOnHomeTab_extendsToEdges() {
        XCTAssertTrue(extends(home: true, pushed: true, layer: false))
    }

    /// Every other tab is opaque regardless — there is no map to show through.
    func test_nonHomeTab_alwaysExtendsToEdges() {
        XCTAssertTrue(extends(home: false))
        XCTAssertTrue(extends(home: false, pushed: true))
        XCTAssertTrue(extends(home: false, layer: true))
    }

    /// A layer over a pushed detail must not somehow cancel back to the island.
    func test_layerAndPushedDetailTogether_extendsToEdges() {
        XCTAssertTrue(extends(home: true, pushed: true, layer: true))
    }
}

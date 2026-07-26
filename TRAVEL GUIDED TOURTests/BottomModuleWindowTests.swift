import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers the cold-launch recovery decision for the secondary
/// mini-player + tab-bar window. The bug: on launches where the App's
/// `.onAppear` fired before any scene reached `.foregroundActive`,
/// `install()` gave up permanently and the bottom module was missing
/// for the whole session. `installOutcome` is the extracted, pure
/// decision that now drives install-now vs. defer-and-retry, so it can
/// be verified deterministically without a live `UIWindowScene`.
@MainActor
final class BottomModuleWindowTests: XCTestCase {

    // A scene is available and no window exists yet → build it now.
    func test_installsNow_whenActiveSceneAndNoWindow() {
        XCTAssertEqual(
            BottomModuleWindowController.installOutcome(hasWindow: false, hasActiveScene: true),
            .installNow
        )
    }

    // The cold-launch race: no active scene yet → defer, don't give up.
    // (Before the fix this branch silently returned with no retry.)
    func test_defersUntilActive_whenNoSceneYet() {
        XCTAssertEqual(
            BottomModuleWindowController.installOutcome(hasWindow: false, hasActiveScene: false),
            .deferUntilActive
        )
    }

    // Idempotence: once the window exists, every later call is a no-op
    // regardless of scene state — so the `.onAppear` and the
    // `scenePhase == .active` retry can never build a second window.
    func test_noOp_whenWindowAlreadyInstalled() {
        XCTAssertEqual(
            BottomModuleWindowController.installOutcome(hasWindow: true, hasActiveScene: true),
            .alreadyInstalled
        )
        XCTAssertEqual(
            BottomModuleWindowController.installOutcome(hasWindow: true, hasActiveScene: false),
            .alreadyInstalled
        )
    }

    // MARK: - Orphaned-window rebuild
    //
    // The idempotence above is correct only while the window is still usable.
    // A window belongs to the scene it was built in; if that scene is torn
    // down (seen on hand-off launches, e.g. opening the build from TestFlight)
    // the window object survives but renders nothing — and `alreadyInstalled`
    // then makes every recovery path a no-op, leaving the mini-player + tab
    // bar missing for the whole session. `needsRebuild` is what breaks that.

    func test_rebuilds_whenWindowsSceneIsGone() {
        XCTAssertTrue(
            BottomModuleWindowController.needsRebuild(hasWindow: true, isAttachedToLiveScene: false)
        )
    }

    // A normal background → foreground cycle keeps the same live scene, so the
    // window must survive it. Rebuilding here would tear down and recreate the
    // module on every foreground.
    func test_doesNotRebuild_whenSceneStillLive() {
        XCTAssertFalse(
            BottomModuleWindowController.needsRebuild(hasWindow: true, isAttachedToLiveScene: true)
        )
    }

    // Nothing to rebuild before the first install — that path is
    // `installOutcome`'s job, not this one.
    func test_doesNotRebuild_whenNoWindowYet() {
        XCTAssertFalse(
            BottomModuleWindowController.needsRebuild(hasWindow: false, isAttachedToLiveScene: false)
        )
        XCTAssertFalse(
            BottomModuleWindowController.needsRebuild(hasWindow: false, isAttachedToLiveScene: true)
        )
    }
}

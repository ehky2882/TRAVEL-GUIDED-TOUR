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
}

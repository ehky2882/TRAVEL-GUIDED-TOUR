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

    // MARK: - Visibility (the bars going missing on a settled Home tab)
    //
    // A DIFFERENT failure from the install race above, and the reason that
    // fix didn't cure the report: the window installed fine and was then left
    // HIDDEN. It painted nothing, and because the inline fallback keyed off
    // `isInstalled`, it drew nothing either — bars gone for the session, on
    // every tab, no way back but a force-quit.
    //
    // The launch is what hid it. `installBottomModule()` latched a hide off
    // `isSplashVisible`, and the single matching unhide in `runLaunchGate`
    // runs 32 ms BEFORE that turns false (a guaranteed suspension point), so
    // any `installBottomModule()` in the gap — `scenePhase == .active` calls
    // it unguarded — re-hid the window with nothing left to undo it.

    // The launch holds the bars back while it is still holding them back —
    // not while `isSplashVisible`, which outlives the unhide.
    func test_withdrawn_whileLaunchHoldsModule() {
        XCTAssertTrue(
            BottomModuleWindowController.shouldWithdraw(
                launchHoldsModule: true, withdrawnByScreen: false
            )
        )
    }

    // 🔴 THE REGRESSION TEST. Once the launch has let go, re-deriving must say
    // "show" — even though this is exactly the moment the old code still read
    // `isSplashVisible == true` and re-hid.
    func test_notWithdrawn_onceLaunchLetsGo_evenBeforeHandOffBegins() {
        XCTAssertFalse(
            BottomModuleWindowController.shouldWithdraw(
                launchHoldsModule: false, withdrawnByScreen: false
            ),
            "a repeat install in the 32ms gap after the unhide must not re-hide the bars"
        )
    }

    // A screen that deliberately took the 126pt keeps them, launch or not.
    func test_withdrawn_whileScreenClaimsTheSpace() {
        XCTAssertTrue(
            BottomModuleWindowController.shouldWithdraw(
                launchHoldsModule: false, withdrawnByScreen: true
            )
        )
        XCTAssertTrue(
            BottomModuleWindowController.shouldWithdraw(
                launchHoldsModule: true, withdrawnByScreen: true
            )
        )
    }

    // 🔴 THE CASE THE OLD FALLBACK MISSED: installed, hidden, nobody asking
    // for it. The main window has to draw the bars itself.
    func test_inlineFallback_whenWindowIsInstalledButHidden() {
        XCTAssertTrue(
            BottomModuleWindowController.rendersInlineFallback(
                isShowingBars: false, withdrawnByScreen: false, isSplashVisible: false
            ),
            "an installed-but-hidden window must not suppress the fallback"
        )
    }

    // Never both: two sets of bars in two windows is its own defect.
    func test_noInlineFallback_whileTheWindowIsShowingThem() {
        XCTAssertFalse(
            BottomModuleWindowController.rendersInlineFallback(
                isShowingBars: true, withdrawnByScreen: false, isSplashVisible: false
            )
        )
    }

    // Hiding one must not reveal the other — the wizard needs the 126pt.
    func test_noInlineFallback_whenAScreenWithdrewTheModule() {
        XCTAssertFalse(
            BottomModuleWindowController.rendersInlineFallback(
                isShowingBars: false, withdrawnByScreen: true, isSplashVisible: false
            )
        )
    }

    // Under the splash there is nothing to draw: the bars sit at opacity 0 and
    // the overlay covers the app anyway.
    func test_noInlineFallback_underTheSplash() {
        XCTAssertFalse(
            BottomModuleWindowController.rendersInlineFallback(
                isShowingBars: false, withdrawnByScreen: false, isSplashVisible: true
            )
        )
    }

    // MARK: - Self-heal retry schedule
    //
    // The deferred branch above only helps if something actually retries. The
    // edge-triggered paths (one `.onAppear`, a `scenePhase` change, a one-shot
    // activation notification) can all be missed by a single launch, which is
    // how the module went missing for a whole session. These pin the
    // level-triggered chain that closes that hole.

    // The chain must start almost immediately — a user staring at a missing tab
    // bar shouldn't wait seconds for the first attempt.
    func test_firstRetryIsPrompt() throws {
        let first = try XCTUnwrap(BottomModuleWindowController.retryDelay(forAttempt: 0))
        XCTAssertLessThanOrEqual(first, 0.25)
        XCTAssertGreaterThan(first, 0)
    }

    // Delays must increase, so a genuinely scene-less launch doesn't spin.
    func test_retryDelaysIncreaseMonotonically() {
        var attempt = 0
        var previous = 0.0
        while let delay = BottomModuleWindowController.retryDelay(forAttempt: attempt) {
            XCTAssertGreaterThan(delay, previous, "attempt \(attempt) did not back off")
            previous = delay
            attempt += 1
        }
        XCTAssertGreaterThan(attempt, 1, "expected a multi-step retry schedule")
    }

    // The chain is bounded — it must terminate rather than retry forever.
    func test_retryScheduleTerminates() {
        var attempt = 0
        while BottomModuleWindowController.retryDelay(forAttempt: attempt) != nil {
            attempt += 1
            if attempt > 100 { break }
        }
        XCTAssertLessThanOrEqual(attempt, 100, "retry schedule never terminates")
        XCTAssertNil(BottomModuleWindowController.retryDelay(forAttempt: attempt))
    }

    // Total coverage should outlast a slow cold launch; a chain that gives up
    // in half a second would be no better than the single `.onAppear` it
    // replaces.
    func test_retryScheduleCoversSeveralSeconds() {
        var attempt = 0
        var total = 0.0
        while let delay = BottomModuleWindowController.retryDelay(forAttempt: attempt) {
            total += delay
            attempt += 1
        }
        XCTAssertGreaterThanOrEqual(total, 5.0)
    }

    // Out-of-range attempts are nil, not a crash or a negative delay.
    func test_retryDelayRejectsOutOfRangeAttempts() {
        XCTAssertNil(BottomModuleWindowController.retryDelay(forAttempt: -1))
        XCTAssertNil(BottomModuleWindowController.retryDelay(forAttempt: 9_999))
    }
}

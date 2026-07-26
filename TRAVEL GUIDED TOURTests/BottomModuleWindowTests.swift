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

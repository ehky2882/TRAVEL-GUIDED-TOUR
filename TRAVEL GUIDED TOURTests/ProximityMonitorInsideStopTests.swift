import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers `ProximityMonitor.decideInsideStopAction` — the pure helper
/// that decides whether (and which) already-inside geofenced stop to
/// trigger at tour start, and whether to play it now or hold it until
/// the current item (the intro) finishes.
///
/// Regression target: AMNH "Four Facades" stop 2 shared the intro's
/// coordinates, so the user was already inside its region when
/// monitoring began → CoreLocation never delivered a `didEnterRegion`
/// → the stop never played. `requestState` + this decision restore it.
final class ProximityMonitorInsideStopTests: XCTestCase {

    private let a = UUID()
    private let b = UUID()
    private let c = UUID()

    func test_noInsideStops_doesNothing() {
        let action = ProximityMonitor.decideInsideStopAction(
            insideStopIds: [],
            orderByStopId: [a: 0, b: 1],
            playedStopIds: [],
            isPlayerBusy: true
        )
        XCTAssertEqual(action, .doNothing)
    }

    func test_insideStop_playerBusy_defersUntilCurrentEnds() {
        // The repro: intro is playing, user is inside the geofenced stop.
        let action = ProximityMonitor.decideInsideStopAction(
            insideStopIds: [b],
            orderByStopId: [a: 0, b: 1, c: 2],
            playedStopIds: [a], // intro stop already seeded as played
            isPlayerBusy: true
        )
        XCTAssertEqual(action, .waitForCurrentToEnd(b))
    }

    func test_insideStop_playerIdle_playsNow() {
        let action = ProximityMonitor.decideInsideStopAction(
            insideStopIds: [b],
            orderByStopId: [a: 0, b: 1],
            playedStopIds: [],
            isPlayerBusy: false
        )
        XCTAssertEqual(action, .playNow(b))
    }

    func test_insideStopAlreadyPlayed_doesNothing() {
        // De-dupe: a stop already triggered (real crossing, or the UI's
        // started stop) must not fire again via the inside path.
        let action = ProximityMonitor.decideInsideStopAction(
            insideStopIds: [b],
            orderByStopId: [a: 0, b: 1],
            playedStopIds: [b],
            isPlayerBusy: false
        )
        XCTAssertEqual(action, .doNothing)
    }

    func test_overlappingInsideStops_picksFirstInTourOrder() {
        // User inside multiple regions at start → choose the lowest
        // `order` stop regardless of set iteration order.
        let action = ProximityMonitor.decideInsideStopAction(
            insideStopIds: [c, b, a],
            orderByStopId: [a: 5, b: 2, c: 9],
            playedStopIds: [],
            isPlayerBusy: true
        )
        XCTAssertEqual(action, .waitForCurrentToEnd(b))
    }

    func test_overlapping_skipsPlayedAndPicksNextInOrder() {
        // Lowest-order stop already played → fall to the next unplayed
        // one in tour order.
        let action = ProximityMonitor.decideInsideStopAction(
            insideStopIds: [a, b, c],
            orderByStopId: [a: 0, b: 1, c: 2],
            playedStopIds: [a],
            isPlayerBusy: false
        )
        XCTAssertEqual(action, .playNow(b))
    }

    func test_unmonitoredInsideId_isIgnored() {
        // An id not currently monitored (no order entry) is never chosen.
        let stray = UUID()
        let action = ProximityMonitor.decideInsideStopAction(
            insideStopIds: [stray],
            orderByStopId: [a: 0, b: 1],
            playedStopIds: [],
            isPlayerBusy: false
        )
        XCTAssertEqual(action, .doNothing)
    }
}

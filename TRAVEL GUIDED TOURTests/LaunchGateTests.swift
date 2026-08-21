import XCTest
import CoreLocation
@testable import TRAVEL_GUIDED_TOUR

/// The launch splash used to end on a fixed 2-second timer that waited for
/// nothing, so every expensive part of coming up — the map, the first
/// clustering pass, the bars' window, the camera flight — happened in front of
/// the user afterwards. `LaunchGate` is the readiness signal that replaced it.
///
/// The bounds are what these pin hardest. A gate with no ceiling turns a dead
/// network into an app that never opens, and a gate with no floor flashes the
/// wordmark and rips it away on a warm launch. Both are worse failures than the
/// lag being fixed.
final class LaunchGateTests: XCTestCase {

    // MARK: - Readiness

    func test_notReadyBeforeFloor_evenWhenEverythingIsLoaded() {
        XCTAssertFalse(
            LaunchGate.isReady(
                elapsed: LaunchGate.floor - 0.01,
                catalogLoaded: true,
                locationSettled: true
            )
        )
    }

    func test_readyAtFloor_whenCatalogAndLocationAreSettled() {
        XCTAssertTrue(
            LaunchGate.isReady(
                elapsed: LaunchGate.floor,
                catalogLoaded: true,
                locationSettled: true
            )
        )
    }

    func test_notReadyWhileCatalogIsEmpty() {
        XCTAssertFalse(
            LaunchGate.isReady(
                elapsed: LaunchGate.floor + 0.5,
                catalogLoaded: false,
                locationSettled: true
            )
        )
    }

    func test_notReadyWhileWaitingOnAGrantedLocationFix() {
        XCTAssertFalse(
            LaunchGate.isReady(
                elapsed: LaunchGate.floor + 0.5,
                catalogLoaded: true,
                locationSettled: false
            )
        )
    }

    /// The ceiling is the promise that the app always opens. Nothing below it
    /// is loaded here and it still hands off.
    func test_ceilingHandsOffRegardless() {
        XCTAssertTrue(
            LaunchGate.isReady(
                elapsed: LaunchGate.ceiling,
                catalogLoaded: false,
                locationSettled: false
            )
        )
    }

    func test_floorIsBelowCeiling() {
        XCTAssertLessThan(LaunchGate.floor, LaunchGate.ceiling)
    }

    // MARK: - Location settling

    func test_grantedWithNoFixIsTheOnlyStateWorthWaitingFor() {
        XCTAssertFalse(LaunchGate.locationSettled(status: .authorizedWhenInUse, hasFix: false))
        XCTAssertFalse(LaunchGate.locationSettled(status: .authorizedAlways, hasFix: false))
    }

    func test_aFixAlwaysSettles() {
        for status: CLAuthorizationStatus in [.notDetermined, .denied, .restricted, .authorizedWhenInUse, .authorizedAlways] {
            XCTAssertTrue(LaunchGate.locationSettled(status: status, hasFix: true))
        }
    }

    /// ⚠️ The load-bearing case. The permission alert is deliberately withheld
    /// until after hand-off, so treating `notDetermined` as unsettled would
    /// stall **every first launch** all the way to the ceiling.
    func test_notDeterminedIsSettled_becauseThePromptComesAfterHandOff() {
        XCTAssertTrue(LaunchGate.locationSettled(status: .notDetermined, hasFix: false))
    }

    func test_refusedPermissionSettles() {
        XCTAssertTrue(LaunchGate.locationSettled(status: .denied, hasFix: false))
        XCTAssertTrue(LaunchGate.locationSettled(status: .restricted, hasFix: false))
    }

    // MARK: - Choreography ramps

    func test_rampIsZeroBeforeItsDelayAndOneAfterItsWindow() {
        XCTAssertEqual(LaunchBloom.ramp(0.1, delay: 0.2, window: 0.4), 0)
        XCTAssertEqual(LaunchBloom.ramp(0.4, delay: 0.2, window: 0.4), 0.5, accuracy: 0.0001)
        XCTAssertEqual(LaunchBloom.ramp(0.6, delay: 0.2, window: 0.4), 1)
        XCTAssertEqual(LaunchBloom.ramp(1.0, delay: 0.2, window: 0.4), 1)
    }

    /// 🔴 Regression: the ramp must return EXACTLY 1, not 0.9999999999999999.
    ///
    /// Everything downstream treats 1 as "arrived" — `atlasPinBloom`
    /// short-circuits on it — so a pin that only approaches 1 keeps a
    /// fractional scale and opacity for the life of the session. These are the
    /// inputs that actually produced the inexact result.
    func test_rampReachesItsEndpointsExactly() {
        XCTAssertEqual(LaunchBloom.ramp(0.6, delay: 0.2, window: 0.4), 1)
        XCTAssertEqual(LaunchBloom.ramp(0.9, delay: 0.3, window: 0.6), 1)
        XCTAssertEqual(LaunchBloom.ramp(1.0, delay: 0.66, window: 0.34), 1)
        XCTAssertEqual(LaunchBloom.ramp(0.2, delay: 0.2, window: 0.4), 0)
    }

    func test_rampWithNoWindowIsAStep() {
        XCTAssertEqual(LaunchBloom.ramp(0.19, delay: 0.2, window: 0), 0)
        XCTAssertEqual(LaunchBloom.ramp(0.2, delay: 0.2, window: 0), 1)
    }

    /// The bloom travels outward: the nearest pin is always at least as far
    /// along as one further away.
    func test_bloomTravelsOutwardFromTheUser() {
        for step in stride(from: 0.0, through: 1.0, by: 0.05) {
            let near = LaunchBloom.pinProgress(handOff: step, normalisedDistance: 0)
            let mid = LaunchBloom.pinProgress(handOff: step, normalisedDistance: 0.5)
            let far = LaunchBloom.pinProgress(handOff: step, normalisedDistance: 1)
            XCTAssertGreaterThanOrEqual(near, mid, "at \(step)")
            XCTAssertGreaterThanOrEqual(mid, far, "at \(step)")
        }
    }

    /// 🔴 The one that matters for correctness rather than feel: every pin must
    /// be fully arrived by the end. A pin left mid-bloom would sit permanently
    /// scaled-down and semi-transparent on the map.
    func test_everyPinIsFullyArrivedByTheEnd() {
        for d in stride(from: 0.0, through: 1.0, by: 0.05) {
            XCTAssertEqual(LaunchBloom.pinProgress(handOff: 1, normalisedDistance: d), 1, "distance \(d)")
        }
    }

    func test_noPinStartsBeforeTheMarkLands() {
        let landing = LaunchBloom.markLanding.delay + LaunchBloom.markLanding.window
        for d in stride(from: 0.0, through: 1.0, by: 0.1) {
            XCTAssertEqual(
                LaunchBloom.pinProgress(handOff: landing - 0.01, normalisedDistance: d), 0,
                "distance \(d)"
            )
        }
    }

    func test_pinProgressIsMonotonic() {
        var previous = 0.0
        for step in stride(from: 0.0, through: 1.0, by: 0.02) {
            let value = LaunchBloom.pinProgress(handOff: step, normalisedDistance: 0.4)
            XCTAssertGreaterThanOrEqual(value, previous)
            previous = value
        }
    }

    func test_outOfRangeDistanceClamps() {
        XCTAssertEqual(
            LaunchBloom.pinProgress(handOff: 0.8, normalisedDistance: -5),
            LaunchBloom.pinProgress(handOff: 0.8, normalisedDistance: 0)
        )
        XCTAssertEqual(
            LaunchBloom.pinProgress(handOff: 0.8, normalisedDistance: 5),
            LaunchBloom.pinProgress(handOff: 0.8, normalisedDistance: 1)
        )
    }

    func test_staggerRunsInOrderAndFinishes() {
        let count = 6
        for step in stride(from: 0.0, through: 1.0, by: 0.05) {
            for i in 1..<count {
                XCTAssertGreaterThanOrEqual(
                    LaunchBloom.staggerProgress(handOff: step, index: i - 1, count: count),
                    LaunchBloom.staggerProgress(handOff: step, index: i, count: count)
                )
            }
        }
        for i in 0..<count {
            XCTAssertEqual(LaunchBloom.staggerProgress(handOff: 1, index: i, count: count), 1)
        }
    }

    /// A single item has no one to stagger against and must still arrive.
    func test_staggerHandlesASingleItem() {
        XCTAssertEqual(LaunchBloom.staggerProgress(handOff: 1, index: 0, count: 1), 1)
        XCTAssertEqual(LaunchBloom.staggerProgress(handOff: 0, index: 0, count: 1), 0)
    }

    func test_staggerClampsAnOutOfRangeIndex() {
        let count = 4
        XCTAssertEqual(
            LaunchBloom.staggerProgress(handOff: 0.8, index: 99, count: count),
            LaunchBloom.staggerProgress(handOff: 0.8, index: count - 1, count: count)
        )
    }

    // MARK: - LaunchState

    @MainActor
    func test_beginHandOffIsIdempotentAndOnlyLeavesTheSplashOnce() {
        let state = LaunchState()
        XCTAssertTrue(state.isSplashVisible)
        XCTAssertTrue(state.isCovering)

        state.beginHandOff()
        XCTAssertFalse(state.isSplashVisible, "the camera and the permission gate open here")
        XCTAssertTrue(state.isCovering, "the overlay is still on screen through the choreography")

        state.settle()
        XCTAssertFalse(state.isCovering)

        // A late backstop call must not drag the overlay back on screen.
        state.beginHandOff()
        XCTAssertFalse(state.isCovering)
    }

    @MainActor
    func test_settlingLeavesProgressComplete() {
        let state = LaunchState()
        state.beginHandOff()
        state.settle()
        // Anything still reading the value — a rebuilt map annotation, a rail
        // card scrolled into view later — must see "fully arrived", never a
        // frozen mid-animation number.
        XCTAssertEqual(state.handOffProgress, 1)
    }

    @MainActor
    func test_progressClamps() {
        let state = LaunchState()
        state.setHandOffProgress(-2)
        XCTAssertEqual(state.handOffProgress, 0)
        state.setHandOffProgress(7)
        XCTAssertEqual(state.handOffProgress, 1)
    }
}

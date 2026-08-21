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

    // MARK: - LaunchState

    @MainActor
    func test_handOffIsIdempotent() {
        let state = LaunchState()
        XCTAssertTrue(state.isSplashVisible)
        state.handOff()
        XCTAssertFalse(state.isSplashVisible)
        state.handOff()
        XCTAssertFalse(state.isSplashVisible)
    }
}

import XCTest
import CoreLocation
import MapKit
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
                locationSettled: true,
                imagesReady: true
            )
        )
    }

    func test_readyAtFloor_whenCatalogAndLocationAreSettled() {
        XCTAssertTrue(
            LaunchGate.isReady(
                elapsed: LaunchGate.floor,
                catalogLoaded: true,
                locationSettled: true,
                imagesReady: true
            )
        )
    }

    func test_notReadyWhileCatalogIsEmpty() {
        XCTAssertFalse(
            LaunchGate.isReady(
                elapsed: LaunchGate.floor + 0.5,
                catalogLoaded: false,
                locationSettled: true,
                imagesReady: true
            )
        )
    }

    func test_notReadyWhileWaitingOnAGrantedLocationFix() {
        XCTAssertFalse(
            LaunchGate.isReady(
                elapsed: LaunchGate.floor + 0.5,
                catalogLoaded: true,
                locationSettled: false,
                imagesReady: true
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
                locationSettled: false,
                imagesReady: true
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










    // MARK: - Photos

    func test_imagesNotReadyHoldsTheSplash() {
        XCTAssertFalse(
            LaunchGate.isReady(
                elapsed: LaunchGate.floor + 0.5,
                catalogLoaded: true,
                locationSettled: true,
                imagesReady: false
            )
        )
    }

    /// ⚠️ Photos are worth a moment, never the app. Past the ceiling we open
    /// regardless of what is still downloading.
    func test_ceilingOverridesImages() {
        XCTAssertTrue(
            LaunchGate.isReady(
                elapsed: LaunchGate.ceiling,
                catalogLoaded: true,
                locationSettled: true,
                imagesReady: false
            )
        )
    }

    func test_warmupDeadlineFitsInsideTheCeiling() {
        XCTAssertLessThan(LaunchImageWarmup.deadline, LaunchGate.ceiling)
    }

    // MARK: - The opening

    func test_theZoomRunsFromTheFirstFrame() {
        XCTAssertEqual(LaunchBloom.zoom.delay, 0, "the zoom IS the transition — nothing precedes it")
        XCTAssertEqual(LaunchBloom.zoomProgress(handOff: 0), 0)
        XCTAssertEqual(LaunchBloom.zoomProgress(handOff: LaunchBloom.zoom.window), 1)
    }

    /// The black must clear while the opening is still growing, not after — the
    /// whole complaint about the old fade was that it lingered over the thing
    /// it was supposed to reveal.
    func test_theBlackClearsBeforeTheOpeningFinishes() {
        XCTAssertLessThan(
            LaunchBloom.splashCut.delay + LaunchBloom.splashCut.window,
            LaunchBloom.zoom.delay + LaunchBloom.zoom.window
        )
    }

    /// The slide starts only once the opening is well under way, so the two
    /// read as one gesture continuing rather than two events.
    func test_theSlideStartsInsideTheZoom() {
        XCTAssertGreaterThan(LaunchBloom.assembly.delay, LaunchBloom.zoom.delay)
        XCTAssertLessThan(LaunchBloom.assembly.delay, LaunchBloom.zoom.delay + LaunchBloom.zoom.window)
    }

    /// 🔴 The haptic fires on the settle, and the settle is the end.
    ///
    /// Owner, 2026-08-22: *"the haptic is at the wrong beat, it's not synced
    /// with the things settling into place."* It used to fire mid-sequence.
    func test_theSettleIsTheEndOfTheHandOff() {
        XCTAssertEqual(LaunchBloom.settleFraction, 1.0, accuracy: 1e-9)
        XCTAssertEqual(LaunchBloom.assemblyProgress(handOff: LaunchBloom.settleFraction), 1)
    }

    // MARK: - The three-edge settle

    /// 🔴 THE INVARIANT THIS DESIGN WAS CHOSEN FOR.
    ///
    /// The bottom module, the search bar and the drawer come from three
    /// different edges and must land on ONE frame — owner, 2026-08-22: *"I like
    /// that the things settle at exactly the same time."* They all read
    /// `assemblyProgress`, so this asserts the thing that would break it: that
    /// there is exactly one curve, sampled everywhere.
    func test_theThreeEdgesShareOneProgressAtEveryInstant() {
        for step in stride(from: 0.0, through: 1.0, by: 0.01) {
            let value = LaunchBloom.assemblyProgress(handOff: step)
            let direct = LaunchBloom.ramp(
                step,
                delay: LaunchBloom.assembly.delay,
                window: LaunchBloom.assembly.window
            )
            XCTAssertEqual(value, direct, "at \(step)")
        }
    }




    /// The splash is a cut, not a dissolve.
    ///
    /// 🔴 Asserted in SECONDS, not in fractions of the hand-off. The previous
    /// version of this test said `splashCut.window <= 0.2` — a fraction — and
    /// when the hand-off went from 0.9s to 0.42s it started failing even though
    /// the cut had got *shorter* in real terms (0.162s → 0.160s). A fraction
    /// assertion measures nothing on its own; it silently re-scales under you.
    func test_theSplashCutIsAnActualCut() {
        let seconds = LaunchBloom.splashCut.window * LaunchBloom.duration
        XCTAssertLessThanOrEqual(seconds, 0.2, "a cut, not a dissolve")
        XCTAssertLessThan(
            LaunchBloom.splashCut.delay + LaunchBloom.splashCut.window,
            LaunchBloom.assembly.delay + LaunchBloom.assembly.window
        )
    }

    /// The whole thing has to stay under half a second — that is the point of
    /// this round. Owner, on the 0.9s version: *"slow and feels very lethargic."*
    func test_theHandOffStaysUnderHalfASecond() {
        XCTAssertLessThanOrEqual(LaunchBloom.duration, 0.5)
        XCTAssertLessThan(LaunchBloom.reducedMotionDuration, LaunchBloom.duration)
    }



    // MARK: - Photo warm-up selection

    func test_warmupTakesTheFirstCardsInRailOrderWithoutRepeats() {
        let a = TestFixtures.makeTour(title: "A", heroImageURL: "https://x/a.webp")
        let b = TestFixtures.makeTour(title: "B", heroImageURL: "https://x/b.webp")
        let rails = [
            HomeRail(id: "1", title: "Near you", tours: [a, b]),
            HomeRail(id: "2", title: "Iconic", tours: [a]),
        ]
        let urls = LaunchImageWarmup.warmupURLs(rails: rails)
        XCTAssertEqual(urls.map(\.absoluteString), ["https://x/a.webp", "https://x/b.webp"],
                       "a tour on two shelves must be fetched once")
    }

    func test_warmupIsCapped() {
        let tours = (0..<40).map { TestFixtures.makeTour(title: "T\($0)", heroImageURL: "https://x/\($0).webp") }
        let urls = LaunchImageWarmup.warmupURLs(rails: [HomeRail(id: "1", title: "R", tours: tours)])
        XCTAssertEqual(urls.count, LaunchImageWarmup.count)
    }

    func test_warmupSkipsUnusableURLs() {
        let bad = TestFixtures.makeTour(title: "Bad", heroImageURL: "")
        let good = TestFixtures.makeTour(title: "Good", heroImageURL: "https://x/g.webp")
        let urls = LaunchImageWarmup.warmupURLs(rails: [HomeRail(id: "1", title: "R", tours: [bad, good])])
        XCTAssertEqual(urls.map(\.absoluteString), ["https://x/g.webp"])
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

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

    /// 🔴 The black is cut UNDERNEATH the disc, never in view.
    ///
    /// It used to fade on its own ramp while the disc was still growing, and
    /// the two visibly came apart: the map appeared early and the "solid
    /// expanding mark" turned into a translucent blob over it. The cut may
    /// only happen once the disc covers the screen, and must be finished
    /// before the disc starts dissolving.
    func test_theBlackIsCutUnderneathTheDisc() {
        let covered = LaunchBloom.zoom.delay + LaunchBloom.zoom.window
        XCTAssertGreaterThanOrEqual(LaunchBloom.splashCut.delay, covered)
        XCTAssertLessThanOrEqual(
            LaunchBloom.splashCut.delay + LaunchBloom.splashCut.window,
            LaunchBloom.markDissolve.delay + LaunchBloom.markDissolve.window
        )
    }

    /// 🔴 THE ZOOM ENDS ON A BARE MAP. Nothing may arrive while the brass is
    /// still on screen — owner, 2026-08-22: *"after the brass circle goes away
    /// it should be a blank map screen. then the components start sliding
    /// in."*
    func test_nothingArrivesUntilTheBrassIsGone() {
        let zoomEnds = LaunchBloom.markDissolve.delay + LaunchBloom.markDissolve.window
        XCTAssertGreaterThanOrEqual(LaunchBloom.assembly.delay, zoomEnds)
        XCTAssertGreaterThanOrEqual(LaunchBloom.chrome.delay, zoomEnds)
        XCTAssertEqual(LaunchBloom.assemblyProgress(handOff: zoomEnds), 0)
        XCTAssertEqual(LaunchBloom.chromeProgress(handOff: zoomEnds), 0)
        XCTAssertEqual(LaunchBloom.drawerExpandProgress(handOff: zoomEnds), 0)
    }

    /// 🔴 The disc stays SOLID for the whole of its growth: it starts
    /// dissolving only once it covers the screen. Owner, 2026-08-22: *"it
    /// should stay as a solid as it expands."*
    func test_theDiscOnlyDissolvesOnceItCoversTheScreen() {
        XCTAssertGreaterThanOrEqual(
            LaunchBloom.markDissolve.delay,
            LaunchBloom.zoom.delay + LaunchBloom.zoom.window
        )
        // And the black is cut underneath it, never in view.
        XCTAssertGreaterThanOrEqual(LaunchBloom.splashCut.delay, LaunchBloom.zoom.delay + LaunchBloom.zoom.window)
        XCTAssertLessThanOrEqual(
            LaunchBloom.splashCut.delay + LaunchBloom.splashCut.window,
            LaunchBloom.markDissolve.delay + LaunchBloom.markDissolve.window
        )
    }

    /// The drawer opens only after the block it rode in on has landed.
    func test_theDrawerOpensAfterTheBlockLands() {
        XCTAssertGreaterThanOrEqual(
            LaunchBloom.drawerExpand.delay,
            LaunchBloom.assembly.delay + LaunchBloom.assembly.window
        )
    }

    /// 🔴 The haptic fires on the settle, and the settle is the end.
    ///
    /// Owner, 2026-08-22: *"the haptic is at the wrong beat, it's not synced
    /// with the things settling into place."* It used to fire mid-sequence.
    func test_theSettleIsTheEndOfTheHandOff() {
        XCTAssertEqual(LaunchBloom.settleFraction, 1.0, accuracy: 1e-9)
        XCTAssertEqual(LaunchBloom.assemblyProgress(handOff: LaunchBloom.settleFraction), 1)
    }

    // MARK: - The snap

    /// 🔴 THE INVARIANT THIS DESIGN WAS CHOSEN FOR.
    ///
    /// The drawer finishes opening and the top chrome lands on ONE frame —
    /// owner, 2026-08-22: *"at the end the drawer and the top components should
    /// 'snap' into place at exactly the same time. and when it 'snaps' into
    /// place, that's when the haptic happens."* So the two ramps must end
    /// together, and the haptic's instant must be that end.
    func test_theDrawerAndTheChromeLandOnTheSameFrame() {
        let chromeEnds = LaunchBloom.chrome.delay + LaunchBloom.chrome.window
        let drawerEnds = LaunchBloom.drawerExpand.delay + LaunchBloom.drawerExpand.window
        XCTAssertEqual(chromeEnds, drawerEnds, accuracy: 1e-9)
        XCTAssertEqual(LaunchBloom.settleFraction, drawerEnds, accuracy: 1e-9)

        for step in stride(from: 0.0, through: 1.0, by: 0.01) where step < drawerEnds {
            XCTAssertLessThan(LaunchBloom.chromeProgress(handOff: step), 1, "at \(step)")
            XCTAssertLessThan(LaunchBloom.drawerExpandProgress(handOff: step), 1, "at \(step)")
        }
        XCTAssertEqual(LaunchBloom.chromeProgress(handOff: drawerEnds), 1)
        XCTAssertEqual(LaunchBloom.drawerExpandProgress(handOff: drawerEnds), 1)
    }

    /// The module and the drawer ride in as one block, so they share one curve
    /// at every instant — that is what stops them arriving separately.
    func test_theBlockSharesOneProgressAtEveryInstant() {
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
        XCTAssertLessThanOrEqual(
            LaunchBloom.splashCut.delay + LaunchBloom.splashCut.window,
            LaunchBloom.assembly.delay
        )
    }

    /// The whole thing has to stay snappy — that is the point of this round.
    /// Owner, on the 1.05s staged assembly: *"slow and feels very lethargic."*
    ///
    /// ⚠️ 0.62s, not the 0.42s this once pinned: the sequence gained a third
    /// beat (zoom → slide → the drawer opening) and three beats inside 0.42s
    /// left none of them long enough to read. The ceiling is on the WHOLE
    /// hand-off, so a fourth beat has to buy its time from the other three.
    func test_theHandOffStaysSnappy() {
        XCTAssertLessThanOrEqual(LaunchBloom.duration, 0.7)
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

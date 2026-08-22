import Foundation
import CoreLocation
import Observation

/// When the launch splash may hand off to the app.
///
/// The splash used to end on `asyncAfter(.now() + 2.0)` — a fixed timer that
/// waited for nothing. `ContentView` did not exist until it fired, so at the two
/// second mark the app created `MKMapView` from scratch, clustered the whole
/// catalog for the first time, mounted the drawer, installed the mini-player's
/// window and then flew the camera from the fallback region to the user's
/// actual position. All of it in front of the user, which is what read as lag.
///
/// The fix is not to make that work faster but to do it **behind** the splash
/// and hand off only once it is done. That needs a readiness signal, which is
/// what this is.
///
/// The two bounds are as load-bearing as the readiness test itself:
/// - a **floor**, so a warm launch that is ready in 200 ms doesn't flash the
///   wordmark and rip it away again;
/// - a **ceiling**, so a dead network, a location fix that never arrives or a
///   stalled image fetch cannot hold the user on a black screen indefinitely.
///   Past the ceiling we hand off regardless — an app with a few photos still
///   loading beats no app.
enum LaunchGate {
    /// Shortest time the splash is ever shown.
    static let floor: TimeInterval = 1.2
    /// Longest time the splash is ever shown, ready or not.
    static let ceiling: TimeInterval = 3.0
    /// How often readiness is re-evaluated while the splash is up.
    static let pollInterval: TimeInterval = 0.1

    /// Whether the splash may hand off now.
    ///
    /// - Parameters:
    ///   - elapsed: seconds since launch.
    ///   - catalogLoaded: the catalog has tours (cache, bundle or network).
    ///   - locationSettled: see `locationSettled(status:hasFix:)`.
    ///   - imagesReady: the first screenful of card photos is in the image
    ///     cache, or its own deadline passed. See `LaunchImageWarmup`.
    static func isReady(
        elapsed: TimeInterval,
        catalogLoaded: Bool,
        locationSettled: Bool,
        imagesReady: Bool
    ) -> Bool {
        if elapsed >= ceiling { return true }
        guard elapsed >= floor else { return false }
        return catalogLoaded && locationSettled && imagesReady
    }

    /// Whether there is any point waiting longer for a location fix.
    ///
    /// ⚠️ Only a **granted** authorization with no fix yet is worth waiting on.
    /// `notDetermined` in particular must count as settled: the permission
    /// alert is deliberately not shown until after hand-off (a system alert
    /// over a black splash reads as a broken launch), so waiting on it would
    /// stall every first launch until the ceiling.
    static func locationSettled(status: CLAuthorizationStatus, hasFix: Bool) -> Bool {
        if hasFix { return true }
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return false
        default:
            return true
        }
    }
}

/// Where the launch frames the user on the map.
///
/// 🔴 **Not decoration.** The launch camera used to centre on the user, which
/// puts the location dot at the middle of the screen — *behind the drawer* at
/// its mid detent, where you cannot see it. Framing the user higher fixes that,
/// and it is also what gives the launch mark somewhere to travel to.
///
/// The splash's mark and the map camera BOTH read this, which is the point: the
/// mark has to land exactly where the dot will appear, and two constants would
/// drift apart the first time either was touched.
enum LaunchLayout {
    /// The user's position as a fraction of screen height, measured from the
    /// top. 0.5 would be dead centre (and behind the drawer).
    static let userScreenFraction: CGFloat = 0.30

    /// How far the camera's centre sits *south* of the user, as a fraction of
    /// the visible latitude span. Moving the camera south pushes the user north
    /// — i.e. up the screen.
    static var cameraOffsetFraction: CGFloat { 0.5 - userScreenFraction }

    /// The mark's landing point in a full-screen view's coordinate space.
    static func landingPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height * userScreenFraction)
    }
}

/// Whether the launch splash is still covering the app.
///
/// Injected app-wide because four places behave differently while it is up, and
/// all four are the point of the change:
/// - the camera resolves to the user's region **without** animation, so nobody
///   watches the map travel there from the fallback region;
/// - the mini-player + tab bar's window is installed but hidden (it sits at a
///   higher window level than the splash, so it would otherwise paint over it);
/// - the search bar and filter chips hold off-screen to the right;
/// - the drawer holds off-screen below.
@MainActor
@Observable
final class LaunchState {
    /// Where the launch is up to.
    enum Phase {
        /// The splash is resting, the app is being built behind it.
        case splash
        /// The hand-off choreography is playing.
        case handingOff
        /// Done. The overlay is gone and nothing launch-related is animating.
        case settled
    }

    private(set) var phase: Phase = .splash

    /// 0 → 1 across the hand-off. **Every part of the choreography reads this
    /// one value** — the mark's rise, the ripple, the three-edge assembly, the
    /// rail stagger — each through its own ramp in `LaunchBloom`.
    private(set) var handOffProgress: Double = 0

    /// True only while the splash is resting. The launch camera resolves
    /// without animation and the permission alert is withheld while this holds.
    var isSplashVisible: Bool { phase == .splash }

    /// True while the overlay is still on screen (resting or handing off).
    var isCovering: Bool { phase != .settled }

    /// Begin the hand-off. Idempotent — the poll loop and any backstop can both
    /// call it.
    func beginHandOff() {
        guard phase == .splash else { return }
        phase = .handingOff
    }

    /// Drive the choreography. Called inside a `withAnimation`.
    func setHandOffProgress(_ value: Double) {
        handOffProgress = min(max(value, 0), 1)
    }

    /// Tear the overlay down once the choreography has finished.
    func settle() {
        phase = .settled
        handOffProgress = 1
    }
}

/// The ramps that turn one hand-off progress value into per-element timing.
///
/// Pure arithmetic, so the whole choreography's shape is unit-testable without
/// a simulator — which matters because none of it can be *watched* in CI.
enum LaunchBloom {
    /// A sub-animation of the hand-off: starts at `delay`, runs for `window`,
    /// both expressed as fractions of the whole. Returns its own 0→1.
    static func ramp(_ progress: Double, delay: Double, window: Double) -> Double {
        guard window > 0 else { return progress >= delay ? 1 : 0 }
        // 🔴 The endpoints are SNAPPED, and on the computed fraction rather
        // than on `progress` against `delay + window`.
        //
        // `(progress - delay) / window` lands on 0.9999999999999999 for plenty
        // of ordinary inputs, and everything downstream treats 1 as "arrived".
        //
        // ⚠️ Comparing `progress >= delay + window` does NOT fix it — that sum
        // carries its own error (0.2 + 0.4 is 0.6000000000000001, so an exact
        // 0.6 fails the test and falls through to the inexact division). The
        // tolerance has to sit on the result.
        let t = (progress - delay) / window
        if t <= 0 { return 0 }
        if t >= 1 - Double.ulpOfOne.squareRoot() { return 1 }
        return t
    }

    // MARK: - Phase fractions
    //
    // Named rather than inlined so the sequence can be read in one place and
    // retimed without hunting through five views.

    /// The wordmark lifts away first.
    static let wordmarkLift = (delay: 0.02, window: 0.22)

    /// The brass mark rises from the wordmark's position onto the user's dot.
    ///
    /// ⚠️ `delay + window` must equal `arrival.delay`: the ripple, the blue dot
    /// and the haptic all key off the instant the mark touches down.
    /// `landingFraction` below is the single expression of that, and a test
    /// pins it.
    static let markLanding = (delay: 0.045, window: 0.47)

    /// The splash CUTS rather than dissolving — short and linear, so the black
    /// is gone before you register it and the assembly is what you watch.
    static let splashCut = (delay: 0.22, window: 0.18)

    /// Ripple + blue dot + haptic, from the moment the mark lands.
    static let arrival = (delay: 0.515, window: 0.34)

    /// 🔴 THE THREE-EDGE SETTLE — the thing this design was chosen for.
    ///
    /// The bottom module (from below), the search bar and filter chips (from
    /// the right) and the drawer (from below) all share **this one delay and
    /// this one window**. They start together and land together on a single
    /// frame; the drawer travels furthest so it simply moves fastest.
    ///
    /// ⚠️ Do not give any of the three its own timing. Owner decision
    /// 2026-08-22: *"I like that the things settle at exactly the same time."*
    /// A test asserts all three resolve to the same value at every step.
    static let assembly = (delay: 0.31, window: 0.38)

    /// Rail cards ease in behind the settled drawer.
    static let rails = (delay: 0.66, window: 0.30)

    /// The instant the mark touches down, as a fraction of the hand-off.
    /// The haptic fires here, and `arrival` starts here.
    static var landingFraction: Double { markLanding.delay + markLanding.window }

    /// Progress of one staggered item in a sequence (rail cards).
    static func staggerProgress(handOff: Double, index: Int, count: Int) -> Double {
        guard count > 1 else { return ramp(handOff, delay: rails.delay, window: rails.window) }
        let d = Double(min(max(index, 0), count - 1)) / Double(count - 1)
        let share = 0.6
        let lead = rails.window * (1 - share) * d
        return ramp(handOff, delay: rails.delay + lead, window: rails.window * share)
    }

    /// Progress of the three-edge assembly. One function, so the module, the
    /// chrome and the drawer physically cannot drift apart.
    static func assemblyProgress(handOff: Double) -> Double {
        ramp(handOff, delay: assembly.delay, window: assembly.window)
    }
}

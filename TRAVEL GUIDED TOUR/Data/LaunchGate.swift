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
/// - a **ceiling**, so a dead network or a location fix that never arrives
///   cannot hold the user on a black screen indefinitely. Past the ceiling we
///   hand off regardless — an app on the fallback region beats no app.
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
    static func isReady(
        elapsed: TimeInterval,
        catalogLoaded: Bool,
        locationSettled: Bool
    ) -> Bool {
        if elapsed >= ceiling { return true }
        guard elapsed >= floor else { return false }
        return catalogLoaded && locationSettled
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

/// Whether the launch splash is still covering the app.
///
/// Injected app-wide because three places behave differently while it is up,
/// and all three are the point of the change:
/// - the camera resolves to the user's region **without** animation, so nobody
///   watches the map travel there from the fallback region;
/// - the mini-player + tab bar's window is installed but hidden (it sits at a
///   higher window level than the splash, so it would otherwise paint on top
///   of it);
/// - the drawer holds off-screen and rises once the splash clears, which is
///   the one piece of motion the hand-off keeps.
@MainActor
@Observable
final class LaunchState {
    /// Where the launch is up to.
    enum Phase {
        /// The splash is resting, the app is being built behind it.
        case splash
        /// The hand-off choreography is playing: the mark lands, the pins bloom.
        case handingOff
        /// Done. The overlay is gone and nothing launch-related is animating.
        case settled
    }

    private(set) var phase: Phase = .splash

    /// 0 → 1 across the hand-off. **Every part of the choreography reads this
    /// one value** — the mark's contraction, the ripple, the pin bloom, the
    /// rail stagger — each through its own ramp in `LaunchBloom`.
    ///
    /// 🔴 It is a stored, animated `Double` rather than a set of `.transition`s
    /// for one specific reason: the pins are **MapKit annotations**, and MapKit
    /// rebuilds annotation views as the region changes. An insertion animation
    /// would re-fire every time the map settled — and this map emits settle
    /// frames for seconds after any camera move, so the bloom would replay on
    /// every pan, forever. A rebuilt annotation reading a *value* just picks up
    /// wherever the number is now, which is nothing at all once it reaches 1.
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
        return min(max((progress - delay) / window, 0), 1)
    }

    // MARK: - Phase fractions
    //
    // Named rather than inlined so the sequence can be read in one place and
    // retimed without hunting through four views.

    /// The wordmark lifts away first.
    static let wordmarkLift = (delay: 0.0, window: 0.28)
    /// The mark contracts from the splash circle to the location dot.
    ///
    /// ⚠️ `delay + window` must equal `arrival.delay` and `bloom.delay`: the
    /// ripple, the blue dot and the first pin all key off the instant the mark
    /// touches down. Retime one and retime all four, or the bloom starts before
    /// the thing it is supposed to be radiating from has arrived.
    static let markLanding = (delay: 0.05, window: 0.47)
    /// Ripple + blue dot, from the moment the mark lands.
    static let arrival = (delay: 0.52, window: 0.34)
    /// The black ground fades, revealing the map already built underneath.
    static let groundFade = (delay: 0.28, window: 0.44)
    /// Pins bloom outward; the furthest starts as the nearest finishes.
    static let bloom = (delay: 0.52, window: 0.48)
    /// Rail cards stagger in behind the rising drawer.
    static let rails = (delay: 0.66, window: 0.34)

    /// Progress of one pin's own arrival.
    ///
    /// The bloom travels outward from the user, so a pin's delay is set by how
    /// far away it is: the nearest starts immediately, the furthest starts last.
    /// - Parameter normalisedDistance: 0 = at the user, 1 = furthest pin on screen.
    static func pinProgress(handOff: Double, normalisedDistance: Double) -> Double {
        let d = min(max(normalisedDistance, 0), 1)
        // Each pin's own animation is `share` of the bloom window; the rest of
        // the window is spent waiting its turn.
        let share = 0.55
        let lead = bloom.window * (1 - share) * d
        return ramp(handOff, delay: bloom.delay + lead, window: bloom.window * share)
    }

    /// Progress of one staggered item in a sequence (rail cards).
    static func staggerProgress(handOff: Double, index: Int, count: Int) -> Double {
        guard count > 1 else { return ramp(handOff, delay: rails.delay, window: rails.window) }
        let d = Double(min(max(index, 0), count - 1)) / Double(count - 1)
        let share = 0.6
        let lead = rails.window * (1 - share) * d
        return ramp(handOff, delay: rails.delay + lead, window: rails.window * share)
    }
}

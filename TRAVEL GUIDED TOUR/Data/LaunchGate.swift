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
    private(set) var isSplashVisible = true

    /// Hand off from the splash to the app. Idempotent — the poll loop and any
    /// backstop can both call it.
    func handOff() {
        guard isSplashVisible else { return }
        isSplashVisible = false
    }
}

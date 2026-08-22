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

/// Where the zoom opens from.
///
/// The splash mark and the mask that reveals the app share this point — the
/// app comes through the opening the mark leaves, so if the two disagreed the
/// app would appear to open out of thin air next to the logo.
///
/// ⚠️ There is deliberately NO framing constant here any more. An earlier
/// revision shifted the launch camera so the user sat in the upper third, to
/// give a travelling mark somewhere to fly to. That was the tail wagging the
/// dog — owner, 2026-08-22: *"it means moving the location up so that it's not
/// centred... I don't think it works."* The mark no longer travels, so the
/// camera centres on the user like everything else in the app.
enum LaunchZoom {
    /// Vertical position of the opening, as a fraction of screen height.
    ///
    /// 🔴 EXACTLY THE CENTRE, because that is where the map puts the user's
    /// blue dot: the map view fills the screen and the launch camera resolves
    /// centred on the user, so the dot lands at the middle of it. The mark has
    /// to open from that same point or it does not read as *becoming* the dot.
    /// Owner decision 2026-08-22. Was 0.46, which sat visibly above it.
    static let originFraction: CGFloat = 0.5

    static func origin(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height * originFraction)
    }

    /// Radius the opening starts at — the mark's own radius, so it begins
    /// exactly at the edge of the circle you were just looking at.
    static let startRadius: CGFloat = 22

    /// The opening's radius at a given progress: from the mark's own radius
    /// out to a circle that clears the furthest corner, so it finishes by
    /// leaving the screen rather than by reaching an arbitrary size.
    ///
    /// 🔴 Lives here because TWO views have to agree on it exactly — the hole
    /// punched in the splash's black, and (were it ever reinstated) any mask on
    /// the app. Two copies of this arithmetic is precisely the drift that makes
    /// a container transform read as a seam.
    static func radius(progress: Double, in size: CGSize) -> CGFloat {
        let origin = origin(in: size)
        let corner = CGPoint(
            x: origin.x > size.width / 2 ? 0 : size.width,
            y: origin.y > size.height / 2 ? 0 : size.height
        )
        let full = (pow(corner.x - origin.x, 2) + pow(corner.y - origin.y, 2)).squareRoot()
        return startRadius + (full - startRadius) * progress
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

    /// How long the whole hand-off takes.
    ///
    /// ⚠️ Lives HERE, beside the fractions it scales, and not in the App —
    /// otherwise every timing assertion has to be written as a fraction, and a
    /// fraction silently changes meaning the moment the duration moves. That
    /// exact trap fired once: a test pinned the splash cut at "≤ 0.2 of the
    /// hand-off", the hand-off went 0.9s → 0.42s, and the assertion started
    /// failing while the cut was in real terms *shorter* than before.
    ///
    /// Was 1.05s (staged assembly), then 0.9s, then 0.42s — now 0.62s,
    /// because the sequence gained a third beat (the drawer opening) and 0.42s
    /// could not hold three of them without any one reading as a jump.
    static let duration: TimeInterval = 0.62

    /// Reduce Motion gets a plain cross-dissolve, and a shorter one.
    static let reducedMotionDuration: TimeInterval = 0.28

    // MARK: - Phase fractions
    //
    // Three beats, in this order. Owner direction 2026-08-22:
    //
    //   1. THE ZOOM. The brass mark expands as a SOLID disc and dissolves into
    //      the map — Apple's zoom transition / Material's container transform.
    //      ⚠️ It stays solid the whole way: *"i dont like that the brass circle
    //      becomes a ring and that there's blue behind it. it should stay as a
    //      solid as it expands."* What it leaves behind is a BARE MAP — no
    //      chrome of any kind is on screen yet.
    //   2. THE SLIDE. The bottom module rises as ONE BLOCK — tab bar,
    //      mini-player and the drawer *in its closed position* — while the
    //      search bar and chips come in from the right.
    //   3. THE OPENING. The drawer expands from closed to its mid detent, and
    //      finishes on the SAME FRAME the top chrome lands. That shared frame
    //      is the snap, and where the haptic fires.
    //
    // 🔴 What made an earlier version lethargic was not its duration — it was
    // that the destination did not exist yet when the transition ended, so you
    // sat watching furniture arrive. The zoom reveals a map that is already
    // built and already still; only the chrome moves after it.

    /// The wordmark goes first and fast — it is not part of the gesture.
    static let wordmarkLift = (delay: 0.0, window: 0.14)

    /// The disc's growth, from the mark's 44pt to covering the screen. Runs
    /// from the very first frame: this IS the transition.
    static let zoom = (delay: 0.0, window: 0.34)

    /// The disc dissolving into the map behind it — and it starts only once
    /// the disc COVERS the screen, so the brass is solid for the whole of its
    /// growth and what is left when it goes is a bare map.
    static let markDissolve = (delay: 0.34, window: 0.14)

    /// The black is cut while the disc is covering the screen, so the cut
    /// itself is never visible.
    static let splashCut = (delay: 0.34, window: 0.02)

    /// 🔴 THE SLIDE — the module and the closed drawer as ONE BLOCK.
    ///
    /// Tab bar, mini-player and drawer share one delay and one window so they
    /// travel as a single object. Owner: *"the entire bottom module should
    /// slide up together… right now the miniplayer and bottom tabs are already
    /// in place and then the drawer slides up from behind it."*
    static let assembly = (delay: 0.52, window: 0.20)

    /// 🔴 THE OPENING — the drawer alone, closed → mid detent, after the block
    /// has landed.
    static let drawerExpand = (delay: 0.72, window: 0.28)

    /// The search bar and chips travel the whole of the second half, so they
    /// land on the frame the drawer finishes opening. ⚠️ Its end must equal
    /// `drawerExpand`'s end — that shared frame is the snap. A test pins it.
    static let chrome = (delay: 0.52, window: 0.48)

    /// The instant everything comes to rest — where the haptic fires.
    ///
    /// ⚠️ Owner note 2026-08-22: *"the haptic is at the wrong beat, it's not
    /// synced with the things settling into place."* It fires on the frame the
    /// drawer finishes opening and the top chrome lands, which is the end.
    static var settleFraction: Double { drawerExpand.delay + drawerExpand.window }

    /// 🔴 HOW LATE THE HAPTIC FIRES, past the settle's nominal instant.
    ///
    /// The bump is scheduled off a WALL CLOCK while the settle is drawn by the
    /// render server, so any frame the device drops puts the buzz ahead of the
    /// thing it is meant to punctuate. Reported from a device: *"haptic feels
    /// early."* A touch late reads as the tail of the movement; early reads as
    /// a mistake, so the bias goes one way deliberately.
    ///
    /// ⚠️ If the settle ever gains frames back, this can shrink — but do not
    /// take it to zero: a wall clock and a render clock never agree exactly.
    static let settleLatency: TimeInterval = 0.07

    /// Progress of the slide: the module and the closed drawer, one value, so
    /// they physically cannot drift apart.
    static func assemblyProgress(handOff: Double) -> Double {
        ramp(handOff, delay: assembly.delay, window: assembly.window)
    }

    /// Progress of the drawer's opening, closed → mid detent.
    static func drawerExpandProgress(handOff: Double) -> Double {
        ramp(handOff, delay: drawerExpand.delay, window: drawerExpand.window)
    }

    /// Progress of the top chrome's arrival from the right.
    static func chromeProgress(handOff: Double) -> Double {
        ramp(handOff, delay: chrome.delay, window: chrome.window)
    }

    /// Progress of the opening.
    static func zoomProgress(handOff: Double) -> Double {
        ramp(handOff, delay: zoom.delay, window: zoom.window)
    }
}

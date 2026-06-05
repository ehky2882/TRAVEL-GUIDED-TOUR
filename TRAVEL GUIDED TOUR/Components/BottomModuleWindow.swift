import SwiftUI
import UIKit

/// State shared between `ContentView` (in the main window) and the
/// mini-player + tab bar (in a second, higher-level UIWindow). Both
/// sides read & write through this object — single source of truth
/// for tab selection and full-player sheet presentation.
///
/// **Why an `@Observable` object instead of `@State`?** Because the
/// mini-player + tab bar live in a *separate UIWindow* now (so they
/// can sit z-above the UIKit-presented tour-detail modal — the
/// owner-requested "comes up from behind the bottom module" look).
/// `@State` is per-view-hierarchy; an `@Observable` injected via
/// `@Environment` spans both windows.
@MainActor
@Observable
final class AppSharedState {
    /// Currently selected tab. Mutated by the tab bar (in the second
    /// window), read by `ContentView` (in the main window) to decide
    /// which tab content to render.
    var selectedTab: AtlasTab = .home
    /// Drives the full-player sheet opened by tapping the
    /// mini-player. Lives here because the tap originates in the
    /// second window's `MiniPlayerBar` but the sheet presents from
    /// the main window's content.
    var showingFullPlayer: Bool = false
    /// The stop currently being played, when known. `nil` means
    /// no stop-level identity (no audio playing, intro audio
    /// playing, or audio whose owner didn't record a stop id).
    /// `TourDetailView` reads this to animate a now-playing
    /// indicator next to the matching stop row. Set from every
    /// site that triggers stop-level playback:
    /// `PlayerView.playStop`, `ProximityMonitor.handleEntry`, and
    /// `TourDetailView.handlePrimaryAction` (Start Tour from the
    /// inline button row).
    var currentPlayingStopId: UUID? = nil
}

/// Installs and tears down the secondary `UIWindow` that hosts the
/// mini-player + tab bar at a higher window level than the main
/// content window. This lets UIKit modal presentations in the main
/// window slide up *behind* the mini-player + tab bar — the
/// architecture Apple Music uses for its persistent now-playing
/// strip.
///
/// Lifecycle: `install(rootView:in:)` is called once from the
/// `App` body's `.onAppear`, with the SwiftUI root that should
/// render in the second window (i.e. the `MiniPlayerBar` +
/// `AtlasTabBar` VStack, with shared state + environments
/// injected). The window is retained on this object until app
/// termination — there's no need to tear it down per
/// presentation.
@MainActor
final class BottomModuleWindowController {
    private var window: UIWindow?

    /// Installs the secondary window. Idempotent — calling again is a no-op.
    /// `rootView` is built lazily so it can capture the latest environment values.
    /// `interactiveBottomInset` is the height of the bottom strip
    /// where the window's content actually paints — touches above
    /// it are passed through to the main window.
    func install<Root: View>(
        interactiveBottomInset: CGFloat,
        @ViewBuilder rootView: () -> Root
    ) {
        guard window == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        let w = PassThroughWindow(windowScene: scene)
        // One level above .normal so this window sits on top of
        // every modal presentation (UIKit modals default to .normal
        // level). The level is a `CGFloat`, so we add a small
        // positive increment.
        w.windowLevel = UIWindow.Level(UIWindow.Level.normal.rawValue + 1)
        w.backgroundColor = .clear
        w.isOpaque = false
        w.interactiveBottomInset = interactiveBottomInset

        let host = UIHostingController(rootView: rootView())
        host.view.backgroundColor = .clear
        w.rootViewController = host

        w.isHidden = false
        window = w
    }

    /// Mirrors the app-level color-scheme preference onto the
    /// secondary window's `overrideUserInterfaceStyle`. SwiftUI's
    /// `.preferredColorScheme(...)` only propagates into a window
    /// owned by a `WindowGroup`; it does not reach a manually-
    /// created `UIWindow` hosting a `UIHostingController`. Without
    /// this bridge, the second window's trait collection always
    /// follows SYSTEM appearance and the dynamic-provider colors
    /// (e.g. `secondaryBackgroundUIColor`) resolve to the wrong
    /// shade when the user picks an appearance in Settings that
    /// differs from the system.
    func apply(preference: ColorSchemePreference) {
        guard let window else { return }
        switch preference {
        case .system: window.overrideUserInterfaceStyle = .unspecified
        case .light:  window.overrideUserInterfaceStyle = .light
        case .dark:   window.overrideUserInterfaceStyle = .dark
        }
    }

    /// Hides or shows the secondary window. Used to clear the
    /// mini-player + tab bar out of the way while the full-screen
    /// `PlayerView` cover is up — the window sits one level above
    /// modal presentations (see `install`), so a `.fullScreenCover`
    /// in the main window would otherwise show *under* it. Hiding the
    /// whole window is purely a visibility toggle; it doesn't touch
    /// the mini-player's own layout or design.
    func setHidden(_ hidden: Bool) {
        window?.isHidden = hidden
    }
}

/// A `UIWindow` whose hit-testing returns nil for any point that
/// doesn't land on an actual interactive subview. Lets touches in
/// the transparent areas (everything except the mini-player + tab
/// bar strip at the bottom) pass through to the main window
/// underneath. Without this override, the second window would
/// absorb every touch in its bounds — meaning the map, drawer,
/// etc. would all become un-tappable.
///
/// The rule we apply: walk up the responder chain from the hit view
/// to this window. If every view in the chain is either (a) the
/// window itself, (b) the root view controller's view, or (c) a
/// container view that has no `UIControl` / gesture-recognizer-
/// bearing leaf at this point, then no real interactive target
/// claims the touch — pass it through.
///
/// In practice, the easiest robust check is: if the topmost hit
/// view's actual leaf-level frame in window coordinates falls
/// OUTSIDE the bottom-inset strip, treat it as pass-through. That
/// way every touch above the mini-player + tab bar's vertical
/// region goes to the main window regardless of what SwiftUI's
/// hosting layout decided to place there (transparent Spacers etc.
/// can claim hits at the UIKit level even though they have no
/// gesture).
final class PassThroughWindow: UIWindow {
    /// The height (in points, from the bottom of the screen) of the
    /// strip the window's content actually paints. Touches above
    /// this strip are passed through to the main window.
    var interactiveBottomInset: CGFloat = 0

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Anything above the painted bottom strip is decorative
        // (transparent Spacers / VStacks in the SwiftUI tree) and
        // must pass through to the main window. We decide
        // geometrically off the point alone — checking the hit view
        // identity is unreliable because SwiftUI often returns the
        // hosting view itself even for taps on actual Buttons.
        let topOfStrip = bounds.height - interactiveBottomInset
        if point.y < topOfStrip {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}

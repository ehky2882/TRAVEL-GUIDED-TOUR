import SwiftUI
import UIKit
import OSLog

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
    /// While true the mini-player and tab bar are withdrawn entirely — the
    /// secondary window is hidden and the inline fallback stops rendering.
    ///
    /// Only the tour wizard sets this, and only because it needs the 126pt
    /// those bars occupy: no step of it may scroll (owner rule, 2026-08-20),
    /// and a quarter of the screen reserved for controls that do nothing while
    /// you are making a tour is the cheapest height to buy back. Reverting is
    /// one Bool — see `CreateTourWizardView.hidesBottomModule`, which is the
    /// only thing that ever writes here.
    ///
    /// ⚠️ Whoever sets this true owns setting it false again. The bars going
    /// missing for a whole session is a failure this app has shipped three
    /// times; the wizard therefore drives it from `MakerView`'s presentation
    /// state — which always resolves — rather than from its own lifecycle.
    var hidesBottomModule: Bool = false
    /// A list opened from a share link, held until `ContentView` can present
    /// it. Lives here rather than in `TourListService` because it is view
    /// state belonging to one incoming link, not part of the user's own
    /// lists — and because the link arrives at the App, which has no other
    /// channel into the content window.
    var sharedList: SharedListPresentation? = nil
}

/// A list arriving from outside the app, with its items already fetched so the
/// screen can render without a second round-trip.
struct SharedListPresentation: Identifiable, Equatable {
    let list: TourList
    let items: [TourListItem]
    var id: UUID { list.id }
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
/// What `install()` should do given the current state. Extracted as a
/// pure value so the cold-launch recovery logic is unit-testable
/// without a live `UIWindowScene` (see `BottomModuleWindowTests`).
enum BottomModuleInstallOutcome: Equatable {
    /// The window already exists — calling again is a no-op.
    case alreadyInstalled
    /// A foreground-active scene is available — build the window now.
    case installNow
    /// No active scene yet (the cold-launch race) — defer and retry
    /// once a scene activates instead of silently giving up.
    case deferUntilActive
}

/// `@Observable` so the main window can watch `isInstalled` and render the
/// mini-player + tab bar inline whenever this secondary window is absent. That
/// fallback is what makes the bars unconditional — see `isInstalled`.
@MainActor
@Observable
final class BottomModuleWindowController {
    private var window: UIWindow?
    /// One-shot observer that retries the install when a scene
    /// activates, for the cold-launch case where `install()` ran
    /// before any window scene reached `.foregroundActive`. Removed
    /// as soon as the window is installed.
    private var activationObserver: NSObjectProtocol?
    /// The most recent color-scheme preference handed to `apply(...)`.
    /// Cached so a *deferred* install (which happens after the App's
    /// `.onAppear` already called `apply`) can re-apply it — otherwise
    /// the recovered window would be stuck on SYSTEM appearance.
    private var lastPreference: ColorSchemePreference = .system
    /// The most recent interactive-strip height. Cached for the same reason as
    /// `lastPreference`: a *deferred* install must not lose an update that
    /// arrived before the window existed.
    private var lastInteractiveBottomInset: CGFloat?
    /// Whether the module is currently withdrawn. Stored for the same reason as
    /// `lastPreference`: a *deferred* install must not come back on screen
    /// after something already asked for it to be hidden.
    private var isHiddenByRequest = false
    /// Pending self-heal retry, so only one chain is ever in flight.
    private var retryWorkItem: DispatchWorkItem?
    /// How many self-heal retries have been scheduled so far.
    private var retryAttempt = 0

    private static let log = Logger(subsystem: "com.dozent.app", category: "BottomModuleWindow")

    /// Delay before self-heal retry number `attempt` (0-based), or `nil` once
    /// we've exhausted the schedule.
    ///
    /// **Why a retry chain at all, when there are already two triggers?** Every
    /// existing trigger is *edge*-driven: `ContentView`'s `.onAppear` (fires
    /// once, ~2s after launch when the splash swaps out), a `scenePhase`
    /// *change* to `.active`, and a one-shot `UIScene.didActivateNotification`.
    /// If the scene isn't `.foregroundActive` at the `.onAppear` moment AND no
    /// later edge arrives — the app launched straight into `.foregroundActive`
    /// so `scenePhase` never *changes*, and the activation notification already
    /// fired before we were listening — nothing tries again, and the
    /// mini-player + tab bar are missing **for the entire session** until the
    /// user force-quits. That matches the reported symptom exactly (missing on
    /// first launch after installing a build; fine after a relaunch).
    ///
    /// A level-triggered retry closes that hole without needing to know which
    /// edge was missed. `install()` is idempotent and cheap, so retrying costs
    /// nothing once the window exists.
    static func retryDelay(forAttempt attempt: Int) -> Double? {
        let schedule: [Double] = [0.15, 0.4, 1.0, 2.0, 4.0]
        guard attempt >= 0, attempt < schedule.count else { return nil }
        return schedule[attempt]
    }

    /// Whether the secondary window currently exists.
    ///
    /// Read by `ContentView`, which renders the mini-player + tab bar **inline in
    /// the main window** while this is `false`. That fallback exists because
    /// every previous fix here was a bet on scene timing, and the bars kept
    /// going missing anyway: they lived *only* in this window, so any failure to
    /// install meant no bars at all, with nothing to fall back to. Rendering
    /// them in the ordinary SwiftUI hierarchy can't fail for scene-lifecycle
    /// reasons. The only thing lost in fallback mode is z-order above UIKit
    /// modals, which is a far better failure than an app with no tab bar.
    var isInstalled: Bool { window != nil }

    /// Update the height of the bottom strip in which this window claims
    /// touches. **Must** track the module's real painted height, not a constant:
    /// content can appear *above* the mini-player (the Group Listen banner), and
    /// anything outside the claimed strip is visible but completely untappable —
    /// which is exactly how the banner's "Leave" button ended up dead.
    /// Never shrinks below `AtlasBottomModule.height()`. The measurement can
    /// legitimately be *larger* than that constant (content above the
    /// mini-player), which is the whole reason it's measured — but it must never
    /// come in smaller, because a transient value mid-animation (the module
    /// animates on `nowPlayingTour` changes, and `onGeometryChange` reports
    /// intermediate frames) would shrink the touch strip and leave part of the
    /// painted bars visible but dead. Clamping makes an under-measurement
    /// harmless instead of turning it into an untappable tab bar.
    func setInteractiveBottomInset(_ inset: CGFloat) {
        let clamped = max(inset, AtlasBottomModule.height())
        guard clamped > 0, clamped != lastInteractiveBottomInset else { return }
        lastInteractiveBottomInset = clamped
        (window as? PassThroughWindow)?.interactiveBottomInset = clamped
    }

    /// Withdraw or restore the whole module. A hidden `UIWindow` does not
    /// hit-test, which is the point: leaving it visible-but-empty would keep
    /// `PassThroughWindow` claiming the bottom strip and swallow taps on
    /// whatever now sits there — the way the Group Listen banner's Leave button
    /// ended up dead. Hiding the window removes the claim with it.
    ///
    /// Idempotent, and survives a deferred install (see `isHiddenByRequest`).
    func setHidden(_ hidden: Bool) {
        guard hidden != isHiddenByRequest else { return }
        isHiddenByRequest = hidden
        window?.isHidden = hidden
    }

    /// Pure decision used by `install()`. Kept separate so the
    /// recovery branching can be unit-tested deterministically.
    static func installOutcome(hasWindow: Bool, hasActiveScene: Bool) -> BottomModuleInstallOutcome {
        if hasWindow { return .alreadyInstalled }
        return hasActiveScene ? .installNow : .deferUntilActive
    }

    /// Installs the secondary window. Idempotent — once installed,
    /// calling again is a no-op (the `window == nil` guard).
    /// `rootView` is built lazily so it can capture the latest
    /// environment values. `interactiveBottomInset` is the height of
    /// the bottom strip where the window's content actually paints —
    /// touches above it are passed through to the main window.
    ///
    /// **Cold-launch recovery.** On some launches the App body's
    /// `.onAppear` fires *before* the window scene reaches
    /// `.foregroundActive`. Rather than silently give up (which left
    /// the mini-player + tab bar missing for the whole session), this
    /// registers a one-shot `UIScene.didActivateNotification` observer
    /// that retries with the scene that just activated, then removes
    /// itself. The App also re-calls `install()` on `scenePhase ==
    /// .active` (belt-and-suspenders); both paths hit the same guard,
    /// so the window is created exactly once.
    ///
    /// - Returns: `true` if the window is now installed (either this
    ///   call built it or it already existed); `false` if the install
    ///   was deferred because no active scene was available yet.
    @discardableResult
    func install<Root: View>(
        interactiveBottomInset: CGFloat,
        @ViewBuilder rootView: @escaping () -> Root
    ) -> Bool {
        let activeScene = Self.foregroundActiveScene()
        switch Self.installOutcome(hasWindow: window != nil, hasActiveScene: activeScene != nil) {
        case .alreadyInstalled:
            return true
        case .installNow:
            installWindow(in: activeScene!, interactiveBottomInset: interactiveBottomInset, rootView: rootView)
            return true
        case .deferUntilActive:
            registerActivationRetry(interactiveBottomInset: interactiveBottomInset, rootView: rootView)
            scheduleSelfHealRetry(interactiveBottomInset: interactiveBottomInset, rootView: rootView)
            return false
        }
    }

    /// Schedules the next level-triggered retry (see `retryDelay(forAttempt:)`
    /// for why the edge-triggered paths aren't sufficient on their own). Only
    /// one chain runs at a time, and it stops as soon as the window exists or
    /// the schedule is exhausted.
    private func scheduleSelfHealRetry<Root: View>(
        interactiveBottomInset: CGFloat,
        @ViewBuilder rootView: @escaping () -> Root
    ) {
        guard retryWorkItem == nil else { return }
        guard let delay = Self.retryDelay(forAttempt: retryAttempt) else {
            Self.log.error("Bottom-module install still deferred after all retries — no active scene.")
            return
        }
        retryAttempt += 1
        let item = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.retryWorkItem = nil
                guard self.window == nil else { return }
                // Re-entering install() either succeeds or schedules the next
                // retry, so the chain continues without special-casing here.
                self.install(interactiveBottomInset: interactiveBottomInset, rootView: rootView)
            }
        }
        retryWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelSelfHealRetry() {
        retryWorkItem?.cancel()
        retryWorkItem = nil
    }

    /// The current foreground-active window scene, if any. On iPad
    /// multi-scene (`UIApplicationSupportsMultipleScenes`) this picks
    /// the active one so we never attach to a backgrounded scene.
    ///
    /// **Zero-size scenes don't count.** A scene can report
    /// `.foregroundActive` before its geometry is configured, and a window
    /// attached to one is zero-sized — invisible, and untappable too, since
    /// `PassThroughWindow.hitTest` measures from `bounds.height`. Treating that
    /// as "no scene yet" sends it down the retry path instead of installing a
    /// window that can never be seen.
    private static func foregroundActiveScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive && !$0.coordinateSpace.bounds.isEmpty }
    }

    private func installWindow<Root: View>(
        in scene: UIWindowScene,
        interactiveBottomInset: CGFloat,
        rootView: () -> Root
    ) {
        guard window == nil else { return }

        let w = PassThroughWindow(windowScene: scene)
        // NOTE: deliberately no explicit `frame` assignment. An earlier revision
        // set `w.frame = scene.coordinateSpace.bounds` as "harmless insurance",
        // which was a mistake twice over: it pins a snapshot of the geometry (so
        // the window stops tracking the scene across rotation), and if the scene
        // wasn't configured yet it pins *zero* — the exact invisible-window
        // failure it was meant to prevent. `UIWindow(windowScene:)` adopts and
        // tracks the scene's geometry on its own; readiness is now checked in
        // `foregroundActiveScene()` instead.
        // One level above .normal so this window sits on top of
        // every modal presentation (UIKit modals default to .normal
        // level). The level is a `CGFloat`, so we add a small
        // positive increment.
        w.windowLevel = UIWindow.Level(UIWindow.Level.normal.rawValue + 1)
        w.backgroundColor = .clear
        w.isOpaque = false
        // Prefer a measured height if one already arrived (deferred install).
        w.interactiveBottomInset = lastInteractiveBottomInset ?? interactiveBottomInset

        let host = UIHostingController(rootView: rootView())
        host.view.backgroundColor = .clear
        w.rootViewController = host

        // Not unconditionally visible: a window installed late must respect a
        // hide that was requested before it existed.
        w.isHidden = isHiddenByRequest
        window = w
        clearActivationRetry()
        cancelSelfHealRetry()
        // Re-apply the last-known appearance: a deferred install
        // happens after the App already called `apply`, so the fresh
        // window would otherwise be stuck on SYSTEM appearance.
        apply(preference: lastPreference)
        Self.log.info("Bottom-module window installed (scene=\(scene.session.persistentIdentifier, privacy: .public))")
    }

    /// Registers the one-shot scene-activation retry. Safe to call
    /// repeatedly — only the first registration takes effect.
    private func registerActivationRetry<Root: View>(
        interactiveBottomInset: CGFloat,
        @ViewBuilder rootView: @escaping () -> Root
    ) {
        guard activationObserver == nil else { return }
        Self.log.info("Bottom-module install deferred — no active scene yet; awaiting scene activation.")
        activationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self, self.window == nil else { return }
                // Prefer the scene that just activated (correct on
                // iPad multi-scene); fall back to any active scene.
                let scene = (note.object as? UIWindowScene).flatMap {
                    $0.activationState == .foregroundActive ? $0 : nil
                } ?? Self.foregroundActiveScene()
                guard let scene else { return }
                self.installWindow(in: scene, interactiveBottomInset: interactiveBottomInset, rootView: rootView)
            }
        }
    }

    private func clearActivationRetry() {
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
            self.activationObserver = nil
        }
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
        lastPreference = preference
        guard let window else { return }
        switch preference {
        case .system: window.overrideUserInterfaceStyle = .unspecified
        case .light:  window.overrideUserInterfaceStyle = .light
        case .dark:   window.overrideUserInterfaceStyle = .dark
        }
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
        // When this window is presenting a modal (the full-screen
        // PlayerView), it owns the entire screen — claim every touch so
        // the player is fully interactive, not just its bottom strip.
        if rootViewController?.presentedViewController != nil {
            return super.hitTest(point, with: event)
        }
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

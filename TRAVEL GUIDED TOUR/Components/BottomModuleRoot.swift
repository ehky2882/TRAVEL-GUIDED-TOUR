import SwiftUI

/// The root view of the secondary higher-level `UIWindow` that
/// hosts the mini-player + tab bar above any UIKit modal presented
/// in the main window. Pinned to the bottom of the screen; the rest
/// of the window's area is transparent and pass-through (see
/// `PassThroughWindow`).
///
/// Mirrors the layout `ContentView` used to render inline — same
/// rectangle background in `.fullEdge` mode, same VStack of
/// MiniPlayerBar + AtlasTabBar — just hoisted into its own window so
/// the UIKit detail-presentation modal slides up *behind* it.
struct BottomModuleRoot: View {
    /// Reports the module's real painted height so the hosting window can claim
    /// exactly that strip for touches. Anything painted outside the claimed
    /// strip renders but receives no taps — see
    /// `BottomModuleWindowController.setInteractiveBottomInset(_:)`.
    /// `@MainActor` because it drives the (main-actor) window controller —
    /// same pattern as `GroupTransport`'s callbacks.
    /// Explicit `= nil` so `BottomModuleRoot()` is unambiguously valid: the
    /// inline fallback in `ContentView` renders it without a window to measure.
    var onInteractiveHeightChange: (@MainActor (CGFloat) -> Void)? = nil

    @Environment(DataService.self) private var dataService
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(TourPresenter.self) private var tourPresenter
    /// Needed here, not just in `ContentView`, so a tab tap can close a presented
    /// maker page from this window — see `tabSelection`.
    @Environment(MakerPresenter.self) private var makerPresenter: MakerPresenter?
    /// Optional for the same reason as `makerPresenter`: the inline fallback
    /// renders this view without the full app environment.
    @Environment(PlacePresenter.self) private var placePresenter: PlacePresenter?
    @Environment(AppSharedState.self) private var appShared
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(AuthService.self) private var authService: AuthService?
    @Environment(FollowService.self) private var followService: FollowService?
    @Environment(MakerProfileService.self) private var makerProfileService: MakerProfileService?

    var body: some View {
        @Bindable var appShared = appShared
        // Only Home (no detail) preserves the floating-island look so
        // the map shows through the 8pt side gaps + outer strip.
        // Everywhere else — Library, Me, and ANY tab with a detail
        // sheet open — the bars grow edge-to-edge with square outer
        // corners. Buttons sit at identical x positions across both
        // forms (design rule: only the fill changes).
        // Reading `showingFullPlayer` registers it as a dependency so
        // the bars recompute their island/edge form the moment the
        // player retracts — this window is hidden while the player is
        // up, so without an explicit dependency the geometry could read
        // stale on re-show.
        _ = appShared.showingFullPlayer
        // `navState.isShowingDetail` is the primary signal: every pushed
        // detail (TourDetail, Search, Maker, ManageDownloads) calls
        // push()/pop(), so this catches NavigationLink-pushed screens
        // that stay on the Home tab — e.g. the Search→Maker deep-link —
        // which the tab check alone misses. `presentedTour != nil` is
        // kept as belt-and-suspenders for the UIKit-presented tour
        // sheet so its edge form can't flicker on any push/pop timing
        // gap.
        let extendsToScreenEdges = appShared.selectedTab != .home
            || navState.isShowingDetail
            || tourPresenter.presentedTour != nil
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            // The painted module. Measured as one unit so the window claims a
            // touch strip that covers exactly what's drawn here — rather than a
            // fixed constant. Anything added ABOVE the mini-player is therefore
            // tappable automatically; the old fixed 126pt strip left such a view
            // visible but untouchable.
            VStack(spacing: 0) {
                MiniPlayerBar(
                    tour: nowPlayingTour,
                    maker: nowPlayingTour.flatMap { dataService.maker(for: $0) },
                    onExpand: { appShared.showingFullPlayer = true },
                    extendsToScreenEdges: extendsToScreenEdges
                )
                AtlasTabBar(
                    selected: tabSelection,
                    extendsToScreenEdges: extendsToScreenEdges,
                    badgedTabs: (followService?.ownPendingRequests ?? 0) > 0 ? [.me] : []
                )
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                onInteractiveHeightChange?(height)
            }
        }
        // Keep the Me-tab notification badge in sync with the pending
        // follow-request count on the signed-in user's own maker. Re-runs on
        // sign-in/out and once the user's maker id becomes known after launch
        // hydration; refreshOwnPendingRequests seeds from cache then corrects
        // from the network so the badge is right on the first frame.
        .task(id: ownMakerId) {
            guard let followService else { return }
            guard authService?.isSignedIn == true, let ownMakerId else {
                followService.clearOwnPendingRequests()
                return
            }
            await followService.refreshOwnPendingRequests(ownMakerId: ownMakerId)
        }
        // `.all` covers both the container inset (home-indicator
        // strip — already needed for the floating-island look) AND
        // the keyboard inset. Without ignoring the keyboard, focusing
        // a TextField anywhere in the main window (SearchView,
        // Settings, etc.) would push the bottom module up by the
        // keyboard's height. We want the bottom module to stay
        // anchored at the bottom of the screen and let the keyboard
        // overlay it.
        .ignoresSafeArea(.all, edges: .bottom)
        // Toasts render here, in this higher-level window, so they appear above
        // every UIKit modal (tour/maker layers, sheets) and the main window.
        .overlay(alignment: .top) { ToastHost() }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: nowPlayingTour?.id)
        // Present the full player from THIS window (above the detail
        // modal) so the cover slides up over the mini-player + tab bar
        // in the same window — no hiding/showing of the module, so the
        // transition has no empty gap. `PassThroughWindow.hitTest`
        // claims all touches while this modal is up.
        .fullScreenCover(isPresented: $appShared.showingFullPlayer) {
            if let tour = nowPlayingTour {
                PlayerView(tour: tour)
            }
        }
    }

    /// The signed-in user's own maker id (the followee side of any pending
    /// request). `nil` when signed out or before the maker profile exists —
    /// which clears the badge. Doubles as the `.task` id so the refresh re-runs
    /// when the user (or their maker) changes.
    private var ownMakerId: UUID? {
        guard authService?.isSignedIn == true else { return nil }
        return makerProfileService?.myMaker?.id
    }

    /// Tab-bar binding that closes any presented detail layer **as part of the
    /// tap**, then switches tab.
    ///
    /// `ContentView` has an `.onChange(of: selectedTab)` that does the same, and
    /// it is kept as a backstop — but it cannot be relied on alone. It lives in
    /// the MAIN window, which is entirely covered by the UIKit tour-detail modal
    /// at the moment of the tap, and SwiftUI can stop delivering updates to a
    /// hierarchy hidden behind a modal presentation. When that happens the tap
    /// still flips `selectedTab` (so the tab icon highlights) while nothing
    /// dismisses the layer, and the new tab's content swaps in *behind* the
    /// detail — the user sees a tab bar that appears dead. Reported on 1.1 (44)
    /// after joining a group, with the tour page still open.
    ///
    /// This binding runs in the secondary window, which is never covered, so the
    /// dismissal is not conditional on the main window still being live.
    private var tabSelection: Binding<AtlasTab> {
        Binding(
            get: { appShared.selectedTab },
            set: { newTab in
                // Every slide-up layer comes down as part of the tap, from
                // THIS window — the one a layer can never cover. A layer left
                // up sits over the tab's content and the bar reads as dead:
                // the icon highlights, the screen doesn't change (the
                // session-8 symptom).
                //
                // 🔴 DELIBERATELY NOT GUARDED ON `newTab != selectedTab`.
                // It used to be, and that was a real dead-tab bug: open a
                // tour from Home, then tap Home. The tab hasn't changed, so
                // nothing was dismissed and the tap did nothing whatsoever,
                // with the tour still covering the screen and no way out but
                // the X. Tapping the tab you are already on is iOS's "back to
                // the root of this tab" gesture, so it has to tear the layers
                // down as well.
                //
                // 🔴 A NEW LAYER MUST BE ADDED HERE. The place layer shipped
                // in 1.1 (69) without its line, so a place page stayed up
                // while the selection changed behind it.
                if tourPresenter.presentedTour != nil {
                    tourPresenter.dismiss()
                }
                if makerPresenter?.presentedMaker != nil {
                    makerPresenter?.dismiss()
                }
                if placePresenter?.presentedPlace != nil {
                    placePresenter?.dismiss()
                }
                appShared.selectedTab = newTab
            }
        )
    }

    private var nowPlayingTour: Tour? {
        guard audioPlayer.state != .idle,
              let sourceId = audioPlayer.currentSourceId,
              let uuid = UUID(uuidString: sourceId) else {
            return nil
        }
        return dataService.tour(by: uuid)
    }
}

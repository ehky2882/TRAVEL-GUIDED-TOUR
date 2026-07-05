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
    @Environment(DataService.self) private var dataService
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(AppSharedState.self) private var appShared
    @Environment(AtlasNavigationState.self) private var navState

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
            MiniPlayerBar(
                tour: nowPlayingTour,
                maker: nowPlayingTour.flatMap { dataService.maker(for: $0) },
                onExpand: { appShared.showingFullPlayer = true },
                extendsToScreenEdges: extendsToScreenEdges
            )
            AtlasTabBar(
                selected: $appShared.selectedTab,
                extendsToScreenEdges: extendsToScreenEdges
            )
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

    private var nowPlayingTour: Tour? {
        guard audioPlayer.state != .idle,
              let sourceId = audioPlayer.currentSourceId,
              let uuid = UUID(uuidString: sourceId) else {
            return nil
        }
        return dataService.tour(by: uuid)
    }
}

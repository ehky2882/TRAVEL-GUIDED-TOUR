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

    var body: some View {
        @Bindable var appShared = appShared
        // Edge-to-edge fill on every surface except Home root —
        // makes the bottom-region read as one continuous chrome band
        // when a detail is up or the user's on Library / Me. On Home
        // (no fill) the bar + tab bar's individual backgrounds float
        // as the island, with map showing through the 8pt side gaps
        // and the 8pt outer strip below.
        let extendsToScreenEdges = tourPresenter.presentedTour != nil
            || appShared.selectedTab != .home
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack(alignment: .bottom) {
                if extendsToScreenEdges {
                    Rectangle()
                        .fill(AtlasColors.secondaryBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: AtlasBottomModule.height())
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    MiniPlayerBar(
                        tour: nowPlayingTour,
                        maker: nowPlayingTour.flatMap { dataService.maker(for: $0) }
                    ) {
                        appShared.showingFullPlayer = true
                    }
                    AtlasTabBar(selected: $appShared.selectedTab)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: nowPlayingTour?.id)
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

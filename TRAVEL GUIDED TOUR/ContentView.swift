import SwiftUI
import Foundation

/// Root shell — V1 has 3 surfaces (Home / Library / Me). Renders
/// the tab CONTENT (map/drawer for Home, Library, Settings) only —
/// the mini-player + tab bar are hoisted out into a separate
/// higher-level `UIWindow` (see `Components/BottomModuleWindow.swift`)
/// so the UIKit-presented tour detail slides up *behind* them.
///
/// **Tour detail presentation.** Detail screens come up via a
/// UIKit-backed `BottomLayerController` that slides up from the
/// bottom and stops short of the bottom-module height (mini-player +
/// tab bar). This isn't a SwiftUI `.sheet` (covers the bottom
/// module) nor a hand-rolled `.offset` layer (the previous approach
/// — fighting SwiftUI's animation system at every step). The UIKit
/// bridge gives us system-quality spring physics, natural
/// touch-through to the underlying mini-player + tab bar in the
/// un-covered region, and proper view-controller-life-cycle handling
/// of the inner SwiftUI content. See
/// `Components/BottomLayerPresentation.swift` for the full
/// machinery.
struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(ProximityMonitor.self) private var proximityMonitor
    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(AppSharedState.self) private var appShared
    @Environment(TourPresenter.self) private var tourPresenter

    /// `.onAppear` fires every time the view re-attaches (tab switch,
    /// returning from background, etc.). Request location permission
    /// once per process so we don't repeatedly hit
    /// `CLLocationManager.requestWhenInUseAuthorization()` — iOS no-ops
    /// after the first call but the redundancy was conceptually wrong
    /// (audit P3-7).
    @State private var didRequestLocationPermission = false
    /// The home drawer's detent, lifted out of `HomeView` so it
    /// survives HomeView being recreated on tab switches. Starts
    /// expanded on a fresh launch; returning to the Home tab restores
    /// whatever detent the user last left it at.
    @State private var homeSheetDetent: BottomSheetDetent = .large
    /// State shared between `HomeView`'s map surface and the home
    /// drawer (which is hosted here in `ContentView` so it can stack
    /// z-order on top of the mini-player + tab bar). Both sides read
    /// it via `@Environment`.
    @State private var homeSharedState = HomeSharedState()

    /// Tracks whether any pushed detail screen is currently visible.
    /// Driven by each detail view's `.onAppear` / `.onDisappear`
    /// calling `push()` / `pop()`. Injected into the environment so
    /// children can find it without prop-drilling.
    @State private var navState = AtlasNavigationState()

    /// UIKit presentation controller — finds the topmost view
    /// controller in the active window and presents
    /// `TourDetailView` (wrapped in a `UIHostingController`) with
    /// the custom slide-from-bottom transition. Held here so the
    /// transitioning delegate survives the presentation's lifetime.
    @State private var bottomLayer = BottomLayerController(
        bottomInset: AtlasBottomModule.height()
    )

    var body: some View {
        @Bindable var appShared = appShared
        // NOTE on bindings: deliberately NOT using `@Bindable` for
        // `homeSharedState` — `@Bindable`'s `$` projection during
        // body registers an Observable read for the property, so
        // `sheetDragOffset` (written 60×/sec during a drag) would
        // re-evaluate the entire `ContentView` body on every frame.
        // Manual `Binding(get:set:)` captures the reference without
        // touching the tracked property at body time; SwiftUI only
        // reads through the closure when it actually needs the
        // value, which avoids that re-eval storm.
        let dragOffsetBinding = Binding(
            get: { homeSharedState.sheetDragOffset },
            set: { homeSharedState.sheetDragOffset = $0 }
        )
        return ZStack(alignment: .bottom) {
            tabContent

            // Home drawer — only on Home tab.
            if appShared.selectedTab == .home {
                BottomSheet(
                    detent: $homeSheetDetent,
                    dragOffset: dragOffsetBinding,
                    peekHeight: 80,
                    bottomCornerRadius: 0,
                    bottomReservedHeight: AtlasBottomModule.height()
                ) {
                    HomeDrawerContent(
                        sheetDetent: $homeSheetDetent,
                        onTourTap: { tour in
                            tourPresenter.present(tour)
                        }
                    )
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .environment(navState)
        .environment(homeSharedState)
        .sheet(isPresented: $appShared.showingFullPlayer) {
            if let tour = nowPlayingTour {
                PlayerView(tour: tour)
            }
        }
        .onAppear {
            guard !didRequestLocationPermission else { return }
            didRequestLocationPermission = true
            locationManager.requestPermission()
        }
        // Drive the UIKit-backed slide-up modal off the presenter's
        // `presentedTour`. When a tour appears: build the SwiftUI
        // root view (with every environment value the detail
        // subtree needs, captured here at body time), hand it to
        // `BottomLayerController` to wrap in a UIHostingController
        // and present via UIKit's custom transition. When the tour
        // goes nil: dismiss. `onDismiss` is wired so a future
        // interactive drag-down would also keep state in sync.
        // Tapping a tab while the detail sheet is up should dismiss
        // it — otherwise the new tab's content swaps in *behind* the
        // detail and the user appears stuck (icon updates, content
        // doesn't). Apple Music does the same: swiping the now-
        // playing modal away is a separate gesture from changing tabs.
        .onChange(of: appShared.selectedTab) { _, _ in
            if tourPresenter.presentedTour != nil {
                tourPresenter.dismiss()
            }
        }
        // Bridge geofence-triggered stop playback into shared state
        // so the tour-detail sheet's now-playing indicator can light
        // up the matching stop row. ProximityMonitor stays free of
        // UI-state coupling — the bridge lives here, where both
        // dependencies are already in scope.
        .onChange(of: proximityMonitor.lastEnteredStopId) { _, newStopId in
            if let newStopId {
                appShared.currentPlayingStopId = newStopId
            }
        }
        .onChange(of: tourPresenter.presentedTour?.id) { _, _ in
            if let tour = tourPresenter.presentedTour {
                bottomLayer.present(
                    NavigationStack {
                        TourDetailView(tour: tour)
                    }
                    .environment(navState)
                    .environment(homeSharedState)
                    .environment(tourPresenter)
                    .environment(dataService)
                    .environment(locationManager)
                    .environment(audioPlayer)
                    .environment(libraryStore)
                    .environment(recentlyViewedStore)
                    .environment(proximityMonitor)
                    .environment(tourDownloader)
                    .environment(appShared),
                    onDismiss: { tourPresenter.dismiss() }
                )
            } else {
                bottomLayer.dismiss()
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch appShared.selectedTab {
        case .home:    HomeView(sheetDetent: $homeSheetDetent)
        case .library: LibraryView()
        case .me:      SettingsView()
        }
    }

    /// The tour whose audio is currently loaded, or `nil` when nothing
    /// is playing. Drives the mini-player's visibility.
    private var nowPlayingTour: Tour? {
        guard audioPlayer.state != .idle,
              let sourceId = audioPlayer.currentSourceId,
              let uuid = UUID(uuidString: sourceId) else {
            return nil
        }
        return dataService.tour(by: uuid)
    }
}

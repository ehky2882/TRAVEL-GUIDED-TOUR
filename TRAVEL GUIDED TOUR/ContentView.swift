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
    @Environment(MakerPresenter.self) private var makerPresenter
    @Environment(SavedMakersStore.self) private var savedMakersStore

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
    /// calling `push()` / `pop()`. Owned at the App level (so the
    /// bottom-module window observes the same instance) and read here
    /// to hide the Home drawer once a detail is pushed.
    @Environment(AtlasNavigationState.self) private var navState

    /// UIKit presentation controller — finds the topmost view
    /// controller in the active window and presents
    /// `TourDetailView` (wrapped in a `UIHostingController`) with
    /// the custom slide-from-bottom transition. Held here so the
    /// transitioning delegate survives the presentation's lifetime.
    @State private var bottomLayer = BottomLayerController(
        bottomInset: AtlasBottomModule.height()
    )

    /// True while the tour-detail layer is up (or animating) having
    /// been presented from the Home ROOT — i.e. the drawer was
    /// visible underneath when it came up. While true, the drawer
    /// stays mounted behind the layer instead of being removed, so
    /// dismissing the layer reveals the drawer already sitting at
    /// its old detent ("it stayed there") rather than re-inserting
    /// it after the slide finishes (which read as a flash). Captured
    /// at present time as `pushedDepth == 0` so tours opened from
    /// inside Search/Maker DON'T mount the drawer over those
    /// screens; cleared by the dismiss animation's completion.
    @State private var tourLayerCoversDrawer = false

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

            // Home drawer — only on the Home tab root. Once a detail
            // is pushed (Search, Maker — including the Search→Maker
            // deep-link, which stays on the Home tab and so wouldn't
            // be caught by the tab check alone) the drawer hides so
            // it can't leak its header over the pushed screen.
            // Exception: the tour-detail LAYER presented from the
            // Home root keeps the drawer mounted underneath
            // (`tourLayerCoversDrawer`) — the layer fully covers it,
            // and keeping it in place means the dismiss slide reveals
            // the drawer at its old detent instead of flashing it
            // back in after the animation.
            if appShared.selectedTab == .home
                && (tourLayerCoversDrawer || !navState.isShowingDetail) {
                BottomSheet(
                    detent: $homeSheetDetent,
                    dragOffset: dragOffsetBinding,
                    peekHeight: 80,
                    bottomCornerRadius: 0,
                    bottomReservedHeight: AtlasBottomModule.height(),
                    // .large stops below the search bar + chip row
                    // so they stay anchored at the top of the screen
                    // when the drawer is fully expanded. AtlasSpacing.sm
                    // is a small visual buffer between the chip row's
                    // bottom edge and the drawer's top edge.
                    topReservedHeight: AtlasSpacing.searchAndChipsBlockHeight + AtlasSpacing.sm
                ) {
                    HomeDrawerContent(
                        sheetDetent: $homeSheetDetent
                    )
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .environment(navState)
        .environment(homeSharedState)
        // Maker deep links (a shared maker link) have no nav stack to push
        // onto, so present the maker page as a sheet driven by MakerPresenter.
        // Re-inject the environment the maker subtree needs (a tour tapped
        // inside slides up over this sheet via the bottom-layer presenter,
        // which targets the topmost view controller).
        .sheet(item: Bindable(makerPresenter).presentedMaker) { maker in
            NavigationStack {
                MakerView(maker: maker)
            }
            .environment(dataService)
            .environment(tourPresenter)
            .environment(makerPresenter)
            .environment(libraryStore)
            .environment(savedMakersStore)
            .environment(audioPlayer)
            .environment(locationManager)
            .environment(recentlyViewedStore)
            .environment(proximityMonitor)
            .environment(tourDownloader)
            .environment(appShared)
            .environment(navState)
        }
        // NOTE: the full PlayerView is presented from `BottomModuleRoot`
        // (the secondary top window), NOT here — so the cover physically
        // slides up over the mini-player + tab bar in the same window,
        // with no separate hide/show of the module (which used to leave
        // a visible gap during the transition).
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
        // Opening the full player makes it the now-playing surface, so
        // drop any detail sheet underneath it. Otherwise retracting the
        // player lands back on the stale detail sheet — which forces the
        // bottom module into its edge-to-edge form even when the user
        // expects to be back on Home (floating island).
        .onChange(of: appShared.showingFullPlayer) { _, isUp in
            if isUp && tourPresenter.presentedTour != nil {
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
                // Capture BEFORE the layer's TourDetailView registers
                // its own push — depth 0 here means the layer is
                // coming up over the Home root with the drawer
                // visible beneath it.
                tourLayerCoversDrawer = navState.pushedDepth == 0
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
                    .environment(appShared)
                    .environment(savedMakersStore),
                    onDismiss: { tourPresenter.dismiss() }
                )
            } else {
                // Keep the drawer mounted through the slide-down;
                // clear the cover flag only once the layer has fully
                // revealed it (the detail's own navState.pop() fires
                // around the same moment, so the drawer condition
                // hands over seamlessly from one term to the other).
                bottomLayer.dismiss {
                    tourLayerCoversDrawer = false
                }
            }
        }
        // Resolve the current tour's maker avatar into lock-screen /
        // Control-Center artwork whenever the loaded source changes.
        // Done here (not in AudioPlayerService) because the avatar
        // lives on the maker, which only DataService can resolve from
        // the source id. The resolve is async (remote URL / emoji
        // render); `setArtwork(_:for:)` drops the result if a newer
        // tour has since loaded.
        .onChange(of: audioPlayer.currentSourceId) { _, sourceId in
            #if canImport(UIKit)
            guard let sourceId,
                  let uuid = UUID(uuidString: sourceId),
                  let tour = dataService.tour(by: uuid) else { return }
            let maker = dataService.maker(for: tour)
            Task { @MainActor in
                let image = await MakerArtwork.image(for: maker)
                audioPlayer.setArtwork(image, for: sourceId)
            }
            #endif
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch appShared.selectedTab {
        case .home:    HomeView(sheetDetent: $homeSheetDetent)
        case .library: LibraryView()
        case .me:      ProfileView()
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

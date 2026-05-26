import SwiftUI
import Foundation

/// Root shell — V1 has 3 surfaces (Home / Library / Me).
///
/// Uses a custom `AtlasTabBar` floating over the tab content (instead
/// of the system `TabView`) so the tab bar can match the home screen's
/// drawer width, corner radius, and inset exactly — the two read as
/// one integrated bottom UI region. The trade-off is we manage tab
/// selection state ourselves and give up a few system tab-bar
/// features (badge support, focus animations); easy to revisit if
/// those become needed.
struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(TourDownloader.self) private var tourDownloader

    @State private var selectedTab: AtlasTab = .home
    /// `.onAppear` fires every time the view re-attaches (tab switch,
    /// returning from background, etc.). Request location permission
    /// once per process so we don't repeatedly hit
    /// `CLLocationManager.requestWhenInUseAuthorization()` — iOS no-ops
    /// after the first call but the redundancy was conceptually wrong
    /// (audit P3-7).
    @State private var didRequestLocationPermission = false
    /// Drives the full-player sheet opened by tapping the mini-player.
    @State private var showingFullPlayer = false
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
    /// App-wide tour-detail presentation channel. Every "open this
    /// tour" entry point (drawer card, placecard, library, search,
    /// maker, rail) calls `tourPresenter.present(tour)` instead of
    /// pushing a `NavigationLink` — the detail view always comes up
    /// from the bottom as a modal sheet.
    @State private var tourPresenter = TourPresenter()
    /// Mirrors `tourPresenter.presentedTour` but **lags** during
    /// dismiss — kept non-nil for the duration of the slide-down so
    /// the detail content stays rendered while the layer slides
    /// off-screen. Without this lag, the conditional content would
    /// be torn down the instant `presentedTour` goes nil and the
    /// layer would slide down empty (looking like a fade).
    @State private var displayedTour: Tour? = nil

    /// Active screen height. Used as the off-screen offset for the
    /// detail layer so the slide animation is fully visible across
    /// its full duration. Earlier hardcoded `2000` left ~57% of the
    /// animation off-screen (especially on smaller iPhones), and
    /// the visible tail read as a "pop in" / fade rather than a
    /// clean slide.
    private var screenHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen.bounds.height ?? 900
    }

    /// Tracks whether any pushed detail screen is currently visible.
    /// Driven by each detail view's `.onAppear` / `.onDisappear`
    /// calling `push()` / `pop()`. Injected into the environment so
    /// children can find it without prop-drilling.
    @State private var navState = AtlasNavigationState()

    /// Floating-island look ONLY when on the Home tab AT ROOT — no
    /// detail layer up and no `NavigationStack` push. Every other
    /// state uses full-edge. Both `tourPresenter.presentedTour` and
    /// `navState.isShowingDetail` are read here so the geometry
    /// switches at the SAME tick as the detail layer's slide
    /// (otherwise the module's fade-to-fullEdge happens on a
    /// different curve / duration and the whole thing reads as two
    /// uncoordinated animations).
    private var moduleGeometry: AtlasModuleGeometry {
        if tourPresenter.presentedTour != nil || navState.isShowingDetail {
            return .fullEdge
        }
        return selectedTab == .home ? .floatingIsland : .fullEdge
    }

    private var extendsToScreenEdges: Bool {
        moduleGeometry == .fullEdge
    }

    var body: some View {
        // NOTE on bindings: deliberately NOT using `@Bindable` for
        // these — `@Bindable`'s `$` projection during body registers
        // an Observable read for the property, so `sheetDragOffset`
        // (written 60×/sec during a drag) would re-evaluate the
        // entire `ContentView` body on every frame. Manual
        // `Binding(get:set:)` captures the reference without
        // touching the tracked property at body time; SwiftUI only
        // reads through the closure when it actually needs the
        // value, which avoids that re-eval storm.
        let dragOffsetBinding = Binding(
            get: { homeSharedState.sheetDragOffset },
            set: { homeSharedState.sheetDragOffset = $0 }
        )
        return ZStack(alignment: .bottom) {
            tabContent

            // Tour detail layer — ALWAYS rendered in the view tree
            // (not conditional). Position controlled via `.offset`
            // so we can use a deterministic `.animation(_, value:)`
            // instead of relying on SwiftUI's `.transition`, which
            // falls back to an opacity fade on removal for views
            // containing `NavigationStack` regardless of the
            // `.move` transition we specify.
            //
            // `displayedTour` lags behind `tourPresenter.presentedTour`
            // — kept non-nil for the dismiss-animation duration so
            // the content stays visible while the layer slides
            // off-screen.
            ZStack(alignment: .top) {
                AtlasColors.secondaryBackground
                    .ignoresSafeArea(.container, edges: .top)

                if let tour = displayedTour {
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
                    .environment(tourDownloader)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Off-screen position = exactly one screen height
            // below natural position. This keeps the slide visible
            // throughout the animation — too-large values left the
            // layer off-screen for most of the duration and the
            // visible tail read as a fade-in / pop.
            .offset(y: tourPresenter.presentedTour == nil ? screenHeight : 0)
            .allowsHitTesting(tourPresenter.presentedTour != nil)
            .animation(
                .smooth(duration: 0.4),
                value: tourPresenter.presentedTour != nil
            )

            // Mini-player + tab bar — rendered AFTER the detail
            // layer so it stays z-order on top and remains visible
            // even when a tour detail is open. Rendered identically
            // across surfaces; only the background fill behind it
            // changes between modes.
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
                        showingFullPlayer = true
                    }
                    AtlasTabBar(selected: $selectedTab)
                }
            }

            // Home drawer — z-stacked AFTER the mini-player + tab
            // bar so its bottom edge can sit flush against them
            // without the last card peeking behind.
            //
            // Always rendered when on the Home tab (no longer
            // conditional on `tourPresenter.presentedTour`) — its
            // insertion/removal was running on the same SwiftUI
            // animation tick as the detail-layer's slide, and the
            // drawer's default opacity-fade transition was bleeding
            // into the detail layer's transition so the detail
            // read as fading out instead of sliding down. Keeping
            // the drawer rendered and just opacity-controlling it
            // avoids the conflict — the detail's `.move` runs
            // alone now.
            if selectedTab == .home {
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
                .opacity(tourPresenter.presentedTour == nil ? 1 : 0)
                .allowsHitTesting(tourPresenter.presentedTour == nil)
                // Match the detail layer's slide duration so the
                // drawer's fade-out and the detail's slide-up run
                // on the same clock. Otherwise the drawer pops away
                // instantly while the detail is still entering and
                // the user perceives a flash / fade.
                .animation(
                    .smooth(duration: 0.4),
                    value: tourPresenter.presentedTour != nil
                )
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: nowPlayingTour?.id)
        // Match the detail-layer's slide curve so the bottom
        // module's fade-to-fullEdge stays in lockstep with the
        // slide. Same `.smooth` curve, slightly longer than the
        // dismiss so the trailing module change reads as part of
        // the same gesture.
        .animation(.smooth(duration: 0.35), value: moduleGeometry)
        .environment(navState)
        .environment(homeSharedState)
        .environment(tourPresenter)
        .sheet(isPresented: $showingFullPlayer) {
            if let tour = nowPlayingTour {
                PlayerView(tour: tour)
            }
        }
        .onAppear {
            guard !didRequestLocationPermission else { return }
            didRequestLocationPermission = true
            locationManager.requestPermission()
        }
        // Drive `displayedTour` from `tourPresenter.presentedTour`,
        // with a lag on dismiss so the content stays rendered while
        // the layer slides off-screen.
        .onChange(of: tourPresenter.presentedTour?.id) { _, _ in
            if let new = tourPresenter.presentedTour {
                displayedTour = new
            } else {
                Task {
                    // Slightly longer than the offset animation so
                    // the view is fully off-screen before its
                    // content tears down.
                    try? await Task.sleep(for: .seconds(0.45))
                    await MainActor.run {
                        if tourPresenter.presentedTour == nil {
                            displayedTour = nil
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
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

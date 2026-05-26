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
    /// from the bottom as a modal sheet. The presenter also owns the
    /// `displayedTour` lag (set synchronously in `present(_:)`, held
    /// through the slide-down before clearing) so the inner content
    /// is in the view tree on the same tick the layer's offset starts
    /// animating — no separate `.onChange`-driven mirror in this view.
    @State private var tourPresenter = TourPresenter()

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

            // Tour detail layer — always in the view tree (not
            // conditional on a parent `if`). Position controlled via
            // `.offset` so we can use a deterministic
            // `.animation(_, value:)` instead of relying on SwiftUI's
            // `.transition`, which falls back to an opacity fade on
            // removal for views containing `NavigationStack`.
            //
            // The inner `if let displayedTour` is read off the
            // presenter (set synchronously in `present(_:)` and held
            // through the slide-down via a lag in `dismiss()`), so
            // the content is in the view tree on the SAME SwiftUI
            // tick the offset animation starts — no one-frame gap
            // that SwiftUI fills with an opacity fade-in. The
            // `.transition(.identity)` belt-and-suspenders the same
            // guarantee for the eventual remove.
            //
            // Z-index 2: ABOVE the drawer (which drops to z-1 while
            // a detail is up — see the drawer block below), BELOW
            // the mini-player + tab bar (z-3) so their buttons stay
            // tappable while the detail is up.
            ZStack(alignment: .top) {
                AtlasColors.secondaryBackground
                    .ignoresSafeArea(.container, edges: .top)

                if let tour = tourPresenter.displayedTour {
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
                    .transition(.identity)
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
            .zIndex(2)

            // Mini-player + tab bar — z-index 3, always the topmost
            // chrome. Stays tappable even when the detail layer is
            // up; the layer's action bar paints the same
            // `secondaryBackground` color through the bottom-module
            // area so the seam isn't visible.
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
            .zIndex(3)

            // Home drawer — z-index dynamic:
            //   - no detail (displayedTour nil): z-4, ABOVE the
            //     mini-player + tab bar. PR #76's "last card visible
            //     at scroll-end" fix — the drawer's rounded bottom
            //     sits flush against the bottom module without the
            //     last card peeking behind.
            //   - detail active (displayedTour set): z-1, BELOW the
            //     detail layer. The detail's slide-up then COVERS
            //     the drawer naturally as it rises — no drawer
            //     opacity fade needed, which was the source of the
            //     "fade in / fade out" perception from the drawer
            //     entry point (drawer at .large covered most of the
            //     screen, so its opacity-fade dominated visually).
            //
            // The drawer stays at full opacity throughout; visibility
            // is gated by z-order alone. Hit-testing is off while a
            // detail is up so taps that miss the X button can't
            // sneak through to drawer cards underneath.
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
                .allowsHitTesting(tourPresenter.displayedTour == nil)
                .zIndex(tourPresenter.displayedTour == nil ? 4 : 1)
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

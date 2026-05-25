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

    /// Tracks whether any pushed detail screen is currently visible.
    /// Driven by each detail view's `.onAppear` / `.onDisappear`
    /// calling `push()` / `pop()`. Injected into the environment so
    /// children can find it without prop-drilling.
    @State private var navState = AtlasNavigationState()

    /// Floating-island look ONLY when on the Home tab AT ROOT — no
    /// detail pushed. Every other state (non-Home tab, OR Home with
    /// a pushed detail) uses the full-edge geometry. The two modes
    /// share the same bottom-module height and button position, so
    /// switching between them only changes what's painted in the
    /// 8pt outer strip below the buttons (transparent vs. opaque).
    private var moduleGeometry: AtlasModuleGeometry {
        if navState.isShowingDetail {
            return .fullEdge
        }
        return selectedTab == .home ? .floatingIsland : .fullEdge
    }

    private var extendsToScreenEdges: Bool {
        moduleGeometry == .fullEdge
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent

            // Mini-player + tab bar stack at the bottom of every
            // tab. The mini-player + tab bar themselves are
            // rendered IDENTICALLY on every surface (8pt inset,
            // rounded bottom, transparent 8pt outer strip) — same
            // buttons, same shape, same position. The only thing
            // that changes between Home root (floating island)
            // and every other surface (full-edge look) is the
            // background fill BEHIND the island: on Home root
            // nothing's painted behind, so the 8pt side + bottom
            // gaps show the map; elsewhere we paint an
            // edge-to-edge `secondaryBackground` rectangle behind
            // the island so the gaps blend into one continuous
            // full-width strip the same color as the bar.
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
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: nowPlayingTour?.id)
        .animation(.easeInOut(duration: 0.2), value: moduleGeometry)
        .environment(navState)
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

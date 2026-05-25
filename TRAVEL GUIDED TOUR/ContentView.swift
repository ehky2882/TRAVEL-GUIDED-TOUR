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

    /// Whether the active tab is Home. Drives the bottom-module
    /// geometry switch: Home keeps the floating-island look (inset +
    /// rounded bottom); every other tab extends flush to the screen
    /// edges. Plumbed into the module directly and propagated down to
    /// pushed children via `\.atlasIsHomeTab` so scrollable content
    /// can size its `safeAreaInset(.bottom)` to match.
    private var isHomeTab: Bool { selectedTab == .home }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .environment(\.atlasIsHomeTab, isHomeTab)

            // Mini-player + tab bar stack at the bottom of every tab.
            // The mini-player is always present — it shows the active
            // tour, or a muted "Nothing playing" idle state. On Home
            // the stack floats as a rounded island (per PR #60); on
            // every other tab it extends flush to the screen edges.
            VStack(spacing: 0) {
                MiniPlayerBar(
                    tour: nowPlayingTour,
                    maker: nowPlayingTour.flatMap { dataService.maker(for: $0) },
                    extendsToScreenEdges: !isHomeTab
                ) {
                    showingFullPlayer = true
                }
                AtlasTabBar(selected: $selectedTab, extendsToScreenEdges: !isHomeTab)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: nowPlayingTour?.id)
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

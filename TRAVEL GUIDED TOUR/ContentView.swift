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

    /// Bottom-module geometry, driven by the currently-visible
    /// content's `.atlasModuleGeometry(...)` preference. Floating
    /// island only when the user is at the Home tab's root; every
    /// non-Home tab and every pushed detail screen overrides this
    /// to `.fullEdge`. Anchoring the buttons to the same screen-y
    /// across both modes (see `AtlasTabBar`) means the visual
    /// difference between the two is purely cosmetic — what gets
    /// painted in the 8pt outer gap + home-indicator strip below
    /// the buttons.
    @State private var moduleGeometry: AtlasModuleGeometry = .floatingIsland

    private var extendsToScreenEdges: Bool {
        moduleGeometry == .fullEdge
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent

            // Mini-player + tab bar stack at the bottom of every tab.
            // The mini-player is always present — it shows the active
            // tour, or a muted "Nothing playing" idle state. On the
            // Home tab's root the stack floats as a rounded island
            // (per PR #60); on every other surface — including
            // pushed detail screens reached from Home — it extends
            // flush to the screen edges so the bar reads the same
            // way past the map.
            VStack(spacing: 0) {
                MiniPlayerBar(
                    tour: nowPlayingTour,
                    maker: nowPlayingTour.flatMap { dataService.maker(for: $0) },
                    extendsToScreenEdges: extendsToScreenEdges
                ) {
                    showingFullPlayer = true
                }
                AtlasTabBar(
                    selected: $selectedTab,
                    extendsToScreenEdges: extendsToScreenEdges
                )
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: nowPlayingTour?.id)
        .animation(.easeInOut(duration: 0.25), value: moduleGeometry)
        .onPreferenceChange(AtlasModuleGeometryKey.self) { newGeometry in
            moduleGeometry = newGeometry
        }
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

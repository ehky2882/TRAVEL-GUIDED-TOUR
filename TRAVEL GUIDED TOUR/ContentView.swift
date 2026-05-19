import SwiftUI

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

    @State private var selectedTab: AtlasTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent

            AtlasTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            locationManager.requestPermission()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:    HomeView()
        case .library: LibraryView()
        case .me:      SettingsView()
        }
    }
}

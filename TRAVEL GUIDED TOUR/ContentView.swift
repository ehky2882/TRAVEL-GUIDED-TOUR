import SwiftUI

struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            MapView()
                .tabItem {
                    Label("Explore", systemImage: "map")
                }

            CollectionsView()
                .tabItem {
                    Label("Favorites", systemImage: "bookmark")
                }

            MessagesPlaceholderView()
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right")
                }

            SettingsView()
                .tabItem {
                    Label("Me", systemImage: "person.crop.circle")
                }
        }
        .tint(AtlasColors.accent)
        .onAppear {
            locationManager.requestPermission()
        }
    }
}

private struct MessagesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.md) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 48))
                    .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
                Text("Messages")
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)
                Text("Coming soon")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(AtlasColors.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtlasColors.background)
            .navigationTitle("Messages")
            .inlineNavigationBarTitle()
        }
    }
}

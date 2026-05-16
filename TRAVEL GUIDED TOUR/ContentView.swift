import SwiftUI

/// Root tab bar. Per owner decision (M-map cut), the V1 shell drops
/// from 5 tabs to 3:
///   Home    — map-dominant discovery + curated rails
///   Library — Saved / Downloaded / Recently played
///   Me      — settings + post-V1 placeholders (Sign in, Messages)
///
/// The standalone Map / Explore tab was redundant against Home's
/// embedded map. The Messages tab survives as a "Coming soon" row
/// inside Settings so the entry point exists once messaging ships
/// post-V1.
struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "bookmark")
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

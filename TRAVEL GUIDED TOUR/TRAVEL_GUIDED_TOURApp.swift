//
//  TRAVEL_GUIDED_TOURApp.swift
//  TRAVEL GUIDED TOUR
//
//  Created by Edward Yung on 3/4/26.
//

import SwiftUI

@main
struct TRAVEL_GUIDED_TOURApp: App {
    @State private var dataService = DataService()
    @State private var libraryStore = LibraryStore()
    @State private var locationManager = LocationManager()
    @State private var audioPlayer = AudioPlayerService()
    @State private var recentlyViewed = RecentlyViewedStore()
    @State private var recentSearches = RecentSearchStore()
    @State private var proximityMonitor = ProximityMonitor()
    @State private var tourDownloader = TourDownloader()
    @State private var isLoading = true
    /// Mirrors the `@AppStorage` key used by SettingsView's Appearance
    /// picker. Wired here so `.preferredColorScheme` applies app-wide.
    @AppStorage("colorSchemePreference") private var colorSchemePreference: ColorSchemePreference = .system

    var body: some Scene {
        WindowGroup {
            if isLoading {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                isLoading = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .environment(dataService)
                    .environment(libraryStore)
                    .environment(locationManager)
                    .environment(audioPlayer)
                    .environment(recentlyViewed)
                    .environment(recentSearches)
                    .environment(proximityMonitor)
                    .environment(tourDownloader)
                    .preferredColorScheme(colorSchemePreference.colorScheme)
            }
        }
    }
}

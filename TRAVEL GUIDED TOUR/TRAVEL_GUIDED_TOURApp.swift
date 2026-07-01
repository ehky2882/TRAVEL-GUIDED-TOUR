//
//  TRAVEL_GUIDED_TOURApp.swift
//  TRAVEL GUIDED TOUR
//
//  Created by Edward Yung on 3/4/26.
//

import SwiftUI

@main
struct TRAVEL_GUIDED_TOURApp: App {
    init() {
        // Expand URLCache limits so disk-cached images survive app
        // restarts and cold launches without a network round-trip.
        // Default limits (4 MB memory / 20 MB disk) are too small for
        // 138+ hero images. ImageCache handles in-session RAM; URLCache
        // handles cross-launch disk persistence.
        URLCache.shared = URLCache(
            memoryCapacity: 50_000_000,
            diskCapacity: 200_000_000
        )
    }

    @State private var dataService = DataService()
    @State private var authService = AuthService()
    @State private var libraryStore = LibraryStore()
    @State private var locationManager = LocationManager()
    @State private var audioPlayer = AudioPlayerService()
    @State private var recentlyViewed = RecentlyViewedStore()
    @State private var recentSearches = RecentSearchStore()
    @State private var proximityMonitor = ProximityMonitor()
    @State private var tourDownloader = TourDownloader()
    /// Shared between `ContentView` (main window) and the
    /// `BottomModuleRoot` (secondary higher-level window) so the
    /// tab bar in the second window can drive the main window's
    /// tab content. See `Components/BottomModuleWindow.swift`.
    @State private var appShared = AppSharedState()
    /// App-wide tour-detail presentation channel. Promoted from
    /// `ContentView` to the App level so the bottom-module window
    /// can read it too (the mini-player + tab bar's geometry
    /// switches between floating-island and full-edge based on
    /// whether a detail is up).
    @State private var tourPresenter = TourPresenter()
    /// Tracks how many pushed detail screens are on top of any tab's
    /// nav stack. Promoted from `ContentView` to the App level so the
    /// bottom-module window (a separate `UIWindow`) can read it too:
    /// the mini-player + tab bar's island/full-edge geometry — and the
    /// Home drawer's visibility — switch off `isShowingDetail`, so both
    /// windows must observe the SAME instance. Details reached via a
    /// `NavigationLink` push (Search, Maker-via-Search) keep
    /// `tourPresenter.presentedTour == nil`, so this counter is the
    /// only signal that flips the chrome to full-edge for them.
    @State private var navState = AtlasNavigationState()
    /// On-device "saved makers" bookmark store. App-level so every
    /// surface that can reach a maker (Home/Search push, the
    /// tour-detail sheet's stack, the player window) and the Library
    /// tab all read + mutate the same instance.
    @State private var savedMakersStore = SavedMakersStore()
    /// Created once content appears (so it can capture the auth + store
    /// instances). Syncs a signed-in user's library + saved makers to Supabase;
    /// retained here for the app's lifetime. See `Data/SyncService.swift`.
    @State private var syncService: SyncService?
    /// Holds the secondary `UIWindow` that renders the mini-player
    /// + tab bar above any UIKit modal presented in the main
    /// window. Installed once on first appearance.
    @State private var bottomModuleWindow = BottomModuleWindowController()
    @State private var isLoading = true
    /// Mirrors the `@AppStorage` key used by SettingsView's Appearance
    /// picker. Wired here so `.preferredColorScheme` applies app-wide.
    @AppStorage("colorSchemePreference") private var colorSchemePreference: ColorSchemePreference = .system
    /// Drives the catalog refresh-on-foreground: returning to `.active` re-runs
    /// the network refresh (debounced inside `DataService`) so reopening the app
    /// picks up new content with no force-quit. See `DataService.refreshOnForeground`.
    @Environment(\.scenePhase) private var scenePhase

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
                    .environment(authService)
                    .environment(libraryStore)
                    .environment(locationManager)
                    .environment(audioPlayer)
                    .environment(recentlyViewed)
                    .environment(recentSearches)
                    .environment(proximityMonitor)
                    .environment(tourDownloader)
                    .environment(appShared)
                    .environment(tourPresenter)
                    .environment(navState)
                    .environment(savedMakersStore)
                    .preferredColorScheme(colorSchemePreference.colorScheme)
                    .task {
                        // Wire up library/saved-makers sync once. Created here
                        // (not as an inline @State default) so it captures the
                        // live auth + store instances; it sets the stores'
                        // write-through hooks and runs the sign-in merge.
                        if syncService == nil {
                            syncService = SyncService(
                                auth: authService,
                                library: libraryStore,
                                savedMakers: savedMakersStore,
                                recentlyViewed: recentlyViewed
                            )
                        }
                        // Record listening progress on every pause/end/stop,
                        // regardless of which player UI is showing, so the
                        // Library "Recents" list always updates (it used to be
                        // recorded only inside the full-screen player).
                        audioPlayer.onProgressCheckpoint = { sourceId, seconds, completed in
                            guard let tourId = UUID(uuidString: sourceId) else { return }
                            libraryStore.updateProgress(
                                tourId,
                                listenedSeconds: seconds,
                                completed: completed
                            )
                        }
                    }
                    .onChange(of: scenePhase) { _, phase in
                        // Returning to the foreground re-pulls the catalog so a
                        // plain relaunch picks up new content. DataService
                        // debounces this against the cold-launch / last refresh.
                        if phase == .active {
                            Task { await dataService.refreshOnForeground() }
                        }
                    }
                    .onAppear {
                        // Install the secondary higher-level window
                        // for the mini-player + tab bar. Captures
                        // the same `@State` services so the second
                        // window's content has access to the same
                        // audio player, data, etc. as `ContentView`.
                        // `interactiveBottomInset` tells the
                        // window's hit-test override to pass
                        // touches above this strip through to the
                        // main window.
                        bottomModuleWindow.install(
                            interactiveBottomInset: AtlasBottomModule.height()
                        ) {
                            BottomModuleRoot()
                                .environment(dataService)
                                .environment(authService)
                                .environment(libraryStore)
                                .environment(locationManager)
                                .environment(audioPlayer)
                                .environment(recentlyViewed)
                                .environment(recentSearches)
                                .environment(proximityMonitor)
                                .environment(tourDownloader)
                                .environment(appShared)
                                .environment(tourPresenter)
                                .environment(navState)
                                .environment(savedMakersStore)
                            // No `.preferredColorScheme(...)` here:
                            // the install closure is evaluated ONCE
                            // and would freeze the host
                            // controller's `overrideUserInterfaceStyle`
                            // at the install-time value, shadowing
                            // the window-level override applied
                            // below. The window override + .onChange
                            // hook is the single source of truth for
                            // the second window's trait collection.
                        }
                        // SwiftUI's `.preferredColorScheme` doesn't
                        // propagate into a manually-created
                        // UIWindow, so bridge the preference
                        // directly onto the second window's
                        // `overrideUserInterfaceStyle`. Without
                        // this, the second window's trait
                        // collection follows SYSTEM appearance and
                        // the bars render inverted whenever the
                        // picker disagrees with the system.
                        bottomModuleWindow.apply(preference: colorSchemePreference)
                    }
                    .onChange(of: colorSchemePreference) { _, newValue in
                        bottomModuleWindow.apply(preference: newValue)
                    }
                    // NOTE: the full player is presented from within the
                    // bottom-module window itself (see `BottomModuleRoot`),
                    // so there's no longer any need to hide/show that
                    // window while the player is up — the cover slides
                    // over the module in the same window.
            }
        }
    }
}

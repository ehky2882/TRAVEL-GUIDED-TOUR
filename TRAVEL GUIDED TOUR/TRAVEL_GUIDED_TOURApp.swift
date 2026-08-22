//
//  TRAVEL_GUIDED_TOURApp.swift
//  TRAVEL GUIDED TOUR
//
//  Created by Edward Yung on 3/4/26.
//

import SwiftUI
import Foundation

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
        // AuthService is shared by MakerProfileService (and SyncService, created
        // later in .task), so build it here and hand the same instance in.
        let auth = AuthService()
        _authService = State(initialValue: auth)
        _makerProfileService = State(initialValue: MakerProfileService(auth: auth))
        _makerTourService = State(initialValue: MakerTourService(auth: auth))
        _followService = State(initialValue: FollowService(auth: auth))
        _listService = State(initialValue: TourListService(auth: auth))
        _purchaseService = State(initialValue: PurchaseService(auth: auth))
    }

    @State private var dataService = DataService()
    @State private var authService: AuthService
    /// The signed-in user's own creator profile (their `makers` row). Loaded by
    /// the Profile tab; created/edited via the profile editor. See
    /// `Data/MakerProfileService.swift`.
    @State private var makerProfileService: MakerProfileService
    /// The follow graph (batch D): follow/unfollow + counts. Shares `AuthService`.
    @State private var followService: FollowService
    /// Paid tours (V2 Step 6): StoreKit purchases + which tours this account
    /// owns. Shares `AuthService` because entitlements are per-account — that
    /// is what lets a purchase follow the user to a new phone.
    @State private var purchaseService: PurchaseService
    /// The signed-in user's own tours (all statuses) + draft creation. Loaded by
    /// the Profile tab. See `Data/MakerTourService.swift`.
    @State private var makerTourService: MakerTourService
    /// The signed-in user's lists — curated, ordered collections of whole
    /// tours. Shares `AuthService`. See `Data/TourListService.swift`.
    @State private var listService: TourListService
    @State private var libraryStore = LibraryStore()
    @State private var savedPlacesStore = SavedPlacesStore()
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
    /// Group Listen (SharePlay-style synced group listening). Built here, its
    /// service dependencies wired in `.task` (so it captures the same live
    /// `@State` instances); injected app-wide + into the bottom-module window
    /// (the banner). See `Features/GroupListen/`.
    @State private var groupListen = GroupListenCoordinator()
    /// App-wide tour-detail presentation channel. Promoted from
    /// `ContentView` to the App level so the bottom-module window
    /// can read it too (the mini-player + tab bar's geometry
    /// switches between floating-island and full-edge based on
    /// whether a detail is up).
    @State private var tourPresenter = TourPresenter()
    /// App-wide channel for presenting a maker page from a deep link (a shared
    /// maker link). Makers are otherwise only *pushed* onto local nav stacks;
    /// this drives a `.sheet` in `ContentView`. See `MakerPresenter`.
    @State private var makerPresenter = MakerPresenter()
    @State private var placePresenter = PlacePresenter()
    @State private var listPresenter = TourListPresenter()
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
    /// App-wide transient-toast channel. Injected into both windows; the toast
    /// itself renders in the bottom-module window (above every modal). See
    /// `Components/AtlasToast.swift`.
    @State private var toastCenter = ToastCenter()
    /// Created once content appears (so it can capture the auth + store
    /// instances). Syncs a signed-in user's library to Supabase;
    /// retained here for the app's lifetime. See `Data/SyncService.swift`.
    @State private var syncService: SyncService?
    /// Holds the secondary `UIWindow` that renders the mini-player
    /// + tab bar above any UIKit modal presented in the main
    /// window. Installed once on first appearance.
    @State private var bottomModuleWindow = BottomModuleWindowController()
    /// Whether the launch splash is still covering the app. Replaces the old
    /// `isLoading` Bool, which a fixed 2-second timer flipped; readiness now
    /// decides — see `LaunchGate` for why, and for the floor and ceiling that
    /// bound it.
    @State private var launchState = LaunchState()
    /// Warms the first screenful of card photos during the splash so the drawer
    /// arrives complete. Owner decision 2026-08-22: "ready including photos".
    @State private var imageWarmup = LaunchImageWarmup()
    /// A tour deep link that arrived during the launch splash (cold launch),
    /// held until `ContentView` — which hosts the detail presenter — is mounted.
    @State private var pendingDeepLink: DeepLink?
    /// Mirrors the `@AppStorage` key used by SettingsView's Appearance
    /// picker. Wired here so `.preferredColorScheme` applies app-wide.
    @AppStorage("colorSchemePreference") private var colorSchemePreference: ColorSchemePreference = .system
    /// Drives the catalog refresh-on-foreground: returning to `.active` re-runs
    /// the network refresh (debounced inside `DataService`) so reopening the app
    /// picks up new content with no force-quit. See `DataService.refreshOnForeground`.
    @Environment(\.scenePhase) private var scenePhase
    /// Honoured by the hand-off: with Reduce Motion on the mark doesn't travel
    /// and the pins don't bloom — the splash simply cross-dissolves, which is
    /// what shipped in 1.1 (99) and is already a complete hand-off.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Refresh the signed-in user's own lists (Library's Lists tab).
    private func refreshLists() async {
        async let mine: Void = listService.loadMyLists()
        async let saved: Void = listService.loadSavedLists()
        _ = await (mine, saved)
    }

    /// Refresh the signed-in user's creator profile and their own tours (Me
    /// tab). The tours query needs the maker row's id, so these two stay
    /// ordered.
    private func refreshOwnMakerAndTours() async {
        await makerProfileService.loadMyMaker()
        if let makerId = makerProfileService.myMaker?.id {
            await makerTourService.loadMyTours(makerId: makerId)
        }
    }

    var body: some Scene {
        WindowGroup {
            // ContentView is mounted from the FIRST frame and the splash sits
            // over it, rather than the two being the arms of an `if`. That one
            // change is where the snappiness comes from: MKMapView's creation,
            // the first clustering pass over the whole catalog, the drawer, and
            // the mini-player window's install all happen while the brass dot
            // is still pulsing, instead of in front of the user afterwards.
            ContentView()
                .environment(dataService)
                .environment(authService)
                .environment(makerProfileService)
                .environment(followService)
                .environment(purchaseService)
                .environment(makerTourService)
                .environment(listService)
                .environment(libraryStore)
                .environment(savedPlacesStore)
                .environment(locationManager)
                .environment(audioPlayer)
                .environment(recentlyViewed)
                .environment(recentSearches)
                .environment(proximityMonitor)
                .environment(tourDownloader)
                .environment(appShared)
                .environment(tourPresenter)
                .environment(makerPresenter)
                .environment(placePresenter)
                .environment(listPresenter)
                .environment(navState)
                .environment(toastCenter)
                .environment(groupListen)
                // So ContentView can render the mini-player + tab bar inline
                // while the secondary window isn't installed. Without that
                // fallback, a failed install means no bars for the session.
                .environment(bottomModuleWindow)
                .preferredColorScheme(colorSchemePreference.colorScheme)
                .task {
                    // App Store screenshot run only — no-op in a shipping
                    // build (gated on a launch argument, see UITestSupport).
                    // Runs before the sync wiring below so it can never
                    // write seeded rows through to Supabase.
                    UITestSupport.seedLibraryIfRequested(
                        tours: dataService.tours,
                        into: libraryStore
                    )
                    // Pre-warm the Me tab at launch so its data is already
                    // loaded before the user first opens it — the services
                    // also hydrate from a cached snapshot at init (instant
                    // first paint), and this refreshes them now rather than
                    // waiting for the first Me-tab tap. Non-blocking so it
                    // doesn't delay sync setup / deep-link handling below.
                    Task {
                        guard authService.isSignedIn else { return }
                        // The user's lists back the Library tab, and they
                        // don't need the maker row — so they refresh
                        // alongside it rather than behind it. Both services
                        // hydrate from disk at init, so this only replaces
                        // a cached shape with a current one; without it the
                        // first Library tap of a launch is what starts the
                        // clock, and the tab settles in front of the user.
                        async let lists: Void = refreshLists()
                        async let profile: Void = refreshOwnMakerAndTours()
                        _ = await (lists, profile)
                    }
                    // Wire the Group Listen coordinator's dependencies once
                    // (it's constructed dependency-free so it can be injected
                    // into the environment before this runs).
                    groupListen.attach(
                        audioPlayer: audioPlayer,
                        appShared: appShared,
                        dataService: dataService,
                        tourDownloader: tourDownloader,
                        proximityMonitor: proximityMonitor,
                        auth: authService
                    )
                    // Wire up library/saved-makers sync once. Created here
                    // (not as an inline @State default) so it captures the
                    // live auth + store instances; it sets the stores'
                    // write-through hooks and runs the sign-in merge.
                    if syncService == nil {
                        syncService = SyncService(
                            auth: authService,
                            library: libraryStore,
                            recentlyViewed: recentlyViewed,
                            savedPlaces: savedPlacesStore
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
                    // NOTE: a deep link captured during the splash is
                    // presented by `runLaunchGate`, after hand-off — this
                    // task now runs while the splash is still up, so
                    // presenting here would put a layer behind it.
                }
                .onChange(of: scenePhase) { _, phase in
                    // Returning to the foreground re-pulls the catalog so a
                    // plain relaunch picks up new content. DataService
                    // debounces this against the cold-launch / last refresh.
                    if phase == .active {
                        Task { await dataService.refreshOnForeground() }
                        // Recover the bottom-module window if the
                        // cold-launch `.onAppear` fired before any
                        // scene reached `.foregroundActive` (a timing
                        // race that left the mini-player + tab bar
                        // missing for the whole session). `install()`
                        // is idempotent, so once the window exists
                        // this is a permanent no-op.
                        installBottomModule()
                    }
                }
                .onAppear {
                    // Install the secondary higher-level window for
                    // the mini-player + tab bar. See
                    // `installBottomModule()` — factored so this
                    // call site and the `scenePhase == .active`
                    // recovery build the window identically.
                    installBottomModule()
                }
                // Level-triggered backstop. Every other install trigger is
                // edge-driven (a single `.onAppear`, a `scenePhase`
                // *change*, a one-shot activation notification), so a
                // launch that misses all of them left the mini-player + tab
                // bar missing for the whole session. This re-checks the
                // actual state a beat after mount; `install()` is
                // idempotent, so it's a no-op in the normal case.
                .task {
                    guard !bottomModuleWindow.isInstalled else { return }
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !bottomModuleWindow.isInstalled else { return }
                    installBottomModule()
                }
                .onChange(of: colorSchemePreference) { _, newValue in
                    bottomModuleWindow.apply(preference: newValue)
                }
                // Deep links while the app is already running route straight
                // through (catalog is in memory; ContentView is mounted).
                .onOpenURL(perform: handleDeepLink)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb, perform: handleUserActivity)
                // NOTE: the full player is presented from within the
                // bottom-module window itself (see `BottomModuleRoot`),
                // so there's no longer any need to hide/show that
                // window while the player is up — the cover slides
                // over the module in the same window.
                .environment(launchState)
                // The splash covers the whole app, including the inline
                // fallback bars. It cannot cover the mini-player's separate
                // window, though — that sits a level above every window in
                // this scene — so `runLaunchGate` keeps that one hidden
                // until hand-off rather than relying on z-order.
                .overlay {
                    if launchState.isCovering {
                        // No `.transition` — the fade is inside the view, driven
                        // by `handOffProgress`, so the mark and the ground move
                        // on different clocks. A transition here would
                        // cross-fade the whole composition at once and flatten
                        // the choreography back out.
                        SplashView(
                            handOff: launchState.handOffProgress,
                            reduceMotion: reduceMotion
                        )
                    }
                }
                .task { await runLaunchGate() }
        }
    }

    // MARK: - Launch

    /// Holds the splash until the app behind it is actually ready, then hands
    /// off. Polls rather than observing because the three inputs come from
    /// three different places (the catalog, CoreLocation, the clock) and a
    /// tenth of a second of latency on a decision this coarse costs nothing.
    ///
    /// Everything after the hand-off is the choreography: the splash
    /// cross-dissolves, the bars' window comes back, and any link that arrived
    /// cold is presented now that there is something to present it over.
    @MainActor
    private func runLaunchGate() async {
        let startedAt = Date()
        while launchState.isSplashVisible {
            // Start warming photos the moment there is a catalog to pick them
            // from. Idempotent, so polling can't restart it.
            if !dataService.tours.isEmpty {
                imageWarmup.start(
                    tours: dataService.tours,
                    libraryEntries: libraryStore.entries,
                    recentlyViewedIds: recentlyViewed.tourIds,
                    userLocation: locationManager.userLocation
                )
            }
            let ready = LaunchGate.isReady(
                elapsed: Date().timeIntervalSince(startedAt),
                catalogLoaded: !dataService.tours.isEmpty,
                locationSettled: LaunchGate.locationSettled(
                    status: locationManager.authorizationStatus,
                    hasFix: locationManager.userLocation != nil
                ),
                imagesReady: imageWarmup.isReady
            )
            if ready { break }
            try? await Task.sleep(for: .seconds(LaunchGate.pollInterval))
            // A cancelled task must not strand the user on the splash.
            if Task.isCancelled { break }
        }
        // Unhide FIRST: the window is already built, so this is just a
        // visibility flip, and doing it before the hand-off means the bars are
        // simply present when the splash clears rather than arriving after it.
        bottomModuleWindow.setHidden(false)
        await playHandOff()
        if let link = pendingDeepLink {
            pendingDeepLink = nil
            try? await Task.sleep(for: .milliseconds(350))
            present(link)
        }
    }

    /// The hand-off: the wordmark lifts, the mark contracts onto the user's
    /// position and ripples, and the pins bloom outward from it.
    ///
    /// One animated value drives all of it (`LaunchState.handOffProgress`) —
    /// see that property for why it is a value rather than a set of
    /// transitions. `linear` is deliberate: the shaping lives in the ramps in
    /// `LaunchBloom`, so an eased driver would ease every sub-animation twice.
    @MainActor
    private func playHandOff() async {
        launchState.beginHandOff()

        // Reduce Motion gets the plain cross-dissolve this replaced. That is
        // already a complete hand-off, so there is nothing to reintroduce.
        let duration = reduceMotion ? LaunchBloom.reducedMotionDuration : LaunchBloom.duration

        withAnimation(.linear(duration: duration)) {
            launchState.setHandOffProgress(1)
        }

        // 🔴 The bump lands ON THE SETTLE — the instant the module, the search
        // bar and the drawer come to rest together. It used to fire mid-sequence
        // when the mark landed, which the owner heard immediately: *"the haptic
        // is at the wrong beat, it's not synced with the things settling into
        // place."* Deliberately the same soft impact the geofence fires on
        // arriving at a stop. Silent in the Simulator — device-only to judge.
        try? await Task.sleep(for: .seconds(duration * LaunchBloom.settleFraction))
        if !reduceMotion { AtlasHaptics.impact(.medium) }

        // Tear the overlay down only once nothing of it is still animating.
        launchState.settle()
    }


    // MARK: - Bottom-module window

    /// Installs the secondary higher-level window hosting the
    /// mini-player + tab bar, injecting the same `@State` services the
    /// main window's `ContentView` uses so both windows share one
    /// audio player, data service, etc.
    ///
    /// Called from **two** sites — the App body's `.onAppear` and the
    /// `scenePhase == .active` handler — so the cold-launch race (where
    /// `.onAppear` fires before any scene is `.foregroundActive`) can
    /// recover. `install()` is idempotent (`window == nil` guard), so
    /// only the first successful call builds the window; the rest are
    /// no-ops. Factoring it here keeps the two call sites' environment
    /// injection from drifting apart.
    private func installBottomModule() {
        // The module's window sits one level ABOVE every window in this scene,
        // so it would paint over the splash. Install it anyway — building it
        // during the splash is the whole point, and it arriving after the map
        // is the most visible "still loading" tell there was — but keep it
        // hidden until `runLaunchGate` hands off.
        //
        // ⚠️ Whoever hides this owns unhiding it (see `setHidden`). The gate's
        // ceiling guarantees hand-off runs, and it unhides unconditionally.
        if launchState.isSplashVisible {
            bottomModuleWindow.setHidden(true)
        }
        bottomModuleWindow.install(
            interactiveBottomInset: AtlasBottomModule.height()
        ) {
            // The install-time inset is only a first guess; the module reports
            // its real painted height (which grows when the Group Listen banner
            // appears above the mini-player) so the window claims touches over
            // all of it. Without this the banner's Leave button was untappable.
            BottomModuleRoot(onInteractiveHeightChange: { [bottomModuleWindow] height in
                bottomModuleWindow.setInteractiveBottomInset(height)
            })
                .environment(launchState)
                .environment(dataService)
                .environment(authService)
                .environment(followService)
                .environment(purchaseService)
                .environment(makerProfileService)
                .environment(libraryStore)
                .environment(savedPlacesStore)
                .environment(locationManager)
                .environment(audioPlayer)
                .environment(recentlyViewed)
                .environment(recentSearches)
                .environment(proximityMonitor)
                .environment(tourDownloader)
                .environment(appShared)
                .environment(tourPresenter)
                .environment(makerPresenter)
                .environment(placePresenter)
                .environment(listPresenter)
                .environment(navState)
                .environment(toastCenter)
                .environment(groupListen)
            // No `.preferredColorScheme(...)` here: the install closure
            // is evaluated ONCE and would freeze the host controller's
            // `overrideUserInterfaceStyle` at the install-time value,
            // shadowing the window-level override. The window override
            // (`apply`) + the `.onChange` hook are the single source of
            // truth for the second window's trait collection.
        }
        // SwiftUI's `.preferredColorScheme` doesn't propagate into a
        // manually-created UIWindow, so bridge the preference directly
        // onto the second window's `overrideUserInterfaceStyle`.
        // Without this the second window follows SYSTEM appearance and
        // the bars render inverted when the picker disagrees with it.
        bottomModuleWindow.apply(preference: colorSchemePreference)
    }

    // MARK: - Deep linking

    /// Universal Links (`applinks:` https) are delivered as a browsing user
    /// activity; unwrap the URL and route it like any other deep link.
    private func handleUserActivity(_ activity: NSUserActivity) {
        guard activity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = activity.webpageURL else { return }
        handleDeepLink(url)
    }

    /// Entry point for both Universal Links and the `dozent://` custom scheme.
    /// Parses the URL; presents immediately when running, or stashes it for
    /// after the launch splash on a cold start. Unrecognized URLs are ignored.
    private func handleDeepLink(_ url: URL) {
        guard let link = DeepLinkParser.parse(url) else { return }
        if launchState.isSplashVisible {
            pendingDeepLink = link
        } else {
            present(link)
        }
    }

    /// Resolves a parsed link against the loaded catalog and presents it via the
    /// shared `TourPresenter`. An unknown/invalid id is a no-op — the app just
    /// opens to Home rather than crashing.
    private func present(_ link: DeepLink) {
        switch link {
        case .tour(let id):
            if let tour = dataService.tour(by: id) {
                tourPresenter.present(tour)
            }
        case .maker(let id):
            if let maker = dataService.maker(by: id) {
                makerPresenter.present(maker)
            }
        case .list(let id):
            // Unlike a tour or a maker, a list isn't in the catalog — it lives
            // in Supabase and has to be fetched. RLS decides: a link to an
            // Only-me list simply returns nothing, and the app opens to Home,
            // which is the right answer for a link its owner didn't mean to
            // share.
            Task { @MainActor in
                guard let fetched = await listService.list(byId: id) else {
                    toastCenter.show(
                        "That list isn't available any more.",
                        style: .error
                    )
                    return
                }
                // The same slide-up layer every other entry point uses. It
                // used to be a sheet of its own, which is why a shared list
                // was the one copy of this screen that closed differently.
                listPresenter.present(listId: fetched.list.id, preloaded: fetched.list)
            }
        case .place(let id):
            if let place = dataService.place(by: id) {
                placePresenter.present(place)
            }
        case .group(let code):
            // A join QR scanned with the system Camera app lands here. No tour
            // id is needed — the leader broadcasts what the group is playing,
            // and the session banner provides the confirmation. Joining is
            // account-gated, so say something when it can't proceed rather than
            // appearing to do nothing.
            if groupListen.join(code: code) == false {
                toastCenter.show(
                    "Sign in to listen together with a group.",
                    style: .error
                )
            }
        }
    }
}

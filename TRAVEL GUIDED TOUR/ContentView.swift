import SwiftUI
import Foundation

/// Root shell — V1 has 3 surfaces (Home / Library / Me). Renders
/// the tab CONTENT (map/drawer for Home, Library, Settings) only —
/// the mini-player + tab bar are hoisted out into a separate
/// higher-level `UIWindow` (see `Components/BottomModuleWindow.swift`)
/// so the UIKit-presented tour detail slides up *behind* them.
///
/// **Tour detail presentation.** Detail screens come up via a
/// UIKit-backed `BottomLayerController` that slides up from the
/// bottom and stops short of the bottom-module height (mini-player +
/// tab bar). This isn't a SwiftUI `.sheet` (covers the bottom
/// module) nor a hand-rolled `.offset` layer (the previous approach
/// — fighting SwiftUI's animation system at every step). The UIKit
/// bridge gives us system-quality spring physics, natural
/// touch-through to the underlying mini-player + tab bar in the
/// un-covered region, and proper view-controller-life-cycle handling
/// of the inner SwiftUI content. See
/// `Components/BottomLayerPresentation.swift` for the full
/// machinery.
struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(SavedPlacesStore.self) private var savedPlacesStore
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(ProximityMonitor.self) private var proximityMonitor
    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(AppSharedState.self) private var appShared
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(MakerPresenter.self) private var makerPresenter
    @Environment(PlacePresenter.self) private var placePresenter
    @Environment(TourListPresenter.self) private var listPresenter
    @Environment(FollowService.self) private var followService
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(AuthService.self) private var authService
    @Environment(TourListService.self) private var listService
    @Environment(GroupListenCoordinator.self) private var groupListen
    /// Optional so previews and any host that doesn't build the secondary window
    /// still render. When present and not installed, the bottom module is drawn
    /// inline as a fallback — see the render site in `body`.
    @Environment(BottomModuleWindowController.self) private var bottomModuleWindow: BottomModuleWindowController?

    /// `.onAppear` fires every time the view re-attaches (tab switch,
    /// returning from background, etc.). Request location permission
    /// once per process so we don't repeatedly hit
    /// `CLLocationManager.requestWhenInUseAuthorization()` — iOS no-ops
    /// after the first call but the redundancy was conceptually wrong
    /// (audit P3-7).
    @State private var didRequestLocationPermission = false
    /// The home drawer's detent, lifted out of `HomeView` so it
    /// survives HomeView being recreated on tab switches. Starts
    /// half-open on a fresh launch so the map (and its pins) is visible
    /// above the drawer — new users were missing the map when it opened
    /// fully-expanded; returning to the Home tab restores whatever
    /// detent the user last left it at.
    @State private var homeSheetDetent: BottomSheetDetent = .medium
    /// State shared between `HomeView`'s map surface and the home
    /// drawer (which is hosted here in `ContentView` so it can stack
    /// z-order on top of the mini-player + tab bar). Both sides read
    /// it via `@Environment`.
    @State private var homeSharedState = HomeSharedState()

    /// Tracks whether any pushed detail screen is currently visible.
    /// Driven by each detail view's `.onAppear` / `.onDisappear`
    /// calling `push()` / `pop()`. Owned at the App level (so the
    /// bottom-module window observes the same instance) and read here
    /// to hide the Home drawer once a detail is pushed.
    @Environment(AtlasNavigationState.self) private var navState

    /// UIKit presentation controller — finds the topmost view
    /// controller in the active window and presents
    /// `TourDetailView` (wrapped in a `UIHostingController`) with
    /// the custom slide-from-bottom transition. Held here so the
    /// transitioning delegate survives the presentation's lifetime.
    @State private var bottomLayer = BottomLayerController(
        bottomInset: AtlasBottomModule.height()
    )

    /// Second UIKit slide-up layer, for presenting a public maker page
    /// as its own top-level screen (via `MakerPresenter`) — a shared
    /// deep link, a Search result, or a saved-maker row. Separate from
    /// `bottomLayer` so a maker can, if needed, stack over a tour (each
    /// controller tracks its own presented VC). Gives makers the same
    /// treatment tours get, replacing the earlier `.sheet` stopgap.
    @State private var makerLayer = BottomLayerController(
        bottomInset: AtlasBottomModule.height()
    )

    /// Third slide-up layer, for a PLACE — a site several tours describe.
    /// Its own controller for the same reason the maker layer has one: a tour
    /// tapped inside a place page has to stack over it, and each controller
    /// tracks its own presented VC.
    @State private var placeLayer = BottomLayerController(
        bottomInset: AtlasBottomModule.height()
    )

    /// Fourth slide-up layer, for a LIST. Its own controller for the same
    /// reason the others have one: a tour tapped inside a list has to stack
    /// over it, and each controller tracks its own presented VC.
    @State private var listLayer = BottomLayerController(
        bottomInset: AtlasBottomModule.height()
    )

    /// True while the tour-detail layer is up (or animating) having
    /// been presented from the Home ROOT — i.e. the drawer was
    /// visible underneath when it came up. While true, the drawer
    /// stays mounted behind the layer instead of being removed, so
    /// dismissing the layer reveals the drawer already sitting at
    /// its old detent ("it stayed there") rather than re-inserting
    /// it after the slide finishes (which read as a flash). Captured
    /// at present time as `pushedDepth == 0` so tours opened from
    /// inside Search/Maker DON'T mount the drawer over those
    /// screens; cleared by the dismiss animation's completion.
    @State private var tourLayerCoversDrawer = false

    /// Whether the launch splash is still up. Optional for the same reason
    /// `HomeView` reads it optionally — nil means "not launching".
    @Environment(LaunchState.self) private var launchState: LaunchState?
    /// The opening's progress, or 1 (fully open) when not launching.
    private var launchZoomProgress: Double {
        guard let launchState, launchState.isCovering else { return 1 }
        return LaunchBloom.zoomProgress(handOff: launchState.handOffProgress)
    }

    /// The drawer's share of the three-edge launch assembly, or 1 when not
    /// launching (so a tab return is instant — the entrance is launch-only).
    private var drawerAssemblyProgress: Double {
        guard let launchState, launchState.isCovering else { return 1 }
        return LaunchBloom.assemblyProgress(handOff: launchState.handOffProgress)
    }


    var body: some View {
        @Bindable var appShared = appShared
        // NOTE on bindings: deliberately NOT using `@Bindable` for
        // `homeSharedState` — `@Bindable`'s `$` projection during
        // body registers an Observable read for the property, so
        // `sheetDragOffset` (written 60×/sec during a drag) would
        // re-evaluate the entire `ContentView` body on every frame.
        // Manual `Binding(get:set:)` captures the reference without
        // touching the tracked property at body time; SwiftUI only
        // reads through the closure when it actually needs the
        // value, which avoids that re-eval storm.
        let dragOffsetBinding = Binding(
            get: { homeSharedState.sheetDragOffset },
            set: { homeSharedState.sheetDragOffset = $0 }
        )
        return ZStack(alignment: .bottom) {
            tabContent

            // Home drawer — only on the Home tab root. Once a detail
            // is pushed (Search, Maker — including the Search→Maker
            // deep-link, which stays on the Home tab and so wouldn't
            // be caught by the tab check alone) the drawer hides so
            // it can't leak its header over the pushed screen.
            // Exception: the tour-detail LAYER presented from the
            // Home root keeps the drawer mounted underneath
            // (`tourLayerCoversDrawer`) — the layer fully covers it,
            // and keeping it in place means the dismiss slide reveals
            // the drawer at its old detent instead of flashing it
            // back in after the animation.
            if appShared.selectedTab == .home
                && (tourLayerCoversDrawer || !navState.isShowingDetail) {
                BottomSheet(
                    detent: $homeSheetDetent,
                    dragOffset: dragOffsetBinding,
                    peekHeight: 80,
                    bottomCornerRadius: 0,
                    bottomReservedHeight: AtlasBottomModule.height(),
                    // .large stops below the search bar + chip row
                    // so they stay anchored at the top of the screen
                    // when the drawer is fully expanded. AtlasSpacing.sm
                    // is a small visual buffer between the chip row's
                    // bottom edge and the drawer's top edge.
                    topReservedHeight: AtlasSpacing.searchAndChipsBlockHeight + AtlasSpacing.sm
                ) {
                    HomeDrawerContent(
                        sheetDetent: $homeSheetDetent
                    )
                }
                // Off-screen until the entrance plays. The sheet lays out
                // bottom-anchored inside a full-screen frame, so translating
                // the whole thing down by more than any phone's height parks
                // it completely out of view without touching its internals.
                // 🔴 Same ramp as the bottom module and the search bar. The
                // drawer travels furthest of the three, so it moves fastest —
                // that is what makes them land on one frame. Owner decision
                // 2026-08-22: *"I want the mid-detent to settle at the same
                // time as the stuff at top."*
                .offset(y: (1 - drawerAssemblyProgress) * Self.drawerEntryOffset)
            }
            // Fallback mini-player + tab bar, rendered in THIS (main) window
            // whenever the secondary higher-level window isn't installed.
            //
            // The bars normally live only in that window, so any failure to
            // install it left the app with no tab bar at all for the whole
            // session — repeatedly reported on the first launch after installing
            // a TestFlight build. Successive fixes there were all bets on scene
            // lifecycle timing, and the symptom kept coming back. This makes the
            // bars unconditional: an ordinary part of the SwiftUI hierarchy,
            // which cannot fail for scene-lifecycle reasons.
            //
            // The retry chain still promotes to the real window within seconds,
            // at which point this disappears (`isInstalled` is observed). While
            // it is showing, the only thing missing is z-order above UIKit
            // modals — a much better failure than an app you can't navigate.
            //
            // `hidesBottomModule` withdraws the bars entirely (the tour
            // wizard, which needs their 126pt). It has to be honoured here as
            // well as on the window, or hiding one would simply reveal the
            // other.
            if let bottomModuleWindow, !bottomModuleWindow.isInstalled,
               !appShared.hidesBottomModule {
                BottomModuleRoot()
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        // 🔴 THE ZOOM. The whole app is revealed through a circular opening that
        // expands from the splash mark — Apple's zoom transition, Material's
        // container transform. The scale and the blur are what give it depth:
        // two layers moving reads as fast at a third of a second, where a
        // cross-dissolve at the same duration reads as sluggish.
        //
        // ⚠️ The mask is applied to the MAIN window only. The mini-player and
        // tab bar live in a separate, higher window that this cannot reach —
        // which is fine, because they are part of the *slide*, not the zoom,
        // and arrive from the bottom edge afterwards.
        //
        // ⚠️ If this ever janks on an older device, the blur is the first thing
        // to drop: it is the expensive half, and the scale carries most of the
        // depth on its own.
        .modifier(LaunchZoomReveal(progress: launchZoomProgress))
        .environment(navState)
        .environment(homeSharedState)
        // NOTE: the full PlayerView is presented from `BottomModuleRoot`
        // (the secondary top window), NOT here — so the cover physically
        // slides up over the mini-player + tab bar in the same window,
        // with no separate hide/show of the module (which used to leave
        // a visible gap during the transition).
        // Permission is requested after hand-off, not on appear. ContentView
        // now mounts underneath the splash, and a system alert over a black
        // screen with a wordmark on it reads as a broken launch. `LaunchGate`
        // treats `notDetermined` as settled precisely so this delay can't
        // stall the gate.
        .onChange(of: launchState?.isSplashVisible ?? false) { _, splashVisible in
            guard !splashVisible else { return }
            requestLocationPermissionIfNeeded()
        }

        .onAppear {
            // Backstop for any host that never injects `LaunchState` (previews,
            // tests): with no splash to wait for, behave exactly as before.
            guard launchState == nil else { return }
            requestLocationPermissionIfNeeded()
        }
        // 🔴 Give each presenter a DIRECT route to take its layer down.
        //
        // The `.onChange` blocks below do the presenting and dismissing, and
        // they run in THIS view — which lives in the main window. While a
        // layer is up that window is fully covered by a UIKit modal, and
        // SwiftUI can stop delivering updates to a covered hierarchy: a
        // `dismiss()` writes its state and the observer never runs, so the
        // control does nothing at all. That is what made the X on tour detail
        // and the bottom tab bar both stop working once you had been into a
        // creator page and back, and it is the same root cause as the dead
        // place pin (#532) and the dead tab bar of session 74.
        //
        // Dismissal needs no view construction, so it can be performed
        // directly and does not have to wait on an observer. Presentation
        // still goes through `.onChange` because the environment injection
        // below has to happen here — a place tapped from inside a layer
        // therefore still pushes in-stack rather than presenting (see
        // `MakerView.openPlaceFromMap`).
        //
        // The `.onChange` else-branches stay as a backstop; both paths are
        // idempotent, because `BottomLayerController.dismiss` no-ops when
        // nothing is presented.
        .onAppear {
            tourPresenter.performDismiss = {
                bottomLayer.dismiss { tourLayerCoversDrawer = false }
            }
            makerPresenter.performDismiss = { makerLayer.dismiss() }
            placePresenter.performDismiss = { placeLayer.dismiss() }
            listPresenter.performDismiss = { listLayer.dismiss() }
        }
        // Paid tours: keep entitlements in step with whoever is signed in.
        // Keyed on `userId` so it re-runs on sign-in, sign-out AND an account
        // switch — the last of which must never leave one account holding the
        // other's unlocks. `handleSignedIn` hydrates from that user's on-disk
        // cache first (so an owned tour is playable offline on the first
        // frame), then confirms against the server and drains any purchase
        // that was paid for but never recorded.
        .task(id: authService.userId) {
            if authService.isSignedIn {
                await purchaseService.handleSignedIn()
            } else {
                purchaseService.handleSignedOut()
            }
        }
        // Load StoreKit products for whichever tiers the catalog uses, so
        // badges can show the buyer's *local* price rather than a USD
        // approximation. Re-runs when the catalog does.
        .task(id: dataService.tours.count) {
            await purchaseService.loadProducts(for: dataService.tours)
        }
        // Drive the UIKit-backed slide-up modal off the presenter's
        // `presentedTour`. When a tour appears: build the SwiftUI
        // root view (with every environment value the detail
        // subtree needs, captured here at body time), hand it to
        // `BottomLayerController` to wrap in a UIHostingController
        // and present via UIKit's custom transition. When the tour
        // goes nil: dismiss. `onDismiss` is wired so a future
        // interactive drag-down would also keep state in sync.
        // Tapping a tab while the detail sheet is up should dismiss
        // it — otherwise the new tab's content swaps in *behind* the
        // detail and the user appears stuck (icon updates, content
        // doesn't). Apple Music does the same: swiping the now-
        // playing modal away is a separate gesture from changing tabs.
        .onChange(of: appShared.selectedTab) { _, _ in
            if tourPresenter.presentedTour != nil {
                tourPresenter.dismiss()
            }
            if makerPresenter.presentedMaker != nil {
                makerPresenter.dismiss()
            }
        }
        // Opening the full player makes it the now-playing surface, so
        // drop any detail sheet underneath it. Otherwise retracting the
        // player lands back on the stale detail sheet — which forces the
        // bottom module into its edge-to-edge form even when the user
        // expects to be back on Home (floating island).
        .onChange(of: appShared.showingFullPlayer) { _, isUp in
            if isUp && tourPresenter.presentedTour != nil {
                tourPresenter.dismiss()
            }
            if isUp && makerPresenter.presentedMaker != nil {
                makerPresenter.dismiss()
            }
        }
        // Bridge geofence-triggered stop playback into shared state
        // so the tour-detail sheet's now-playing indicator can light
        // up the matching stop row. ProximityMonitor stays free of
        // UI-state coupling — the bridge lives here, where both
        // dependencies are already in scope.
        .onChange(of: proximityMonitor.lastEnteredStopId) { _, newStopId in
            if let newStopId {
                appShared.currentPlayingStopId = newStopId
            }
        }
        .onChange(of: tourPresenter.presentedTour?.id) { _, _ in
            if let tour = tourPresenter.presentedTour {
                // Capture BEFORE the layer's TourDetailView registers
                // its own push — depth 0 here means the layer is
                // coming up over the Home root with the drawer
                // visible beneath it.
                tourLayerCoversDrawer = navState.pushedDepth == 0
                bottomLayer.present(
                    NavigationStack {
                        TourDetailView(tour: tour)
                    }
                    .environment(navState)
                    .environment(homeSharedState)
                    .environment(tourPresenter)
                    // MakerView is pushed in-stack from tour detail, and its
                    // MAP tab draws place pins. Without this the presenter is
                    // nil there and tapping a place pin does nothing at all —
                    // silently, because the lookup is optional to keep this
                    // layer from crashing. Same shape as the batch-D Follow
                    // button that went missing for exactly one dropped
                    // injection (build 68 → 69).
                    .environment(placePresenter)
                    .environment(listPresenter)
                    .environment(dataService)
                    .environment(locationManager)
                    .environment(audioPlayer)
                    .environment(libraryStore)
                    .environment(savedPlacesStore)
                    .environment(recentlyViewedStore)
                    .environment(proximityMonitor)
                    .environment(tourDownloader)
                    .environment(appShared)
                    .environment(followService)
                    .environment(authService)
                    .environment(purchaseService)
                    .environment(listService)
                    .environment(groupListen),
                    onDismiss: { tourPresenter.dismiss() }
                )
            } else {
                // Keep the drawer mounted through the slide-down;
                // clear the cover flag only once the layer has fully
                // revealed it (the detail's own navState.pop() fires
                // around the same moment, so the drawer condition
                // hands over seamlessly from one term to the other).
                bottomLayer.dismiss {
                    tourLayerCoversDrawer = false
                }
            }
        }
        // Present a public maker page as its own top-level screen off the
        // presenter's `presentedMaker` — the maker twin of the tour block
        // above. Reached from a shared deep link, a Search result, or a
        // saved-maker row. Uses `.publicStandalone` so MakerView shows an X
        // (there's no back stack to pop). A tour tapped inside slides up
        // over it (topmost-VC presentation); the environment is re-injected
        // here since the UIKit layer doesn't inherit the SwiftUI chain.
        // The place layer: a site several tours describe, reached by tapping a
        // place pin. Same slide-up treatment as tours and makers so it isn't
        // the one screen in the app that behaves differently. The environment
        // is re-injected because the UIKit layer doesn't inherit the SwiftUI
        // chain.
        .onChange(of: placePresenter.presentedPlace?.id) { _, _ in
            if let place = placePresenter.presentedPlace {
                placeLayer.present(
                    PlaceView(place: place, onDismiss: { placePresenter.dismiss() })
                        .environment(navState)
                        .environment(homeSharedState)
                        .environment(tourPresenter)
                        .environment(makerPresenter)
                        .environment(placePresenter)
                    .environment(listPresenter)
                        .environment(dataService)
                        .environment(locationManager)
                        .environment(audioPlayer)
                        .environment(libraryStore)
                        .environment(savedPlacesStore)
                        .environment(recentlyViewedStore)
                        .environment(proximityMonitor)
                        .environment(tourDownloader)
                        .environment(appShared)
                        .environment(followService)
                        .environment(authService)
                        .environment(purchaseService)
                        .environment(listService)
                        .environment(groupListen),
                    onDismiss: { placePresenter.dismiss() }
                )
            } else {
                placeLayer.dismiss()
            }
        }
        // The list layer. A list is a top-level screen wherever you reach it
        // from — Library, a profile, a shared link — so it slides up like the
        // other three rather than pushing onto whichever stack you happened to
        // be in (owner direction, 2026-08-20). `preloaded` is passed straight
        // through so the title is on screen from the first frame.
        .onChange(of: listPresenter.presented?.id) { _, _ in
            if let presentedList = listPresenter.presented {
                listLayer.present(
                    // Wrapped in its own stack, like the maker layer: "Go to
                    // creator" pushes a maker page here rather than stacking a
                    // second layer over this one.
                    NavigationStack {
                        TourListDetailView(
                            target: presentedList,
                            onDismiss: { listPresenter.dismiss() }
                        )
                    }
                        .environment(navState)
                        .environment(homeSharedState)
                        .environment(tourPresenter)
                        .environment(makerPresenter)
                        .environment(placePresenter)
                        .environment(listPresenter)
                        .environment(dataService)
                        .environment(locationManager)
                        .environment(audioPlayer)
                        .environment(libraryStore)
                        .environment(savedPlacesStore)
                        .environment(recentlyViewedStore)
                        .environment(proximityMonitor)
                        .environment(tourDownloader)
                        .environment(appShared)
                        .environment(followService)
                        .environment(authService)
                        .environment(purchaseService)
                        .environment(listService)
                        .environment(groupListen),
                    onDismiss: { listPresenter.dismiss() }
                )
            } else {
                listLayer.dismiss()
            }
        }
        .onChange(of: makerPresenter.presentedMaker?.id) { _, _ in
            if let maker = makerPresenter.presentedMaker {
                makerLayer.present(
                    NavigationStack {
                        MakerView(maker: maker, mode: .publicStandalone)
                    }
                    .environment(navState)
                    .environment(homeSharedState)
                    .environment(tourPresenter)
                    .environment(makerPresenter)
                    .environment(placePresenter)
                    .environment(listPresenter)
                    .environment(dataService)
                    .environment(locationManager)
                    .environment(audioPlayer)
                    .environment(libraryStore)
                    .environment(savedPlacesStore)
                    .environment(recentlyViewedStore)
                    .environment(proximityMonitor)
                    .environment(tourDownloader)
                    .environment(appShared)
                    .environment(followService)
                    .environment(authService)
                    .environment(purchaseService)
                    .environment(listService)
                    .environment(groupListen),
                    onDismiss: { makerPresenter.dismiss() }
                )
            } else {
                makerLayer.dismiss()
            }
        }
        // Resolve the current tour's maker avatar into lock-screen /
        // Control-Center artwork whenever the loaded source changes.
        // Done here (not in AudioPlayerService) because the avatar
        // lives on the maker, which only DataService can resolve from
        // the source id. The resolve is async (remote URL / emoji
        // render); `setArtwork(_:for:)` drops the result if a newer
        // tour has since loaded.
        .onChange(of: audioPlayer.currentSourceId) { _, sourceId in
            #if canImport(UIKit)
            guard let sourceId,
                  let uuid = UUID(uuidString: sourceId),
                  let tour = dataService.tour(by: uuid) else { return }
            let maker = dataService.maker(for: tour)
            Task { @MainActor in
                let image = await MakerArtwork.image(for: maker)
                audioPlayer.setArtwork(image, for: sourceId)
            }
            #endif
        }
    }

    // MARK: - Launch

    /// How far down the drawer is parked before its entrance. Larger than any
    /// iPhone is tall, so the sheet is fully off-screen whatever the device.
    private static let drawerEntryOffset: CGFloat = 1200


    /// Ask for location permission exactly once per session.
    private func requestLocationPermissionIfNeeded() {
        guard !didRequestLocationPermission else { return }
        didRequestLocationPermission = true
        locationManager.requestPermission()
    }

    /// Tab content. **Home is kept permanently mounted** (visibility-
    /// toggled, not `switch`-swapped) so its SwiftUI `Map` — backed by an
    /// `MKMapView` carrying ~509 clustered stop annotations — isn't torn
    /// down and rebuilt every time the user returns to Home. That rebuild
    /// (map re-creation + tile reload + re-adding/re-clustering every
    /// annotation, plus losing `HomeView`'s `@State` camera position back
    /// to the NYC default) is the "return-to-Home lag" the owner reported
    /// on device. Profiling confirmed the Swift-side recompute
    /// (`filteredTours` ≈0.02 ms, cluster ≈1–3 ms) is negligible — the cost
    /// is the map's UIKit reconstruction, which staying mounted eliminates.
    ///
    /// Library / Me keep their existing mount-on-select lifecycle (cheap to
    /// build; some refresh-on-return is fine) and render opaque on top of
    /// the hidden Home, so nothing shows through. While Home is hidden it's
    /// made inert — `allowsHitTesting(false)` stops all map gestures (so the
    /// 60 fps camera-change callbacks can't fire) and `isActive: false`
    /// guards its camera side-effects — so it isn't burning CPU/battery
    /// off-screen.
    @ViewBuilder
    private var tabContent: some View {
        let isHome = appShared.selectedTab == .home
        ZStack {
            HomeView(sheetDetent: $homeSheetDetent, isActive: isHome)
                .opacity(isHome ? 1 : 0)
                .allowsHitTesting(isHome)
                .accessibilityHidden(!isHome)

            switch appShared.selectedTab {
            case .home:    EmptyView()
            case .library: LibraryView()
            case .me:      ProfileView()
            }
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

import SwiftUI
import MapKit
import CoreLocation
import UIKit

/// Map-dominant home screen — AllTrails-style.
///
/// **Layout:**
///   - `ZStack`: map fills entire background; floating search bar +
///     filter chip row at top; persistent BottomSheet at bottom.
///   - Map pins reflect the currently-applied category filter.
///   - Tapping a pin scrolls the drawer's vertical tour list to that
///     tour's card and highlights it (and vice-versa).
///   - Drawer content is a single vertical list of `TourListCard`,
///     filtered by the selected category and sorted by distance from
///     the user (falls back to insertion order without location).
///   - "Continue listening" / "Recently viewed" surface as inline
///     banner rows above the main list when present.
struct HomeView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(TourDownloader.self) private var tourDownloader

    @State private var visibleRegion: MKCoordinateRegion?
    /// Drawer detent — owned by `ContentView` so it persists across
    /// tab switches (returning to Home restores the last detent).
    @Binding var sheetDetent: BottomSheetDetent
    /// True while the map camera is in motion. Retracts the drawer to
    /// peek and fades the recenter button while the user is panning,
    /// then clears when the camera settles.
    @State private var isMapMoving = false
    /// Guards against the map firing camera events during initial
    /// render. Set to true 1 s after the view appears — enough time
    /// for the map's first tile load / settle cycle to complete so
    /// those events don't retract the drawer before the user touches
    /// anything. onEnd-based approach was unreliable because onEnd
    /// fires immediately on first render, making the guard useless.
    @State private var mapInteractionEnabled = false
    /// Lifted out of BottomSheet so the recenter button can read the
    /// drawer's in-progress drag delta and stay glued to its top edge
    /// throughout the drag (not just snap on release).
    @State private var sheetDragOffset: CGFloat = 0
    @State private var selectedCategory: TourCategory? = nil
    @State private var selectedTourId: UUID? = nil
    /// Active map type. Cycled / picked by the map-mode selector
    /// button. Standard is the default — same as Apple Maps.
    @State private var mapMode: MapMode = .standard
    /// Loaded Look Around scene for the current map center, or `nil`
    /// when the center has no Look Around coverage. Probed
    /// asynchronously on every settled camera change so the Look
    /// Around button's disabled state reflects current coverage.
    @State private var lookAroundScene: MKLookAroundScene?
    /// Drives the sheet that presents `LookAroundView`. Held as a Bool
    /// so dismissing the sheet doesn't clear `lookAroundScene` (which
    /// would disable the button until the next probe completes).
    @State private var isShowingLookAround = false
    /// Most recently probed center — used to debounce probes when the
    /// camera reports many `.onEnd` events with the same center.
    @State private var lastProbedCenter: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            // Fallback start (NYC) — overridden on first appear if
            // the user has granted location.
            center: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
            span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        )
    )

    /// Peek-detent height. Sized to fit the drag handle (~16pt) + the
    /// centered header line (~30pt) with some breathing room — and
    /// nothing more. The drawer's `bottomReservedHeight` keeps it
    /// stacked *above* the mini-player + tab bar, so the peek doesn't
    /// need to reserve any height for the floating island itself.
    private let peekHeight: CGFloat = 80

    /// Exact pixel height of the floating mini-player + tab bar stack
    /// at the bottom of the screen. Passed to `BottomSheet` so its
    /// `.large` detent stops short by this amount — the drawer's
    /// bottom edge sits flush against the mini-player's top edge with
    /// no gap, and the drawer's square bottom corners read as visually
    /// continuous with the mini-player. Also fed to the recenter
    /// button's bottom offset so it sits a fixed distance above the
    /// drawer's top edge regardless of which detent is active.
    ///
    /// Sourced from the shared `AtlasBottomModule.height` helper so it
    /// stays in lockstep with the matching `safeAreaInset(.bottom)`
    /// applied to scrollable surfaces on non-Home tabs.
    private var floatingIslandHeight: CGFloat {
        AtlasBottomModule.height(extendsToScreenEdges: false)
    }

    var body: some View {
        // NavigationStack wraps the layout so the tour list cards,
        // quick-resume banners, and any other NavigationLinks have a
        // context to push onto. The nav bar itself is hidden — the
        // floating search bar + filter chips replace it visually.
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    HomeMapSection(
                        tours: filteredTours,
                        userLocation: locationManager.userLocation,
                        userHeading: locationManager.heading,
                        selectedTourId: $selectedTourId,
                        cameraPosition: $cameraPosition,
                        mapMode: mapMode,
                        onCameraChanged: { region in
                            visibleRegion = region
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isMapMoving = false
                            }
                            probeLookAround(at: region.center)
                        },
                        onCameraMoving: {
                            guard mapInteractionEnabled, !isMapMoving else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isMapMoving = true
                                if sheetDetent != .peek {
                                    sheetDetent = .peek
                                }
                            }
                        }
                    )
                    .ignoresSafeArea()

                    VStack(spacing: AtlasSpacing.sm) {
                        SearchBar()
                            .padding(.horizontal, AtlasSpacing.lg)

                        CategoryChipRow(
                            availableCategories: chipPlaceholderCategories,
                            selectedCategory: $selectedCategory
                        )
                    }
                    .padding(.top, AtlasSpacing.sm)

                    BottomSheet(
                        detent: $sheetDetent,
                        dragOffset: $sheetDragOffset,
                        peekHeight: peekHeight,
                        // Square bottom corners read as visually
                        // continuous with the rectangular mini-player
                        // sitting directly below.
                        bottomCornerRadius: 0,
                        bottomReservedHeight: floatingIslandHeight
                    ) {
                        drawerContent(in: geo)
                    }

                    // Floating map-control button stack anchored to
                    // bottom-leading, padded up by the drawer's
                    // *current* visible height — which includes the
                    // in-progress drag delta — so the stack stays glued
                    // to the drawer's top edge during the drag, not
                    // just after release. All three buttons share the
                    // same `MapControlButton` shape per the design rule.
                    mapControlStack
                        .padding(.leading, AtlasSpacing.md)
                        // Drawer now floats *above* the mini-player +
                        // tab bar, so the button's offset from the
                        // screen bottom is the drawer's height PLUS
                        // the reserved floating-island height — that
                        // puts the button a fixed `sm` gap above the
                        // drawer's top edge in every detent.
                        .padding(.bottom, drawerVisibleHeight(in: geo) + floatingIslandHeight + AtlasSpacing.sm)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomLeading
                        )
                        // Hidden at full detent (drawer covers the map)
                        // and while the map is moving (clean panning UX).
                        // Button fades back when the camera settles.
                        // Explicit gentle eases so the fade doesn't snap
                        // with whatever spring drove the drawer/camera.
                        .opacity(sheetDetent == .large || isMapMoving ? 0 : 1)
                        .animation(.easeInOut(duration: 0.5), value: isMapMoving)
                        .animation(.easeInOut(duration: 0.3), value: sheetDetent)
                        .allowsHitTesting(sheetDetent != .large && !isMapMoving)
                }
                .toolbar(.hidden, for: .navigationBar)
                .task {
                    try? await Task.sleep(for: .seconds(1))
                    mapInteractionEnabled = true
                }
                .onChange(of: selectedTourId, initial: false) { _, _ in
                    if selectedTourId != nil && sheetDetent == .peek {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            sheetDetent = .medium
                        }
                    }
                }
            }
        }
    }

    /// Mirrors the height formula BottomSheet uses internally so the
    /// recenter button can sit at a fixed offset above the drawer's
    /// top edge — including during the drag. `sheetDragOffset` is the
    /// in-flight drag delta (negative = dragging up, positive =
    /// dragging down) so the visible height grows/shrinks live with
    /// the user's finger. Does NOT include `floatingIslandHeight` —
    /// callers add that explicitly when they need the drawer's top
    /// position measured from the screen bottom.
    private func drawerVisibleHeight(in geo: GeometryProxy) -> CGFloat {
        let baseHeight: CGFloat
        switch sheetDetent {
        case .peek:   baseHeight = peekHeight
        case .medium: baseHeight = geo.size.height * 0.5
        case .large:  baseHeight = geo.size.height - AtlasSpacing.sm - floatingIslandHeight
        }
        return max(peekHeight, baseHeight - sheetDragOffset)
    }

    // MARK: - Map control buttons

    /// Standard zoom span the recenter button snaps to — roughly
    /// 0.005° ≈ 555m N-S / ~420m E-W at NYC latitude, i.e. a few
    /// city blocks across. Picked to land between "neighborhood
    /// overview" and "block-level detail" so a tap from any zoom
    /// returns the user to a useful local view without overshooting
    /// to a single building.
    private static let recenterSpan = MKCoordinateSpan(
        latitudeDelta: 0.005,
        longitudeDelta: 0.005
    )

    private var mapControlStack: some View {
        VStack(spacing: AtlasSpacing.sm) {
            MapControlButton(systemImage: "binoculars.fill", isEnabled: lookAroundScene != nil) {
                guard lookAroundScene != nil else { return }
                isShowingLookAround = true
            }
            .accessibilityLabel(lookAroundScene != nil ? "Look Around" : "Look Around not available here")

            Menu {
                Picker("Map type", selection: $mapMode) {
                    ForEach(MapMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.iconName).tag(mode)
                    }
                }
            } label: {
                MapControlButtonLabel(systemImage: mapMode.iconName)
            }
            .accessibilityLabel("Map type — \(mapMode.title)")

            MapControlButton(systemImage: "location.fill") {
                recenterOnUser()
            }
            .accessibilityLabel("Recenter on my location")
        }
        .sheet(isPresented: $isShowingLookAround) {
            if let scene = lookAroundScene {
                LookAroundView(scene: scene)
                    .ignoresSafeArea()
            }
        }
    }

    /// Single-action recenter: snap the camera to the user's current
    /// location at the standard zoom, with 2D tilt and a North-up
    /// heading. `.region(...)` sets a non-tilted, north-aligned
    /// camera by default, so resetting all four attributes is just
    /// "build a fresh region centered on the user."
    private func recenterOnUser() {
        guard let user = locationManager.userLocation else { return }
        let region = MKCoordinateRegion(
            center: user.coordinate,
            span: Self.recenterSpan
        )
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(region)
        }
    }

    /// Async-probe Look Around coverage at `coordinate`. Cached on
    /// `lastProbedCenter` so quick successive `.onEnd` events with
    /// the same center don't fire a new request. The result drives
    /// the Look Around button's enabled state — `nil` = no coverage.
    private func probeLookAround(at coordinate: CLLocationCoordinate2D) {
        if let last = lastProbedCenter,
           abs(last.latitude - coordinate.latitude) < 1e-6,
           abs(last.longitude - coordinate.longitude) < 1e-6 {
            return
        }
        lastProbedCenter = coordinate
        Task {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            let scene = try? await request.scene
            await MainActor.run {
                // Drop the result if the camera has moved since the
                // probe started — only the most recent center's scene
                // should bind to the button.
                if let current = lastProbedCenter,
                   abs(current.latitude - coordinate.latitude) < 1e-6,
                   abs(current.longitude - coordinate.longitude) < 1e-6 {
                    lookAroundScene = scene
                }
            }
        }
    }

    // MARK: - Drawer content

    @ViewBuilder
    private func drawerContent(in geo: GeometryProxy) -> some View {
        // Fade the scrollable list in as the drawer opens past peek.
        // At the peek detent the list is hidden entirely — otherwise a
        // sliver of the first card (often a hero image) shows above
        // the tab bar (M-qa finding).
        let visible = drawerVisibleHeight(in: geo)
        let listOpacity = min(1, max(0, (visible - peekHeight) / 90))

        // Clip the visible region to the strip of map between the top
        // of the screen and the drawer's top edge, then count tours
        // with any stop in that strip. At large the drawer covers
        // nearly everything, so we swap the count for a friendly
        // invitation instead of "0 tours in view".
        let aboveDrawerCount = toursInViewCount(in: geo)

        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                // Header — dynamic count for the area in view.
                // Centered to read cleanly at the peek detent where
                // this is the *only* drawer content visible.
                Text(headerText(forCount: aboveDrawerCount))
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.top, AtlasSpacing.sm)
                    .padding(.bottom, AtlasSpacing.md)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AtlasSpacing.md) {
                        // Quick-resume banners — surface above the main
                        // list when the user has progress to pick up.
                        if let resumeTour = continueListeningTour {
                            quickResumeBanner(tour: resumeTour, label: "Continue listening")
                                .id("continue-listening")
                        }
                        if let recentTour = recentlyViewedTour {
                            quickResumeBanner(tour: recentTour, label: "Recently viewed")
                                .id("recently-viewed")
                        }

                        if displayedTours.isEmpty {
                            emptyState
                        } else {
                            ForEach(displayedTours) { tour in
                                TourListCard(
                                    tour: tour,
                                    maker: dataService.maker(for: tour),
                                    isDownloaded: tourDownloader.isDownloaded(tourId: tour.id),
                                    distanceText: distanceText(for: tour),
                                    isSelected: selectedTourId == tour.id
                                )
                                .id(tour.id)
                                .padding(.horizontal, AtlasSpacing.lg)
                            }
                        }
                    }
                    .padding(.top, AtlasSpacing.sm)
                    .padding(.bottom, AtlasSpacing.lg)
                }
                .opacity(listOpacity)
                .allowsHitTesting(listOpacity > 0.01)
                .onChange(of: selectedTourId, initial: false) { _, newId in
                    guard let newId else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newId, anchor: .top)
                    }
                }
            }
        }
    }

    private func quickResumeBanner(tour: Tour, label: String) -> some View {
        NavigationLink {
            TourDetailView(tour: tour)
        } label: {
            HStack(spacing: AtlasSpacing.md) {
                HeroImageView(
                    imageName: tour.heroImageURL,
                    height: 48,
                    cornerRadius: 8,
                    category: tour.primaryCategory
                )
                .frame(width: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                    Text(tour.title)
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.horizontal, AtlasSpacing.md)
            .padding(.vertical, AtlasSpacing.sm)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    // MARK: - Derived

    /// Tours after the category-chip filter is applied.
    private var filteredTours: [Tour] {
        guard let selectedCategory else { return dataService.tours }
        return dataService.tours.filter { $0.primaryCategory == selectedCategory }
    }

    /// Tours visible in the drawer list — filter + distance-sort.
    private var displayedTours: [Tour] {
        let base = filteredTours
        guard let userLocation = locationManager.userLocation else { return base }
        return base.sorted { $0.distance(from: userLocation) < $1.distance(from: userLocation) }
    }

    private var continueListeningTour: Tour? {
        libraryStore.entries
            .filter { $0.listenedSeconds > 0 && $0.completedAt == nil }
            .sorted { ($0.savedAt ?? .distantPast) > ($1.savedAt ?? .distantPast) }
            .compactMap { dataService.tour(by: $0.tourId) }
            .first
    }

    private var recentlyViewedTour: Tour? {
        // Skip if it'd duplicate the continue-listening banner.
        let cont = continueListeningTour?.id
        return recentlyViewedStore.tourIds
            .compactMap { dataService.tour(by: $0) }
            .first { $0.id != cont }
    }

    /// Show all `TourCategory` cases as filter-chip placeholders for
    /// now. Owner direction: surface the chip taxonomy even before
    /// every category has content. Categories with no tours filter
    /// to an empty list when tapped — fine as a placeholder; will
    /// likely refine once M-launch-content populates the catalog.
    private var chipPlaceholderCategories: [TourCategory] {
        TourCategory.allCases
    }

    /// Number of tours with at least one stop pin in the strip of
    /// map between the screen's top edge and the drawer's top edge.
    /// The map `.ignoresSafeArea()`, so its actual render height is
    /// the full screen height (not `geo.size.height`, which excludes
    /// top + bottom safe areas). We measure the drawer's top edge in
    /// those same screen coordinates to keep the pixel-to-latitude
    /// mapping consistent. Counts tours rather than raw pins
    /// (matches the "N tours in view" wording), and tests each tour's
    /// individual stops so multi-stop tours with off-screen centroids
    /// still count when any of their pins is visible.
    private func toursInViewCount(in geo: GeometryProxy) -> Int {
        guard let region = visibleRegion else { return filteredTours.count }
        let screenHeight = currentScreenHeight() ?? geo.size.height
        guard screenHeight > 0 else { return 0 }
        // Drawer's top edge measured from the screen's top edge. The
        // drawer + floating island stack flush against the screen
        // bottom (`ContentView` ignores the bottom safe area), so
        // both heights subtract directly off the full screen height.
        let drawerTopY = screenHeight
            - drawerVisibleHeight(in: geo)
            - floatingIslandHeight
        let visibleFraction = max(0, min(1, drawerTopY / screenHeight))
        guard visibleFraction > 0 else { return 0 }
        let topLatitude = region.center.latitude + region.span.latitudeDelta / 2
        let clippedLatDelta = region.span.latitudeDelta * visibleFraction
        let clipped = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: topLatitude - clippedLatDelta / 2,
                longitude: region.center.longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: clippedLatDelta,
                longitudeDelta: region.span.longitudeDelta
            )
        )
        return filteredTours.filter { tour in
            tour.stops.contains { clipped.contains($0.coordinate) }
        }.count
    }

    /// Full pixel height of the device screen, looked up via the
    /// active `UIWindowScene` (iOS 26's recommended replacement for
    /// `UIScreen.main.bounds`). Returns `nil` when no scene is
    /// available — extremely rare in the running app, but callers
    /// should fall back to `geo.size.height` defensively.
    private func currentScreenHeight() -> CGFloat? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen.bounds.height
    }

    private func headerText(forCount n: Int) -> String {
        // At `.large` the drawer covers nearly all of the map, so "0
        // tours in view" would always be true and read as a dead-end.
        // Swap in a friendly invitation that primes the user to scroll
        // the tour list below instead.
        if sheetDetent == .large { return "Let's explore together!" }
        switch n {
        case 0: return "No tours in view"
        case 1: return "1 tour in view"
        default: return "\(n) tours in view"
        }
    }

    private func distanceText(for tour: Tour) -> String? {
        guard let user = locationManager.userLocation else { return nil }
        return AtlasFormatters.distanceAway(meters: tour.distance(from: user))
    }

    private var emptyState: some View {
        VStack(spacing: AtlasSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
            Text(selectedCategory == nil ? "No tours yet" : "No tours in this category")
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
            Text(selectedCategory == nil
                 ? "Check back soon — Atlas is preparing its first audio tours."
                 : "No tours in this category yet — try a different one or clear the filter.")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AtlasSpacing.xl)
        .padding(.horizontal, AtlasSpacing.lg)
    }
}

/// The three Apple-Maps map types Atlas exposes via the map-mode
/// selector. `style` is the SwiftUI `MapStyle` value applied to the
/// `Map`; `iconName` is the SF Symbol shown on the selector button
/// when this mode is active.
enum MapMode: String, CaseIterable, Identifiable {
    case standard, hybrid, imagery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .hybrid:   return "Hybrid"
        case .imagery:  return "Satellite"
        }
    }

    var iconName: String {
        switch self {
        case .standard: return "map"
        case .hybrid:   return "map.fill"
        case .imagery:  return "globe.americas.fill"
        }
    }

}

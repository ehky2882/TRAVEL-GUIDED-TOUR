import SwiftUI
import MapKit
import CoreLocation

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
    @State private var sheetDetent: BottomSheetDetent = .large
    /// True while the map camera is in motion. Retracts the drawer to
    /// peek and fades the recenter button while the user is panning,
    /// then clears when the camera settles.
    @State private var isMapMoving = false
    /// Guards against the map firing continuous camera events during
    /// its initial render — drawer retraction only kicks in after the
    /// first onEnd (camera has settled at least once).
    @State private var mapHasSettledOnce = false
    /// Lifted out of BottomSheet so the recenter button can read the
    /// drawer's in-progress drag delta and stay glued to its top edge
    /// throughout the drag (not just snap on release).
    @State private var sheetDragOffset: CGFloat = 0
    @State private var selectedCategory: TourCategory? = nil
    @State private var selectedTourId: UUID? = nil
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            // Fallback start (NYC) — overridden on first appear if
            // the user has granted location.
            center: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
            span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        )
    )

    /// Peek-detent height. Sized so the AtlasTabBar (~62pt) + drag
    /// handle (~16pt) + centered header line (~30pt) all fit — and
    /// nothing more. Increasing this lets the first list item peek;
    /// decreasing clips the header.
    private let peekHeight: CGFloat = 110

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
                        selectedTourId: $selectedTourId,
                        cameraPosition: $cameraPosition,
                        onCameraChanged: { region in
                            visibleRegion = region
                            mapHasSettledOnce = true
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isMapMoving = false
                            }
                        },
                        onCameraMoving: {
                            guard mapHasSettledOnce, !isMapMoving else { return }
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
                        peekHeight: peekHeight
                    ) {
                        drawerContent
                    }

                    // Floating recenter button anchored to bottom-leading,
                    // padded up by the drawer's *current* visible height —
                    // which includes the in-progress drag delta — so the
                    // button stays glued to the drawer's top edge during
                    // the drag, not just after release.
                    recenterButton
                        .padding(.leading, AtlasSpacing.md)
                        .padding(.bottom, drawerVisibleHeight(in: geo) + AtlasSpacing.sm)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomLeading
                        )
                        // Hidden at full detent (drawer covers the map)
                        // and while the map is moving (clean panning UX).
                        // Button fades back when the camera settles.
                        .opacity(sheetDetent == .large || isMapMoving ? 0 : 1)
                        .allowsHitTesting(sheetDetent != .large && !isMapMoving)
                }
                .toolbar(.hidden, for: .navigationBar)
                .onChange(of: selectedTourId, initial: false) { _, _ in
                    if selectedTourId != nil && sheetDetent == .peek {
                        sheetDetent = .medium
                    }
                }
            }
        }
    }

    /// Mirrors the formula BottomSheet uses internally so the
    /// recenter button can sit exactly at the drawer's top edge —
    /// including during the drag. `sheetDragOffset` is the in-flight
    /// drag delta (negative = dragging up, positive = dragging down)
    /// so the visible height grows/shrinks live with the user's
    /// finger.
    private func drawerVisibleHeight(in geo: GeometryProxy) -> CGFloat {
        let baseHeight: CGFloat
        switch sheetDetent {
        case .peek:   baseHeight = peekHeight
        case .medium: baseHeight = geo.size.height * 0.5
        case .large:  baseHeight = geo.size.height - (AtlasSpacing.sm * 2)
        }
        return max(peekHeight, baseHeight - sheetDragOffset)
    }

    // MARK: - Recenter button

    private var recenterButton: some View {
        Button {
            recenterOnUser()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 16))
                .foregroundStyle(AtlasColors.primaryText)
                .frame(width: 44, height: 44)
                .background(.thickMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel("Recenter on my location")
    }

    private func recenterOnUser() {
        guard let userLocation = locationManager.userLocation else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }

    // MARK: - Drawer content

    private var drawerContent: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                // Header — dynamic count for the area in view.
                // Centered to read cleanly at the peek detent where
                // this is the *only* drawer content visible.
                Text(headerText)
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.top, AtlasSpacing.sm)
                    .padding(.bottom, AtlasSpacing.sm)

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
                    .padding(.vertical, AtlasSpacing.sm)
                }
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

    private var toursInView: [Tour] {
        guard let region = visibleRegion else { return filteredTours }
        return filteredTours.filter { region.contains($0.coordinate) }
    }

    private var headerText: String {
        let n = toursInView.count
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

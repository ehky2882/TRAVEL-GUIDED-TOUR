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
    @Environment(AudioPlayerService.self) private var audioPlayer

    @State private var visibleRegion: MKCoordinateRegion?
    @State private var sheetDetent: BottomSheetDetent = .large
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
    @State private var trackingMode: LocationTrackingMode = .none
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            // Fallback start (NYC) — overridden on first appear if
            // the user has granted location.
            center: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
            span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        )
    )

    /// Base peek-detent height. Sized so the AtlasTabBar (~62pt) + drag
    /// handle (~16pt) + centered header line (~30pt) all fit — and
    /// nothing more. Increasing this lets the first list item peek;
    /// decreasing clips the header.
    private let basePeekHeight: CGFloat = 130

    /// True while the mini-player is showing — it sits between the
    /// drawer and the tab bar, so the drawer's peek height grows by
    /// the bar's footprint to keep the same content visible above it.
    private var isMiniPlayerVisible: Bool {
        audioPlayer.state != .idle
    }

    /// Effective peek height — grows when the mini-player is on screen.
    private var peekHeight: CGFloat {
        isMiniPlayerVisible ? basePeekHeight + MiniPlayerBar.layoutHeight : basePeekHeight
    }

    /// Bottom padding for the drawer's scroll list so the last card
    /// clears the floating island (tab bar + mini-player) when the
    /// drawer is fully open.
    private var bottomListInset: CGFloat {
        let tabBar: CGFloat = 64
        let miniPlayer = isMiniPlayerVisible ? MiniPlayerBar.layoutHeight : 0
        return tabBar + miniPlayer + AtlasSpacing.md
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
                        onCameraChanged: { region in
                            visibleRegion = region
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isMapMoving = false
                            }
                        },
                        onCameraMoving: {
                            guard mapInteractionEnabled, !isMapMoving else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isMapMoving = true
                                trackingMode = .none
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
                        drawerContent(in: geo)
                    }

                    // Floating recenter button anchored to bottom-leading,
                    // padded up by the drawer's *current* visible height —
                    // which includes the in-progress drag delta — so the
                    // button stays glued to the drawer's top edge during
                    // the drag, not just after release.
                    locationButton
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

    // MARK: - Location button

    private var locationButton: some View {
        Button { cycleTrackingMode() } label: {
            Image(systemName: trackingMode.iconName)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color(uiColor: .systemGray3))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("My location")
    }

    private func cycleTrackingMode() {
        switch trackingMode {
        case .none:
            guard locationManager.userLocation != nil else { return }
            trackingMode = .follow
            // Animate the camera so it glides to the user instead of
            // snapping there abruptly.
            withAnimation(.easeInOut(duration: 0.45)) {
                cameraPosition = .userLocation(followsHeading: false, fallback: cameraPosition)
            }
        case .follow:
            trackingMode = .followWithHeading
            withAnimation(.easeInOut(duration: 0.45)) {
                cameraPosition = .userLocation(followsHeading: true, fallback: cameraPosition)
            }
        case .followWithHeading:
            trackingMode = .none
        }
    }

    // MARK: - Drawer content

    private func drawerContent(in geo: GeometryProxy) -> some View {
        // Fade the scrollable list in as the drawer opens past peek.
        // At the peek detent the list is hidden entirely — otherwise a
        // sliver of the first card (often a hero image) shows above
        // the tab bar (M-qa finding).
        let visible = drawerVisibleHeight(in: geo)
        let listOpacity = min(1, max(0, (visible - peekHeight) / 90))

        return ScrollViewReader { proxy in
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
                    .padding(.bottom, bottomListInset)
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

private enum LocationTrackingMode {
    case none, follow, followWithHeading

    var iconName: String {
        switch self {
        case .none:              return "location"
        case .follow:            return "location.fill"
        case .followWithHeading: return "location.north.line.fill"
        }
    }
}

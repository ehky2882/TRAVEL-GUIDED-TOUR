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
    @State private var sheetDetent: BottomSheetDetent = .peek
    @State private var selectedCategory: TourCategory? = nil
    @State private var selectedTourId: UUID? = nil

    /// Tunable peek height — enough for the drag handle + header line.
    private let peekHeight: CGFloat = 100

    var body: some View {
        // NavigationStack wraps the layout so the tour list cards,
        // quick-resume banners, and any other NavigationLinks have a
        // context to push onto. The nav bar itself is hidden — the
        // floating search bar + filter chips replace it visually.
        NavigationStack {
            ZStack(alignment: .top) {
                HomeMapSection(
                    tours: filteredTours,
                    userLocation: locationManager.userLocation,
                    selectedTourId: $selectedTourId,
                    onCameraChanged: { region in
                        visibleRegion = region
                    }
                )
                .ignoresSafeArea()

                VStack(spacing: AtlasSpacing.sm) {
                    SearchBar()
                        .padding(.horizontal, AtlasSpacing.lg)

                    CategoryChipRow(
                        availableCategories: categoriesWithTours,
                        selectedCategory: $selectedCategory
                    )
                }
                .padding(.top, AtlasSpacing.sm)

                BottomSheet(detent: $sheetDetent, peekHeight: peekHeight) {
                    drawerContent
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: selectedTourId, initial: false) { _, _ in
                // When a pin is tapped, expand to medium so the drawer
                // surfaces the matching card.
                if selectedTourId != nil && sheetDetent == .peek {
                    sheetDetent = .medium
                }
            }
        }
    }

    // MARK: - Drawer content

    private var drawerContent: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                // Header — dynamic count for the area in view.
                HStack {
                    Text(headerText)
                        .font(AtlasTypography.headline)
                        .foregroundStyle(AtlasColors.primaryText)
                    Spacer()
                }
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

    /// Only show chips for categories that actually have tours in the
    /// catalog. Avoids dead chips that filter to nothing.
    private var categoriesWithTours: [TourCategory] {
        let used = Set(dataService.tours.map { $0.primaryCategory })
        return TourCategory.allCases.filter { used.contains($0) }
    }

    private var toursInView: [Tour] {
        guard let region = visibleRegion else { return filteredTours }
        return filteredTours.filter { isCoordinate($0.coordinate, inside: region) }
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
        let meters = tour.distance(from: user)
        if meters < 1000 {
            return "\(Int(meters)) m away"
        }
        return String(format: "%.1f km away", meters / 1000)
    }

    private func isCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        inside region: MKCoordinateRegion
    ) -> Bool {
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        return coordinate.latitude >= minLat
            && coordinate.latitude <= maxLat
            && coordinate.longitude >= minLon
            && coordinate.longitude <= maxLon
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

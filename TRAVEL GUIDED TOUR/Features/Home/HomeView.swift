import SwiftUI
import MapKit
import CoreLocation

/// Map-dominant home screen — spec § Key screens #1 / roadmap M-home.
///
/// **Layout (post home-redesign):**
///   - `ZStack`: map fills the entire background, edge to edge.
///   - Floating search bar pinned at the top above the map.
///   - Persistent bottom sheet (Apple Maps pattern) presents the
///     curated rails. Three detents:
///       1. peek      — drag handle + "N tours in view" header only
///       2. medium    — handle + header + ~half-screen of rails
///       3. large     — handle + header + full-height rails
///   - Map remains pannable / zoomable through the sheet up to the
///     `.medium` detent via `.presentationBackgroundInteraction`.
///   - At `.large` the sheet covers the map and the user interacts
///     with rails exclusively.
///
/// The peek-detent header text recomputes from `visibleRegion`
/// whenever the map pans, so the user always sees how many tours
/// are spatially relevant to their current view.
struct HomeView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore

    @State private var visibleRegion: MKCoordinateRegion?
    @State private var sheetDetent: BottomSheetDetent = .peek

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                HomeMapSection(
                    tours: dataService.tours,
                    userLocation: locationManager.userLocation,
                    onCameraChanged: { region in
                        visibleRegion = region
                    }
                )
                .ignoresSafeArea()

                SearchBar()
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.top, AtlasSpacing.sm)

                // Custom bottom sheet — not `.sheet` because the standard
                // SwiftUI sheet system presents at the window level and
                // covers the tab bar. Living inside this ZStack keeps the
                // sheet within the tab content's safe area, so the tab
                // bar above remains visible at every detent.
                BottomSheet(detent: $sheetDetent, peekHeight: peekHeight) {
                    railsSheetContent
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sheet content

    /// Tunable: gives the peek detent just enough height for the drag
    /// indicator + the "N tours in view" header, with no rail content
    /// visible. Bumps if the header text wraps.
    private let peekHeight: CGFloat = 100

    private var railsSheetContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sheet header: dynamic count that recomputes on pan/zoom.
            HStack(spacing: AtlasSpacing.sm) {
                Text(tourCountText)
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)
                Spacer()
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.sm)
            .padding(.bottom, AtlasSpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                    if rails.isEmpty {
                        emptyState
                    } else {
                        ForEach(rails) { rail in
                            RailCarousel(title: rail.title, tours: rail.tours)
                        }
                    }
                }
                .padding(.vertical, AtlasSpacing.md)
            }
        }
    }

    // MARK: - Derived

    private var rails: [HomeRail] {
        HomeRailsViewModel.rails(
            tours: dataService.tours,
            libraryEntries: libraryStore.entries,
            recentlyViewedIds: recentlyViewedStore.tourIds,
            userLocation: locationManager.userLocation,
            visibleRegion: visibleRegion
        )
    }

    /// Tours whose `centroid` falls within the visible map region.
    /// Falls back to all tours when `visibleRegion` hasn't reported
    /// yet (e.g. immediately after launch, before the map settles).
    private var toursInView: [Tour] {
        guard let region = visibleRegion else { return dataService.tours }
        return dataService.tours.filter { tour in
            isCoordinate(tour.coordinate, inside: region)
        }
    }

    private var tourCountText: String {
        let n = toursInView.count
        switch n {
        case 0: return "No tours in view"
        case 1: return "1 tour in view"
        default: return "\(n) tours in view"
        }
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
            Image(systemName: "ear")
                .font(.system(size: 48))
                .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
            Text("No tours yet")
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
            Text("Check back soon — Atlas is preparing its first audio tours.")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AtlasSpacing.xl)
        .padding(.horizontal, AtlasSpacing.lg)
    }
}

import SwiftUI
import MapKit

/// Map-dominant home screen — spec § Key screens #1 / roadmap M-home.
///
/// Structure (top to bottom):
///   - SearchBarStub (pinned outside the scroll view, always visible)
///   - ScrollView:
///       - HomeMapSection (the map fills the upper portion of the
///         screen; scrolls off as the user pulls up)
///       - RailCarousel × N (rails picked by HomeRailsViewModel)
///
/// Pan-detection on the map updates `visibleRegion`, which feeds back
/// into the rails computation so the "In view" rail recurates as the
/// user explores.
struct HomeView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore

    @State private var visibleRegion: MKCoordinateRegion?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBarStub()
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.vertical, AtlasSpacing.sm)
                    .background(AtlasColors.background)

                // Map sits OUTSIDE the rails ScrollView so pinch-to-zoom
                // and pan gestures aren't intercepted by the scroll.
                HomeMapSection(
                    tours: dataService.tours,
                    userLocation: locationManager.userLocation,
                    onCameraChanged: { region in
                        visibleRegion = region
                    }
                )

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
                .background(AtlasColors.background)
            }
            .background(AtlasColors.background)
            .navigationTitle("Atlas")
            .inlineNavigationBarTitle()
        }
    }

    private var rails: [HomeRail] {
        HomeRailsViewModel.rails(
            tours: dataService.tours,
            libraryEntries: libraryStore.entries,
            recentlyViewedIds: recentlyViewedStore.tourIds,
            userLocation: locationManager.userLocation,
            visibleRegion: visibleRegion
        )
    }

    /// Shown if every rail computed empty — should be rare unless the
    /// catalog is empty. Defensive, not expected to appear in normal V1.
    private var emptyState: some View {
        VStack(spacing: AtlasSpacing.md) {
            Image(systemName: "ear")
                .font(.system(size: 48))
                .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
            Text("No tours yet")
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
            Text("Tours will appear here once Tours.json is populated.")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AtlasSpacing.xl)
        .padding(.horizontal, AtlasSpacing.lg)
    }
}

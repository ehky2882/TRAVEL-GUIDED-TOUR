import SwiftUI
import CoreLocation
import MapKit

/// The home drawer's scrollable content — header + quick-resume
/// banners + filtered tour list. Lifted out of `HomeView` so it can
/// live inside a `BottomSheet` hosted at the `ContentView` level,
/// which lets the drawer stack z-order ON TOP of the mini-player +
/// tab bar (previously the drawer rendered behind, causing the last
/// card to peek out at scroll-end).
///
/// Reads the shared map/drawer state via `HomeSharedState`. Tour-tap
/// navigation goes through the caller-supplied `onTourTap` closure so
/// presentation policy (push, sheet, full-screen cover) is decided by
/// the parent.
struct HomeDrawerContent: View {
    @Binding var sheetDetent: BottomSheetDetent
    let onTourTap: (Tour) -> Void

    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(HomeSharedState.self) private var sharedState

    /// Peek-detent height — mirrors `HomeView.peekHeight`. Used to
    /// fade the scrollable list in as the drawer opens past peek so a
    /// sliver of the first card never shows at the peek detent.
    private let peekHeight: CGFloat = 80

    var body: some View {
        GeometryReader { geo in
            let visible = drawerVisibleHeight(in: geo)
            let listOpacity = min(1, max(0, (visible - peekHeight) / 90))
            let inViewCount = displayedTours.count

            VStack(alignment: .leading, spacing: 0) {
                headerLabel(forCount: inViewCount)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.top, AtlasSpacing.sm)
                    .padding(.bottom, AtlasSpacing.md)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AtlasSpacing.md) {
                        if let resumeTour = continueListeningTour {
                            quickResumeBanner(tour: resumeTour, label: "Continue listening")
                        }
                        if let recentTour = recentlyViewedTour {
                            quickResumeBanner(tour: recentTour, label: "Recently viewed")
                        }

                        if displayedTours.isEmpty {
                            emptyState
                        } else {
                            ForEach(displayedTours) { tour in
                                Button {
                                    onTourTap(tour)
                                } label: {
                                    TourListCard(
                                        tour: tour,
                                        maker: dataService.maker(for: tour),
                                        isDownloaded: tourDownloader.isDownloaded(tourId: tour.id),
                                        distanceText: distanceText(for: tour),
                                        isSelected: sharedState.placecardTour?.id == tour.id,
                                        isSaved: libraryStore.isSaved(tour.id),
                                        onBookmarkTap: { libraryStore.toggleSaved(tour.id) }
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, AtlasSpacing.lg)
                            }
                        }
                    }
                    .padding(.top, AtlasSpacing.sm)
                    // Generous bottom padding so the last card can be
                    // scrolled clear of the home-indicator strip on
                    // phones with rounded corners.
                    .padding(.bottom, AtlasSpacing.xxl)
                }
                .opacity(listOpacity)
                .allowsHitTesting(listOpacity > 0.01)
            }
        }
    }

    // MARK: - Quick-resume banner

    private func quickResumeBanner(tour: Tour, label: String) -> some View {
        Button {
            onTourTap(tour)
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

    private var filteredTours: [Tour] {
        guard let selectedCategory = sharedState.selectedCategory else {
            return dataService.tours
        }
        return dataService.tours.filter { $0.primaryCategory == selectedCategory }
    }

    /// Tours surfaced in the scrollable list, in order. The list is
    /// scoped to the *current map view* — only tours with at least
    /// one stop inside `sharedState.visibleRegion` are included, and
    /// they're sorted by the tour's centroid distance from the map's
    /// center. The header count above the list reflects the same
    /// set, so "N TOURS IN VIEW" matches the number of cards below.
    /// Before the first `.onMapCameraChange` fires (visibleRegion ==
    /// nil), the unfiltered list is shown so the drawer isn't blank
    /// on launch.
    ///
    /// Future direction: when the drawer grows into a rail layout
    /// (see `HomeRailsViewModel`), this single in-view feed becomes
    /// one rail ("Tours in map view") and a sibling rail will sort
    /// `filteredTours` by `Tour.distance(from: userLocation)` for a
    /// "Near you" feed. Both shapes are derivable from the same
    /// `filteredTours` base + the existing `sharedState.visibleRegion`
    /// and `locationManager.userLocation` inputs, so no model change
    /// is required for that pivot — it's just lifting these closures
    /// into rail-shaped computed properties.
    private var displayedTours: [Tour] {
        let base = filteredTours
        guard let region = sharedState.visibleRegion else { return base }
        let center = CLLocation(latitude: region.center.latitude,
                                longitude: region.center.longitude)
        return base
            .filter { tour in
                tour.stops.contains { region.contains($0.coordinate) }
            }
            .sorted { $0.distance(from: center) < $1.distance(from: center) }
    }

    private var continueListeningTour: Tour? {
        libraryStore.entries
            .filter { $0.listenedSeconds > 0 && $0.completedAt == nil }
            .sorted { ($0.savedAt ?? .distantPast) > ($1.savedAt ?? .distantPast) }
            .compactMap { dataService.tour(by: $0.tourId) }
            .first
    }

    private var recentlyViewedTour: Tour? {
        let cont = continueListeningTour?.id
        return recentlyViewedStore.tourIds
            .compactMap { dataService.tour(by: $0) }
            .first { $0.id != cont }
    }

    private func drawerVisibleHeight(in geo: GeometryProxy) -> CGFloat {
        let baseHeight: CGFloat
        switch sheetDetent {
        case .peek:   baseHeight = peekHeight
        case .medium: baseHeight = geo.size.height * 0.5
        case .large:
            // Mirrors BottomSheet.heightForDetent(.large) — subtract
            // search/chips block + small buffer so the tours-in-view
            // clipping math uses the real drawer height. Safe-area
            // top is NOT added here (see matching note in BottomSheet).
            let topGap = AtlasSpacing.searchAndChipsBlockHeight + AtlasSpacing.sm
            baseHeight = geo.size.height - topGap - AtlasBottomModule.height()
        }
        return max(peekHeight, baseHeight - sharedState.sheetDragOffset)
    }


    /// The "N tours in view" header. While the map is mid-pan/-fling
    /// (sharedState.isMapMoving), shows an animated *ELLIPSIS*
    /// cycling . / .. / ... via a TimelineView — better than letting
    /// the count flicker through 0 mid-gesture, which reads as
    /// "no results."
    @ViewBuilder
    private func headerLabel(forCount n: Int) -> some View {
        if sheetDetent == .large {
            Text("LET'S EXPLORE TOGETHER!")
        } else if sharedState.isMapMoving {
            TimelineView(.periodic(from: .now, by: 0.4)) { context in
                let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.4) % 3 + 1
                Text(String(repeating: ".", count: tick))
            }
        } else {
            switch n {
            case 0: Text("NO TOURS IN VIEW")
            case 1: Text("1 TOUR IN VIEW")
            default: Text("\(n) TOURS IN VIEW")
            }
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
            Text(sharedState.selectedCategory == nil
                 ? "No tours yet"
                 : "No tours in this category")
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
            Text(sharedState.selectedCategory == nil
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

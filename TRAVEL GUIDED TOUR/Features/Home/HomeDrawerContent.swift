import SwiftUI
import CoreLocation
import MapKit
import UIKit

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
            let aboveDrawerCount = toursInViewCount(in: geo)

            VStack(alignment: .leading, spacing: 0) {
                Text(headerText(forCount: aboveDrawerCount))
                    .font(AtlasTypography.headline)
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
                                        isSelected: sharedState.placecardTour?.id == tour.id
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
        case .large:  baseHeight = geo.size.height - AtlasSpacing.sm - AtlasBottomModule.height()
        }
        return max(peekHeight, baseHeight - sharedState.sheetDragOffset)
    }

    /// Mirrors `HomeView.toursInViewCount(in:)`. Clips the visible map
    /// region to the strip of map between the screen top and the
    /// drawer's top edge, then counts tours with any stop in that
    /// strip.
    private func toursInViewCount(in geo: GeometryProxy) -> Int {
        guard let region = sharedState.visibleRegion else { return filteredTours.count }
        let screenHeight = currentScreenHeight() ?? geo.size.height
        guard screenHeight > 0 else { return 0 }
        let drawerTopY = screenHeight
            - drawerVisibleHeight(in: geo)
            - AtlasBottomModule.height()
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

    private func currentScreenHeight() -> CGFloat? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen.bounds.height
    }

    private func headerText(forCount n: Int) -> String {
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

import SwiftUI
import CoreLocation
import MapKit

/// The home drawer's scrollable content — header + quick-resume
/// banner + curated tag shelves (or a flat results list when a filter
/// is active). Lifted out of `HomeView` so it can live inside a
/// `BottomSheet` hosted at the `ContentView` level, which lets the
/// drawer stack z-order ON TOP of the mini-player + tab bar (previously
/// the drawer rendered behind, causing the last card to peek out at
/// scroll-end).
///
/// Reads the shared map/drawer state via `HomeSharedState`. Tour taps
/// (banner row here, rail cards in `RailCarousel`, result rows below)
/// present via `TourPresenter`, so the detail always comes up as a
/// bottom sheet.
struct HomeDrawerContent: View {
    @Binding var sheetDetent: BottomSheetDetent

    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(HomeSharedState.self) private var sharedState
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(AudioPlayerService.self) private var audioPlayer

    /// Peek-detent height — mirrors `HomeView.peekHeight`. Used to
    /// fade the scrollable rails in as the drawer opens past peek so a
    /// sliver of the first rail never shows at the peek detent.
    private let peekHeight: CGFloat = 80

    var body: some View {
        GeometryReader { geo in
            let visible = drawerVisibleHeight(in: geo)
            let listOpacity = min(1, max(0, (visible - peekHeight) / 90))
            let filtering = sharedState.hasActiveFilters
            let results = filtering ? filteredResults : []
            // The count shows at peek AND medium (every resting state
            // except fully-open); "LET'S EXPLORE" shows only once the
            // drawer has SETTLED at .large with NO filter active. Keyed
            // off detent + drag offset — NOT the GeometryReader, whose
            // `geo` here is the *drawer's* own height (it shrinks to the
            // peek height at peek), not the screen, so any geo-derived
            // progress is unreliable in this nested context.
            let showExplore = sheetDetent == .large
                && !filtering
                && abs(sharedState.sheetDragOffset) < 1

            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    countHeader(filtering: filtering, resultCount: results.count)
                        .opacity(showExplore ? 0 : 1)
                    Text("LET'S EXPLORE TOGETHER!")
                        .opacity(showExplore ? 1 : 0)
                }
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.mapPin)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AtlasSpacing.lg)
                .padding(.top, AtlasSpacing.sm)
                .padding(.bottom, AtlasSpacing.md)
                .animation(.easeInOut(duration: 0.3), value: showExplore)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                        if filtering {
                            // Filter active → a single flat results list
                            // (owner decision D8), sorted by map-view
                            // center distance.
                            if results.isEmpty {
                                noResultsState
                            } else {
                                ForEach(results) { tour in
                                    FilterResultCard(tour: tour)
                                }
                            }
                        } else {
                            // No filter → the curated tag shelves. The
                            // resume entry renders as a compact single
                            // ROW, not a shelf — you don't browse
                            // "continue listening," you tap it. One line
                            // keeps the top location rail above the fold.
                            if let resumeTour = continueListeningTour {
                                quickResumeBanner(tour: resumeTour, label: "Continue listening")
                            }

                            if railList.isEmpty {
                                emptyState
                            } else {
                                ForEach(railList) { rail in
                                    RailCarousel(title: rail.title, tours: rail.tours)
                                        .id(rail.id)
                                }
                            }
                        }
                    }
                    .padding(.top, AtlasSpacing.sm)
                    // Generous bottom padding so the last row can be
                    // scrolled clear of the home-indicator strip on
                    // phones with rounded corners.
                    .padding(.bottom, AtlasSpacing.xxl)
                }
                .opacity(listOpacity)
                .allowsHitTesting(listOpacity > 0.01)
            }
        }
    }

    // MARK: - Derived

    /// The curated tag shelves shown when no filter is active —
    /// location-anchored (Near you / In view) then one shelf per curated
    /// tag drawn from the whole catalog. Built by the pure
    /// `HomeRailsViewModel`; recomputed each render, cheap for V1's small
    /// catalog. The personalized rails the view-model also produces
    /// (Continue listening / Recently viewed) are dropped here — Continue
    /// renders as a compact banner above the shelves; Recently viewed
    /// lives in Library.
    private var railList: [HomeRail] {
        HomeRailsViewModel.rails(
            tours: dataService.tours,
            libraryEntries: libraryStore.entries,
            recentlyViewedIds: recentlyViewedStore.tourIds,
            userLocation: locationManager.userLocation,
            visibleRegion: sharedState.visibleRegion
        )
        .filter { $0.id != "continueListening" && $0.id != "recentlyViewed" }
    }

    /// The flat, distance-sorted results shown when a filter is active.
    private var filteredResults: [Tour] {
        HomeRailsViewModel.filteredResults(
            tours: dataService.tours,
            selectedTags: sharedState.selectedTags,
            walksOnly: sharedState.walksOnly,
            userLocation: locationManager.userLocation,
            visibleRegion: sharedState.visibleRegion
        )
    }

    /// The tour for the compact "Continue listening" row. Priority:
    /// whatever is CURRENTLY loaded in the player (it is literally the
    /// thing you'd continue listening to — same signal the mini-player
    /// keys on), falling back to the most-recently-listened unfinished
    /// library entry when the player is idle.
    private var continueListeningTour: Tour? {
        if let loaded = nowPlayingTour { return loaded }
        return libraryStore.entries
            .filter { $0.listenedSeconds > 0 && $0.completedAt == nil }
            .sorted { ($0.lastListenedAt ?? .distantPast) > ($1.lastListenedAt ?? .distantPast) }
            .compactMap { dataService.tour(by: $0.tourId) }
            .first
    }

    /// The tour whose audio is loaded in the player, or `nil` when idle.
    private var nowPlayingTour: Tour? {
        guard audioPlayer.state != .idle,
              let sourceId = audioPlayer.currentSourceId,
              let uuid = UUID(uuidString: sourceId) else {
            return nil
        }
        return dataService.tour(by: uuid)
    }

    // MARK: - Quick-resume banner

    private func quickResumeBanner(tour: Tour, label: String) -> some View {
        Button {
            tourPresenter.present(tour)
        } label: {
            HStack(spacing: AtlasSpacing.md) {
                HeroImageView(
                    imageName: tour.heroImageURL,
                    height: 48,
                    cornerRadius: 0,
                    category: tour.primaryCategory
                )
                .frame(width: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                    Text(tour.title)
                        .font(AtlasTypography.body)
                        .textCase(.uppercase)
                        .foregroundStyle(AtlasColors.primaryText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.leading, AtlasSpacing.sm)
            .padding(.trailing, AtlasSpacing.md)
            .padding(.vertical, AtlasSpacing.sm)
            .background(.regularMaterial)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Count of tours with at least one stop inside the current map
    /// view — drives the peek/medium "N TOURS IN VIEW" header. Stays a
    /// map-context stat even though the rails browse the whole catalog;
    /// at peek the header is all the user sees, so it keeps describing
    /// what's under the map. `nil` visibleRegion falls back to the full
    /// count.
    private var toursInViewCount: Int {
        guard let region = sharedState.visibleRegion else { return dataService.tours.count }
        return dataService.tours.filter { tour in
            tour.stops.contains { region.contains($0.coordinate) }
        }.count
    }

    private func drawerVisibleHeight(in geo: GeometryProxy) -> CGFloat {
        let baseHeight: CGFloat
        switch sheetDetent {
        case .peek:   baseHeight = peekHeight
        case .medium: baseHeight = geo.size.height * 0.5
        case .large:
            let topGap = AtlasSpacing.searchAndChipsBlockHeight + AtlasSpacing.sm
            baseHeight = geo.size.height - topGap - AtlasBottomModule.height()
        }
        return max(peekHeight, baseHeight - sharedState.sheetDragOffset)
    }

    /// The drawer header line. When a filter is active it reports the
    /// **result count**; otherwise the map-context "N TOURS IN VIEW".
    /// While the map is mid-pan/-fling (and not filtering) it shows an
    /// animated *ELLIPSIS* rather than letting the count flicker through
    /// 0, which reads as "no results."
    @ViewBuilder
    private func countHeader(filtering: Bool, resultCount: Int) -> some View {
        if filtering {
            switch resultCount {
            case 0: Text("NO MATCHES")
            case 1: Text("1 RESULT")
            default: Text("\(resultCount) RESULTS")
            }
        } else if sharedState.isMapMoving {
            TimelineView(.periodic(from: .now, by: 0.4)) { context in
                let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.4) % 3 + 1
                Text(String(repeating: ".", count: tick))
            }
        } else {
            switch toursInViewCount {
            case 0: Text("NO TOURS IN VIEW")
            case 1: Text("1 TOUR IN VIEW")
            default: Text("\(toursInViewCount) TOURS IN VIEW")
            }
        }
    }

    /// Shown only if the catalog produces no rails at all — a true
    /// cold-start state (no tours), not a "nothing nearby" state.
    private var emptyState: some View {
        VStack(spacing: AtlasSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
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

    /// Shown when the active filter combination matches no tours.
    private var noResultsState: some View {
        VStack(spacing: AtlasSpacing.md) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 40))
                .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
            Text("No tours match")
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
            Text("Try removing a filter to widen your search.")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AtlasSpacing.xl)
        .padding(.horizontal, AtlasSpacing.lg)
    }
}

// MARK: - Filter result card

/// One **full-width** card in the filtered results list (drawer, filter
/// active). Same big 4:3 hero as the rail cards, but the frame spans the
/// drawer width instead of scrolling in a rail — so filtered results read
/// as a rich, scannable vertical feed (owner direction 2026-07-05).
/// Title / maker / meta below, bookmark AFFORDANCE on the hero corner.
private struct FilterResultCard: View {
    let tour: Tour

    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(TourPresenter.self) private var tourPresenter

    var body: some View {
        Button {
            tourPresenter.present(tour)
        } label: {
            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                heroSection

                // Uniform xs between title → maker → meta, matching the
                // rail card so the two card families read identically.
                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    Text(tour.title)
                        .font(AtlasTypography.body)
                        .textCase(.uppercase)
                        .foregroundStyle(AtlasColors.primaryText)
                        .lineLimit(1)

                    if let maker = dataService.maker(for: tour) {
                        Text(maker.displayName)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .lineLimit(1)
                    }

                    HStack(spacing: AtlasSpacing.xs) {
                        Image(systemName: "clock")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                        Text(metaLine)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, AtlasSpacing.xs)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Full-width 4:3 hero with the bookmark AFFORDANCE in the top-right
    /// corner (same control as the rail card). The inner Button fires
    /// `toggleSaved`; a tap anywhere else on the card opens the tour.
    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: Self.heroHeight,
                cornerRadius: 0,
                category: tour.primaryCategory
            )

            Button {
                libraryStore.toggleSaved(tour.id)
            } label: {
                Image(systemName: libraryStore.isSaved(tour.id) ? "bookmark.fill" : "bookmark")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(AtlasSpacing.sm)
            .accessibilityLabel(libraryStore.isSaved(tour.id) ? "Saved" : "Save tour")
        }
    }

    /// Height for the full-width hero. Pinned to the rail card's hero
    /// height (260pt wide × 3/4 = 195pt) so the filtered cards match the
    /// rail exactly — a wider-than-4:3 banner, so the 1200×900 heroes are
    /// lightly cropped top/bottom (vs the full uncropped 4:3 the rail
    /// gets at its narrower width).
    private static let heroHeight: CGFloat = 195

    /// "3 min" alone, or "3 min · 1.2 mi away" when the user's location
    /// is known — the same shape the rail cards + placecard use. Walks
    /// (multi-stop) surface their stop count as a cue.
    private var metaLine: String {
        let duration = AtlasFormatters.duration(seconds: tour.totalDurationSeconds)
        let base = tour.kind == .multiStop ? "\(duration) · \(tour.stops.count) stops" : duration
        guard let user = locationManager.userLocation else { return base }
        let away = AtlasFormatters.distanceAway(meters: tour.distance(from: user))
        return "\(base) · \(away)"
    }
}

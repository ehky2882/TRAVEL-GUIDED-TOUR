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
    /// The filter is on the cross-window state — see
    /// `AppSharedState.filterPanel` for why it is not on `sharedState`.
    @Environment(AppSharedState.self) private var appShared: AppSharedState?

    /// Peek-detent height — mirrors `HomeView.peekHeight`. Used to
    /// fade the scrollable rails in as the drawer opens past peek so a
    /// sliver of the first rail never shows at the peek detent.
    private let peekHeight: CGFloat = 80

    var body: some View {
        GeometryReader { geo in
            let visible = drawerVisibleHeight(in: geo)
            let listOpacity = min(1, max(0, (visible - peekHeight) / 90))
            let filtering = appShared?.filter.isActive ?? false
            let results = filtering ? filteredResults : []
            // The header counts what is UNDER THE MAP, filtered or not — see
            // `HomeRailsViewModel.countInView`. The list below stays the full
            // match set, nearest first, so panning past the edge of the view
            // still leaves somewhere to scroll to.
            let inView = HomeRailsViewModel.countInView(results, region: sharedState.visibleRegion)
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
                    countHeader(
                        filtering: filtering,
                        matchCount: results.count,
                        inViewCount: inView
                    )
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
                        // 🔴 **The shelves stay when a filter is on** — they
                        // are simply built from the matching tours instead of
                        // the whole catalogue, and `HomeRailsViewModel.rails`
                        // already drops a shelf with nothing in it. Owner, on
                        // device, 2026-09-13: *"within the drawer the
                        // scrollable rails went away after you filter."*
                        //
                        // ⚠️ They went away because filtering swapped them for
                        // a flat list of full-width cards — **itself an owner
                        // direction, 2026-07-05**, for results that read as "a
                        // rich, scannable vertical feed". This reverses that,
                        // and the card view goes with it (it was unreferenced
                        // afterwards; git has it if the feed ever returns).
                        //
                        // ⚠️ The comment that stood here credited the swap to
                        // "owner decision D8", which it never was: D8 was about
                        // the CHIP ROW being multi-select rather than a faceted
                        // sheet, and had nothing to say about the drawer. The
                        // real direction was recorded on the card, not here.
                        if filtering, results.isEmpty {
                            noResultsState
                        } else {
                            // The resume entry renders as a compact single
                            // ROW, not a shelf — you don't browse "continue
                            // listening," you tap it. One line keeps the top
                            // location rail above the fold. ⚠️ Hidden while
                            // filtering: it is the one row on this screen that
                            // ignores the filter, and a card that does not
                            // match what you asked for reads as a bug.
                            if !filtering, let resumeTour = continueListeningTour {
                                quickResumeBanner(tour: resumeTour, label: "Continue listening")
                            }

                            // Derived ONCE. `railList` builds thirteen shelves,
                            // and reading it twice built them twice — in the
                            // same frame the map lands on a searched place.
                            // Same "derive once, use many" trap as
                            // `filteredTours` in SearchView.
                            let rails = railList(matching: filtering ? results : nil)
                            if rails.isEmpty {
                                emptyState
                            } else {
                                ForEach(rails) { rail in
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
    /// `HomeRailsViewModel`.
    ///
    /// ⚠️ Recomputed on every render, and every camera settle rewrites
    /// `visibleRegion` — so this runs in the one frame where the map lands on
    /// a searched place. A hot path, not the cheap one the original comment
    /// here claimed while the catalog was small. Shelf MEMBERSHIP comes from a
    /// prebuilt index; only the ORDER is derived live.
    /// **Read it once per body** (see the call site).
    ///
    /// The personalized rails the view-model also produces
    /// (Continue listening / Recently viewed) are dropped here — Continue
    /// renders as a compact banner above the shelves; Recently viewed
    /// lives in Library.
    /// - Parameter matching: the filter's matches, or `nil` when no filter is
    ///   on. Non-nil narrows every shelf to that set; shelves left with nothing
    ///   are dropped by `rails` itself, so a filter thins the drawer rather
    ///   than emptying it.
    private func railList(matching: [Tour]?) -> [HomeRail] {
        HomeRailsViewModel.rails(
            tours: matching ?? dataService.tours,
            libraryEntries: libraryStore.entries,
            recentlyViewedIds: recentlyViewedStore.tourIds,
            userLocation: locationManager.userLocation,
            visibleRegion: sharedState.visibleRegion,
            // Prebuilt tag index — without it each shelf filters the whole
            // catalog, thirteen times, on every frame of a camera move. ⚠️ The
            // prebuilt one covers the WHOLE catalogue, so it is wrong for a
            // filtered set; that case builds its own in one pass, from the
            // array the header already computed.
            toursByTag: matching.map(HomeRailsViewModel.tagIndex(for:)) ?? dataService.toursByTagIndex
        )
        .filter { $0.id != "continueListening" && $0.id != "recentlyViewed" }
    }

    /// The flat, distance-sorted results shown when a filter is active.
    private var filteredResults: [Tour] {
        HomeRailsViewModel.filteredResults(
            tours: dataService.tours,
            filter: appShared?.filter ?? .none,
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

    /// Shown in place of any count while the map is moving. Both the filtered
    /// and unfiltered headers use it: a number that is about to change is worse
    /// than no number, and a zero mid-pan reads as a dead end.
    private var movingDots: some View {
        TimelineView(.periodic(from: .now, by: 0.4)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.4) % 3 + 1
            Text(String(repeating: ".", count: tick))
        }
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

    /// The drawer header line: **"N TOURS IN VIEW"** unfiltered, **"N RESULTS
    /// IN VIEW"** filtered. While the map is mid-pan or mid-fling it shows an
    /// animated ellipsis instead, rather than letting the count flicker through
    /// 0 — which reads as "nothing here" at exactly the moment it is not true.
    ///
    /// 🔴 **Always a map stat.** `matchCount` is the whole catalogue's answer
    /// to the filter and `inViewCount` is how much of it is under the map right
    /// now; the header reads the second, so it keeps live-updating as you pan
    /// (owner, on device, 2026-09-13). The two are distinguished in one place
    /// only, and deliberately: **nothing matches anywhere** is a different
    /// problem from **nothing matches HERE**, and the second is solved by
    /// moving the map rather than by clearing a chip.
    @ViewBuilder
    private func countHeader(filtering: Bool, matchCount: Int, inViewCount: Int) -> some View {
        if filtering, matchCount == 0 {
            Text("NO MATCHES")
        } else if filtering, sharedState.isMapMoving {
            movingDots
        } else if filtering {
            switch inViewCount {
            case 0: Text("NO RESULTS IN VIEW")
            case 1: Text("1 RESULT IN VIEW")
            default: Text("\(inViewCount) RESULTS IN VIEW")
            }
        } else if sharedState.isMapMoving {
            movingDots
        } else {
            let count = toursInViewCount
            switch count {
            case 0: Text("NO TOURS IN VIEW")
            case 1: Text("1 TOUR IN VIEW")
            default: Text("\(count) TOURS IN VIEW")
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

import SwiftUI
import CoreLocation
import MapKit

/// The home drawer's scrollable content — header + quick-resume
/// banners + category rails. Lifted out of `HomeView` so it can
/// live inside a `BottomSheet` hosted at the `ContentView` level,
/// which lets the drawer stack z-order ON TOP of the mini-player +
/// tab bar (previously the drawer rendered behind, causing the last
/// card to peek out at scroll-end).
///
/// Reads the shared map/drawer state via `HomeSharedState`. Tour
/// taps (banner rows here, rail cards in `RailCarousel`) present via
/// `TourPresenter`, so the detail always comes up as a bottom sheet.
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
            let railList = rails
            // The count shows at peek AND medium (every resting state
            // except fully-open); "LET'S EXPLORE" shows only once the
            // drawer has SETTLED at .large (detent committed AND drag
            // offset zeroed). Keyed off detent + drag offset — NOT the
            // GeometryReader, whose `geo` here is the *drawer's* own
            // height (it shrinks to the peek height at peek), not the
            // screen, so any geo-derived progress is unreliable in
            // this nested context. The cross-fade is what kills the
            // old hard-swap "lag": flicking up fades the count out and
            // "LET'S EXPLORE" in only at rest; dragging back down
            // reverses it the instant the finger moves (offset != 0).
            let showExplore = sheetDetent == .large && abs(sharedState.sheetDragOffset) < 1

            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    countHeader(forCount: toursInViewCount)
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

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                            // The resume entry renders as a compact
                            // single ROW, not a shelf — you don't
                            // browse "continue listening," you tap
                            // it. One line keeps "NEAR YOU" (the
                            // first real shelf, and the map-anchored
                            // one) above the fold. ("Recently viewed"
                            // was dropped from the drawer entirely —
                            // owner trial 2026-06-12; it still lives
                            // in Library.)
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
                        .padding(.top, AtlasSpacing.sm)
                        // Generous bottom padding so the last rail can be
                        // scrolled clear of the home-indicator strip on
                        // phones with rounded corners.
                        .padding(.bottom, AtlasSpacing.xxl)
                    }
                    .opacity(listOpacity)
                    .allowsHitTesting(listOpacity > 0.01)
                    // Filter chips above the drawer act as jump-scroll:
                    // selecting a category glides the rails to that
                    // category's shelf (and opens the drawer if it was
                    // peeking, so the jump lands somewhere visible).
                    .onChange(of: sharedState.selectedCategory) { _, category in
                        jumpToCategory(category, using: proxy, rails: railList)
                    }
                }
            }
        }
    }

    // MARK: - Jump-scroll

    /// Scroll the rails to the selected category's shelf. `nil` (the
    /// "All" chip) returns to the top.
    ///
    /// At the peek detent we deliberately do NOT raise the drawer:
    /// tapping a chip there filters the *map pins* (via
    /// `HomeView.filteredTours`, keyed on the same
    /// `sharedState.selectedCategory`) and the drawer stays put —
    /// owner request 2026-06-24. The jump-scroll only matters once the
    /// drawer is already open (medium / large), where the rails are
    /// actually visible; at peek the rails are hidden, so there's
    /// nothing to scroll to and raising the drawer would fight the
    /// "only the pins change" intent.
    private func jumpToCategory(_ category: TourCategory?, using proxy: ScrollViewProxy, rails: [HomeRail]) {
        guard sheetDetent != .peek else { return }
        let targetId: String? = category.map { "category.\($0.rawValue)" } ?? rails.first?.id
        guard let targetId else { return }
        // Defer a tick so the rail is realized (the list fades / lazily
        // realizes as the drawer opens) before the scroll resolves its
        // frame.
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(targetId, anchor: .top)
            }
        }
    }

    // MARK: - Derived

    /// The ordered rails shown in the drawer — location-anchored
    /// (Near you / In view), then one shelf per category drawn from
    /// the whole catalog. Built by the pure `HomeRailsViewModel`;
    /// recomputed each render, which is cheap for V1's small catalog.
    /// The personalized rails the view-model also produces (Continue
    /// listening / Recently viewed) are dropped here — they render as
    /// compact single-row banners above the shelves instead, so the
    /// location rails aren't pushed below the fold.
    /// The category chips above the drawer no longer *filter* this
    /// set — they jump-scroll to a shelf (see `jumpToCategory`).
    private var rails: [HomeRail] {
        HomeRailsViewModel.rails(
            tours: dataService.tours,
            libraryEntries: libraryStore.entries,
            recentlyViewedIds: recentlyViewedStore.tourIds,
            userLocation: locationManager.userLocation,
            visibleRegion: sharedState.visibleRegion
        )
        .filter { $0.id != "continueListening" && $0.id != "recentlyViewed" }
    }

    /// The tour for the compact "Continue listening" row. Priority:
    /// whatever is CURRENTLY loaded in the player (it is literally
    /// the thing you'd continue listening to — same signal the
    /// mini-player keys on), falling back to the most-recently-
    /// listened unfinished library entry when the player is idle.
    /// The fallback orders by `lastListenedAt` (NOT save date —
    /// resuming is about what you last heard, even if you saved
    /// something else since).
    private var continueListeningTour: Tour? {
        if let loaded = nowPlayingTour { return loaded }
        return libraryStore.entries
            .filter { $0.listenedSeconds > 0 && $0.completedAt == nil }
            .sorted { ($0.lastListenedAt ?? .distantPast) > ($1.lastListenedAt ?? .distantPast) }
            .compactMap { dataService.tour(by: $0.tourId) }
            .first
    }

    /// The tour whose audio is loaded in the player, or `nil` when
    /// idle. Mirrors `ContentView.nowPlayingTour` (the mini-player's
    /// visibility signal) so the row and the mini-player always
    /// agree on what "currently playing" means.
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
            // Leading inset matches the vertical inset so the square
            // thumbnail sits at an even distance from the box's top,
            // bottom, and left edges; the trailing side keeps the
            // larger inset so the chevron doesn't crowd the edge.
            .padding(.leading, AtlasSpacing.sm)
            .padding(.trailing, AtlasSpacing.md)
            .padding(.vertical, AtlasSpacing.sm)
            // Square corners — matches the square-cornered tour
            // imagery everywhere else on home (owner choice).
            .background(.regularMaterial)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Count of tours with at least one stop inside the current map
    /// view — drives the peek/medium "N TOURS IN VIEW" header. This
    /// stays a map-context stat even though the rails below browse the
    /// whole catalog; at peek the header is all the user sees, so it
    /// keeps describing what's under the map. `nil` visibleRegion
    /// (pre-first-camera-settle) falls back to the full count.
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
            // Mirrors BottomSheet.heightForDetent(.large) — subtract
            // search/chips block + small buffer so the tours-in-view
            // clipping math uses the real drawer height. Safe-area
            // top is NOT added here (see matching note in BottomSheet).
            let topGap = AtlasSpacing.searchAndChipsBlockHeight + AtlasSpacing.sm
            baseHeight = geo.size.height - topGap - AtlasBottomModule.height()
        }
        return max(peekHeight, baseHeight - sharedState.sheetDragOffset)
    }


    /// The "N TOURS IN VIEW" count layer (the ".large → LET'S EXPLORE"
    /// case now lives in the body's cross-fade, not here). While the
    /// map is mid-pan/-fling (sharedState.isMapMoving), shows an
    /// animated *ELLIPSIS* cycling . / .. / ... via a TimelineView —
    /// better than letting the count flicker through 0 mid-gesture,
    /// which reads as "no results."
    @ViewBuilder
    private func countHeader(forCount n: Int) -> some View {
        if sharedState.isMapMoving {
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

    /// Shown only if the catalog produces no rails at all — i.e. there
    /// are genuinely no tours. With whole-catalog category rails the
    /// drawer is no longer a dead-end when the map is panned to an
    /// empty area (the rails still browse everything), so this is a
    /// true cold-start state, not a "nothing nearby" state.
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
}

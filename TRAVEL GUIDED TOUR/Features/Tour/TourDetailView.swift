import SwiftUI
import MapKit
import UIKit

/// Tour detail screen — spec § Key screens #4 / roadmap M-tour-detail.
///
/// PR 1 of the detail-sheet retool (session 12, 2026-05-29). Owner-driven
/// design pass — see `archive/HANDOFF-260529.md` for the full Q&A trail.
///
/// **Layout** (top to bottom, in scroll order):
///   - Toolbar (in nav bar): X close (leading) · bookmark (trailing) · `…`
///     overflow menu (trailing). **No title text** — the body's title
///     carries the page identity.
///   - Hero image — single image OR paging carousel (multi-image tours).
///     Inset side padding, **no corner radius** (square corners).
///   - Title
///   - Maker row (chevron pushes to MakerView)
///   - Subtitle line: `"3 min · 1 stop · 455 ft away"` (or, multi-stop:
///     `"… · 1.2 mi walk"`). Replaces the old meta row + chips.
///   - Button row: Start Tour / Save / Download. Repeated at the bottom
///     of the scroll body, redundancy intentional.
///   - Description — full text inline, scroll-edge gradient fade signals
///     "more below."
///   - Stops section — same simple numbered list as today for both
///     single- and multi-stop tours (PR 2 reshapes this into a numbered
///     timeline with thumbnails + a now-playing indicator).
///   - Button row (second copy)
///   - Bottom inset reserving room for the mini-player + tab bar that
///     float over from the secondary higher-level UIWindow.
///
/// **Overflow menu** (`…`): Download · Save · Share · Follow creator
/// (disabled, V1 has no follow graph) · Go to creator · Report a concern.
///
/// **Action wiring** (PR 1 only — Start Tour still opens PlayerView;
/// PR 2 rewires it to a non-modal playback start):
///   - Start Tour → opens PlayerView sheet (today's behaviour).
///   - Save / bookmark → `LibraryStore.toggleSaved`.
///   - Download → state-aware (idle / downloading / completed / failed),
///     gated when another tour is mid-download.
///   - Share → `ShareLink` with the tour title + maker line.
///   - Report a concern → presents `ReportSheet` (reason + details →
///     Supabase `reports` table; no email address ships in the app).
///   - Go to creator → in-stack `NavigationLink` to MakerView, same
///     destination as tapping the inline maker row.
struct TourDetailView: View {
    let tour: Tour

    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(LocationManager.self) private var locationManager
    /// Used by the X close button in the top-leading toolbar slot —
    /// closes the entire detail layer (slides it back down), even
    /// when reached via a `NavigationLink` push (e.g. from
    /// `MakerView`). Within the layer's nav stack the default back
    /// chevron pops one level; X always exits the layer.
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(AppSharedState.self) private var appShared
    @Environment(\.openURL) private var openURL
    /// Optional: TourDetailView is hosted in the UIKit slide-up layers, which
    /// inject `JourneyService` explicitly. Optional so any other presentation
    /// path can't crash on a missing lookup — the "Add to a Journey" item just
    /// hides when it's absent.
    @Environment(JourneyService.self) private var journeyService: JourneyService?
    /// Optional for the same reason as `journeyService` — injected by the UIKit
    /// slide-up layers; "Listen together" hides if absent.
    @Environment(GroupListenCoordinator.self) private var groupListen: GroupListenCoordinator?

    /// Programmatic push for the menu's "Go to creator" item. The
    /// inline maker row uses its own inline `NavigationLink`; the
    /// menu item can't host a NavigationLink directly inside a Menu's
    /// content closure (iOS would render it as a plain row that
    /// doesn't push), so we drive it through `.navigationDestination`.
    @State private var showingMaker = false
    @State private var showingReport = false
    @State private var showingAddToJourney = false
    @State private var showingGroupListen = false

    /// Toggles between the truncated 4-line preview of `longDescription`
    /// and the full text. Apple Music / Podcasts pattern — keeps the
    /// action row close to the fold, lets readers expand inline.
    @State private var isDescriptionExpanded = false

    /// Lines shown in the truncated state. iOS convention (Apple Music
    /// album notes, Podcasts show notes); ~25 words at 15pt SF Pro.
    private static let descriptionPreviewLineLimit = 4

    /// Active when the user is dragging on the primary button's
    /// progress bar. Mirrors PlayerView's scrub pattern: while true,
    /// the bar fill + time-remaining text track `scrubTime` instead
    /// of the live `audioPlayer.currentTime`, so the thumb doesn't
    /// fight the periodic time observer.
    @State private var isScrubbingPrimary = false
    @State private var primaryScrubTime: TimeInterval = 0

    /// Walking-route polylines between consecutive stops on multi-stop
    /// tours. Empty for single-stop tours, and empty for multi-stop
    /// tours until the async `MKDirections.calculate()` requests come
    /// back. Pins render immediately; the route line draws when ready.
    @State private var routePolylines: [MKPolyline] = []

    /// Which top-of-sheet visual is showing — the photo *GALLERY* or the
    /// location *MAP*. Owner-requested experiment (2026-07-06): brings
    /// the map above the fold so the user doesn't have to scroll past
    /// the stops list to discover it. The rest of the body (masthead,
    /// description, stops, nearby tours) is unchanged.
    @State private var topSectionTab: TopSectionTab = .gallery

    private enum TopSectionTab: String, CaseIterable, Identifiable {
        case gallery = "Gallery"
        case map = "Map"
        var id: String { rawValue }
    }

    init(tour: Tour) {
        self.tour = tour
        // Match LibraryView's segmented-control font (SF Mono 13pt =
        // AtlasTypography.caption). Duplicated here rather than
        // trusted from LibraryView's init because a cold launch → tap
        // a tour would open detail before Library was ever
        // instantiated, so its appearance setup wouldn't have run yet.
        // `UISegmentedControl.appearance()` is idempotent — safe to
        // set from both surfaces.
        let mono = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        UISegmentedControl.appearance().setTitleTextAttributes([.font: mono], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.font: mono], for: .selected)
    }

    var body: some View {
        scrollBody
            // `.safeAreaInset(.top)` parks the chromeRow above the
            // ScrollView's content area: the row stays anchored at
            // the screen top while the body content scrolls *under*
            // it. Solid material + tint backdrop, hard bottom edge.
            // A gradient fade was explored on 2026-06-03 and parked
            // — owner wants to revisit later.
            .safeAreaInset(edge: .top, spacing: 0) {
                chromeRow
                    .background(AtlasColors.secondaryBackground.opacity(0.8))
                    .background(.regularMaterial)
            }
            .background(AtlasColors.secondaryBackground)
            // System nav bar hidden — our chromeRow handles all top
            // chrome inline so each control is an identical 44pt
            // Capsule, sized + styled to match the action row's
            // secondary buttons exactly. iOS 26's auto glass-grouping
            // around toolbar items was visually stacking on top of
            // any custom chrome we added, producing a "two layers"
            // look (owner correction, 2026-06-03).
            .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showingMaker) {
            if let maker = dataService.maker(for: tour) {
                MakerView(maker: maker)
            }
        }
        .sheet(isPresented: $showingReport) {
            ReportSheet(target: .tour(tour))
        }
        .sheet(isPresented: $showingAddToJourney) {
            AddToJourneySheet(tour: tour)
        }
        .sheet(isPresented: $showingGroupListen) {
            GroupListenSheet(tour: tour)
        }
        .onAppear {
            navState.push()
            recentlyViewedStore.record(tour.id)
        }
        .onDisappear {
            navState.pop()
        }
        .onChange(of: tourDownloader.states[tour.id]) { _, newState in
            switch newState {
            case .completed:
                libraryStore.markDownloaded(tour.id)
            case .idle, .failed, .none:
                if libraryStore.entry(for: tour.id)?.downloadedAt != nil {
                    libraryStore.clearDownload(tour.id)
                }
            case .downloading:
                break
            }
        }
    }

    /// Sticky top chrome — X close (leading) · Save · overflow
    /// (trailing). Renders three discrete `chromeCapsule`-styled
    /// buttons matching the inline action row's secondary
    /// (save/download) buttons: 44×44 Capsule with
    /// `AtlasColors.mapPin.opacity(0.15)` fill + 20pt regular SF
    /// Symbol in `mapPin` gold. The row sits at the top of the
    /// body (outside the ScrollView) so it stays put while the
    /// content scrolls underneath.
    private var chromeRow: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Button(action: { tourPresenter.dismiss() }) {
                chromeCapsule("xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            Button(action: toggleSaved) {
                chromeCapsule(isSaved ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSaved ? "Remove from saved" : "Save tour")

            overflowMenu
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    /// Scrollable body content — everything below the chromeRow.
    private var scrollBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                // Owner-requested experiment (2026-07-06): swap the
                // hero-only top for a GALLERY / MAP tab pair so the
                // map is discoverable above the fold. The map's
                // previous "Location" section below the stops list is
                // gone (moved into the Map tab).
                topSection
                    .padding(.top, AtlasSpacing.md)

                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    masthead
                    buttonRow
                        // VStack `md` (16) + this `sm` (8) on top *and*
                        // bottom = 24pt visible above and below the
                        // action row (owner-set, 2026-06-03). Asymmetric
                        // breath above the row removed.
                        .padding(.vertical, AtlasSpacing.sm)
                    descriptionSection
                    stopsSection
                    nearbyToursSection
                }
                .padding(.horizontal, AtlasSpacing.lg)

                // Bottom inset so the last line of content clears the
                // mini-player + tab bar that float over this view from
                // the secondary higher-level window.
                Color.clear.frame(height: AtlasBottomModule.height())
            }
        }
        // Pre-fetch the walking route on tour load, so switching to
        // the Map tab renders the polyline instantly (was on the Map
        // view itself, which delayed the first tap by an MKDirections
        // round-trip). No-op on single-stop tours.
        .task(id: tour.id) {
            await loadWalkingRoute()
        }
    }

    // MARK: - Top section (Gallery / Map tabs)

    /// Owner-requested experiment (2026-07-06). The top of the sheet
    /// used to be just the hero image / carousel. Now a **Library-style
    /// segmented picker** (Gallery / Map) sits above the swap zone so
    /// the map is discoverable without scrolling. The old "Location"
    /// section below the stops list is removed — the map only lives
    /// here.
    ///
    /// `GET DIRECTIONS` renders **outside** the swap zone (owner ask,
    /// iteration 2): persistent across both tabs so the layout height
    /// stays constant when the user toggles between Gallery and Map.
    ///
    /// Both tab contents self-manage horizontal padding of `lg` so
    /// they align with each other and with the hero-height frame.
    private var topSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            topSectionTabRow
            Group {
                switch topSectionTab {
                case .gallery:
                    imageSection
                case .map:
                    mapContent
                }
            }
            getDirectionsLink
        }
    }

    /// System segmented `Picker` — same shape as `LibraryView`'s
    /// Saved / Downloaded / Recents picker, so the two surfaces read
    /// as one visual system. Font is SF Mono 13pt via the
    /// `UISegmentedControl.appearance()` setup in `init`.
    private var topSectionTabRow: some View {
        Picker("Top section", selection: $topSectionTab) {
            ForEach(TopSectionTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    // MARK: - Gallery (photo carousel)

    /// Hero area: a single image for tours with one photo, or a paging
    /// carousel for tours that supply `additionalImageURLs` and/or
    /// `videoURLs` (videos render as extra pages after the photos).
    /// Shared with `PlayerView` via `TourMediaCarousel` so the two
    /// surfaces stay identical.
    ///
    /// Square corners (HeroImageView's `cornerRadius` defaults to 0) +
    /// `disableLoadAnimation` (no crossfade while the detail layer
    /// slides up) are baked into the shared carousel. Horizontal side
    /// padding stays here so the footprint matches the map tab.
    private var imageSection: some View {
        TourMediaCarousel(
            heroImageURL: tour.heroImageURL,
            additionalImageURLs: tour.additionalImageURLs,
            videoURLs: tour.videoURLs,
            height: AtlasSpacing.heroHeight,
            category: tour.primaryCategory
        )
        .padding(.horizontal, AtlasSpacing.lg)
    }

    // MARK: - Masthead

    /// Title + maker row + subtitle line. Replaces the old
    /// title+chips+maker+meta stack with a tighter editorial-style
    /// header. Category chips dropped per the design pass; duration /
    /// stops / distance folded into a single small subtitle line.
    private var masthead: some View {
        // VStack spacing is 0 on purpose — the visible 4pt gap above
        // and below the maker row comes from `makerRow`'s own
        // `.padding(.vertical, AtlasSpacing.xs)` (4pt top + 4pt
        // bottom). Keeping the gap inside the maker row lets the
        // NavigationLink's tap zone include that gap, instead of
        // pushing the gap up into inert VStack spacing.
        VStack(alignment: .leading, spacing: 0) {
            Text(tour.title.uppercased())
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            makerRow

            Text(subtitleLine)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
    }

    private var makerRow: some View {
        Group {
            if let maker = dataService.maker(for: tour) {
                NavigationLink {
                    MakerView(maker: maker)
                } label: {
                    HStack(spacing: AtlasSpacing.sm) {
                        Text(maker.displayName)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.tertiaryText)
                    }
                    .padding(.vertical, AtlasSpacing.xs)
                }
                .buttonStyle(.plain)
            } else {
                EmptyView()
            }
        }
    }

    /// One-line summary: `"3 min · 1 stop · 455 ft away"` for single-stop
    /// tours when the user's location is known, `"3 min · 1 stop"`
    /// otherwise. Multi-stop tours swap "away" for total walking
    /// distance: `"8 min 44 sec · 5 stops · 1.2 mi walk"`.
    private var subtitleLine: String {
        var parts: [String] = []
        parts.append(AtlasFormatters.duration(seconds: tour.totalDurationSeconds))

        let stopWord = tour.stops.count == 1 ? "stop" : "stops"
        parts.append("\(tour.stops.count) \(stopWord)")

        if tour.kind == .multiStop, let meters = tour.walkingDistanceMeters {
            parts.append("\(AtlasFormatters.distance(meters: Double(meters))) walk")
        } else if let user = locationManager.userLocation {
            parts.append(AtlasFormatters.distanceAway(meters: tour.distance(from: user)))
        }

        return parts.joined(separator: " · ")
    }

    // MARK: - Description + stops

    /// Description — truncated to a 4-line preview by default with an
    /// inline "Read more" / "Show less" toggle. Apple Music / Podcasts
    /// pattern; keeps the action row close to the fold for tours with
    /// long editorial-voice longDescription strings (the Cloisters
    /// runs ~32 lines unbounded).
    ///
    /// The toggle row only renders when the text actually overflows
    /// the limit — short descriptions skip the affordance entirely.
    /// We detect overflow by comparing the text's intrinsic height
    /// at body typography against the height of the same text capped
    /// at `descriptionPreviewLineLimit` lines.
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            Text(tour.longDescription)
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .lineLimit(isDescriptionExpanded ? nil : Self.descriptionPreviewLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.2), value: isDescriptionExpanded)

            if shouldShowReadMoreToggle {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    Text(isDescriptionExpanded ? "Show less" : "Read more")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isDescriptionExpanded ? "Show less description" : "Read more description")
            }
        }
    }

    /// Cheap overflow check — uses raw character count as a proxy for
    /// "does this overflow 4 lines at 15pt body on iPhone width?"
    /// 240 chars is the empirical break point (4 × ~60 chars/line at
    /// our content width); anything under that always fits, anything
    /// over reliably overflows. A character-count proxy avoids a
    /// GeometryReader / Text-measurement round-trip on every body
    /// eval, which would fight the inline truncation animation.
    private var shouldShowReadMoreToggle: Bool {
        tour.longDescription.count > 240
    }

    /// Stops list — header unified to "Stops" for both single- and
    /// multi-stop tours per the album/track-list metaphor (PR 2 will
    /// reshape this into a numbered timeline with thumbnails + a
    /// now-playing indicator next to the currently-playing row).
    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("Stops")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .padding(.top, AtlasSpacing.md)

            ForEach(tour.stops.sorted(by: { $0.order < $1.order })) { stop in
                stopRow(stop)
                if stop.id != tour.stops.last?.id {
                    Divider()
                }
            }
        }
    }

    /// Tappable stop row — whole row acts as one play affordance
    /// (Apple Podcasts pattern). Leading column shows the stop
    /// number, or an animated waveform when this stop is currently
    /// producing audio. Trailing column shows a play / pause SF
    /// Symbol so the per-row affordance is also visible at the
    /// row's right edge — same effect on tap.
    private func stopRow(_ stop: Stop) -> some View {
        Button {
            handleStopTap(stop)
        } label: {
            HStack(alignment: .top, spacing: AtlasSpacing.md) {
                // Stop number, OR an animated waveform when this stop is
                // currently playing. The waveform sits in the same 24pt
                // slot as the number so the column alignment doesn't
                // shift when playback starts. `.symbolEffect(.variableColor.iterative)`
                // is iOS 17+ — Atlas targets 26.2+, so it's fine.
                Group {
                    if isPlayingStop(stop) {
                        Image(systemName: "waveform")
                            .font(AtlasTypography.body.weight(.semibold))
                            .foregroundStyle(AtlasColors.mapPin)
                            .symbolEffect(.variableColor.iterative, options: .repeating)
                            .accessibilityLabel("Playing")
                    } else {
                        Text("\(stop.order + 1)")
                            .font(AtlasTypography.body)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                }
                .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    Text(stop.title.uppercased())
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                        .multilineTextAlignment(.leading)

                    if let caption = stop.caption {
                        Text(caption)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(AtlasFormatters.duration(seconds: stop.audioDurationSeconds))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }

                Spacer()
            }
            .padding(.vertical, AtlasSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(stopRowAccessibilityLabel(for: stop))
        .accessibilityHint("Plays this stop")
    }

    private func stopRowAccessibilityLabel(for stop: Stop) -> String {
        let base = "Stop \(stop.order + 1): \(stop.title)"
        if isPlayingStop(stop) && audioPlayer.state == .playing {
            return "\(base), now playing"
        }
        return base
    }

    /// Whole-row tap handler. If this stop is the audible one, toggle
    /// pause / resume in place; otherwise start playback at this stop.
    private func handleStopTap(_ stop: Stop) {
        let isAudible = appShared.currentPlayingStopId == stop.id
            && audioPlayer.currentSourceId == tour.id.uuidString
        if isAudible {
            switch audioPlayer.state {
            case .playing, .loading:
                audioPlayer.pause()
                return
            case .paused, .ended:
                audioPlayer.play()
                return
            case .idle, .failed:
                break // fall through to a fresh play
            }
        }
        playStop(stop)
    }

    /// Plays the given stop's audio through `AudioPlayerService` —
    /// lifted from `PlayerView.playStop(at:)`. Prefers the on-disk
    /// copy when the tour is downloaded; sets the shared
    /// `currentPlayingStopId` so the waveform indicator + row
    /// highlight light up immediately.
    private func playStop(_ stop: Stop) {
        guard let remoteURL = URL(string: stop.audioURL) else { return }
        let url = tourDownloader.localURL(forStop: stop, in: tour) ?? remoteURL
        let maker = dataService.maker(for: tour)
        appShared.currentPlayingStopId = stop.id
        audioPlayer.play(
            url: url,
            title: tour.title,
            artist: maker?.displayName,
            sourceId: tour.id.uuidString
        )
    }

    // MARK: - Map preview + directions

    /// Map body for the MAP tab. Pannable/zoomable map with every
    /// stop, a walking-route polyline on multi-stop tours, and the
    /// user-location dot. Below the map: a `GET DIRECTIONS` menu
    /// (Apple Maps / Google Maps) that opens walking directions to
    /// the first stop.
    ///
    /// The old free-standing "Location" header is gone — the tab
    /// label above already names this surface. The walking route is
    /// prefetched on tour load by the scrollBody's `.task`, so this
    /// view doesn't own the async fetch anymore; switching to Map
    /// renders the polyline immediately if it's ready.
    private var mapContent: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Map(initialPosition: .region(initialMapRegion)) {
                // Polylines declared first → drawn under the pins.
                // MapContent z-order follows declaration order (later
                // = on top).
                ForEach(Array(routePolylines.enumerated()), id: \.offset) { _, polyline in
                    MapPolyline(polyline)
                        .stroke(AtlasColors.mapPin, lineWidth: 5)
                }
                ForEach(stopGroupsForMap) { group in
                    Annotation(
                        group.stops.first?.title ?? "Stop",
                        coordinate: group.coordinate,
                        anchor: .center
                    ) {
                        mapStopPin(for: group)
                    }
                }
                // User-location dot — paints when the user has
                // granted location permission (already requested by
                // ContentView on first launch for the home map).
                // Lets users zoom out to see where they are relative
                // to the tour.
                //
                // System `UserAnnotation()` would inherit the app's
                // terracotta `AccentColor` and render orange — same
                // issue HomeMapSection.UserLocationDot's doc comment
                // calls out. We paint an explicit Apple-Maps-blue
                // dot here for the same reason; heading wedge isn't
                // needed in this static preview, so this is just the
                // halo + dot, not the full home `UserLocationDot`.
                if let userLocation = locationManager.userLocation {
                    Annotation("My location", coordinate: userLocation.coordinate, anchor: .center) {
                        userLocationDot
                    }
                    .annotationTitles(.hidden)
                }
            }
            // Match the home map's style exactly: muted standard
            // emphasis + the same curated POI allowlist
            // (`HomeMapSection.tourPOI`), so landmarks / museums /
            // parks / transit show through but ATMs / retail /
            // restaurants don't. Keeps the inline preview reading
            // as the same canvas as the home map.
            .mapStyle(.standard(emphasis: .muted, pointsOfInterest: HomeMapSection.tourPOI))
            // Match the hero image's footprint exactly: same height
            // token, no corner radius (square corners). Horizontal
            // padding is applied to the whole map-tab content below
            // so the map aligns with the tab row + the gallery.
            .frame(height: AtlasSpacing.heroHeight)
        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Persistent `GET DIRECTIONS` affordance — hoisted out of the
    /// map body so it renders on both tabs. Keeps the layout height
    /// constant when the user toggles between Gallery and Map (owner
    /// ask, iteration 2). Semantically map-related, but present on
    /// Gallery too as the "get me to this tour" affordance.
    ///
    /// Uses the `?api=1` universal link for Google Maps so iOS
    /// routes the tap to the Google Maps app when installed or
    /// Safari as a fallback — no `LSApplicationQueriesSchemes`
    /// entry needed.
    private var getDirectionsLink: some View {
        Menu {
            Button {
                openInAppleMaps()
            } label: {
                Label("Apple Maps", systemImage: "applelogo")
            }
            Button {
                openInGoogleMaps()
            } label: {
                Label("Google Maps", systemImage: "globe")
            }
        } label: {
            Text("GET DIRECTIONS")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.mapPin)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.top, AtlasSpacing.xs)
        .accessibilityLabel("Get directions")
        .accessibilityHint("Opens Apple Maps or Google Maps with walking directions to the start of the tour.")
    }

    private var sortedStopsForMap: [Stop] {
        tour.stops.sorted(by: { $0.order < $1.order })
    }

    /// One pin per unique coordinate. When two or more stops share a
    /// coordinate (e.g. an intro + first stop staged in the same
    /// spot) they collapse into a single pin labeled with all their
    /// numbers (e.g. `1,2`). Preserves stop order within a group.
    private var stopGroupsForMap: [StopGroup] {
        var buckets: [(coordinate: CLLocationCoordinate2D, stops: [Stop])] = []
        for stop in sortedStopsForMap {
            if let idx = buckets.firstIndex(where: {
                $0.coordinate.latitude == stop.latitude
                    && $0.coordinate.longitude == stop.longitude
            }) {
                buckets[idx].stops.append(stop)
            } else {
                buckets.append((stop.coordinate, [stop]))
            }
        }
        return buckets.map { bucket in
            StopGroup(coordinate: bucket.coordinate, stops: bucket.stops)
        }
    }

    /// One pin's worth of stops — all stops at the same coordinate.
    /// `id` is built from lat/lon so ForEach diffing is stable across
    /// re-renders (CLLocationCoordinate2D itself isn't Hashable).
    private struct StopGroup: Identifiable {
        let coordinate: CLLocationCoordinate2D
        let stops: [Stop]
        var id: String { "\(coordinate.latitude),\(coordinate.longitude)" }
    }

    /// Stop pin for the inline preview. On single-stop tours we
    /// render the same small 14pt gold dot as the home map's
    /// `StopPin` (which is `private` to HomeMapSection so it can't
    /// be reused directly). On multi-stop tours we render a numbered
    /// gold badge — Capsule-shaped so it can stretch horizontally
    /// when multiple stops share a coordinate (label becomes e.g.
    /// `1,2` instead of layering pins on top of each other). Numbers
    /// are stop `order + 1`, matching the numbered stops list above.
    @ViewBuilder
    private func mapStopPin(for group: StopGroup) -> some View {
        if tour.kind == .multiStop {
            let label = group.stops
                .map { String($0.order + 1) }
                .joined(separator: ",")
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, AtlasSpacing.sm)
                .frame(minWidth: 22, minHeight: 22)
                .background(Capsule().fill(AtlasColors.mapPin))
                .overlay(Capsule().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 1)
        } else {
            Circle()
                .fill(AtlasColors.mapPin)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 1)
        }
    }

    /// Apple-Maps-style user-location dot for the inline preview:
    /// soft blue accuracy halo + solid blue dot with a white ring.
    /// Mirrors HomeMapSection's `UserLocationDot` *without* the
    /// heading wedge (this preview is static, no compass needed)
    /// and with all colors explicit so the dot stays blue instead
    /// of inheriting the terracotta app accent.
    private var userLocationDot: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 46, height: 46)
            Circle()
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.25), radius: 1.5)
        }
        .frame(width: 46, height: 46)
    }

    /// Single stop → tight neighborhood span (~0.005°, matches the
    /// home recenter button). Multi-stop → bounding box of all stop
    /// coordinates with ~40% padding so the route doesn't kiss the
    /// edges of the preview frame.
    private var initialMapRegion: MKCoordinateRegion {
        let stops = sortedStopsForMap
        // Every tour has at least one stop per the schema, but guard
        // anyway — fall back to a wide NYC view if somehow empty.
        guard let first = stops.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        if stops.count == 1 {
            return MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
        let lats = stops.map(\.latitude)
        let lons = stops.map(\.longitude)
        let minLat = lats.min() ?? first.latitude
        let maxLat = lats.max() ?? first.latitude
        let minLon = lons.min() ?? first.longitude
        let maxLon = lons.max() ?? first.longitude
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = max((maxLat - minLat) * 1.4, 0.005)
        let lonDelta = max((maxLon - minLon) * 1.4, 0.005)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    /// Async-fetches a walking route from `MKDirections` between each
    /// consecutive pair of stops on a multi-stop tour. Sequential
    /// awaits are intentional — MKDirections rate-limits concurrent
    /// requests, and the typical Atlas walk is 4–6 stops so total
    /// latency is acceptable. Failures are silent: any unreachable
    /// segment just won't draw, and the pins stay correct.
    private func loadWalkingRoute() async {
        guard tour.kind == .multiStop else {
            routePolylines = []
            return
        }
        let stops = sortedStopsForMap
        guard stops.count >= 2 else { return }
        var polylines: [MKPolyline] = []
        for i in 0..<(stops.count - 1) {
            let req = MKDirections.Request()
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: stops[i].coordinate))
            req.destination = MKMapItem(placemark: MKPlacemark(coordinate: stops[i + 1].coordinate))
            req.transportType = .walking
            do {
                let response = try await MKDirections(request: req).calculate()
                if let route = response.routes.first {
                    polylines.append(route.polyline)
                }
            } catch {
                // Silent: route segment skipped, pins remain.
            }
        }
        routePolylines = polylines
    }

    /// Opens Apple Maps with walking directions to the FIRST stop of
    /// the tour (where the user needs to walk to before the audio
    /// starts). Multi-stop tours show the full inline preview already
    /// — the directions link is "get me to the start," not "navigate
    /// the whole walk for me."
    private func openInAppleMaps() {
        guard let destination = sortedStopsForMap.first else { return }
        var components = URLComponents(string: "http://maps.apple.com/")!
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "dirflg", value: "w")
        ]
        if let url = components.url {
            openURL(url)
        }
    }

    /// Opens Google Maps with walking directions to the first stop.
    /// Uses the cross-platform `?api=1` universal link instead of the
    /// `comgooglemaps://` scheme — iOS routes it to the Google Maps
    /// app if installed and falls back to Safari otherwise, so we
    /// don't need an `LSApplicationQueriesSchemes` entry in
    /// `Info.plist` to detect installation.
    private func openInGoogleMaps() {
        guard let destination = sortedStopsForMap.first else { return }
        var components = URLComponents(string: "https://www.google.com/maps/dir/")!
        components.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "travelmode", value: "walking")
        ]
        if let url = components.url {
            openURL(url)
        }
    }

    // MARK: - Nearby Tours

    /// "Nearby Tours" — up to 5 tours closest to *this* tour (by
    /// centroid distance), excluding self. Row style matches
    /// `MakerView.tourRow`: 64pt square hero, BODY all-caps title,
    /// caption subtitle (duration + distance from this tour), tail
    /// chevron, divider between rows.
    ///
    /// Hidden when the catalog has no other tours.
    @ViewBuilder
    private var nearbyToursSection: some View {
        let nearby = nearbyTours
        if !nearby.isEmpty {
            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                Text("Nearby Tours")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .padding(.top, AtlasSpacing.md)

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(nearby) { other in
                        // We're already inside the detail layer's
                        // own NavigationStack, so push another
                        // TourDetailView onto it — same pattern as
                        // MakerView's `tourOpen` when reached from
                        // within a detail layer. X close still
                        // dismisses the whole layer; the back chevron
                        // pops one level. Avoids double-stacking a
                        // second slide-up layer.
                        NavigationLink {
                            TourDetailView(tour: other)
                        } label: {
                            nearbyTourRow(other)
                        }
                        .buttonStyle(.plain)

                        if other.id != nearby.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    /// 5 tours closest to this tour's centroid (centroid-to-centroid
    /// distance), excluding self. `dataService.toursNearby` returns
    /// the current tour first (distance 0 to itself), so we ask for
    /// 6 then drop self.
    private var nearbyTours: [Tour] {
        let here = CLLocation(
            latitude: tour.centroidLatitude,
            longitude: tour.centroidLongitude
        )
        return dataService.toursNearby(here, limit: 6)
            .filter { $0.id != tour.id }
            .prefix(5)
            .map { $0 }
    }

    /// Mirrors `MakerView.tourRow` exactly so list density is
    /// identical across surfaces.
    private func nearbyTourRow(_ other: Tour) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            HeroImageView(
                imageName: other.heroImageURL,
                height: 64,
                cornerRadius: 0,
                category: other.primaryCategory
            )
            .frame(width: 64)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(other.title)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(nearbySubtitleText(other))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
    }

    /// "2m 15s · 0.8 mi away" — distance is from this tour's
    /// centroid (the section's anchor), not from the user.
    /// `distanceAway`'s "away" suffix reads naturally in the
    /// "Nearby Tours" section context.
    private func nearbySubtitleText(_ other: Tour) -> String {
        let duration = AtlasFormatters.duration(seconds: other.totalDurationSeconds)
        let here = CLLocation(
            latitude: tour.centroidLatitude,
            longitude: tour.centroidLongitude
        )
        let distance = AtlasFormatters.distanceAway(meters: other.distance(from: here))
        return "\(duration) · \(distance)"
    }

    // MARK: - Button row (inline)

    /// Shared height for the three buttons so they line up in size and
    /// baseline.
    private let controlHeight: CGFloat = 44

    /// Inline button row — sits above the description so users can
    /// act without scrolling. Order: Start Tour (primary, full
    /// width) · Save · Download. Buttons are rendered as custom
    /// Capsule fills (primary) / strokes (secondary) rather than
    /// system `.borderedProminent` / `.bordered` so they sit at
    /// **exactly** 44pt visual height — the system styles add their
    /// own vertical padding around the label that would inflate the
    /// rendered button past 44.
    ///
    /// When this tour is the audible source, the Start Tour button's
    /// leading glyph is wrapped in a *PROGRESS RING* identical to the
    /// MiniPlayerBar's (lineWidth 2, clockwise trim, faint full-circle
    /// track behind). Same ring math, same visual identity — the
    /// detail-sheet button and the persistent mini-player read as one
    /// surface.
    private var buttonRow: some View {
        HStack(spacing: AtlasSpacing.md) {
            primaryTransportButton
            Button(action: toggleSaved) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .foregroundStyle(AtlasColors.mapPin)
                    .frame(width: controlHeight, height: controlHeight)
                    .background(Capsule().fill(AtlasColors.mapPin.opacity(0.15)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSaved ? "Remove from saved" : "Save tour")

            downloadButton
        }
        .frame(maxWidth: .infinity)
    }

    /// Composite primary transport surface — gold Capsule with three
    /// independent interactive zones:
    ///   - Leading icon button: tap = play/pause.
    ///   - Middle progress bar: drag = scrub (calls
    ///     `audioPlayer.seek(to:)` on release); tap is inert so the
    ///     user can't accidentally jump while reaching for the bar.
    ///   - Trailing time text: tap = play/pause (same as icon).
    /// The outer wrapper is NOT a Button — wrapping the whole row
    /// would consume the drag gesture before it reaches the bar.
    private var primaryTransportButton: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Button(action: handlePrimaryAction) {
                Image(systemName: primaryButtonIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 28, height: controlHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(primaryButtonTitle)

            primaryProgressBar
                .frame(maxWidth: .infinity)

            Button(action: handlePrimaryAction) {
                Text(primaryButtonTimeText)
                    .font(AtlasTypography.caption)
                    .monospacedDigit()
                    .frame(height: controlHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, AtlasSpacing.md)
        .frame(maxWidth: .infinity)
        .frame(height: controlHeight)
        .background(Capsule().fill(AtlasColors.mapPin))
    }

    // MARK: - Download button

    /// State-aware download control. Four faces:
    ///   - idle         → arrow.down icon, taps to start a download
    ///   - downloading  → circular progress around a stop icon, taps to cancel
    ///   - completed    → checkmark, taps to delete
    ///   - failed       → exclamation mark, taps to retry
    /// `tourDownloader.activeTourId` gates whether *other* tours can
    /// also start downloading — the button is disabled when another
    /// tour is already in flight.
    @ViewBuilder
    private var downloadButton: some View {
        let state = tourDownloader.states[tour.id] ?? .idle
        let isOtherActive = tourDownloader.activeTourId != nil
            && tourDownloader.activeTourId != tour.id

        Button(action: handleDownloadTap) {
            downloadButtonIcon(for: state)
                .font(.system(size: 20))
                .foregroundStyle(AtlasColors.mapPin)
                .frame(width: controlHeight, height: controlHeight)
                .background(Capsule().fill(AtlasColors.mapPin.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .disabled(isOtherActive)
        .accessibilityLabel(
            isOtherActive
                ? "Download unavailable"
                : downloadAccessibilityLabel(for: state)
        )
        .accessibilityHint(
            isOtherActive
                ? "Wait for the current download to finish, then try again."
                : ""
        )
    }

    @ViewBuilder
    private func downloadButtonIcon(for state: TourDownloader.DownloadState) -> some View {
        switch state {
        case .idle, .failed:
            Image(systemName: state == .idle ? "arrow.down.circle" : "exclamationmark.circle")
        case .downloading(let progress):
            ZStack {
                Image(systemName: "stop.circle")
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AtlasColors.primaryText, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 28, height: 28)
                    .animation(.linear(duration: 0.25), value: progress)
            }
        case .completed:
            // SF Symbol's multicolor variant for checkmark.circle.fill
            // is blue, not green. Hardcoding .green here as the one
            // exception to the theme-tokens rule — "success = green"
            // is a strong enough convention that the placeholder
            // theme would feel wrong without it. M-polish-theme can
            // promote this to an AtlasColors.success token later.
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    private func downloadAccessibilityLabel(for state: TourDownloader.DownloadState) -> String {
        switch state {
        case .idle: return "Download tour"
        case .downloading: return "Cancel download"
        case .completed: return "Delete downloaded tour"
        case .failed: return "Retry download"
        }
    }

    private func handleDownloadTap() {
        let state = tourDownloader.states[tour.id] ?? .idle
        switch state {
        case .idle, .failed:
            tourDownloader.download(tour: tour)
        case .downloading:
            tourDownloader.cancel(tourId: tour.id)
        case .completed:
            tourDownloader.deleteDownload(tourId: tour.id)
            libraryStore.clearDownload(tour.id)
        }
    }

    // MARK: - Overflow menu

    /// Top-trailing `…` overflow menu. Order:
    ///   1. Download (mirrors the inline download button's current state)
    ///   2. Save (mirrors the inline bookmark)
    ///   3. Share (ShareLink → standard iOS share sheet)
    ///   4. Follow creator — DISABLED in V1; the follow graph requires
    ///      accounts which aren't in scope. Shown grayed-out so the
    ///      slot is visible and the feature reads as "planned" rather
    ///      than missing.
    ///   5. Go to creator — pushes MakerView via `.navigationDestination`.
    ///   6. Report a concern — presents `ReportSheet` (writes to `reports`).
    @ViewBuilder
    private var overflowMenu: some View {
        Menu {
            Button(action: handleDownloadTap) {
                Label(menuDownloadLabel, systemImage: menuDownloadIcon)
            }
            .disabled(menuDownloadDisabled)

            Button(action: toggleSaved) {
                Label(
                    isSaved ? "Remove from saved" : "Save",
                    systemImage: isSaved ? "bookmark.fill" : "bookmark"
                )
            }

            // Share only the tour's https Universal Link — no accompanying
            // message text, so iMessage shows a single rich link bubble (not a
            // link bubble + a separate text bubble). The card's title/image
            // come from the landing page's Open Graph tags.
            ShareLink(
                item: AtlasShareLink.tourURL(for: tour),
                subject: Text(tour.title)
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            if journeyService != nil {
                Button {
                    showingAddToJourney = true
                } label: {
                    Label("Add to a Journey", systemImage: "text.badge.plus")
                }
            }

            if groupListen != nil {
                Button {
                    showingGroupListen = true
                } label: {
                    Label("Listen together", systemImage: "person.2.wave.2")
                }
            }

            Section {
                FollowMenuButton(makerId: tour.makerId)

                Button {
                    showingMaker = true
                } label: {
                    Label("Go to creator", systemImage: "person.crop.circle")
                }
            }

            Section {
                Button(role: .destructive) {
                    showingReport = true
                } label: {
                    Label("Report a concern", systemImage: "exclamationmark.bubble")
                }
            }
        } label: {
            chromeCapsule("ellipsis")
                .accessibilityLabel("More options")
        }
    }

    /// Shared visual for every top chrome control — 44×44 Capsule
    /// with a neutral dark translucent fill and a 20pt regular-weight
    /// SF Symbol in `AtlasColors.primaryText`. Gold (`mapPin`) is
    /// reserved for the inline action row so the chrome's "navigate
    /// + manage" controls stay tonally separate from the chrome's
    /// "play this tour" controls (owner correction, 2026-06-03).
    private func chromeCapsule(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(AtlasColors.primaryText)
            .frame(width: 44, height: 44)
            .background(Capsule().fill(AtlasColors.tertiaryText.opacity(0.18)))
            .contentShape(Capsule())
    }

    /// Menu-side label for the download item — mirrors the inline
    /// button's state so the menu reads as a parallel control surface.
    private var menuDownloadLabel: String {
        let state = tourDownloader.states[tour.id] ?? .idle
        switch state {
        case .idle:        return "Download"
        case .downloading: return "Cancel download"
        case .completed:   return "Remove download"
        case .failed:      return "Retry download"
        }
    }

    private var menuDownloadIcon: String {
        let state = tourDownloader.states[tour.id] ?? .idle
        switch state {
        case .idle:        return "arrow.down.circle"
        case .downloading: return "stop.circle"
        case .completed:   return "checkmark.circle.fill"
        case .failed:      return "exclamationmark.circle"
        }
    }

    private var menuDownloadDisabled: Bool {
        tourDownloader.activeTourId != nil
            && tourDownloader.activeTourId != tour.id
    }

    // MARK: - Actions

    /// Start Tour kicks off audio playback *non-modally* — the
    /// full `PlayerView` sheet is no longer presented from the detail
    /// sheet. The user opens the full player by tapping the
    /// mini-player at the bottom of the screen, the same way Apple
    /// Music and Spotify gate the full now-playing UI.
    ///
    /// Logic mirrors `PlayerView.startPlaybackIfNeeded`: if this
    /// tour's audio is already loaded, just resume (or no-op when
    /// already playing). Otherwise, start from the intro audio if
    /// it exists, else the first stop.
    ///
    /// **Multi-stop auto-advance.** For geofenced multi-stop tours
    /// (Atlas's common case) `ProximityMonitor` drives the next
    /// stop's playback as the user walks. For non-geofenced
    /// multi-stop tours auto-advance still requires `PlayerView` to
    /// be the visible surface (its `.onChange(of: audioPlayer.state)`
    /// observer is what calls `playStop(at: nextIndex)`); a future
    /// pass can promote that orchestrator to an env-level service so
    /// auto-advance survives without `PlayerView` on screen. Single-
    /// stop tours and geofenced multi-stop tours are unaffected.
    private func handlePrimaryAction() {
        // If this tour's audio is already loaded, toggle pause/resume
        // in place — the button now doubles as the tour-level
        // transport control on the detail sheet (owner-confirmed,
        // 2026-06-03). The mini-player is still the canonical
        // transport surface, but the detail button is no longer a
        // dead-end "Playing" label.
        if audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state != .idle
            && audioPlayer.state != .failed {
            switch audioPlayer.state {
            case .playing, .loading:
                audioPlayer.pause()
            case .paused, .ended:
                audioPlayer.play()
            case .idle, .failed:
                break
            }
            return
        }

        let maker = dataService.maker(for: tour)
        let sortedStops = tour.stops.sorted(by: { $0.order < $1.order })

        // Prefer the on-disk copy when the tour is downloaded — same
        // pattern PlayerView uses. Falls back to streaming.
        if let introString = tour.introAudioURL,
           let remoteURL = URL(string: introString) {
            let url = tourDownloader.localURL(forIntroOf: tour) ?? remoteURL
            // Intro audio doesn't belong to a single stop.
            appShared.currentPlayingStopId = nil
            audioPlayer.play(
                url: url,
                title: tour.title,
                artist: maker?.displayName,
                sourceId: tour.id.uuidString
            )
        } else if let firstStop = sortedStops.first,
                  let remoteURL = URL(string: firstStop.audioURL) {
            let url = tourDownloader.localURL(forStop: firstStop, in: tour) ?? remoteURL
            // Light up the now-playing indicator on the first stop
            // row immediately — `PlayerView` would do this too if it
            // were the surface starting playback.
            appShared.currentPlayingStopId = firstStop.id
            audioPlayer.play(
                url: url,
                title: tour.title,
                artist: maker?.displayName,
                sourceId: tour.id.uuidString
            )
        }
    }

    /// Whether a given stop is the one currently producing audio.
    /// Combines the shared `currentPlayingStopId` (set by every
    /// playback trigger — PlayerView, ProximityMonitor, this view's
    /// Start Tour) with the audio engine's live state, so the
    /// indicator clears on pause / end / failure rather than
    /// flickering as a stale highlight.
    private func isPlayingStop(_ stop: Stop) -> Bool {
        appShared.currentPlayingStopId == stop.id
            && audioPlayer.currentSourceId == tour.id.uuidString
            && (audioPlayer.state == .playing || audioPlayer.state == .loading)
    }

    private func toggleSaved() {
        libraryStore.toggleSaved(tour.id)
    }

    private var isSaved: Bool {
        libraryStore.isSaved(tour.id)
    }

    // MARK: - Audio state derivations
    //
    // We identify "this tour's audio" via the AudioPlayerService's
    // `currentSourceId`, set by PlayerView to the tour's UUID string
    // when it calls `play(url:title:artist:sourceId:)`. M-player owns
    // the actual playback control; this view only reads the state for
    // label decoration.

    private var isThisTourActive: Bool {
        audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state != .idle
            && audioPlayer.state != .failed
    }

    /// Label adapts to the audio state:
    ///   - "Start Tour" when idle / no audio loaded → tap starts playback.
    ///   - "Pause"  when audio is actively producing sound → tap pauses.
    ///   - "Resume" when paused or ended → tap resumes / replays.
    private var primaryButtonTitle: String {
        guard isThisTourActive else { return "Start Tour" }
        switch audioPlayer.state {
        case .playing, .loading: return "Pause"
        case .paused, .ended:    return "Resume"
        case .idle, .failed:     return "Start Tour"
        }
    }

    private var primaryButtonIcon: String {
        guard isThisTourActive else { return "play.fill" }
        switch audioPlayer.state {
        case .playing, .loading: return "pause.fill"
        case .paused, .ended:    return "play.fill"
        case .idle, .failed:     return "play.fill"
        }
    }

    private var isThisTourLoading: Bool {
        audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state == .loading
    }

    // MARK: - Primary-button transport row

    /// 0…1 fraction of the loaded audio that has played, mirrored
    /// from MiniPlayerBar's identical computation. 0 when this tour
    /// isn't the audible source or the duration isn't yet known.
    /// Forced to 1 on `.ended` so the bar reads as fully filled when
    /// AVPlayer stops publishing currentTime a hair short of duration.
    private var tourProgressFraction: Double {
        guard isThisTourActive else { return 0 }
        if audioPlayer.state == .ended { return 1 }
        guard audioPlayer.duration > 0 else { return 0 }
        let raw = audioPlayer.currentTime / audioPlayer.duration
        return min(max(raw, 0), 1)
    }

    /// Linear scrubbable progress bar inside the primary button.
    /// Background track is white at 25% opacity; fill is solid white.
    /// Drag = scrub: while the gesture is active, the bar fill +
    /// time-remaining text mirror the user's finger position; on
    /// release we call `audioPlayer.seek(to:)`. The drag gesture
    /// lives ON the bar (not on the outer button) so the icon + time
    /// text remain clean play/pause tap targets.
    private var primaryProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: geo.size.width, height: 4)
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * displayedPrimaryProgress, height: 4)
                    .animation(isScrubbingPrimary ? nil : .linear(duration: 0.5),
                               value: displayedPrimaryProgress)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(primaryScrubGesture(barWidth: geo.size.width))
        }
        .frame(height: controlHeight)
        .accessibilityLabel("Playback progress")
        .accessibilityValue(primaryButtonTimeText)
    }

    /// Drag gesture for the primary progress bar. No-ops on idle
    /// tours (nothing to scrub); on the audible tour it tracks the
    /// finger position to `primaryScrubTime`, then commits with
    /// `audioPlayer.seek(to:)` on release.
    private func primaryScrubGesture(barWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isThisTourActive, audioPlayer.duration > 0 else { return }
                if !isScrubbingPrimary {
                    isScrubbingPrimary = true
                    primaryScrubTime = audioPlayer.currentTime
                }
                let fraction = min(max(value.location.x / barWidth, 0), 1)
                primaryScrubTime = fraction * audioPlayer.duration
            }
            .onEnded { value in
                guard isThisTourActive, audioPlayer.duration > 0 else {
                    isScrubbingPrimary = false
                    return
                }
                let fraction = min(max(value.location.x / barWidth, 0), 1)
                let target = fraction * audioPlayer.duration
                primaryScrubTime = target
                audioPlayer.seek(to: target)
                isScrubbingPrimary = false
            }
    }

    /// Bar-fill fraction — shows the scrub position while dragging,
    /// the live playback position otherwise.
    private var displayedPrimaryProgress: Double {
        if isScrubbingPrimary, audioPlayer.duration > 0 {
            return min(max(primaryScrubTime / audioPlayer.duration, 0), 1)
        }
        return tourProgressFraction
    }

    /// Time remaining text on the primary button's trailing edge.
    /// While the tour is playing this counts down from `duration` to
    /// zero; while scrubbing it counts the remaining time at the
    /// scrub position. Before playback starts (or for any other tour)
    /// it shows the tour's total duration.
    private var primaryButtonTimeText: String {
        let totalSeconds: TimeInterval
        let elapsed: TimeInterval
        if isThisTourActive && audioPlayer.duration > 0 {
            totalSeconds = audioPlayer.duration
            elapsed = isScrubbingPrimary ? primaryScrubTime : audioPlayer.currentTime
        } else {
            totalSeconds = TimeInterval(tour.totalDurationSeconds)
            elapsed = 0
        }
        let remaining = max(0, totalSeconds - elapsed)
        return formatTimeRemaining(remaining)
    }

    /// `M:SS` for under an hour, `H:MM:SS` for an hour or more.
    /// Mirrors PlayerView's `formatTime` for visual consistency.
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

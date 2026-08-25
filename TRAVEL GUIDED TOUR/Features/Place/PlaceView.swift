import SwiftUI
import CoreLocation
import MapKit

/// A site several tours describe — the page you reach by tapping a place pin.
///
/// Exists because a pin can stand for more than one tour. Before the place
/// layer those tours shared a coordinate, merged into a cluster no camera could
/// separate, and were simply unreachable; build 64 stacked their cards over the
/// map as a stopgap. This is the durable answer: the site gets a page, and the
/// tours become its contents.
///
/// **Built from `TourDetailView`'s structure, deliberately** (owner direction,
/// 2026-08-18: *"I want it to be consistent with my other pages such as the
/// tour details page"*). The first version shipped its own layout and read as a
/// different app — a white ground where every other detail page uses
/// `secondaryBackground`, a bare circular close button floating on the photo,
/// and a full-bleed hero. What the two pages now share, and must keep sharing:
///
///   - `secondaryBackground` ground and a hidden system nav bar.
///   - A sticky chrome row, parked and painted by the shared `atlasChromeRow`
///     — 44 pt capsules on an opaque bar (NOT a material: see that file),
///     content scrolling *under* it.
///   - `AtlasTabStrip` (GALLERY / MAP) above a swap zone, with `GET DIRECTIONS`
///     *outside* it so the layout height doesn't jump when you toggle.
///   - `TourMediaCarousel` at the hero ratio, inset by `lg`, square corners.
///   - Outer stack spacing `lg`, inner `md`, one horizontal `lg` on the body.
///   - A 4-line description with an inline Read more.
///
/// **The tour list's header is the MAKER page's header** (owner, 2026-08-25:
/// *"it should just look exactly like the example from profile page"*) — the
/// count, the list/grid toggle and the sort pull-down, in that order and those
/// colours. ⚠️ It was briefly brass and read "N TOURS AVAILABLE" (2026-08-18);
/// that divergence is retired, and the note explaining it now sits at the row
/// itself so it cannot be restored by accident.
struct PlaceView: View {
    let place: Place

    @Environment(DataService.self) private var dataService
    @Environment(LocationManager.self) private var locationManager
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(SavedPlacesStore.self) private var savedPlaces
    @Environment(\.openURL) private var openURL

    let onDismiss: () -> Void

    @State private var topSectionTab: TopSectionTab = .gallery
    @State private var isDescriptionExpanded = false
    @State private var showingReport = false
    /// Rows or photo grid, remembered between visits — the same control the
    /// maker page carries (owner, 2026-08-25). The key is this page's own; see
    /// `AtlasListLayout` for why it is not shared with the maker page's.
    @AppStorage("placeListLayout") private var layout: AtlasListLayout = .list
    /// Sort, its own key for the same reason. Opens on Newest, which is what
    /// `Place.ranked` already produced when this page could not be sorted.
    @AppStorage("placeSortCriterion") private var sortCriterion: AtlasTourSort = .dateAdded
    @AppStorage("placeSortAscending") private var sortAscending: Bool = false
    /// Measured width of the grid container — drives square tile sizing.
    @State private var gridContentWidth: CGFloat = 0

    private enum TopSectionTab: String, CaseIterable, Identifiable {
        case gallery = "Gallery"
        case map = "Map"
        var id: String { rawValue }
    }

    /// Same empirical break point tour detail uses — 4 lines of 15 pt body at
    /// content width. A character count avoids a `GeometryReader` round-trip on
    /// every body eval, which would fight the truncation animation.
    private static let descriptionPreviewLineLimit = 4
    private static let descriptionOverflowThreshold = 240

    /// The place's tours in catalogue order. `Place.ranked` owns the rule so
    /// it can change without a content re-seed — and it stays the page's
    /// identity (which photograph leads, which category the placeholder
    /// borrows) so that sorting the list cannot change the hero under the
    /// reader.
    private var rankedTours: [Tour] {
        dataService.rankedTours(at: place)
    }

    /// The list as the reader has chosen to order it. The sort is stable, so
    /// its default — Newest — reproduces `Place.ranked` exactly, tiebreaks
    /// included; see `AtlasTourSort.sorted`.
    private var tours: [Tour] {
        AtlasTourSort.sorted(
            rankedTours,
            by: sortCriterion,
            ascending: sortAscending,
            from: locationManager.userLocation
        )
    }

    /// The place's own editorial hero when it has one, otherwise the hero of
    /// its top-ranked tour — so a place is never blocked on new photography.
    private var heroImageURL: String {
        place.heroImageURL ?? rankedTours.first?.heroImageURL ?? ""
    }

    /// Extra photos only when the place has a hero of its own. If the hero is
    /// borrowed from a tour, showing the *place's* gallery behind it would put
    /// two unrelated sets of pictures in one carousel.
    private var galleryImageURLs: [String]? {
        place.heroImageURL == nil ? nil : place.additionalImageURLs
    }

    private var distanceText: String? {
        guard let user = locationManager.userLocation else { return nil }
        let here = CLLocation(latitude: place.latitude, longitude: place.longitude)
        return AtlasFormatters.distanceAway(meters: here.distance(from: user))
    }

    private var isSaved: Bool { savedPlaces.isSaved(place.id) }

    var body: some View {
        scrollBody
            // Shared with tour detail and the list page — see `atlasChromeRow`,
            // including why the fill is opaque and must not sit over a material.
            .atlasChromeRow { chromeControls }
            .sheet(isPresented: $showingReport) {
                ReportSheet(target: .place(place))
            }
    }

    // MARK: - Chrome

    /// X close (leading) · bookmark · overflow (trailing) — the same three
    /// controls, in the same order and the same capsule, as tour detail. The
    /// row around them comes from `atlasChromeRow`, shared with that page.
    @ViewBuilder
    private var chromeControls: some View {
        Button(action: onDismiss) {
            AtlasChromeButton("xmark")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")

        Spacer()

        Button {
            savedPlaces.toggleSaved(place.id)
        } label: {
            AtlasChromeButton(isSaved ? "bookmark.fill" : "bookmark")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Remove \(place.name) from saved places" : "Save \(place.name)")

        overflowMenu
    }

    /// Deliberately shorter than tour detail's menu. There is no download (a
    /// place has no audio of its own), no creator to follow (a place has
    /// several), and no group to listen with.
    private var overflowMenu: some View {
        Menu {
            Button {
                savedPlaces.toggleSaved(place.id)
            } label: {
                Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
            }

            // Link only, no message text, so iMessage shows a single rich link
            // bubble rather than a link plus a stray text bubble — same reason
            // tour detail shares bare.
            ShareLink(
                item: AtlasShareLink.placeURL(for: place),
                subject: Text(place.name)
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Section {
                Button(role: .destructive) {
                    showingReport = true
                } label: {
                    Label("Report a concern", systemImage: "exclamationmark.bubble")
                }
            }
        } label: {
            AtlasChromeButton("ellipsis")
                .accessibilityLabel("More options")
        }
    }

    /// Shared visual for every top chrome control — identical to tour
    /// detail's, down to the fill opacity. Gold is reserved for action
    /// controls, so chrome stays neutral.

    // MARK: - Body

    private var scrollBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                topSection
                    .padding(.top, AtlasSpacing.md)

                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    masthead
                    if let description = place.description, !description.isEmpty {
                        descriptionSection(description)
                    }
                }
                .padding(.horizontal, AtlasSpacing.lg)

                // Rows run edge to edge — their own padding is inside, so the
                // dividers reach the screen edges the way a list's do. That is
                // why this sits outside the padded stack above.
                toursSection

                // The bottom module floats over every screen from a higher
                // window, so the last row has to reserve its height or it can
                // never be tapped.
                Color.clear.frame(height: AtlasBottomModule.height())
            }
        }
    }

    // MARK: - Top section (Gallery / Map)

    /// `GET DIRECTIONS` renders **outside** the swap zone, exactly as on tour
    /// detail, so the page doesn't change height when the tab flips.
    private var topSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            AtlasTabStrip(tabs: TopSectionTab.allCases, selection: $topSectionTab)
            Group {
                switch topSectionTab {
                case .gallery: imageSection
                case .map:     mapContent
                }
            }
            getDirectionsLink
        }
    }

    /// The **same** carousel component tour detail and the player use. With no
    /// extra photos it renders precisely as a single image did, so nothing
    /// changes on screen until place photography exists — the point is that the
    /// two carousels can no longer drift apart.
    private var imageSection: some View {
        TourMediaCarousel(
            heroImageURL: heroImageURL,
            additionalImageURLs: galleryImageURLs,
            videoURLs: nil,
            height: nil,   // takes AtlasSpacing.heroAspectRatio
            category: rankedTours.first?.primaryCategory ?? .culturalHeritage
        )
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// One pin, no route. Simpler than tour detail's map, which has to draw a
    /// walking polyline between stops — a place is a single point by
    /// definition, which is what makes it a place.
    private var mapContent: some View {
        Map(initialPosition: .region(mapRegion)) {
            Annotation(place.name, coordinate: place.coordinate, anchor: .center) {
                PlacePin(count: tours.count)
            }
            .annotationTitles(.hidden)

            if let userLocation = locationManager.userLocation {
                // Explicit blue dot rather than `UserAnnotation()`, which would
                // inherit the app's gold accent. No heading — this preview is
                // static, so a compass wedge would be noise.
                Annotation("My location", coordinate: userLocation.coordinate, anchor: .center) {
                    UserLocationDot(headingDegrees: nil)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: HomeMapSection.tourPOI))
        // Exactly the hero's footprint, so the page height is identical on
        // both tabs.
        // Same sizing as the carousel it swaps with, so the page height
        // is identical on both tabs.
        .atlasHeroSizing(nil)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// ~400 m across — close enough to read the streets around the site, which
    /// is the question someone opening the Map tab is actually asking.
    private var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )
    }

    /// Mirrors tour detail's directions menu, including the `?api=1` universal
    /// link for Google Maps so iOS routes to the app when installed and Safari
    /// otherwise, with no `LSApplicationQueriesSchemes` entry needed.
    private var getDirectionsLink: some View {
        Menu {
            Button {
                var c = URLComponents(string: "http://maps.apple.com/")!
                c.queryItems = [
                    URLQueryItem(name: "daddr", value: "\(place.latitude),\(place.longitude)"),
                    URLQueryItem(name: "dirflg", value: "w")
                ]
                if let url = c.url { openURL(url) }
            } label: {
                Label("Apple Maps", systemImage: "applelogo")
            }
            Button {
                var c = URLComponents(string: "https://www.google.com/maps/dir/")!
                c.queryItems = [
                    URLQueryItem(name: "api", value: "1"),
                    URLQueryItem(name: "destination", value: "\(place.latitude),\(place.longitude)"),
                    URLQueryItem(name: "travelmode", value: "walking")
                ]
                if let url = c.url { openURL(url) }
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
        .accessibilityHint("Opens Apple Maps or Google Maps with walking directions to this place.")
    }

    // MARK: - Masthead + description

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(place.name.uppercased())
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            // Address is optional — the catalog has never stored one, so these
            // are backfilled. A place without it shows just the distance, and
            // one with neither shows no line at all rather than an empty gap.
            let metaLine = [place.address, distanceText]
                .compactMap { $0 }
                .joined(separator: " · ")
            if !metaLine.isEmpty {
                Text(metaLine)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .padding(.top, 6)
            }
        }
    }

    /// Truncated to 4 lines with an inline toggle, like tour detail. Untruncated
    /// it pushed the tour list off the screen — on the one page whose whole
    /// purpose is that list.
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            Text(description)
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .lineLimit(isDescriptionExpanded ? nil : Self.descriptionPreviewLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.2), value: isDescriptionExpanded)

            if description.count > Self.descriptionOverflowThreshold {
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

    // MARK: - The tours

    /// "29 TOURS" / "1 TOUR" — the maker page's wording, uppercased at the
    /// call site so VoiceOver still reads it as words.
    private var tourCountText: String {
        tours.count == 1 ? "1 tour" : "\(tours.count) tours"
    }

    private var toursSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            // 🔴 This row is the maker page's row — same wording, same colour,
            // same two controls in the same order (owner, 2026-08-25: *"it
            // should just look exactly like the example from profile page"*).
            //
            // ⚠️ That RETIRES two earlier decisions on this page, deliberately,
            // so neither gets "restored" by someone reading the old note: the
            // count was brass `accent` and read "N TOURS AVAILABLE" (kept as a
            // divergence on 2026-08-18 because the count is why a place page
            // exists), and the order was STATED as "NEWEST FIRST" rather than
            // offered. The count is quiet `tertiaryText` now, and the order is
            // a real control.
            HStack(spacing: AtlasSpacing.md) {
                Text(tourCountText)
                    .font(AtlasTypography.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.tertiaryText)
                Spacer()
                AtlasLayoutToggle(selection: $layout)
                AtlasSortMenu(criterion: $sortCriterion, ascending: $sortAscending)
            }
            .padding(.horizontal, AtlasSpacing.lg)

            switch layout {
            case .list: tourList
            case .grid: tourGrid
            }
        }
    }

    private var tourList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(tours) { tour in
                Button {
                    tourPresenter.present(tour)
                } label: {
                    PlaceTourRow(tour: tour, maker: dataService.maker(for: tour))
                }
                .buttonStyle(.plain)

                if tour.id != tours.last?.id {
                    Divider().padding(.leading, AtlasSpacing.lg)
                }
            }
        }
    }

    /// The same three-across square photo grid the maker page draws, from the
    /// shared `AtlasTourGrid` geometry so the two can't disagree about tile
    /// size or gutter. Unlike the rows it is inset by `lg`, because a grid has
    /// no internal padding to run its edges out to.
    private var tourGrid: some View {
        let side = AtlasTourGrid.side(forContentWidth: gridContentWidth)
        return LazyVGrid(columns: AtlasTourGrid.columns, spacing: AtlasTourGrid.spacing) {
            ForEach(tours) { tour in
                Button {
                    tourPresenter.present(tour)
                } label: {
                    HeroImageView(
                        imageName: tour.heroImageURL,
                        height: side,
                        cornerRadius: 0,
                        category: tour.primaryCategory
                    )
                    .clipped()
                    // WALK and price share this corner as one chip row, the
                    // maker grid's arrangement — the tile carries no title, so
                    // these two are the only thing distinguishing a paid walk
                    // from a free single stop.
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: AtlasSpacing.xs) {
                            if tour.kind == .multiStop {
                                walkPill
                                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                            }
                            TourPriceBadge(tour: tour)
                        }
                        .padding(AtlasSpacing.xs)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // A tile is a photograph and nothing else, so VoiceOver has
                // no text to read unless it is given one.
                .accessibilityLabel(tour.title)
            }
        }
        // ⚠️ Measured BEFORE the inset, or the reader hands back the padded
        // width and every tile comes out 16pt too wide.
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { gridContentWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in gridContentWidth = w }
            }
        )
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// The brass WALK pill, identical to the one `PlaceTourRow` carries.
    private var walkPill: some View {
        Text("WALK")
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundStyle(AtlasColors.background)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(AtlasColors.accent, in: Capsule())
    }
}

// MARK: - One tour in the list

/// A row on the place page. Deliberately close to the maker page's tour row —
/// same WALK pill, same price badge, same mono metadata — because a user
/// scanning tours should not have to learn a second row format. **Not** shaped
/// like tour detail's stop row: these are whole tours, not stops.
private struct PlaceTourRow: View {
    let tour: Tour
    let maker: Maker?

    var body: some View {
        HStack(spacing: AtlasSpacing.sm) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 56,
                cornerRadius: AtlasSpacing.xs,
                category: tour.primaryCategory
            )
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(tour.title.uppercased())
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)

                // 🔴 Badges sit BELOW the metadata, not above the title — owner
                // decision 2026-08-25. Above the title they took a line of their
                // own, so a walk with a two-line title ran to four rows with the
                // pill stranded at the top, furthest from the information it
                // qualifies. A fourth row is fine; the pill being adrift was not.
                //
                // ⚠️ `PlaceView` and `TourListDetailView` carry this row
                // byte-identically by design. Change one and change the other.
                HStack(spacing: AtlasSpacing.xs) {
                    if tour.kind == .multiStop {
                        Text("WALK")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(AtlasColors.background)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(AtlasColors.accent, in: Capsule())
                    }
                    TourPriceBadge(tour: tour)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
        .padding(.horizontal, AtlasSpacing.lg)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        var parts: [String] = []
        if let maker { parts.append(maker.displayName) }
        if tour.kind == .multiStop {
            parts.append("\(tour.stops.count) stops")
        }
        parts.append(AtlasFormatters.duration(seconds: tour.totalDurationSeconds))
        return parts.joined(separator: " · ")
    }
}

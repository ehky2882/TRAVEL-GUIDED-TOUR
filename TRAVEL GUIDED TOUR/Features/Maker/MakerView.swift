import SwiftUI

/// Sort criteria for a maker's tour list. All reversible — the menu
/// shows a direction-specific label so the active sort reads in plain
/// words ("A–Z" / "Z–A", "Newest" / "Oldest", …). The page opens on
/// Date added → Newest (see the `@AppStorage` default).
private enum MakerSortCriterion: String, CaseIterable, Identifiable {
    case name, duration, distance, dateAdded

    var id: String { rawValue }

    /// The direction a criterion takes when first selected. Date added
    /// defaults to newest-first; everything else to its natural
    /// ascending form.
    var defaultAscending: Bool {
        self == .dateAdded ? false : true
    }

    /// Direction-aware label (their vocabulary, not "ascending").
    func label(ascending: Bool) -> String {
        switch self {
        case .name:      return ascending ? "A–Z" : "Z–A"
        case .duration:  return ascending ? "Shortest" : "Longest"
        case .distance:  return ascending ? "Nearest" : "Farthest"
        case .dateAdded: return ascending ? "Oldest" : "Newest"
        }
    }
}

/// List vs. Instagram-style grid presentation of a maker's tours.
/// `String`-backed so it can persist via `@AppStorage`.
private enum MakerListLayout: String {
    case list, grid
}

/// How a `MakerView` is being shown.
///
/// A maker page and the signed-in user's own profile are the SAME
/// screen (owner direction, 2026-07-01: "each maker should be thought
/// of like a user too"). The mode only toggles the chrome around the
/// shared header + tour feed:
///  • `.publicMaker` — someone else's page (default; unchanged): a
///    bookmark + a `…` overflow menu (Share / Follow / Report), and it
///    registers as a pushed detail (`navState.push()`).
///  • `.ownProfile` — the Me tab's own profile: a gear that opens
///    Settings, and a `+` add-a-tour affordance in the feed. It's a
///    TAB ROOT, so it does NOT register as a pushed detail.
enum MakerViewMode {
    case publicMaker
    case ownProfile
}

/// Maker page — spec § Key screens #5 / roadmap M-maker.
///
/// Replaces the stub that landed in M-tour-detail. Shows the maker's
/// avatar, display name, bio, optional website link, and the full
/// list of their tours. Each tour row pushes `TourDetailView` onto
/// the navigation stack.
///
/// Also serves as the signed-in user's own profile (the Me tab) via
/// `mode: .ownProfile` — see `MakerViewMode`.
struct MakerView: View {
    let maker: Maker
    /// Public maker page vs. the user's own profile. Defaults to
    /// `.publicMaker` so every existing call site is unchanged.
    var mode: MakerViewMode = .publicMaker

    @Environment(DataService.self) private var dataService
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(SavedMakersStore.self) private var savedMakersStore
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(LocationManager.self) private var locationManager
    // Optional: the public maker page can be reached via the
    // UIKit-backed tour-detail layer, whose environment does NOT inject
    // AuthService — a required lookup would crash there (same class of
    // bug as the old ReportSheet crash). Only `.ownProfile` (a tab root
    // that always carries the app environment) reads it.
    @Environment(AuthService.self) private var authService: AuthService?

    private let avatarSize: CGFloat = 96

    /// Current sort of the maker's tour list. Persisted across visits +
    /// launches (shared by all maker pages). Opens on Date added →
    /// Newest by default.
    @AppStorage("makerSortCriterion") private var sortCriterion: MakerSortCriterion = .dateAdded
    @AppStorage("makerSortAscending") private var sortAscending: Bool = false

    /// List vs grid presentation; persisted like the sort.
    @AppStorage("makerListLayout") private var layout: MakerListLayout = .list
    /// Measured width of the grid container — drives square tile sizing.
    @State private var gridContentWidth: CGFloat = 0
    @State private var showingReport = false
    /// Own-profile only: Settings sheet (behind the gear) + the
    /// create-a-tour placeholder (behind the `+`).
    @State private var showingSettings = false
    @State private var showingCreate = false

    private var isSaved: Bool { savedMakersStore.isSaved(maker.id) }
    private var isOwnProfile: Bool { mode == .ownProfile }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                header
                    .frame(maxWidth: .infinity)
                    .padding(.top, AtlasSpacing.lg)

                if let urlString = maker.websiteURL,
                   let url = URL(string: urlString) {
                    websiteLink(url: url)
                }

                toursSection
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.bottom, AtlasSpacing.xl)
        }
        // `secondaryBackground` (a fixed RGB, not the level-sensitive
        // `.systemBackground`) so the page reads as the SAME shade as
        // the bottom module + the tour-detail body regardless of how
        // MakerView is reached. Via the tour-detail sheet (elevated
        // userInterfaceLevel) `.systemBackground` resolved to #1C1C1E
        // and happened to match; pushed from Search (base level) it
        // fell to pure black and mismatched the module. Matches the
        // token TourDetailView / ManageDownloadsView already use.
        .background(AtlasColors.secondaryBackground)
        .sheet(isPresented: $showingReport) {
            ReportSheet(target: .maker(maker))
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingCreate) {
            CreateTourPlaceholderView()
        }
        // No visible nav-bar title (owner direction): the masthead
        // already shows the maker name. Empty string keeps the bar +
        // back button while dropping the centered title text. The
        // `navigationTitle` accessibility identity moves to the
        // masthead name in the body.
        .navigationTitle("")
        .inlineNavigationBarTitle()
        // Trailing nav-bar controls.
        //  • Own profile: a gear that opens Settings (Settings moved
        //    inside the profile — owner direction, 2026-07-01).
        //  • Public maker: a bookmark (save this maker) + a `…` overflow
        //    menu (Save · Share · Follow [disabled] · Report), mirroring
        //    the tour-detail sheet.
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isOwnProfile {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                } else {
                    Button {
                        savedMakersStore.toggleSaved(maker.id)
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    }
                    .accessibilityLabel(isSaved
                        ? "Remove \(maker.displayName) from saved"
                        : "Save \(maker.displayName)")

                    overflowMenu
                }
            }
        }
        // Reserve room at the bottom for the mini-player + tab bar
        // stack so the last tour row is reachable above the module.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        // Public maker pages register as a pushed detail so the bottom
        // module switches to full-edge while they're on top — even when
        // reached from Home. The own profile is a TAB ROOT (the Me tab),
        // whose full-edge geometry already comes from `selectedTab != .home`,
        // so it must NOT push (that would leak into the Home drawer's
        // isShowingDetail logic).
        .onAppear { if !isOwnProfile { navState.push() } }
        .onDisappear { if !isOwnProfile { navState.pop() } }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: AtlasSpacing.md) {
            avatar

            Text(maker.displayName)
                .font(AtlasTypography.caption)
                .textCase(.uppercase)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.center)

            Text(maker.bio)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var avatar: some View {
        Group {
            if let emoji = maker.avatarEmoji, !emoji.isEmpty {
                // Single-glyph brand mark (e.g. the Atlas Studio NYC
                // red apple) rendered inside a muted circular plate.
                // MiniPlayerBar.authorIcon uses the same resolution
                // order at a smaller frame.
                ZStack {
                    Circle().fill(AtlasColors.placeholderWarm)
                    Text(emoji)
                        .font(.system(size: avatarSize * 0.6))
                }
            } else if let urlString = maker.avatarURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Circle().fill(AtlasColors.placeholderWarm)
                    }
                }
            } else {
                // No remote avatar or emoji — fall back to the bundled
                // Atlas Studio brand asset.
                Image("AtlasStudioAvatar")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
    }

    private func websiteLink(url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "link")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.secondaryText)
                Text(url.host ?? url.absoluteString)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.horizontal, AtlasSpacing.md)
            .padding(.vertical, AtlasSpacing.sm)
            .background(AtlasColors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                    .stroke(AtlasColors.secondaryText.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
        }
        .accessibilityLabel("Open \(maker.displayName) website")
    }

    private var toursSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HStack(spacing: AtlasSpacing.md) {
                Text(tourCountText)
                    .font(AtlasTypography.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.tertiaryText)
                Spacer()
                layoutToggle
                sortMenu
            }
            .padding(.top, AtlasSpacing.md)

            // Own profile always shows the feed so the `+` add-a-tour
            // affordance is present even with zero tours. Public pages
            // keep the plain "No tours yet." empty state.
            if makerTours.isEmpty && !isOwnProfile {
                Text("No tours yet.")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .padding(.vertical, AtlasSpacing.md)
            } else if layout == .grid {
                toursGrid
            } else {
                toursList
            }
        }
    }

    /// Wraps a tour's tappable content with the correct open behavior.
    /// Opening depends on how MakerView itself was reached:
    ///  • Top-level push (Library / Search / Home) — no detail layer is
    ///    up, so present the tour via the shared `tourPresenter`
    ///    slide-up layer (same as every other tour list); the sheet's X
    ///    close — wired to `tourPresenter.dismiss()` — then works.
    ///  • Already inside a detail layer (reached via a tour sheet →
    ///    "Go to creator") — push within that layer's own nav stack so
    ///    we don't double-stack a second layer; X still dismisses it.
    @ViewBuilder
    private func tourOpen<Label: View>(_ tour: Tour, @ViewBuilder label: () -> Label) -> some View {
        if tourPresenter.presentedTour == nil {
            Button { tourPresenter.present(tour) } label: { label() }
                .buttonStyle(.plain)
        } else {
            NavigationLink { TourDetailView(tour: tour) } label: { label() }
                .buttonStyle(.plain)
        }
    }

    private var toursList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if isOwnProfile {
                addTourRow
                if !makerTours.isEmpty { Divider() }
            }

            ForEach(makerTours) { tour in
                tourOpen(tour) { tourRow(tour) }

                if tour.id != makerTours.last?.id {
                    Divider()
                }
            }
        }
    }

    /// Own-profile "+" row that starts a new tour. Mirrors `tourRow`'s
    /// layout (square 64pt leading tile) so it sits flush with the feed.
    private var addTourRow: some View {
        Button {
            showingCreate = true
        } label: {
            HStack(alignment: .center, spacing: AtlasSpacing.md) {
                ZStack {
                    Rectangle()
                        .fill(AtlasColors.placeholderWarm.opacity(0.35))
                    Image(systemName: "plus")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                .frame(width: 64, height: 64)

                Text("ADD A TOUR")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add a tour")
    }

    /// Own-profile "+" grid tile — a square dashed cell that starts a
    /// new tour, sized to match the photo tiles beside it.
    private func addTourTile(side: CGFloat) -> some View {
        Button {
            showingCreate = true
        } label: {
            ZStack {
                Rectangle()
                    .fill(AtlasColors.placeholderWarm.opacity(0.35))
                Image(systemName: "plus")
                    .font(.system(size: max(18, side * 0.28)))
                    .foregroundStyle(AtlasColors.secondaryText)
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add a tour")
    }

    /// Instagram-style 3-column square photo grid (image only). Shows
    /// the same sorted `makerTours`; tap a tile to open the tour. Tile
    /// side is derived from the measured grid width so tiles stay
    /// square at any device size.
    private var toursGrid: some View {
        let spacing: CGFloat = 2
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3)
        let side = max(0, (gridContentWidth - spacing * 2) / 3)
        return LazyVGrid(columns: columns, spacing: spacing) {
            if isOwnProfile {
                addTourTile(side: side)
            }
            ForEach(makerTours) { tour in
                tourOpen(tour) {
                    HeroImageView(
                        imageName: tour.heroImageURL,
                        height: side,
                        cornerRadius: 0,
                        category: tour.primaryCategory
                    )
                    .clipped()
                    .contentShape(Rectangle())
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { gridContentWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in gridContentWidth = w }
            }
        )
    }

    /// List / grid presentation toggle.
    private var layoutToggle: some View {
        HStack(spacing: AtlasSpacing.sm) {
            layoutToggleIcon("list.bullet", target: .list)
            layoutToggleIcon("square.grid.3x3", target: .grid)
        }
    }

    private func layoutToggleIcon(_ systemName: String, target: MakerListLayout) -> some View {
        Button { layout = target } label: {
            Image(systemName: systemName)
                .font(AtlasTypography.caption)
                .foregroundStyle(layout == target ? AtlasColors.primaryText : AtlasColors.tertiaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(target == .grid ? "Grid view" : "List view")
    }

    /// Pull-down sort control. Each criterion is one row; the active
    /// one carries an up/down chevron and a direction-aware label.
    /// Tapping the active criterion flips its direction; tapping
    /// another selects it at its default direction.
    private var sortMenu: some View {
        Menu {
            ForEach(MakerSortCriterion.allCases) { criterion in
                Button {
                    if criterion == sortCriterion {
                        sortAscending.toggle()
                    } else {
                        sortCriterion = criterion
                        sortAscending = criterion.defaultAscending
                    }
                } label: {
                    sortMenuRowLabel(criterion)
                }
            }
        } label: {
            HStack(spacing: AtlasSpacing.xs) {
                Image(systemName: "arrow.up.arrow.down")
                Text(activeSortLabel)
            }
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
        }
        .accessibilityLabel("Sort tours, currently \(activeSortLabel)")
    }

    /// The active criterion shows its current direction + a chevron;
    /// inactive ones show their default-direction label.
    @ViewBuilder
    private func sortMenuRowLabel(_ criterion: MakerSortCriterion) -> some View {
        if criterion == sortCriterion {
            Label(
                criterion.label(ascending: sortAscending),
                systemImage: sortAscending ? "chevron.up" : "chevron.down"
            )
        } else {
            Text(criterion.label(ascending: criterion.defaultAscending))
        }
    }

    private var activeSortLabel: String {
        sortCriterion.label(ascending: sortAscending)
    }

    private func tourRow(_ tour: Tour) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            // Square corners per the app-wide "all images square
            // corners" rule (owner, 2026-06-04) — matches the Search
            // result rows.
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 64,
                cornerRadius: 0,
                category: tour.primaryCategory
            )
            .frame(width: 64)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                // Title: BODY, all-caps, single line, tail-truncated —
                // mirrors the Search result rows / Player stop titles.
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Subtitle: duration, then distance-away when there's a
                // location fix (e.g. "2m 15s · 1.2 mi away"); duration
                // only otherwise. One line.
                Text(subtitleText(tour))
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

    // MARK: - Nav-bar overflow

    /// Top-trailing `…` overflow menu — mirrors the tour-detail sheet's
    /// menu, minus the tour-only items (Download / Go to creator).
    /// Order: Save · Share · Follow [disabled] · Report a concern.
    private var overflowMenu: some View {
        Menu {
            Button {
                savedMakersStore.toggleSaved(maker.id)
            } label: {
                Label(
                    isSaved ? "Remove from saved" : "Save",
                    systemImage: isSaved ? "bookmark.fill" : "bookmark"
                )
            }

            // Single link bubble in Messages (no separate text bubble) — the
            // card's title/image come from the landing page's Open Graph tags.
            ShareLink(
                item: AtlasShareLink.makerURL(for: maker),
                subject: Text(maker.displayName)
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Section {
                // Disabled in V1 — the follow graph (a social feature)
                // isn't built. Saving (above) is a separate local
                // bookmark, not a follow. Kept visible to surface the
                // upcoming feature, matching the tour-detail menu.
                Button {} label: {
                    Label("Follow creator", systemImage: "person.badge.plus")
                }
                .disabled(true)
            }

            Section {
                Button(role: .destructive) {
                    showingReport = true
                } label: {
                    Label("Report a concern", systemImage: "exclamationmark.bubble")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .accessibilityLabel("More options")
        }
    }


    // MARK: - Derived

    private var makerTours: [Tour] {
        let tours = dataService.tours(by: maker)
        let asc = sortAscending
        switch sortCriterion {
        case .name:
            return tours.sorted { Self.compareName($0, $1, ascending: asc) }
        case .duration:
            return tours.sorted {
                asc
                    ? $0.totalDurationSeconds < $1.totalDurationSeconds
                    : $0.totalDurationSeconds > $1.totalDurationSeconds
            }
        case .distance:
            // No location yet → leave catalog order rather than a
            // meaningless one.
            guard let location = locationManager.userLocation else { return tours }
            return tours.sorted {
                let d0 = $0.distance(from: location)
                let d1 = $1.distance(from: location)
                return asc ? d0 < d1 : d0 > d1
            }
        case .dateAdded:
            return tours.sorted { Self.compareCreatedAt($0, $1, ascending: asc) }
        }
    }

    /// Title compare, direction-aware.
    private nonisolated static func compareName(_ lhs: Tour, _ rhs: Tour, ascending: Bool) -> Bool {
        let cmp = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        return ascending ? cmp == .orderedAscending : cmp == .orderedDescending
    }

    /// `createdAt` compare, direction-aware. Tours without a date sort
    /// LAST in both directions. ISO "YYYY-MM-DD" strings compare
    /// chronologically as plain strings.
    private nonisolated static func compareCreatedAt(_ lhs: Tour, _ rhs: Tour, ascending: Bool) -> Bool {
        switch (lhs.createdAt, rhs.createdAt) {
        case let (l?, r?): return ascending ? l < r : l > r
        case (_?, nil):    return true   // dated before undated, always
        case (nil, _?):    return false
        case (nil, nil):   return false
        }
    }

    /// Subtitle: duration, plus "· N away" when a location fix exists
    /// (e.g. "2m 15s · 1.2 mi away"); duration only otherwise.
    private func subtitleText(_ tour: Tour) -> String {
        let duration = formattedDuration(tour.totalDurationSeconds)
        guard let location = locationManager.userLocation else { return duration }
        let distance = AtlasFormatters.distanceAway(meters: tour.distance(from: location))
        return "\(duration) · \(distance)"
    }

    private var tourCountText: String {
        let count = dataService.tours(by: maker).count
        return count == 1 ? "1 tour" : "\(count) tours"
    }

    private func formattedDuration(_ seconds: Int) -> String {
        AtlasFormatters.duration(seconds: seconds)
    }
}

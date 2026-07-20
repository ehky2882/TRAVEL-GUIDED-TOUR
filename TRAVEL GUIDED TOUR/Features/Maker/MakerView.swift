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
///  • `.publicMaker` — someone else's page, **pushed** onto an existing
///    nav stack (e.g. a tour's "Go to creator", back returns to the
///    tour): a bookmark + a `…` overflow menu (Share / Follow / Report),
///    a back chevron for close, registers as a pushed detail.
///  • `.publicStandalone` — someone else's page presented as **its own
///    top-level screen** via `MakerPresenter` (a shared deep link, a
///    Search result, a saved-maker row) — the same UIKit slide-up
///    treatment tours get. Same trailing controls as `.publicMaker`,
///    but with an **X** close (no back stack to pop to).
///  • `.ownProfile` — the Me tab's own profile: a gear that opens
///    Settings, and a `+` add-a-tour affordance in the feed. It's a
///    TAB ROOT, so it does NOT register as a pushed detail.
enum MakerViewMode {
    case publicMaker
    case publicStandalone
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
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(LocationManager.self) private var locationManager
    // Optional: the public maker page can be reached via the
    // UIKit-backed tour-detail layer, whose environment does NOT inject
    // AuthService — a required lookup would crash there (same class of
    // bug as the old ReportSheet crash). Only `.ownProfile` (a tab root
    // that always carries the app environment) reads it.
    @Environment(AuthService.self) private var authService: AuthService?
    // Optional for the same reason: only `.publicStandalone` (presented
    // via the bottom layer, which injects it explicitly) uses this — for
    // its X close. Pushed / own-profile contexts don't.
    @Environment(MakerPresenter.self) private var makerPresenter: MakerPresenter?
    // Optional: only `.ownProfile` (the Me tab, which carries it via the
    // ContentView environment) uses these — to edit/create the profile and to
    // show the user's own tours (all statuses, incl. drafts).
    @Environment(MakerProfileService.self) private var makerProfileService: MakerProfileService?
    @Environment(MakerTourService.self) private var makerTourService: MakerTourService?
    @Environment(FollowService.self) private var followService: FollowService?
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?
    // Optional: only `.ownProfile` (the Me tab, which carries it via the
    // ContentView environment) uses this — to enter the user's Journeys.
    @Environment(JourneyService.self) private var journeyService: JourneyService?

    /// Follower/following counts + this viewer's relationship to the maker.
    /// Loaded on appear; refreshed after a follow/unfollow.
    @State private var followState: FollowState = .empty
    @State private var isTogglingFollow = false

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
    /// create-a-tour placeholder (behind the `+`) + the profile editor
    /// (behind "Edit Profile").
    @State private var showingSettings = false
    @State private var showingCreate = false
    @State private var showingEditProfile = false
    /// Set when a new draft is created, to push its editor (step 2) as the
    /// create sheet dismisses. `pendingDraftId` holds the id until the sheet is
    /// fully gone, then `draftToEdit` fires the push (avoids a dismiss↔push race).
    @State private var draftToEdit: EditingDraft?
    @State private var pendingDraftId: UUID?

    private var isOwnProfile: Bool { mode == .ownProfile }
    private var isStandalone: Bool { mode == .publicStandalone }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                header
                    .frame(maxWidth: .infinity)
                    .padding(.top, AtlasSpacing.lg)

                if isOwnProfile && journeyService != nil {
                    journeysSection
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
            CreateTourView { newId in
                pendingDraftId = newId
            }
        }
        // Once the create sheet is fully dismissed, push the new draft's editor
        // (step 2) so "Save draft & continue" lands there instead of the profile.
        .onChange(of: showingCreate) { _, showing in
            if !showing, let id = pendingDraftId {
                pendingDraftId = nil
                draftToEdit = EditingDraft(id: id)
            }
        }
        .navigationDestination(item: $draftToEdit) { draft in
            TourAuthoringView(tourId: draft.id)
        }
        .sheet(isPresented: $showingEditProfile) {
            ProfileEditorView(currentMaker: maker)
        }
        // No visible nav-bar title (owner direction): the masthead
        // already shows the maker name. Empty string keeps the bar +
        // back button while dropping the centered title text. The
        // `navigationTitle` accessibility identity moves to the
        // masthead name in the body.
        .navigationTitle("")
        .inlineNavigationBarTitle()
        // Nav-bar controls.
        //  • Leading: an X close, only when presented standalone (via
        //    MakerPresenter) — there's no back stack to pop to. Pushed
        //    pages keep the system back chevron.
        //  • Trailing — own profile: a gear that opens Settings (Settings
        //    moved inside the profile, owner direction 2026-07-01).
        //    Public (pushed or standalone): a `…` overflow menu (Share ·
        //    Follow · Report), mirroring the tour-detail sheet. Follow is
        //    the single way to keep track of a maker (owner direction
        //    2026-07-19: the old bookmark/save-maker was redundant with
        //    Follow and has been removed).
        .toolbar {
            if isStandalone {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        makerPresenter?.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isOwnProfile {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                } else {
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

            // Display name — preserve the maker's own casing (no forced
            // ALL CAPS; owner direction 2026-07-03).
            Text(maker.displayName)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.center)

            if !maker.bio.isEmpty {
                Text(maker.bio)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Up to 3 profile links as inline blue link text under the bio
            // (not boxes). Owner direction 2026-07-03: "Allow up to 3 links."
            ForEach(maker.links, id: \.self) { urlString in
                if let url = URL(string: urlString) {
                    Link(destination: url) {
                        Text(displayLink(url))
                            .font(AtlasTypography.caption)
                            .foregroundStyle(Color.blue)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityLabel("Open \(maker.displayName) link \(displayLink(url))")
                }
            }

            followCounts

            if isOwnProfile {
                editProfileButton
            } else {
                followButton
            }
        }
        .task(id: maker.id) {
            guard let followService else { return }
            // Stale-while-revalidate: show the last-known counts instantly (no
            // 0/blank flash on open — most visible on the Me tab), then refresh.
            // `state(for:)` returns the cached value on failure, so a transient
            // network blip never clobbers good counts back to zero.
            followState = followService.cachedState(for: maker.id)
            followState = await followService.state(for: maker.id)
            // On the own profile, this refresh is the freshest read of the
            // pending set — keep the Me-tab notification badge in sync with it.
            if isOwnProfile {
                await followService.refreshOwnPendingRequests(ownMakerId: maker.id)
            }
        }
    }

    /// Follower + Following counts — each taps through to the list screen
    /// (`FollowListView`, batch D2). On the own profile a pending follow
    /// request surfaces as a small gold heart badge over the followers count;
    /// tapping the followers count opens the unified list with the requests
    /// pinned at the top (there's no separate requests page).
    private var followCounts: some View {
        HStack(spacing: AtlasSpacing.lg) {
            followersLink
            countLink(followState.following, "following", .following)
        }
        .padding(.top, AtlasSpacing.xs)
    }

    /// Followers count. On the own profile it links to the unified list
    /// (requests pinned on top) and carries the pending-request heart badge.
    private var followersLink: some View {
        NavigationLink {
            FollowListView(
                makerId: maker.id,
                kind: .followers,
                showsPendingRequests: isOwnProfile,
                onRequestsChange: {
                    Task {
                        if let followService {
                            followState = await followService.state(for: maker.id)
                            await followService.refreshOwnPendingRequests(ownMakerId: maker.id)
                        }
                    }
                }
            )
        } label: {
            countPill(followState.followers, "followers")
                .overlay(alignment: .topTrailing) {
                    if isOwnProfile && followState.pendingRequests > 0 {
                        pendingRequestBadge
                    }
                }
        }
        .buttonStyle(.plain)
    }

    /// Decorative gold heart badge reminding the user of pending follow
    /// requests. The whole followers count is the tap target (it opens the
    /// list where the requests are actioned), so the badge itself isn't a
    /// separate button.
    private var pendingRequestBadge: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(AtlasColors.background)
            .frame(width: 18, height: 18)
            .background(AtlasColors.mapPin, in: Circle())
            .overlay(Circle().stroke(AtlasColors.background, lineWidth: 1.5))
            .offset(x: 10, y: -10)
            .accessibilityLabel(followState.pendingRequests == 1
                                ? "1 pending follow request"
                                : "\(followState.pendingRequests) pending follow requests")
    }

    private func countLink(_ n: Int, _ label: String, _ kind: FollowListView.Kind) -> some View {
        NavigationLink {
            FollowListView(makerId: maker.id, kind: kind)
        } label: {
            countPill(n, label)
        }
        .buttonStyle(.plain)
    }

    private func countPill(_ n: Int, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text("\(n)")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
            Text(label)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
    }

    /// Follow / Following / Requested. Shown on other people's pages when signed
    /// in (following needs an account). Private makers turn a follow into a
    /// pending request — the label reflects that.
    @ViewBuilder
    private var followButton: some View {
        if authService?.isSignedIn == true {
            Button { toggleFollow() } label: {
                Text(followLabel)
                    .font(AtlasTypography.caption)
                    .padding(.horizontal, AtlasSpacing.lg)
                    .frame(height: 44)
                    .background(followState.isFollowing || followState.isPending
                                ? Color.clear : AtlasColors.mapPin)
                    .foregroundStyle(followState.isFollowing || followState.isPending
                                     ? AtlasColors.primaryText : AtlasColors.background)
                    .overlay(
                        Capsule().stroke(AtlasColors.secondaryText.opacity(0.4),
                                         lineWidth: followState.isFollowing || followState.isPending ? 1 : 0)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isTogglingFollow)
            .padding(.top, AtlasSpacing.xs)
        }
    }

    private var followLabel: String {
        if followState.isFollowing { return "Following" }
        if followState.isPending { return "Requested" }
        return "Follow"
    }

    private func toggleFollow() {
        guard let followService else { return }
        AtlasHaptics.selection()   // immediate tap feedback (before the network round-trip)
        isTogglingFollow = true
        Task {
            defer { isTogglingFollow = false }
            do {
                if followState.isFollowing || followState.isPending {
                    try await followService.unfollow(maker.id)
                } else {
                    try await followService.follow(maker.id)
                }
                followState = await followService.state(for: maker.id)
            } catch {
                // Leave the current state; a transient failure shouldn't lie —
                // but tell the user it didn't take.
                toastCenter?.show("Couldn't update follow. Check your connection.")
            }
        }
    }

    /// Compact link label — host without the leading `www.` (falls back to the
    /// full string).
    private func displayLink(_ url: URL) -> String {
        (url.host ?? url.absoluteString).replacingOccurrences(of: "www.", with: "")
    }

    /// Own-profile "Edit Profile" pill — opens the profile editor, which
    /// creates the maker row the first time and edits it after.
    private var editProfileButton: some View {
        Button {
            showingEditProfile = true
        } label: {
            Text("Edit Profile")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .padding(.horizontal, AtlasSpacing.lg)
                .padding(.vertical, AtlasSpacing.sm)
                .overlay(
                    Capsule().stroke(AtlasColors.secondaryText.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, AtlasSpacing.xs)
    }

    private var avatar: some View {
        // Shared resolution: photo → emoji → custom initials+colour →
        // display-name monogram. See Components/MakerAvatarView.
        MakerAvatarView(maker: maker, size: avatarSize)
    }

    /// Own-profile entry into the user's Journeys (curated tour collections).
    /// A single row that pushes `JourneysListView` — the full create / view /
    /// edit surface lives there.
    private var journeysSection: some View {
        NavigationLink {
            JourneysListView()
        } label: {
            HStack(spacing: AtlasSpacing.md) {
                Image(systemName: "map")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.mapPin)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("JOURNEYS")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                    Text("Your curated tour collections")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Journeys, your curated tour collections")
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

            // Own profile always shows the feed (with the `+` add affordance).
            // A public page with no tours shows a single empty placeholder box
            // in the first slot (grid/list) instead of a "No tours yet." line.
            if layout == .grid {
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
        if isOwnProfile {
            // Own tours open the authoring EDITOR (add audio / photos /
            // transcript / submit), pushed within the Me tab's nav stack —
            // not the public read-only detail.
            NavigationLink { TourAuthoringView(tourId: tour.id) } label: { label() }
                .buttonStyle(.plain)
        } else if tourPresenter.presentedTour == nil {
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
            } else if makerTours.isEmpty {
                // Public page, no tours — a single empty placeholder row.
                emptyPlaceholderRow
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

    /// Empty placeholder row for a public maker page with no tours — a single
    /// blank square in the first slot (mirrors the list's leading thumbnail).
    private var emptyPlaceholderRow: some View {
        Rectangle()
            .fill(AtlasColors.placeholderWarm.opacity(0.35))
            .frame(width: 64, height: 64)
            .padding(.vertical, AtlasSpacing.sm)
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
            } else if makerTours.isEmpty {
                // Public page, no tours — a single empty placeholder tile.
                Rectangle()
                    .fill(AtlasColors.placeholderWarm.opacity(0.35))
                    .frame(width: side, height: side)
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
                    .overlay(alignment: .bottomLeading) {
                        if let status = status(for: tour), status.showsBadge {
                            statusBadge(status)
                                .padding(AtlasSpacing.xs)
                        }
                    }
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

                if let status = status(for: tour), status.showsBadge {
                    statusBadge(status)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
    }

    /// Small status pill for the own-profile feed (Draft / In review / Taken
    /// down). Published tours carry no badge.
    private func statusBadge(_ status: TourStatus) -> some View {
        Text(status.label.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(AtlasColors.background)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.badgeColor)
            .clipShape(Capsule())
    }

    // MARK: - Nav-bar overflow

    /// Top-trailing `…` overflow menu — mirrors the tour-detail sheet's
    /// menu, minus the tour-only items (Download / Go to creator).
    /// Order: Share · Follow · Report a concern.
    private var overflowMenu: some View {
        Menu {
            // Single link bubble in Messages (no separate text bubble) — the
            // card's title/image come from the landing page's Open Graph tags.
            ShareLink(
                item: AtlasShareLink.makerURL(for: maker),
                subject: Text(maker.displayName)
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            // Follow lives on the header button here; the menu item echoes it
            // for parity with the tour-detail / player menus (self-hides when
            // signed out).
            Section {
                FollowMenuButton(makerId: maker.id)
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

    /// The feed's source tours. Own profile shows the user's OWN tours across
    /// all statuses (drafts + in-review + published) from `MakerTourService`;
    /// public pages show the maker's published catalog tours.
    private var feedTours: [Tour] {
        if isOwnProfile {
            return makerTourService?.myTours.map(\.tour) ?? []
        }
        return dataService.tours(by: maker)
    }

    /// Status for a tour on the own-profile feed (nil on public pages / for
    /// tours not owned) — drives the badge.
    private func status(for tour: Tour) -> TourStatus? {
        guard isOwnProfile else { return nil }
        return makerTourService?.myTours.first(where: { $0.id == tour.id })?.status
    }

    private var makerTours: [Tour] {
        let tours = feedTours
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
        let count = feedTours.count
        return count == 1 ? "1 tour" : "\(count) tours"
    }

    private func formattedDuration(_ seconds: Int) -> String {
        AtlasFormatters.duration(seconds: seconds)
    }
}

/// Identifiable wrapper so a newly-created draft's id can drive
/// `navigationDestination(item:)` (UUID isn't Identifiable on its own).
private struct EditingDraft: Identifiable, Hashable {
    let id: UUID
}

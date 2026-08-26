import MapKit
import SwiftUI

/// The three views of a maker: what they made, what they collected, and
/// where in the world their work is.
///
/// Owner direction 2026-07-27, with Instagram and AllTrails as the north
/// stars — both put secondary profile content behind a tab strip under
/// the header, and AllTrails' profile carries a literal Lists tab.
///
/// **LISTS is own-profile only for now.** Showing another creator's
/// public lists needs their `auth.users` id to query `journeys`, and the
/// catalog's `get_catalog()` doesn't emit one — `Maker` has no `userId`.
/// That's a backend change, and it belongs with the visibility model
/// (shared / only-me, follower-aware) rather than ahead of it. See
/// `docs/lists-design.md`.
enum ProfileTab: String, CaseIterable, Identifiable {
    case tours = "Tours"
    case lists = "Lists"
    case map = "Map"

    var id: String { rawValue }
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
    /// Optional because this screen also renders inside the UIKit slide-up
    /// layers, which carry a narrower environment than a tab root. Only the
    /// own-profile path presents the wizard, and that path is a tab root.
    @Environment(AppSharedState.self) private var appShared: AppSharedState?
    /// The secondary window hosting the mini-player and tab bar, so the wizard
    /// can withdraw them. Optional for the same reason as `appShared`.
    @Environment(BottomModuleWindowController.self)
    private var bottomModuleWindow: BottomModuleWindowController?
    @Environment(TourPresenter.self) private var tourPresenter
    // Optional for the same reason as the services below: this page can be
    // reached from the tour-detail layer, whose environment does not inject
    // PlacePresenter — a required lookup would crash there, exactly the class
    // of bug the old ReportSheet crash was.
    @Environment(PlacePresenter.self) private var placePresenter: PlacePresenter?
    // Optional for the same reason as `placePresenter`: this page is reachable
    // from layers that don't inject every presenter.
    @Environment(TourListPresenter.self) private var listPresenter: TourListPresenter?
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
    /// Optional for the same reason as the services above — the UIKit
    /// maker layer doesn't inject them. Only `.ownProfile` reads these:
    /// `listService` for named lists, `libraryStore` for Liked (which is
    /// local, not server-backed, so it works signed out).
    @Environment(TourListService.self) private var listService: TourListService?
    @Environment(LibraryStore.self) private var libraryStore: LibraryStore?

    /// Follower/following counts + this viewer's relationship to the maker.
    /// Loaded on appear; refreshed after a follow/unfollow.
    @State private var followState: FollowState = .empty
    @State private var isTogglingFollow = false

    private let avatarSize: CGFloat = 96

    /// Current sort of the maker's tour list. Persisted across visits +
    /// launches (shared by all maker pages). Opens on Date added →
    /// Newest by default.
    @AppStorage("makerSortCriterion") private var sortCriterion: AtlasTourSort = .dateAdded
    @AppStorage("makerSortAscending") private var sortAscending: Bool = false

    /// List vs grid presentation; persisted like the sort. The key is this
    /// page's own — see `AtlasListLayout` for why it is not shared with the
    /// place page's.
    @AppStorage("makerListLayout") private var layout: AtlasListLayout = .list
    /// Measured width of the grid container — drives square tile sizing.
    @State private var gridContentWidth: CGFloat = 0
    @State private var showingReport = false
    /// Own-profile only: Settings sheet (behind the gear) + the
    /// create-a-tour placeholder (behind the `+`) + the profile editor
    /// (behind "Edit Profile").
    @State private var showingSettings = false
    @State private var showingCreate = false
    @State private var showingEditProfile = false
    /// One of the maker's own tours, opened in the wizard.
    @State private var draftToEdit: EditingDraft?
    /// Either route into the wizard — creating or editing. One value so the
    /// bottom module is withdrawn on both, and restored the moment neither is
    /// showing.
    private var isPresentingWizard: Bool { showingCreate || draftToEdit != nil }

    /// Which of TOURS / LISTS / MAP is showing.
    @State private var profileTab: ProfileTab = .tours
    /// Create-a-list sheet, reached from the LISTS tab.
    @State private var showingCreateList = false
    /// Set when a place pin is tapped on a maker page that is itself inside a
    /// detail layer — see `openPlaceFromMap`.
    @State private var placeToPush: Place?
    @State private var listToPush: TourListTarget?
    /// Another maker's visible lists. Kept here rather than in
    /// `TourListService` so they can't be mistaken for the viewer's own —
    /// they belong to whichever page is open and die with it.
    @State private var theirLists: [TourList] = []
    /// The tours this maker has saved — their Liked. Same lifetime as
    /// `theirLists`: belongs to the open page, not to the viewer.
    @State private var theirLikedTourIds: [UUID] = []

    private var isOwnProfile: Bool { mode == .ownProfile }
    private var isStandalone: Bool { mode == .publicStandalone }

    /// **Every profile gets all three tabs.** Owner direction 2026-07-27:
    /// *"an atlas studio should be treated as a regular user … we should always
    /// treat atlas studio as a regular person."*
    ///
    /// The 19 Atlas studios have no account behind them (`userId` is nil), so
    /// their LISTS tab shows an empty Liked and nothing else — structurally the
    /// same as a real creator who has saved nothing, which is the point. It
    /// fills in on its own once those accounts are backfilled; no code change.
    private var availableTabs: [ProfileTab] {
        listService == nil ? [.tours, .map] : ProfileTab.allCases
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                header
                    .frame(maxWidth: .infinity)
                    .padding(.top, AtlasSpacing.lg)
                    .padding(.horizontal, AtlasSpacing.lg)

                // The strip insets itself, so its rule lines up with the
                // rows below rather than running edge to edge (owner
                // direction on device, TestFlight 1.1 (52)).
                AtlasTabStrip(tabs: availableTabs, selection: $profileTab)

                // Each tab owns its own horizontal inset — the list rows
                // carry theirs internally (they're shared with Library,
                // which isn't pre-padded), so a blanket padding here
                // would double it to 48pt.
                tabContent
            }
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
        // The five-step create wizard. It ends on its own confirmation screen,
        // so there is nothing to push afterwards — unlike the old two-screen
        // form, which saved a draft and handed you to the editor.
        .sheet(isPresented: $showingCreate) {
            CreateTourWizardView()
        }
        // 🔴 EDITING PRESENTS FULL-SCREEN, NOT AS A SHEET — this is the fix
        // for the saved-tour watchdog hang (builds 76→88), do not "restore
        // consistency" with the create sheet above. Every crash log went
        // through `UISheetPresentationController._sheetLayoutInfoLayout:` —
        // a frame only a sheet can produce — spinning in a synchronous layout
        // oscillation during the presentation transition. Five attempts at
        // the loop's trigger failed (toolbar structure, camera writes,
        // dismiss preferences, deferred loading); removing the sheet removes
        // the machinery that loops. The old editor was never a sheet either:
        // `TourAuthoringView` was pushed. Only the create path — which never
        // hung — has ever safely lived in one.
        .fullScreenCover(item: $draftToEdit) { draft in
            CreateTourWizardView(existingTourId: draft.id)
        }
        // 🔴 THE WIZARD'S BARS ARE WITHDRAWN FROM HERE, NOT FROM INSIDE IT.
        //
        // While the wizard is up the mini-player and tab bar are hidden, which
        // buys back the 126pt they occupy — every wizard step has to fit on one
        // screen without scrolling, and those bars do nothing during authoring.
        //
        // The flag is driven by *presentation state on this view*, deliberately,
        // rather than by the wizard's own `onAppear`/`onDisappear`. This view
        // outlives the wizard by construction, so `showingCreate` and
        // `draftToEdit` always resolve back to their empty values however the
        // wizard goes away — dismissed, swiped, or torn down. A missed
        // `onDisappear` inside the wizard would leave the app with no tab bar
        // for the rest of the session, which is a failure this app has already
        // shipped three times.
        //
        // 🔴 And the window is hidden from HERE, not from an observer in
        // `ContentView`. That view is in the main window, which the wizard
        // covers completely, and SwiftUI can stop delivering updates to a
        // covered hierarchy — the same trap that made the tour layer's X and
        // the tab bar go dead. This `onChange` fires on state owned by this
        // view, at the instant it flips, while this view is still live: it
        // cannot be starved. The flag it also sets is only read as a *render*
        // dependency by `ContentView`'s inline fallback, which re-evaluates
        // whenever it is on screen.
        //
        // `initial: true` makes opening a profile restore the bars, so even a
        // stuck flag heals itself. `onDisappear` is the third backstop.
        //
        // To bring the bars back permanently, set
        // `CreateTourWizardView.hidesBottomModule` to false — nothing else
        // needs touching.
        .onChange(of: isPresentingWizard, initial: true) { _, presenting in
            let hidden = presenting && CreateTourWizardView.hidesBottomModule
            appShared?.hidesBottomModule = hidden
            bottomModuleWindow?.setHidden(hidden)
        }
        // ⚠️ Guarded, because presenting a `fullScreenCover` can itself fire
        // `onDisappear` on the view it covers — unguarded, this would put the
        // bars straight back on top of the wizard. This is only here for the
        // case where this page genuinely goes away with no wizard showing.
        .onDisappear {
            guard !isPresentingWizard else { return }
            appShared?.hidesBottomModule = false
            bottomModuleWindow?.setHidden(false)
        }
        // A place tapped on the MAP tab while this page is already inside a
        // detail layer. See `openPlaceFromMap` for why it cannot go through
        // the presenter from here.
        .navigationDestination(item: $listToPush) { target in
            TourListDetailView(target: target, onDismiss: { listToPush = nil })
        }
        .navigationDestination(item: $placeToPush) { place in
            PlaceView(place: place, onDismiss: { placeToPush = nil })
        }
        .sheet(isPresented: $showingEditProfile) {
            ProfileEditorView(currentMaker: maker)
        }
        .sheet(isPresented: $showingCreateList) {
            TourListEditorSheet()
        }
        // Named lists live in Supabase, keyed on the account, so a
        // sign-out or switch can't leave the previous user's on screen.
        // Mirrors LibraryView's load.
        // `?? nil` flattens the double optional (`authService` is itself
        // optional here) so the task identity is a plain `UUID?`.
        .task(id: authService?.userId ?? nil) {
            guard isOwnProfile else { return }
            // Concurrent, not stacked: neither query depends on the other, and
            // awaiting them in turn made the LISTS tab re-lay-out twice.
            async let mine: Void? = listService?.loadMyLists()
            async let saved: Void? = listService?.loadSavedLists()
            _ = await (mine, saved)
        }
        // Someone else's visible lists + their Liked. Keyed on the maker so
        // opening a second creator's page replaces them rather than showing
        // the first's.
        .task(id: maker.id) {
            guard !isOwnProfile, let ownerUserId = maker.userId else {
                // No account behind this maker (every Atlas studio). Their
                // LISTS tab still appears — it just holds an empty Liked.
                theirLists = []
                theirLikedTourIds = []
                return
            }
            theirLists = await listService?.publicLists(ofUser: ownerUserId) ?? []
            theirLikedTourIds = await listService?.likedTourIds(ofUser: ownerUserId) ?? []
        }
        // If the account loses access to lists mid-session (sign-out),
        // don't strand the user on a tab that no longer exists.
        .onChange(of: availableTabs) { _, tabs in
            if !tabs.contains(profileTab) { profileTab = .tours }
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

    /// The body below the tab strip.
    @ViewBuilder
    private var tabContent: some View {
        switch profileTab {
        case .tours:
            toursSection
                .padding(.horizontal, AtlasSpacing.lg)
        case .lists:
            listsSection
        case .map:
            mapSection
                .padding(.horizontal, AtlasSpacing.lg)
        }
    }

    // MARK: - Lists tab

    /// Your own lists, or someone else's visible ones.
    ///
    /// Rows come from `Features/Library/TourListRows.swift`, shared with
    /// Library so the two surfaces can't drift.
    @ViewBuilder
    private var listsSection: some View {
        if isOwnProfile {
            ownListsSection
        } else {
            theirListsSection
        }
    }

    /// Another creator's lists.
    ///
    /// **Liked leads, exactly as it does on your own profile** — owner
    /// direction 2026-07-27: *"each user should have a default 'LIKED' list,
    /// even if it's empty."* It is the one list everybody has, so a page
    /// without it reads as broken rather than as empty.
    ///
    /// **New list is absent**, and that is the only difference from your own:
    /// creating belongs to whoever owns the page.
    private var theirListsSection: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            Button {
                openList(.liked(ownerName: maker.displayName, tourIds: theirLikedTourIds))
            } label: {
                LikedListRow(
                    count: theirLikedTours.count,
                    coverImageName: theirLikedTours.first?.heroImageURL,
                    coverCategory: theirLikedTours.first?.primaryCategory
                )
            }
            .buttonStyle(.plain)

            ForEach(theirLists) { list in
                Divider().padding(.horizontal, AtlasSpacing.lg)

                Button { openList(.list(id: list.id, preloaded: list)) } label: {
                    NamedListRow(
                        list: list,
                        coverImageName: TourListCover.imageName(for: list, in: dataService),
                        coverCategory: TourListCover.category(for: list, in: dataService)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Their saved tours, resolved against the catalog. Ids that no longer
    /// match a published tour just drop out.
    private var theirLikedTours: [Tour] {
        theirLikedTourIds.compactMap { dataService.tour(by: $0) }
    }

    /// Liked first, then anything you've named. Liked is deliberately styled
    /// as just another list: it's the default one, not a special case.
    private var ownListsSection: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            NewListRow { showingCreateList = true }
            Divider().padding(.horizontal, AtlasSpacing.lg)

            Button {
                openList(.ownLiked)
            } label: {
                LikedListRow(
                    count: likedTours.count,
                    coverImageName: likedTours.first?.heroImageURL,
                    coverCategory: likedTours.first?.primaryCategory
                )
            }
            .buttonStyle(.plain)

            ForEach(myLists) { list in
                Divider().padding(.horizontal, AtlasSpacing.lg)

                Button { openList(.list(id: list.id, preloaded: list)) } label: {
                    NamedListRow(
                        list: list,
                        coverImageName: TourListCover.imageName(for: list, in: dataService),
                        coverCategory: TourListCover.category(for: list, in: dataService)
                    )
                }
                .buttonStyle(.plain)
            }

            // Lists you kept from other people. Their own section, exactly as
            // in Library — the two surfaces show the same thing and must not
            // drift. Only ever rendered in `.ownProfile`, so a saved list can
            // never surface on your public page: a visitor's view is built
            // from `publicLists(ofUser:)`, which returns only what you own.
            if !savedLists.isEmpty {
                profileListsHeader("Saved lists")

                ForEach(savedLists) { list in
                    Button { openList(.list(id: list.id, preloaded: list)) } label: {
                        SavedListRowView(
                            list: list,
                            ownerName: TourListOwner.name(of: list, in: dataService),
                            coverImageName: TourListCover.imageName(for: list, in: dataService),
                            coverCategory: TourListCover.category(for: list, in: dataService)
                        )
                    }
                    .buttonStyle(.plain)

                    if list.id != savedLists.last?.id {
                        Divider().padding(.horizontal, AtlasSpacing.lg)
                    }
                }
            }
        }
    }

    /// Other people's lists the user has saved. Empty signed out.
    private var savedLists: [TourList] {
        listService?.savedLists ?? []
    }

    /// Same caption divider Library uses between its list groups.
    private func profileListsHeader(_ title: String) -> some View {
        Text(title)
            .font(AtlasTypography.caption)
            .textCase(.uppercase)
            .foregroundStyle(AtlasColors.tertiaryText)
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
            .padding(.bottom, AtlasSpacing.sm)
    }

    // MARK: - Map tab

    /// Where this maker's tours are in the world.
    ///
    /// The camera, the "Show all" control and the stacked cards a doubled-up
    /// pin needs all live in `TourSetMap` now — shared with the list page
    /// rather than copied to it. **Read that file before changing anything
    /// here**: the stacked cards are the only way a tour under a coincident
    /// pin is reachable at all, and a second copy would drift.
    ///
    /// Treatment copied from `TourDetailView.mapContent` (owner direction):
    /// hero-sized, square corners, inset `lg` by the caller so the gutters
    /// either side stay available for scrolling the page. That inset is
    /// load-bearing — without it a drag on the map has nowhere else to land
    /// and the page can't be scrolled.
    @ViewBuilder
    private var mapSection: some View {
        TourSetMap(
            tours: makerTours,
            places: dataService.places,
            // Every tour here is this maker's, so the card names them without
            // a lookup. A list page passes a real lookup instead.
            makerForTour: { _ in maker },
            onOpenTour: openTourFromMap,
            onOpenPlace: openPlaceFromMap
        )
    }

    /// Open a place tapped on the MAP tab.
    ///
    /// 🔴 **A presenter is not enough from here, and that is the whole bug.**
    /// `PlacePresenter` only sets state; the slide-up is actually performed by
    /// an `.onChange` in `ContentView` — which lives in the MAIN window. When
    /// this maker page is itself inside a detail layer (reached from a tour's
    /// creator row, or as a standalone maker layer), that window is fully
    /// covered by a UIKit modal, and SwiftUI can stop delivering updates to a
    /// covered hierarchy: the state is written, the observer never runs, and
    /// the tap does nothing whatsoever. Reported on 1.1 (69) and again on (70)
    /// after a dropped-injection fix that was real but treated a symptom.
    ///
    /// It is the same lesson as the dead tab bar in session 74: **never put a
    /// side effect that must run in a window a modal can cover.**
    ///
    /// So this mirrors `tourOpen` exactly — presenter when this page is
    /// top-level, an in-stack push when it is already inside a layer. The push
    /// depends on no observer at all, so it cannot fail the same way.
    /// Open a list. Routed exactly like `openPlaceFromMap`, and for the same
    /// reason: the presenter only sets state, and the slide-up itself is
    /// performed by an `.onChange` in `ContentView` — which lives in the MAIN
    /// window. Whenever this page is *itself* inside a layer that window is
    /// covered, SwiftUI can stop delivering updates to it, and the row would
    /// simply do nothing. So a list slides up from a tab root and pushes
    /// in-stack from inside a layer.
    private func openList(_ target: TourListTarget) {
        if let listPresenter, tourPresenter.presentedTour == nil, !isStandalone {
            listPresenter.present(target)
        } else {
            listToPush = target
        }
    }

    private func openPlaceFromMap(_ place: Place) {
        if let placePresenter, tourPresenter.presentedTour == nil, !isStandalone {
            placePresenter.present(place)
        } else {
            placeToPush = place
        }
    }

    /// Open a tour tapped on the map, matching `tourOpen`'s routing: own
    /// tours go to the authoring editor (via the `navigationDestination` the
    /// create flow already installs), everyone else's slides up as a tour.
    private func openTourFromMap(_ tourId: UUID) {
        if isOwnProfile {
            draftToEdit = EditingDraft(id: tourId)
        } else if let tour = makerTours.first(where: { $0.id == tourId }) {
            tourPresenter.present(tour)
        }
    }

    /// Tours in Liked, newest-saved first — the same source the Liked screen
    /// (`TourListDetailView` with a `.liked` target) renders.
    private var likedTours: [Tour] {
        guard let libraryStore else { return [] }
        return libraryStore.savedEntries.compactMap { dataService.tour(by: $0.tourId) }
    }

    /// The user's named lists. Empty signed out — Liked is the only list
    /// an anonymous user has.
    private var myLists: [TourList] {
        listService?.myLists ?? []
    }

    // MARK: - Tours tab

    private var toursSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HStack(spacing: AtlasSpacing.md) {
                Text(tourCountText)
                    .font(AtlasTypography.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.tertiaryText)
                Spacer()
                AtlasLayoutToggle(selection: $layout)
                AtlasSortMenu(criterion: $sortCriterion, ascending: $sortAscending)
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
            Button { draftToEdit = EditingDraft(id: tour.id) } label: { label() }
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
        let side = AtlasTourGrid.side(forContentWidth: gridContentWidth)
        return LazyVGrid(columns: AtlasTourGrid.columns, spacing: AtlasTourGrid.spacing) {
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
                    // Multi-stop walks get the same brass WALK pill as the
                    // list rows, top-leading so it stays clear of the
                    // bottom-leading status badge. A soft shadow lifts it
                    // off busy photos. Single stops carry no pill.
                    .overlay(alignment: .topLeading) {
                        // WALK and price share this corner as one chip row.
                        // Every paid tour today IS a walk, so these two always
                        // co-occur — pairing them beats letting a price badge
                        // land on top of the pill.
                        HStack(spacing: AtlasSpacing.xs) {
                            if tour.kind == .multiStop {
                                walkPill
                                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                            }
                            TourPriceBadge(tour: tour)
                        }
                        .padding(AtlasSpacing.xs)
                    }
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

                // Subtitle: for a multi-stop walk, a brass WALK pill +
                // leading stop count distinguish it from a single stop at
                // a glance (owner ask, 2026-07-21); then duration, then
                // distance-away when there's a location fix
                // (e.g. "6 stops · 12m 39s · 1.2 mi away"). Single stops
                // show no pill and read "2m 15s · 1.2 mi away". One line;
                // the distance truncates off the end first, so the pill +
                // count always stay visible.
                HStack(spacing: AtlasSpacing.xs) {
                    if tour.kind == .multiStop {
                        walkPill
                    }
                    TourPriceBadge(tour: tour)
                    Text(subtitleText(tour))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

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

    /// Brass "WALK" pill shown on multi-stop tour rows — the scannable
    /// at-a-glance cue that a row is a multi-stop walk, not a single
    /// stop (owner ask, 2026-07-21). Mirrors `statusBadge`'s shape but
    /// in the brand accent so walks stand out down a long list; single
    /// stops carry no pill, so its absence reads too. Fixed-size so the
    /// adjacent subtitle text is the one that truncates.
    private var walkPill: some View {
        Text("WALK")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(AtlasColors.background)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AtlasColors.accent)
            .clipShape(Capsule())
            .fixedSize()
            .accessibilityLabel("Multi-stop walk")
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

    /// The feed in the reader's chosen order. Stable, so tours a criterion
    /// cannot separate keep catalog order rather than an arbitrary one.
    private var makerTours: [Tour] {
        AtlasTourSort.sorted(
            feedTours,
            by: sortCriterion,
            ascending: sortAscending,
            from: locationManager.userLocation
        )
    }

    /// Subtitle: duration, plus "· N away" when a location fix exists
    /// (e.g. "2m 15s · 1.2 mi away"); duration only otherwise.
    private func subtitleText(_ tour: Tour) -> String {
        var parts: [String] = []
        // Multi-stop walks lead with the stop count (the WALK pill sits
        // just before this text); single stops omit it and read exactly
        // as before.
        if tour.kind == .multiStop {
            let count = tour.stops.count
            parts.append("\(count) \(count == 1 ? "stop" : "stops")")
        }
        parts.append(formattedDuration(tour.totalDurationSeconds))
        if let location = locationManager.userLocation {
            parts.append(AtlasFormatters.distanceAway(meters: tour.distance(from: location)))
        }
        return parts.joined(separator: " · ")
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

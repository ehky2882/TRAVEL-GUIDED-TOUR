import SwiftUI

/// Library tab — spec section Flow 3: Library / roadmap M-library.
///
/// Three sections accessed via an `AtlasTabStrip` at the top:
///   - Lists (every list the user has — **Liked**, the default list, plus
///     any they named — followed by the creators they follow)
///   - Downloaded (audio cached on device — populated by M-offline)
///   - Recently played (resume listening — populated by PlayerView's
///     progress writes)
///
/// All three are backed by the existing `LibraryStore` from
/// M-data-model. Each section resolves `LibraryEntry.tourId` against
/// `DataService.tours` and renders matching tours as tappable rows
/// into `TourDetailView`.
///
/// For V1 the three sections share one row style; if the surfaces
/// diverge (e.g. Downloaded gains storage size, Recently played
/// gains progress bars), they're easy to split into their own files
/// later.
struct LibraryView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(MakerPresenter.self) private var makerPresenter
    @Environment(PlacePresenter.self) private var placePresenter
    @Environment(SavedPlacesStore.self) private var savedPlacesStore
    @Environment(FollowService.self) private var followService
    @Environment(MakerProfileService.self) private var makerProfileService
    @Environment(AuthService.self) private var authService
    /// Optional so Library still renders if the service isn't injected on some
    /// path; signed-out users have no named lists anyway.
    @Environment(TourListService.self) private var listService: TourListService?

    @State private var selectedSection: Section = .saved
    @State private var showingCreateList = false

    /// Library is the one home for everything the user has kept. **Liked is
    /// not a separate section** — it's the default list (`SaveState`) and sits
    /// in the Lists section as its first row, so every list looks like a list.
    enum Section: String, CaseIterable, Identifiable {
        case saved = "Lists"
        case downloaded = "Downloaded"
        case recentlyPlayed = "Recents"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // The strip carries its own inset hairline, so it needs
                // no padding from here and no `Divider()` beneath it.
                sectionPicker

                ScrollView {
                    sectionContent
                        .padding(.vertical, AtlasSpacing.md)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("Library")
            .inlineNavigationBarTitle()
            // ALL CAPS caption-styled inline title — replaces the
            // default nav title rendering with the editorial voice
            // carried by every other small auxiliary label on home /
            // detail. `navigationTitle("Library")` stays for VoiceOver
            // identity; this toolbar item overrides the visible label.
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("LIBRARY")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
            }
            // Reserve room at the bottom for the mini-player + tab bar
            // stack so the last list item is always reachable above the
            // module rather than hidden behind it.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
            }
            // Load the follow list on appear + whenever the account changes.
            // Library is switch-swapped (rebuilt on each tab entry), so this
            // also refreshes the list each time the tab is opened — picking up
            // follows/unfollows made on a maker page.
            .task(id: authService.userId) {
                // Three independent round-trips, run **concurrently**. Awaited
                // one after another they stacked: the follow list (which may
                // itself have to load the user's maker row first), then the
                // named lists, then the saved ones — so the tab kept
                // re-laying-out as each landed. Nothing here depends on
                // anything else here, so the tab now settles in the time of
                // the slowest single query rather than the sum of all three.
                async let following: Void = loadFollowing()
                // Named lists live in Supabase; keyed on the account so a
                // sign-out or switch can't leave the previous user's on screen.
                async let mine: Void? = listService?.loadMyLists()
                // Other people's lists you've kept. Separate query, same
                // trigger — both are account-scoped and both feed this tab.
                async let saved: Void? = listService?.loadSavedLists()
                _ = await (following, mine, saved)
            }
            .sheet(isPresented: $showingCreateList) {
                TourListEditorSheet()
            }
        }
    }

    // MARK: - Sections

    private var sectionPicker: some View {
        AtlasTabStrip(tabs: Section.allCases, selection: $selectedSection)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .saved:
            listsContent
        case .downloaded:
            tourList(tours: downloadedTours, empty: DownloadedEmptyState())
        case .recentlyPlayed:
            tourList(tours: recentlyPlayedTours, empty: RecentlyPlayedEmptyState())
        }
    }

    @ViewBuilder
    private func tourList<EmptyView: View>(tours: [Tour], empty: EmptyView) -> some View {
        if tours.isEmpty {
            empty
                .frame(maxWidth: .infinity)
                .padding(.top, AtlasSpacing.xl)
                .padding(.horizontal, AtlasSpacing.lg)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(tours) { tour in
                    Button {
                        tourPresenter.present(tour)
                    } label: {
                        LibraryTourRow(tour: tour)
                    }
                    .buttonStyle(.plain)

                    if tour.id != tours.last?.id {
                        Divider()
                            .padding(.leading, AtlasSpacing.lg)
                            .padding(.trailing, AtlasSpacing.lg)
                    }
                }
            }
        }
    }

    /// The Lists tab — every list the user has, Liked included.
    ///
    /// **Liked gets no section of its own.** It's the default list, so it's the
    /// first row of Lists and opens like any other; a list is a list. Followed
    /// creators sit below in their own section.
    // Not `@ViewBuilder`: it returns one `LazyVStack`, and dropping the
    // attribute is what lets the body bind `saved` before building it.
    private var listsContent: some View {
        // Resolved once and passed down: the Liked row reads the count, the
        // cover and the cover's category, and as a computed property that was
        // three full walks of the saved entries per body evaluation.
        let saved = savedTours

        return LazyVStack(alignment: .leading, spacing: 0) {
            librarySectionHeader("Lists")

            // Create sits at the very top — it's an action, not a list, so it
            // shouldn't be buried among them (owner direction).
            if canUseLists {
                NewListRow { showingCreateList = true }
                Divider().padding(.horizontal, AtlasSpacing.lg)
            }

            NavigationLink {
                LikedListView()
            } label: {
                LikedListRow(
                    count: saved.count,
                    coverImageName: saved.first?.heroImageURL,
                    coverCategory: saved.first?.primaryCategory
                )
            }
            .buttonStyle(.plain)

            if canUseLists {
                ForEach(myLists) { list in
                    Divider().padding(.horizontal, AtlasSpacing.lg)

                    NavigationLink {
                        TourListDetailView(listId: list.id)
                    } label: {
                        NamedListRow(
                            list: list,
                            coverImageName: TourListCover.imageName(for: list, in: dataService),
                            coverCategory: TourListCover.category(for: list, in: dataService)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Other people's lists get their own section rather than being
            // mixed in above. In a column of identical rows, "delete" and
            // "remove my save" would be one gesture apart and look the same —
            // the section is what keeps yours and theirs distinct. Following
            // already sets that precedent on this screen.
            if !savedLists.isEmpty {
                librarySectionHeader("Saved lists")
                ForEach(savedLists) { list in
                    NavigationLink {
                        TourListDetailView(listId: list.id, preloaded: list)
                    } label: {
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

            if !savedPlaces.isEmpty {
                librarySectionHeader("Places")
                ForEach(savedPlaces) { place in
                    Button {
                        placePresenter.present(place)
                    } label: {
                        placeRow(place, tours: dataService.rankedTours(at: place))
                    }
                    .buttonStyle(.plain)

                    if place.id != savedPlaces.last?.id {
                        Divider().padding(.horizontal, AtlasSpacing.lg)
                    }
                }
            }

            if !followingMakers.isEmpty {
                librarySectionHeader("Following")
                ForEach(followingMakers) { maker in
                    Button {
                        makerPresenter.present(maker)
                    } label: {
                        makerRow(maker)
                    }
                    .buttonStyle(.plain)

                    if maker.id != followingMakers.last?.id {
                        Divider().padding(.horizontal, AtlasSpacing.lg)
                    }
                }
            }
        }
    }

    /// Saved places, newest first, resolved against the catalog. A saved id
    /// whose place has since left the catalog simply drops out — the same
    /// forgiving resolution saved tours get.
    private var savedPlaces: [Place] {
        savedPlacesStore.entries.compactMap { dataService.place(by: $0.placeId) }
    }

    /// Caption all-caps section divider — matches the Search view's
    /// Makers / Tours group headers.
    private func librarySectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AtlasTypography.caption)
            .textCase(.uppercase)
            .foregroundStyle(AtlasColors.tertiaryText)
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
            .padding(.bottom, AtlasSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Followed-maker row — circular emoji avatar, BODY all-caps name,
    /// caption tour-count subtitle. Mirrors the Search makers rows.
    private func makerRow(_ maker: Maker) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            // Shared avatar (photo → emoji → custom initials+colour → monogram).
            MakerAvatarView(maker: maker, size: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(maker.displayName)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(makerTourCountText(maker))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    /// A saved place. Same 56 pt leading square + two-line stack as the maker
    /// row above, so the two groups read as one list rather than two designs.
    /// - Parameter tours: the place's ranked tours, resolved once by the
    ///   caller. Cover, category and subtitle all need them, and each used to
    ///   re-derive the list for itself.
    private func placeRow(_ place: Place, tours: [Tour]) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            HeroImageView(
                imageName: place.heroImageURL ?? tours.first?.heroImageURL ?? "",
                height: 56,
                cornerRadius: AtlasSpacing.xs,
                category: tours.first?.primaryCategory
            )
            .frame(width: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(place.name)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(placeSubtitle(place, tourCount: tours.count))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    private func placeSubtitle(_ place: Place, tourCount: Int) -> String {
        let tourWord = tourCount == 1 ? "tour" : "tours"
        return [place.city, "\(tourCount) \(tourWord)"].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: - Derived

    /// LibraryEntry rows → Tour rows. Tours that no longer exist in
    /// the catalog (e.g. removed from Tours.json) are dropped silently.
    private var savedTours: [Tour] {
        libraryStore.savedEntries.compactMap { entry in
            dataService.tour(by: entry.tourId)
        }
    }

    /// Makers the signed-in user follows — shown in the Saved tab below their
    /// saved tours (owner direction 2026-07-19: Follow replaced the old
    /// bookmark-a-maker, so the maker list here is now the follow graph, not a
    /// local bookmark store).
    ///
    /// Read synchronously from `FollowService`'s in-memory cache during `body`
    /// (rather than an async-loaded `@State`, which lands a frame after the tab
    /// re-mounts and made the Saved tab re-format on every entry). On a warm
    /// re-entry the cache is already populated, so the final layout renders on
    /// the first frame with no jitter; `loadFollowing()` refreshes it in place.
    /// Empty when signed out or before the user has a maker profile — the Saved
    /// tab then falls back to tours-only.
    private var followingMakers: [Maker] {
        guard let myMakerId = makerProfileService.myMaker?.id else { return [] }
        return followService.cachedFollowing(of: myMakerId)
    }

    /// The user's named lists. Empty signed out — Liked is the only list an
    /// anonymous user has, and it *is* this tab.
    private var myLists: [TourList] {
        listService?.myLists ?? []
    }

    /// Other people's lists the user has saved. Empty signed out — saving a
    /// list is account-backed, unlike bookmarking a tour.
    private var savedLists: [TourList] {
        listService?.savedLists ?? []
    }

    /// Named lists need an account. When the user has one the Lists section
    /// always shows — including with zero lists — so "New list" is reachable.
    private var canUseLists: Bool {
        authService.isSignedIn && listService != nil
    }


    /// Refresh the signed-in user's followed makers into the shared cache.
    /// Keyed by the user's own maker id (the follow graph resolves maker →
    /// owner), so it needs a loaded profile — the same requirement as the
    /// profile's own "Following" list. Signed out, or before a profile exists,
    /// there's nothing to refresh and the computed `followingMakers` stays empty.
    private func loadFollowing() async {
        guard authService.isSignedIn else { return }
        // Ensure the user's own maker row is loaded (it's pre-warmed at launch,
        // but Library may open before that lands or after a fresh sign-in).
        if makerProfileService.myMaker == nil {
            await makerProfileService.loadMyMaker()
        }
        guard let myMakerId = makerProfileService.myMaker?.id else { return }
        // Write-through into FollowService's cache; the computed property above
        // observes it, so the view updates in place if the list changed.
        _ = await followService.following(of: myMakerId)
    }

    private func makerTourCountText(_ maker: Maker) -> String {
        let count = dataService.tours(by: maker).count
        return count == 1 ? "1 tour" : "\(count) tours"
    }

    private var downloadedTours: [Tour] {
        libraryStore.downloadedEntries.compactMap { entry in
            dataService.tour(by: entry.tourId)
        }
    }

    private var recentlyPlayedTours: [Tour] {
        libraryStore.recentlyPlayed.compactMap { entry in
            dataService.tour(by: entry.tourId)
        }
    }

}

// MARK: - Empty states


private struct DownloadedEmptyState: View {
    var body: some View {
        EmptyStateLayout(
            icon: "arrow.down.circle",
            title: "No downloads yet",
            message: "Tap the download icon on any tour to listen offline — useful for walking tours where you might lose signal."
        )
    }
}

private struct RecentlyPlayedEmptyState: View {
    var body: some View {
        EmptyStateLayout(
            icon: "play.circle",
            title: "Nothing played yet",
            message: "Tours you start listening to will appear here so you can pick up where you left off."
        )
    }
}

/// Internal, not fileprivate: `LikedEmptyState` lives in `LikedListView.swift`
/// so the Liked list screen can show it too.
struct EmptyStateLayout: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AtlasSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
            Text(title)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            // Signed-out only (self-hiding): encourage creating an account.
            JoinDozentPrompt(showIcon: false)
        }
    }
}

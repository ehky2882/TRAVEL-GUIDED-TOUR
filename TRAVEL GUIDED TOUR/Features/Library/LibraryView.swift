import SwiftUI
import UIKit

/// Library tab — spec section Flow 3: Library / roadmap M-library.
///
/// Three sections accessed via a segmented picker at the top:
///   - Saved (bookmarked tours)
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
    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(MakerPresenter.self) private var makerPresenter
    @Environment(FollowService.self) private var followService
    @Environment(MakerProfileService.self) private var makerProfileService
    @Environment(AuthService.self) private var authService
    /// Optional so Library still renders if the service isn't injected on some
    /// path; signed-out users have no named lists anyway.
    @Environment(JourneyService.self) private var journeyService: JourneyService?

    @State private var selectedSection: Section = .saved
    @State private var showingCreateList = false

    /// Push the section picker's labels to SF Mono caption (13pt
    /// monospaced regular) — matches the editorial voice carried by
    /// every other small auxiliary label on home + detail. SwiftUI
    /// doesn't expose a font modifier on a segmented `Picker`, so we
    /// reach down to UIKit's appearance proxy. Set globally because
    /// Library is the only place a segmented control appears in the
    /// app today; if another segmented control lands later it'll
    /// inherit the same SF Mono treatment automatically.
    init() {
        let mono = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        UISegmentedControl.appearance().setTitleTextAttributes([.font: mono], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.font: mono], for: .selected)
    }

    /// "Liked" is the default list, not a separate saved-things bucket — see
    /// `SaveState`. Library is the one home for everything the user has kept:
    /// their Liked tours, their named lists, and the creators they follow.
    enum Section: String, CaseIterable, Identifiable {
        case saved = "Liked"
        case downloaded = "Downloaded"
        case recentlyPlayed = "Recents"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sectionPicker
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.vertical, AtlasSpacing.sm)

                Divider()

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
                await loadFollowing()
                // Named lists live in Supabase; keyed on the account so a
                // sign-out or switch can't leave the previous user's on screen.
                await journeyService?.loadMyJourneys()
            }
            .sheet(isPresented: $showingCreateList) {
                JourneyEditorSheet()
            }
        }
    }

    // MARK: - Sections

    private var sectionPicker: some View {
        Picker("Library section", selection: $selectedSection) {
            ForEach(Section.allCases) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .saved:
            likedContent
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
                        tourRow(tour)
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

    /// The Liked tab — the one home for everything the user has kept.
    ///
    /// The tab *is* Liked, so its tours render directly rather than behind a
    /// row (the common case — "show me what I saved" — needs no tap). Named
    /// lists and followed creators sit below. When neither exists this falls
    /// through to the plain tour list + empty state, so the anonymous and
    /// brand-new cases are unchanged.
    @ViewBuilder
    private var likedContent: some View {
        if !hasSideSections {
            tourList(tours: savedTours, empty: LikedEmptyState())
        } else {
            // Tours first — lists, then followed makers below (owner direction
            // 2026-07-03: prioritize individual tours).
            LazyVStack(alignment: .leading, spacing: 0) {
                if !savedTours.isEmpty {
                    // "Liked", not "Tours" — this section IS the Liked list's
                    // contents, and labelling it as a sibling of "Lists" made
                    // it read as though these tours belonged to no list at all.
                    librarySectionHeader("Liked")
                    ForEach(savedTours) { tour in
                        Button {
                            tourPresenter.present(tour)
                        } label: {
                            tourRow(tour)
                        }
                        .buttonStyle(.plain)

                        if tour.id != savedTours.last?.id {
                            Divider().padding(.horizontal, AtlasSpacing.lg)
                        }
                    }
                } else {
                    // Nothing liked yet, but lists or follows exist below —
                    // still say how tours get here rather than showing a
                    // headerless gap.
                    LikedEmptyState()
                        .frame(maxWidth: .infinity)
                        .padding(.top, AtlasSpacing.lg)
                        .padding(.horizontal, AtlasSpacing.lg)
                }

                if canUseLists {
                    librarySectionHeader("Lists")
                    newListRow

                    ForEach(myLists) { list in
                        Divider().padding(.horizontal, AtlasSpacing.lg)

                        NavigationLink {
                            JourneyDetailView(journeyId: list.id)
                        } label: {
                            listRow(list)
                        }
                        .buttonStyle(.plain)
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
    }

    /// Create a new list. Lives here because Library is now the single home for
    /// the user's own lists — the profile no longer carries a second door into
    /// the same thing.
    private var newListRow: some View {
        Button {
            showingCreateList = true
        } label: {
            HStack(alignment: .center, spacing: AtlasSpacing.md) {
                ZStack {
                    Rectangle()
                        .fill(AtlasColors.placeholderWarm.opacity(0.35))
                    Image(systemName: "plus")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.mapPin)
                }
                .frame(width: 56, height: 56)

                Text("New list")
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)

                Spacer()
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// A named list row — cover thumbnail (explicit, else the first tour's
    /// hero), title, tour count. Matches the maker row's 56pt metrics so the
    /// two sections below the tours read as one system.
    private func listRow(_ list: Journey) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            // Same cover treatment as the lists screen's own rows.
            Group {
                if let name = listCoverImageName(for: list) {
                    HeroImageView(
                        imageName: name,
                        height: 56,
                        cornerRadius: 0,
                        category: list.firstTourId.flatMap { dataService.tour(by: $0)?.primaryCategory }
                    )
                } else {
                    ZStack {
                        Rectangle()
                            .fill(AtlasColors.placeholderWarm.opacity(0.35))
                        Image(systemName: "map")
                            .font(AtlasTypography.body)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                }
            }
            .frame(width: 56, height: 56)
            .clipped()

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(list.title)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(list.itemCount == 1 ? "1 tour" : "\(list.itemCount) tours")
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

    private func listCoverImageName(for list: Journey) -> String? {
        if let explicit = list.coverImageURL, !explicit.isEmpty { return explicit }
        guard let firstTourId = list.firstTourId else { return nil }
        return dataService.tour(by: firstTourId)?.heroImageURL
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

    private func tourRow(_ tour: Tour) -> some View {
        HStack(alignment: .top, spacing: AtlasSpacing.md) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 64,
                cornerRadius: 0,
                category: tour.primaryCategory
            )
            .frame(width: 64)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(tour.title.uppercased())
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let maker = dataService.maker(for: tour) {
                    Text(maker.displayName)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }

                HStack(spacing: AtlasSpacing.xs) {
                    Text(formattedDuration(tour.totalDurationSeconds))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)

                    // Small download badge so users scanning Saved /
                    // Recents can see which tours are already cached
                    // for offline listening.
                    if tourDownloader.isDownloaded(tourId: tour.id) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .padding(.leading, AtlasSpacing.xs)
                            .accessibilityLabel("Downloaded for offline")
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
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
    private var myLists: [Journey] {
        journeyService?.myJourneys ?? []
    }

    /// Named lists need an account. When the user has one the Lists section
    /// always shows — including with zero lists — so "New list" is reachable.
    private var canUseLists: Bool {
        authService.isSignedIn && journeyService != nil
    }

    /// Whether anything renders below the Liked tours. Drives whether the tab
    /// shows section headers or stays a plain list.
    private var hasSideSections: Bool {
        canUseLists || !followingMakers.isEmpty
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

    private func formattedDuration(_ seconds: Int) -> String {
        AtlasFormatters.duration(seconds: seconds)
    }
}

// MARK: - Empty states

private struct LikedEmptyState: View {
    var body: some View {
        EmptyStateLayout(
            icon: "bookmark",
            title: "Nothing saved yet",
            message: "Tap the bookmark on any tour and it lands here in Liked. Sign in to sort your tours into your own lists."
        )
    }
}

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

private struct EmptyStateLayout: View {
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

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
    @Environment(SavedMakersStore.self) private var savedMakersStore

    @State private var selectedSection: Section = .saved

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

    enum Section: String, CaseIterable, Identifiable {
        case saved = "Saved"
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
            savedContent
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

    /// The Saved tab: a "Makers" section (saved makers) above the
    /// saved tours. When no makers are saved this falls through to the
    /// original tour-only list + empty state, so the common case is
    /// unchanged.
    @ViewBuilder
    private var savedContent: some View {
        if savedMakers.isEmpty {
            tourList(tours: savedTours, empty: SavedEmptyState())
        } else {
            // Tours first — saved makers live below (owner direction
            // 2026-07-03: prioritize individual tours; makers/friends will
            // also have their own home in the follow system).
            LazyVStack(alignment: .leading, spacing: 0) {
                if !savedTours.isEmpty {
                    librarySectionHeader("Tours")
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
                }

                librarySectionHeader("Makers")
                ForEach(savedMakers) { maker in
                    Button {
                        makerPresenter.present(maker)
                    } label: {
                        makerRow(maker)
                    }
                    .buttonStyle(.plain)

                    if maker.id != savedMakers.last?.id {
                        Divider().padding(.horizontal, AtlasSpacing.lg)
                    }
                }
            }
        }
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

    /// Saved-maker row — circular emoji avatar, BODY all-caps name,
    /// caption tour-count subtitle. Mirrors the Search makers rows.
    private func makerRow(_ maker: Maker) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            ZStack {
                Circle().fill(AtlasColors.placeholderWarm)
                if let emoji = maker.avatarEmoji, !emoji.isEmpty {
                    Text(emoji).font(.system(size: 28))
                } else if let urlString = maker.avatarURL,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(AtlasColors.secondaryText)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

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

    /// Saved makers, most-recently-saved first. Makers no longer in
    /// the catalog are dropped silently (mirrors `savedTours`).
    private var savedMakers: [Maker] {
        savedMakersStore.savedEntries.compactMap { entry in
            dataService.maker(by: entry.makerId)
        }
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

private struct SavedEmptyState: View {
    var body: some View {
        EmptyStateLayout(
            icon: "bookmark",
            title: "Nothing saved yet",
            message: "Tap the bookmark on any tour or maker to save it for later."
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
        }
    }
}

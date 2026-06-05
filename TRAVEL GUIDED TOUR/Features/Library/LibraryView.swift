import SwiftUI

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

    @State private var selectedSection: Section = .saved

    enum Section: String, CaseIterable, Identifiable {
        case saved = "Saved"
        case downloaded = "Downloaded"
        case recentlyPlayed = "Recently played"

        var id: String { rawValue }

        /// ALL CAPS editorial label rendered inside the chip — matches
        /// the SF Mono caption voice the home tab established (tab bar
        /// labels, "N TOURS IN VIEW" header, mini-player title).
        var displayLabel: String {
            switch self {
            case .saved: "SAVED"
            case .downloaded: "DOWNLOADED"
            case .recentlyPlayed: "RECENTLY PLAYED"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LibrarySectionChipRow(selection: $selectedSection)
                    .padding(.vertical, AtlasSpacing.lg)

                ScrollView {
                    sectionContent
                        .padding(.vertical, AtlasSpacing.md)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("Library")
            .inlineNavigationBarTitle()
            // Reserve room at the bottom for the mini-player + tab bar
            // stack so the last list item is always reachable above the
            // module rather than hidden behind it.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
            }
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .saved:
            tourList(tours: savedTours, empty: SavedEmptyState())
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
                        Divider().padding(.leading, AtlasSpacing.lg)
                    }
                }
            }
        }
    }

    private func tourRow(_ tour: Tour) -> some View {
        HStack(alignment: .top, spacing: AtlasSpacing.md) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 64,
                cornerRadius: 8,
                category: tour.primaryCategory
            )
            .frame(width: 64)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let maker = dataService.maker(for: tour) {
                    Text(maker.displayName)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }

                HStack(spacing: AtlasSpacing.xs) {
                    Text(tour.primaryCategory.displayName)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                    Text("•")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                    Text(formattedDuration(tour.totalDurationSeconds))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)

                    // Small download badge so users scanning Saved /
                    // Recently played can see which tours are already
                    // cached for offline listening.
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
                .foregroundStyle(AtlasColors.tertiaryText)
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
            message: "Tap the bookmark on any tour to save it for later."
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

// MARK: - Section chip row

/// Horizontally-scrolling chip row that picks the active Library
/// section. Modeled on `CategoryChipRow` so the two surfaces feel
/// like one design system — same 44pt capsule, same SF Mono caption,
/// same selected/unselected fill treatment.
private struct LibrarySectionChipRow: View {
    @Binding var selection: LibraryView.Section

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.sm) {
                ForEach(LibraryView.Section.allCases) { section in
                    chip(for: section)
                }
            }
            .padding(.horizontal, AtlasSpacing.md)
        }
    }

    private func chip(for section: LibraryView.Section) -> some View {
        let isSelected = selection == section
        return Button {
            selection = section
        } label: {
            Text(section.displayLabel)
                .font(AtlasTypography.caption)
                .foregroundStyle(isSelected ? AtlasColors.background : AtlasColors.primaryText)
                .padding(.horizontal, AtlasSpacing.md)
                .frame(height: AtlasSpacing.searchBarHeight)
                .background(
                    Capsule()
                        .fill(isSelected ? AtlasColors.primaryText : AtlasColors.secondaryBackground)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct EmptyStateLayout: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AtlasSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
            Text(title)
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

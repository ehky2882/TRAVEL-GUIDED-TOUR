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

    @State private var selectedSection: Section = .saved

    enum Section: String, CaseIterable, Identifiable {
        case saved = "Saved"
        case downloaded = "Downloaded"
        case recentlyPlayed = "Recently played"

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
            .background(AtlasColors.background)
            .navigationTitle("Library")
            .inlineNavigationBarTitle()
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
                    NavigationLink {
                        TourDetailView(tour: tour)
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
        let minutes = seconds / 60
        if minutes == 0 { return "\(seconds)s" }
        return "\(minutes) min"
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
            message: "Downloading tours for offline listening lands in M-offline."
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

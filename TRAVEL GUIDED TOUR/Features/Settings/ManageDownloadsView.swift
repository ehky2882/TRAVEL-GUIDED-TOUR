import SwiftUI

/// Manage Downloads — spec § M-offline "Settings includes a 'Manage
/// downloads' view for deleting cached tours and seeing storage
/// usage." Reachable from Settings; mirrors the on-disk state from
/// `TourDownloader` rather than `LibraryStore` (the two are kept in
/// sync via TourDetailView's onChange).
struct ManageDownloadsView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(TourDownloader.self) private var tourDownloader

    var body: some View {
        List {
            if downloadedTours.isEmpty {
                Section {
                    Text("No downloads yet. Tap the download button on a tour to cache it for offline listening.")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            } else {
                Section {
                    ForEach(downloadedTours) { tour in
                        rowFor(tour)
                    }
                } header: {
                    HStack {
                        Text("\(downloadedTours.count) tour\(downloadedTours.count == 1 ? "" : "s") downloaded")
                        Spacer()
                        Text(formattedTotalBytes)
                    }
                    .font(AtlasTypography.caption)
                }
            }
        }
        .navigationTitle("Manage downloads")
        .inlineNavigationBarTitle()
    }

    private func rowFor(_ tour: Tour) -> some View {
        HStack(spacing: AtlasSpacing.md) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 48,
                cornerRadius: 8,
                category: tour.primaryCategory
            )
            .frame(width: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                Text(formattedBytes(tourDownloader.diskUsage(tourId: tour.id)))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
            }

            Spacer()

            Button(role: .destructive) {
                tourDownloader.deleteDownload(tourId: tour.id)
                libraryStore.clearDownload(tour.id)
            } label: {
                Text("Delete")
                    .font(AtlasTypography.body)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, AtlasSpacing.xs)
    }

    /// Drive the list from `tourDownloader.states` (which is
    /// `@Observable`) rather than `allDownloadedTourIds()` (which scans
    /// the filesystem and isn't observed). Otherwise SwiftUI doesn't
    /// re-render when a delete happens.
    ///
    /// Sorted alphabetically by title — `tourDownloader.states` is a
    /// Dictionary, which has no defined iteration order, so without
    /// this sort the list re-ordered itself between launches (audit
    /// P3-10).
    private var downloadedTours: [Tour] {
        tourDownloader.states.compactMap { tourId, state -> Tour? in
            guard case .completed = state else { return nil }
            return dataService.tour(by: tourId)
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var formattedTotalBytes: String {
        let total = downloadedTours.reduce(Int64(0)) { sum, tour in
            sum + tourDownloader.diskUsage(tourId: tour.id)
        }
        return formattedBytes(total)
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

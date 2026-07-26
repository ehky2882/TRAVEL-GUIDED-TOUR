import SwiftUI

/// One tour row in a Library list — 64pt hero, all-caps title, maker, duration,
/// and a download badge when the audio is cached offline.
///
/// Extracted so the Library sections and the Liked list screen render tours
/// identically instead of drifting apart.
struct LibraryTourRow: View {
    let tour: Tour

    @Environment(DataService.self) private var dataService
    @Environment(TourDownloader.self) private var tourDownloader

    var body: some View {
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
                    Text(AtlasFormatters.duration(seconds: tour.totalDurationSeconds))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)

                    // Small download badge so users scanning a list can see
                    // which tours are already cached for offline listening.
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
}

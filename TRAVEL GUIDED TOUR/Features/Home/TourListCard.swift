import SwiftUI
import CoreLocation

/// Single tour card for the AllTrails-style vertical list in the
/// home screen's bottom drawer. Larger and more informative than
/// the rail carousel cards (since the drawer fits one column).
///
/// Pure presentational view — taps are handled by the parent, which
/// routes them through `TourPresenter` so the detail view always
/// comes up from the bottom as a sheet.
struct TourListCard: View {
    let tour: Tour
    let maker: Maker?
    let isDownloaded: Bool
    /// Optional distance from the user's location, formatted by the
    /// caller (e.g. "0.8 km away"). Hidden when nil.
    let distanceText: String?
    /// True when this card matches the currently-selected pin on the
    /// map; receives a subtle highlight to anchor the eye.
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            heroSection

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let maker {
                    Text("by \(maker.displayName)")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }

                metaRow
            }
            .padding(.horizontal, AtlasSpacing.sm)
            .padding(.bottom, AtlasSpacing.sm)
        }
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Subviews

    /// Hero area — a paged carousel when the tour supplies
    /// `additionalImageURLs`, otherwise a single image. No corner
    /// radius: the parent card clips, so the top corners inherit the
    /// card's outer radius and the bottom sits flush with the title.
    @ViewBuilder
    private var heroImage: some View {
        let allImages = [tour.heroImageURL] + (tour.additionalImageURLs ?? [])
        if allImages.count > 1 {
            TabView {
                ForEach(allImages, id: \.self) { url in
                    HeroImageView(
                        imageName: url,
                        height: 160,
                        cornerRadius: 0,
                        category: tour.primaryCategory
                    )
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 160)
        } else {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 160,
                cornerRadius: 0,
                category: tour.primaryCategory
            )
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            heroImage

            // Category badge top-right of hero
            HStack(spacing: AtlasSpacing.xs) {
                Image(systemName: tour.primaryCategory.iconName)
                    .font(AtlasTypography.caption)
                Text(tour.primaryCategory.displayName)
                    .font(AtlasTypography.caption)
            }
            .foregroundStyle(AtlasColors.primaryText)
            .padding(.horizontal, AtlasSpacing.sm)
            .padding(.vertical, AtlasSpacing.xs)
            .background(.regularMaterial, in: Capsule())
            .padding(AtlasSpacing.sm)
        }
    }

    private var metaRow: some View {
        HStack(spacing: AtlasSpacing.xs) {
            Image(systemName: "clock")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
            Text(formattedDuration(tour.totalDurationSeconds))
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)

            if tour.kind == .multiStop {
                Text("•")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
                Text("\(tour.stops.count) stops")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }

            if let distanceText {
                Text("•")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
                Text(distanceText)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }

            if isDownloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .padding(.leading, AtlasSpacing.xs)
                    .accessibilityLabel("Downloaded for offline")
            }
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes == 0 { return "\(seconds)s" }
        return "\(minutes) min"
    }
}

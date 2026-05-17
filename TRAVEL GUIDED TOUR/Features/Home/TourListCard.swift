import SwiftUI
import CoreLocation

/// Single tour card for the AllTrails-style vertical list in the
/// home screen's bottom drawer. Larger and more informative than
/// the rail carousel cards (since the drawer fits one column).
///
/// Pushes `TourDetailView` via NavigationLink. The host
/// ScrollViewReader uses `tour.id` as the scroll anchor — tapping a
/// map pin will scroll the drawer to the matching card.
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
        NavigationLink {
            TourDetailView(tour: tour)
        } label: {
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
            }
            .padding(.vertical, AtlasSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                    .fill(isSelected ? AtlasColors.primaryText.opacity(0.05) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                    .stroke(
                        isSelected ? AtlasColors.primaryText.opacity(0.4) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 160,
                cornerRadius: AtlasSpacing.cardCornerRadius,
                category: tour.primaryCategory
            )

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

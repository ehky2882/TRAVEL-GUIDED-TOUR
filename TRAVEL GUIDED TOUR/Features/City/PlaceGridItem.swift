import SwiftUI

struct PlaceGridItem: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            ZStack(alignment: .topTrailing) {
                HeroImageView(
                    imageName: place.thumbnailURL,
                    height: 150,
                    cornerRadius: AtlasSpacing.cardCornerRadius,
                    category: place.category
                )

                Text(place.priceIndicator.displayText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(AtlasSpacing.sm)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: place.category.iconName)
                        .font(.system(size: 8))
                    Text(place.category.displayName.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.8)
                }
                .foregroundStyle(AtlasColors.accent)

                Text(place.name)
                    .font(AtlasTypography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let neighborhood = place.neighborhood {
                    Text(neighborhood)
                        .font(.system(size: 11))
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
            }
        }
    }
}

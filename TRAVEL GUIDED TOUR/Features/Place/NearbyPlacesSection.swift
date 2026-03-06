import SwiftUI

struct NearbyPlaceCard: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HeroImageView(
                imageName: place.thumbnailURL,
                height: 110,
                cornerRadius: AtlasSpacing.cardCornerRadius,
                category: place.category
            )
            .frame(width: 170)

            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(AtlasTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: place.category.iconName)
                        .font(.system(size: 8))
                    Text(place.category.displayName)
                        .font(.system(size: 10))
                }
                .foregroundStyle(AtlasColors.tertiaryText)
            }
            .frame(width: 170, alignment: .leading)
        }
        .frame(width: 170)
    }
}

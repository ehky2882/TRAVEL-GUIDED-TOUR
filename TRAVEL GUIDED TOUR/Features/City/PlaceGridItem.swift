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
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white)
                    .clipShape(Capsule())
                    .padding(AtlasSpacing.sm)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: place.category.iconName)
                        .font(AtlasTypography.standard)
                    Text(place.category.displayName.uppercased())
                        .font(AtlasTypography.standard)
                        .tracking(0.8)
                }
                .foregroundStyle(.black)

                Text(place.name)
                    .font(AtlasTypography.callout)
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let neighborhood = place.neighborhood {
                    Text(neighborhood)
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                }
            }
        }
    }
}

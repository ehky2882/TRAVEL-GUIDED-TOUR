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
                    .foregroundStyle(.black)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: place.category.iconName)
                        .font(AtlasTypography.standard)
                    Text(place.category.displayName)
                        .font(AtlasTypography.standard)
                }
                .foregroundStyle(.black)
            }
            .frame(width: 170, alignment: .leading)
        }
        .frame(width: 170)
    }
}

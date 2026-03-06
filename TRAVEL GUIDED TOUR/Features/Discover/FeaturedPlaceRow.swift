import SwiftUI

struct FeaturedPlaceRow: View {
    let place: Place
    let cityName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            ZStack(alignment: .bottomLeading) {
                HeroImageView(
                    imageName: place.heroImageURL,
                    height: 260,
                    cornerRadius: AtlasSpacing.cardCornerRadius,
                    category: place.category
                )

                // Price badge
                VStack {
                    HStack {
                        Spacer()
                        Text(place.priceIndicator.displayText)
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(AtlasSpacing.md)
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                HStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: place.category.iconName)
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                    Text(place.category.displayName.uppercased())
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                        .tracking(1)

                    if !cityName.isEmpty {
                        Text("·")
                            .foregroundStyle(.black)
                        Text(cityName)
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }
                }

                Text(place.name)
                    .font(AtlasTypography.title3)
                    .foregroundStyle(.black)
                    .lineLimit(2)

                Text(place.editorialDescription)
                    .font(AtlasTypography.callout)
                    .foregroundStyle(.black)
                    .lineSpacing(3)
                    .lineLimit(3)
            }
        }
    }
}

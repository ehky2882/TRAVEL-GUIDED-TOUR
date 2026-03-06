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

                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))

                // Price badge
                VStack {
                    HStack {
                        Spacer()
                        Text(place.priceIndicator.displayText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(AtlasSpacing.md)
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                HStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: place.category.iconName)
                        .font(.system(size: 10))
                        .foregroundStyle(AtlasColors.accent)
                    Text(place.category.displayName.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AtlasColors.accent)
                        .tracking(1)

                    if !cityName.isEmpty {
                        Text("·")
                            .foregroundStyle(AtlasColors.tertiaryText)
                        Text(cityName)
                            .font(.system(size: 11))
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                }

                Text(place.name)
                    .font(AtlasTypography.title3)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)

                Text(place.editorialDescription)
                    .font(AtlasTypography.callout)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineSpacing(3)
                    .lineLimit(3)
            }
        }
    }
}

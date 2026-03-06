import SwiftUI

struct CityCardView: View {
    let city: City

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeroImageView(imageName: city.heroImageURL, height: 240, cornerRadius: AtlasSpacing.cardCornerRadius)
                .frame(width: 300)

            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(city.country.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.7))

                Text(city.name)
                    .font(AtlasTypography.title)
                    .foregroundStyle(.white)

                Text("\(city.placeCount) curated places")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(AtlasSpacing.lg)
        }
        .frame(width: 300, height: 240)
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}

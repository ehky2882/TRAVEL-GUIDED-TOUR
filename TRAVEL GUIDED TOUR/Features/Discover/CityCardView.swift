import SwiftUI

struct CityCardView: View {
    let city: City

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeroImageView(imageName: city.heroImageURL, height: 240, cornerRadius: AtlasSpacing.cardCornerRadius)
                .frame(width: 300)


            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(city.country.uppercased())
                    .font(AtlasTypography.standard)
                    .tracking(1.5)
                    .foregroundStyle(.black)

                Text(city.name)
                    .font(AtlasTypography.title)
                    .foregroundStyle(.black)

                Text("\(city.placeCount) curated places")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(.black)
            }
            .padding(AtlasSpacing.lg)
        }
        .frame(width: 300, height: 240)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

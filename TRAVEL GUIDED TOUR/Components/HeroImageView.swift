import SwiftUI

struct HeroImageView: View {
    let imageName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 0
    var category: PlaceCategory? = nil

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)

            // Category icon or city icon
            if let category {
                Image(systemName: category.iconName)
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
            } else {
                Image(systemName: cityIcon(for: imageName))
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func cityIcon(for name: String) -> String {
        if name.contains("nyc") || name.contains("highline") || name.contains("noguchi") {
            return "building.2.crop.circle"
        } else if name.contains("porto") || name.contains("lello") || name.contains("clerigos") {
            return "building.columns"
        } else if name.contains("london") || name.contains("barbican") {
            return "crown"
        }
        return "photo"
    }
}

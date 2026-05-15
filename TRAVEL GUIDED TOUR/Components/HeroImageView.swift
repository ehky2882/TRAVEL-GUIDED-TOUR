import SwiftUI

struct HeroImageView: View {
    let imageName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 0
    var category: TourCategory? = nil

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)

            if let category {
                Image(systemName: category.iconName)
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
            } else {
                Image(systemName: "photo")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

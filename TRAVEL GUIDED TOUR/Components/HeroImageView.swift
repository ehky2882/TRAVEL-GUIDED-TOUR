import SwiftUI

struct HeroImageView: View {
    let imageName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 0
    var category: TourCategory? = nil

    // Loads the remote image from `imageName` (an HTTPS URL on the
    // CDN — gh-pages during the prototype phase, R2 post-V1; see
    // docs/cdn-decision.md). The adaptive-grey block is the
    // placeholder while loading, the failure fallback when the
    // network errors, and the empty state when `imageName` isn't a
    // valid URL.

    var body: some View {
        AsyncImage(url: URL(string: imageName)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Rectangle()
                    .fill(AtlasColors.placeholderWarm)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

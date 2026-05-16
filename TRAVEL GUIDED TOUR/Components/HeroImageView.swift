import SwiftUI

struct HeroImageView: View {
    let imageName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 0
    var category: TourCategory? = nil

    // V1 placeholder: a solid mid-grey block. The intent is to make
    // image regions read as obvious "image goes here" shapes during
    // layout work, before real photos arrive in M-launch-content.
    // The category icon is intentionally omitted — solid blocks make
    // the layout grid easier to scan. Swap to AsyncImage(url:) once
    // CDN photos are available.
    private let placeholderFill = Color(white: 0.78)

    var body: some View {
        Rectangle()
            .fill(placeholderFill)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

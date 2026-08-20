import SwiftUI

/// How anything hero-sized gets its height.
///
/// One modifier, used by every surface that sits in a hero slot — the photo
/// carousel, the still image inside it, a gallery video, and the map that swaps
/// in beside them. They **must** agree: if the carousel and the map resolve to
/// different heights, the page jumps when you switch between GALLERY and MAP.
/// Sharing one modifier is what makes disagreeing impossible.
///
/// Pass a number for a fixed height (56 pt list thumbnails, rail cards), or nil
/// to take `AtlasSpacing.heroAspectRatio` — see that token for why a ratio
/// rather than a fixed height.
extension View {
    @ViewBuilder
    func atlasHeroSizing(_ height: CGFloat?) -> some View {
        if let height {
            frame(height: height)
        } else {
            // `.fit` against an unbounded height (a vertical ScrollView proposes
            // one) resolves from the width, which is what makes the height
            // follow the device.
            aspectRatio(AtlasSpacing.heroAspectRatio, contentMode: .fit)
        }
    }
}

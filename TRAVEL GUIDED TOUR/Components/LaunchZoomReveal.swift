import SwiftUI

/// The launch opening: a circular mask expanding from the splash mark, with a
/// scale and a blur behind it.
///
/// A `ViewModifier` rather than inline modifiers so the whole effect can be
/// applied — and skipped — in one place, and so `progress == 1` costs literally
/// nothing: no mask, no blur, no scale, for the entire life of the app after
/// the first half second.
struct LaunchZoomReveal: ViewModifier {
    /// 0 = closed (a circle the size of the mark), 1 = fully open.
    let progress: Double

    // `@ViewBuilder` because the body branches: the finished state returns the
    // content untouched rather than a masked copy of it, and without this the
    // two arms would have to be one type.
    @ViewBuilder
    func body(content: Content) -> some View {
        if progress >= 1 {
            // The overwhelmingly common case. Returning the content untouched
            // means no offscreen render pass once the launch is done.
            content
        } else {
            content
                .scaleEffect(1 + (1 - progress) * Self.scaleOvershoot)
                .blur(radius: (1 - progress) * Self.maxBlur)
                // ⚠️ The GeometryReader lives INSIDE the mask, never around the
                // content. Wrapping the app in one would change its layout —
                // a GeometryReader fills the proposal and aligns its child
                // top-leading — for the sake of reading a size. A mask's
                // content is already laid out against the masked view's bounds,
                // so measuring in here is free and touches nothing.
                .mask {
                    GeometryReader { geo in
                        Circle()
                            .frame(
                                width: radius(in: geo.size) * 2,
                                height: radius(in: geo.size) * 2
                            )
                            .position(LaunchZoom.origin(in: geo.size))
                    }
                }
        }
    }

    /// From the mark's own radius out to a circle that covers the furthest
    /// corner — so the opening finishes by clearing the screen, not by
    /// reaching an arbitrary size that happens to look big enough.
    private func radius(in size: CGSize) -> CGFloat {
        let origin = LaunchZoom.origin(in: size)
        let corner = CGPoint(
            x: origin.x > size.width / 2 ? 0 : size.width,
            y: origin.y > size.height / 2 ? 0 : size.height
        )
        let full = (pow(corner.x - origin.x, 2) + pow(corner.y - origin.y, 2)).squareRoot()
        return LaunchZoom.startRadius + (full - LaunchZoom.startRadius) * progress
    }

    private static let scaleOvershoot: CGFloat = 0.07
    private static let maxBlur: CGFloat = 6
}

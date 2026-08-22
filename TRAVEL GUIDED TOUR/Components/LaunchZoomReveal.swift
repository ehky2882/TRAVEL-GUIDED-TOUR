import SwiftUI

/// The depth behind the launch opening: a scale and a blur on the app while the
/// splash's hole grows over it.
///
/// 🔴 **THIS DOES NOT MASK.** The opening is a hole punched in the splash's
/// black (`SplashView`), never a mask on the app. Build 102 masked the app and
/// faded the black over the top of it, so the opening expanded under an opaque
/// sheet and the whole thing read as a cross-fade — the exact effect three
/// rounds of work were meant to replace. If you find yourself adding a `.mask`
/// here, you are rebuilding that bug.
///
/// ⚠️ The effect is applied **unconditionally and neutralised by value** — at
/// `progress == 1` the scale is 1 and the blur radius 0. It used to branch
/// (`if progress >= 1 { content } else { … }`), and the two `@ViewBuilder` arms
/// are different view types, so reaching 1 could hand SwiftUI a structural
/// change and tear down the whole `ContentView` subtree — `MKMapView` included,
/// at the 0.42s mark, undoing the entire point of building it early.
struct LaunchZoomReveal: ViewModifier {
    /// 0 = the app is small and soft behind the splash, 1 = arrived.
    let progress: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(1 + (1 - progress) * Self.scaleOvershoot)
            .blur(radius: (1 - progress) * Self.maxBlur)
    }

    private static let scaleOvershoot: CGFloat = 0.07
    private static let maxBlur: CGFloat = 6
}

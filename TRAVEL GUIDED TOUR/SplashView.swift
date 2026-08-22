import SwiftUI

/// The launch screen, and the opening it turns into.
///
/// The hand-off is a **zoom transition** — Apple's own (`.zoom`, what drives
/// folder-open and app-launch-from-icon); Material calls the same idea a
/// *container transform*. The brass mark is the container: it expands, and the
/// app comes through the opening it leaves rather than a black panel fading off
/// the top of it.
///
/// Owner reference 2026-08-22 (a screenshot of an iOS folder opening), after
/// two rejected attempts at a staged assembly: *"I like the transition from the
/// splash to the app… snappy."*
///
/// **This is one view rather than two on purpose.** The mark has to be visibly
/// the same object before and after the hand-off begins — a resting splash
/// swapped for a separate animating overlay would pop at the seam unless both
/// laid the circle out identically, which is exactly the kind of agreement that
/// drifts. At `handOff == 0` this draws precisely the splash it always did.
struct SplashView: View {
    /// 0 → 1 across the hand-off. See `LaunchState.handOffProgress`.
    var handOff: Double = 0
    /// Reduce Motion: the mark doesn't bloom, the black simply clears.
    var reduceMotion: Bool = false

    @State private var pulse: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            let origin = LaunchZoom.origin(in: geo.size)
            ZStack {
                // Black, not `AtlasColors.background` — the splash is the same
                // black in both appearances, the way the brand screen has
                // always been.
                Color.black
                    .opacity(groundOpacity)
                    .ignoresSafeArea()

                // The wordmark is not part of the gesture; it goes first and
                // fast, so the mark is alone by the time it starts to open.
                Text("Dozent")
                    .font(AtlasTypography.wordmark)
                    .foregroundStyle(.white)
                    .tracking(2)
                    .opacity(1 - wordmarkLift)
                    .position(
                        x: origin.x,
                        y: origin.y + Self.markDiameter / 2 + AtlasSpacing.md
                    )

                // The mark. It blooms outward AS the app's mask opens from the
                // same point and the same starting radius, so the two read as
                // one movement: the circle you were looking at becomes the hole
                // you are looking through.
                Circle()
                    .fill(AtlasColors.mapPin)
                    .frame(width: Self.markDiameter, height: Self.markDiameter)
                    .scaleEffect(markScale)
                    .opacity(markOpacity)
                    .position(origin)
                    // The resting pulse, and only at rest: a mark that is
                    // blooming and breathing at once reads as two animations
                    // fighting.
                    .opacity(handOff > 0 ? 1 : pulse)
                    .animation(
                        handOff > 0 ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: pulse
                    )
            }
        }
        .onAppear { pulse = 0.2 }
        .allowsHitTesting(false)
    }

    // MARK: - Geometry

    /// The splash circle. Its radius is also where the app's mask starts, which
    /// is why `LaunchZoom.startRadius` is half of this — change one, change both.
    private static let markDiameter: CGFloat = 44

    // MARK: - Ramps

    private var wordmarkLift: Double {
        LaunchBloom.ramp(handOff, delay: LaunchBloom.wordmarkLift.delay, window: LaunchBloom.wordmarkLift.window)
    }

    /// A CUT, not a dissolve — and it happens *under* the expanding opening, so
    /// by the time the black goes there is very little of it left to see.
    ///
    /// The 0.42s eased dissolve this replaced was the single biggest reason the
    /// launch stopped feeling snappy: the black lingered over the thing it was
    /// supposed to be revealing. Owner, 2026-08-21: *"the fade of the splash
    /// page doesn't feel like a good transition, too slow and gentle."*
    private var groundOpacity: Double {
        1 - LaunchBloom.ramp(handOff, delay: LaunchBloom.splashCut.delay, window: LaunchBloom.splashCut.window)
    }

    /// Blooms open with the mask. Reduce Motion holds it still and lets the
    /// black clear on its own.
    private var markScale: Double {
        guard !reduceMotion else { return 1 }
        return 1 + 8 * zoomEase
    }

    private var markOpacity: Double {
        guard !reduceMotion else { return 1 - groundFadeMirror }
        return 1 - min(zoomEase * 1.6, 1)
    }

    /// The mark leads the mask slightly so it is gone before the opening is
    /// wide enough for its edge to be distracting.
    private var zoomEase: Double {
        LaunchBloom.ramp(handOff, delay: LaunchBloom.zoom.delay, window: LaunchBloom.zoom.window * 0.7)
    }

    /// Under Reduce Motion the mark simply fades with the ground.
    private var groundFadeMirror: Double { 1 - groundOpacity }
}

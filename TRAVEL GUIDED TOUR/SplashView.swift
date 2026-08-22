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
                Rectangle()
                    .fill(.black)
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

                // 🔴 THE MARK IS SIZED OFF THE HOLE, so it survives the
                // mask as a RIM travelling just ahead of the opening — which
                // is what makes the mark read as *opening* rather than just
                // fading. Owner, at ⅙× speed: *"def prefer mark opens (A)."*
                //
                // A fixed diameter with a `scaleEffect` cannot do this: the
                // opening starts at exactly the mark's own radius and grows
                // toward a screen corner, so it outruns any scale within a
                // frame or two and the brass is simply gone.
                Circle()
                    .fill(AtlasColors.mapPin)
                    .frame(width: markDiameter(in: geo.size), height: markDiameter(in: geo.size))
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
            // 🔴 THE OPENING IS A HOLE IN THE WHOLE SPLASH — black, wordmark
            // and mark together — not a mask on the app.
            //
            // Build 102 had it the other way round: the app carried the
            // expanding mask and this layer faded uniformly over the top, so
            // the opening expanded *underneath an opaque sheet* and all anyone
            // could see was a cross-fade. Owner: *"the build basically did none
            // of what i asked for."*
            //
            // Masking the whole stack is also what makes the mark read as
            // OPENING rather than merely fading: the hole starts at the mark's
            // own radius and eats it from the inside, so what is left of the
            // brass is a rim travelling ahead of the opening.
            .mask {
                if reduceMotion {
                    // No opening under Reduce Motion — the black simply
                    // clears, which is what `groundOpacity` does.
                    Rectangle()
                } else {
                    Rectangle()
                        .overlay {
                            Circle()
                                .frame(
                                    width: holeRadius(in: geo.size) * 2,
                                    height: holeRadius(in: geo.size) * 2
                                )
                                .position(LaunchZoom.origin(in: geo.size))
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }
            }
            .ignoresSafeArea()
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
        // Under Reduce Motion this IS the transition. Otherwise the hole has
        // already cleared the screen by the time it matters, and this only
        // guarantees nothing is left over at the end.
        guard reduceMotion else {
            return 1 - LaunchBloom.ramp(handOff, delay: 0.86, window: 0.14)
        }
        return 1 - LaunchBloom.ramp(handOff, delay: LaunchBloom.splashCut.delay, window: LaunchBloom.splashCut.window)
    }

    /// The hole, on exactly the geometry the opening was always specified with.
    private func holeRadius(in size: CGSize) -> CGFloat {
        // ⚠️ No hole at rest. The opening starts at the mark's own radius, so
        // a resting splash would otherwise be punched through — a 44pt window
        // onto the map, on the brand screen.
        guard handOff > 0 else { return 0 }
        return LaunchZoom.radius(progress: LaunchBloom.zoomProgress(handOff: handOff), in: size)
    }

    /// The rim: the hole's radius plus a brass band that thins as it goes.
    /// At rest (`handOff == 0`) there is no hole, so this is simply the mark.
    private func markDiameter(in size: CGSize) -> CGFloat {
        guard !reduceMotion, handOff > 0 else { return Self.markDiameter }
        let band = LaunchZoom.startRadius * (1 - zoomEase)
        return (holeRadius(in: size) + band) * 2
    }

    private var markOpacity: Double {
        guard !reduceMotion else { return 1 - groundFadeMirror }
        return 1 - min(zoomEase * 1.15, 1)
    }

    /// The mark leads the mask slightly so it is gone before the opening is
    /// wide enough for its edge to be distracting.
    private var zoomEase: Double {
        LaunchBloom.ramp(handOff, delay: LaunchBloom.zoom.delay, window: LaunchBloom.zoom.window * 0.7)
    }

    /// Under Reduce Motion the mark simply fades with the ground.
    private var groundFadeMirror: Double { 1 - groundOpacity }
}

import SwiftUI

/// The launch screen, and the hand-off out of it.
///
/// **This is one view rather than two on purpose.** The mark has to be visibly
/// the *same object* before and after the hand-off begins — a resting splash
/// swapped for a separate animating overlay would pop at the seam unless both
/// laid the circle out identically, which is exactly the kind of agreement that
/// drifts. At `handOff == 0` this draws precisely the splash it always did.
struct SplashView: View {
    /// 0 → 1 across the hand-off. See `LaunchState.handOffProgress`.
    var handOff: Double = 0
    /// Where the mark should land, in this view's coordinate space — the
    /// user's dot on the map. `nil` (no location fix) lands it at the centre,
    /// where the fallback region is centred anyway.
    var landingPoint: CGPoint? = nil
    /// Reduce Motion: hold the resting composition and let the ground fade.
    /// The mark doesn't travel, the ripple doesn't fire.
    var reduceMotion: Bool = false

    @State private var pulse: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            let target = landingPoint ?? CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                // Black, not `AtlasColors.background` — the splash is the same
                // black in both appearances, the way the brand screen has
                // always been. It fades to reveal the map already built beneath.
                Color.black
                    .opacity(groundOpacity)
                    .ignoresSafeArea()

                // Resting composition. The mark is pulled OUT of this stack
                // once the hand-off starts (`markTravel > 0`) so it can travel
                // independently while the wordmark lifts away beneath it.
                VStack(spacing: AtlasSpacing.md) {
                    Color.clear
                        .frame(width: Self.restingDiameter, height: Self.restingDiameter)

                    // Wordmark in iOS's New York serif system font —
                    // editorial register matches the gold map-pin palette.
                    //
                    // Reads the shared token rather than hardcoding the face
                    // so this and the Settings masthead cannot drift into two
                    // variants of one logotype; only the colour differs, and
                    // deliberately — the brass circle above carries the accent
                    // here, so the mark itself is white.
                    Text("Dozent")
                        .font(AtlasTypography.wordmark)
                        .foregroundStyle(.white)
                        .tracking(2)
                        .opacity(1 - wordmarkLift)
                        .offset(y: -10 * wordmarkLift)
                }

                // The ripple the landing throws off. Same halo treatment as
                // `ClusterPin`'s outer ring, so the arrival reads as part of
                // the map's own vocabulary rather than a one-off effect.
                if arrival > 0 && !reduceMotion {
                    Circle()
                        .stroke(AtlasColors.mapPin, lineWidth: 1.5)
                        .frame(width: Self.dotDiameter, height: Self.dotDiameter)
                        .scaleEffect(1 + 7 * arrival)
                        .opacity(1 - arrival)
                        .position(target)
                }

                // The mark itself.
                Circle()
                    .fill(AtlasColors.mapPin)
                    .frame(width: Self.restingDiameter, height: Self.restingDiameter)
                    .scaleEffect(markScale)
                    .opacity(markOpacity)
                    .position(markPosition(in: geo.size, target: target))
                    // The resting pulse, and only at rest: a mark that is
                    // travelling and breathing at the same time reads as two
                    // animations fighting.
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

    /// The splash circle's diameter. Also the app icon's mark.
    private static let restingDiameter: CGFloat = 44
    /// `UserLocationDot`'s inner dot. The mark contracts to exactly this, so it
    /// can hand over to the real thing without a size jump.
    private static let dotDiameter: CGFloat = 16

    /// Where the mark sits at rest: centred, lifted by half the wordmark block
    /// so the pair is optically centred (mirrors the `VStack` above).
    private func restingPosition(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2 - Self.restingDiameter / 2)
    }

    /// Interpolates from the resting position to the landing point.
    ///
    /// ⚠️ The travel is SHORT — the launch camera centres on the user, so the
    /// dot lands at the map's centre, a few points below where the mark already
    /// sits. The motion that carries this moment is the **contraction**
    /// (44pt → 16pt) and the ripple, not a fall. Don't add distance by moving
    /// the resting mark; that is the brand screen's composition.
    private func markPosition(in size: CGSize, target: CGPoint) -> CGPoint {
        let from = restingPosition(in: size)
        guard !reduceMotion else { return from }
        let t = markLanding
        return CGPoint(
            x: from.x + (target.x - from.x) * t,
            y: from.y + (target.y - from.y) * t
        )
    }

    // MARK: - Ramps

    private var wordmarkLift: Double {
        LaunchBloom.ramp(handOff, delay: LaunchBloom.wordmarkLift.delay, window: LaunchBloom.wordmarkLift.window)
    }
    private var markLanding: Double {
        LaunchBloom.ramp(handOff, delay: LaunchBloom.markLanding.delay, window: LaunchBloom.markLanding.window)
    }
    private var arrival: Double {
        LaunchBloom.ramp(handOff, delay: LaunchBloom.arrival.delay, window: LaunchBloom.arrival.window)
    }
    private var groundOpacity: Double {
        1 - LaunchBloom.ramp(handOff, delay: LaunchBloom.groundFade.delay, window: LaunchBloom.groundFade.window)
    }

    /// Contracts to the location dot's exact size as it lands.
    private var markScale: Double {
        guard !reduceMotion else { return 1 }
        let shrunk = Self.dotDiameter / Self.restingDiameter
        return 1 + (shrunk - 1) * markLanding
    }

    /// Fades out as the arrival plays, handing the position over to the real
    /// blue dot rising underneath it. The two overlap deliberately — a gap
    /// would read as the mark vanishing rather than becoming something.
    private var markOpacity: Double {
        1 - arrival
    }
}

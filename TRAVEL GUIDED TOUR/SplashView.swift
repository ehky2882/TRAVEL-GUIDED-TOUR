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
                // 🔴 A PLAIN BLACK GROUND, AND NOTHING CLEVER — the disc is
                // simply drawn on top of it and cut out from under once it
                // covers the screen.
                //
                // ⚠️ TWO REJECTED GROUNDS, do not rebuild either. A masked
                // rectangle (an offscreen pass every frame) and a circle
                // stroked wider than the screen whose inner edge tracked the
                // disc. The stroked ring was reported from a device
                // immediately: *"the circle has a border around it when it
                // expands."* Two antialiased edges at the same radius — the
                // disc's and the hole's — cannot line up sub-pixel, and the
                // disc's own edge softens as it is scaled up, so the seam
                // between them reads as a rim around the mark.
                //
                // One shape over another has no seam to show.
                Rectangle()
                    .fill(.black)
                    .opacity(groundOpacity)
                    .ignoresSafeArea()

                // The wordmark is not part of the gesture; it goes first and
                // fast, so the mark is alone by the time it starts to grow.
                Text("Dozent")
                    .font(AtlasTypography.wordmark)
                    .foregroundStyle(.white)
                    .tracking(2)
                    .opacity(1 - wordmarkLift)
                    .position(
                        x: origin.x,
                        y: origin.y + Self.markDiameter / 2 + AtlasSpacing.md
                    )

                // 🔴 THE MARK IS A SOLID DISC THE WHOLE WAY. It expands from
                // the mark's own 44pt until it covers the screen, and only
                // then dissolves into the map behind it — the container
                // transform proper: the container grows, then its fill
                // cross-fades to the destination.
                //
                // ⚠️ TWO REJECTED SHAPES, do not rebuild either. (a) Masking
                // the app and fading black over it: the opening expanded under
                // an opaque sheet and read as a cross-fade. (b) Punching a hole
                // and sizing the mark off it: that leaves a brass RING with map
                // inside it — owner, *"i dont like that the brass circle
                // becomes a ring and that there's blue behind it. it should
                // stay as a solid as it expands."* A disc over black needs
                // neither a mask nor a hole, and costs two shape fills a frame.
                Circle()
                    .fill(AtlasColors.mapPin)
                    .frame(width: Self.markDiameter, height: Self.markDiameter)
                    .scaleEffect(discScale(in: geo.size))
                    .opacity(markOpacity)
                    .position(origin)
                    // The resting pulse breathes the SIZE, not the opacity — a
                    // half-faded disc is exactly the "solid" this is not
                    // supposed to be, and the pulse's in-flight opacity was
                    // still on screen at the first frame of the hand-off.
                    .scaleEffect(handOff > 0 ? 1 : pulse)
                    .animation(
                        handOff > 0 ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: pulse
                    )
                    .ignoresSafeArea()
            }
        }
        // 🔴 THE GEOMETRY READER MUST SPAN THE WHOLE SCREEN, because the mark's
        // position is specified against the screen — it has to sit exactly
        // where the map draws the user's blue dot, which is the map view's
        // centre. Read inside the safe area instead and it sits ~30pt high of
        // the dot, and the mark no longer reads as becoming it. Owner: *"the
        // brass circle should be positioned exactly where the blue location
        // marker would be so it is as if the brass circle becomes the location
        // marker."*
        .ignoresSafeArea()
        .onAppear { pulse = 1.10 }
        .allowsHitTesting(false)
    }

    // MARK: - Geometry

    /// The resting mark.
    private static let markDiameter: CGFloat = 44

    /// How far past "just covering the screen" the disc grows.
    private static let coverageOvershoot: CGFloat = 1.06

    // MARK: - Ramps

    private var wordmarkLift: Double {
        LaunchBloom.ramp(handOff, delay: LaunchBloom.wordmarkLift.delay, window: LaunchBloom.wordmarkLift.window)
    }

    /// 🔴 THE BLACK FADES ON EXACTLY THE DISC'S OWN VALUE — not on a clock of
    /// its own.
    ///
    /// Cutting it on a separate ramp kept producing the same bug in different
    /// clothes: the black went while the disc was still visibly growing, so the
    /// map appeared behind a mark that was meant to be covering it. Two ramps
    /// that are supposed to coincide will not, because the renderer does not
    /// advance every layer at the same rate under load — which is exactly what
    /// a slow device does. One number cannot disagree with itself.
    ///
    /// The disc covers the screen before it starts to fade, so the black behind
    /// it is invisible by then anyway; they simply go together.
    private var groundOpacity: Double { markOpacity }

    /// 🔴 THE GROWTH IS A SCALE, NOT A FRAME — and that is what keeps the disc
    /// solid while it grows.
    ///
    /// A `.frame(width:)` animation is a LAYOUT animation, and in the Simulator
    /// it visibly could not keep pace with the opacity animation beside it on
    /// the same transaction: the fade ran ahead of the growth, so the map
    /// showed through a disc that was still expanding — exactly the
    /// see-through the owner rejected. A scale and an opacity are both plain
    /// transform-layer properties, animate on the same clock, and cannot come
    /// apart.
    ///
    /// It grows from the mark's own radius out to a circle clearing the
    /// furthest corner, so it finishes by covering the screen rather than by
    /// reaching an arbitrary size. Reduce Motion holds it still.
    private func discScale(in size: CGSize) -> CGFloat {
        guard !reduceMotion else { return 1 }
        // ⚠️ The overshoot is load-bearing: the black is cut the instant the
        // disc is meant to cover the screen, so the disc has to be *past*
        // covering by then. Without it, a frame of lag shows a rim of map.
        return LaunchZoom.radius(progress: LaunchBloom.zoomProgress(handOff: handOff), in: size)
            * Self.coverageOvershoot / LaunchZoom.startRadius
    }

    private var markOpacity: Double {
        // Reduce Motion: no growth and no dissolve — the black simply clears
        // over the splash-cut window, and the mark clears with it.
        guard !reduceMotion else {
            return 1 - LaunchBloom.ramp(handOff, delay: LaunchBloom.splashCut.delay, window: LaunchBloom.splashCut.window)
        }
        // Dissolves into the map it has been covering, finishing exactly when
        // the opening does — so the zoom ends on a bare map with no brass and
        // no chrome on it.
        return 1 - LaunchBloom.ramp(handOff, delay: LaunchBloom.markDissolve.delay, window: LaunchBloom.markDissolve.window)
    }

}

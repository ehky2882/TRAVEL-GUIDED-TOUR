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
    /// Reduce Motion: the mark doesn't bloom, the ground simply clears.
    var reduceMotion: Bool = false
    /// Called once, when the splash's first frame has actually reached the
    /// screen. The launch gate times the visible breath from this — see
    /// `LaunchState.markSplashShown`.
    var onShown: () -> Void = {}

    /// When the breathing started. The breath is read off the clock, not animated.
    @State private var breathStart = Date()

    var body: some View {
        GeometryReader { geo in
            let origin = LaunchZoom.origin(in: geo.size)
            ZStack {
                // 🔴 A PLAIN GROUND, AND NOTHING CLEVER — the disc is
                // simply drawn on top of it and cut out from under once it
                // covers the screen.
                //
                // ⚠️ THE GROUND IS `AtlasColors.background`, NOT `.black` —
                // it must follow the colour scheme. `UILaunchScreen` is an
                // empty dict, so the system's own launch screen paints
                // `systemBackground`: white in light mode. A hardcoded black
                // splash therefore flashed white → black → white on every
                // light-mode launch (owner, 2026-08-22: *"splash page if on
                // light mode should have light background rather than
                // black"*). This token IS `systemBackground`, so dark mode is
                // the same pure black it always drew, and light mode now
                // continues the system launch screen with no seam.
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
                    .fill(AtlasColors.background)
                    .opacity(groundOpacity)
                    .ignoresSafeArea()

                // The wordmark is not part of the gesture; it goes first and
                // fast, so the mark is alone by the time it starts to grow.
                // `primaryText`, not `.white`: it reverses with the ground
                // above, so it stays white on the dark splash and goes black
                // on the light one. (Settings draws the same wordmark in
                // brass — see the note there for why the two differ.)
                Text("Dozent")
                    .font(AtlasTypography.wordmark)
                    .foregroundStyle(AtlasColors.primaryText)
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
                //
                // 🔴 THE RESTING MARK BREATHES — it fades 1.0 ↔ 0.2 every 0.8s,
                // exactly the splash it has had since the first build, and the
                // same pulse `site/atlas.css` draws on dozent.world. Owner,
                // 2026-09-12: *"i want the 'breathing' icon to come back on the
                // splash screen. i never wanted it to go away."* #559 had swapped
                // it for a 10% size pulse nobody could see. **Do not remove it
                // again, or swap it for a scale.**
                //
                // 🔴 THE BREATH RUNS ON CORE ANIMATION, NOT SWIFTUI — see
                // `SplashBreathingDisc`. The resting splash is exactly when the
                // main thread is busiest (the map, the first clustering pass and
                // the drawer are all built behind it), and a SwiftUI-driven fade
                // measured in the Simulator held one value for up to half a
                // second at a time: a breath that stutters. A layer animation is
                // run by the render server and keeps breathing through all of it.
                disc(in: geo.size)
                    .position(origin)
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

    /// The resting breath: 1.0 → 0.2 → 1.0, one half-cycle every 0.8s.
    static let breathHalfPeriod: TimeInterval = 0.8
    static let breathFloor: Double = 0.2

    /// The breath at a moment, eased back to solid across the hand-off's
    /// opening beat (the wordmark-lift window, the first ~50ms) so the disc
    /// starts growing from wherever the breath was and is opaque by the time
    /// it matters. Reduce Motion holds it solid, as the website does.
    private func breathOpacity(at date: Date) -> Double {
        guard !reduceMotion else { return 1 }
        let resting = Self.breath(elapsed: date.timeIntervalSince(breathStart))
        let solid = LaunchBloom.ramp(handOff, delay: 0, window: LaunchBloom.wordmarkLift.window)
        return resting + (1 - resting) * solid
    }

    /// A cosine is an ease-in-out by construction, so this is the same curve
    /// the original `.easeInOut(duration: 0.8).repeatForever(autoreverses:)`
    /// drew, starting at full opacity.
    static func breath(elapsed: TimeInterval) -> Double {
        let mid = (1 + breathFloor) / 2
        let amplitude = (1 - breathFloor) / 2
        return mid + amplitude * cos(.pi * elapsed / breathHalfPeriod)
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

    // MARK: - The mark

    /// The brass disc: breathing while it rests, then growing and dissolving
    /// through the hand-off. The growth and dissolve stay on `handOff` exactly
    /// as before, so they still move on the same number as the ground.
    @ViewBuilder
    private func disc(in size: CGSize) -> some View {
        #if canImport(UIKit)
        SplashBreathingDisc(
            diameter: Self.markDiameter,
            isBreathing: !reduceMotion && handOff == 0,
            onShown: onShown
        )
            .frame(width: Self.markDiameter, height: Self.markDiameter)
            .scaleEffect(discScale(in: size))
            .opacity(markOpacity)
        #else
        // No UIKit (the macOS build): read the breath off a clock instead.
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Circle()
                .fill(AtlasColors.mapPin)
                .frame(width: Self.markDiameter, height: Self.markDiameter)
                .scaleEffect(discScale(in: size))
                .opacity(markOpacity * breathOpacity(at: timeline.date))
        }
        .onAppear(perform: onShown)
        #endif
    }

}

#if canImport(UIKit)
/// The splash mark as a layer, so its breath is a Core Animation animation the
/// render server keeps running however busy the main thread is.
///
/// ⚠️ The breath is a PRESENTATION animation only — the layer's model opacity
/// stays 1 the whole time. That is what makes the hand-off safe, and it is the
/// exact problem #559 cited when it dropped the fade: a SwiftUI animation's
/// in-flight opacity was still on screen at the first frame of the hand-off, so
/// the disc started growing half-transparent. Here, when breathing stops the
/// animation is removed and a 50ms settle carries the layer from wherever the
/// breath was up to solid, on the render server — long before the disc covers
/// anything.
struct SplashBreathingDisc: UIViewRepresentable {
    /// The resting size. The hand-off grows the disc with a transform, which
    /// never changes its bounds, so the corner radius is set once.
    var diameter: CGFloat
    var isBreathing: Bool
    /// Called once, on the first frame the disc is actually on screen.
    var onShown: () -> Void = {}

    static let breathKey = "atlas.splash.breath"

    /// 1.0 → 0.2 → 1.0, a half-cycle every 0.8s, eased — the original splash's
    /// `.easeInOut(duration: 0.8).repeatForever(autoreverses: true)`, and the
    /// same pulse `site/atlas.css` draws on dozent.world.
    static func breathAnimation() -> CABasicAnimation {
        let breath = CABasicAnimation(keyPath: "opacity")
        breath.fromValue = 1.0
        breath.toValue = SplashView.breathFloor
        breath.duration = SplashView.breathHalfPeriod
        breath.autoreverses = true
        breath.repeatCount = .infinity
        breath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        breath.isRemovedOnCompletion = false
        return breath
    }

    func makeUIView(context: Context) -> UIView {
        let view = SplashDiscView()
        view.onFirstFrame = onShown
        // `brass`, not `mapPin`: `mapPin` resolves the environment's accent,
        // which a bridged UIColor cannot follow. It is the same #8B7535.
        view.backgroundColor = UIColor(AtlasColors.brass)
        view.isUserInteractionEnabled = false
        view.layer.cornerCurve = .circular
        view.layer.cornerRadius = diameter / 2
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        let layer = view.layer
        if isBreathing {
            if layer.animation(forKey: Self.breathKey) == nil {
                layer.add(Self.breathAnimation(), forKey: Self.breathKey)
            }
        } else if layer.animation(forKey: Self.breathKey) != nil {
            let current = layer.presentation()?.opacity ?? 1
            layer.removeAnimation(forKey: Self.breathKey)
            let settle = CABasicAnimation(keyPath: "opacity")
            settle.fromValue = current
            settle.toValue = 1.0
            settle.duration = 0.05
            layer.add(settle, forKey: "atlas.splash.settle")
        }
    }
}

/// The disc's view, which reports the first frame it is actually on screen.
///
/// 🔴 THIS IS WHAT MAKES THE BREATH VISIBLE AT ALL. SwiftUI's `onAppear` fires
/// when the splash is *built* — measured 27ms after launch — but nothing is
/// *drawn* until the main thread finishes building the app behind it, which on a
/// cold launch was ~4.9s later in the Simulator. Timing the floor from launch
/// therefore spent it behind iOS's static launch picture, and the breathing
/// splash drew for ~0.77s: one dip, which the owner reasonably read as no
/// breathing at all (TestFlight 1.1.2 (147), 2026-09-12).
///
/// A display link's first tick runs on the main run loop after the frame that
/// put this view in a window has been committed, so it is as close to "the user
/// can see it" as the app can observe.
final class SplashDiscView: UIView {
    var onFirstFrame: () -> Void = {}
    private var displayLink: CADisplayLink?
    private var reported = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !reported, displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(firstTick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func firstTick() {
        // Invalidating releases the link's strong hold on this view.
        displayLink?.invalidate()
        displayLink = nil
        guard !reported else { return }
        reported = true
        onFirstFrame()
    }
}
#endif

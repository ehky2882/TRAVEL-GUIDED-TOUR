import SwiftUI
import AVKit
import AVFoundation
import Combine

/// What the inline carousel hands over when the user taps expand.
///
/// Carries the shape and the narration-takeover flag rather than making the
/// fullscreen view re-derive them: the inline view has already loaded the
/// asset's tracks (`GalleryVideoView.prepare()`), so re-loading them here
/// would open the clip in the wrong orientation for a beat while the second
/// load resolved.
///
/// ⚠️ `didPauseNarration` is **transferred, not copied**. The inline view
/// clears its own flag as it hands this over, which is what stops it
/// resuming the narration behind the video — see `GalleryVideoView.expand()`.
struct FullscreenVideoRequest: Identifiable, Equatable {
    let id = UUID()
    let urlString: String
    /// Where the inline player had got to, so the clip carries on rather than
    /// restarting.
    let startSeconds: Double
    /// Whether the clip carries an audio track — decides whether it takes the
    /// narration over at all. A silent clip never touches it.
    let hasAudio: Bool
    /// True when the *inline* view had paused the narration and is handing
    /// that debt over. The fullscreen view now owes the resume.
    let didPauseNarration: Bool
    /// Shape as displayed (i.e. after `preferredTransform`), not as stored.
    let isLandscape: Bool
    /// Displayed width ÷ height. Lets the expand land the picture exactly on
    /// the thumbnail's picture: the clip is aspect-fit inside both boxes, so
    /// knowing its shape is what makes the two rects comparable.
    let aspectRatio: CGFloat
    /// The carousel thumbnail's frame in GLOBAL coordinates — where the clip
    /// is on screen at the moment the user taps expand. The viewer grows out
    /// of this rather than sliding up from the bottom, so the picture appears
    /// to be the same object getting bigger.
    ///
    /// Global rather than local because the two live in different windows:
    /// the thumbnail is in the main window, the viewer in the bottom module's.
    /// Both are full-screen on the same scene, so global coordinates line up.
    let sourceFrame: CGRect
    /// The owning tour. The viewer resolves it to show the same chrome the
    /// tour page has — see `FullscreenVideoView.chromeRow`.
    let tourId: UUID?
    /// What the clip is — see `TourVideoRole`. A `.narration` clip is muted
    /// and follows the tour's audio clock, and has no transport of its own.
    let role: TourVideoRole

    static func == (a: FullscreenVideoRequest, b: FullscreenVideoRequest) -> Bool { a.id == b.id }
}

/// A clip filling the screen, presented from `BottomModuleRoot`.
///
/// **Why this exists.** In the carousel a clip is letterboxed into the 320pt
/// landscape hero box, so a 9:16 clip uses 180pt of a 345pt box — over half
/// the frame is black. Fullscreen a vertical clip is 393 × 699: **4.8× the
/// area**. Landscape barely gains upright (1.3×), which is why rotation
/// matters for it and not for vertical.
///
/// **🔴 Rotation rotates the VIDEO, never the app.** The app is portrait-locked
/// (`UISupportedInterfaceOrientations~iphone` is portrait alone) and
/// `Info.plist` is a *ceiling*: a view controller can only narrow the declared
/// set, so allowing this screen to rotate would mean opening rotation app-wide
/// and locking every other screen back — machinery this project has none of
/// (no `AppDelegate`, no scene delegate). Worse, orientation belongs to the
/// window *scene*, and this presents from the secondary `PassThroughWindow`
/// which shares its scene with the main window — so a real rotation would turn
/// the map, drawer and tour sheet behind the video too. Rotating the content
/// inside a portrait screen is invisible to everything else in the app.
///
/// **Vertical clips never rotate.** 9:16 is already at its largest upright;
/// turning it sideways makes it smaller. Same as TikTok, Reels and Shorts,
/// which letterbox landscape and never rotate — YouTube rotates because it is
/// landscape-native.
///
/// Accepted trade-off: the status bar and home indicator stay portrait-aligned
/// while the picture is sideways.
struct FullscreenVideoView: View {
    let request: FullscreenVideoRequest

    @Environment(AudioPlayerService.self) private var audioPlayer: AudioPlayerService?
    /// Dismissal clears this rather than calling `@Environment(\.dismiss)`.
    /// The cover is presented from the secondary window's `BottomModuleRoot`
    /// while this view's content is built in that window's hierarchy; driving
    /// the shared state directly is one unambiguous source of truth for
    /// "is a clip expanded", and it is the same state the carousel set to get
    /// here. Verified: the environment dismiss did not close it.
    @Environment(AppSharedState.self) private var appShared: AppSharedState?
    /// Resolves `request.tourId` so the viewer can carry the tour page's own
    /// chrome. Optional so a presentation path without it degrades to a bare
    /// close button rather than crashing.
    @Environment(DataService.self) private var dataService: DataService?
    @Environment(LibraryStore.self) private var libraryStore: LibraryStore?
    @Environment(PurchaseService.self) private var purchaseService: PurchaseService?

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    /// Physical device orientation. Still reported while the app is
    /// portrait-locked, as long as generation is running — see `.onAppear`.
    @State private var deviceOrientation = UIDevice.current.orientation
    /// Narration debt: seeded from the request, then owned here.
    @State private var owesNarrationResume = false
    @State private var controlsVisible = true
    /// The clip's own length, for the scrubber on a gallery clip. A narration
    /// clip scrubs the tour instead, so it reads the audio player's duration.
    @State private var videoDuration: Double = 0
    /// Set while a drag is in progress so the scrubber follows the finger
    /// rather than snapping back to the clock on every tick.
    @State private var scrubTarget: Double? = nil
    /// 0 = the carousel thumbnail, 1 = the whole screen. Driven on appear and
    /// on close, and the ONLY animation the viewer has — the cover is
    /// presented with animation suppressed so there is no slide underneath it.
    @State private var expansion: Double = 0

    /// The growth curve. Deliberately quick — owner: *"can the expand and
    /// contract animation be faster? right now doesnt feel very snappy."*
    /// Damping is high so that at this speed it lands cleanly instead of
    /// wobbling; a springier curve reads as slower even when it is not.
    ///
    /// This is the same instinct the launch hand-off settled on at ~0.2s for
    /// the brass disc, and for the same reason: a reveal wants to be over.
    static let expandCurve: Animation = .spring(response: 0.22, dampingFraction: 0.9)
    /// How long to let the collapse run before the state is cleared. Just past
    /// the curve, so the viewer is never torn out mid-flight — but no longer,
    /// or the tap-to-close feels like it hesitated.
    static let collapseSeconds: Double = 0.22

    // MARK: - Pure rules (unit-tested; no view, no device needed)

    /// Is the clip landscape **as displayed**?
    ///
    /// ⚠️ Read the display size, not `naturalSize`. Phone-shot video is
    /// commonly 1920 × 1080 stored with a 90° `preferredTransform`; reading
    /// `naturalSize` alone calls that vertical clip landscape and would rotate
    /// it exactly the wrong way.
    ///
    /// Square counts as not-landscape, so a 1:1 clip stays upright — there is
    /// nothing to gain by turning it.
    static func isLandscape(naturalSize: CGSize, preferredTransform: CGAffineTransform) -> Bool {
        let display = naturalSize.applying(preferredTransform)
        return abs(display.width) > abs(display.height)
    }

    /// How far to rotate the content for a given physical device orientation.
    ///
    /// Only a landscape clip rotates, and only when the phone is actually
    /// turned — otherwise the viewer would open sideways on a phone held
    /// upright.
    ///
    /// Signs, which are easy to get backwards: `UIDeviceOrientation.landscapeLeft`
    /// is the device held with the **home button on the right**, i.e. turned
    /// anticlockwise, so screen-up points to world-left and the content must
    /// rotate **+90° (clockwise)** to stand up. `.landscapeRight` is the
    /// mirror, hence −90°. (Note `UIDeviceOrientation` and
    /// `UIInterfaceOrientation` name these opposite ways round — this is the
    /// device one.)
    static func rotationDegrees(clipIsLandscape: Bool, device: UIDeviceOrientation) -> Double {
        guard clipIsLandscape else { return 0 }
        switch device {
        case .landscapeLeft: return 90
        case .landscapeRight: return -90
        default: return 0
        }
    }

    /// Should a clip take the tour narration over?
    ///
    /// The owner's rule, 2026-07-19, and the silent path is live today so it
    /// must keep working:
    ///   - a clip **with** an audio track pauses the narration and resumes it
    ///     afterwards;
    ///   - a **silent** clip never touches it — it plays as moving imagery
    ///     while the narration continues, exactly like a photo.
    ///
    /// Also refuses to pause a narration that isn't playing, so a tour the
    /// user deliberately paused is never restarted on their behalf, and
    /// refuses to double-take when the debt is already owed.
    ///
    /// Shared by the inline carousel view and this one so the two cannot
    /// drift — the inline copy is what the silent-clip behaviour rests on.
    static func shouldTakeOverNarration(
        clipHasAudio: Bool,
        narrationIsPlaying: Bool,
        alreadyOwesResume: Bool
    ) -> Bool {
        clipHasAudio && narrationIsPlaying && !alreadyOwesResume
    }

    /// How far in from each edge the controls sit.
    ///
    /// 🔴 Read the safe area from the WINDOW, not from the `GeometryReader`.
    /// Once `.ignoresSafeArea()` is applied the geometry reports insets of
    /// zero, so deriving the numbers there silently gives a bare constant —
    /// which is how the close button ended up centred at y=46, inside the
    /// Dynamic Island's cutout, where the system takes the touch. It drew, it
    /// sat in the accessibility tree, and it did nothing.
    ///
    /// **Unrotated, these reproduce `TourDetailView.chromeRow` exactly**: that
    /// row lives inside the safe area with `sm` above it and `lg` at the
    /// sides, so its button centres land at `safeTop + sm + 22`. Matching that
    /// is the point — owner direction, the X / bookmark / `…` sit where they
    /// sit on the tour page.
    ///
    /// **Rotated, they go uniform.** The controls ride inside the rotated
    /// stack, so the island can be along any edge relative to them, and a
    /// 24pt side inset would put a control straight back under it.
    static func controlInsets(
        rotated: Bool,
        safeArea: UIEdgeInsets? = nil
    ) -> EdgeInsets {
        let safe = safeArea ?? (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets)
            ?? .zero
        if rotated {
            let uniform = max(safe.top, safe.bottom, safe.left, safe.right, AtlasSpacing.lg)
            return EdgeInsets(top: uniform, leading: uniform, bottom: uniform, trailing: uniform)
        }
        return EdgeInsets(
            top: safe.top + AtlasSpacing.sm,
            leading: AtlasSpacing.lg,
            bottom: max(safe.bottom, AtlasSpacing.sm) + AtlasSpacing.sm,
            trailing: AtlasSpacing.lg
        )
    }

    /// The rect a clip of this shape actually occupies inside a box, once
    /// aspect-fit. The letterboxing is why the picture's on-screen rect is not
    /// the box: a vertical clip in a wide box leaves black down both sides.
    static func aspectFitRect(aspectRatio: CGFloat, in box: CGRect) -> CGRect {
        guard aspectRatio > 0, box.width > 0, box.height > 0 else { return box }
        let boxRatio = box.width / box.height
        let size: CGSize = aspectRatio > boxRatio
            ? CGSize(width: box.width, height: box.width / aspectRatio)   // width-limited
            : CGSize(width: box.height * aspectRatio, height: box.height) // height-limited
        return CGRect(
            x: box.midX - size.width / 2,
            y: box.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    /// How the viewer's content is transformed partway through the expand.
    ///
    /// `progress` 0 reproduces the carousel thumbnail exactly; 1 fills the
    /// screen.
    ///
    /// 🔴 The thumbnail FILLS its box (cropping the clip) while fullscreen
    /// FITS (showing all of it), so the expand is a reveal, not just a
    /// growth: the picture keeps its scale relationship while the window onto
    /// it opens out. Three interpolations do that —
    ///
    ///  - `scale` from the fill scale to 1, so at rest the picture is exactly
    ///    the size the thumbnail draws it;
    ///  - `centre` from the thumbnail's centre to the screen's;
    ///  - `mask` from the thumbnail's box to the whole screen, which is what
    ///    uncrops the top and bottom on the way out.
    ///
    /// Matching only the box would have needed a per-axis scale, squashing the
    /// picture for the whole flight.
    ///
    /// An empty `source` returns the identity, so a missing measurement
    /// degrades to the picture simply being there rather than to nothing.
    ///
    /// ⚠️ Computed unrotated. Expanding while the phone is already sideways
    /// with a landscape clip starts fractionally off for the length of the
    /// growth; not worth carrying rotation through for that.
    static func expandTransform(
        source: CGRect,
        full: CGRect,
        aspectRatio: CGFloat,
        progress: Double
    ) -> (scale: CGFloat, centre: CGPoint, mask: CGRect) {
        let identity = (
            scale: CGFloat(1),
            centre: CGPoint(x: full.midX, y: full.midY),
            mask: full
        )
        guard source.width > 0, source.height > 0, full.width > 0, full.height > 0 else {
            return identity
        }
        let t = CGFloat(min(max(progress, 0), 1))
        // What fullscreen draws: the clip fitted into the screen.
        let fullPicture = aspectFitRect(aspectRatio: aspectRatio, in: full)
        guard fullPicture.width > 0, fullPicture.height > 0 else { return identity }
        // What the thumbnail draws: the same clip scaled to COVER its box.
        // `max` is what makes it a fill — the overflow is the crop.
        let fillScale = max(
            source.width / fullPicture.width,
            source.height / fullPicture.height
        )
        func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * t }
        return (
            scale: lerp(fillScale, 1),
            centre: CGPoint(x: lerp(source.midX, full.midX), y: lerp(source.midY, full.midY)),
            mask: CGRect(
                x: lerp(source.minX, full.minX),
                y: lerp(source.minY, full.minY),
                width: lerp(source.width, full.width),
                height: lerp(source.height, full.height)
            )
        )
    }

    /// The size the content stack is laid out at before rotation. When
    /// rotated it takes the screen's dimensions swapped, so the picture fills
    /// the long axis.
    static func contentSize(screen: CGSize, rotationDegrees: Double) -> CGSize {
        rotationDegrees == 0 ? screen : CGSize(width: screen.height, height: screen.width)
    }

    // MARK: - View

    private var rotation: Double {
        Self.rotationDegrees(clipIsLandscape: request.isLandscape, device: deviceOrientation)
    }

    var body: some View {
        GeometryReader { geo in
            let size = Self.contentSize(screen: geo.size, rotationDegrees: rotation)
            // 🔴 The picture fills the screen, but the CONTROLS must clear the
            // Dynamic Island. At a plain 24pt inset the close button centred at
            // y=46 — inside the island's cutout, where the system takes the
            // touch: the button drew, sat in the accessibility tree, and its
            // action never ran. A uniform inset is used because the controls
            // ride inside the rotated stack, so the island can be along any
            // edge relative to them; `safeAreaInsets` still reports what was
            // ignored, which is exactly the number needed here.
            let controlInsets = Self.controlInsets(rotated: rotation != 0)
            let full = CGRect(origin: .zero, size: geo.size)
            let zoom = Self.expandTransform(
                source: request.sourceFrame,
                full: full,
                aspectRatio: request.aspectRatio,
                progress: expansion
            )
            // The picture GROWS out of the carousel thumbnail rather than
            // sliding up from the bottom, so it reads as the same object
            // getting bigger. The cover itself is presented with animation
            // suppressed (see `GalleryVideoView.expand()`); this is the only
            // motion.
            ZStack {
                // The ground fades in with the growth. At progress 0 it is
                // clear, so the first frame shows the tour page underneath
                // exactly as it was.
                Color.black.opacity(expansion).ignoresSafeArea()
                // Everything the viewer contains — picture AND controls —
                // lives inside the rotated stack. A sideways picture with an
                // upright close button reads as broken.
                ZStack {
                    if let player {
                        FullscreenVideoSurface(player: player)
                            .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                                switch status {
                                case .playing:
                                    isPlaying = true
                                    withAnimation { controlsVisible = false }
                                case .paused:
                                    isPlaying = false
                                    withAnimation { controlsVisible = true }
                                default: break
                                }
                            }
                            .onReceive(
                                NotificationCenter.default.publisher(
                                    for: AVPlayerItem.didPlayToEndTimeNotification,
                                    object: player.currentItem
                                )
                            ) { _ in
                                player.seek(to: .zero)
                                isPlaying = false
                                // Reaching the end is the moment to offer the
                                // controls back, since the picture has stopped.
                                withAnimation { controlsVisible = true }
                            }
                    }
                    controlsLayer(insets: controlInsets)
                }
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(rotation))
                // A rotated frame wider than the screen must not be clipped by
                // the ZStack's own bounds.
                .frame(width: geo.size.width, height: geo.size.height)
                // One uniform transform rather than a re-layout each frame, so
                // the video surface is never asked to resize 60 times a second
                // and the picture cannot distort on the way.
                .scaleEffect(zoom.scale)
                .position(zoom.centre)
            }
            // The window onto the picture, opening from the thumbnail's box to
            // the whole screen. This is what uncrops a filled thumbnail.
            .mask(
                Rectangle()
                    .frame(width: zoom.mask.width, height: zoom.mask.height)
                    .position(x: zoom.mask.midX, y: zoom.mask.midY)
            )
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .task { await prepare() }
        .onAppear {
            withAnimation(Self.expandCurve) { expansion = 1 }
            owesNarrationResume = request.didPauseNarration
            // The device keeps reporting physical orientation while the app is
            // portrait-locked, but only while generation is switched on.
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            deviceOrientation = UIDevice.current.orientation
        }
        .onDisappear {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            player?.pause()
            // The narration debt handed over by the carousel is settled here,
            // and only here — the inline view cleared its own flag as it
            // handed this over precisely so it could not also resume.
            resumeNarrationIfOwed()
        }
        .onChange(of: audioPlayer?.currentTime ?? 0) { _, _ in followNarration() }
        .onChange(of: audioPlayer?.state) { _, _ in followNarration() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let new = UIDevice.current.orientation
            // Face-up / face-down / unknown carry no useful heading — keep the
            // last real one rather than snapping the picture upright when the
            // phone is laid on a table.
            guard new.isPortrait || new.isLandscape else { return }
            withAnimation(.easeInOut(duration: 0.28)) { deviceOrientation = new }
        }
        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
    }

    /// The tour this clip belongs to, when the carousel supplied one.
    private var tour: Tour? {
        guard let id = request.tourId else { return nil }
        return dataService?.tour(by: id)
    }

    /// The viewer's controls, riding inside the rotated stack so they never
    /// read as upright over a sideways picture.
    ///
    /// **Two tiers, deliberately.** The chrome row PERSISTS — owner direction:
    /// the X, the bookmark and the `…` sit where they sit on the tour page and
    /// stay put, because they are how you leave and how you act on the tour,
    /// and hunting for them by tapping is not acceptable. Only the play/pause
    /// hides, so nothing sits over the picture while it runs.
    private func controlsLayer(insets: EdgeInsets) -> some View {
        ZStack {
            // Tapping the picture shows/hides the play control. While it is
            // hidden a tap brings it back rather than toggling playback, so
            // nothing is one accidental tap from stopping.
            // Tap the picture to play or pause — owner, 2026-08-24. This used
            // to only show and hide the controls, which meant the biggest
            // target on screen did the least useful thing. The controls now
            // follow playback instead: hidden while it runs, back when it
            // stops, so nothing sits over a moving picture.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    GalleryVideoView.toggle(
                        role: request.role,
                        videoPlayer: player,
                        isPlaying: isPlaying,
                        tour: tour,
                        audioPlayer: audioPlayer,
                        purchaseService: purchaseService,
                        appShared: appShared
                    )
                }

            VStack(spacing: 0) {
                chromeRow
                Spacer(minLength: 0)
                if tour != nil { identityBlock }
                scrubber
            }
            .padding(insets)
            // 🔴 The chrome is drawn over VIDEO, so it must be light whatever
            // the app's appearance. `AtlasChromeButton` paints `primaryText`,
            // which in light mode is near-black — invisible on a dark clip,
            // which is exactly how it first shipped here. Pinning the scheme
            // resolves the same semantic colours the dark-mode way, so the
            // button keeps its shared shape rather than growing a second one.
            .environment(\.colorScheme, .dark)

            if controlsVisible, request.role != .narration {
                Button {
                    if isPlaying { player?.pause() } else { player?.play() }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.35))
                        .shadow(color: .black.opacity(0.35), radius: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? "Pause video" : "Play video")
                .transition(.opacity)
            }
        }
    }

    /// The tour page's own chrome row, at the tour page's own geometry:
    /// `AtlasChromeButton`s, X leading, bookmark and `…` trailing, `sm`
    /// between them.
    ///
    /// ⚠️ The POSITIONS match `TourDetailView.chromeRow`; the bar behind it
    /// does not, and must not. That page floats its row on a material bar over
    /// a scrolling page. Banding the top of a video the same way would fight
    /// the whole point of fullscreen — Reels and TikTok float their controls
    /// straight on the picture. The buttons carry their own capsule fill, so
    /// they stay legible without one.
    private var chromeRow: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Button(action: collapse) {
                AtlasChromeButton("xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close video")

            Spacer()

            if let tour {
                Button {
                    libraryStore?.toggleSaved(tour.id)
                } label: {
                    AtlasChromeButton(
                        libraryStore?.isSaved(tour.id) == true ? "bookmark.fill" : "bookmark"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    libraryStore?.isSaved(tour.id) == true ? "Remove from saved" : "Save tour"
                )

                Menu {
                    ShareLink(item: AtlasShareLink.tourURL(for: tour)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    AtlasChromeButton("ellipsis")
                }
                .accessibilityLabel("More options")
            }
        }
    }

    /// Where the clip is, and a way to move it.
    ///
    /// 🔴 It reads whichever clock actually drives the picture: a
    /// **narration** clip is slaved to the tour's audio, so the scrubber IS
    /// the tour's scrubber and dragging it moves the sound (the picture
    /// follows). A **gallery** clip owns its own player, so it scrubs that.
    /// Getting this backwards is precisely the complaint that started the
    /// video-role work — a bar that did not match the picture.
    ///
    /// Styled after the full player's: a thin brass line, no thumb knob.
    private var scrubber: some View {
        let total = max(scrubDuration, 0.001)
        let shown = scrubTarget ?? scrubPosition
        let fraction = min(max(shown / total, 0), 1)
        return VStack(spacing: AtlasSpacing.xs) {
            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.28))
                    Capsule().fill(AtlasColors.accent)
                        .frame(width: bar.size.width * fraction)
                }
                .frame(height: 3)
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let f = min(max(g.location.x / bar.size.width, 0), 1)
                            scrubTarget = f * total
                        }
                        .onEnded { g in
                            let f = min(max(g.location.x / bar.size.width, 0), 1)
                            seek(to: f * total)
                            scrubTarget = nil
                        }
                )
            }
            // A tall touch target over a 3pt line — the line is the drawing,
            // not the thing you have to hit.
            .frame(height: 28)

            HStack {
                Text(AtlasFormatters.duration(seconds: Int(shown)))
                Spacer()
                Text(AtlasFormatters.duration(seconds: Int(total)))
            }
            .font(AtlasTypography.caption)
            .foregroundStyle(.white.opacity(0.85))
        }
        .shadow(color: .black.opacity(0.6), radius: 8, y: 1)
        .padding(.top, AtlasSpacing.md)
    }

    /// The clock this clip runs on.
    private var scrubPosition: Double {
        if request.role == .narration { return audioPlayer?.currentTime ?? 0 }
        let t = player?.currentTime().seconds ?? 0
        return t.isFinite ? t : 0
    }

    private var scrubDuration: Double {
        if request.role == .narration { return audioPlayer?.duration ?? 0 }
        return videoDuration
    }

    /// Move whichever clock drives the picture. For a narration clip that is
    /// the tour's audio — the picture catches up on the next follow tick.
    private func seek(to seconds: Double) {
        if request.role == .narration {
            audioPlayer?.seek(to: seconds, precise: true)
        } else {
            player?.seek(
                to: CMTime(seconds: seconds, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }
    }

    /// Creator and title, bottom-left — the block Reels and TikTok both put
    /// there, and the one piece of their layout worth borrowing: over a
    /// full-bleed picture you still need to know whose it is and what it is.
    ///
    /// Their right-hand action rail is deliberately NOT copied: the owner
    /// asked for the tour page's chrome positions, and having save in a rail
    /// here and in the top row one screen back would be the inconsistency this
    /// app keeps having to fix.
    @ViewBuilder
    private var identityBlock: some View {
        if let tour {
            HStack(alignment: .center, spacing: AtlasSpacing.sm) {
                if let maker = dataService?.maker(for: tour) {
                    MakerAvatarView(maker: maker, size: 32)
                }
                VStack(alignment: .leading, spacing: 2) {
                    if let maker = dataService?.maker(for: tour) {
                        Text(maker.displayName)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    Text(tour.title.uppercased())
                        .font(AtlasTypography.body)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            // A scrim rather than a panel: the picture keeps going underneath,
            // which is what stops the block reading as a bar stuck on the end.
            .shadow(color: .black.opacity(0.6), radius: 8, y: 1)
        }
    }

    /// Keep a `.narration` clip on the narration's clock — the same rule the
    /// carousel applies, so the picture does not jump when it is expanded.
    private func followNarration() {
        guard request.role == .narration, let player, let audioPlayer else { return }
        let audioTime = audioPlayer.currentTime
        if GalleryVideoView.shouldResync(
            audioTime: audioTime,
            videoTime: player.currentTime().seconds
        ) {
            player.seek(
                to: CMTime(seconds: audioTime, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }
        let wanted = audioPlayer.state == .playing ? Float(audioPlayer.rate) : 0
        if player.rate != wanted { player.rate = wanted }
    }

    /// Shrink back into the carousel thumbnail, then clear the state.
    ///
    /// The state is cleared inside a transaction with animations suppressed:
    /// otherwise the cover would slide *down* on top of the collapse we just
    /// ran, which reads as two dismissals.
    private func collapse() {
        withAnimation(Self.expandCurve) { expansion = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.collapseSeconds) {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { appShared?.fullscreenVideo = nil }
        }
    }

    /// Builds this view's own player, seeded where the inline one left off.
    ///
    /// Deliberately **not** the inline view's `AVPlayer`. Sharing one player
    /// across two view hierarchies in two windows means the inline view's
    /// `onDisappear` / `isActive` hooks can pause the clip this view is
    /// showing — they fire when the cover goes up. A separate player makes the
    /// handover explicit in both directions instead.
    private func prepare() async {
        guard player == nil, let url = URL(string: request.urlString) else { return }
        let p = AVPlayer(playerItem: AVPlayerItem(asset: AVURLAsset(url: url)))
        if request.startSeconds > 0 {
            await p.seek(
                to: CMTime(seconds: request.startSeconds, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }
        if let d = try? await p.currentItem?.asset.load(.duration),
           CMTimeGetSeconds(d).isFinite {
            videoDuration = CMTimeGetSeconds(d)
        }
        player = p
        // A narration clip is a passenger: muted, and moved only by the tour's
        // clock. It must not take the narration over — it IS the narration —
        // and it must not carry a transport of its own, which would start the
        // content with the paid preview cap unapplied.
        if request.role == .narration {
            p.isMuted = true
            followNarration()
            return
        }
        takeNarrationOverIfNeeded()
        p.play()
    }

    /// A clip with sound pauses the narration; a silent one never touches it.
    /// Only pauses narration that is actually playing, so a tour the user
    /// paused themselves stays paused.
    private func takeNarrationOverIfNeeded() {
        guard Self.shouldTakeOverNarration(
            clipHasAudio: request.hasAudio,
            narrationIsPlaying: audioPlayer?.state == .playing,
            alreadyOwesResume: owesNarrationResume
        ) else { return }
        audioPlayer?.pause()
        owesNarrationResume = true
    }

    private func resumeNarrationIfOwed() {
        guard owesNarrationResume else { return }
        owesNarrationResume = false
        audioPlayer?.play()
    }
}

/// Picture-only surface. Same reasoning as `GalleryVideoView`'s: AVKit's own
/// transport bar installs a pan recognizer across the whole surface, and here
/// that would fight the tap-to-toggle-controls gesture. We draw our own
/// controls instead.
private struct FullscreenVideoSurface: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = false
        // The tour narration owns the lock screen; without this AVKit
        // overwrites now-playing with the untitled clip.
        controller.updatesNowPlayingInfoCenter = false
        controller.view.backgroundColor = .black
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player { controller.player = player }
    }
}

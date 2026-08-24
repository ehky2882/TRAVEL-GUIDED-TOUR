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

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    /// Physical device orientation. Still reported while the app is
    /// portrait-locked, as long as generation is running — see `.onAppear`.
    @State private var deviceOrientation = UIDevice.current.orientation
    /// Narration debt: seeded from the request, then owned here.
    @State private var owesNarrationResume = false
    @State private var controlsVisible = true

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

    /// How far in from the edge the controls sit.
    ///
    /// 🔴 Read from the WINDOW, not from the `GeometryReader`. Once
    /// `.ignoresSafeArea()` is applied the geometry reports insets of zero, so
    /// deriving the number there silently gives a bare 24pt — which puts the
    /// close button's centre at y=46, inside the Dynamic Island's cutout,
    /// where the system takes the touch. The button then draws, sits in the
    /// accessibility tree, and does nothing at all. The window keeps
    /// reporting the device's real insets regardless of what any view ignores.
    ///
    /// A single uniform inset, because the controls ride inside the rotated
    /// stack: relative to them the island can be along any edge.
    static func controlInset(
        insets: UIEdgeInsets? = nil,
        floor: CGFloat = AtlasSpacing.lg
    ) -> CGFloat {
        let resolved = insets ?? (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets)
            ?? .zero
        return max(resolved.top, resolved.bottom, resolved.left, resolved.right, floor)
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
            let controlInset = Self.controlInset()
            ZStack {
                Color.black.ignoresSafeArea()
                // Everything the viewer contains — picture AND controls —
                // lives inside the rotated stack. A sideways picture with an
                // upright close button reads as broken.
                ZStack {
                    if let player {
                        FullscreenVideoSurface(player: player)
                            .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                                switch status {
                                case .playing: isPlaying = true
                                case .paused: isPlaying = false
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
                    controlsLayer(inset: controlInset)
                }
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(rotation))
                // A rotated frame wider than the screen must not be clipped by
                // the ZStack's own bounds.
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .task { await prepare() }
        .onAppear {
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

    /// Close + play/pause, riding inside the rotated stack.
    private func controlsLayer(inset: CGFloat) -> some View {
        ZStack {
            // Tap the picture to show/hide the controls; while they are hidden
            // a tap brings them back rather than toggling playback, so nothing
            // is one accidental tap from stopping.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { controlsVisible.toggle() } }

            if controlsVisible {
                VStack {
                    HStack {
                        Button {
                            appShared?.fullscreenVideo = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.45), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close video")
                        Spacer()
                    }
                    Spacer()
                }
                .padding(inset)
                .transition(.opacity)

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
        player = p
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

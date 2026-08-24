import SwiftUI
import AVKit
import AVFoundation
import Combine

/// One video page inside the tour-detail / player photo carousel.
///
/// Videos live alongside images in the gallery. Since 2026-07-26 a
/// tour's `videoURLs` render **first**, so a tour that has a video opens
/// on it — see `TourMediaCarousel`. This view is the per-page renderer:
/// the video sized to the same hero frame as `HeroImageView` and
/// letterboxed on black (aspect-fit, so video is never cropped the way
/// a fill-scaled photo would be).
///
/// **Custom controls, deliberately** (owner decision, 2026-07-26). This
/// used to be AVKit's `VideoPlayer`, whose built-in transport bar
/// installs a pan recognizer across the whole video surface. Inside a
/// paged `TabView` that recognizer **swallows horizontal swipes** — it
/// scrubs instead of paging — so once a video was on screen the user
/// could not swipe to the photos at all. Verified in the simulator: with
/// the video leading, both flicks and slow drags scrubbed and the
/// carousel never advanced. We therefore host `AVPlayerViewController`
/// with `showsPlaybackControls = false` and supply our own tap-to-play
/// affordance. With no built-in recognizer the drag falls through to the
/// TabView and paging works; the trade-off the owner accepted is that
/// gallery videos have no scrubber and no fullscreen button — they
/// behave like a tappable moving photo, which is the right register for
/// short b-roll.
///
/// **No autoplay.** The user taps to start — this is an *audio*-tour
/// app, so a video that starts itself would fight the narration.
///
/// **Audio interaction — "take over, then resume"** (owner decision,
/// 2026-07-19):
///   - A clip that **has its own audio track** pauses the tour narration
///     when it starts playing, and the narration **auto-resumes** when
///     the clip ends, is paused, or the user swipes away / closes.
///   - A **silent** clip (no audio track — b-roll, an animated shot)
///     **never** touches the narration: it plays as moving imagery while
///     the narration keeps going, exactly like a photo. This is why we
///     detect the audio track (`hasAudio`) before deciding to pause.
///
/// We only resume narration we ourselves paused (`didPauseNarration`),
/// and only if it was actually playing at takeover — so a tour the user
/// had already paused stays paused.
struct GalleryVideoView: View {
    let urlString: String
    let height: CGFloat?
    /// True when this page is the currently-visible carousel page.
    /// The carousel flips this to `false` when the user swipes away,
    /// so a hidden video doesn't keep playing audio behind another
    /// page (and its narration resumes). Defaults true for standalone
    /// use.
    var isActive: Bool = true

    /// Optional so any presentation path that doesn't inject the
    /// player (there shouldn't be one — it's app-wide + injected into
    /// the UIKit slide-up layers) can't crash on a required lookup.
    @Environment(AudioPlayerService.self) private var audioPlayer: AudioPlayerService?

    @State private var player: AVPlayer?
    /// Whether this clip carries an audio track. Determined async after
    /// the asset loads. Starts `false` so a clip whose tracks haven't
    /// resolved yet won't pre-emptively pause the narration.
    @State private var hasAudio = false
    /// True while the narration is paused *because of this video*, so we
    /// know to resume it (and don't resume a tour the user had paused
    /// themselves).
    @State private var didPauseNarration = false
    /// Drives the play affordance. Mirrors `timeControlStatus` rather
    /// than being set by the tap, so it stays honest if playback stalls
    /// or ends on its own.
    @State private var isPlaying = false
    /// Clip shape as *displayed* (after `preferredTransform`). Resolved with
    /// `hasAudio` in `prepare()` and handed to the fullscreen viewer so it
    /// opens in the right orientation immediately rather than resolving the
    /// asset a second time.
    @State private var isLandscape = true
    /// Displayed width ÷ height, resolved with `isLandscape` in `prepare()`.
    /// Lets the fullscreen viewer grow from exactly the picture you tapped.
    @State private var aspectRatio: CGFloat = 4.0 / 3.0
    /// This page's frame on screen, in global coordinates — handed to the
    /// viewer so it can grow out of exactly where the clip already is.
    @State private var frameOnScreen: CGRect = .zero

    /// Optional for the same reason `audioPlayer` is: not every presentation
    /// path injects it. Without it the expand button simply isn't offered.
    @Environment(AppSharedState.self) private var appShared: AppSharedState?

    var body: some View {
        ZStack {
            Color.black
            if let player {
                VideoSurface(player: player)
                    .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                        switch status {
                        case .playing:
                            isPlaying = true
                            pauseNarrationIfNeeded()
                        case .paused:
                            // Fires on user-pause and on reaching the end
                            // (AVPlayer stops → .paused). Either way, hand
                            // the audio back to the narration.
                            isPlaying = false
                            resumeNarrationIfNeeded()
                        default:
                            break // .waitingToPlayAtSpecifiedRate (buffering)
                        }
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(
                            for: AVPlayerItem.didPlayToEndTimeNotification,
                            object: player.currentItem
                        )
                    ) { _ in
                        // Rewind so the next tap replays instead of
                        // sitting on the last frame doing nothing.
                        player.seek(to: .zero)
                        isPlaying = false
                    }
            }
            playAffordance
        }
        .frame(maxWidth: .infinity)
        .atlasHeroSizing(height)
        .background(Color.black)
        .clipped()
        // Tap anywhere to pause while playing. A tap gesture (unlike
        // AVKit's transport bar) doesn't claim the horizontal drag, so
        // the carousel can still page. Starting playback goes through
        // the explicit button below rather than this, so there's a real
        // control in the accessibility tree.
        .contentShape(Rectangle())
        .onTapGesture { if isPlaying { player?.pause() } }
        // 🔴 TOP-trailing, and the corner matters. At the BOTTOM the button
        // rendered, appeared in the accessibility tree, and its action never
        // ran: a paged `TabView` draws its `UIPageControl` across the FULL
        // width of the strip where the dots sit, and a tap on that control's
        // right half advances a page. So the tap paged the carousel instead —
        // the page control is part of the TabView and hit-tests above page
        // content, whatever the page draws on top. Verified with a probe:
        // `expand()` was never reached, and the carousel advanced by exactly
        // one page every time. Applied as an overlay (rather than inside the
        // ZStack) so it also sits above the surface tap gesture below.
        .overlay(alignment: .topTrailing) { expandAffordance }
        // Global, because the viewer is presented in a different window. Both
        // are full-screen on the same scene, so the coordinates line up.
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frameOnScreen = $0 }
        .task(id: urlString) {
            await prepare()
        }
        .onChange(of: isActive) { _, active in
            if !active {
                player?.pause()
                resumeNarrationIfNeeded()
            }
        }
        .onDisappear {
            player?.pause()
            resumeNarrationIfNeeded()
        }
    }

    /// The only control: a play button while paused. Hidden during
    /// playback so nothing sits over the picture. A real `Button` (not a
    /// bare glyph + surface tap) so it lands in the accessibility tree
    /// as a control — VoiceOver reaches it, and it's a definite hit
    /// target rather than relying on the whole surface.
    @ViewBuilder
    private var playAffordance: some View {
        if !isPlaying {
            Button {
                player?.play()
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 52))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.35))
                    .shadow(color: .black.opacity(0.35), radius: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play video")
            .transition(.opacity)
        }
    }

    /// Expand to fullscreen.
    ///
    /// **A corner button, deliberately not the surface tap** — the surface tap
    /// is already pause-while-playing, and a real `Button` lands in the
    /// accessibility tree so VoiceOver reaches it. Being a small corner target
    /// it also cannot claim the horizontal drag the carousel needs for paging,
    /// which is the whole reason this view draws its own controls rather than
    /// using AVKit's.
    ///
    /// Stays visible during playback — unlike the play glyph, which hides so
    /// nothing sits over the picture — because expanding *while watching* is
    /// the common case.
    @ViewBuilder
    private var expandAffordance: some View {
        if appShared != nil {
            Button(action: expand) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    // 44pt is the app's universal control diameter (map
                    // controls, the tour action row, the chrome capsules).
                    // The painted disc is smaller; the target is not.
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.black.opacity(0.45))
                            .frame(width: 32, height: 32)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Expand video to fullscreen")
            .padding(AtlasSpacing.xs)
        }
    }

    /// Hand the clip to the fullscreen viewer.
    ///
    /// 🔴 **The narration debt is TRANSFERRED, not copied.** Clearing
    /// `didPauseNarration` as we hand it over is what stops this view resuming
    /// the tour audio behind the video: presenting a cover trips at least one
    /// of the three `resumeNarrationIfNeeded()` call sites (the
    /// `timeControlStatus` change from the pause below, `isActive`, and
    /// `onDisappear`), and every one of them is guarded on that flag. With the
    /// flag cleared they all become no-ops, and the fullscreen view owes the
    /// resume instead. Suppressing the call sites individually would leave the
    /// next one added unguarded.
    private func expand() {
        guard let appShared else { return }
        let at = player?.currentTime().seconds ?? 0
        // Pause the inline clip: the fullscreen view runs its own player, and
        // two players on one clip with sound would talk over each other.
        player?.pause()
        let debt = didPauseNarration
        didPauseNarration = false
        let request = FullscreenVideoRequest(
            urlString: urlString,
            startSeconds: at.isFinite ? max(0, at) : 0,
            hasAudio: hasAudio,
            didPauseNarration: debt,
            isLandscape: isLandscape,
            aspectRatio: aspectRatio,
            sourceFrame: frameOnScreen
        )
        // 🔴 Presented with animation SUPPRESSED. A `fullScreenCover` slides up
        // from the bottom by default, and the viewer's own growth out of this
        // thumbnail would then run on top of that slide — two motions at once.
        // The growth is the only animation the expand should have.
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { appShared.fullscreenVideo = request }
    }

    /// Builds the player and detects whether the clip has an audio
    /// track. Runs on the main actor (`.task`), so the `@State`
    /// mutations are safe. `hasAudio` stays `false` if the load is
    /// cancelled or fails — the conservative default (no takeover).
    private func prepare() async {
        guard player == nil, let url = URL(string: urlString) else { return }
        let asset = AVURLAsset(url: url)
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        if let tracks = try? await asset.loadTracks(withMediaType: .audio) {
            hasAudio = !tracks.isEmpty
        }
        // Shape for the fullscreen viewer. ⚠️ Must come from the DISPLAY size
        // — phone video is commonly 1920x1080 stored with a 90 degree
        // `preferredTransform`, and reading `naturalSize` alone would call
        // that vertical clip landscape and rotate it the wrong way.
        if let video = try? await asset.loadTracks(withMediaType: .video).first,
           let size = try? await video.load(.naturalSize),
           let transform = try? await video.load(.preferredTransform) {
            isLandscape = FullscreenVideoView.isLandscape(
                naturalSize: size,
                preferredTransform: transform
            )
            let display = size.applying(transform)
            if abs(display.height) > 0 {
                aspectRatio = abs(display.width) / abs(display.height)
            }
        }
    }

    /// Pause the narration when a clip *with sound* starts — but only if
    /// the narration is actually playing, so we never fight a tour the
    /// user deliberately paused.
    private func pauseNarrationIfNeeded() {
        // One rule, shared with the fullscreen viewer so the two cannot drift.
        guard FullscreenVideoView.shouldTakeOverNarration(
            clipHasAudio: hasAudio,
            narrationIsPlaying: audioPlayer?.state == .playing,
            alreadyOwesResume: didPauseNarration
        ) else { return }
        audioPlayer?.pause()
        didPauseNarration = true
    }

    /// Resume the narration we paused. Idempotent — the flag guard means
    /// the several call sites (end, user-pause, swipe-away, disappear)
    /// can all fire without double-resuming.
    private func resumeNarrationIfNeeded() {
        guard didPauseNarration else { return }
        didPauseNarration = false
        audioPlayer?.play()
    }
}

/// Bare video surface — `AVPlayerViewController` with its transport bar
/// switched off. See `GalleryVideoView`'s note: the built-in controls
/// install a pan recognizer that steals the carousel's paging swipe, so
/// we render picture only and drive playback ourselves.
private struct VideoSurface: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        // 🔴 FILL, not fit — owner decision. In the square carousel box a
        // letterboxed vertical clip used barely half the frame and the rest
        // was black. Filling makes the clip read like the photographs it sits
        // beside, which are also fill-cropped into this box. The cost is that
        // the top and bottom of a vertical clip are cropped here — which is
        // precisely what the expand button is for: fullscreen fits, so
        // nothing is cut off once you open it.
        controller.videoGravity = .resizeAspectFill
        controller.allowsPictureInPicturePlayback = false
        // The tour narration owns the lock screen. Without this, AVKit
        // overwrites the now-playing info with the (untitled) clip.
        controller.updatesNowPlayingInfoCenter = false
        controller.view.backgroundColor = .black
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player {
            controller.player = player
        }
    }
}

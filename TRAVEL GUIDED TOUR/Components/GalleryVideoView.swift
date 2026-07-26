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
    let height: CGFloat
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
        .frame(height: height)
        .background(Color.black)
        .clipped()
        // Tap anywhere to pause while playing. A tap gesture (unlike
        // AVKit's transport bar) doesn't claim the horizontal drag, so
        // the carousel can still page. Starting playback goes through
        // the explicit button below rather than this, so there's a real
        // control in the accessibility tree.
        .contentShape(Rectangle())
        .onTapGesture { if isPlaying { player?.pause() } }
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
    }

    /// Pause the narration when a clip *with sound* starts — but only if
    /// the narration is actually playing, so we never fight a tour the
    /// user deliberately paused.
    private func pauseNarrationIfNeeded() {
        guard hasAudio, !didPauseNarration else { return }
        guard audioPlayer?.state == .playing else { return }
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
        controller.videoGravity = .resizeAspect
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

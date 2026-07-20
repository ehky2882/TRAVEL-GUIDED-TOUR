import SwiftUI
import AVKit
import AVFoundation
import Combine

/// One video page inside the tour-detail / player photo carousel.
///
/// Videos live alongside images in the gallery (owner decision,
/// 2026-07-19): a tour's `videoURLs` render as extra swipeable pages
/// after the photos. This view is the per-page renderer — a system
/// `VideoPlayer` (AVKit) with its standard transport controls, sized
/// to the same hero frame as `HeroImageView` and letterboxed on black
/// (aspect-fit, so video is never cropped the way a fill-scaled photo
/// would be).
///
/// **No autoplay.** The user taps the play button to start — this is an
/// *audio*-tour app, so a video that starts itself would fight the
/// narration.
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

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                        switch status {
                        case .playing:
                            pauseNarrationIfNeeded()
                        case .paused:
                            // Fires on user-pause and on reaching the end
                            // (AVPlayer stops → .paused). Either way, hand
                            // the audio back to the narration.
                            resumeNarrationIfNeeded()
                        default:
                            break // .waitingToPlayAtSpecifiedRate (buffering)
                        }
                    }
            } else {
                // Brief black placeholder before the player is built —
                // matches the letterbox background so there's no flash.
                Rectangle().fill(Color.black)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color.black)
        .clipped()
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

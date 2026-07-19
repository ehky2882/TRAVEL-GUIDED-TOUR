import SwiftUI
import AVKit
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
/// narration. When the user *does* start a gallery video we pause the
/// tour narration (`AudioPlayerService.pause()`) so two audio sources
/// never talk over each other. `isActive` tracks whether this is the
/// visible carousel page; swiping to another page pauses the video.
struct GalleryVideoView: View {
    let urlString: String
    let height: CGFloat
    /// True when this page is the currently-visible carousel page.
    /// The carousel flips this to `false` when the user swipes away,
    /// so a hidden video doesn't keep playing audio behind another
    /// page. Defaults true for standalone use.
    var isActive: Bool = true

    /// Optional so any presentation path that doesn't inject the
    /// player (there shouldn't be one — it's app-wide + injected into
    /// the UIKit slide-up layers) can't crash on a required lookup.
    /// When present, we pause the narration the moment the video
    /// starts producing sound.
    @Environment(AudioPlayerService.self) private var audioPlayer: AudioPlayerService?

    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                        if status == .playing {
                            audioPlayer?.pause()
                        }
                    }
            } else {
                // Brief black placeholder before the player is built
                // in `.onAppear` — matches the letterbox background so
                // there's no flash.
                Rectangle().fill(Color.black)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color.black)
        .clipped()
        .onAppear {
            if player == nil, let url = URL(string: urlString) {
                player = AVPlayer(url: url)
            }
        }
        .onChange(of: isActive) { _, active in
            if !active { player?.pause() }
        }
        .onDisappear {
            player?.pause()
        }
    }
}

import Foundation
import AVFoundation
import Observation

/// Plays back the audio already attached to a tour, from inside the editor.
///
/// **Why this exists.** The editor showed "Audio added · 2m 43s" and gave no way
/// to hear it. The only way to check what you had actually attached was to
/// re-record it.
///
/// **Deliberately NOT `AudioPlayerService`.** That is the app's single tour
/// player — it owns the mini-player, the lock screen, now-playing info and the
/// geofence hand-off. Auditioning your own draft in the authoring editor should
/// not put a half-finished tour on the lock screen or hijack the mini-player, so
/// this is a small separate `AVPlayer`.
///
/// **Not `AVAudioPlayer` either**, which cannot stream a remote URL — attached
/// audio lives on Supabase Storage, so it is an https URL, not a local file.
@MainActor
@Observable
final class AuthoringAudioPreview {
    private(set) var isPlaying = false
    /// Seconds elapsed, for the little counter next to the button.
    private(set) var elapsed: TimeInterval = 0

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var currentURL: URL?

    /// Play this URL, or pause if it's already the one playing.
    func toggle(url: URL) {
        if isPlaying, currentURL == url {
            pause()
        } else if currentURL == url, let player {
            player.play()
            isPlaying = true
        } else {
            start(url: url)
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// Tear everything down — call when the editor goes away, or a preview keeps
    /// playing over whatever the user opens next.
    func stop() {
        removeObservers()
        player?.pause()
        player = nil
        currentURL = nil
        isPlaying = false
        elapsed = 0
    }

    private func start(url: URL) {
        removeObservers()
        let player = AVPlayer(url: url)
        self.player = player
        currentURL = url
        elapsed = 0

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.elapsed = time.seconds.isFinite ? time.seconds : 0
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            // Rewind rather than leave it parked at the end, so a second tap
            // replays instead of doing nothing.
            Task { @MainActor in
                guard let self else { return }
                self.player?.seek(to: .zero)
                self.isPlaying = false
                self.elapsed = 0
            }
        }

        player.play()
        isPlaying = true
    }

    private func removeObservers() {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
    }
}

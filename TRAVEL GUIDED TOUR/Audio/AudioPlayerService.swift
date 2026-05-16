import Foundation
import AVFoundation
import MediaPlayer
import Observation

@Observable
final class AudioPlayerService {
    enum PlaybackState {
        case idle
        case loading
        case playing
        case paused
        case ended
    }

    private(set) var state: PlaybackState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var currentTitle: String?
    private(set) var currentArtist: String?
    private(set) var rate: Float = 1.0

    private let player = AVQueuePlayer()
    private var timeObserverToken: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    init() {
        configureAudioSession()
        wireRemoteCommands()
        observePlayerStatus()
        observePeriodicTime()
        observePlaybackEnd()
    }

    deinit {
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    // MARK: - Public API

    func play(url: URL, title: String?, artist: String?) {
        currentTitle = title
        currentArtist = artist
        currentTime = 0
        duration = 0
        state = .loading

        let item = AVPlayerItem(url: url)
        player.removeAllItems()
        player.insert(item, after: nil)
        player.play()
        // Restore the user's chosen rate. AVPlayer.play() resets rate to 1.0,
        // so we re-apply on the next runloop tick after play() takes effect.
        if rate != 1.0 {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.player.rate = self.rate
            }
        }
        updateNowPlayingInfo()
    }

    func play() {
        player.play()
        // Same rate-restore as play(url:title:artist:) — resume should
        // honor the user's last speed selection.
        if rate != 1.0 {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.player.rate = self.rate
            }
        }
    }

    func setPlaybackRate(_ newRate: Float) {
        rate = newRate
        if state == .playing {
            player.rate = newRate
        }
        updateNowPlayingInfo()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
        player.removeAllItems()
        currentTime = 0
        duration = 0
        currentTitle = nil
        currentArtist = nil
        state = .idle
        updateNowPlayingInfo()
    }

    func seek(to time: TimeInterval) {
        let target = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: target)
    }

    func skip(by seconds: TimeInterval) {
        let target = max(0, min(currentTime + seconds, duration))
        seek(to: target)
    }

    // MARK: - Configuration

    private func configureAudioSession() {
        #if os(iOS) || os(visionOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("AudioPlayerService: failed to configure audio session: \(error)")
            #endif
        }
        #endif
    }

    private func wireRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            if self.state == .playing {
                self.pause()
            } else {
                self.play()
            }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skip(by: 15)
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skip(by: -15)
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    private func observePlayerStatus() {
        statusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.state = .playing
                case .paused:
                    // AVPlayer briefly reports .paused during load and after end.
                    // Preserve .idle (no item), .loading (in-flight play(url:)),
                    // and .ended (playback finished) through those transient reports.
                    switch self.state {
                    case .idle, .loading, .ended:
                        break
                    case .playing, .paused:
                        self.state = .paused
                    }
                case .waitingToPlayAtSpecifiedRate:
                    self.state = .loading
                @unknown default:
                    break
                }
                self.updateNowPlayingInfo()
            }
        }
    }

    private func observePeriodicTime() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            // Ignore observer reports during a load. AVQueuePlayer can
            // briefly report the *previous* item's currentTime + duration
            // between `removeAllItems()` and the new item becoming
            // current — that would clobber the 0/0 reset done in
            // `play(url:title:artist:)` and make the scrub bar jump
            // back to the old stop's position. Once the new item is
            // ready, `timeControlStatus` transitions to `.playing` and
            // the observer takes over with valid values.
            if self.state == .loading { return }
            self.currentTime = time.seconds.isFinite ? time.seconds : 0
            if let item = self.player.currentItem {
                let itemDuration = item.duration
                if itemDuration.isNumeric {
                    self.duration = itemDuration.seconds
                }
            }
        }
    }

    private func observePlaybackEnd() {
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.state = .ended
            self?.updateNowPlayingInfo()
        }
    }

    private func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        if let title = currentTitle {
            info[MPMediaItemPropertyTitle] = title
        }
        if let artist = currentArtist {
            info[MPMediaItemPropertyArtist] = artist
        }
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = state == .playing ? Double(rate) : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

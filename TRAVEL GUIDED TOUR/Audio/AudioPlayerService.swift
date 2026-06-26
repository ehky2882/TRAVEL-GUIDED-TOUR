import Foundation
import AVFoundation
import MediaPlayer
import Observation
#if canImport(UIKit)
import UIKit
#endif

@Observable
final class AudioPlayerService {
    enum PlaybackState {
        case idle
        case loading
        case playing
        case paused
        case ended
        /// Audio failed to load (DNS failure, 4xx/5xx, or our own
        /// `loadingTimeoutSeconds` watchdog firing because the asset
        /// took too long). `lastError` carries detail. UI should
        /// re-enable the play/start button so the user can retry.
        case failed
    }

    private(set) var state: PlaybackState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var currentTitle: String?
    private(set) var currentArtist: String?
    /// Opaque identifier for the *source* of the current audio, set
    /// by the caller of `play(url:title:artist:sourceId:)`. Tour
    /// surfaces (TourDetailView / PlayerView) pass the tour's UUID
    /// string so they can answer "is this player currently mine?"
    /// without relying on title equality — which broke when two
    /// tours shared a title (audit P1-3).
    private(set) var currentSourceId: String?
    private(set) var rate: Float = 1.0
    #if canImport(UIKit)
    /// Lock-screen / Control-Center artwork for the current item —
    /// the tour maker's avatar. Resolved off the main UI (the maker
    /// avatar can be a remote URL, an emoji, or the bundled studio
    /// mark) and pushed in via `setArtwork(_:for:)`; held here so
    /// every `updateNowPlayingInfo()` re-attaches it. Cleared on each
    /// new `play(url:…)` so a stale avatar never lingers across tours.
    private var nowPlayingArtwork: MPMediaItemArtwork?
    #endif
    /// Populated when `state == .failed`; cleared on the next
    /// successful `play(url:...)`. The watchdog timeout produces a
    /// generic error; AVPlayer's reported failures preserve
    /// `AVPlayerItem.error`.
    private(set) var lastError: Error?

    private let player = AVQueuePlayer()
    private var timeObserverToken: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    /// Observers for audio-session interruption (phone calls, Siri,
    /// other audio apps) and route changes (headphones unplugged,
    /// AirPods disconnected). Both are iOS/visionOS-only — macOS
    /// doesn't expose AVAudioSession.
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    /// KVO on the current `AVPlayerItem`'s `status`. Lets us catch
    /// `.failed` for the *item* (unreachable host, bad codec, etc.) —
    /// AVPlayer's `timeControlStatus` doesn't surface that distinctly.
    /// Recreated every `play(url:...)` for the new item; invalidated
    /// when superseded or in `deinit`.
    private var itemStatusObserver: NSKeyValueObservation?
    /// Watchdog: if `state` is still `.loading` after this many seconds,
    /// transition to `.failed`. Without this, AVPlayer can sit in
    /// `.waitingToPlayAtSpecifiedRate` indefinitely on a stalled host.
    private let loadingTimeoutSeconds: TimeInterval = 10
    private var loadingTimeoutTask: Task<Void, Never>?
    /// True between `play(url:...)` and the first time AVPlayer reports
    /// it's actually `.playing`. While this is true the periodic time
    /// observer is suppressed — AVQueuePlayer can briefly report the
    /// *previous* item's currentTime/duration between `removeAllItems()`
    /// and the new item becoming current, which would clobber the 0/0
    /// reset done in `play(url:title:artist:)`. After the first
    /// `.playing` transition we trust the observer, so subsequent
    /// scrubs and pause/resume don't fight it.
    private var isAwaitingFirstPlayTransition = false
    /// URL handed to the most recent `play(url:title:artist:sourceId:)`.
    /// Retained so callers can re-trigger the same item without
    /// re-deriving the URL from the tour model — used by the
    /// mini-player's tap-to-replay path after `.ended`.
    private var lastPlayedURL: URL?

    init() {
        configureAudioSession()
        wireRemoteCommands()
        observePlayerStatus()
        observePeriodicTime()
        observePlaybackEnd()
        observeAudioSessionEvents()
    }

    deinit {
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        if let routeChangeObserver {
            NotificationCenter.default.removeObserver(routeChangeObserver)
        }
        itemStatusObserver?.invalidate()
        loadingTimeoutTask?.cancel()
    }

    // MARK: - Public API

    func play(url: URL, title: String?, artist: String?, sourceId: String? = nil) {
        // Tear down anything attached to the previous item.
        cancelLoadingTimeout()
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil

        currentTitle = title
        currentArtist = artist
        currentSourceId = sourceId
        #if canImport(UIKit)
        // Drop the previous tour's avatar immediately; the host
        // re-resolves and re-attaches one via setArtwork(_:for:).
        nowPlayingArtwork = nil
        #endif
        lastPlayedURL = url
        currentTime = 0
        duration = 0
        lastError = nil
        state = .loading
        isAwaitingFirstPlayTransition = true

        let item = AVPlayerItem(url: url)

        // Observe the new item's status so we catch AVPlayer-reported
        // load failures (unreachable host, bad codec, etc.). The
        // `.readyToPlay` case is handled implicitly by the player's
        // `timeControlStatus` transitioning to `.playing`.
        itemStatusObserver = item.observe(\.status, options: [.new]) { [weak self] observedItem, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if observedItem.status == .failed {
                    self.lastError = observedItem.error
                    self.state = .failed
                    self.cancelLoadingTimeout()
                    self.updateNowPlayingInfo()
                }
            }
        }

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

        startLoadingTimeout()
        updateNowPlayingInfo()
    }

    func play() {
        // Re-activate the audio session before resuming. If the session
        // was deactivated while backgrounded (e.g. lock screen + another
        // app taking audio focus), player.play() silently fails without
        // this call — the remote-command play tap appears to "work" but
        // audio never starts and the now-playing slot reverts to Spotify.
        #if os(iOS) || os(visionOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
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
        cancelLoadingTimeout()
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil

        player.pause()
        player.removeAllItems()
        currentTime = 0
        duration = 0
        currentTitle = nil
        currentArtist = nil
        currentSourceId = nil
        lastPlayedURL = nil
        lastError = nil
        state = .idle
        isAwaitingFirstPlayTransition = false
        updateNowPlayingInfo()
    }

    /// Replays the most recent item from the beginning, reusing the
    /// last title / artist / sourceId. No-op if nothing has been
    /// played yet. Used by the mini-player when the user taps play
    /// after a tour has reached `.ended`: AVQueuePlayer auto-drains
    /// its queue at end-of-item, so a parameterless `play()` would
    /// have nothing to resume.
    func replayLast() {
        guard let url = lastPlayedURL else { return }
        play(url: url, title: currentTitle, artist: currentArtist, sourceId: currentSourceId)
    }

    func seek(to time: TimeInterval) {
        let target = CMTime(seconds: time, preferredTimescale: 600)
        // Update the published currentTime immediately so the UI
        // snaps to the new position the moment the user releases the
        // scrub thumb. The periodic time observer takes over from
        // there as AVPlayer resumes reporting time.
        currentTime = time
        player.seek(to: target)

        // Seek-to-end (or beyond) doesn't fire
        // `AVPlayerItem.didPlayToEndTime` — that notification only
        // arrives when AVPlayer reaches the end via continuous
        // playback. Without this synthesized `.ended` transition,
        // AVPlayer parks in `.waitingToPlayAtSpecifiedRate` after a
        // seek-to-end and our observer would flip state to `.loading`,
        // leaving the mini- and full-player stuck on hourglass /
        // "Loading…". Mirror the natural end semantics: pause the
        // player and publish `.ended` so the play button reverts to
        // play.fill and tap-to-replay works.
        if duration > 0 && time >= duration - 0.1 {
            player.pause()
            currentTime = duration
            state = .ended
            cancelLoadingTimeout()
            updateNowPlayingInfo()
        }
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
                    self.isAwaitingFirstPlayTransition = false
                    self.cancelLoadingTimeout()
                case .paused:
                    // AVPlayer briefly reports .paused during load and after end.
                    // Preserve .idle (no item), .loading (in-flight play(url:)),
                    // .ended (playback finished), and .failed through those
                    // transient reports.
                    switch self.state {
                    case .idle, .loading, .ended, .failed:
                        break
                    case .playing, .paused:
                        self.state = .paused
                        self.cancelLoadingTimeout()
                    }
                case .waitingToPlayAtSpecifiedRate:
                    // Only treat this as `.loading` from states where
                    // we expect AVPlayer to actually start producing
                    // audio. Terminal states (`.failed`, `.ended`) and
                    // `.idle` must be preserved: AVPlayer keeps emitting
                    // `.waitingToPlayAtSpecifiedRate` after a failure
                    // *and* after end-of-item, so blindly setting
                    // `.loading` would snap the UI back to the hourglass
                    // and the "Loading…" subtitle moments after the
                    // item-status KVO or `didPlayToEndTime` notification
                    // moved us off `.loading`.
                    switch self.state {
                    case .failed, .ended, .idle:
                        break
                    case .loading, .playing, .paused:
                        self.state = .loading
                    }
                @unknown default:
                    break
                }
                self.updateNowPlayingInfo()
            }
        }
    }

    private func startLoadingTimeout() {
        loadingTimeoutTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.loadingTimeoutSeconds))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                // Only fire if we're still actually stuck loading.
                guard self.state == .loading else { return }
                self.lastError = NSError(
                    domain: "AudioPlayerService",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Audio took longer than \(Int(self.loadingTimeoutSeconds)) seconds to load."
                    ]
                )
                self.state = .failed
                self.updateNowPlayingInfo()
            }
        }
    }

    private func cancelLoadingTimeout() {
        loadingTimeoutTask?.cancel()
        loadingTimeoutTask = nil
    }

    private func observePeriodicTime() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            // Ignore observer reports during the *first-load* window
            // (the gap between `removeAllItems()` and the new item
            // becoming current) — without this the scrub bar would
            // briefly show the previous stop's position. Once AVPlayer
            // reports `.playing` for the first time we trust the
            // observer for everything after (scrubs, pause/resume,
            // etc.). Also skip when the item has failed outright.
            if self.isAwaitingFirstPlayTransition || self.state == .failed { return }
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

    /// Wires interruption + route-change handling so:
    ///   - Phone calls / Siri / other audio apps pause this player,
    ///     and resume it on interruption end if the system indicates
    ///     `.shouldResume` (audit P1-5).
    ///   - Headphone unplug / AirPods disconnect pauses playback per
    ///     Apple HIG — never blast a walking tour through the
    ///     iPhone speaker (audit P1-6).
    private func observeAudioSessionEvents() {
        #if os(iOS) || os(visionOS)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
        #endif
    }

    #if os(iOS) || os(visionOS)
    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        switch type {
        case .began:
            // System has already paused our audio. Sync our published
            // state so the UI's play/pause icon matches; don't call
            // `pause()` on the player — that's redundant.
            if state == .playing {
                state = .paused
                updateNowPlayingInfo()
            }
        case .ended:
            // Resume only if iOS hints we should (e.g., a short Siri
            // interruption ends with `.shouldResume`; a phone call
            // typically does not).
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                play()
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        // Apple HIG: pause when the audio's old route becomes
        // unavailable (headphones unplugged, AirPods removed). Any
        // other route-change reason is a no-op — adding a new device
        // shouldn't change playback state.
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }
    #endif

    #if canImport(UIKit)
    /// Set the lock-screen artwork (the maker avatar) for the tour
    /// identified by `sourceId`. The host resolves the avatar image
    /// asynchronously, so by the time it returns the user may have
    /// started a different tour — the `sourceId` guard drops a
    /// resolution that's no longer for the current item. Pass `nil`
    /// image to clear.
    func setArtwork(_ image: UIImage?, for sourceId: String?) {
        guard sourceId == currentSourceId else { return }
        if let image {
            nowPlayingArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        } else {
            nowPlayingArtwork = nil
        }
        updateNowPlayingInfo()
    }
    #endif

    private func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        if let title = currentTitle {
            info[MPMediaItemPropertyTitle] = title
        }
        if let artist = currentArtist {
            info[MPMediaItemPropertyArtist] = artist
        }
        #if canImport(UIKit)
        if let nowPlayingArtwork {
            info[MPMediaItemPropertyArtwork] = nowPlayingArtwork
        }
        #endif
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = state == .playing ? Double(rate) : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

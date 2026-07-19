import Foundation
import Observation

/// The Group Listen sync engine (design: `docs/group-listen-design.md` §3–4).
/// Transport-agnostic: the **leader** samples its own player + broadcasts a
/// tiny `GroupPlaybackState`; each **follower** applies it (load the right
/// stop, seek, play/pause, correct drift). The leader model dissolves the
/// geofence-vs-sync conflict — a follower's geofence monitoring is turned OFF
/// and it only mirrors the leader.
///
/// Built once at app launch and injected via environment; its service
/// dependencies are wired in `attach(...)` from the App `.task` (so it can
/// capture the same live `@State` instances the rest of the app uses).
@MainActor
@Observable
final class GroupListenCoordinator {
    // MARK: - Published (drives the sheet + banner)

    /// nil = not in a session. `.leader` drives; `.follower` mirrors.
    private(set) var role: GroupRole?
    /// The join code — the leader shares it; a follower shows the one it joined.
    private(set) var code: String?
    /// Everyone else connected (self excluded).
    private(set) var participants: [Participant] = []
    /// Follower only: the leader's display name (from the roster).
    private(set) var leaderName: String?
    /// The tour the group is on (leader sets it; follower resolves from state).
    private(set) var activeTour: Tour?
    /// Set when the leader drops (follower side) — the banner shows "Leader left".
    private(set) var leaderLost = false

    var isActive: Bool { role != nil }
    var isLeader: Bool { role == .leader }
    /// Total people in the session, including self.
    var participantCount: Int { participants.count + (isActive ? 1 : 0) }

    // MARK: - Dependencies (wired via attach)

    private var audioPlayer: AudioPlayerService?
    private var appShared: AppSharedState?
    private var dataService: DataService?
    private var tourDownloader: TourDownloader?
    private var proximityMonitor: ProximityMonitor?
    private var auth: AuthService?
    private var configured: Bool { audioPlayer != nil }

    // MARK: - Internal session state

    private var transport: GroupTransport?
    private var me: Participant?
    private var sessionEpoch = 0
    private var broadcastTask: Task<Void, Never>?
    /// Leader: last state sent, to choose reliable (change) vs unreliable (heartbeat).
    private var lastSent: GroupPlaybackState?
    /// Follower: the stop index currently loaded, to avoid reloading each heartbeat.
    private var appliedStopIndex: Int?

    /// Drift beyond this (seconds) triggers a corrective seek on a follower.
    /// Below it, small phone-to-phone differences are inaudible — don't
    /// over-correct (causes stutter). Design §4.
    private let driftThreshold: Double = 1.25
    private let heartbeatSeconds: Double = 1.0

    init() {}

    /// Wire the live services (called once from the App `.task`).
    func attach(
        audioPlayer: AudioPlayerService,
        appShared: AppSharedState,
        dataService: DataService,
        tourDownloader: TourDownloader,
        proximityMonitor: ProximityMonitor,
        auth: AuthService
    ) {
        guard !configured else { return }
        self.audioPlayer = audioPlayer
        self.appShared = appShared
        self.dataService = dataService
        self.tourDownloader = tourDownloader
        self.proximityMonitor = proximityMonitor
        self.auth = auth
    }

    // MARK: - Session lifecycle

    /// Whether this tour is cached for offline play (the group should download
    /// before an offline Nearby session — design decision §13.2). The UI warns
    /// when false.
    func isTourDownloaded(_ tour: Tour) -> Bool {
        tourDownloader?.isDownloaded(tourId: tour.id) ?? false
    }

    /// Start a session as the leader for `tour`. Returns the join code to share,
    /// or nil if not configured / signed out.
    @discardableResult
    func startAsLeader(tour: Tour) -> String? {
        guard configured, let me = currentUser() else { return nil }
        leave()   // clean any prior session first

        self.me = me
        let newCode = Self.makeCode()
        sessionEpoch += 1
        role = .leader
        code = newCode
        activeTour = tour
        leaderLost = false

        let mp = MultipeerTransport(
            role: .leader, code: newCode, me: me,
            tourId: tour.id, leaderName: me.displayName
        )
        wire(mp)
        mp.start()
        transport = mp

        startBroadcastLoop()
        return newCode
    }

    /// Join an existing session by code as a follower. The tour is resolved from
    /// the leader's first broadcast, so this needs only the code.
    func join(code joinCode: String) {
        guard configured, let me = currentUser() else { return }
        leave()

        self.me = me
        role = .follower
        code = joinCode
        leaderLost = false
        appliedStopIndex = nil
        // A follower must not let its own geofence drive playback — it only
        // mirrors the leader (design §3).
        proximityMonitor?.stopMonitoring()

        let mp = MultipeerTransport(
            role: .follower, code: joinCode, me: me, tourId: nil, leaderName: nil
        )
        wire(mp)
        mp.start()
        transport = mp
    }

    /// Leave the session and reset. Solo playback/geofencing resume as normal on
    /// the next tour the user starts.
    func leave() {
        broadcastTask?.cancel()
        broadcastTask = nil
        transport?.leave()
        transport = nil
        role = nil
        code = nil
        participants = []
        leaderName = nil
        activeTour = nil
        leaderLost = false
        lastSent = nil
        appliedStopIndex = nil
        me = nil
    }

    // MARK: - Wiring

    private func wire(_ transport: GroupTransport) {
        transport.onState = { [weak self] state in
            self?.applyFromLeader(state)
        }
        transport.onRoster = { [weak self] others in
            guard let self else { return }
            self.participants = others
            if self.role == .follower {
                self.leaderName = others.first?.displayName
            }
        }
        transport.onLeaderLost = { [weak self] in
            guard let self, self.role == .follower else { return }
            self.leaderLost = true
            self.audioPlayer?.pause()
        }
    }

    // MARK: - Leader: broadcast

    private func startBroadcastLoop() {
        broadcastTask?.cancel()
        broadcastTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.broadcastCurrentState()
                try? await Task.sleep(for: .seconds(self?.heartbeatSeconds ?? 1.0))
            }
        }
    }

    private func broadcastCurrentState() {
        guard role == .leader,
              let transport, let me,
              let tour = activeTour,
              let audioPlayer, let appShared else { return }

        // Only report live position when the leader is actually on this tour;
        // otherwise report a paused stop 0 so followers park cleanly.
        let onThisTour = audioPlayer.currentSourceId == tour.id.uuidString
        let stops = tour.stops.sorted { $0.order < $1.order }
        let stopIndex: Int = {
            guard onThisTour, let sid = appShared.currentPlayingStopId,
                  let idx = stops.firstIndex(where: { $0.id == sid }) else { return 0 }
            return idx
        }()

        let state = GroupPlaybackState(
            tourId: tour.id,
            stopIndex: stopIndex,
            isPlaying: onThisTour && audioPlayer.state == .playing,
            positionSeconds: onThisTour ? audioPlayer.currentTime : 0,
            rate: audioPlayer.rate,
            leaderId: me.id,
            sessionEpoch: sessionEpoch,
            sentAt: Date()
        )

        // Reliable delivery for a real change (stop / play-pause / rate);
        // unreliable for the position-only heartbeat (loss-tolerant).
        let changed = lastSent.map {
            $0.stopIndex != state.stopIndex ||
            $0.isPlaying != state.isPlaying ||
            $0.rate != state.rate
        } ?? true
        transport.send(state, reliable: changed)
        lastSent = state
    }

    // MARK: - Follower: apply

    private func applyFromLeader(_ state: GroupPlaybackState) {
        guard role == .follower, let audioPlayer, let dataService else { return }
        // Ignore a stale leader (lower epoch); adopt a newer one.
        if state.sessionEpoch < sessionEpoch { return }
        sessionEpoch = state.sessionEpoch
        leaderLost = false

        // Resolve the tour from the broadcast (you follow whatever the leader plays).
        if activeTour?.id != state.tourId {
            activeTour = dataService.tour(by: state.tourId)
            appliedStopIndex = nil
        }
        guard let tour = activeTour else { return }
        let stops = tour.stops.sorted { $0.order < $1.order }
        guard stops.indices.contains(state.stopIndex) else { return }
        let stop = stops[state.stopIndex]

        let needsLoad = appliedStopIndex != state.stopIndex
            || audioPlayer.currentSourceId != tour.id.uuidString

        if needsLoad {
            let remote = URL(string: stop.audioURL)
            guard let url = tourDownloader?.localURL(forStop: stop, in: tour) ?? remote else { return }
            let maker = dataService.maker(for: tour)
            audioPlayer.play(url: url, title: tour.title, artist: maker?.displayName,
                             sourceId: tour.id.uuidString)
            appShared?.currentPlayingStopId = stop.id
            appliedStopIndex = state.stopIndex
            audioPlayer.seek(to: state.positionSeconds)
            if !state.isPlaying { audioPlayer.pause() }
        } else {
            // Same stop already loaded — match transport + correct drift.
            if state.isPlaying, audioPlayer.state != .playing {
                audioPlayer.play()
            } else if !state.isPlaying, audioPlayer.state == .playing {
                audioPlayer.pause()
            }
            if state.isPlaying, audioPlayer.duration > 0 {
                let drift = abs(audioPlayer.currentTime - state.positionSeconds)
                if drift > driftThreshold { audioPlayer.seek(to: state.positionSeconds) }
            }
        }

        if audioPlayer.rate != state.rate {
            audioPlayer.setPlaybackRate(state.rate)
        }
    }

    // MARK: - Helpers

    /// The signed-in user as a `Participant`, or nil when signed out.
    private func currentUser() -> Participant? {
        guard let auth, auth.isSignedIn, let id = auth.userId else { return nil }
        let name = auth.email?.split(separator: "@").first.map(String.init) ?? "Dozent"
        return Participant(id: id, displayName: name)
    }

    /// A short, read-aloud-friendly join code from an unambiguous alphabet
    /// (no O/0/I/1). e.g. "K7QP2".
    private static func makeCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<5).map { _ in alphabet.randomElement()! })
    }
}

import Foundation

/// The transport seam (design: `docs/group-listen-design.md` §5). The sync
/// engine (`GroupListenCoordinator`) depends only on this protocol; the pipe
/// underneath is swappable — `MultipeerTransport` (Nearby/offline) now, a
/// `RealtimeTransport` (Supabase, large groups) later. Building one transport
/// commits nothing on the other.
///
/// Callbacks are always delivered on the main actor so the coordinator can
/// touch UI/player state directly.
protocol GroupTransport: AnyObject {
    /// A follower received a new playback state from the leader.
    var onState: (@MainActor (GroupPlaybackState) -> Void)? { get set }
    /// The roster changed (someone joined/left). Includes everyone currently
    /// connected, self excluded (the coordinator adds self).
    var onRoster: (@MainActor ([Participant]) -> Void)? { get set }
    /// The leader disappeared (follower side) — a peer that was **connected**
    /// dropped. Not fired for the initial handshake churn (a peer that never
    /// connected going `.notConnected`), so a slow join never looks like a
    /// leader who left.
    var onLeaderLost: (@MainActor () -> Void)? { get set }
    /// Discovery/connection status changed. Lets the UI show "searching",
    /// "connected", or an actionable failure (Local Network permission).
    var onStatus: (@MainActor (GroupConnectionStatus) -> Void)? { get set }

    /// Begin advertising (leader) or browsing+joining (follower).
    func start()
    /// Leader broadcasts a state to all followers. `reliable` for state changes
    /// (play/pause/stop-change), unreliable for the position heartbeat.
    func send(_ state: GroupPlaybackState, reliable: Bool)
    /// Tear down the session (stop advertising/browsing, disconnect).
    func leave()
}

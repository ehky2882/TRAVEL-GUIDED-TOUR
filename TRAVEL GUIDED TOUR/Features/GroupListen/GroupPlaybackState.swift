import Foundation

/// A participant's role in a Group Listen session.
enum GroupRole: String, Codable, Sendable {
    /// Drives playback; its player is the source of truth and it broadcasts.
    case leader
    /// Mirrors the leader — geofence monitoring off; applies received state.
    case follower
}

/// One person in a session — shown in the banner / roster. `id` is the
/// signed-in user's id (sessions are account-gated); `displayName` is their
/// maker/display name for the roster.
struct Participant: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let displayName: String
}

/// The entire sync protocol, essentially — the leader broadcasts this on every
/// play/pause/seek/stop-change and as a periodic heartbeat while playing; each
/// follower applies it (design: `docs/group-listen-design.md` §4). Tiny (a few
/// hundred bytes), transport-agnostic (Multipeer now, Supabase Realtime later).
struct GroupPlaybackState: Codable, Equatable, Sendable {
    /// Which tour the group is listening to (followers resolve it via `DataService`).
    let tourId: UUID
    /// Index into the tour's stops (sorted by `order`) — the current stop.
    var stopIndex: Int
    var isPlaying: Bool
    /// Playback position within the current stop's audio, in seconds.
    var positionSeconds: Double
    /// Leader's playback speed (a follower matches it).
    var rate: Float
    /// Current leader's user id — enables handoff.
    var leaderId: UUID
    /// Bumped on any leader handoff; a follower ignores state from a lower epoch
    /// (a stale leader that reconnects).
    var sessionEpoch: Int
    /// When the leader sent it. Kept for future latency compensation; v1
    /// reconciliation seeks to `positionSeconds` directly (Multipeer latency is
    /// negligible and phone clocks may skew, so we don't add travel time).
    var sentAt: Date
}

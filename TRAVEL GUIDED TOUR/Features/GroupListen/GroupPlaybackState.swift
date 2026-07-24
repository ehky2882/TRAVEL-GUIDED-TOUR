import Foundation

/// A participant's role in a Group Listen session.
enum GroupRole: String, Codable, Sendable {
    /// Drives playback; its player is the source of truth and it broadcasts.
    case leader
    /// Mirrors the leader — geofence monitoring off; applies received state.
    case follower
}

/// Discovery / connection status for a Group Listen session, surfaced from the
/// transport up to the UI so a session can never silently dead-end. Before this
/// existed, a denied Local Network permission (or simply no peer in range) left
/// both phones showing a code/roster forever with no feedback — the #1 reason
/// the feature "did nothing."
enum GroupConnectionStatus: Equatable, Sendable {
    /// Not in a session (or torn down).
    case idle
    /// Advertising (leader) / browsing (follower) — radios up, no peer yet.
    case searching
    /// At least one peer connected.
    case connected
    /// Discovery could not start — almost always Local Network permission
    /// denied. Carries user-facing copy.
    case failed(String)
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
    /// True when the leader is playing the tour's **intro** clip (which belongs
    /// to no single stop). Followers must then load `Tour.introAudioURL`, not
    /// `stops[stopIndex]` — otherwise they'd play stop 0's audio over the
    /// leader's intro. Defaults false so older encodings decode unchanged.
    var isIntro: Bool = false
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

// Explicit decoding so a payload missing `isIntro` (a peer on an older build)
// decodes to `false` rather than throwing — synthesized `Decodable` does not
// fall back to a property's default for an absent key. Defined in an extension
// so the memberwise initializer is preserved; encoding stays synthesized.
extension GroupPlaybackState {
    private enum CodingKeys: String, CodingKey {
        case tourId, stopIndex, isIntro, isPlaying, positionSeconds, rate, leaderId, sessionEpoch, sentAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tourId = try c.decode(UUID.self, forKey: .tourId)
        stopIndex = try c.decode(Int.self, forKey: .stopIndex)
        isIntro = try c.decodeIfPresent(Bool.self, forKey: .isIntro) ?? false
        isPlaying = try c.decode(Bool.self, forKey: .isPlaying)
        positionSeconds = try c.decode(Double.self, forKey: .positionSeconds)
        rate = try c.decode(Float.self, forKey: .rate)
        leaderId = try c.decode(UUID.self, forKey: .leaderId)
        sessionEpoch = try c.decode(Int.self, forKey: .sessionEpoch)
        sentAt = try c.decode(Date.self, forKey: .sentAt)
    }
}

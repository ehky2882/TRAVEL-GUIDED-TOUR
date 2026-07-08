# Group Listen — design & production handoff

Status: **design only, not built** (2026-07-05). Produced in a web session for a
future **local (Mac/Xcode) session** to implement. Everything needed to build it
without re-deriving decisions is here: UX, architecture, the concrete data model,
exact integration points in the existing code, the two transports, entitlements,
a phased plan, and a test plan. Backend SQL for the online mode is in
[`../backend/group_sessions.sql`](../backend/group_sessions.sql).

> **This is a proposal awaiting the owner's green-light to build.** Decisions below were
> made with the owner 2026-07-05; open questions are flagged at the end.

---

## 1. What we're building

Let a group of people **listen to a tour together, in sync**. A tour group is
**physically co-located** (the defining constraint). One person leads; everyone else's
audio mirrors theirs — same words at the same moment, and stops advance together as the
group walks.

Two use cases, one feature:
- **Delight (free):** you + your spouse at a museum; friends on a trail. Small, often
  **offline** (travelers avoid data roaming).
- **Business (paid "Pro Guide"):** a guide leading a large paying group.

## 2. Decisions locked with the owner (2026-07-05)
- **Offline must work** — roaming-averse travelers are the core audience.
- **Anyone can be the leader** (free); **"Pro Guide" is a paid upgrade** (verified guide, large groups, extras).
- **Joining is account-gated** — every participant is signed in (gives names/faces; ties into the social layer).
- **Leadership is a passable token** — design the data for handoff; keep the UI minimal (rare event).
- The feature intentionally **stitches together the social layer** (invite people you follow) **and monetization** (Pro Guide).

## 3. The core idea: the leader model
This dissolves the one real wrinkle — the GPS geofence auto-trigger fighting the sync.

- **The leader's phone drives everything.** Its normal playback (GPS-triggered stop
  advances, play/pause, scrub) is the source of truth.
- **Followers mirror.** Their **geofence monitoring is OFF** during the session; they only
  apply what the leader sends. (Bonus: followers save battery, no GPS needed.)
- Mirrors how a real guided walk works, and removes all trigger conflicts.

## 4. Two modes, one engine (the key architecture)
The **sync engine is identical** in both modes — the leader broadcasts a tiny state, the
followers apply it. Only the **transport** (the pipe) differs. Build the engine once
behind a `GroupTransport` protocol; plug a transport underneath.

| Mode | Transport | Size | Signal | Use case |
|---|---|---|---|---|
| **Nearby** | `MultipeerConnectivity` (Bluetooth/peer-Wi-Fi mesh) | **~8** (Apple's practical cap) | **Offline** ✅ | You + spouse; small groups; dead zones |
| **Hosted** | Supabase Realtime (internet relay, join by code) | **Hundreds** | Needs signal | Pro Guide + large commercial groups |

The ~8 cap on Nearby is a hard property of the mesh radios — it is *why* large groups need
the online Hosted mode. That's not a limitation to fix; it's the reason two modes exist.

### The shared state (the whole protocol, essentially)
The leader broadcasts this on every play/pause/seek/stop-change (and ~every 3s as a
heartbeat while playing). It's tiny — a few hundred bytes.

```swift
struct GroupPlaybackState: Codable, Equatable {
    let tourId: UUID
    var stopIndex: Int          // which stop in the tour
    var isPlaying: Bool
    var positionSeconds: Double // position within the current stop's audio
    var rate: Float             // playback speed (leader may change it)
    var leaderId: UUID          // current leader (enables handoff)
    var sessionEpoch: Int       // bumped on leader handoff; ignore lower epochs
    var sentAt: Date            // for latency compensation on the follower
}
```

Follower reconciliation logic (transport-agnostic):
- **On join / on stop-change:** load `tour.stops[stopIndex].audioURL` → `seek` →
  `play`/`pause` to match.
- **On heartbeat:** compute expected position = `positionSeconds + (now - sentAt)` if
  playing; if local drift **> ~1.0–1.5 s**, `seek` to correct; otherwise leave it (small
  drift between phones a few feet apart is inaudible — don't over-correct, it causes
  stutter).
- **Ignore** any state whose `sessionEpoch` is lower than the current one (stale leader).

## 5. Integration with the existing code (exact touch points)
Verified against the current codebase — the feature is **additive**; it does not require
changing playback or geofencing internals.

- **`Audio/AudioPlayerService.swift`** (`@Observable`) — the follower drives it through the
  **existing public API**: `play(url:title:artist:sourceId:)`, `play()`, `pause()`,
  `seek(to:)`, `setPlaybackRate(_:)`, `stop()`; reads `currentTime`, `duration`, `state`,
  `rate`. **No need to expose the private `AVQueuePlayer`.** (This is why we do *not* use
  SharePlay's `AVPlaybackCoordinator`, which would require surfacing the player.) The
  leader path is unchanged — a thin observer watches these same values and broadcasts.
- **`Location/ProximityMonitor.swift`** — for a **follower**, simply **don't call
  `startMonitoring(...)`** (or call `stopMonitoring()` on join). The leader keeps normal
  monitoring. No internal changes.
- **`Data/AuthService.swift`** — gate the "Start/Join" entry points on `isSignedIn`; use
  the signed-in user's id as `leaderId`/participant id and to fetch display name/avatar.
- **UI entry point** — a **"Listen together"** action on the tour detail
  (`Features/Tour/TourDetailView.swift`) and/or the player. Present a small
  `GroupListenSheet` (start nearby / host with code / join). A compact **"group" banner**
  on the mini-player + player shows participant count and (for followers) a "you're
  following <leader>" state with a **Leave** button.
- **App wiring** — a new `@Observable GroupListenCoordinator` built once at
  `TRAVEL_GUIDED_TOURApp` init (like the other services), injected via environment, holding
  the active transport + the leader/follower role. It owns the reconciliation loop and
  toggles `ProximityMonitor` accordingly.

### Proposed new files (all new — nothing rewired that ships today)
```
Features/GroupListen/
  GroupListenCoordinator.swift   // @Observable; role, session lifecycle, reconciliation
  GroupTransport.swift           // protocol: send(state), onReceive, join/leave, roster
  MultipeerTransport.swift       // Nearby mode (MCSession/MCNearbyServiceAdvertiser/Browser)
  RealtimeTransport.swift        // Hosted mode (Supabase Realtime broadcast + presence)
  GroupPlaybackState.swift       // the Codable struct above
  GroupListenSheet.swift         // start / host / join UI
  GroupBanner.swift              // participant count + role + Leave, on mini-player/player
```

### The transport seam
```swift
protocol GroupTransport: AnyObject {
    var onState: ((GroupPlaybackState) -> Void)? { get set }   // follower receives
    var onRoster: (([Participant]) -> Void)? { get set }       // who's here (Pro roster)
    func start(as role: GroupRole) async throws                 // leader advertises / joins
    func send(_ state: GroupPlaybackState)                      // leader broadcasts
    func leave()
}
```
`GroupListenCoordinator` depends only on this protocol; `MultipeerTransport` and
`RealtimeTransport` are interchangeable implementations. **Build the coordinator + one
transport first; the second transport is purely additive.**

## 6. Nearby mode — MultipeerConnectivity (offline)
- Frameworks: `MultipeerConnectivity`. Leader runs `MCNearbyServiceAdvertiser`; joiners run
  `MCNearbyServiceBrowser`; both share an `MCSession`. Service type e.g. `"atlas-tour"`.
- Send `GroupPlaybackState` as `session.send(data, toPeers:, with: .reliable)` for
  state-change events, `.unreliable` for the position heartbeat (loss-tolerant).
- **~8 peers** including the leader — enforce/communicate this cap in the UI ("Nearby groups
  hold up to 8; host an online group for more").
- **No internet, no backend, no cost.** Works with downloaded tours in a dead zone (pair
  with the existing `TourDownloader` — recommend prompting the group to download the tour
  before starting offline).
- **Info.plist required:** `NSLocalNetworkUsageDescription` (+ `NSBonjourServices` listing
  the `_atlas-tour._tcp`/`._udp` service types). No special entitlement beyond that.

## 7. Hosted mode — Supabase Realtime (online, large)
- **`group_sessions` table** (see `backend/group_sessions.sql`): a short **join code**, the
  host/leader, the tour, a `pro` flag, and the **last broadcast state** (so late-joiners
  sync immediately). Reuses the Supabase project already live.
- **Live sync:** a Supabase **Realtime broadcast** channel named by session id carries the
  `GroupPlaybackState` stream (not Postgres-changes — broadcast is lower-latency and
  ephemeral). **Presence** on the same channel gives the live **roster** ("who's here")
  for free — perfect for the Pro Guide view.
- **Join flow:** leader taps "Host" → row created, gets a code like `MET-4821` → reads it
  aloud → others "Join" + type code → look up the session → subscribe to its channel →
  pull `last_state` → sync. Account-gated, so each joiner shows up by name.
- Scales to hundreds; Supabase free tier (200 concurrent connections) covers small
  commercial groups, paid tiers go far higher.

## 8. Leadership handoff (design the data, keep the UI simple)
- Leader identity lives in the state (`leaderId`) and, for Hosted, in
  `group_sessions.leader_user_id`. `sessionEpoch` increments on any handoff so stale
  broadcasts are ignored.
- **v1 UI (minimal):** if the leader leaves or drops (Nearby: peer disconnect; Hosted:
  presence timeout), the session **pauses** and shows **"Leader left — tap to take over"**;
  the first to tap claims leadership (bumps epoch, becomes broadcaster). No elaborate
  controls. Explicit "pass the lead" can come later (matters most for Pro Guide).

## 9. Free vs Pro Guide (the monetization seam)
| | **Listen Together** (free) | **Pro Guide** (paid) |
|---|---|---|
| Who | Any signed-in user | Verified guide (entitlement/flag) |
| Modes | Nearby + small Hosted | Hosted at scale |
| Size | ≤ ~8 (Nearby) / small Hosted | Large Hosted groups |
| Extras | Synced audio only | Roster ("who's here"), leadership handoff/co-leads, guide branding on the session, (later) live annotations/analytics |

- Gate Pro behind a `profiles.is_pro_guide` flag (or the Step-6 purchases system when it
  lands). The **free tier is the hook; you charge the person monetizing the tour**, not the
  casual couple. Clean, honest paywall. Ties into Step 6 (payments) and Step 8 (social).

## 10. Why not SharePlay?
Considered and set aside as the primary mechanism:
- Its session model is **FaceTime/call-oriented** — awkward to spin up for a walking group.
- It **needs signal** — fails the offline requirement outright.
- Its `AVPlaybackCoordinator` would require exposing the private `AVQueuePlayer` and doesn't
  cover the leader/geofence logic (you'd write that anyway via `GroupSessionMessenger`).
- The leader model + reconciliation we need is the same amount of work without it.

Leave a **future door open**: a `SharePlayTransport: GroupTransport` could be added later
for the pure remote "listen together from two cities" case (not the co-located tour-group
use case this design targets). The transport seam makes that additive.

## 11. Phased implementation plan (for the local session)
Each phase ends in something testable on device.

**Phase 1 — the engine + Nearby mode (the north-star: you + spouse, offline).**
- `GroupPlaybackState`, `GroupTransport`, `GroupListenCoordinator` (reconciliation, role,
  ProximityMonitor toggle), `MultipeerTransport`, minimal `GroupListenSheet` + `GroupBanner`.
- Account-gated entry on tour detail. Single-stop tours first, then multi-stop advancement.
- Acceptance: two signed-in devices, airplane-mode-except-Bluetooth, start a tour together →
  play/pause/scrub/stop-advance mirror within ~1s; follower's geofence stays off; leader
  leaving pauses + offers takeover.

**Phase 2 — Hosted mode (online, large).**
- `backend/group_sessions.sql` applied (owner, hand-held). `RealtimeTransport` (broadcast +
  presence), join-by-code UI, late-join via `last_state`. Same coordinator, new pipe.
- Acceptance: 3+ devices join by code across networks → synced; roster shows names.

**Phase 3 — Pro Guide.**
- `is_pro_guide` gate, large-group polish, roster UI, explicit leadership pass, guide
  branding. Wire to the payments system (Step 6) when available.

## 12. Entitlements / project changes needed (flag for the build)
- **Info.plist:** `NSLocalNetworkUsageDescription`, `NSBonjourServices` (Nearby). (Mic key,
  location keys already present.)
- No new entitlement for Multipeer/Realtime. *(Only if a SharePlay transport is ever added
  would you need the GroupActivities entitlement.)*
- New SwiftUI files added to the app target → **code PRs, so `test_sim` + simulator review
  before merge**, per the repo rules.
- **Device testing is mandatory** — Multipeer and multi-device sync barely work in the
  simulator. Needs **2+ real devices** signed into different accounts.

## 13. Open questions still worth resolving before/while building
1. **Pro Guide priority** — is it a real near-term thread? If yes, Hosted mode + guide
   identity may outrank the cozy offline case, and it couples to the Step-6 payments work.
2. **Do we require the tour be downloaded before an offline Nearby session?** (Strongly
   recommend yes — otherwise a dead-zone group has no audio to sync.)
3. **Group discovery in Nearby** — auto-show everyone running the app nearby, or require the
   leader to share a short code / QR even in Nearby mode (avoids randoms joining)? Leaning:
   code/QR even for Nearby, for intentionality + privacy.
4. **What syncs beyond playback?** Just audio (recommended for v1), or also the map view /
   current-stop highlight? Keep v1 audio-only.

## 14. Verification (when built)
- Two/three real devices, signed-in different accounts.
- Nearby: Bluetooth-only (data off) → start together → verify sync, geofence-off on
  followers, leader-leave takeover, ≤8 enforced.
- Hosted: join by code across networks → sync + roster; late-joiner snaps to current state.
- Regression: solo playback + solo geofence auto-trigger unchanged when not in a session.

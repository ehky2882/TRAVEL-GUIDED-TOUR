import Foundation
import MultipeerConnectivity

/// Nearby / offline transport (design: `docs/group-listen-design.md` §6).
/// Works with **no internet** over Bluetooth / peer-Wi-Fi. The leader
/// advertises the session with a short **join code** in its `discoveryInfo`;
/// a follower browses and only invites the advertiser whose code matches what
/// the user typed — so the radios do the finding, the code makes it
/// intentional and private (no strangers in a crowded museum).
///
/// Practical cap ~8 peers (a hard property of the mesh radios) — the reason
/// large groups need the future Hosted mode.
final class MultipeerTransport: NSObject, GroupTransport {
    var onState: (@MainActor (GroupPlaybackState) -> Void)?
    var onRoster: (@MainActor ([Participant]) -> Void)?
    var onLeaderLost: (@MainActor () -> Void)?
    var onStatus: (@MainActor (GroupConnectionStatus) -> Void)?

    /// Bonjour service type: ≤15 chars, lowercase letters / digits / hyphen.
    /// Must match `NSBonjourServices` in Info.plist (`_atlas-tour._tcp/._udp`).
    static let serviceType = "atlas-tour"

    private let role: GroupRole
    private let code: String
    private let me: Participant
    private let tourId: UUID?
    private let leaderName: String?

    private let peerID: MCPeerID
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// Stable `Participant` per connected peer (keyed by peer display name) so
    /// roster rows don't churn ids across updates. Ephemeral to the session.
    /// Guarded by `lock` — MultipeerConnectivity delivers session/browser
    /// callbacks on its own arbitrary queues, so mutating this plain Dictionary
    /// from them unsynchronized was a data race (crash / corrupt roster).
    private var peerParticipants: [String: Participant] = [:]
    private let lock = NSLock()

    /// Follower side: whether we ever reached `.connected`. Leader-lost is only
    /// real *after* a real connection — the initial handshake churn (a peer
    /// going `.connecting` → `.notConnected`) must not read as "leader left".
    private var everConnected = false

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(role: GroupRole, code: String, me: Participant, tourId: UUID?, leaderName: String?) {
        self.role = role
        self.code = code
        self.me = me
        self.tourId = tourId
        self.leaderName = leaderName

        // Display name must be 1–63 UTF-8 bytes; fall back to a constant.
        let name = me.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let clamped = name.isEmpty ? "Dozent" : String(name.prefix(60))
        self.peerID = MCPeerID(displayName: clamped)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .optional)
        super.init()
        session.delegate = self
    }

    func start() {
        emitStatus(.searching)
        switch role {
        case .leader:
            var info: [String: String] = ["code": code]
            if let tourId { info["tour"] = tourId.uuidString }
            if let leaderName { info["leader"] = leaderName }
            let advertiser = MCNearbyServiceAdvertiser(
                peer: peerID, discoveryInfo: info, serviceType: Self.serviceType
            )
            advertiser.delegate = self
            advertiser.startAdvertisingPeer()
            self.advertiser = advertiser
        case .follower:
            let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
            browser.delegate = self
            browser.startBrowsingForPeers()
            self.browser = browser
        }
    }

    func send(_ state: GroupPlaybackState, reliable: Bool) {
        guard !session.connectedPeers.isEmpty,
              let data = try? encoder.encode(state) else { return }
        try? session.send(data, toPeers: session.connectedPeers,
                          with: reliable ? .reliable : .unreliable)
    }

    func leave() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        session.disconnect()
    }

    // MARK: - Roster / status

    /// Serialized under `lock` — called only from `emitRoster()`.
    private func participant(for peer: MCPeerID) -> Participant {
        if let existing = peerParticipants[peer.displayName] { return existing }
        let p = Participant(id: UUID(), displayName: peer.displayName)
        peerParticipants[peer.displayName] = p
        return p
    }

    private func emitRoster() {
        lock.lock()
        let others = session.connectedPeers.map { participant(for: $0) }
        lock.unlock()
        Task { @MainActor in self.onRoster?(others) }
    }

    private func emitStatus(_ status: GroupConnectionStatus) {
        Task { @MainActor in self.onStatus?(status) }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerTransport: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        emitRoster()

        let hasPeers = !session.connectedPeers.isEmpty
        if state == .connected { everConnected = true }

        if hasPeers {
            emitStatus(.connected)
        } else {
            // No peers right now. For a follower that had *already* connected,
            // this is a real leader drop → surface the takeover prompt. During
            // the initial handshake (never connected yet) or for a leader whose
            // last follower left, we're simply back to searching — not a
            // failure, so we keep advertising/browsing.
            emitStatus(.searching)
            if role == .follower, state == .notConnected, everConnected {
                Task { @MainActor in self.onLeaderLost?() }
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let state = try? decoder.decode(GroupPlaybackState.self, from: data) else { return }
        Task { @MainActor in self.onState?(state) }
    }

    // Unused streaming/resource APIs — required by the protocol.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate (leader)

extension MultipeerTransport: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Only followers holding the correct code invite us (the browser filters
        // by the advertised code), so auto-accept.
        invitationHandler(true, session)
    }

    /// Advertising couldn't start — on iOS this is almost always the Local
    /// Network permission being denied. Without surfacing this the leader shows
    /// a code that no one can ever join, with no explanation.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        emitStatus(.failed(Self.discoveryFailureMessage(error)))
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (follower)

extension MultipeerTransport: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        // Join only the session whose advertised code matches ours.
        guard info?["code"] == code else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        emitRoster()
    }

    /// Browsing couldn't start — same story as the advertiser: almost always
    /// the Local Network permission being denied. Surface it so the follower
    /// isn't left staring at a "Following…" screen that never connects.
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        emitStatus(.failed(Self.discoveryFailureMessage(error)))
    }
}

// MARK: - Failure copy

private extension MultipeerTransport {
    /// User-facing copy for a discovery start failure. iOS reports Local Network
    /// permission denial here; there's no reliable public pre-flight API, so
    /// reacting to this callback is the robust way to detect it.
    static func discoveryFailureMessage(_ error: Error) -> String {
        "Couldn't find nearby devices. Enable Local Network access for Dozent in Settings › Privacy & Security › Local Network, then try again."
    }
}

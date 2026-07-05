import Foundation
import CoreLocation
import UserNotifications
import Observation

/// Geofence coordinator — spec § Flow 2 (multi-stop geofenced tours)
/// and roadmap M-geofencing.
///
/// One active tour at a time. When a stop's `CLCircularRegion` reports
/// an entry, this service:
///   - sets `lastEnteredStopId` (observable; the player UI syncs its
///     currentStopIndex off this so transport controls stay in sync)
///   - calls `audioPlayer.play(url:title:artist:sourceId:)` with that stop's
///     audio (works while the app is foregrounded, locked, or
///     backgrounded — iOS wakes us on the boundary crossing)
///   - fires a local notification (only shown while the app is
///     backgrounded; iOS suppresses these in the foreground by
///     default)
///
/// V1 design choices:
///   - Only stops with `triggerMode == .geofenced` are registered.
///     Manual stops are user-tap only.
///   - Apple caps simultaneous monitored regions at 20 per app; we
///     prefix the registered stops as a safety net (V1 catalog is
///     well below this).
///   - We don't stop monitoring when the player sheet dismisses —
///     the user might pocket their phone mid-tour. Monitoring stops
///     when a new tour starts (overwriting the old) or
///     `stopMonitoring()` is called explicitly.
@Observable
final class ProximityMonitor: NSObject, CLLocationManagerDelegate {
    /// The tour we're currently monitoring stops for, or nil.
    private(set) var activeTourId: UUID?
    /// Most recent stop the user has entered the geofence for. The
    /// player UI watches this to sync `currentStopIndex`.
    private(set) var lastEnteredStopId: UUID?

    private let manager = CLLocationManager()
    private var monitoredStops: [UUID: Stop] = [:]
    /// Stops that have already been triggered this monitoring session —
    /// via a real `didEnterRegion` crossing *or* the already-inside
    /// (`didDetermineState == .inside`) path. De-dupes the two against
    /// each other so a stop never plays twice. Also seeded in
    /// `startMonitoring` with the stop the player view started directly
    /// (`startedStopId`), so the already-inside path never re-fires a
    /// stop the UI is already playing (audit: AMNH stop-2 miss).
    private var playedStopIds: Set<UUID> = []
    /// Stops the user is currently determined to be *inside* (from
    /// `requestState`/`didDetermineState`). Tracked as a set so an
    /// overlapping-regions start resolves to the first stop in tour
    /// order rather than whichever determination arrived first.
    private var insideStopIds: Set<UUID> = []
    /// A geofenced stop the user is standing inside at monitoring start
    /// but whose audio we're holding back until the currently-playing
    /// item (typically the intro) finishes — so we don't stomp it.
    /// Played by `playerStateDidChangeWhilePending()` when the player
    /// goes idle, or cleared by `cancelPendingInsideStop()` when the UI
    /// takes the stop over (intro → stop-0 auto-advance).
    private var pendingInsideStopId: UUID?
    /// Guards against stacking multiple `withObservationTracking`
    /// re-arms while we wait for the current item to end.
    private var isObservingForPendingFire = false
    /// Retained so `handleEntry` can ask `tourDownloader` for the
    /// active tour's local audio URL when the user is offline
    /// (audit P0-5). Cleared in `stopMonitoring`.
    private var activeTour: Tour?
    private var activeTourTitle: String?
    private var activeMakerName: String?
    private weak var audioPlayer: AudioPlayerService?
    /// Lets `handleEntry` prefer the on-disk audio file over the
    /// remote URL for downloaded tours. Weak so the environment
    /// shelf owns the lifetime.
    private weak var tourDownloader: TourDownloader?

    override init() {
        super.init()
        manager.delegate = self
        #if os(iOS) || os(visionOS)
        // Register self as the notification delegate so geofence
        // entries surface a banner/sound even while Atlas is in the
        // foreground (audit P0-6). iOS suppresses notifications in
        // the foreground by default; a `willPresent` override is
        // the documented opt-in.
        UNUserNotificationCenter.current().delegate = self
        #endif
    }

    // MARK: - Public API

    /// Begin monitoring geofenced stops for `tour`. Stops any prior
    /// monitoring first. No-op when the tour has no `.geofenced`
    /// stops (single-piece or all-manual tours).
    ///
    /// `tourDownloader` is consulted on geofence entry so a
    /// downloaded tour plays from disk even when the user is
    /// offline (airplane mode, no signal mid-walk).
    /// `startedStopId` is the stop the player view has just begun
    /// playing directly (e.g. a geofenced stop-0 with no intro, or a
    /// manual intro stop). It's seeded into `playedStopIds` so the
    /// already-inside path never double-plays a stop the UI is already
    /// sounding. Pass `nil` when the UI started the tour's intro audio
    /// (`introAudioURL`) rather than a stop.
    func startMonitoring(
        tour: Tour,
        maker: Maker?,
        audioPlayer: AudioPlayerService,
        tourDownloader: TourDownloader,
        startedStopId: UUID? = nil
    ) {
        #if os(iOS)
        stopMonitoring()

        let geofencedStops = tour.stops.filter { $0.triggerMode == .geofenced }
        guard !geofencedStops.isEmpty else { return }

        requestNotificationPermissionIfNeeded()

        self.activeTourId = tour.id
        self.activeTour = tour
        self.activeTourTitle = tour.title
        self.activeMakerName = maker?.displayName
        self.audioPlayer = audioPlayer
        self.tourDownloader = tourDownloader
        if let startedStopId {
            playedStopIds.insert(startedStopId)
        }

        for stop in geofencedStops.prefix(20) {
            let region = CLCircularRegion(
                center: stop.coordinate,
                radius: CLLocationDistance(stop.triggerRadiusMeters),
                identifier: stop.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
            monitoredStops[stop.id] = stop
            // CoreLocation only delivers `didEnterRegion` on a boundary
            // *crossing* — never for a region the user is already
            // inside when monitoring begins. Ask for each region's
            // current state so a stop the user is already standing in
            // (e.g. an intro that shares the first geofenced stop's
            // coordinates) still triggers. See `didDetermineState`.
            manager.requestState(for: region)
        }
        #endif
    }

    func stopMonitoring() {
        #if os(iOS)
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        #endif
        monitoredStops.removeAll()
        activeTourId = nil
        activeTour = nil
        activeTourTitle = nil
        activeMakerName = nil
        audioPlayer = nil
        tourDownloader = nil
        lastEnteredStopId = nil
        playedStopIds.removeAll()
        insideStopIds.removeAll()
        pendingInsideStopId = nil
        isObservingForPendingFire = false
    }

    /// Called by the player UI when it takes over a stop the
    /// already-inside path might otherwise fire — specifically the
    /// intro → stop-0 auto-advance, where both the UI and this monitor
    /// would start stop 0 (double audio). Drops the pending hold and
    /// marks the stop played so it can't re-pend.
    func cancelPendingInsideStop() {
        if let pending = pendingInsideStopId {
            playedStopIds.insert(pending)
        }
        pendingInsideStopId = nil
    }

    // MARK: - Delegate

    #if os(iOS)
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        guard let stopId = UUID(uuidString: region.identifier) else { return }
        MainActor.assumeIsolated {
            self.handleEntry(stopId: stopId)
        }
    }

    /// Response to the `requestState(for:)` calls made in
    /// `startMonitoring`. The `.inside` case is what fixes the
    /// already-inside miss: a region the user is standing in at start
    /// never produces a `didEnterRegion`, so this is the only signal
    /// that it should play.
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didDetermineState state: CLRegionState,
        for region: CLRegion
    ) {
        guard let stopId = UUID(uuidString: region.identifier) else { return }
        MainActor.assumeIsolated {
            switch state {
            case .inside:
                self.handleInsideDetermination(stopId: stopId)
            case .outside, .unknown:
                // `requestState` reports every monitored region,
                // including the ones the user is outside — expected;
                // just keep the inside-set accurate.
                self.insideStopIds.remove(stopId)
            @unknown default:
                break
            }
        }
    }
    #endif

    // MARK: - Handlers

    private func handleEntry(stopId: UUID) {
        guard let stop = monitoredStops[stopId] else { return }
        // De-dupe: a stop already played (via a real crossing *or* the
        // already-inside path, or seeded as the UI's started stop)
        // must not play again.
        guard !playedStopIds.contains(stopId) else { return }
        playedStopIds.insert(stopId)
        insideStopIds.remove(stopId)
        if pendingInsideStopId == stopId { pendingInsideStopId = nil }
        lastEnteredStopId = stopId

        // Prefer the on-disk audio file when the tour is downloaded
        // — without this, a user walking a downloaded tour offline
        // hits the geofence and the audio fails to load (audit P0-5).
        // Falls back to the remote URL for non-downloaded tours.
        let localURL: URL? = {
            guard let activeTour, let tourDownloader else { return nil }
            return tourDownloader.localURL(forStop: stop, in: activeTour)
        }()
        let remoteURL = URL(string: stop.audioURL)

        if let url = localURL ?? remoteURL {
            // The app's signature moment: a soft bump when a stop auto-fires,
            // often felt with the phone pocketed and the screen off.
            AtlasHaptics.impact(.medium)
            audioPlayer?.play(
                url: url,
                title: activeTourTitle,
                artist: activeMakerName,
                sourceId: activeTourId?.uuidString
            )
        }

        sendNotification(for: stop)
    }

    // MARK: - Already-inside handling

    /// The user is standing inside a monitored stop's region at start.
    /// Decide what to do with it (play now, or hold until the current
    /// item ends) via the pure `decideInsideStopAction` helper.
    private func handleInsideDetermination(stopId: UUID) {
        guard monitoredStops[stopId] != nil else { return }
        insideStopIds.insert(stopId)

        let action = Self.decideInsideStopAction(
            insideStopIds: insideStopIds,
            orderByStopId: monitoredStops.mapValues { $0.order },
            playedStopIds: playedStopIds,
            isPlayerBusy: isPlayerBusy
        )
        switch action {
        case .doNothing:
            break
        case .playNow(let id):
            // Nothing relevant is playing — fire straight away.
            pendingInsideStopId = nil
            handleEntry(stopId: id)
        case .waitForCurrentToEnd(let id):
            // Intro (or other current audio) is playing — hold this
            // stop and play it the moment the player goes idle, so we
            // don't interrupt what's already sounding.
            pendingInsideStopId = id
            observePlayerForPendingFire()
        }
    }

    /// Pure decision helper (unit-tested). Chooses which already-inside
    /// stop, if any, to act on and whether to play it now or defer.
    ///
    /// Overlapping-regions policy: when the user is inside more than one
    /// monitored stop at start, pick the **first stop in tour order**
    /// (lowest `order`) — the most natural place to begin. Ties (which
    /// shouldn't occur — `order` is unique per tour) break by id for
    /// determinism. Stops already played (real crossing, or the UI's
    /// started stop) are excluded; ids not currently monitored are
    /// ignored.
    enum InsideStopAction: Equatable {
        case doNothing
        case playNow(UUID)
        case waitForCurrentToEnd(UUID)
    }

    static func decideInsideStopAction(
        insideStopIds: Set<UUID>,
        orderByStopId: [UUID: Int],
        playedStopIds: Set<UUID>,
        isPlayerBusy: Bool
    ) -> InsideStopAction {
        let candidates = insideStopIds
            .subtracting(playedStopIds)
            .filter { orderByStopId[$0] != nil }
        guard let chosen = candidates.min(by: {
            let lo = orderByStopId[$0] ?? .max
            let ro = orderByStopId[$1] ?? .max
            return lo != ro ? lo < ro : $0.uuidString < $1.uuidString
        }) else {
            return .doNothing
        }
        return isPlayerBusy ? .waitForCurrentToEnd(chosen) : .playNow(chosen)
    }

    /// True while the audio player has something in flight that we
    /// shouldn't interrupt. `.paused` counts as busy: the user may have
    /// paused the intro and we still wait for them to finish it rather
    /// than barging in with the inside stop.
    private var isPlayerBusy: Bool {
        guard let audioPlayer else { return false }
        switch audioPlayer.state {
        case .loading, .playing, .paused:
            return true
        case .idle, .ended, .failed:
            return false
        }
    }

    /// Watch the audio player so a held `pendingInsideStopId` fires when
    /// the current item finishes. Uses `withObservationTracking` (the
    /// monitor isn't a SwiftUI view) and re-arms itself each change
    /// until the player goes idle or the pending stop is cleared.
    private func observePlayerForPendingFire() {
        guard !isObservingForPendingFire,
              pendingInsideStopId != nil,
              let audioPlayer else { return }
        isObservingForPendingFire = true
        withObservationTracking {
            _ = audioPlayer.state
        } onChange: { [weak self] in
            // Fires once, synchronously, just before the new value is
            // applied — hop to the main actor and read the settled state.
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isObservingForPendingFire = false
                self.playerStateDidChangeWhilePending()
            }
        }
    }

    private func playerStateDidChangeWhilePending() {
        guard let pending = pendingInsideStopId else { return }
        if isPlayerBusy {
            // Still playing (intro running, or a new item started) —
            // keep waiting.
            observePlayerForPendingFire()
        } else {
            // Current item finished and nothing replaced it → play the
            // stop the user is already standing inside. Re-validate it's
            // still inside and unplayed first.
            pendingInsideStopId = nil
            if insideStopIds.contains(pending), !playedStopIds.contains(pending) {
                handleEntry(stopId: pending)
            }
        }
    }

    private func sendNotification(for stop: Stop) {
        let content = UNMutableNotificationContent()
        content.title = stop.title
        if let caption = stop.caption {
            content.body = caption
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: stop.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound]
            ) { _, _ in }
        }
    }
}

#if os(iOS) || os(visionOS)
extension ProximityMonitor: UNUserNotificationCenterDelegate {
    /// Force geofence-entry notifications to show as a banner +
    /// sound even when Atlas is in the foreground (audit P0-6).
    /// Default iOS behavior suppresses notifications while the app
    /// is active — wrong for a walking-tour app where the user
    /// might be looking at the map and needs to know a stop fired.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
#endif

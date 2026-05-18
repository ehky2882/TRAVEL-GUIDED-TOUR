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
///   - calls `audioPlayer.play(url:title:artist:)` with that stop's
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
    func startMonitoring(
        tour: Tour,
        maker: Maker?,
        audioPlayer: AudioPlayerService,
        tourDownloader: TourDownloader
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
    #endif

    // MARK: - Handlers

    private func handleEntry(stopId: UUID) {
        guard let stop = monitoredStops[stopId] else { return }
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
            audioPlayer?.play(
                url: url,
                title: activeTourTitle,
                artist: activeMakerName
            )
        }

        sendNotification(for: stop)
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

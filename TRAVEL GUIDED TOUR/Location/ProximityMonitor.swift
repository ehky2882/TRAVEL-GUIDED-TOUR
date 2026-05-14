import Foundation
import CoreLocation
import UserNotifications
import Observation

@Observable
final class ProximityMonitor: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var monitoredStops: [UUID: Stop] = [:]
    private(set) var lastEnteredStop: Stop?

    override init() {
        super.init()
        manager.delegate = self
    }

    func startMonitoring(stops: [Stop]) {
        #if os(iOS)
        stopAllMonitoring()
        requestNotificationPermission()

        for stop in stops.prefix(20) where stop.triggerMode == .geofenced {
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

    func stopAllMonitoring() {
        #if os(iOS)
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        monitoredStops.removeAll()
        #endif
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    #if os(iOS)
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let stopId = UUID(uuidString: region.identifier) else { return }
        MainActor.assumeIsolated {
            guard let stop = monitoredStops[stopId] else { return }
            lastEnteredStop = stop
            sendNotification(for: stop)
        }
    }
    #endif

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
}

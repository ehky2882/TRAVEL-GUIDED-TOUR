import Foundation
import CoreLocation
import UserNotifications
import Observation

@Observable
final class ProximityMonitor: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var monitoredPlaces: [UUID: Place] = [:]
    private(set) var nearbyPlace: Place?

    override init() {
        super.init()
        manager.delegate = self
    }

    func startMonitoring(places: [Place]) {
        #if os(iOS)
        stopAllMonitoring()
        requestNotificationPermission()

        for place in places.prefix(20) {
            let region = CLCircularRegion(
                center: place.coordinate,
                radius: 200,
                identifier: place.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
            monitoredPlaces[place.id] = place
        }
        #endif
    }

    func stopAllMonitoring() {
        #if os(iOS)
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        monitoredPlaces.removeAll()
        #endif
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    #if os(iOS)
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let placeId = UUID(uuidString: region.identifier) else { return }
        MainActor.assumeIsolated {
            guard let place = monitoredPlaces[placeId] else { return }
            nearbyPlace = place
            sendNotification(for: place)
        }
    }
    #endif

    private func sendNotification(for place: Place) {
        let content = UNMutableNotificationContent()
        content.title = place.name
        content.body = "You're nearby — \(place.onSiteTip ?? place.editorialDescription)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: place.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

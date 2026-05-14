import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var userLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        #if os(macOS)
        manager.requestAlwaysAuthorization()
        #else
        manager.requestWhenInUseAuthorization()
        #endif
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            userLocation = locations.last
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            authorizationStatus = manager.authorizationStatus
            let authorized: Bool
            #if os(iOS) || os(visionOS)
            authorized = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
            #else
            authorized = manager.authorizationStatus == .authorizedAlways
            #endif
            if authorized {
                manager.startUpdatingLocation()
            }
        }
    }

    func distanceString(toLatitude latitude: Double, longitude: Double) -> String? {
        guard let userLocation else { return nil }
        let target = CLLocation(latitude: latitude, longitude: longitude)
        let distance = userLocation.distance(from: target)
        if distance < 1000 {
            return "\(Int(distance))m away"
        } else {
            let km = distance / 1000.0
            return String(format: "%.1fkm away", km)
        }
    }
}

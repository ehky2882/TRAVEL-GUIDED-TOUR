import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var userLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// Device compass heading in degrees (0 = true north, clockwise).
    /// `nil` until the first heading update arrives, or on platforms
    /// without a magnetometer (macOS / visionOS). Drives the
    /// directional wedge on the home-map user-location dot.
    private(set) var heading: CLLocationDirection?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        #if os(iOS)
        // Smooth out magnetometer jitter — only report heading changes
        // larger than a couple of degrees.
        manager.headingFilter = 2
        #endif
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        #if os(macOS)
        manager.requestAlwaysAuthorization()
        #else
        manager.requestWhenInUseAuthorization()
        #endif
    }

    /// Upgrade path used by M-geofencing — Apple only shows the
    /// Always dialog after the app has already been granted
    /// When-In-Use, so this is gated on `authorizationStatus`.
    /// Safe to call repeatedly: iOS shows the prompt at most once
    /// per launch and silently no-ops afterward.
    func requestAlwaysIfPossible() {
        #if os(iOS) || os(visionOS)
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
        #endif
    }

    var hasAlwaysAuthorization: Bool {
        authorizationStatus == .authorizedAlways
    }

    func startUpdating() {
        manager.startUpdatingLocation()
        #if os(iOS)
        manager.startUpdatingHeading()
        #endif
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        #if os(iOS)
        manager.stopUpdatingHeading()
        #endif
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
                #if os(iOS)
                manager.startUpdatingHeading()
                #endif
            }
        }
    }

    #if os(iOS)
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        MainActor.assumeIsolated {
            // Prefer true heading (geographic north); fall back to
            // magnetic when true is unavailable (reported as negative).
            heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }
    #endif

    func distanceString(toLatitude latitude: Double, longitude: Double) -> String? {
        guard let userLocation else { return nil }
        let target = CLLocation(latitude: latitude, longitude: longitude)
        return AtlasFormatters.distanceAway(meters: userLocation.distance(from: target))
    }
}

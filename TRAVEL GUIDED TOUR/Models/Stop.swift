import Foundation
import CoreLocation

enum StopTriggerMode: String, Codable {
    case geofenced
    case manual

    /// An unfamiliar trigger mode becomes `.manual` rather than throwing.
    ///
    /// 🔴 **`.manual` is load-bearing here, not an arbitrary default.** A manual
    /// stop never auto-fires: `ProximityMonitor` registers regions only for
    /// `.geofenced` stops, so a value this build cannot interpret can never
    /// produce a geofence that triggers by itself. The failure is "you have to
    /// press play", which is visible and harmless. Defaulting to `.geofenced`
    /// would invent a region from a rule we did not understand.
    ///
    /// ⚠️ **Optional does not protect a field like this, and neither does
    /// throwing.** Before tolerance, an unfamiliar value here failed the stop,
    /// which failed its tour, which failed the whole catalogue array — and
    /// `RemoteCatalogLoader`'s `try?` turned that into a silent "no new
    /// content". See `ToursData` for the full story.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = StopTriggerMode(rawValue: raw) ?? .manual
    }
}

struct Stop: Codable, Identifiable, Hashable {
    let id: UUID
    let order: Int
    let title: String
    let caption: String?
    let latitude: Double
    let longitude: Double
    let audioURL: String
    let audioDurationSeconds: Int
    let triggerMode: StopTriggerMode
    let triggerRadiusMeters: Int
    let imageURL: String?
    let transcriptText: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let stopLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: stopLocation)
    }
}

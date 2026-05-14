import Foundation
import CoreLocation

enum StopTriggerMode: String, Codable {
    case geofenced
    case manual
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

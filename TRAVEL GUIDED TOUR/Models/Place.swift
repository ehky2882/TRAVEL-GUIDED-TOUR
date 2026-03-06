import Foundation
import CoreLocation

struct Place: Codable, Identifiable, Hashable {
    let id: UUID
    let cityId: UUID
    let name: String
    let category: PlaceCategory
    let heroImageURL: String
    let thumbnailURL: String
    let editorialDescription: String
    let onSiteTip: String?
    let address: String
    let latitude: Double
    let longitude: Double
    let neighborhood: String?
    let hours: String?
    let priceIndicator: PriceIndicator
    let websiteURL: String?
    let tags: [String]
    let isFeatured: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let placeLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: placeLocation)
    }
}

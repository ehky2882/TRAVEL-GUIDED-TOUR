import Foundation
import CoreLocation

enum TourKind: String, Codable {
    case single
    case multiStop
}

struct Tour: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let shortDescription: String
    let longDescription: String
    let makerId: UUID
    let heroImageURL: String
    let additionalImageURLs: [String]?
    /// Optional gallery videos (hosted as `.mp4` on gh-pages, same
    /// pipeline as images/audio). Rendered as extra swipeable pages at
    /// the end of the tour-detail / player photo carousel, after the
    /// images. `nil` (the common case) or empty → the carousel is
    /// image-only exactly as before. Additive + backward-compatible:
    /// a catalog without this key decodes to `nil`.
    let videoURLs: [String]?
    let kind: TourKind
    let stops: [Stop]
    let introAudioURL: String?
    let totalDurationSeconds: Int
    let walkingDistanceMeters: Int?
    let centroidLatitude: Double
    let centroidLongitude: Double
    let city: String?
    let primaryCategory: TourCategory
    let tags: [String]
    let priceUSD: Decimal
    /// Catalog-added date as an ISO `"YYYY-MM-DD"` string — the day this
    /// tour first appeared in `Tours.json` (derived from git history).
    /// Powers the maker page's Newest / Oldest sort. Stored as a String
    /// (not `Date`) so it needs no decoder date-strategy and sorts
    /// chronologically by plain lexicographic compare. **Optional** so
    /// tours added without it (e.g. by a concurrent content session)
    /// still decode — they sort last under Newest/Oldest.
    let createdAt: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centroidLatitude, longitude: centroidLongitude)
    }

    /// The lightweight primary tag derived from `tags` (owner decision
    /// D5), for one-label spots that will migrate off `primaryCategory`
    /// in Phase 3. `nil` only for a tagless tour. `primaryCategory` is
    /// still the source of truth for map pins + placeholders in Phase 2.
    var primaryTag: String? { Tag.derivePrimary(from: tags) }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let tourLocation = CLLocation(latitude: centroidLatitude, longitude: centroidLongitude)
        return location.distance(from: tourLocation)
    }
}

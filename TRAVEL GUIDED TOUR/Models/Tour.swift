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
    /// The city's country, as authored in the catalog.
    ///
    /// Denormalised onto the tour exactly as `city` is — there is no city
    /// entity to hang it off — so it travels with content and reaches
    /// phones over the air on a catalog merge, with no build. That is the
    /// point of storing it rather than deriving it from `city` in Swift:
    /// a city launch ships as content alone, so a lookup table compiled
    /// into the binary would start understating the moment one landed.
    ///
    /// Optional, and load-bearing: the bundled offline seed and the
    /// gh-pages mirror predate this key until they are republished, and
    /// maker-authored tours (`MakerTourService`) carry no country at all,
    /// so every one of those must keep decoding.
    let country: String?
    let primaryCategory: TourCategory
    let tags: [String]
    let priceUSD: Decimal
    /// The tour's price in **US cents**, or `nil` for free — which is the
    /// entire catalog today. One of the ten App Store tiers created in
    /// Phase 1 (99, 199, 299, 399, 499, 699, 899, 999, 1499, 1999).
    ///
    /// **Not the authority on what was paid.** `paid_tours.sql` CHECK-
    /// constrains the same closed set, and `record-purchase` re-checks the
    /// tier against the receipt server-side before granting anything. This
    /// value drives display + which StoreKit product to buy, nothing more.
    ///
    /// Optional so a catalog without the key (or an older cached copy)
    /// still decodes — absent means free, which is the safe default.
    let priceTier: Int?
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

    /// True when this tour must be bought before its audio will play.
    /// A `nil` or non-positive tier means free — the whole catalog today.
    var isPaid: Bool { (priceTier ?? 0) > 0 }

    /// The App Store product id backing this tour's tier, e.g. 299 →
    /// `"tour.tier.299"` and 99 → `"tour.tier.099"`. Zero-padded to **at
    /// least** three digits so it matches the products created by hand in
    /// App Store Connect (`tour.tier.099` … `tour.tier.1999`); four-digit
    /// tiers are already wide enough and pass through unpadded.
    ///
    /// `nil` for a free tour — there is nothing to buy.
    var storeProductId: String? {
        guard let tier = priceTier, tier > 0 else { return nil }
        return "tour.tier." + String(format: "%03d", tier)
    }

    /// Fallback price string (`"$2.99"`) for the rare moment before
    /// StoreKit's localized `displayPrice` is available. **Prefer
    /// `PurchaseService.displayPrice(for:)`** — this one is always USD, so
    /// it would misstate the price to a non-US storefront if it were the
    /// primary source.
    var fallbackPriceText: String? {
        guard let tier = priceTier, tier > 0 else { return nil }
        return String(format: "$%.2f", Double(tier) / 100)
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let tourLocation = CLLocation(latitude: centroidLatitude, longitude: centroidLongitude)
        return location.distance(from: tourLocation)
    }
}

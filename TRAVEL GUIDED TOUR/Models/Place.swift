import Foundation
import CoreLocation

/// A physical site that more than one tour describes.
///
/// Introduced 2026-08-18. Until now every tour owned its own map pin, so when
/// two tours sat on the same coordinate their pins merged into a cluster that
/// no camera could separate — the bug fixed provisionally in PR #512 by
/// stacking place cards. A `Place` is the durable answer: the site becomes the
/// thing on the map, and the tours become its contents.
///
/// **Identity is exact coordinate equality** (owner decision, 2026-08-18).
/// A looser proximity rule was measured against the live catalog first and
/// rejected: grouping anything within 40 m produced 43 places of which 19 were
/// wrong — it merged LACMA with the Academy Museum, two unrelated Sydney
/// restaurants, and chained three separate La Boca venues into one site through
/// transitive links. Exact matches are provably one place and need no editorial
/// judgement. Anything looser must be approved by a human, never auto-created.
///
/// A place is **content**, so it travels in `Tours.json` alongside makers and
/// tours rather than living only in Supabase. That keeps it in the gh-pages
/// mirror, the on-disk cache and the bundled offline seed — the app has to work
/// with no signal, and a place pin that only exists online would vanish exactly
/// when someone is standing in front of the building.
struct Place: Codable, Identifiable, Hashable {
    let id: UUID
    /// Editorial name of the site — the place, not any one tour about it.
    let name: String
    /// One or two editorial sentences. Optional so a place can ship before its
    /// copy is written.
    let description: String?
    let latitude: Double
    let longitude: Double
    let city: String?
    /// Street address, shown beside the distance on the place page. Optional —
    /// the catalog has never stored addresses, so these are backfilled.
    let address: String?
    /// Editorial hero. **Optional by design**: when absent the place page falls
    /// back to the hero of its top-ranked tour, so a place is never blocked on
    /// a new image being sourced.
    let heroImageURL: String?
    /// Further photos of the site, shown after the hero in the place page's
    /// carousel. Empty everywhere today — the field exists so the place page can
    /// use the **same** `TourMediaCarousel` a tour page and the player use, which
    /// is what stops the two carousels drifting apart later. With nothing here the
    /// carousel renders exactly as a single image did.
    let additionalImageURLs: [String]?
    /// Membership only — **not** display order. Ranking is applied at render
    /// time by `ranked(_:)` so it can change without a content re-seed.
    let tourIds: [UUID]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Order the tours of a place for display.
    ///
    /// **Newest first** (owner decision, 2026-08-18 — explicitly provisional,
    /// to be revisited once there is real usage data to rank on).
    ///
    /// ⚠️ The two tiebreaks are load-bearing, not decoration. Both tours at a
    /// place are almost always published in the same city batch, so their
    /// `createdAt` values tie exactly — 22 of the 24 places in the catalog
    /// today. Without a tiebreak the order is whatever the array happened to
    /// hold, which reads as random to someone comparing two place pages.
    ///
    ///  1. `createdAt` descending; a tour with no date sorts last.
    ///  2. On a tie, the **single-stop tour before the walk** — someone
    ///     standing at Dorchester Square wants the tour *about* the square
    ///     ahead of the walk that merely begins there.
    ///  3. Then title, so the result is fully deterministic.
    static func ranked(_ tours: [Tour]) -> [Tour] {
        tours.sorted { a, b in
            let da = a.createdAt ?? ""
            let db = b.createdAt ?? ""
            if da != db { return da > db }
            if (a.kind == .single) != (b.kind == .single) { return a.kind == .single }
            return a.title < b.title
        }
    }
}

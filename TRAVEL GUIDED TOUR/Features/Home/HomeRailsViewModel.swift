import Foundation
import CoreLocation
import MapKit

/// Pure function over the home screen's inputs that returns the
/// ordered list of rails to display, with empty rails dropped.
/// No state — recomputed every render, which is cheap for V1's tiny
/// catalog.
///
/// Order matches the spec § Key screens #1 ranking:
///   personalized → location-anchored → interest (curated tag shelves)
struct HomeRail: Identifiable {
    let id: String
    let title: String
    let tours: [Tour]
}

enum HomeRailsViewModel {
    static let maxPerRail = 10
    /// Pan threshold: once the visible region's center is at least this
    /// far from the user, the map counts as "panned away" — the top
    /// location rail swaps from "Near you" to "In view" and "Near you"
    /// is hidden (§1.5, owner-confirmed: NYC tours are noise while
    /// looking at Tokyo).
    static let inViewPanThresholdMeters: Double = 500

    static func rails(
        tours: [Tour],
        libraryEntries: [LibraryEntry],
        recentlyViewedIds: [UUID],
        userLocation: CLLocation?,
        visibleRegion: MKCoordinateRegion?
    ) -> [HomeRail] {
        var rails: [HomeRail] = []

        // Personalized
        if let rail = continueListeningRail(tours: tours, libraryEntries: libraryEntries) {
            rails.append(rail)
        }
        if let rail = recentlyViewedRail(tours: tours, recentlyViewedIds: recentlyViewedIds) {
            rails.append(rail)
        }

        // Location-anchored — one top rail, context-aware (§1.5):
        //   • Near mode (map over the user): "Near you".
        //   • Far mode (panned to another area): "In view", and "Near
        //     you" is hidden entirely.
        if isPannedFar(userLocation: userLocation, visibleRegion: visibleRegion) {
            if let rail = inViewRail(tours: tours, visibleRegion: visibleRegion) {
                rails.append(rail)
            }
        } else {
            if let rail = nearYouRail(tours: tours, userLocation: userLocation) {
                rails.append(rail)
            }
        }

        // Interest-based — the curated tag shelves (owner decision D7),
        // in editorial order. Hide shelves with zero matching tours.
        // Within each shelf the tours are ordered by distance from the
        // *map viewport center* (§1.5) so the nearest tours of that
        // interest surface first — meaningful whether the user is home
        // or browsing another city.
        let viewer = viewerLocation(userLocation: userLocation, visibleRegion: visibleRegion)
        for shelf in Tag.curatedShelves {
            let matching = tours.filter { $0.tags.contains(shelf.tag) }
            if matching.isEmpty { continue }
            let ordered = sortedByDistance(matching, from: viewer)
            rails.append(
                HomeRail(
                    id: "shelf.\(shelf.tag)",
                    title: shelf.title,
                    tours: Array(ordered.prefix(maxPerRail))
                )
            )
        }

        return rails
    }

    /// Flat, distance-sorted result list for when a filter is active
    /// (owner decision D8 — the drawer swaps its shelves for this).
    /// Combines per D6 plus the "Walks" format filter (§1.6); orders by
    /// distance from the map viewport center (§1.5). Pure + testable.
    static func filteredResults(
        tours: [Tour],
        selectedTags: Set<String>,
        walksOnly: Bool,
        userLocation: CLLocation?,
        visibleRegion: MKCoordinateRegion?
    ) -> [Tour] {
        let matched = tours.filter { tour in
            if walksOnly && tour.kind != .multiStop { return false }
            return Tag.matches(tourTags: Set(tour.tags), selection: selectedTags)
        }
        let viewer = viewerLocation(userLocation: userLocation, visibleRegion: visibleRegion)
        return sortedByDistance(matched, from: viewer)
    }

    // MARK: - Location helpers

    /// The reference point for distance-based ordering: the **map
    /// viewport center** when known (so shelves rank by what the user is
    /// looking at — §1.5), falling back to the user's location. `nil`
    /// only before any camera settle *and* before the first location
    /// fix, in which case callers keep catalog order.
    private static func viewerLocation(
        userLocation: CLLocation?,
        visibleRegion: MKCoordinateRegion?
    ) -> CLLocation? {
        if let visibleRegion {
            return CLLocation(
                latitude: visibleRegion.center.latitude,
                longitude: visibleRegion.center.longitude
            )
        }
        return userLocation
    }

    /// Sort by distance from `viewer`, computing each tour's distance
    /// exactly **once** (decorate → sort → undecorate) rather than on
    /// every comparison. `Array.sorted`'s comparator runs O(n log n)
    /// times, and `Tour.distance(from:)` allocates a fresh `CLLocation`
    /// and runs a geodesic calc each call — so the naïve
    /// `sorted { $0.distance < $1.distance }` did ~n·log n such
    /// allocations per shelf. Over 13 shelves × ~790 tours that was
    /// ~100k allocations per map-settle (the visible hitch on pan
    /// release once the catalog spans many cities). This makes it n
    /// distance computations per shelf. Result order is identical (same
    /// comparator, ties unspecified in both).
    private static func sortedByDistance(_ tours: [Tour], from viewer: CLLocation?) -> [Tour] {
        guard let viewer else { return tours }
        return tours
            .map { (tour: $0, distance: $0.distance(from: viewer)) }
            .sorted { $0.distance < $1.distance }
            .map(\.tour)
    }

    /// True when the map has been panned far enough from the user that
    /// "Near you" is no longer the right top rail. With no user fix we
    /// can't compute "near", so any settled region counts as far (show
    /// "In view"); with a user but no region yet, treat as near.
    static func isPannedFar(
        userLocation: CLLocation?,
        visibleRegion: MKCoordinateRegion?
    ) -> Bool {
        guard let userLocation else { return visibleRegion != nil }
        guard let visibleRegion else { return false }
        let center = CLLocation(
            latitude: visibleRegion.center.latitude,
            longitude: visibleRegion.center.longitude
        )
        return userLocation.distance(from: center) >= inViewPanThresholdMeters
    }

    // MARK: - Rail builders

    private static func continueListeningRail(
        tours: [Tour],
        libraryEntries: [LibraryEntry]
    ) -> HomeRail? {
        let inProgressIds = libraryEntries
            .filter { $0.listenedSeconds > 0 && $0.completedAt == nil }
            .sorted { ($0.lastListenedAt ?? .distantPast) > ($1.lastListenedAt ?? .distantPast) }
            .map { $0.tourId }

        let matched = inProgressIds.compactMap { id in
            tours.first { $0.id == id }
        }

        guard !matched.isEmpty else { return nil }
        return HomeRail(
            id: "continueListening",
            title: "Continue listening",
            tours: Array(matched.prefix(maxPerRail))
        )
    }

    private static func recentlyViewedRail(
        tours: [Tour],
        recentlyViewedIds: [UUID]
    ) -> HomeRail? {
        let matched = recentlyViewedIds.compactMap { id in
            tours.first { $0.id == id }
        }
        guard !matched.isEmpty else { return nil }
        return HomeRail(
            id: "recentlyViewed",
            title: "Recently viewed",
            tours: Array(matched.prefix(maxPerRail))
        )
    }

    private static func nearYouRail(
        tours: [Tour],
        userLocation: CLLocation?
    ) -> HomeRail? {
        guard let userLocation else { return nil }
        let sorted = sortedByDistance(tours, from: userLocation).prefix(maxPerRail)
        guard !sorted.isEmpty else { return nil }
        return HomeRail(id: "nearYou", title: "Near you", tours: Array(sorted))
    }

    private static func inViewRail(
        tours: [Tour],
        visibleRegion: MKCoordinateRegion?
    ) -> HomeRail? {
        guard let visibleRegion else { return nil }
        let center = CLLocation(
            latitude: visibleRegion.center.latitude,
            longitude: visibleRegion.center.longitude
        )
        let matching = sortedByDistance(
            tours.filter { visibleRegion.contains($0.coordinate) },
            from: center
        )
        guard !matching.isEmpty else { return nil }
        return HomeRail(
            id: "inView",
            title: "In view",
            tours: Array(matching.prefix(maxPerRail))
        )
    }
}

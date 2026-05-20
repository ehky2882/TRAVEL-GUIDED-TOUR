import Foundation
import CoreLocation
import MapKit

/// Pure function over the home screen's inputs that returns the
/// ordered list of rails to display, with empty rails dropped.
/// No state — recomputed every render, which is cheap for V1's tiny
/// catalog.
///
/// Order matches the spec § Key screens #1 ranking:
///   personalized → location-anchored → interest-based
struct HomeRail: Identifiable {
    let id: String
    let title: String
    let tours: [Tour]
}

enum HomeRailsViewModel {
    static let maxPerRail = 10
    /// "In view" rail only surfaces when the visible region's center
    /// is at least this far from the user — otherwise it overlaps
    /// "Near you" too much to be useful.
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

        // Location-anchored
        if let rail = nearYouRail(tours: tours, userLocation: userLocation) {
            rails.append(rail)
        }
        if let rail = inViewRail(tours: tours, userLocation: userLocation, visibleRegion: visibleRegion) {
            rails.append(rail)
        }

        // Interest-based — one per category, in TourCategory case order.
        // Hide categories with zero tours.
        for category in TourCategory.allCases {
            let matching = tours.filter { $0.primaryCategory == category }
            if matching.isEmpty { continue }
            rails.append(
                HomeRail(
                    id: "category.\(category.rawValue)",
                    title: category.displayName,
                    tours: Array(matching.prefix(maxPerRail))
                )
            )
        }

        return rails
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
        let sorted = tours
            .sorted { $0.distance(from: userLocation) < $1.distance(from: userLocation) }
            .prefix(maxPerRail)
        guard !sorted.isEmpty else { return nil }
        return HomeRail(id: "nearYou", title: "Near you", tours: Array(sorted))
    }

    private static func inViewRail(
        tours: [Tour],
        userLocation: CLLocation?,
        visibleRegion: MKCoordinateRegion?
    ) -> HomeRail? {
        guard let visibleRegion else { return nil }

        // Hide if map is still near the user's location — "Near you"
        // already covers this case.
        if let userLocation {
            let visibleCenter = CLLocation(
                latitude: visibleRegion.center.latitude,
                longitude: visibleRegion.center.longitude
            )
            if userLocation.distance(from: visibleCenter) < inViewPanThresholdMeters {
                return nil
            }
        }

        let matching = tours.filter { tour in
            visibleRegion.contains(tour.coordinate)
        }
        guard !matching.isEmpty else { return nil }

        return HomeRail(
            id: "inView",
            title: "In view",
            tours: Array(matching.prefix(maxPerRail))
        )
    }
}


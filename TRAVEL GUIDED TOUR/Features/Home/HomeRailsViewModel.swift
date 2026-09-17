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

    /// - Parameter toursByTag: tag → the tours carrying it, prebuilt by
    ///   `DataService`. Optional so every existing caller and test keeps
    ///   working; when it is nil each shelf falls back to filtering the whole
    ///   catalog, which is correct but is what made the map hitch on arrival.
    ///   Pass it from anything that re-renders when the map region changes.
    /// ⚠️ No `libraryEntries` any more. It existed only to build the
    /// **Continue listening** rail, which the owner removed outright on
    /// 2026-09-13 — so the parameter went with it rather than sitting here
    /// unread. Listening PROGRESS is untouched: it still drives the resume
    /// position and Library's in-progress state.
    static func rails(
        tours: [Tour],
        recentlyViewedIds: [UUID],
        userLocation: CLLocation?,
        visibleRegion: MKCoordinateRegion?,
        toursByTag: [String: [Tour]]? = nil,
        /// Candidate seeds, best first. Defaulted empty so every existing
        /// caller and test is untouched — and so that removing this rail later
        /// means deleting one function and one call, the way *Continue
        /// listening* was removed on 2026-09-13.
        savedTourIds: [UUID] = [],
        /// 🔴 EVERYTHING SAVED, from BOTH stores — not just `savedTourIds`.
        /// A tour is saved when it is in Liked **or** any named list
        /// (`SaveState`), and the first version of this rail read only Liked.
        /// It is passed in rather than derived from `savedTourIds` because the
        /// seed order and the full membership are different questions: only
        /// Liked carries a timestamp, so only Liked can be ordered.
        savedTourIdSet: Set<UUID> = [],
        /// `relatedTourIds`, already in the catalogue and already on the phone.
        /// Passed as a closure so this stays a pure function over its inputs —
        /// `DataService.relatedTours(for:)` is the real implementation.
        relatedTours: ((Tour) -> [Tour])? = nil
    ) -> [HomeRail] {
        var rails: [HomeRail] = []

        // Personalized
        if let rail = recentlyViewedRail(tours: tours, recentlyViewedIds: recentlyViewedIds) {
            rails.append(rail)
        }
        if let rail = becauseYouSavedRail(
            tours: tours,
            savedTourIds: savedTourIds,
            savedTourIdSet: savedTourIdSet.isEmpty ? Set(savedTourIds) : savedTourIdSet,
            relatedTours: relatedTours
        ) {
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
        // viewer anchor (see `viewerLocation`): the user's own location
        // when they're on screen, else the map viewport center when
        // panned away — so the nearest tours of that interest surface
        // first whether the user is home or browsing another city.
        let viewer = viewerLocation(userLocation: userLocation, visibleRegion: visibleRegion)
        for shelf in Tag.curatedShelves {
            // One dictionary lookup where this used to be a full pass over the
            // catalog — thirteen shelves x 1,512 tours, on every render, and a
            // render is triggered every time the map region settles. The
            // fallback keeps the old behaviour for callers that pass no index.
            let matching = toursByTag?[shelf.tag]
                ?? tours.filter { $0.tags.contains(shelf.tag) }
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
    /// Applies `TourFilter` and orders by distance from the map viewport
    /// center (§1.5). Pure + testable.
    /// A tag → tours index over an arbitrary tour set.
    ///
    /// `DataService.toursByTagIndex` is the prebuilt one for the WHOLE
    /// catalogue, and it exists because thirteen shelves each filtering 1,552
    /// tours on every camera settle made the map hitch. With a filter on, the
    /// shelves are built from the matching set instead, which has no prebuilt
    /// index — so this builds one, once, from a list the drawer has already
    /// computed for its header.
    ///
    /// ⚠️ It is a **one-pass** build (tours × their own tags) rather than
    /// thirteen passes over the set, which is the whole point: a weak filter
    /// like `Free` matches most of the catalogue, so the naive version would
    /// reinstate exactly the hitch the index was added to remove.
    static func tagIndex(for tours: [Tour]) -> [String: [Tour]] {
        var index: [String: [Tour]] = [:]
        for tour in tours {
            for tag in tour.tags {
                index[tag, default: []].append(tour)
            }
        }
        return index
    }

    /// How many of `tours` have at least one stop inside the map's current
    /// view.
    ///
    /// 🔴 **The drawer's header is a MAP stat, filtered or not.** Unfiltered it
    /// has always read "N TOURS IN VIEW"; filtered it read the whole
    /// catalogue's match count, so panning changed nothing and `District` said
    /// **270 RESULTS** over the US east coast — a number about everywhere,
    /// printed over a map of somewhere (owner, on device, 2026-09-13).
    ///
    /// ⚠️ A `nil` region means the map has not reported one yet — count
    /// everything rather than nothing, so the header cannot flash a zero it
    /// does not mean.
    ///
    /// ⚠️ Membership is by STOP, matching `toursInViewCount` and the map's own
    /// pins: a walk is in view when any of its stops is, which is the only
    /// reading that agrees with what you can see.
    static func countInView(_ tours: [Tour], region: MKCoordinateRegion?) -> Int {
        guard let region else { return tours.count }
        return tours.reduce(into: 0) { total, tour in
            if tour.stops.contains(where: { region.contains($0.coordinate) }) { total += 1 }
        }
    }

    static func filteredResults(
        tours: [Tour],
        filter: TourFilter,
        userLocation: CLLocation?,
        visibleRegion: MKCoordinateRegion?
    ) -> [Tour] {
        let matched = tours.filter(filter.matches)
        let viewer = viewerLocation(userLocation: userLocation, visibleRegion: visibleRegion)
        return sortedByDistance(matched, from: viewer)
    }

    // MARK: - Location helpers

    /// The reference point for distance-based ordering. The **user's own
    /// location is the primary anchor** — owner call (2026-07-20): rails
    /// should rank by how close a tour is to *you*, especially when
    /// you're on screen. So we return `userLocation` whenever the user is
    /// known and either there's no settled region yet or the region
    /// actually contains the user. Only when the map has been panned away
    /// to an area that no longer shows the user do we fall back to the
    /// **map viewport center**, so browsing another city still ranks by
    /// what's in view (§1.5). `nil` only before any camera settle *and*
    /// before the first location fix, in which case callers keep catalog
    /// order.
    private static func viewerLocation(
        userLocation: CLLocation?,
        visibleRegion: MKCoordinateRegion?
    ) -> CLLocation? {
        if let userLocation {
            // User on screen (or no region yet) → rank by distance to the
            // user. Panned away → viewport center.
            if let visibleRegion, !visibleRegion.contains(userLocation.coordinate) {
                return CLLocation(
                    latitude: visibleRegion.center.latitude,
                    longitude: visibleRegion.center.longitude
                )
            }
            return userLocation
        }
        // No user fix — fall back to the viewport center when we have one.
        if let visibleRegion {
            return CLLocation(
                latitude: visibleRegion.center.latitude,
                longitude: visibleRegion.center.longitude
            )
        }
        return nil
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

    /// "Because you saved …" — neighbours of something already in the library.
    ///
    /// 🔴 NO MODEL AND NO DOWNLOAD. `relatedTourIds` is computed offline and
    /// already ships in the catalogue, so this is a dictionary lookup. An
    /// earlier sketch of this rail proposed scoring it on the device from the
    /// search embeddings, which would have meant an async actor and a 4 MB
    /// file inside a pure synchronous function recomputed on every render.
    ///
    /// ⚠️ SEEDED FROM ONE TOUR, not a blend of everything saved, so the title
    /// can name it honestly. A rail headed "Because you saved Trellick Tower"
    /// that is secretly an average of nine tours is a small lie that makes
    /// every suggestion in it unexplainable.
    private static func becauseYouSavedRail(
        tours: [Tour],
        savedTourIds: [UUID],
        savedTourIdSet: Set<UUID>,
        relatedTours: ((Tour) -> [Tour])?
    ) -> HomeRail? {
        guard let relatedTours, !savedTourIds.isEmpty else { return nil }
        // ⚠️ The exclusion set is the UNION, not the seed list. Suggesting a
        // tour the user already has in a named list is the same mistake as
        // suggesting one they Liked — it just hid behind a different store.
        let saved = savedTourIdSet

        // Most recent first, and skip anything with no neighbours rather than
        // rendering an empty rail under a confident heading.
        for id in savedTourIds {
            guard let seed = tours.first(where: { $0.id == id }) else { continue }
            let suggestions = relatedTours(seed).filter { !saved.contains($0.id) }
            guard !suggestions.isEmpty else { continue }
            return HomeRail(
                id: "becauseYouSaved.\(id.uuidString)",
                title: "Because you saved \(seed.title)",
                tours: Array(suggestions.prefix(maxPerRail))
            )
        }
        return nil
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
        // 🔴 Match the drawer header's definition of "in view": a tour
        // counts when **any of its stops** is on screen. Filtering on
        // `tour.coordinate` — the centroid — silently disagreed with the
        // header for multi-stop walks, because a walk's centroid is the
        // mean of stops that can be a kilometre apart. Standing at
        // Dorchester Square the header said "2 TOURS IN VIEW" while this
        // rail listed one: the Downtown walk's first stop was under the
        // map, but its centroid sat 197 m away, outside the viewport.
        // Ordering still uses the centroid, which is the right summary
        // of where a whole walk is.
        let matching = sortedByDistance(
            tours.filter { tour in
                tour.stops.contains { visibleRegion.contains($0.coordinate) }
            },
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

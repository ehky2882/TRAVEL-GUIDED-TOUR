import CoreLocation
import Foundation

/// Turns a catalog into the pins a map draws.
///
/// Lives outside both map views so the home map and the maker map cannot
/// disagree about what a pin means — the two have drifted before, and a pin
/// that means "zoom in" on one screen and "open me" on the other is the exact
/// confusion the place layer exists to remove.
///
/// Two rules:
///
///  1. **One pin per tour.** A walk contributes only its entry stop
///     (`order == 0`), so a six-stop walk doesn't scatter six pins across a
///     city for what is one thing to open.
///  2. **Tours that share a place collapse into one pin for the place.** That
///     is what stops two tours at an identical coordinate producing a cluster
///     no camera could separate.
enum MapMarkers {

    /// Build the marker set for `tours`, collapsing any that belong to a place
    /// in `places`.
    ///
    /// `places` may describe tours this map isn't showing — a maker page passes
    /// only that maker's work — so a place is only collapsed when **at least
    /// two** of its tours are actually present. With fewer, the surviving tour
    /// draws its own ordinary pin, because a place pin reading "1" would be a
    /// lie about what tapping it gives you.
    static func markers(
        for tours: [Tour],
        places: [Place]
    ) -> [MapClustering.StopMarker] {
        let toursById = Dictionary(tours.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        var placeMarkers: [MapClustering.StopMarker] = []
        var collapsed = Set<UUID>()

        for place in places {
            let present = place.tourIds.filter { toursById[$0] != nil }
            guard present.count >= 2 else { continue }

            // The tap target behind a place is its top-ranked tour, so any
            // caller that only knows how to open a tour still does something
            // sensible rather than nothing.
            let ranked = Place.ranked(present.compactMap { toursById[$0] })
            guard let lead = ranked.first else { continue }

            placeMarkers.append(
                MapClustering.StopMarker(
                    id: place.id,
                    tourId: lead.id,
                    title: place.name,
                    coordinate: place.coordinate,
                    placeId: place.id,
                    placeTourCount: present.count
                )
            )
            collapsed.formUnion(present)
        }

        let tourMarkers = tours
            .filter { !collapsed.contains($0.id) }
            .flatMap { tour in
                tour.stops
                    .filter { tour.kind == .single || $0.order == 0 }
                    .map { stop in
                        MapClustering.StopMarker(
                            id: stop.id,
                            tourId: tour.id,
                            title: stop.title,
                            coordinate: stop.coordinate
                        )
                    }
            }

        return placeMarkers + tourMarkers
    }
}

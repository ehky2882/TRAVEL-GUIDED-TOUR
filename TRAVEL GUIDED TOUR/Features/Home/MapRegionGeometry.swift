import MapKit
import CoreLocation

/// Helper for deciding whether a place the user flew to via search has
/// any Atlas tour pins in view — and therefore whether to show the
/// "No Atlas tours here yet" overlay. Kept free of any view state so
/// it's unit-testable without a running map. The point-in-region test
/// reuses `MKCoordinateRegion.contains(_:)` (antimeridian-aware).
enum MapRegionGeometry {
    /// True if any stop of any tour falls inside `region`.
    static func anyStop(of tours: [Tour], inside region: MKCoordinateRegion) -> Bool {
        tours.contains { tour in
            tour.stops.contains { region.contains($0.coordinate) }
        }
    }
}

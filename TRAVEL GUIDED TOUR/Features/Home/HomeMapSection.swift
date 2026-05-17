import SwiftUI
import MapKit
import CoreLocation

/// Map section at the top of the home screen. Renders a pin per stop
/// across `tours`, centered on the user's location (or an NYC default
/// when location is denied / unavailable). Reports the visible
/// region's center after every pan so the parent can update the
/// "in view" count, and reports the tapped tour upward via
/// `onTourSelected` so the parent can scroll its drawer to that
/// tour's card (AllTrails pattern).
///
/// Selection state is owned by the parent via `selectedTourId` so the
/// pin and the drawer card can be kept visually in sync.
struct HomeMapSection: View {
    let tours: [Tour]
    let userLocation: CLLocation?
    @Binding var selectedTourId: UUID?
    /// Fires after a pan settles. The parent uses this to recompute
    /// the in-view tour count and any location-anchored UI.
    let onCameraChanged: (MKCoordinateRegion) -> Void

    /// Internal selection state for `Map(selection:)`. We resolve
    /// stop-id → parent tour-id and push that up through the binding.
    @State private var selectedStopId: UUID?

    /// Fallback when user location is unknown. NYC, since V1 seed
    /// content is NYC-based.
    private let defaultCenter = CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857)
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)

    var body: some View {
        Map(initialPosition: .region(initialRegion), selection: $selectedStopId) {
            ForEach(allStopMarkers, id: \.id) { marker in
                Marker(marker.title, systemImage: marker.systemImage, coordinate: marker.coordinate)
                    .tint(AtlasColors.accent)
                    .tag(marker.id)
            }

            if userLocation != nil {
                UserAnnotation()
            }
        }
        .mapControls {
            MapCompass()
            MapUserLocationButton()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            onCameraChanged(context.region)
        }
        .onChange(of: selectedStopId, initial: false) { _, newStopId in
            selectedTourId = tourId(forStopId: newStopId)
        }
        .onChange(of: selectedTourId, initial: false) { _, newTourId in
            // Allow the parent to clear selection (e.g. user tapped
            // empty space in the drawer or scrolled away).
            if newTourId == nil { selectedStopId = nil }
        }
    }

    // MARK: - Derived

    private var initialRegion: MKCoordinateRegion {
        let center = userLocation?.coordinate ?? defaultCenter
        return MKCoordinateRegion(center: center, span: defaultSpan)
    }

    /// All stops across every tour, flattened into pin descriptors.
    private var allStopMarkers: [StopMarker] {
        tours.flatMap { tour in
            tour.stops.map { stop in
                StopMarker(
                    id: stop.id,
                    title: stop.title,
                    systemImage: tour.primaryCategory.iconName,
                    coordinate: stop.coordinate
                )
            }
        }
    }

    private func tourId(forStopId stopId: UUID?) -> UUID? {
        guard let stopId else { return nil }
        return tours.first(where: { tour in
            tour.stops.contains { $0.id == stopId }
        })?.id
    }
}

private struct StopMarker: Identifiable {
    let id: UUID
    let title: String
    let systemImage: String
    let coordinate: CLLocationCoordinate2D
}

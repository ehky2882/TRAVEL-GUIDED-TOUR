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
    /// Device compass heading in degrees (0 = true north). When
    /// present, the user-location dot shows a directional wedge.
    let userHeading: CLLocationDirection?
    @Binding var selectedTourId: UUID?
    @Binding var cameraPosition: MapCameraPosition
    /// Fires after a pan settles. The parent uses this to recompute
    /// the in-view tour count and any location-anchored UI.
    let onCameraChanged: (MKCoordinateRegion) -> Void
    /// Fires on every camera-change frame while the user is panning or
    /// flinging the map (`.continuous` frequency). The parent uses this
    /// to retract the drawer and fade the recenter button.
    let onCameraMoving: () -> Void

    /// Internal selection state for `Map(selection:)`. We resolve
    /// stop-id → parent tour-id and push that up through the binding.
    @State private var selectedStopId: UUID?

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedStopId) {
            ForEach(allStopMarkers, id: \.id) { marker in
                Marker(marker.title, systemImage: marker.systemImage, coordinate: marker.coordinate)
                    .tint(AtlasColors.accent)
                    .tag(marker.id)
            }

            if let userLocation {
                Annotation("My location", coordinate: userLocation.coordinate, anchor: .center) {
                    UserLocationDot(headingDegrees: wedgeRotationDegrees)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .continuous) { _ in
            onCameraMoving()
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

    /// Screen-space rotation for the user-dot's heading wedge, in
    /// degrees — equal to the device compass heading so the wedge
    /// points the real-world direction the user is facing.
    /// `nil` hides the wedge when heading is unavailable.
    private var wedgeRotationDegrees: Double? {
        userHeading
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

/// iOS-Maps-style user-location indicator: a soft accuracy halo, an
/// optional directional wedge showing which way the device is
/// facing, and the blue dot itself. All colors are explicit (not
/// `.tint`-derived) so the dot stays Apple-Maps blue rather than
/// inheriting the terracotta app accent.
private struct UserLocationDot: View {
    /// Screen-space rotation for the heading wedge, in degrees
    /// (0 = pointing up). `nil` hides the wedge.
    let headingDegrees: Double?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 46, height: 46)

            if let headingDegrees {
                HeadingWedge()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.55), Color.blue.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 34, height: 26)
                    .offset(y: -16)
                    .rotationEffect(.degrees(headingDegrees))
            }

            Circle()
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.25), radius: 1.5)
        }
        .frame(width: 46, height: 46)
    }
}

/// A fan/cone — apex at bottom-center (over the dot), spreading
/// toward the top. Rotated by the device heading so it points the
/// way the user is facing.
private struct HeadingWedge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.55)
        )
        path.closeSubpath()
        return path
    }
}

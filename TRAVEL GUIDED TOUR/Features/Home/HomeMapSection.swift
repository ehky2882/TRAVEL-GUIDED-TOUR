import SwiftUI
import MapKit
import CoreLocation

/// Map section at the top of the home screen. Renders a pin per stop
/// across every tour, centered on the user's location (or an NYC
/// default if location is denied / unavailable). Reports the visible
/// region's center after every pan so the parent can recompute the
/// "In view" rail. Tapping a pin reveals a preview card with a
/// NavigationLink into `TourDetailView`.
struct HomeMapSection: View {
    let tours: [Tour]
    let userLocation: CLLocation?
    /// Fires after a pan settles. The parent uses this to recompute
    /// location-anchored rails for the area now in view.
    let onCameraChanged: (MKCoordinateRegion) -> Void

    @State private var selectedStopId: UUID?

    /// Fallback when user location is unknown. NYC, since V1 seed
    /// content is NYC-based. Reasonable global default could replace
    /// this in M-launch-content once content scope is final.
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
        .overlay(alignment: .bottom) {
            if let tour = selectedTour {
                tourPreviewCard(tour)
                    .padding(.horizontal, AtlasSpacing.md)
                    .padding(.bottom, AtlasSpacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.2), value: selectedStopId)
    }

    // MARK: - Preview card

    /// Tapping the card opens TourDetailView. NavigationLink resolves
    /// against the NavigationStack that wraps HomeView. Close button
    /// clears the selection.
    private func tourPreviewCard(_ tour: Tour) -> some View {
        HStack(spacing: AtlasSpacing.md) {
            NavigationLink {
                TourDetailView(tour: tour)
            } label: {
                HStack(spacing: AtlasSpacing.md) {
                    HeroImageView(
                        imageName: tour.heroImageURL,
                        height: 56,
                        cornerRadius: 8,
                        category: tour.primaryCategory
                    )
                    .frame(width: 56)

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        Text(tour.title)
                            .font(AtlasTypography.body)
                            .foregroundStyle(AtlasColors.primaryText)
                            .lineLimit(1)
                        Text(tour.shortDescription)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            Button {
                selectedStopId = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close preview")
        }
        .padding(AtlasSpacing.md)
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
        .shadow(color: AtlasColors.cardShadow, radius: 8, y: 2)
    }

    // MARK: - Derived

    private var initialRegion: MKCoordinateRegion {
        let center = userLocation?.coordinate ?? defaultCenter
        return MKCoordinateRegion(center: center, span: defaultSpan)
    }

    /// All stops across every tour, flattened into pin descriptors.
    /// Duplicate coordinates are possible if two tours share a stop —
    /// each tour gets its own pin. Acceptable for V1's tiny catalog.
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

    /// Resolve the tapped stop back to its parent tour. A stop is
    /// owned by exactly one tour in the V1 data model.
    private var selectedTour: Tour? {
        guard let stopId = selectedStopId else { return nil }
        return tours.first { tour in
            tour.stops.contains { $0.id == stopId }
        }
    }
}

private struct StopMarker: Identifiable {
    let id: UUID
    let title: String
    let systemImage: String
    let coordinate: CLLocationCoordinate2D
}

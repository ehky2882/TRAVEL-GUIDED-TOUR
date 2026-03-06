import SwiftUI
import MapKit

struct MapView: View {
    var city: City? = nil
    @Environment(DataService.self) private var dataService
    @Environment(LocationManager.self) private var locationManager
    @State private var selectedPlace: Place?
    @State private var selectedCity: City?
    @State private var position: MapCameraPosition = .automatic
    @State private var hasSetInitialPosition = false

    private var displayCity: City? {
        if let city { return city }
        if let selectedCity { return selectedCity }
        if let location = locationManager.userLocation {
            return dataService.nearestCity(to: location)
        }
        return dataService.cities.first
    }

    private var displayPlaces: [Place] {
        guard let c = displayCity else { return [] }
        return dataService.places(for: c)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position, selection: $selectedPlace) {
                ForEach(displayPlaces) { place in
                    Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
                        PlaceAnnotationView(place: place, isSelected: selectedPlace?.id == place.id)
                    }
                    .tag(place)
                }

                UserAnnotation()
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onAppear {
                if !hasSetInitialPosition, let c = displayCity {
                    setCameraToCity(c)
                    hasSetInitialPosition = true
                }
                if city == nil, selectedCity == nil {
                    selectedCity = displayCity
                }
            }

            VStack {
                if city == nil {
                    cityPicker
                }
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        guard let location = locationManager.userLocation else { return }
                        withAnimation {
                            position = .region(MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            ))
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .background(.white)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, AtlasSpacing.lg)
                    .padding(.bottom, AtlasSpacing.sm)
                }
                if let place = selectedPlace {
                    placeCard(place)
                }
            }
        }
        .navigationTitle(displayCity?.name ?? "Map")
        .inlineNavigationBarTitle()
    }

    private func setCameraToCity(_ c: City) {
        let span: Double = city != nil ? 0.04 : 0.06
        position = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        ))
    }

    private var cityPicker: some View {
        HStack {
            Picker("City", selection: $selectedCity) {
                ForEach(dataService.cities) { c in
                    Text(c.name).tag(c as City?)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AtlasSpacing.lg)
            .onChange(of: selectedCity) { _, newCity in
                if let c = newCity {
                    withAnimation {
                        setCameraToCity(c)
                    }
                    selectedPlace = nil
                }
            }
        }
        .padding(.top, AtlasSpacing.sm)
    }

    private func placeCard(_ place: Place) -> some View {
        NavigationLink(value: place) {
            HStack(spacing: AtlasSpacing.md) {
                HeroImageView(imageName: place.thumbnailURL, height: 70, cornerRadius: 8)
                    .frame(width: 70)

                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    Text(place.category.displayName.uppercased())
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                        .tracking(0.8)
                    Text(place.name)
                        .font(AtlasTypography.headline)
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    HStack(spacing: AtlasSpacing.sm) {
                        if let neighborhood = place.neighborhood {
                            Text(neighborhood)
                                .font(AtlasTypography.caption)
                                .foregroundStyle(.black)
                        }
                        if let distance = locationManager.distanceString(to: place) {
                            Text("· \(distance)")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(.black)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
            }
            .padding(AtlasSpacing.md)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.bottom, AtlasSpacing.lg)
        }
        .buttonStyle(.plain)
    }
}

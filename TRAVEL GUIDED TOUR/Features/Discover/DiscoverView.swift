import SwiftUI
import CoreLocation

struct DiscoverView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LocationManager.self) private var locationManager
    @Environment(CollectionStore.self) private var collectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false

    private var nearestCity: City? {
        guard let location = locationManager.userLocation else { return nil }
        guard let city = dataService.nearestCity(to: location) else { return nil }
        let distance = CLLocation(latitude: city.latitude, longitude: city.longitude).distance(from: location)
        return distance < 50_000 ? city : nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.xl) {
                    headerSection

                    if let city = nearestCity {
                        youAreHereCard(city: city)
                    }

                    citiesSection

                    // Divider line
                    Rectangle()
                        .fill(AtlasColors.secondaryText.opacity(0.12))
                        .frame(height: 0.5)
                        .padding(.horizontal, AtlasSpacing.lg)

                    featuredSection
                }
                .padding(.bottom, AtlasSpacing.xxl + AtlasSpacing.lg)
            }
            .refreshable {}
            .background(AtlasColors.background)
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .atlasTrailing) {
                    HStack(spacing: AtlasSpacing.md) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(AtlasTypography.standard)
                                .foregroundStyle(.black)
                        }
                        Button("Done") { dismiss() }
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            Text("Atlas")
                .font(AtlasTypography.standard)
                .foregroundStyle(.black)
            Text("Discover")
                .font(AtlasTypography.standard)
                .foregroundStyle(.black)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.top, AtlasSpacing.md)
    }

    private func youAreHereCard(city: City) -> some View {
        NavigationLink(value: city) {
            HStack(spacing: AtlasSpacing.md) {
                VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                    HStack(spacing: AtlasSpacing.sm) {
                        Circle()
                            .fill(AtlasColors.accent)
                            .frame(width: 8, height: 8)
                            .overlay {
                                Circle()
                                    .fill(AtlasColors.accent.opacity(0.3))
                                    .frame(width: 18, height: 18)
                            }
                        Text("YOU'RE IN \(city.name.uppercased())")
                            .font(AtlasTypography.standard)
                            .tracking(1.2)
                            .foregroundStyle(.black)
                    }

                    Text("Explore \(dataService.places(for: city).count) curated places nearby")
                        .font(AtlasTypography.callout)
                        .foregroundStyle(.black)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
            }
            .padding(AtlasSpacing.md + 4)
            .background(
                RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                    .fill(AtlasColors.accent.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                            .stroke(AtlasColors.accent.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    private var citiesSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            Text("Cities")
                .font(AtlasTypography.standard)
                .foregroundStyle(.black)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.horizontal, AtlasSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasSpacing.md) {
                    ForEach(dataService.cities) { city in
                        NavigationLink(value: city) {
                            CityCardView(city: city)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AtlasSpacing.lg)
            }
        }
        .navigationDestination(for: City.self) { city in
            CityDetailView(city: city)
        }
        .navigationDestination(for: Place.self) { place in
            PlaceDetailView(place: place)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
            Text("Featured")
                .font(AtlasTypography.standard)
                .foregroundStyle(.black)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.horizontal, AtlasSpacing.lg)

            LazyVStack(spacing: AtlasSpacing.xl + AtlasSpacing.sm) {
                ForEach(dataService.featuredPlaces()) { place in
                    NavigationLink(value: place) {
                        FeaturedPlaceRow(place: place, cityName: dataService.city(for: place)?.name ?? "")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
        }
    }
}

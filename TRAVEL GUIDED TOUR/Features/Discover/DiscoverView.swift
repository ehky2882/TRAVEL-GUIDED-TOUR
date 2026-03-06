import SwiftUI
import CoreLocation

struct DiscoverView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LocationManager.self) private var locationManager
    @Environment(CollectionStore.self) private var collectionStore
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
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15))
                            .foregroundStyle(AtlasColors.secondaryText)
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
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AtlasColors.accent)
                .tracking(2)
                .textCase(.uppercase)
            Text("Discover")
                .font(.system(size: 38, weight: .bold, design: .serif))
                .foregroundStyle(AtlasColors.primaryText)
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
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(AtlasColors.accent)
                    }

                    Text("Explore \(dataService.places(for: city).count) curated places nearby")
                        .font(AtlasTypography.callout)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AtlasColors.accent)
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AtlasColors.secondaryText)
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AtlasColors.secondaryText)
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

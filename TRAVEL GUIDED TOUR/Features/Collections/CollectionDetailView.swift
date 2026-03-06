import SwiftUI

struct CollectionDetailView: View {
    let collection: PlaceCollection
    @Environment(DataService.self) private var dataService
    @Environment(CollectionStore.self) private var collectionStore

    private var places: [Place] {
        collection.placeIds.compactMap { dataService.place(by: $0) }
    }

    var body: some View {
        Group {
            if places.isEmpty {
                ContentUnavailableView(
                    "No Places Yet",
                    systemImage: "bookmark",
                    description: Text("Save places from the Discover tab to see them here.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AtlasSpacing.md) {
                        ForEach(places) { place in
                            NavigationLink(value: place) {
                                PlaceListRow(place: place, cityName: dataService.city(for: place)?.name)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.top, AtlasSpacing.md)
                    .padding(.bottom, AtlasSpacing.xxl)
                }
            }
        }
        .navigationTitle(collection.name)
    }
}

struct PlaceListRow: View {
    let place: Place
    var cityName: String?

    var body: some View {
        HStack(spacing: AtlasSpacing.md) {
            HeroImageView(
                imageName: place.thumbnailURL,
                height: 80,
                cornerRadius: 10,
                category: place.category
            )
            .frame(width: 80)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: place.category.iconName)
                        .font(.system(size: 9))
                    Text(place.category.displayName.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                }
                .foregroundStyle(AtlasColors.accent)

                Text(place.name)
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)

                HStack(spacing: AtlasSpacing.sm) {
                    if let cityName {
                        Text(cityName)
                            .font(.system(size: 12))
                            .foregroundStyle(AtlasColors.tertiaryText)
                    }
                    if let neighborhood = place.neighborhood {
                        if cityName != nil {
                            Text("·")
                                .foregroundStyle(AtlasColors.tertiaryText)
                        }
                        Text(neighborhood)
                            .font(.system(size: 12))
                            .foregroundStyle(AtlasColors.tertiaryText)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(AtlasSpacing.sm)
    }
}

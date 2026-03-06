import SwiftUI

struct CollectionsView: View {
    @Environment(CollectionStore.self) private var collectionStore
    @Environment(DataService.self) private var dataService
    @State private var showNewCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        NavigationStack {
            Group {
                if collectionStore.collections.isEmpty {
                    ContentUnavailableView(
                        "No Collections",
                        systemImage: "bookmark",
                        description: Text("Create a collection to start saving places.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AtlasSpacing.md) {
                            ForEach(collectionStore.collections) { collection in
                                NavigationLink(value: collection) {
                                    CollectionRow(collection: collection, dataService: dataService)
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
            .navigationTitle("Collections")
            .navigationDestination(for: PlaceCollection.self) { collection in
                CollectionDetailView(collection: collection)
            }
            .navigationDestination(for: Place.self) { place in
                PlaceDetailView(place: place)
            }
            .toolbar {
                ToolbarItem(placement: .atlasTrailing) {
                    Button {
                        showNewCollection = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AtlasColors.accent)
                    }
                }
            }
            .alert("New Collection", isPresented: $showNewCollection) {
                TextField("Collection name", text: $newCollectionName)
                Button("Cancel", role: .cancel) { newCollectionName = "" }
                Button("Create") {
                    if !newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty {
                        collectionStore.createCollection(name: newCollectionName)
                        newCollectionName = ""
                    }
                }
            }
        }
    }
}

struct CollectionRow: View {
    let collection: PlaceCollection
    let dataService: DataService

    private var collectionPlaces: [Place] {
        collection.placeIds.prefix(4).compactMap { dataService.place(by: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            // Cover mosaic
            if collectionPlaces.isEmpty {
                RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                    .fill(AtlasColors.placeholderWarm.opacity(0.5))
                    .frame(height: 140)
                    .overlay {
                        VStack(spacing: AtlasSpacing.sm) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 28, weight: .light))
                            Text("Empty collection")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(AtlasColors.tertiaryText)
                    }
            } else if collectionPlaces.count == 1 {
                HeroImageView(
                    imageName: collectionPlaces[0].thumbnailURL,
                    height: 140,
                    cornerRadius: AtlasSpacing.cardCornerRadius,
                    category: collectionPlaces[0].category
                )
            } else {
                HStack(spacing: 2) {
                    HeroImageView(
                        imageName: collectionPlaces[0].thumbnailURL,
                        height: 140,
                        category: collectionPlaces[0].category
                    )
                    if collectionPlaces.count > 1 {
                        VStack(spacing: 2) {
                            HeroImageView(
                                imageName: collectionPlaces[1].thumbnailURL,
                                height: 69,
                                category: collectionPlaces[1].category
                            )
                            if collectionPlaces.count > 2 {
                                HeroImageView(
                                    imageName: collectionPlaces[2].thumbnailURL,
                                    height: 69,
                                    category: collectionPlaces[2].category
                                )
                            } else {
                                Rectangle()
                                    .fill(AtlasColors.placeholderCool)
                                    .frame(height: 69)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
            }

            // Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(collection.name)
                        .font(AtlasTypography.headline)
                        .foregroundStyle(AtlasColors.primaryText)
                    Text("\(collection.placeIds.count) \(collection.placeIds.count == 1 ? "place" : "places")")
                        .font(.system(size: 12))
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        }
        .padding(.bottom, AtlasSpacing.sm)
    }
}

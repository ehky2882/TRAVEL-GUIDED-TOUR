import SwiftUI

struct CityDetailView: View {
    let city: City
    @Environment(DataService.self) private var dataService
    @State private var selectedCategory: PlaceCategory? = nil
    @State private var showMap = false

    private var filteredPlaces: [Place] {
        if let category = selectedCategory {
            return dataService.places(for: city, category: category)
        }
        return dataService.places(for: city)
    }

    private var availableCategories: [PlaceCategory] {
        let cityPlaces = dataService.places(for: city)
        let cats = Set(cityPlaces.map { $0.category })
        return PlaceCategory.allCases.filter { cats.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection
                editorialSection
                statsBar
                categoryFilter
                placesGrid
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .atlasTrailing) {
                Button {
                    showMap.toggle()
                } label: {
                    Image(systemName: "map")
                        .foregroundStyle(.black)
                }
            }
        }
        .sheet(isPresented: $showMap) {
            NavigationStack {
                MapView(city: city)
                    .navigationDestination(for: Place.self) { place in
                        PlaceDetailView(place: place)
                    }
                    .toolbar {
                        ToolbarItem(placement: .atlasTrailing) {
                            Button("Done") { showMap = false }
                        }
                    }
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            HeroImageView(imageName: city.heroImageURL, height: 360)


            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                Text(city.country.uppercased())
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
                    .tracking(2)
                Text(city.name)
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
            }
            .padding(AtlasSpacing.lg)
            .padding(.bottom, AtlasSpacing.sm)
        }
    }

    private var editorialSection: some View {
        Text(city.editorialIntro)
            .font(AtlasTypography.body)
            .foregroundStyle(.black)
            .lineSpacing(6)
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.lg)
            .padding(.bottom, AtlasSpacing.md)
    }

    private var statsBar: some View {
        HStack(spacing: AtlasSpacing.xl) {
            statItem(value: "\(dataService.places(for: city).count)", label: "Places")
            statItem(value: "\(availableCategories.count)", label: "Categories")
            statItem(
                value: "\(dataService.places(for: city).filter { $0.priceIndicator == .free }.count)",
                label: "Free"
            )
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.bottom, AtlasSpacing.lg)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AtlasTypography.standard)
                .foregroundStyle(.black)
            Text(label.uppercased())
                .font(AtlasTypography.standard)
                .foregroundStyle(.black)
                .tracking(1)
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.sm) {
                TagChip(text: "All", isSelected: selectedCategory == nil)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                    }

                ForEach(availableCategories) { category in
                    TagChip(text: category.displayName, isSelected: selectedCategory == category)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = category }
                        }
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
        }
        .padding(.bottom, AtlasSpacing.lg)
    }

    private var placesGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: AtlasSpacing.md),
            GridItem(.flexible(), spacing: AtlasSpacing.md)
        ]

        return LazyVGrid(columns: columns, spacing: AtlasSpacing.lg) {
            ForEach(filteredPlaces) { place in
                NavigationLink(value: place) {
                    PlaceGridItem(place: place)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedCategory)
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.bottom, AtlasSpacing.xxl)
    }
}

import SwiftUI

struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var showMapView = false
    @State private var selectedCategory: String? = nil

    private let menuCircleColor = Color(red: 0.22, green: 1.0, blue: 0.08)
    private let filterCategories = [
        "Favorites", "Museums", "Galleries", "Architecture",
        "Design Shops", "Street Art", "Cafes",
        "Bookshops", "Studios", "Public Spaces"
    ]
    private let menuItems = [
        (label: "Home", index: 0),
        (label: "Explore", index: 1),
        (label: "Favorites", index: 2),
        (label: "???", index: 3),
        (label: "Me", index: 4),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top section: Search bar + view toggle
            HStack(spacing: AtlasSpacing.sm) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("Search", text: $searchText)
                        .font(AtlasTypography.standard)
                }
                .padding(.horizontal, AtlasSpacing.md)
                .padding(.vertical, AtlasSpacing.sm + 2)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))

                // List / Map toggle
                HStack(spacing: 0) {
                    Button {
                        showMapView = false
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(showMapView ? Color.clear : Color.black)
                            .foregroundStyle(showMapView ? .black : .white)
                    }
                    Button {
                        showMapView = true
                    } label: {
                        Image(systemName: "map")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(showMapView ? Color.black : Color.clear)
                            .foregroundStyle(showMapView ? .white : .black)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
            .padding(.bottom, AtlasSpacing.sm)

            // Filter categories (horizontal scroll)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasSpacing.sm) {
                    ForEach(filterCategories, id: \.self) { category in
                        Button {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        } label: {
                            Text(category)
                                .font(AtlasTypography.standard)
                                .padding(.horizontal, AtlasSpacing.md)
                                .padding(.vertical, AtlasSpacing.sm)
                                .background(selectedCategory == category ? Color.black : Color.clear)
                                .foregroundStyle(selectedCategory == category ? .white : .black)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AtlasSpacing.lg)
            }
            .padding(.bottom, AtlasSpacing.sm)

            // Middle section: List or Map
            if showMapView {
                MapView()
            } else {
                ScrollView {
                    VStack(spacing: AtlasSpacing.md) {
                        ForEach(0..<8) { index in
                            Button {
                                // placeholder action
                            } label: {
                                RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 160)
                                    .overlay(
                                        Text("Content \(index + 1)")
                                            .font(AtlasTypography.standard)
                                            .foregroundStyle(.gray)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.vertical, AtlasSpacing.sm)
                }
            }

            // Bottom section: Menu (always visible)
            HStack {
                ForEach(menuItems, id: \.label) { item in
                    Spacer()
                    Button {
                        selectedTab = item.index
                    } label: {
                        VStack(spacing: AtlasSpacing.xs) {
                            Circle()
                                .fill(selectedTab == item.index ? Color.black : Color(.systemGray4))
                                .frame(width: 24, height: 24)
                            Text(item.label)
                                .font(AtlasTypography.standard)
                                .foregroundStyle(selectedTab == item.index ? .black : Color(.systemGray4))
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(.top, AtlasSpacing.sm)
            .padding(.bottom, AtlasSpacing.md)
            .background(Color.white)
        }
        .background(Color.white)
        .onAppear {
            locationManager.requestPermission()
        }
    }
}

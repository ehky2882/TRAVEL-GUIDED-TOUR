import SwiftUI
import MapKit

struct PlaceDetailView: View {
    let place: Place
    @Environment(DataService.self) private var dataService
    @Environment(CollectionStore.self) private var collectionStore
    @Environment(LocationManager.self) private var locationManager
    @State private var showCollectionSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection
                contentSection
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .atlasTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        collectionStore.toggleSaved(placeId: place.id)
                    }
                } label: {
                    Image(systemName: collectionStore.isPlaceSaved(place.id) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(.black)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
        }
        .sheet(isPresented: $showCollectionSheet) {
            AddToCollectionSheet(placeId: place.id)
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            HeroImageView(
                imageName: place.heroImageURL,
                height: 380,
                category: place.category
            )


            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                HStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: place.category.iconName)
                        .font(AtlasTypography.standard)
                    Text(place.category.displayName.uppercased())
                        .font(AtlasTypography.standard)
                        .tracking(1.5)
                    if let neighborhood = place.neighborhood {
                        Text("·")
                        Text(neighborhood)
                            .font(AtlasTypography.standard)
                    }
                }
                .foregroundStyle(.black)

                Text(place.name)
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)

                if let distance = locationManager.distanceString(to: place) {
                    HStack(spacing: AtlasSpacing.xs) {
                        Image(systemName: "location.fill")
                            .font(AtlasTypography.standard)
                        Text(distance)
                            .font(AtlasTypography.standard)
                    }
                    .foregroundStyle(.black)
                }
            }
            .padding(AtlasSpacing.lg)
            .padding(.bottom, AtlasSpacing.sm)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
            // Editorial description
            Text(place.editorialDescription)
                .font(AtlasTypography.body)
                .foregroundStyle(.black)
                .lineSpacing(6)
                .padding(.horizontal, AtlasSpacing.lg)
                .padding(.top, AtlasSpacing.lg)

            // On-site tip
            if let tip = place.onSiteTip {
                OnSiteTipCard(tip: tip)
                    .padding(.horizontal, AtlasSpacing.lg)
            }

            // Tags
            tagsSection

            // Practical info
            practicalInfo

            // Map
            mapSnippet

            // Save button
            Button {
                showCollectionSheet = true
            } label: {
                HStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: "plus")
                        .font(AtlasTypography.standard)
                    Text("Add to Collection")
                        .font(AtlasTypography.standard)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AtlasColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
            }
            .padding(.horizontal, AtlasSpacing.lg)

            // Nearby
            nearbySection

            Spacer(minLength: AtlasSpacing.xxl)
        }
    }

    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.sm) {
                ForEach(place.tags, id: \.self) { tag in
                    Text(tag)
                        .font(AtlasTypography.standard)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AtlasColors.secondaryBackground)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
        }
    }

    private var practicalInfo: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AtlasColors.secondaryText.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, AtlasSpacing.lg)

            VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                infoRow(icon: "mappin", text: place.address)

                if let hours = place.hours {
                    infoRow(icon: "clock", text: hours)
                }

                HStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: "tag")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                        .frame(width: 22)
                    Text(place.priceIndicator.displayText)
                        .font(AtlasTypography.callout)
                        .foregroundStyle(.black)
                }

                if let website = place.websiteURL, let url = URL(string: website) {
                    HStack(spacing: AtlasSpacing.sm) {
                        Image(systemName: "globe")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                            .frame(width: 22)
                        Link(url.host ?? "Website", destination: url)
                            .font(AtlasTypography.callout)
                            .foregroundStyle(.black)
                    }
                }
            }
            .padding(AtlasSpacing.lg)

            Rectangle()
                .fill(AtlasColors.secondaryText.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, AtlasSpacing.lg)
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AtlasSpacing.sm) {
            Image(systemName: icon)
                .font(AtlasTypography.standard)
                .foregroundStyle(.black)
                .frame(width: 22)
            Text(text)
                .font(AtlasTypography.callout)
                .foregroundStyle(.black)
        }
    }

    private var mapSnippet: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))) {
            Annotation(place.name, coordinate: place.coordinate) {
                ZStack {
                    Circle()
                        .fill(AtlasColors.accent)
                        .frame(width: 16, height: 16)
                    Circle()
                        .stroke(.white, lineWidth: 2.5)
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(AtlasColors.accent.opacity(0.2))
                        .frame(width: 40, height: 40)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
        .padding(.horizontal, AtlasSpacing.lg)
        .allowsHitTesting(false)
    }

    private var nearbySection: some View {
        let nearby = dataService.nearbyPlaces(to: place)
        return Group {
            if !nearby.isEmpty {
                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    Text("Nearby")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .padding(.horizontal, AtlasSpacing.lg)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AtlasSpacing.md) {
                            ForEach(nearby) { nearbyPlace in
                                NavigationLink(value: nearbyPlace) {
                                    NearbyPlaceCard(place: nearbyPlace)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AtlasSpacing.lg)
                    }
                }
            }
        }
    }
}

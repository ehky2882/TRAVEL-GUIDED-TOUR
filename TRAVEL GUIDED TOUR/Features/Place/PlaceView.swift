import SwiftUI
import CoreLocation

/// A site several tours describe — the page you reach by tapping a place pin.
///
/// Exists because a pin can stand for more than one tour. Before the place
/// layer those tours shared a coordinate, merged into a cluster no camera could
/// separate, and were simply unreachable; build 64 stacked their cards over the
/// map as a stopgap. This is the durable answer: the site gets a page, and the
/// tours become its contents.
///
/// Built entirely from components the app already has — no new colour, no new
/// type step. The one new idea is the brass tour count, which sits where a tour
/// page names its maker.
struct PlaceView: View {
    let place: Place

    @Environment(DataService.self) private var dataService
    @Environment(LocationManager.self) private var locationManager
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(\.openURL) private var openURL

    let onDismiss: () -> Void

    /// The place's tours in display order. `Place.ranked` owns the rule so it
    /// can change without a content re-seed.
    private var tours: [Tour] {
        dataService.rankedTours(at: place)
    }

    /// The place's own editorial hero when it has one, otherwise the hero of
    /// its top-ranked tour — so a place is never blocked on new photography.
    private var heroImageURL: String {
        place.heroImageURL ?? tours.first?.heroImageURL ?? ""
    }

    private var distanceText: String? {
        guard let user = locationManager.userLocation else { return nil }
        let here = CLLocation(latitude: place.latitude, longitude: place.longitude)
        return AtlasFormatters.distanceAway(meters: here.distance(from: user))
    }

    var body: some View {
        ZStack(alignment: .top) {
            AtlasColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    getDirectionsLink
                    header
                    if let description = place.description, !description.isEmpty {
                        Text(description)
                            .font(AtlasTypography.body)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .padding(.horizontal, AtlasSpacing.lg)
                            .padding(.top, AtlasSpacing.sm)
                    }
                    tourList
                }
                // The bottom module sits in a higher window over every screen,
                // so scrollable content has to reserve its height or the last
                // row is unreachable underneath it.
                .padding(.bottom, AtlasBottomModule.height())
            }

            toolbar
        }
    }

    // MARK: - Pieces

    private var hero: some View {
        HeroImageView(
            imageName: heroImageURL,
            height: AtlasSpacing.heroHeight,
            cornerRadius: 0,
            category: tours.first?.primaryCategory ?? .culturalHeritage
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(place.name.uppercased())
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .padding(.top, AtlasSpacing.sm)

            // Address is optional — the catalog has never stored one, so these
            // are backfilled. A place without it just shows the distance, and
            // one with neither shows no line at all rather than an empty gap.
            let metaLine = [place.address, distanceText]
                .compactMap { $0 }
                .joined(separator: " · ")
            if !metaLine.isEmpty {
                Text(metaLine)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    private var tourList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(tours.count) TOURS AVAILABLE")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.accent)
                Spacer()
                // Stated, not offered. There is one order today and no usage
                // data to rank on, so a sort control would be a promise the
                // app cannot keep — see Place.ranked.
                Text("NEWEST FIRST")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.lg)
            .padding(.bottom, AtlasSpacing.sm)

            ForEach(tours) { tour in
                Button {
                    tourPresenter.present(tour)
                } label: {
                    PlaceTourRow(tour: tour, maker: dataService.maker(for: tour))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AtlasColors.primaryText)
                    .frame(width: 44, height: 44)
                    .background(AtlasColors.secondaryBackground, in: Circle())
            }
            .accessibilityLabel("Close")
            Spacer()
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.top, AtlasSpacing.sm)
    }

    /// Mirrors tour detail's directions menu, including the `?api=1` universal
    /// link for Google Maps so iOS routes to the app when installed and Safari
    /// otherwise, with no LSApplicationQueriesSchemes entry needed.
    private var getDirectionsLink: some View {
        Menu {
            Button {
                var c = URLComponents(string: "http://maps.apple.com/")!
                c.queryItems = [
                    URLQueryItem(name: "daddr", value: "\(place.latitude),\(place.longitude)"),
                    URLQueryItem(name: "dirflg", value: "w")
                ]
                if let url = c.url { openURL(url) }
            } label: {
                Label("Apple Maps", systemImage: "applelogo")
            }
            Button {
                var c = URLComponents(string: "https://www.google.com/maps/dir/")!
                c.queryItems = [
                    URLQueryItem(name: "api", value: "1"),
                    URLQueryItem(name: "destination", value: "\(place.latitude),\(place.longitude)"),
                    URLQueryItem(name: "travelmode", value: "walking")
                ]
                if let url = c.url { openURL(url) }
            } label: {
                Label("Google Maps", systemImage: "globe")
            }
        } label: {
            Text("GET DIRECTIONS")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.mapPin)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.top, AtlasSpacing.sm)
        .accessibilityLabel("Get directions")
    }
}

// MARK: - One tour in the list

/// A row on the place page. Deliberately close to the maker page's tour row —
/// same WALK pill, same price badge, same mono metadata — because a user
/// scanning tours should not have to learn a second row format.
private struct PlaceTourRow: View {
    let tour: Tour
    let maker: Maker?

    var body: some View {
        HStack(spacing: AtlasSpacing.sm) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 56,
                cornerRadius: AtlasSpacing.xs,
                category: tour.primaryCategory
            )
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 3) {
                // Absence is the default state: only the exception is marked,
                // so a free single-stop tour carries no badge at all.
                HStack(spacing: AtlasSpacing.xs) {
                    if tour.kind == .multiStop {
                        Text("WALK")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(AtlasColors.background)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(AtlasColors.accent, in: Capsule())
                    }
                    TourPriceBadge(tour: tour)
                }

                Text(tour.title.uppercased())
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
        .padding(.horizontal, AtlasSpacing.lg)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AtlasColors.divider)
                .frame(height: 0.5)
                .padding(.leading, AtlasSpacing.lg)
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if let maker { parts.append(maker.displayName) }
        if tour.kind == .multiStop {
            parts.append("\(tour.stops.count) stops")
        }
        parts.append(AtlasFormatters.duration(seconds: tour.totalDurationSeconds))
        return parts.joined(separator: " · ")
    }
}

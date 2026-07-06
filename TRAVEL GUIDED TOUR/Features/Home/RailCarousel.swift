import SwiftUI

/// Reusable horizontal-scroll rail used by every rail family on the
/// home screen (location-anchored, personalized, interest-based).
/// Renders the rail title + a horizontally-scrolling row of tour
/// cards. Each card opens `TourDetailView` via `TourPresenter` —
/// always as a bottom sheet, never a side push.
struct RailCarousel: View {
    let title: String
    let tours: [Tour]

    @Environment(TourPresenter.self) private var tourPresenter

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            // Rail title in the SF Mono ALL-CAPS caption that the rest
            // of the home surfaces use (search placeholder, chips, the
            // "N TOURS IN VIEW" header) so every small label on the map
            // shares one editorial voice. The trailing chevron signals
            // the row scrolls horizontally.
            HStack(spacing: AtlasSpacing.xs) {
                Text(title)
                    .font(AtlasTypography.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
            }
            .padding(.horizontal, AtlasSpacing.lg)

            // The horizontal padding sits on the ScrollView itself
            // (shrinking its viewport), not on the content inside it,
            // so mid-scroll the cards clip at the drawer's side margins
            // instead of sliding edge-to-edge (owner request).
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AtlasSpacing.md) {
                    ForEach(tours) { tour in
                        Button {
                            tourPresenter.present(tour)
                        } label: {
                            TourCard(tour: tour)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
        }
    }
}

/// One card on a rail. Fixed width so multiple peek in from the right.
private struct TourCard: View {
    let tour: Tour

    @Environment(DataService.self) private var dataService
    @Environment(LocationManager.self) private var locationManager

    /// One dominant card per viewport with a peek of the next: 260pt
    /// wide leaves a ~78pt peek inside the drawer's 24pt side margins,
    /// and the shorter hero lets the next rail's title row peek up
    /// from the bottom of the drawer as a vertical scroll cue too.
    /// The hero is 4:3 (260×195) — the exact aspect of the catalog's
    /// 1200×900 gallery images, so heroes render uncropped.
    private let cardWidth: CGFloat = 260
    private var heroHeight: CGFloat { cardWidth * 3 / 4 }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            heroSection

            // Uniform AtlasSpacing.xs between all three text rows —
            // title → maker → time — so the block reads as one evenly
            // set unit (no extra pad on the time row).
            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)

                if let maker = dataService.maker(for: tour) {
                    Text(maker.displayName)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .lineLimit(1)
                }

                HStack(spacing: AtlasSpacing.xs) {
                    Image(systemName: "clock")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                    // Duration, then distance-away after a separator
                    // dot when the user's location is known — same
                    // "3 min · 1.2 mi away" shape the placecard +
                    // detail subtitle use.
                    Text(metaLine)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, AtlasSpacing.xs)
        }
        .frame(width: cardWidth, alignment: .leading)
    }

    /// Hero image with the paired download + bookmark AFFORDANCES in the
    /// top-right corner (shared `CardHeroControls`, so saving/downloading
    /// reads identically on the map's rails and in the filtered feed) and
    /// — for multi-stop tours only — a decorative route mini-map in the
    /// bottom-right corner. The corner controls sit inside the rail card's
    /// outer Button; SwiftUI routes the tap to the innermost interactive
    /// view, so a chip fires its action while a tap anywhere else opens
    /// the tour. The mini-map has no tap target of its own.
    private var heroSection: some View {
        HeroImageView(
            imageName: tour.heroImageURL,
            height: heroHeight,
            cornerRadius: 0,
            category: tour.primaryCategory
        )
        .overlay(alignment: .bottomTrailing) {
            RouteMiniMapView(tour: tour)
                .padding(AtlasSpacing.sm)
        }
        .overlay(alignment: .topTrailing) {
            CardHeroControls(tour: tour)
        }
    }

    /// "3 min" alone, or "3 min · 1.2 mi away" when the user's
    /// location is known. Crow-fly distance from the user to the
    /// tour's centroid (same `Tour.distance(from:)` the drawer list
    /// and placecard use).
    private var metaLine: String {
        let duration = AtlasFormatters.duration(seconds: tour.totalDurationSeconds)
        guard let user = locationManager.userLocation else { return duration }
        let away = AtlasFormatters.distanceAway(meters: tour.distance(from: user))
        return "\(duration) · \(away)"
    }
}

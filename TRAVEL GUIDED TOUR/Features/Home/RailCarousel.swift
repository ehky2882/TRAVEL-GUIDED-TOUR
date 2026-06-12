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
    @Environment(LibraryStore.self) private var libraryStore

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
                    Text(formattedDuration(tour.totalDurationSeconds))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }
            .padding(.horizontal, AtlasSpacing.xs)
        }
        .frame(width: cardWidth, alignment: .leading)
    }

    /// Hero image with the bookmark AFFORDANCE in the top-right
    /// corner — same control as the full-width list card, so saving a
    /// tour reads identically on the map's rails and in detail. The
    /// button sits inside the rail card's outer Button; SwiftUI routes
    /// the tap to the innermost interactive view, so the bookmark
    /// fires `toggleSaved` while a tap anywhere else opens the tour.
    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: heroHeight,
                cornerRadius: 0,
                category: tour.primaryCategory
            )

            Button {
                libraryStore.toggleSaved(tour.id)
            } label: {
                Image(systemName: libraryStore.isSaved(tour.id) ? "bookmark.fill" : "bookmark")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(AtlasSpacing.sm)
            .accessibilityLabel(libraryStore.isSaved(tour.id) ? "Saved" : "Save tour")
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        AtlasFormatters.duration(seconds: seconds)
    }
}

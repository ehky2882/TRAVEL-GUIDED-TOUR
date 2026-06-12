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
            // shares one editorial voice.
            Text(title)
                .font(AtlasTypography.caption)
                .textCase(.uppercase)
                .foregroundStyle(AtlasColors.primaryText)
                .padding(.horizontal, AtlasSpacing.lg)

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
                .padding(.horizontal, AtlasSpacing.lg)
            }
        }
    }
}

/// One card on a rail. Fixed width so multiple peek in from the right.
private struct TourCard: View {
    let tour: Tour

    @Environment(LibraryStore.self) private var libraryStore

    private let cardWidth: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            heroSection

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tour.shortDescription)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: AtlasSpacing.xs) {
                    Image(systemName: "clock")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                    Text(formattedDuration(tour.totalDurationSeconds))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
                .padding(.top, AtlasSpacing.xs)
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
                height: 140,
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

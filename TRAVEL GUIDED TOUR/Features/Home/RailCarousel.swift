import SwiftUI

/// Reusable horizontal-scroll rail used by every rail family on the
/// home screen (location-anchored, personalized, interest-based).
/// Renders the rail title + a horizontally-scrolling row of tour cards.
/// Each card pushes `TourDetailView` via NavigationLink.
struct RailCarousel: View {
    let title: String
    let tours: [Tour]

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text(title)
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
                .padding(.horizontal, AtlasSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AtlasSpacing.md) {
                    ForEach(tours) { tour in
                        NavigationLink {
                            TourDetailView(tour: tour)
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

    private let cardWidth: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 140,
                cornerRadius: AtlasSpacing.cardCornerRadius,
                category: tour.primaryCategory
            )

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

    private func formattedDuration(_ seconds: Int) -> String {
        AtlasFormatters.duration(seconds: seconds)
    }
}

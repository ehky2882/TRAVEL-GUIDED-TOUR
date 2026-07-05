import SwiftUI

/// Compact floating preview that appears above a tapped map pin —
/// Apple/Google Maps "place card" pattern. Shows the tour's hero
/// thumbnail, title, maker, and (optional) distance from the user.
/// Tapping anywhere on the card invokes `onTap`, which the host uses
/// to push `TourDetailView` onto the home nav stack.
///
/// Single form: no mode flags. Caller controls placement (typically
/// as a `MapContent` annotation anchored above the pin).
struct PlacecardView: View {
    let tour: Tour
    let maker: Maker?
    /// Pre-formatted distance string (e.g. "0.8 km away"). Hidden
    /// when nil.
    let distanceText: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AtlasSpacing.sm) {
                HeroImageView(
                    imageName: tour.heroImageURL,
                    height: 64,
                    cornerRadius: AtlasSpacing.xs,
                    category: tour.primaryCategory
                )
                .frame(width: 64)

                VStack(alignment: .leading, spacing: 2) {
                    // ALL CAPS title to match the editorial-caps
                    // voice used on the mini-player title and the
                    // drawer header. Two-line cap with tail
                    // ellipsis (SwiftUI's default truncation) so a
                    // long name doesn't blow out the card's
                    // standardized width.
                    Text(tour.title.uppercased())
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let maker {
                        Text("by \(maker.displayName)")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .lineLimit(1)
                    }

                    if let distanceText {
                        Text(distanceText)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AtlasSpacing.sm)
            .background(
                AtlasColors.secondaryBackground,
                in: RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tour.title)\(maker.map { ", by \($0.displayName)" } ?? "")")
        .accessibilityHint("Open tour details")
    }
}

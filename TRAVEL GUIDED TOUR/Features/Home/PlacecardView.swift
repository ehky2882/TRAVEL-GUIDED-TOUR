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
    /// Standard width — 2/3 of the active scene's screen width, so the
    /// card reads as the same visual proportion of the map on every
    /// iPhone size. Falls back to a sensible fixed width when there's no
    /// active window scene (test / preview contexts).
    ///
    /// Lives here rather than on a host view because both maps that show
    /// place cards need it, and they must agree: wider would feel like an
    /// overlay sheet, narrower would cramp the 64pt hero next to the
    /// 2-line ALL CAPS title. It also fits inside the maker map, which is
    /// the narrower of the two (screen width less two 24pt gutters).
    static var standardWidth: CGFloat {
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen.bounds.width
        return (screenWidth ?? 390) * 2.0 / 3.0
    }

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

                    // Price sits on the meta line rather than over the 64pt
                    // thumbnail — the thumb is too small to carry a legible
                    // chip, and the placecard is the map's tap target, so the
                    // cost has to be visible before the tour is opened.
                    HStack(spacing: AtlasSpacing.xs) {
                        TourPriceBadge(tour: tour)
                        if let distanceText {
                            Text(distanceText)
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .placecardChrome()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tour.title)\(maker.map { ", by \($0.displayName)" } ?? "")")
        .accessibilityHint("Open tour details")
    }
}

// MARK: - Shared chrome

/// The card surface itself. Extracted so the tour card and the place card
/// cannot drift apart — they sit side by side on the same map and any
/// difference in padding, radius or shadow would read as a bug.
private struct PlacecardChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AtlasSpacing.sm)
            .background(
                AtlasColors.secondaryBackground,
                in: RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
    }
}

private extension View {
    func placecardChrome() -> some View { modifier(PlacecardChrome()) }
}

// MARK: - Place card

/// The placecard for a **place** — a site several tours describe.
///
/// Identical to the tour card except on one line: where a tour names its
/// maker, a place reports **"N tours available"** in brass. That substitution
/// is the whole pattern. It sits on the line the eye already goes to for
/// "what is this", and brass because it is the actionable fact on the card —
/// the reason to tap through rather than a label.
struct PlacePlacecardView: View {
    let place: Place
    /// Already resolved by the caller: the place's editorial hero when it has
    /// one, otherwise the hero of its top-ranked tour. A place is never
    /// blocked on new photography being sourced.
    let heroImageURL: String
    /// Drives the placeholder when the image can't load.
    let category: TourCategory
    let tourCount: Int
    let distanceText: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AtlasSpacing.sm) {
                HeroImageView(
                    imageName: heroImageURL,
                    height: 64,
                    cornerRadius: AtlasSpacing.xs,
                    category: category
                )
                .frame(width: 64)

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name.uppercased())
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("\(tourCount) tours available")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.accent)
                        .lineLimit(1)

                    if let distanceText {
                        Text(distanceText)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .placecardChrome()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(place.name), \(tourCount) tours available")
        .accessibilityHint("Open this place")
    }
}

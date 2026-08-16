import SwiftUI

/// Price chip for a paid tour, shown on browse surfaces so nobody meets a
/// paywall by surprise.
///
/// **Why it exists.** Phase 3 deliberately shipped the paywall on the tour
/// detail sheet only, which was fine while nothing was priced. Once the 66
/// multi-stop walks went to $0.99 (owner decision, see CLAUDE.md § LIVE
/// PRICING) that left a real gap: someone scrolling the rails saw no hint of
/// cost, opened a walk, and hit a Buy button. This closes that.
///
/// **Renders nothing** for a free tour (the great majority of the catalog)
/// or one the viewer already owns — an owned tour behaves like any free one,
/// so a price on it would just be confusing.
///
/// **Fails toward showing a price.** If `PurchaseService` is missing from the
/// environment we can't know what the viewer owns, so we show the tier price
/// rather than hiding it. Showing a price to someone who already bought the
/// tour is a small cosmetic wrinkle; hiding it from someone who hasn't is the
/// surprise-paywall bug this component exists to prevent.
struct TourPriceBadge: View {
    let tour: Tour

    @Environment(PurchaseService.self) private var purchaseService: PurchaseService?

    /// Localized when StoreKit has loaded (a UK buyer sees £, not a
    /// dollar figure), falling back to the USD tier until then.
    private var priceText: String? {
        guard tour.isPaid else { return nil }
        if let purchaseService {
            guard !purchaseService.isUnlocked(tour) else { return nil }
            return purchaseService.displayPrice(for: tour)
        }
        return tour.fallbackPriceText
    }

    var body: some View {
        if let priceText {
            Text(priceText)
                // Matches `MakerView.walkPill` exactly — same size, weight,
                // padding and capsule — so a walk showing both a WALK pill
                // and a price reads as one row of chips rather than two
                // competing treatments.
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AtlasColors.background)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(AtlasColors.accent))
                .fixedSize()
                // Lifts the chip off a busy photo, same as the grid WALK pill.
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                .accessibilityLabel("Costs \(priceText)")
        }
    }
}

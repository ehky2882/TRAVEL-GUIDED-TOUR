import SwiftUI

struct PriceIndicatorView: View {
    let price: PriceIndicator

    var body: some View {
        Text(price.displayText)
            .font(AtlasTypography.caption)
            .fontWeight(.medium)
            .foregroundStyle(price == .free ? AtlasColors.accent : AtlasColors.secondaryText)
    }
}

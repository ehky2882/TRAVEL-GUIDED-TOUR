import SwiftUI

struct PriceIndicatorView: View {
    let price: PriceIndicator

    var body: some View {
        Text(price.displayText)
            .font(AtlasTypography.caption)
            .foregroundStyle(.black)
    }
}

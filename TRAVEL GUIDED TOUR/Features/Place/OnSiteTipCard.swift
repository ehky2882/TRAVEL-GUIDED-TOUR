import SwiftUI

struct OnSiteTipCard: View {
    let tip: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "mappin.circle.fill")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)

                Text("When You're Here")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(.black)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }

            Text(tip)
                .font(AtlasTypography.callout)
                .foregroundStyle(.black)
                .lineSpacing(4)
        }
        .padding(AtlasSpacing.md + 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                .fill(AtlasColors.accent.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                        .stroke(AtlasColors.accent.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

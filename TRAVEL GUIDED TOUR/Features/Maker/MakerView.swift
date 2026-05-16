import SwiftUI

/// Placeholder maker page. Full implementation (avatar, bio, tour list)
/// lands in M-maker. This stub exists so `TourDetailView`'s maker
/// NavigationLink has a real destination — the shape stays stable when
/// M-maker swaps in the real content.
struct MakerView: View {
    let maker: Maker

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                Text(maker.displayName)
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)

                Text(maker.bio)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Tour list coming in M-maker.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
                    .padding(.top, AtlasSpacing.md)
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.vertical, AtlasSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AtlasColors.background)
        .navigationTitle(maker.displayName)
        .inlineNavigationBarTitle()
    }
}

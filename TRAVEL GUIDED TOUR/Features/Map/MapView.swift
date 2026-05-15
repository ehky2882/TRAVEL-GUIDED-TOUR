import SwiftUI

struct MapView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.md) {
                Image(systemName: "map.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
                Text("Explore")
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)
                Text("Tour-stop map lands in M-map (or merges with Home's embedded map).")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AtlasSpacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtlasColors.background)
            .navigationTitle("Explore")
            .inlineNavigationBarTitle()
        }
    }
}

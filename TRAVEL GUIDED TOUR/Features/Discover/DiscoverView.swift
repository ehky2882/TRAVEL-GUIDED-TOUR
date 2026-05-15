import SwiftUI

struct DiscoverView: View {
    @Environment(DataService.self) private var dataService

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.md) {
                Image(systemName: "map")
                    .font(.system(size: 48))
                    .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
                Text("Home")
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)
                Text("Map-dominant home with curated rails lands in M-home.")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AtlasSpacing.lg)
                Text("Loaded \(dataService.tours.count) tour(s) from Tours.json.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
                    .padding(.top, AtlasSpacing.md)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtlasColors.background)
            .navigationTitle("Home")
            .inlineNavigationBarTitle()
        }
    }
}

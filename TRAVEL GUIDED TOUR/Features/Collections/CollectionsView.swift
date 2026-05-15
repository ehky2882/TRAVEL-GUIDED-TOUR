import SwiftUI

struct CollectionsView: View {
    @Environment(LibraryStore.self) private var libraryStore

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.md) {
                Image(systemName: "bookmark")
                    .font(.system(size: 48))
                    .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
                Text("Library")
                    .font(AtlasTypography.headline)
                    .foregroundStyle(AtlasColors.primaryText)
                Text("Saved / Downloaded / Recently played lands in M-library.")
                    .font(AtlasTypography.standard)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AtlasSpacing.lg)
                Text("\(libraryStore.entries.count) library entrie(s).")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
                    .padding(.top, AtlasSpacing.md)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtlasColors.background)
            .navigationTitle("Favorites")
            .inlineNavigationBarTitle()
        }
    }
}

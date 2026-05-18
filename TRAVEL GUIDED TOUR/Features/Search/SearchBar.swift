import SwiftUI

/// The home screen's pinned search-bar tap target. Replaces the
/// earlier `SearchBarStub` now that `SearchView` exists. Same visual
/// shape — tappable capsule with a magnifying-glass icon and
/// placeholder copy — but the destination is the real search results
/// screen.
struct SearchBar: View {
    @State private var showingSearch = false

    var body: some View {
        Button {
            showingSearch = true
        } label: {
            HStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.secondaryText)

                Text("Search tours, makers, categories")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.secondaryText)

                Spacer()
            }
            .padding(.horizontal, AtlasSpacing.md)
            .padding(.vertical, AtlasSpacing.sm + AtlasSpacing.xs)
            // Glass material so the bar reads cleanly over both
            // the map underneath (HomeView) and the white background
            // of any other parent. iOS 26's `.regularMaterial` carries
            // the Liquid Glass look automatically.
            .background(.regularMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(AtlasColors.secondaryText.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSearch) {
            SearchView()
        }
    }
}

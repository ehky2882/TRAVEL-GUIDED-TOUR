import SwiftUI

/// The home screen's pinned search-bar tap target. Replaces the
/// earlier `SearchBarStub` now that `SearchView` exists. Same visual
/// shape — tappable capsule with a magnifying-glass icon and
/// placeholder copy — but the destination is the real search results
/// screen.
///
/// Pushes `SearchView` into the host tab's `NavigationStack` rather
/// than presenting it as a `.sheet`: a sheet covers the parent's
/// view tree (including `ContentView`'s mini-player + tab bar
/// overlay), so the bottom module disappeared whenever the user
/// opened search. Pushing keeps the module in place and lets a
/// further `TourDetailView` push extend the same nav stack instead
/// of stacking presentation contexts.
struct SearchBar: View {
    var body: some View {
        NavigationLink {
            SearchView()
        } label: {
            HStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)

                Text("Search tours, makers, categories")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)

                Spacer()
            }
            .padding(.horizontal, AtlasSpacing.md)
            .frame(height: AtlasSpacing.searchBarHeight)
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
    }
}

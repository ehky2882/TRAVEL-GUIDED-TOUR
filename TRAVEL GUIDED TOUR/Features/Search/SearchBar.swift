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
            // Match the drawer / mini-player / tab bar surface — one
            // unified bar color across the whole bottom-and-top
            // chrome. No stroke (would read as inconsistency against
            // the other surfaces, which have none).
            .background(AtlasColors.secondaryBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

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
            .background(AtlasColors.secondaryBackground)
            .overlay(
                Capsule()
                    .stroke(AtlasColors.secondaryText.opacity(0.2), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSearch) {
            SearchView()
        }
    }
}

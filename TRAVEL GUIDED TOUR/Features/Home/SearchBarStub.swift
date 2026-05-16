import SwiftUI

/// Placeholder search bar for the home screen header. Tapping presents
/// a stub sheet — the real search-results view lands in M-search and
/// will just swap into this same tap-target slot.
struct SearchBarStub: View {
    @State private var showingStub = false

    var body: some View {
        Button {
            showingStub = true
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
        .sheet(isPresented: $showingStub) {
            SearchStubSheet()
        }
    }
}

private struct SearchStubSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AtlasSpacing.md) {
            Capsule()
                .fill(AtlasColors.secondaryText.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, AtlasSpacing.sm)

            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))

            Text("Search")
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)

            Text("Search results land in M-search. The bar already lives in the right spot — only the destination changes.")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AtlasSpacing.lg)

            Spacer()

            Button("Close") { dismiss() }
                .padding(.bottom, AtlasSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AtlasColors.background)
    }
}

import SwiftUI

/// Horizontally-scrolling row of `TourCategory` filter chips for the
/// home screen — AllTrails-style. An "All" chip on the left clears
/// the filter; one chip per category that has at least one tour.
struct CategoryChipRow: View {
    let availableCategories: [TourCategory]
    @Binding var selectedCategory: TourCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.sm) {
                allChip
                ForEach(availableCategories) { category in
                    chip(for: category)
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
        }
    }

    private var allChip: some View {
        let isSelected = selectedCategory == nil
        return Button {
            selectedCategory = nil
        } label: {
            Text("All")
                .font(AtlasTypography.caption)
                .foregroundStyle(isSelected ? AtlasColors.background : AtlasColors.primaryText)
                .padding(.horizontal, AtlasSpacing.md)
                .padding(.vertical, AtlasSpacing.xs + 2)
                .background(chipBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    private func chip(for category: TourCategory) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = isSelected ? nil : category
        } label: {
            HStack(spacing: AtlasSpacing.xs) {
                Image(systemName: category.iconName)
                    .font(AtlasTypography.caption)
                Text(category.displayName)
                    .font(AtlasTypography.caption)
            }
            .foregroundStyle(isSelected ? AtlasColors.background : AtlasColors.primaryText)
            .padding(.horizontal, AtlasSpacing.md)
            .padding(.vertical, AtlasSpacing.xs + 2)
            .background(chipBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    /// Unselected chips use `.regularMaterial` so the map underneath
    /// is softened — without this, the map shows clearly through the
    /// chip and competes with the label text.
    @ViewBuilder
    private func chipBackground(isSelected: Bool) -> some View {
        if isSelected {
            Capsule()
                .fill(AtlasColors.primaryText)
        } else {
            Capsule()
                .fill(.regularMaterial)
                .overlay(
                    Capsule()
                        .stroke(AtlasColors.primaryText.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

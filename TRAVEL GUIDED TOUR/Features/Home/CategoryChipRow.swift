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
            .padding(.horizontal, AtlasSpacing.md)
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
                .frame(height: AtlasSpacing.searchBarHeight)
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
            .frame(height: AtlasSpacing.searchBarHeight)
            .background(chipBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    /// Unselected chips match the drawer / mini-player / tab bar
    /// surface so the entire chrome reads as one unified color band.
    /// No stroke (would read as inconsistency against those surfaces,
    /// which have none).
    @ViewBuilder
    private func chipBackground(isSelected: Bool) -> some View {
        if isSelected {
            Capsule()
                .fill(AtlasColors.primaryText)
        } else {
            Capsule()
                .fill(AtlasColors.secondaryBackground)
        }
    }
}

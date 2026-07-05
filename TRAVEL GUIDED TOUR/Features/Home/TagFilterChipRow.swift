import SwiftUI

/// Horizontally-scrolling row of **multi-select filter chips** for the
/// home screen (owner decision D8). Replaces the old single-select,
/// jump-scroll category row: chips now *filter* — the map pins and the
/// drawer list narrow to tours matching the selection.
///
/// Contents, left → right:
///   - **All** — clears every filter (selected when nothing is active).
///   - **Walks** — the multi-stop *format* filter (§1.6), set off with a
///     `figure.walk` glyph since it filters the tour's shape, not subject.
///   - one chip per curated tag (`Tag.filterChips`).
///
/// Selection combines per D6 (OR within a facet, AND across) — the logic
/// lives in `Tag.matches`; this row only owns the chip state. An active
/// chip is filled with the brand accent so "filters are on" reads at a
/// glance; inactive chips match the drawer / mini-player surface, so the
/// whole chrome stays one unified band.
struct TagFilterChipRow: View {
    @Binding var selectedTags: Set<String>
    @Binding var walksOnly: Bool

    private var hasActiveFilters: Bool { !selectedTags.isEmpty || walksOnly }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.sm) {
                allChip
                walksChip
                ForEach(Tag.filterChips, id: \.self) { tag in
                    tagChip(tag)
                }
            }
            .padding(.horizontal, AtlasSpacing.md)
        }
    }

    // MARK: - Chips

    private var allChip: some View {
        chip(label: "All", systemImage: nil, isSelected: !hasActiveFilters) {
            selectedTags.removeAll()
            walksOnly = false
        }
    }

    private var walksChip: some View {
        chip(label: "Walks", systemImage: "figure.walk", isSelected: walksOnly) {
            walksOnly.toggle()
        }
    }

    private func tagChip(_ tag: String) -> some View {
        chip(label: tag, systemImage: nil, isSelected: selectedTags.contains(tag)) {
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
        }
    }

    // MARK: - Chip primitive

    @ViewBuilder
    private func chip(
        label: String,
        systemImage: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AtlasSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(AtlasTypography.caption)
                }
                Text(label)
                    .font(AtlasTypography.caption)
            }
            .foregroundStyle(isSelected ? AtlasColors.background : AtlasColors.primaryText)
            .padding(.horizontal, AtlasSpacing.md)
            .frame(height: AtlasSpacing.searchBarHeight)
            .background(chipBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    /// Selected chips fill with the brand accent (gold) so active filters
    /// pop; unselected chips match the drawer / mini-player / tab-bar
    /// surface so the chrome reads as one unified color band. No stroke.
    @ViewBuilder
    private func chipBackground(isSelected: Bool) -> some View {
        if isSelected {
            Capsule().fill(AtlasColors.mapPin)
        } else {
            Capsule().fill(AtlasColors.secondaryBackground)
        }
    }
}

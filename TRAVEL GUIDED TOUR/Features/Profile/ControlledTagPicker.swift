import SwiftUI

/// Maker-facing picker for the controlled tag vocabulary. Makers pick from the
/// same closed vocabulary the consumer shelves and filters use, so a new tour is
/// tagged correctly at creation and flows straight onto the right shelves.
///
/// **Five accordion rows, one open at a time.** It was previously five stacks of
/// chips, all expanded — 50 chips down the screen, so Details could only be read
/// by scrolling past the taxonomy to reach anything else. Collapsed, each row
/// says what it is and what you picked; open, it shows its chips.
///
/// **Place type** and **Theme** are required (≥1 each — mirrors the validator
/// and `docs/tag-taxonomy-v2.md`); Style & era and Experience are optional.
/// Architect is single-select and carries a search field, because the
/// vocabulary holds 86 names — a chip wall would be worse than the menu it
/// replaced. Choosing one auto-adds "Designed by a Master" (handled by the
/// caller). The editorial tags a maker can't self-judge — `Iconic Landmark`,
/// `Free to Visit`, `After Dark`, and the architect-derived
/// `Designed by a Master` — are kept out of the Experience chips.
struct ControlledTagPicker: View {
    @Binding var selectedTags: Set<String>
    @Binding var architect: String?

    /// Which row is open, if any. One at a time: opening a row closes the
    /// last, so the section never grows taller than about two screens.
    @State private var expanded: TagFacet?
    @State private var architectQuery = ""

    /// Experience tags a maker shouldn't self-assign (editorial /
    /// derived). Curators hand-author these later.
    private static let experienceExclusions: Set<String> = [
        "Iconic Landmark", "Free to Visit", "After Dark", "Designed by a Master",
    ]

    private static let rows: [(facet: TagFacet, label: String, required: Bool)] = [
        (.placeType,  "PLACE TYPE",  true),
        (.theme,      "THEME",       true),
        (.styleEra,   "STYLE & ERA", false),
        (.experience, "EXPERIENCE",  false),
        (.architect,  "ARCHITECT",   false),
    ]

    var body: some View {
        VStack(spacing: AtlasSpacing.sm) {
            ForEach(Self.rows, id: \.facet) { row in
                facetRow(row.facet, label: row.label, required: row.required)
            }
        }
    }

    // MARK: - Rows

    private func facetRow(_ facet: TagFacet, label: String, required: Bool) -> some View {
        let isOpen = expanded == facet
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expanded = isOpen ? nil : facet
                }
                if facet == .architect { architectQuery = "" }
            } label: {
                HStack(alignment: .center, spacing: AtlasSpacing.md) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: AtlasSpacing.xs) {
                            Text(required ? "\(label) — REQUIRED" : label)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(AtlasColors.tertiaryText)
                            if required && isSatisfied(facet) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AtlasColors.mapPin)
                            }
                        }
                        Text(summary(for: facet))
                            .font(AtlasTypography.caption)
                            .foregroundStyle(hasSelection(facet)
                                             ? AtlasColors.primaryText
                                             : AtlasColors.secondaryText)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AtlasColors.tertiaryText)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                }
                .padding(.horizontal, AtlasSpacing.md)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isOpen ? "Collapses this group" : "Expands this group")

            if isOpen {
                Rectangle()
                    .fill(AtlasColors.divider)
                    .frame(height: 0.5)
                    .padding(.leading, AtlasSpacing.md)
                chips(for: facet)
            }
        }
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }

    @ViewBuilder
    private func chips(for facet: TagFacet) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            if facet == .architect {
                // 86 names. A search field is the only way this row is usable;
                // the other four fit on screen as chips.
                HStack(spacing: AtlasSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(AtlasColors.tertiaryText)
                    TextField("Search \(Tag.tags(in: .architect).count) architects", text: $architectQuery)
                        .font(AtlasTypography.caption)
                        .autocorrectionDisabled()
                    if !architectQuery.isEmpty {
                        Button { architectQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(AtlasColors.tertiaryText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, AtlasSpacing.sm)
                .padding(.vertical, 9)
                .background(AtlasColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            let options = self.options(for: facet)
            if options.isEmpty {
                Text("No architect matches “\(architectQuery)”.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            } else {
                FlowLayout(spacing: AtlasSpacing.sm) {
                    ForEach(options, id: \.self) { tag in
                        Button { toggle(tag, in: facet) } label: {
                            TagChip(text: tag, isSelected: isSelected(tag, in: facet))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if facet == .architect, architect != nil {
                Text("Adds “Designed by a Master.”")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.top, AtlasSpacing.sm)
        .padding(.bottom, AtlasSpacing.md)
    }

    // MARK: - Vocabulary

    /// The chips a row offers. Architect is filtered by the search field, and
    /// keeps the current pick visible even when it doesn't match — otherwise
    /// the one chip you could tap to *deselect* would vanish as you typed.
    private func options(for facet: TagFacet) -> [String] {
        let all = Tag.tags(in: facet)
        switch facet {
        case .experience:
            return all.filter { !Self.experienceExclusions.contains($0) }
        case .architect:
            let query = architectQuery.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return all }
            return all.filter {
                $0.localizedCaseInsensitiveContains(query) || $0 == architect
            }
        default:
            return all
        }
    }

    /// What a closed row shows: the picks, or a prompt.
    private func summary(for facet: TagFacet) -> String {
        if facet == .architect {
            return architect ?? "None selected"
        }
        let picked = Tag.ordered(selectedTags).filter { Tag.tags(in: facet).contains($0) }
        return picked.isEmpty ? "None selected" : picked.joined(separator: ", ")
    }

    private func hasSelection(_ facet: TagFacet) -> Bool {
        facet == .architect ? architect != nil : isSatisfied(facet)
    }

    private func isSatisfied(_ facet: TagFacet) -> Bool {
        !selectedTags.isDisjoint(with: Set(Tag.tags(in: facet)))
    }

    private func isSelected(_ tag: String, in facet: TagFacet) -> Bool {
        facet == .architect ? architect == tag : selectedTags.contains(tag)
    }

    /// Architect is single-select: tapping a different name replaces the
    /// current one, tapping the current one clears it. Everything else toggles.
    private func toggle(_ tag: String, in facet: TagFacet) {
        if facet == .architect {
            architect = (architect == tag) ? nil : tag
        } else if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

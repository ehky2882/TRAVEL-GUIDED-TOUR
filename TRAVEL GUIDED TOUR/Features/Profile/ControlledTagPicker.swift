import SwiftUI

/// Maker-facing picker for the controlled tag vocabulary (tag Phase 2
/// fast-follow). Replaces the old free-text tags field + category picker
/// on `CreateTourView`: makers now pick from the same closed vocabulary
/// the consumer shelves/filters use, so a new tour is tagged correctly
/// at creation and flows straight onto the right shelves.
///
/// **Place type** and **Theme** are required (≥1 each — mirrors the
/// validator + `docs/tag-taxonomy-v2.md`); Style & era and Experience
/// are optional. Architect is a single-select menu that auto-adds
/// "Designed by a Master" on save (handled by the caller). The editorial
/// tags a maker can't self-judge — `Iconic Landmark`, `Free to Visit`,
/// `After Dark`, and the architect-derived `Designed by a Master` — are
/// kept out of the Experience chips.
struct ControlledTagPicker: View {
    @Binding var selectedTags: Set<String>
    @Binding var architect: String?

    /// Experience tags a maker shouldn't self-assign (editorial /
    /// derived). Curators hand-author these later.
    private static let experienceExclusions: Set<String> = [
        "Iconic Landmark", "Free to Visit", "After Dark", "Designed by a Master",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            facetSection("PLACE TYPE — PICK AT LEAST ONE", facet: .placeType, required: true)
            facetSection("THEME — PICK AT LEAST ONE", facet: .theme, required: true)
            facetSection("STYLE & ERA — OPTIONAL", facet: .styleEra)
            facetSection("EXPERIENCE — OPTIONAL", facet: .experience)
            architectSection
        }
    }

    // MARK: - Facet chip sections

    private func facetSection(_ label: String, facet: TagFacet, required: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            sectionLabel(label, satisfied: required && isSatisfied(facet))
            FlowLayout(spacing: AtlasSpacing.sm) {
                ForEach(tags(for: facet), id: \.self) { tag in
                    Button {
                        toggle(tag)
                    } label: {
                        TagChip(text: tag, isSelected: selectedTags.contains(tag))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var architectSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            sectionLabel("ARCHITECT — OPTIONAL", satisfied: false)
            Menu {
                Button("None") { architect = nil }
                ForEach(Tag.tags(in: .architect), id: \.self) { name in
                    Button(name) { architect = name }
                }
            } label: {
                HStack {
                    Text(architect ?? "None")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(architect == nil ? AtlasColors.secondaryText : AtlasColors.primaryText)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                .padding(AtlasSpacing.md)
                .background(AtlasColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
            }
            if architect != nil {
                Text("Adds “Designed by a Master.”")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        }
    }

    // MARK: - Bits

    /// Section header. Required sections show a gold check once satisfied.
    private func sectionLabel(_ text: String, satisfied: Bool) -> some View {
        HStack(spacing: AtlasSpacing.xs) {
            Text(text)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
            if satisfied {
                Image(systemName: "checkmark.circle.fill")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
            }
        }
    }

    private func tags(for facet: TagFacet) -> [String] {
        let all = Tag.tags(in: facet)
        guard facet == .experience else { return all }
        return all.filter { !Self.experienceExclusions.contains($0) }
    }

    private func isSatisfied(_ facet: TagFacet) -> Bool {
        !selectedTags.isDisjoint(with: Set(Tag.tags(in: facet)))
    }

    private func toggle(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

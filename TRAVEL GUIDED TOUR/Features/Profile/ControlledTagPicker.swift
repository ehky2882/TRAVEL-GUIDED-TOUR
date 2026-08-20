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
/// **The open row takes whatever the closed ones leave** (2026-08-20), so this
/// whole step fits a screen with nothing scrolling — the same rule as the map on
/// Location and the description on Details. Two numbers make it work: rows pad
/// 9pt rather than 13, and the explanatory line that used to head this view now
/// lives in the wizard's footer hint, which reserves its height anyway.
///
/// **No facet is required** (owner decision, 2026-08-19). Tags decide where a
/// tour surfaces, not whether it works, and that is the maker's call — the
/// catalogue's validator treats a missing Place type or Theme as a warning,
/// never an error, and review is the backstop.
///
/// **Four facets are multi-select; Architect is one name.** Tapping a second
/// architect replaces the first, and choosing one auto-adds "Designed by a
/// Master" (handled by the caller).
///
/// ⚠️ **The catalogue disagrees with that last rule and the wizard cannot say
/// so.** 22 tours carry two or more architects — Barcelona's Cascada and
/// Dipòsit carry both Josep Fontserè and Antoni Gaudí by an explicit owner
/// decision, because Gaudí did the hydraulics as a student, and one Rio tour
/// names five. Editing such a tour here keeps the extra names (they survive in
/// `selectedTags`, so nothing is lost) but shows only the first, so they are
/// invisible and cannot be removed. Making Architect multi-select is a data
/// decision, not a layout one, and is still open.
///
/// Architect carries a search field because the vocabulary holds 94 names —
/// 1,728pt of chips, which is not a list anyone reads. The editorial tags a maker can't self-judge — `Iconic Landmark`,
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

    private static let rows: [(facet: TagFacet, label: String)] = [
        (.placeType,  "PLACE TYPE"),
        (.theme,      "THEME"),
        (.styleEra,   "STYLE & ERA"),
        (.experience, "EXPERIENCE"),
        (.architect,  "ARCHITECT"),
    ]

    /// Vertical padding inside a closed row. 9, not 13: four closed rows and
    /// one open header are the fixed cost of this step, and 4pt off each buys
    /// **40pt** for whichever group is open — which is the difference between
    /// Theme's 226pt of chips fitting in the space left and overflowing it.
    ///
    /// ⚠️ The alternative was collapsing rows to a single line, which buys
    /// twice as much and was measured against the real catalogue before being
    /// dropped: on one line the summary shares its width with the label, and
    /// **136 of 1,418 tours — 9.6% — would truncate their Theme row**
    /// ("Architecture, Commerce, Engineering, History, Remembrance" is a real
    /// tour's tags). Padding is free; truncation is not.
    private static let rowPadding: CGFloat = 9

    /// How many architects a search may show at once.
    ///
    /// The vocabulary holds 94 names — 1,728pt of chips, which no screen holds
    /// and no amount of layout fixes. The cap is what makes the row finite, and
    /// it is the shape the app's own place search already uses (which caps at
    /// five). Anything cut is *said*, never silently dropped.
    private static let architectResultCap = 8

    var body: some View {
        // Fills its step: the open group is the elastic element, exactly as the
        // map is on Location and the description is on Details.
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            ForEach(Self.rows, id: \.facet) { row in
                facetRow(row.facet, label: row.label)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Rows

    private func facetRow(_ facet: TagFacet, label: String) -> some View {
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
                        Text(label)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(AtlasColors.tertiaryText)
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
                .padding(.vertical, Self.rowPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isOpen ? "Collapses this group" : "Expands this group")

            if isOpen {
                Rectangle()
                    .fill(AtlasColors.divider)
                    .frame(height: 0.5)
                    .padding(.leading, AtlasSpacing.md)
                // The one flexible thing on the step. Its infinite max height
                // makes this row absorb whatever the four closed ones leave,
                // which is how the tallest group opens without the page
                // scrolling.
                chips(for: facet)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }

    @ViewBuilder
    private func chips(for facet: TagFacet) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            if facet == .architect {
                // 94 names, and the row shows none of them until you type —
                // then at most `architectResultCap`. The other four facets fit
                // on screen as chips and need no search.
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
            if facet == .architect, architectQuery.trimmingCharacters(in: .whitespaces).isEmpty,
               architect == nil {
                // Search first. Opening this row used to unroll all 94 names;
                // it now asks you to type, which is what you were going to do
                // anyway to find one you already have in mind.
                Text("Type a name to search.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            } else if options.isEmpty {
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

            // ⚠️ A cap that isn't stated is a cap that lies. If the search
            // matched more names than the row is showing, say so — otherwise
            // someone types "john", sees eight, and concludes their architect
            // isn't in the vocabulary.
            if facet == .architect, hiddenArchitectMatches > 0 {
                Text(hiddenArchitectMatches == 1
                     ? "1 more match. Keep typing to narrow."
                     : "\(hiddenArchitectMatches) more matches. Keep typing to narrow.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
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
            // Nothing typed: just what's already picked, so it can be undone.
            // Ninety-four chips is not a list anyone reads.
            guard !query.isEmpty else { return [architect].compactMap { $0 } }
            var shown = Array(architectMatches(for: query).prefix(Self.architectResultCap))
            // The current pick stays visible even when it doesn't match, or
            // the one chip you could tap to *un*pick would vanish as you type.
            if let architect, !shown.contains(architect) { shown.append(architect) }
            return shown
        default:
            return all
        }
    }

    /// Every architect matching the query, uncapped — what `options(for:)`
    /// then takes the first few of, and what `hiddenArchitectMatches` counts.
    private func architectMatches(for query: String) -> [String] {
        Tag.tags(in: .architect).filter { $0.localizedCaseInsensitiveContains(query) }
    }

    /// How many matches the cap is holding back, for the line that says so.
    private var hiddenArchitectMatches: Int {
        let query = architectQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return 0 }
        return max(0, architectMatches(for: query).count - Self.architectResultCap)
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
        facet == .architect
            ? architect != nil
            : !selectedTags.isDisjoint(with: Set(Tag.tags(in: facet)))
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

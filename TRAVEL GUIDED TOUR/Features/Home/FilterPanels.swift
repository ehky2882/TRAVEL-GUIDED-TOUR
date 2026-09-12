import SwiftUI

/// The panels behind the filter row. Three shapes cover every chip:
///
/// - a **short grid** — `Price`, and `Format` (which stacks, see below)
/// - a **grouped grid** — `Tags`, the only long one
/// - a **searchable list** — `Dozents`, and `Architect` inside `Tags`
///
/// Selections apply **live**: tick an option and the map behind has already
/// narrowed. The pill is not an Apply — it carries the live count and closes
/// the panel. There is deliberately no draft-and-commit split, because the two
/// can disagree and the count on the pill is the thing that tells you whether
/// to keep going.
struct FilterPanelHost: View {
    let route: FilterPanelRoute
    @Binding var filter: TourFilter
    let tours: [Tour]
    let makers: [Maker]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FilterPanel(
            title: title,
            resultCount: filter.matchCount(in: tours),
            onClear: clear,
            onCommit: { dismiss() }
        ) {
            switch route {
            case .all:
                AllFiltersBody(filter: $filter, tours: tours, makers: makers)
            case .group(.format):
                FormatBody(filter: $filter, tours: tours)
            case .group(.price):
                PriceBody(filter: $filter, tours: tours)
            case .group(.dozents):
                DozentsBody(filter: $filter, tours: tours, makers: makers)
            case .group(.tags):
                TagsBody(filter: $filter, tours: tours)
            }
        }
        // 🔴 FULL HEIGHT, AND NOT A MATTER OF TASTE ANY MORE.
        //
        // iOS 26 draws a PARTIAL-height sheet as a floating card: inset from
        // the sides, bottom edges pulled in to nest into the display's curved
        // corners, over a Liquid Glass background. Only at the LARGE detent
        // does that background go opaque and the sheet attach to the sides and
        // bottom of the screen. So "sized to its content" and "spans edge to
        // edge" cannot both be had — the owner chose edge to edge (on device,
        // 2026-09-12): **the only thing in this app that floats is the bottom
        // module.**
        //
        // ⚠️ Re-introducing a `.fraction` detent here re-introduces the
        // floating card. It is not a height knob on iOS 26.
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        // Full-bleed, so the panel's own colour reaches the screen edges and
        // runs under the home indicator. The inner `.background` could not:
        // panel content is inset by the safe area, which left a strip of
        // system material along the bottom.
        .presentationBackground(AtlasColors.secondaryBackground)
    }

    private var title: String {
        switch route {
        case .all: return "All filters"
        case .group(let g): return g.title
        }
    }

    private func clear() {
        switch route {
        case .all: filter = .none
        case .group(let g): filter.clear(g)
        }
    }
}

// MARK: - Panel chrome

/// Grabber, title, `Clear`, a scrolling body, and the floating commit pill.
struct FilterPanel<Content: View>: View {
    let title: String
    let resultCount: Int
    let onClear: () -> Void
    let onCommit: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                content
                // 🔴 The pill floats, so without this the last option sits
                // underneath it and cannot be tapped.
                Spacer(minLength: AtlasSpacing.panelRunOut)
            }
            .padding(.horizontal, AtlasSpacing.panelEdgeInset)
        }
        // The background belongs to the PRESENTATION, not to this scroll view
        // — see `presentationBackground` on the host.
        .overlay(alignment: .bottom) { pill }
    }

    /// The title is the **caption font** — 13 pt SF Mono, uppercase, tracked —
    /// not a sans semibold sheet title. `HomeDrawerContent`'s count header is
    /// already `AtlasTypography.caption` with tracking and uppercase copy, so
    /// panel chrome is mono in this app.
    ///
    /// Centred, with `Clear` laid over the trailing edge rather than placed
    /// beside it: a title centred against a right-hand neighbour is never
    /// actually centred, which is what made an earlier attempt look off.
    private var header: some View {
        ZStack {
            Text(title.uppercased())
                .font(AtlasTypography.caption)
                .tracking(1)
                .foregroundStyle(AtlasColors.primaryText)
                .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                Button("Clear", action: onClear)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
                    .buttonStyle(.plain)
            }
        }
        .padding(.top, AtlasSpacing.panelTopInset)
        .padding(.bottom, AtlasSpacing.lg)
    }

    private var pill: some View {
        Button(action: onCommit) {
            Text(resultLabel)
                .font(AtlasTypography.caption)
                .tracking(0.5)
                .foregroundStyle(AtlasColors.background)
                .padding(.horizontal, AtlasSpacing.lg + AtlasSpacing.xs)
                .frame(height: AtlasSpacing.xxl + AtlasSpacing.xs / 2)
                .background(AtlasColors.brass, in: Capsule())
                .shadow(color: .black.opacity(0.22), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.bottom, AtlasSpacing.lg)
    }

    /// **"Results"** is the noun (owner, 2026-09-12): "pins" is our word for
    /// map markers and should never reach a viewer, and "tours" is wrong for
    /// the pinned posts, which outnumber the tours.
    private var resultLabel: String {
        switch resultCount {
        case 0: return "NO RESULTS"
        case 1: return "SHOW 1 RESULT"
        default: return "SHOW \(resultCount.formatted(.number)) RESULTS"
        }
    }
}

/// A group label inside a panel: 11 pt mono, left-aligned, in secondary ink.
/// Hierarchy against the panel title comes from size and colour rather than a
/// second typeface.
private struct GroupLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(AtlasTypography.caption)
            .tracking(1)
            .foregroundStyle(AtlasColors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AtlasSpacing.lg + AtlasSpacing.xs)
            .padding(.bottom, AtlasSpacing.xs / 2)
    }
}

// MARK: - Format

/// 🔴 **The only panel that stacks one option per row.** Its five-going-on-seven
/// options have a real pecking order — 1,481 audio stops down to 3 YouTube
/// Shorts — so a column reads like a list you work down. `Tags` has thirty-odd
/// values across five groups where nothing outranks anything, and stacking that
/// cost two screens of scrolling for no gain.
private struct FormatBody: View {
    @Binding var filter: TourFilter
    let tours: [Tour]
    /// One option per row. True in the Format panel, whose whole job is these
    /// seven; **false in the All panel** (owner, on device, 2026-09-12), where
    /// Format is one section among four and seven full-width rows cost most of
    /// a screen before the reader reaches Price. The pecking order that earns
    /// the column is worth reading when Format is the subject and not worth a
    /// screen when it is a heading.
    var stacked: Bool = true

    var body: some View {
        if stacked {
            VStack(alignment: .leading, spacing: 0) { chips }
        } else {
            FilterFlowLayout() { chips }
        }
    }

    @ViewBuilder
    private var chips: some View {
        ForEach(FormatOption.allCases) { option in
            let choice = FilterOption.format(option)
            FilterOptionChip(
                label: option.label,
                count: filter.count(adding: choice, in: tours),
                isSelected: filter.formats.contains(option)
            ) {
                filter.toggle(choice)
            }
        }
    }
}

// MARK: - Price

private struct PriceBody: View {
    @Binding var filter: TourFilter
    let tours: [Tour]

    var body: some View {
        FilterFlowLayout() {
            ForEach(PriceOption.allCases) { option in
                let choice = FilterOption.price(option)
                FilterOptionChip(
                    label: option.label,
                    count: filter.count(adding: choice, in: tours),
                    isSelected: filter.prices.contains(option)
                ) {
                    filter.toggle(choice)
                }
            }
        }
    }
}

// MARK: - Dozents

/// A searchable list, not a grid: 377 values will not fit one.
///
/// **One flat list** — no Studio-versus-pinned split (owner, 2026-09-12). A
/// Dozent is a Dozent whether they record for us or we pin their post, and the
/// panel must not sort them into first and second class. Ordered by how much of
/// the map is theirs, which is the one place in this design where size order
/// beats the alphabet: it is a relevance ranking, and alphabetically the list
/// would open on whichever handle happens to begin with an A.
private struct DozentsBody: View {
    @Binding var filter: TourFilter
    let tours: [Tour]
    let makers: [Maker]
    /// Whether an empty search box still lists the busiest Dozents. True in the
    /// Dozents panel, where a list is the whole point; **false in the All
    /// panel** (owner, on device, 2026-09-12) — there the search field alone
    /// says what the section does, and twelve avatar rows buried Tags below
    /// them. Selected Dozents stay visible either way, by the same rule that
    /// keeps a selected-but-unpromoted tag on screen: a panel must never hide a
    /// filter that is switched on.
    var showsUnsearchedList: Bool = true

    @State private var query = ""

    /// How much of the map is each Dozent's. Computed once per render and
    /// handed down, rather than recomputed inside the sort's comparator.
    private var pinCounts: [UUID: Int] {
        tours.reduce(into: [:]) { totals, tour in totals[tour.makerId, default: 0] += 1 }
    }

    private func listed(by counts: [UUID: Int]) -> [Maker] {
        FilterPanelRules.listedMakers(
            makers,
            query: query,
            selected: filter.makerIds,
            counts: counts,
            showsUnsearchedList: showsUnsearchedList
        )
    }

    var body: some View {
        let counts = pinCounts
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                TextField("Search \(makers.count) Dozents", text: $query)
                    .font(AtlasTypography.caption)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, AtlasSpacing.md)
            .frame(height: AtlasSpacing.xl + AtlasSpacing.sm)
            .background(AtlasColors.background, in: Capsule())
            // See `AtlasSpacing.panelSearchLead` — a bare capsule has none of
            // the absorbed row gap a chip carries, so without this it met its
            // heading tighter than everything else on the screen.
            .padding(.top, AtlasSpacing.panelSearchLead)

            ForEach(listed(by: counts)) { maker in
                row(maker, count: counts[maker.id] ?? 0)
            }
        }
    }

    private func row(_ maker: Maker, count: Int) -> some View {
        let choice = FilterOption.maker(maker.id)
        let isSelected = filter.makerIds.contains(maker.id)
        return Button {
            filter.toggle(choice)
        } label: {
            HStack(spacing: AtlasSpacing.sm + AtlasSpacing.xs) {
                // Every row gets the same avatar treatment — no two-tier
                // split between studios and pinned Dozents. `MakerAvatarView`
                // already handles the photo, the monogram fallback and the
                // frame-zero cache read.
                MakerAvatarView(maker: maker, size: AtlasSpacing.xl + AtlasSpacing.xs)
                Text(maker.displayName)
                    .font(AtlasTypography.body)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(count)")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                Image(systemName: "checkmark")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
                    .opacity(isSelected ? 1 : 0)
            }
            .foregroundStyle(AtlasColors.primaryText)
            .frame(height: AtlasSpacing.xxl + AtlasSpacing.sm)
            .overlay(alignment: .top) {
                Rectangle().fill(AtlasColors.divider).frame(height: 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tags

/// The whole controlled vocabulary in one panel: four groups of chips plus the
/// architect search. The groups still AND against each other — that is the
/// point of keeping them apart, and `Tag.matches` does it from the flat
/// selection without being told which chip the user tapped.
private struct TagsBody: View {
    @Binding var filter: TourFilter
    let tours: [Tour]

    /// Groups whose `More` has been opened. Local to the panel: reopening it
    /// later starts collapsed again, because the promoted set is the answer for
    /// almost everyone almost always.
    @State private var expanded: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Tag.panelGroups) { group in
                GroupLabel(text: group.title)
                FilterFlowLayout() {
                    ForEach(values(for: group), id: \.self) { tag in
                        chip(tag)
                    }
                    if group.moreCount > 0, !expanded.contains(group.id) {
                        moreChip(group)
                    }
                }
            }
            GroupLabel(text: Tag.searchedFacet.rawValue)
            ArchitectSearch(filter: $filter, tours: tours)
        }
    }

    private func values(for group: Tag.PanelGroup) -> [String] {
        if expanded.contains(group.id) {
            // Alphabetical on expansion too, so a value does not move when the
            // group opens.
            return Tag.tags(in: group.facet).sorted()
        }
        // Anything selected but not promoted stays visible — otherwise opening
        // the panel would hide a filter that is on.
        let selected = filter.tags.filter { Tag.facet(for: $0) == group.facet }
        return Array(Set(group.promoted).union(selected)).sorted()
    }

    private func chip(_ tag: String) -> some View {
        let choice = FilterOption.tag(tag)
        return FilterOptionChip(
            label: tag,
            count: filter.count(adding: choice, in: tours),
            isSelected: filter.tags.contains(tag)
        ) {
            filter.toggle(choice)
        }
    }

    private func moreChip(_ group: Tag.PanelGroup) -> some View {
        Button {
            expanded.insert(group.id)
        } label: {
            Text("More (\(group.moreCount))")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .padding(.horizontal, AtlasSpacing.sm + 5)
                .frame(height: AtlasSpacing.panelChipHeight)
                .background(Capsule().fill(AtlasColors.background))
                .frame(height: AtlasSpacing.panelChipHeight + AtlasSpacing.panelRowGap)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 429 architects, the largest matching 23 pins — so every one of them is small
/// by construction and a grid of chips would be the worst screen in the app.
/// Search only, and still multi-select: search changes the presentation, never
/// how the facet combines.
private struct ArchitectSearch: View {
    @Binding var filter: TourFilter
    let tours: [Tour]

    @State private var query = ""

    private var results: [String] {
        let all = Tag.tags(in: Tag.searchedFacet)
        guard !query.isEmpty else {
            return Array(filter.tags.filter { Tag.facet(for: $0) == Tag.searchedFacet }).sorted()
        }
        return all.filter { $0.localizedCaseInsensitiveContains(query) }.sorted().prefix(20).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                TextField("Search \(Tag.tags(in: Tag.searchedFacet).count) architects", text: $query)
                    .font(AtlasTypography.caption)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, AtlasSpacing.md)
            .frame(height: AtlasSpacing.xl + AtlasSpacing.sm)
            .background(AtlasColors.background, in: Capsule())
            // Same lead-in as the Dozents field; this is the one the owner
            // spotted, and fixing only this one would have left the other
            // inconsistent. See `AtlasSpacing.panelSearchLead`.
            .padding(.top, AtlasSpacing.panelSearchLead)

            FilterFlowLayout() {
                ForEach(results, id: \.self) { name in
                    let choice = FilterOption.tag(name)
                    FilterOptionChip(
                        label: name,
                        count: filter.count(adding: choice, in: tours),
                        isSelected: filter.tags.contains(name)
                    ) {
                        filter.toggle(choice)
                    }
                }
            }
        }
    }
}

// MARK: - All

/// Every facet in one scroll, one heading level deep.
///
/// Kept because some people would rather scan one list than open four panels
/// (owner, 2026-09-12) — which is how the reference app leads its row. It was
/// briefly cut on the reasoning that it duplicates the chips; duplication is
/// the point. It writes into the same `TourFilter`, so the two routes cannot
/// disagree.
private struct AllFiltersBody: View {
    @Binding var filter: TourFilter
    let tours: [Tour]
    let makers: [Maker]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupLabel(text: FilterGroup.format.title)
            // Flowed rather than stacked here — see `FormatBody.stacked`.
            FormatBody(filter: $filter, tours: tours, stacked: false)
            GroupLabel(text: FilterGroup.price.title)
            PriceBody(filter: $filter, tours: tours)
            GroupLabel(text: FilterGroup.dozents.title)
            // Search field only until something is typed — see
            // `DozentsBody.showsUnsearchedList`.
            DozentsBody(
                filter: $filter,
                tours: tours,
                makers: makers,
                showsUnsearchedList: false
            )
            TagsBody(filter: $filter, tours: tours)
        }
    }
}

// MARK: - Rules worth testing without a screen

/// Panel behaviour that is a **decision** rather than a layout, lifted out of
/// the private view structs so it can be tested without a `View`.
enum FilterPanelRules {

    /// Which Dozents a panel lists, given what has been typed and where the
    /// panel is.
    ///
    /// Three rules, in order of how surprising they are:
    ///
    /// 1. **Typing searches all 377 of them**, capped at 30 — a search that
    ///    stops at the first dozen matches is a search that lies.
    /// 2. **An empty box lists the busiest twelve** in the Dozents panel, and
    ///    in the All panel lists nothing (`showsUnsearchedList: false`). The
    ///    field alone says what the section does; twelve avatar rows there
    ///    pushed Tags off the screen.
    /// 3. 🔴 **A selected Dozent is always listed while the box is empty**,
    ///    whichever panel it is, even if they are not in the busiest twelve.
    ///    Otherwise the panel would hide a filter that is switched on and the
    ///    only way to turn it off would be to guess the name.
    ///
    /// Ordered by how much of the map is theirs, ties alphabetical — the one
    /// place in this design where size order beats the alphabet, because it is
    /// a relevance ranking (see `DozentsBody`).
    static func listedMakers(
        _ makers: [Maker],
        query: String,
        selected: Set<UUID>,
        counts: [UUID: Int],
        showsUnsearchedList: Bool
    ) -> [Maker] {
        let typed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        func busiestFirst(_ left: Maker, _ right: Maker) -> Bool {
            let l = counts[left.id] ?? 0
            let r = counts[right.id] ?? 0
            return l == r ? left.displayName < right.displayName : l > r
        }

        guard typed.isEmpty else {
            return makers
                .filter { $0.displayName.localizedCaseInsensitiveContains(typed) }
                .sorted(by: busiestFirst)
                .prefix(searchedLimit)
                .map { $0 }
        }

        let opening = showsUnsearchedList
            ? Array(makers.sorted(by: busiestFirst).prefix(unsearchedLimit))
            : []
        let shown = Set(opening.map(\.id))
        // Rule 3. In the All panel `opening` is empty, so this IS the list.
        let selectedButUnlisted = makers.filter { selected.contains($0.id) && !shown.contains($0.id) }
        guard !selectedButUnlisted.isEmpty else { return opening }
        return (opening + selectedButUnlisted).sorted(by: busiestFirst)
    }

    /// The busiest few, when nothing has been typed and the panel lists.
    static let unsearchedLimit = 12
    /// Matches for something typed. Capped only so a one-letter query does not
    /// build 377 rows.
    static let searchedLimit = 30
}

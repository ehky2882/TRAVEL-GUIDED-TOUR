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
        .presentationDetents([.fraction(detent)])
        .presentationDragIndicator(.visible)
    }

    private var title: String {
        switch route {
        case .all: return "All filters"
        case .group(let g): return g.title
        }
    }

    /// Fractions rather than the absolute heights the design was drawn at
    /// (552 pt for Format, 780 for Tags), so the panels keep their proportions
    /// on a phone that is not 844 pt tall. ⚠️ On a 667 pt screen the Tags panel
    /// scrolls whatever we do — "fits one screen" is a property of large
    /// phones, not of this design, which is why the group heading pins and
    /// every panel carries `AtlasSpacing.panelRunOut`.
    private var detent: CGFloat {
        switch route {
        case .all: return 0.92
        case .group(.format): return 0.65
        case .group(.price): return 0.36
        case .group(.dozents): return 0.82
        case .group(.tags): return 0.92
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
            .padding(.horizontal, AtlasSpacing.md)
        }
        .background(AtlasColors.secondaryBackground)
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
        .padding(.top, AtlasSpacing.md)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

    @State private var query = ""

    /// How much of the map is each Dozent's. Computed once per render and
    /// handed down, rather than recomputed inside the sort's comparator.
    private var pinCounts: [UUID: Int] {
        tours.reduce(into: [:]) { totals, tour in totals[tour.makerId, default: 0] += 1 }
    }

    private func listed(by counts: [UUID: Int]) -> [Maker] {
        let matching = query.isEmpty
            ? makers
            : makers.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
        return matching
            .sorted { left, right in
                let l = counts[left.id] ?? 0
                let r = counts[right.id] ?? 0
                // Most of the map first; ties fall back to the alphabet so the
                // order is at least stable among the 252 with a single pin.
                return l == r ? left.displayName < right.displayName : l > r
            }
            .prefix(query.isEmpty ? 12 : 30)
            .map { $0 }
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
            FormatBody(filter: $filter, tours: tours)
            GroupLabel(text: FilterGroup.price.title)
            PriceBody(filter: $filter, tours: tours)
            GroupLabel(text: FilterGroup.dozents.title)
            DozentsBody(filter: $filter, tours: tours, makers: makers)
            TagsBody(filter: $filter, tours: tours)
        }
    }
}

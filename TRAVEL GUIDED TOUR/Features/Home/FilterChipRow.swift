import SwiftUI

/// The home map's filter row: a door and four chips.
///
/// ```
/// ≡ All  ·  Format ⌄  ·  Price ⌄  ·  Dozents ⌄  ·  Tags ⌄
/// ```
///
/// Replaces the flat eighteen-toggle row (`TagFilterChipRow`, owner decision
/// D8). The row splits along a real seam: three **structural fields** on
/// `Tour` — `kind`, `priceTier`, `makerId` — get a chip each because each asks
/// a different kind of question, and the **entire controlled vocabulary** gets
/// one chip because it is all the same kind of question.
///
/// Every chip is multi-select. Several values inside one chip mean *any* of
/// them (`Instagram Reels` + `TikTok` gets both); values across chips mean
/// *all* of them (`Museum` + `Paid` gets paid museums). `TourFilter` owns that
/// rule; this row only opens panels.
///
/// Design + the reasoning behind each call: `docs/filter-chips-design.md`.
struct FilterChipRow: View {
    /// Only for the collapsed chip labels — a maker id becomes a display name.
    /// ⚠️ The row does NOT take the tour catalogue: the contextual counts are
    /// computed inside the panels, which are built in `BottomModuleRoot` and
    /// read `DataService` there.
    let makers: [Maker]

    /// 🔴 **The row does not present the panel — it asks for one.**
    ///
    /// `AppSharedState` is the state both windows can see, and the panel is
    /// presented from `BottomModuleRoot` so that it slides up OVER the
    /// mini-player and tab bar rather than behind them (they live in a window
    /// at `.normal + 1`). The alternative — a `.sheet` here plus withdrawing
    /// the bars — was built and filmed: the module vanished ~130 ms before the
    /// sheet appeared, leaving a hole with bare map in it. Session 24 had
    /// already learned the same thing with `PlayerView`. See
    /// `AppSharedState.filterPanel`.
    @Environment(AppSharedState.self) private var appShared: AppSharedState?

    /// Nil-safe read: previews inject no shared state, and an empty filter is
    /// the right thing to draw there.
    private var filter: TourFilter { appShared?.filter ?? .none }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.sm) {
                allChip
                ForEach(FilterGroup.allCases) { group in
                    groupChip(group)
                }
            }
            .padding(.horizontal, AtlasSpacing.md)
        }
    }

    // MARK: - Chips

    /// 🔴 **`All` never fills brass — it is a door, not a filter.** Its badge
    /// counts the values switched on behind it, which is the only thing in the
    /// row that reports state the chips cannot show once they scroll past the
    /// edge.
    private var allChip: some View {
        FilterRowChip(
            label: "All",
            systemImage: "line.3.horizontal.decrease",
            badge: filter.isActive ? filter.valueCount : nil,
            showsChevron: false,
            isSelected: false
        ) {
            appShared?.filterPanel = .all
        }
    }

    /// A set chip becomes its own answer — `Museum`, or `Museum +2` — because
    /// the group's name tells you nothing you did not already know once you
    /// have chosen. Empty, it shows the group name and a chevron.
    private func groupChip(_ group: FilterGroup) -> some View {
        let values = filter.values(in: group, makerName: makerName)
        let label: String
        switch values.count {
        case 0: label = group.title
        case 1: label = values[0]
        default: label = "\(values[0]) +\(values.count - 1)"
        }
        return FilterRowChip(
            label: label,
            systemImage: nil,
            badge: nil,
            showsChevron: true,
            isSelected: !values.isEmpty
        ) {
            appShared?.filterPanel = .group(group)
        }
    }

    private func makerName(_ id: UUID) -> String? {
        makers.first { $0.id == id }?.displayName
    }
}

// MARK: - Which panel

/// Identifies the panel to present. `all` is its own case rather than a fifth
/// `FilterGroup`, because the All panel is not a group — it holds every group.
enum FilterPanelRoute: Identifiable, Hashable {
    case all
    case group(FilterGroup)

    var id: String {
        switch self {
        case .all: return "all"
        case .group(let g): return g.rawValue
        }
    }
}

// MARK: - The row's chip

/// The row chip: a **44 pt** capsule, the same height as the search bar
/// (`AtlasSpacing.searchBarHeight`) and the round map buttons beside it.
///
/// 🔴 44 is the one number in this design that is not a matter of taste — it is
/// Apple's minimum tap target, and this row is the one-handed-while-walking
/// surface. Panel options are smaller (`AtlasSpacing.panelChipHeight`); the row
/// is not.
struct FilterRowChip: View {
    let label: String
    let systemImage: String?
    let badge: Int?
    let showsChevron: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AtlasSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(AtlasTypography.caption)
                }
                Text(label)
                    .font(AtlasTypography.caption)
                    .lineLimit(1)
                if let badge {
                    Text("\(badge)")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.background)
                        .padding(.horizontal, AtlasSpacing.xs + 1)
                        .frame(minWidth: AtlasSpacing.md + 2, minHeight: AtlasSpacing.md + 2)
                        .background(AtlasColors.brass, in: Capsule())
                }
                if showsChevron {
                    Image(systemName: "chevron.down")
                        .font(AtlasTypography.caption)
                        .opacity(0.55)
                }
            }
            .foregroundStyle(isSelected ? AtlasColors.background : AtlasColors.primaryText)
            .padding(.horizontal, AtlasSpacing.md)
            .frame(height: AtlasSpacing.searchBarHeight)
            .background(
                Capsule().fill(isSelected ? AtlasColors.mapPin : AtlasColors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - A panel option

/// An option inside a panel: a **32 pt** capsule in a **48 pt** frame.
///
/// 🔴 The frame is the point. What a thumb feels is the vertical **pitch** —
/// the chip plus the gap it can absorb — not the drawn height, so the capsule
/// is drawn at `panelChipHeight` inside a frame that also owns `panelRowGap`,
/// and `.contentShape` makes that whole frame tappable. 32 + 16 = a 48 pt
/// target from a chip that looks 32. Lay these out with **zero** vertical
/// spacing: the gap is already inside the frame, and adding it again doubles it.
struct FilterOptionChip: View {
    let label: String
    /// Contextual — how many tours match if this were also selected. See
    /// `TourFilter.count(adding:in:)` for why it is never the global count.
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    /// Nothing to find. Dimmed rather than hidden: a chip that vanishes reads
    /// as a bug, and "impossible alongside what you have picked" is
    /// information. Still tappable — refusing the tap would be a dead end with
    /// no explanation.
    private var isDead: Bool { count == 0 && !isSelected }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AtlasSpacing.sm - 1) {
                Text(label)
                    .font(AtlasTypography.caption)
                    .lineLimit(1)
                Text("\(count)")
                    .font(AtlasTypography.caption)
                    .opacity(0.5)
            }
            .foregroundStyle(isSelected ? AtlasColors.background : AtlasColors.primaryText)
            .padding(.horizontal, AtlasSpacing.sm + 5)
            .frame(height: AtlasSpacing.panelChipHeight)
            .background(
                Capsule().fill(isSelected ? AtlasColors.mapPin : AtlasColors.background)
            )
            .opacity(isDead ? 0.4 : 1)
            // The absorbed gap, and the reason the target is 48 rather than 32.
            .frame(height: AtlasSpacing.panelChipHeight + AtlasSpacing.panelRowGap)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wrapping layout

/// Chips that wrap onto as many rows as they need, each row hugging its
/// content. SwiftUI has no built-in flow layout and a `LazyVGrid` will not do:
/// its columns are uniform, and these chips run from "Art" to "Designed by a
/// Master".
///
/// Vertical spacing defaults to **zero** on purpose — `FilterOptionChip`
/// carries the row gap inside its own frame so the gap is tappable. Pass a
/// non-zero `verticalSpacing` only for content that is not an option chip.
struct FilterFlowLayout: Layout {
    var horizontalSpacing: CGFloat = AtlasSpacing.panelColumnGap
    var verticalSpacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var total = CGSize.zero

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let needed = rowWidth == 0 ? size.width : rowWidth + horizontalSpacing + size.width
            if needed > maxWidth, rowWidth > 0 {
                total.width = max(total.width, rowWidth)
                total.height += rowHeight + verticalSpacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = needed
                rowHeight = max(rowHeight, size.height)
            }
        }
        total.width = max(total.width, rowWidth)
        total.height += rowHeight
        return total
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

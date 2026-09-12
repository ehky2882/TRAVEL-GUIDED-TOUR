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
    @Binding var filter: TourFilter
    /// Every tour the chips can match, for the contextual counts inside the
    /// panels. The panels need the catalogue; the row itself does not.
    let tours: [Tour]
    let makers: [Maker]

    /// Which panel is up, if any. `nil` is the resting state.
    @State private var presented: FilterPanelRoute?

    /// 🔴 **Why a filter panel has to switch the bottom module off.**
    ///
    /// The mini-player and tab bar do not live in this window.
    /// `BottomModuleWindowController` installs a separate `UIWindow` at
    /// `.normal + 1` — deliberately, so that UIKit modals in the main window
    /// slide up *behind* the persistent player, the way Apple Music's does. A
    /// `.sheet` is exactly such a modal, so the module painted over the bottom
    /// 126 pt of every panel, taking the commit pill with it (owner, on device,
    /// 2026-09-12).
    ///
    /// So the panel withdraws the bars for as long as it is up. That is the
    /// established move for this collision: the tour wizard does it for the
    /// height, and a link pin's embedded player does it for element fullscreen
    /// (`TourDetailView.setBottomModuleHidden`). ⚠️ The other escape —
    /// presenting from inside the top window, which is what `PlayerView` does —
    /// is not available to a sheet bound to this row's state.
    ///
    /// ⚠️ `hidesBottomModule` is a plain Bool, not a count, so **two owners
    /// must never overlap.** This one cannot overlap either existing owner: the
    /// wizard covers the screen from the Me tab, and a tour page (where the
    /// embed's fullscreen lives) is not reachable from inside a filter panel.
    /// And this row restores only what it withdrew — `withdrewModule` is the
    /// ownership record, so a panel dismissed while some other screen has the
    /// bars withdrawn cannot put them back on top of it.
    @State private var withdrewModule = false

    @Environment(AppSharedState.self) private var appShared: AppSharedState?
    /// Optional for the same reason `appShared` is: this row renders in
    /// previews and tests where neither window nor shared state exists.
    @Environment(BottomModuleWindowController.self)
    private var bottomModuleWindow: BottomModuleWindowController?

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
        .sheet(item: $presented, onDismiss: { restoreBottomModule() }) { route in
            FilterPanelHost(route: route, filter: $filter, tours: tours, makers: makers)
        }
        .onChange(of: presented != nil) { _, isUp in
            if isUp { withdrawBottomModule() }
        }
        // Backstop. `onDismiss` covers both a swipe and the pill's own
        // `dismiss()` — and it fires when the slide FINISHES, which is what
        // keeps the bars from popping in behind a sheet still on its way down.
        // This second path exists because the bars going missing for a whole
        // session is a failure this app has shipped three times, and
        // `syncBottomModuleVisibility()` cannot heal it: on every foreground it
        // re-derives from `hidesBottomModule`, so it re-asserts a stuck flag
        // rather than clearing it. A tab torn down under an open panel fires
        // this while the ownership record is still intact.
        .onDisappear { restoreBottomModule() }
    }

    // MARK: - The bottom module

    @MainActor
    private func withdrawBottomModule() {
        guard !withdrewModule else { return }
        withdrewModule = true
        setBottomModuleHidden(true)
    }

    @MainActor
    private func restoreBottomModule() {
        guard withdrewModule else { return }
        withdrewModule = false
        setBottomModuleHidden(false)
    }

    /// Both, deliberately: hiding the window stops it painting AND hit-testing,
    /// while the flag stops `ContentView`'s inline fallback drawing the same
    /// bars in the main window on a launch where that window never installed.
    @MainActor
    private func setBottomModuleHidden(_ hidden: Bool) {
        appShared?.hidesBottomModule = hidden
        bottomModuleWindow?.setHidden(hidden)
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
            presented = .all
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
            presented = .group(group)
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

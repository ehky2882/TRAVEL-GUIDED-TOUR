import SwiftUI

/// Custom floating tab bar — replaces the system `TabView` chrome
/// so we can match the home-screen drawer's width, inset, and shape
/// exactly. Uses `secondaryBackground` so the buttons stay legible
/// regardless of what the map is showing behind it.
///
/// Shape: rounded pill, 8pt inset from the screen edges on both
/// sides, phone-radius rounded bottom corners, square top corners
/// (so the rectangular mini-player stacks flush above it).
///
/// **The view renders this same shape everywhere — Home root,
/// Library, Me, every pushed detail.** That keeps the buttons
/// themselves in the exact same place across surfaces — same x,
/// same y, same width per column. The only thing that changes
/// between Home (floating-island look) and the other surfaces
/// (full-edge look) is a separate edge-to-edge background fill
/// `ContentView` paints behind this view. On Home there's no fill,
/// so the 8pt side gaps + 8pt bottom gap show the map underneath;
/// elsewhere the fill is `secondaryBackground` (same color as the
/// bar), so the gaps blend into the fill and the whole bottom
/// region reads as one continuous opaque strip.
struct AtlasTabBar: View {
    @Binding var selected: AtlasTab

    /// When `false` (Home + detail-up), the painted button row is
    /// inset 8pt from the screen edges with phone-radius rounded
    /// bottom corners, and an 8pt transparent strip sits below it
    /// — the floating-island look. When `true` (Library / Me with
    /// no detail), the painted row grows to the screen edges with
    /// square corners and no outer strip — the flat full-edge look.
    /// In both modes the buttons themselves sit at the SAME x
    /// positions (8pt inner padding inside the painted row), so
    /// the design rule of "buttons identical everywhere" holds.
    var extendsToScreenEdges: Bool = false

    /// Tabs that should show a small gold notification badge on their icon
    /// (e.g. the Me tab when pending follow requests are waiting).
    var badgedTabs: Set<AtlasTab> = []

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(AtlasTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            // Inner H padding keeps the buttons inset from the
            // painted bar's edges in edge-to-edge mode (so the
            // button x positions match the island mode).
            .padding(.horizontal, extendsToScreenEdges ? 8 : 0)
            .padding(.vertical, AtlasSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(AtlasColors.tabBarBackground)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: extendsToScreenEdges ? 0 : AtlasSpacing.phoneScreenRadius,
                    bottomTrailingRadius: extendsToScreenEdges ? 0 : AtlasSpacing.phoneScreenRadius,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
            .padding(.horizontal, extendsToScreenEdges ? 0 : 8)

            // 8pt strip below the painted button row. Transparent
            // in island mode (map / detail body shows through),
            // opaque-painted in edge-to-edge mode so the chrome
            // continues down to the screen bottom seamlessly.
            (extendsToScreenEdges ? AtlasColors.tabBarBackground : Color.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 8)
        }
    }

    private func tabButton(_ tab: AtlasTab) -> some View {
        let isSelected = selected == tab
        return Button {
            selected = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.selectedSystemImage : tab.systemImage)
                    .font(.system(size: 20))
                    // Gold notification dot — ringed in the bar color so it
                    // reads as a separate badge floating over the icon.
                    .overlay(alignment: .topTrailing) {
                        if badgedTabs.contains(tab) {
                            Circle()
                                .fill(AtlasColors.mapPin)
                                .frame(width: 9, height: 9)
                                .overlay(
                                    Circle().stroke(AtlasColors.tabBarBackground, lineWidth: 1.5)
                                )
                                .offset(x: 5, y: -3)
                                .accessibilityHidden(true)
                        }
                    }
                // Uppercased at the display site (not in the enum)
                // so the .accessibilityLabel(tab.label) below stays
                // proper-cased — VoiceOver pronounces "Home" as a
                // word instead of spelling H-O-M-E.
                Text(tab.label.uppercased())
                    .font(AtlasTypography.caption)
            }
            .foregroundStyle(
                isSelected ? AtlasColors.primaryText : AtlasColors.secondaryText
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, AtlasSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityValue(badgedTabs.contains(tab) ? "New notifications" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

enum AtlasTab: CaseIterable {
    case home
    case library
    case me

    var label: String {
        switch self {
        case .home:    return "Home"
        case .library: return "Library"
        case .me:      return "Me"
        }
    }

    var systemImage: String {
        switch self {
        case .home:    return "house"
        case .library: return "bookmark"
        case .me:      return "person.crop.circle"
        }
    }

    /// The "filled" variant shown when this tab is selected — matches
    /// the system convention.
    var selectedSystemImage: String {
        switch self {
        case .home:    return "house.fill"
        case .library: return "bookmark.fill"
        case .me:      return "person.crop.circle.fill"
        }
    }
}

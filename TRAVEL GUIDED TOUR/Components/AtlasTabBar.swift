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

    /// Square top corners — the rectangular mini-player stacks flush
    /// on top, so the tab bar's top edge must be square to meet it
    /// seamlessly.
    var topCornerRadius: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Button row — the painted "pill". Identical layout on
            // every surface so the buttons themselves never shift.
            HStack(spacing: 0) {
                ForEach(AtlasTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.vertical, AtlasSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(AtlasColors.secondaryBackground)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: topCornerRadius,
                    bottomLeadingRadius: AtlasSpacing.phoneScreenRadius,
                    bottomTrailingRadius: AtlasSpacing.phoneScreenRadius,
                    topTrailingRadius: topCornerRadius,
                    style: .continuous
                )
            )
            .padding(.horizontal, 8)

            // 8pt transparent strip below the painted pill. On Home
            // this shows the map behind; on non-Home surfaces it
            // shows the edge-to-edge background fill `ContentView`
            // paints behind the whole module (same color as the
            // pill, so the gap blends in).
            Color.clear
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
                    .font(.system(size: 22))
                Text(tab.label)
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

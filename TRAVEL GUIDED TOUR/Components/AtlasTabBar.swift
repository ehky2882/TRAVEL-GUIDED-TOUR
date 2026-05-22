import SwiftUI

/// Custom floating tab bar — replaces the system `TabView` chrome
/// so we can match the home-screen drawer's width, inset, and shape
/// exactly. Uses `.thickMaterial` for an almost-opaque backdrop so
/// the buttons stay legible regardless of what the map is showing
/// behind it.
///
/// Shape:
///   - Top corners: square — the rectangular mini-player stacks flush above
///   - Bottom corners: phone-screen radius (the floating-island look)
///
/// When the home drawer is open, the drawer's glass extends down
/// past the safe area and behind this tab bar; the two sit at the
/// same horizontal inset, with the same bottom-corner radius, so
/// they read as one floating phone-shaped island. On tabs without
/// a drawer (Library, Me), the tab bar is the whole island.
struct AtlasTabBar: View {
    @Binding var selected: AtlasTab

    /// Same horizontal inset the BottomSheet uses (8pt) so the tab
    /// bar columns align with the drawer's edges.
    var horizontalInset: CGFloat = 8
    /// Square top corners — the rectangular mini-player stacks flush
    /// on top, so the tab bar's top edge must be square to meet it
    /// seamlessly.
    var topCornerRadius: CGFloat = 0
    /// Phone-screen radius for the bottom corners.
    var bottomCornerRadius: CGFloat = AtlasSpacing.phoneScreenRadius

    var body: some View {
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
                bottomLeadingRadius: bottomCornerRadius,
                bottomTrailingRadius: bottomCornerRadius,
                topTrailingRadius: topCornerRadius,
                style: .continuous
            )
        )
        .padding(.horizontal, horizontalInset)
        .padding(.bottom, horizontalInset)
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

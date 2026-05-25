import SwiftUI

/// Custom floating tab bar — replaces the system `TabView` chrome
/// so we can match the home-screen drawer's width, inset, and shape
/// exactly. Uses `secondaryBackground` so the buttons stay legible
/// regardless of what the map is showing behind it.
///
/// Shape:
///   - Top corners: square — the rectangular mini-player stacks flush above
///   - Bottom corners: phone-screen radius on Home (the floating-
///     island pill look); square on every other surface, where the
///     bar reads as a flat strip flush to the screen edges
///
/// In both modes the entire view occupies a fixed 64pt at the
/// bottom of the screen (56pt painted button row + 8pt outer
/// strip), so the buttons themselves sit at the same screen-y
/// across all tabs and pushed detail screens — the bar doesn't
/// appear to jump when the user moves between Home and Library /
/// Me / a detail. What changes between modes is *what gets painted
/// in the 8pt outer strip below the buttons*: transparent on Home
/// (the floating-island gap — map shows through; home indicator
/// sits over map), opaque `secondaryBackground` on every other
/// surface (the bar continues down through the home-indicator strip
/// as one continuous surface).
struct AtlasTabBar: View {
    @Binding var selected: AtlasTab

    /// When `true` (non-Home tabs + every pushed detail screen) the
    /// bar drops its horizontal inset and bottom corner radius so
    /// it spans the full screen width as a flat strip, and the 8pt
    /// outer strip below the buttons is painted opaquely. When
    /// `false` (Home root only) the bar keeps the AllTrails-style
    /// floating-island look that PR #60 dialed in.
    var extendsToScreenEdges: Bool = false
    /// Square top corners — the rectangular mini-player stacks flush
    /// on top, so the tab bar's top edge must be square to meet it
    /// seamlessly.
    var topCornerRadius: CGFloat = 0

    /// Same horizontal inset the BottomSheet uses (8pt) on Home so the
    /// tab bar columns align with the drawer's edges; zero on non-Home
    /// tabs so the bar spans the full screen width.
    private var horizontalInset: CGFloat {
        extendsToScreenEdges ? 0 : 8
    }
    private var bottomCornerRadius: CGFloat {
        extendsToScreenEdges ? 0 : AtlasSpacing.phoneScreenRadius
    }

    var body: some View {
        VStack(spacing: 0) {
            // Button row — identical layout in both modes (same
            // inner padding, same background, same intrinsic
            // height) so the buttons sit at the same screen-y
            // regardless of geometry.
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

            // 8pt strip below the painted button row. Transparent
            // on Home (the floating-island look — map shows through;
            // home indicator sits over map). Opaque on every other
            // surface (continuous bar background — the home
            // indicator pill sits over the bar's secondaryBackground
            // like a standard iOS tab bar). Height is the SAME in
            // both modes so the buttons stay at the same screen-y.
            Group {
                if extendsToScreenEdges {
                    Rectangle()
                        .fill(AtlasColors.secondaryBackground)
                } else {
                    Color.clear
                }
            }
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

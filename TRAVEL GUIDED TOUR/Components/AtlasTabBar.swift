import SwiftUI

/// Custom floating tab bar — replaces the system `TabView` chrome
/// so we can match the home-screen drawer's width, inset, and shape
/// exactly. Uses `.thickMaterial` for an almost-opaque backdrop so
/// the buttons stay legible regardless of what the map is showing
/// behind it.
///
/// Shape:
///   - Top corners: square — the rectangular mini-player stacks flush above
///   - Bottom corners: phone-screen radius on Home; square on every
///     other surface, where the bar reads as a flat strip flush to
///     the screen edges
///
/// In both modes the button row sits at the same screen-y position
/// (8pt outer gap below the painted bar) so the bar doesn't appear
/// to jump up or down when the user switches tabs or pushes a
/// detail screen. The only thing that changes between modes is what
/// gets painted in the 8pt outer gap + home-indicator strip below
/// the buttons: transparent (map shows through) on Home,
/// `secondaryBackground` on everywhere else.
struct AtlasTabBar: View {
    @Binding var selected: AtlasTab

    /// When `true` (non-Home tabs and every pushed detail screen)
    /// the bar drops its horizontal inset and bottom corner radius
    /// so it spans the full screen width as a flat strip, and its
    /// background extends down through the 8pt outer gap *and* the
    /// home-indicator safe-area inset as one continuous surface.
    /// When `false` (Home root only) the bar keeps the
    /// AllTrails-style floating-island look that PR #60 dialed in:
    /// inset, rounded bottom corners, transparent gap below.
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
    /// Height of the painted area below the tab bar's button row.
    /// Always at least 8pt (the outer gap that keeps the buttons
    /// anchored at the same screen-y across modes); on non-Home
    /// the home-indicator safe-area inset is added on top so the
    /// tab bar background bleeds through the device's bottom strip.
    private var bottomExtensionHeight: CGFloat {
        extendsToScreenEdges ? (8 + safeAreaBottomInset) : 8
    }
    /// Mirrors `AtlasBottomModule.bottomSafeAreaInset` — kept here as
    /// a tiny duplicate so this component has no dependency on the
    /// Player feature module beyond the shared spacing tokens.
    private var safeAreaBottomInset: CGFloat {
        #if canImport(UIKit)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: { $0.isKeyWindow })?
            .safeAreaInsets.bottom ?? 0
        #else
        0
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            // Button row. Identical layout in both modes — same
            // inner padding, same height — so the buttons themselves
            // sit at the same screen-y regardless of geometry.
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

            // Outer gap below the button row. Transparent on Home
            // (the floating-island look — map shows behind through
            // the 8pt gap); opaque on every other surface, where
            // the tab bar background continues down through the
            // home-indicator strip as one continuous surface.
            Group {
                if extendsToScreenEdges {
                    Rectangle()
                        .fill(AtlasColors.secondaryBackground)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: bottomExtensionHeight)
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

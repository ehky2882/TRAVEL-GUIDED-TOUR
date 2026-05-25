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

    /// When `true` (non-Home tabs) the bar drops its horizontal inset
    /// and bottom corner radius and extends flush to the screen edges;
    /// the tab bar's background also extends through the bottom
    /// safe-area inset (home-indicator strip), with the button column
    /// padded up to sit above it. When `false` (Home) the bar keeps
    /// the AllTrails-style floating-island look that PR #60 dialed in.
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
    /// In floating mode the outer bottom padding (8pt) lifts the
    /// island above the device bottom. In full-edge mode the
    /// background runs all the way down to the screen edge, so the
    /// button column instead gets an inner bottom padding equal to
    /// the home-indicator safe-area inset — buttons clear the
    /// indicator while the background fills the edge.
    private var outerBottomPadding: CGFloat {
        extendsToScreenEdges ? 0 : 8
    }
    private var innerBottomPadding: CGFloat {
        extendsToScreenEdges ? safeAreaBottomInset : 0
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
        HStack(spacing: 0) {
            ForEach(AtlasTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.vertical, AtlasSpacing.sm)
        .padding(.bottom, innerBottomPadding)
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
        .padding(.bottom, outerBottomPadding)
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

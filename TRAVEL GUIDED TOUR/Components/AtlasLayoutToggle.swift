import SwiftUI

/// How a set of tours is presented — a row per tour, or an Instagram-style
/// grid of their photographs.
///
/// `String`-backed so a surface can persist the reader's choice in
/// `@AppStorage`.
///
/// ⚠️ **Each surface keeps its OWN storage key.** A maker page holds dozens of
/// tours and a place page holds two or three, so "I want to see this one as a
/// grid" is a judgement about that page, not a global preference. Sharing one
/// key would make flipping a 29-tour maker feed to grid silently reshape every
/// two-tour place page as well.
enum AtlasListLayout: String {
    case list, grid
}

/// The two-glyph control that switches between them.
///
/// The maker page has had this since PR #413/#414; the place page asked for it
/// (owner, 2026-08-25: *"I want ability to view as grid in 'places pages'"*).
/// It lives here rather than being copied because a copy is exactly the shape
/// this repo keeps paying for: `StopPin` and `ClusterPin` were byte-identical
/// private views until one became 14pt while the other stayed 16, and
/// `AtlasChromeButton` exists because three pages had separately grown the
/// same button. A private view a second screen visibly needs is a duplicate
/// that has not diverged yet.
struct AtlasLayoutToggle: View {
    @Binding var selection: AtlasListLayout

    var body: some View {
        HStack(spacing: AtlasSpacing.sm) {
            icon("list.bullet", target: .list)
            icon("square.grid.3x3", target: .grid)
        }
    }

    private func icon(_ systemName: String, target: AtlasListLayout) -> some View {
        Button { selection = target } label: {
            Image(systemName: systemName)
                .font(AtlasTypography.caption)
                .foregroundStyle(selection == target ? AtlasColors.primaryText : AtlasColors.tertiaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(target == .grid ? "Grid view" : "List view")
    }
}

/// Geometry for the square photo grid both the maker page and the place page
/// draw, so the two cannot disagree about tile size or gutter.
enum AtlasTourGrid {
    /// Three across, like the maker feed the owner reviewed on device.
    static let columnCount = 3
    /// A hairline gutter — the photographs, not the gaps, are the surface.
    static let spacing: CGFloat = 2

    static var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    /// Tile side for a measured container width. Derived rather than fixed so
    /// tiles stay square on every device size.
    static func side(forContentWidth width: CGFloat) -> CGFloat {
        max(0, (width - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount))
    }
}

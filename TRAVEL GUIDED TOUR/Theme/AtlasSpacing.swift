import Foundation
import SwiftUI

enum AtlasSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let heroHeight: CGFloat = 320
    static let cardCornerRadius: CGFloat = 12
    static let chipCornerRadius: CGFloat = 20
    /// Used for the home-page floating-island shape so the drawer +
    /// tab bar look like they "follow" the device's bottom curve.
    /// Sized a touch larger than the iPhone bezel radius so the
    /// island reads as generously rounded rather than tracing the
    /// screen edge exactly.
    static let phoneScreenRadius: CGFloat = 56
    /// Shared control height for the home-screen search bar and the
    /// category filter chips below it, so the two rows visually line
    /// up. Sized to clear Apple's 44pt HIG minimum tappable target
    /// while staying compact enough to leave the map readable.
    static let searchBarHeight: CGFloat = 46
}

// MARK: - Bottom module geometry

/// Visual treatment of the mini-player + tab bar stack at the
/// screen bottom.
///
/// `.floatingIsland` is the AllTrails-style look — phone-radius
/// rounded corners, an 8pt outer gap to the device edge, transparent
/// home-indicator strip so the map shows behind. Used ONLY on the
/// Home tab's root screen.
///
/// `.fullEdge` is the flat-strip look used everywhere else: tab bar
/// spans the full screen width with square outer corners, and its
/// background extends down through the home-indicator safe area as
/// one continuous surface. Every non-Home tab uses it, and every
/// pushed detail screen (TourDetailView / MakerView / SearchView /
/// ManageDownloadsView) also uses it — even when reached from the
/// Home tab — so the module reads the same way once the user moves
/// past the map.
///
/// In both modes the mini-player + tab-bar BUTTONS sit at the same
/// vertical position on screen; only what's painted below them
/// changes. Anchoring the buttons makes the bar look glued in place
/// across tabs and pushes instead of "jumping" up when moving to
/// Library / Me / a detail screen.
enum AtlasModuleGeometry: Equatable {
    case floatingIsland
    case fullEdge
}

/// Preference that lets the currently-visible content surface
/// declare which geometry it wants for the bottom module.
/// `ContentView` reads the resolved value via `.onPreferenceChange`
/// and threads it into `MiniPlayerBar` and `AtlasTabBar`.
///
/// Reduce picks the latest (deepest / topmost) value so a pushed
/// detail screen's `.fullEdge` overrides its host tab's preference
/// while it's on screen, and reverts when the user pops back.
///
/// Default is `.fullEdge` — the safer choice. Tab roots that want
/// the floating island (Home) opt in explicitly; everything else
/// either declares `.fullEdge` or inherits it.
struct AtlasModuleGeometryKey: PreferenceKey {
    static let defaultValue: AtlasModuleGeometry = .fullEdge
    static func reduce(
        value: inout AtlasModuleGeometry,
        nextValue: () -> AtlasModuleGeometry
    ) {
        value = nextValue()
    }
}

extension View {
    /// Declare which bottom-module geometry this surface wants.
    /// Apply at the root of each tab view (`HomeView` →
    /// `.floatingIsland`; `LibraryView` / `SettingsView` →
    /// `.fullEdge`) and at the root of each pushed detail screen
    /// (always `.fullEdge`). The deepest declaration wins, so a
    /// pushed detail's preference overrides its host tab's.
    func atlasModuleGeometry(_ geometry: AtlasModuleGeometry) -> some View {
        preference(key: AtlasModuleGeometryKey.self, value: geometry)
    }
}

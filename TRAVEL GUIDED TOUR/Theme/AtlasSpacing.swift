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

/// Propagates "the active tab is Home" down the view tree so pushed
/// children (TourDetailView, MakerView, ManageDownloadsView) can size
/// their bottom safe-area inset to match the floating-island vs.
/// full-edge mini-player + tab bar geometry. Defaults to `true` so
/// previews and isolated screens render with the home-style island
/// geometry.
private struct AtlasIsHomeTabKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var atlasIsHomeTab: Bool {
        get { self[AtlasIsHomeTabKey.self] }
        set { self[AtlasIsHomeTabKey.self] = newValue }
    }
}

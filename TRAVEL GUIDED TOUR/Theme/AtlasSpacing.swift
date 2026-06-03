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
    /// up. Sized to match Apple's 44pt HIG minimum tappable target
    /// exactly — and the diameter of the floating map control
    /// buttons over the same surface — so all interactive elements
    /// on the home map carry the same vertical footprint.
    static let searchBarHeight: CGFloat = 44
    /// Combined height of the home screen's search bar + chip row
    /// block — its top padding plus both rows plus the inter-row
    /// spacing. Does NOT include the device's top safe-area inset.
    /// The drawer's `.large` detent reserves this much (plus the
    /// safe-area inset) at the top so the search bar + chips stay
    /// visible when the drawer is fully expanded.
    static let searchAndChipsBlockHeight: CGFloat = sm + searchBarHeight + sm + searchBarHeight
}

// MARK: - Bottom module geometry

/// Visual treatment of the mini-player + tab bar stack at the
/// screen bottom.
///
/// `.floatingIsland` is the AllTrails-style look — phone-radius
/// rounded corners on the tab bar, an 8pt outer gap to the device
/// edge, transparent home-indicator strip so the map shows behind.
/// Used ONLY at the Home tab's root.
///
/// `.fullEdge` is the flat-strip look used everywhere else: tab bar
/// spans the full screen width with square outer corners, and the
/// 8pt strip below the buttons is filled opaquely so the bar reads
/// as one continuous surface flush against the screen bottom. Every
/// non-Home tab uses it, and every pushed detail screen
/// (TourDetailView / MakerView / SearchView / ManageDownloadsView)
/// also uses it — even when reached from the Home tab — so the
/// module reads the same way once the user moves past the map.
///
/// In both modes the mini-player + tab bar BUTTONS sit at the same
/// vertical position on screen: 8pt of opaque painted area below
/// the button row in both modes, then either an 8pt transparent
/// outer gap (Home) or an 8pt opaque continuation (everywhere
/// else). The painted button row's painted area covers most of the
/// home-indicator safe area in both modes; the 8pt strip below
/// covers the rest of it on non-Home. Anchoring the buttons this
/// way keeps the bar visually glued in place across tabs and
/// pushes instead of jumping up when moving to Library / Me / a
/// detail screen.
enum AtlasModuleGeometry: Equatable {
    case floatingIsland
    case fullEdge
}

// MARK: - Atlas navigation state

/// Tracks how many "detail" screens are currently pushed on top of
/// any tab's navigation stack. `ContentView` reads
/// `isShowingDetail` and uses it (together with the active tab) to
/// decide the bottom module's geometry: floating island when on
/// Home root with nothing pushed, full-edge in every other case
/// (non-Home tabs, OR Home with a pushed detail).
///
/// Replaces an earlier preference-key approach that proved
/// unreliable in practice — the preference value sometimes stuck
/// at `.fullEdge` after popping back from a detail, leaving Home
/// rendering in the wrong geometry. Push/pop counting via the
/// pushed view's own `.onAppear` / `.onDisappear` is deterministic:
/// the value only changes when SwiftUI actually attaches /
/// detaches the pushed view.
///
/// Pushed-style screens (`TourDetailView`, `MakerView`,
/// `ManageDownloadsView`, `SearchView`) call `push()` on appear
/// and `pop()` on disappear. Tab roots (`HomeView`, `LibraryView`,
/// `SettingsView`) do nothing — they're not "detail" screens.
@Observable
final class AtlasNavigationState {
    /// Stack-depth counter. `> 0` means at least one detail screen
    /// is currently on top of some tab's nav stack and the bottom
    /// module should be full-edge regardless of which tab is
    /// active.
    private(set) var pushedDepth: Int = 0

    var isShowingDetail: Bool { pushedDepth > 0 }

    func push() {
        pushedDepth += 1
    }

    func pop() {
        // Guard against unbalanced pops — onDisappear can fire
        // without a matching onAppear in some SwiftUI lifecycle
        // edge cases. Clamping keeps the counter sane.
        pushedDepth = max(0, pushedDepth - 1)
    }
}

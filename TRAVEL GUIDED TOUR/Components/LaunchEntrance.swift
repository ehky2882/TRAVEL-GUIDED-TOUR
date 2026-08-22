import SwiftUI

/// Applies a piece of the launch entrance to whatever it wraps.
///
/// 🔴 THIS EXISTS FOR PERFORMANCE, and it is the single biggest thing standing
/// between the launch and a smooth one.
///
/// `handOffProgress` changes ~60 times a second while the entrance plays. Any
/// view whose **body** reads it is re-evaluated on every one of those ticks —
/// and `ContentView`'s body is the entire app (tab content, the drawer, the
/// fallback bars) while `HomeView`'s is the map, its clustering and the rails.
/// Re-running either at 60Hz starves the render server, and the tell is that
/// the animations stop tracking their own clock: opacity ramps arrive on time
/// while the geometry crawls a second or more behind. Reported from a device as
/// *"the performance/animation feels very lagg-y."*
///
/// So the reads live HERE, in a leaf that wraps content its parent has already
/// built. This view re-evaluates 60 times a second; the app does not.
///
/// ⚠️ Do not "simplify" this by reading `LaunchState` in the parent and passing
/// a Double in. That puts the read back in the parent's body and undoes the
/// whole thing.
struct LaunchEntrance<Content: View>: View {
    /// Which part of the entrance this is, and therefore which edge it comes
    /// from. Both land on the frame the drawer finishes opening — owner
    /// decision 2026-08-22: *"search bar should come in from the top. filter
    /// capsules should still come in from right."*
    enum Part {
        /// Drops in from above the screen.
        case searchBar
        /// Slides in from the right.
        case chips
    }

    let part: Part
    /// How far off-screen the content starts — a screen width for the chips,
    /// enough to clear the top edge for the search bar.
    let travel: CGFloat
    @ViewBuilder var content: Content

    @Environment(LaunchState.self) private var launchState: LaunchState?

    var body: some View {
        content
            .opacity(progress)
            .offset(
                x: part == .chips ? (1 - progress) * travel : 0,
                y: part == .searchBar ? -(1 - progress) * travel : 0
            )
    }

    private var progress: Double {
        guard let launchState, launchState.isCovering else { return 1 }
        return LaunchBloom.chromeProgress(handOff: launchState.handOffProgress)
    }
}

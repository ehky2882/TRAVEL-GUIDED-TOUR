import SwiftUI

/// The **expand** control that floats over an inline map preview: takes you to
/// the Home map, framed on whatever the page is about.
///
/// Owner ask, 2026-08-30. Four surfaces show a map inside a page — tour detail,
/// a place, a creator, a list — and every one of them is a *preview*: you can
/// pan it, but you cannot browse on from it, because it only ever holds that
/// page's own pins. This is the door back to the one map that holds everything.
///
/// 🔴 **One component, used by all four, deliberately.** This app has paid
/// three times for a map idiom copied per surface — `StopPin` and `ClusterPin`
/// drifted to 14pt against 16pt before `MapPins` was extracted, and the
/// swallowed-tap placecard stack was two copies before `TourSetMap` was.
/// A fifth map surface should call this, not grow a fifth copy.
///
/// 🔴 **TOP-trailing, and the bottom corner is a bug this already shipped once.**
/// These maps sit inside a scrolling page, and the mini-player + tab bar render
/// in a window *above* that page — so anything drawn low in the map is behind
/// them. On the creator page the header (avatar, bio, follower counts) pushes
/// the square map down far enough that **its bottom third is under the bar at
/// the page's default scroll position**, which put the control somewhere no
/// finger could reach it. Owner, 2026-08-30: *"dozent page map expansion
/// doesnt seem to work."*
///
/// The top corner is visible the moment any of the map is, which is the state
/// every one of these pages opens in. The mirrored failure — scrolled far
/// enough that the map's top passes under the nav chrome — costs nothing,
/// because by then the map is mostly off screen anyway.
///
/// ⚠️ Same family as the `UIPageControl` trap in #571: a control that renders,
/// sits in the accessibility tree, and is hit-tested by something else.
/// **Verify a new map control by tapping it at the page's RESTING scroll
/// position, not after scrolling it into a convenient place.**
struct MapExpandButton: View {
    let action: () -> Void

    var body: some View {
        MapControlButton(
            systemImage: "arrow.up.left.and.arrow.down.right",
            action: action
        )
        .padding(AtlasSpacing.sm)
        .accessibilityLabel("Expand map")
        .accessibilityHint("Opens the full map here, so you can browse what else is nearby.")
    }
}

extension View {
    /// Float a `MapExpandButton` over this map.
    ///
    /// - Parameter isVisible: pass false where there is nothing to expand to —
    ///   a creator with no published tours yet, or a host that never wired
    ///   `MapExpander` — or where something else is using this corner, which
    ///   for `TourSetMap` means a placecard stack (those stack *upwards* from a
    ///   pin sitting low in the frame, so they land here). **Hidden rather than disabled**, because a control that
    ///   visibly does nothing is worse than one that is absent (the rule the
    ///   wizard's footer already follows); and hidden rather than left inert,
    ///   because an inert control is the invisible-defect class this codebase
    ///   keeps rediscovering.
    func atlasMapExpandControl(
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        overlay(alignment: .topTrailing) {
            if isVisible {
                MapExpandButton(action: action)
            }
        }
    }
}

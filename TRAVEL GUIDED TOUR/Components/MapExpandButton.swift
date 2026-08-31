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
/// Bottom-trailing to match the Home map's own control stack, and because the
/// placecards these maps raise travel *upwards* from a pin sitting low in the
/// frame — a top-trailing button would sit where the top card lands.
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
    ///   `MapExpander`. **Hidden rather than disabled**, because a control that
    ///   visibly does nothing is worse than one that is absent (the rule the
    ///   wizard's footer already follows); and hidden rather than left inert,
    ///   because an inert control is the invisible-defect class this codebase
    ///   keeps rediscovering.
    func atlasMapExpandControl(
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        overlay(alignment: .bottomTrailing) {
            if isVisible {
                MapExpandButton(action: action)
            }
        }
    }
}

//
//  CoachMarkAnchor.swift
//  TRAVEL GUIDED TOUR
//
//  `.coachMarkAnchor(.search)` — tells the navigation tour where a control is.
//

import SwiftUI

extension View {
    /// Report this view's on-screen frame to the coach-mark tour.
    ///
    /// A no-op when no `CoachMarkCenter` is in the environment (previews,
    /// tests, and any host that never builds one), so it is safe to leave on.
    ///
    /// - Parameter forgetsOnDisappear: clear the frame when the view leaves.
    ///   Right for a view that is genuinely torn down and rebuilt (the
    ///   drawer), which reports afresh when it returns. 🔴 WRONG for Home's
    ///   always-mounted chrome — the search bar, the filter row, the bar: a
    ///   push over Home (Search, a tour) fires their `onDisappear` AFTER the
    ///   pop has re-reported the frame, and since nothing has moved,
    ///   `onGeometryChange` never reports again. Every guide then lost its
    ///   spotlight for the rest of the session (owner on 183: "search bar is
    ///   not highlighted", "filters are not highlighted", "the bar isn't").
    func coachMarkAnchor(_ mark: CoachMark, forgetsOnDisappear: Bool = true) -> some View {
        modifier(CoachMarkAnchorModifier(mark: mark, forgetsOnDisappear: forgetsOnDisappear))
    }
}

extension View {
    /// Report one filter chip's frame, so the filters stop can demonstrate
    /// stacking on the real chips.
    func coachMarkChip(_ group: FilterGroup) -> some View {
        modifier(CoachMarkChipModifier(group: group))
    }
}

private struct CoachMarkChipModifier: ViewModifier {
    let group: FilterGroup
    @Environment(CoachMarkCenter.self) private var center: CoachMarkCenter?

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            center?.setChipFrame(group, frame)
        }
    }
}

private struct CoachMarkAnchorModifier: ViewModifier {
    let mark: CoachMark
    let forgetsOnDisappear: Bool
    @Environment(CoachMarkCenter.self) private var center: CoachMarkCenter?

    func body(content: Content) -> some View {
        content
            // `.global` is the window's own space. Both windows fill the same
            // scene from the same origin, so this frame lines up with the
            // overlay drawn in the bottom-module window above.
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                center?.setAnchor(mark, frame)
            }
            // 🔴 Clear on the way out. The drawer and the Home chrome can be
            // torn down (another tab, a detail layer), and a stale rect would
            // cut a spotlight over whatever now sits there.
            .onDisappear { if forgetsOnDisappear { center?.clearAnchor(mark) } }
    }
}

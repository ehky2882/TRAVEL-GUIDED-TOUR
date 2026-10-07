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
    func coachMarkAnchor(_ mark: CoachMark) -> some View {
        modifier(CoachMarkAnchorModifier(mark: mark))
    }
}

private struct CoachMarkAnchorModifier: ViewModifier {
    let mark: CoachMark
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
            .onDisappear { center?.clearAnchor(mark) }
    }
}

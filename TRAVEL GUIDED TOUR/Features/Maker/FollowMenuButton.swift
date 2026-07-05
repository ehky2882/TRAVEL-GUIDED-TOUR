import SwiftUI

/// A Follow / Following / Requested item for a `…` overflow menu (tour detail,
/// player, maker page). Renders nothing when signed out (following needs an
/// account) — so callers can drop it in unconditionally. Loads the current
/// relationship when the menu opens and toggles on tap.
struct FollowMenuButton: View {
    let makerId: UUID

    @Environment(FollowService.self) private var followService: FollowService?
    @Environment(AuthService.self) private var authService: AuthService?
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?
    @State private var state: FollowState = .empty
    @State private var busy = false

    var body: some View {
        if authService?.isSignedIn == true, let followService {
            Button {
                toggle(followService)
            } label: {
                Label(label, systemImage: icon)
            }
            .disabled(busy)
            .task(id: makerId) { state = await followService.state(for: makerId) }
        }
    }

    private var label: String {
        if state.isFollowing { return "Unfollow creator" }
        if state.isPending { return "Cancel request" }
        return "Follow creator"
    }

    private var icon: String {
        (state.isFollowing || state.isPending) ? "person.badge.minus" : "person.badge.plus"
    }

    private func toggle(_ service: FollowService) {
        AtlasHaptics.selection()
        busy = true
        Task {
            defer { busy = false }
            do {
                if state.isFollowing || state.isPending {
                    try await service.unfollow(makerId)
                } else {
                    try await service.follow(makerId)
                }
                state = await service.state(for: makerId)
            } catch {
                // Leave state as-is; a transient failure shouldn't lie.
                toastCenter?.show("Couldn't update follow. Check your connection.")
            }
        }
    }
}

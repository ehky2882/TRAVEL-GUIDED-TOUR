import SwiftUI

/// Compact strip shown above the mini-player while a Group Listen session is
/// active — participant count + role, with a Leave button. Rendered in the
/// bottom-module window (above every modal) so it's always visible during a
/// session. Hidden when no session is active.
struct GroupBanner: View {
    @Environment(GroupListenCoordinator.self) private var coordinator: GroupListenCoordinator?

    var body: some View {
        if let coordinator, coordinator.isActive {
            HStack(spacing: AtlasSpacing.sm) {
                Image(systemName: iconName(coordinator))
                    .font(.system(size: 14))
                    .foregroundStyle(AtlasColors.background)

                Text(label(coordinator))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.background)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: AtlasSpacing.sm)

                Button {
                    coordinator.leave()
                } label: {
                    Text("Leave")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.background)
                        .padding(.horizontal, AtlasSpacing.sm)
                        .padding(.vertical, 4)
                        .overlay(Capsule().stroke(AtlasColors.background.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Leave group")
            }
            .padding(.horizontal, AtlasSpacing.md)
            .padding(.vertical, AtlasSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(isAlarm(coordinator) ? Color.red.opacity(0.85) : AtlasColors.mapPin)
            .clipShape(Capsule())
            .padding(.horizontal, AtlasSpacing.md)
            .accessibilityElement(children: .combine)
        }
    }

    private func label(_ c: GroupListenCoordinator) -> String {
        if c.leaderLost { return "Leader left — tap Leave to exit" }
        if case .failed = c.connectionStatus {
            return "Can't find nearby devices — check Local Network in Settings"
        }
        let count = c.participantCount
        // No peer yet: say we're still trying, not "just you", so an empty room
        // reads as in-progress rather than done.
        if case .searching = c.connectionStatus, count == 1 {
            return c.isLeader ? "Leading · waiting for people to join…" : "Connecting to the leader…"
        }
        let people = count == 1 ? "just you" : "\(count) listening"
        if c.isLeader { return "Leading · \(people)" }
        return "Following \(c.leaderName ?? "leader") · \(people)"
    }

    /// Red (attention) styling for a lost leader or a discovery failure.
    private func isAlarm(_ c: GroupListenCoordinator) -> Bool {
        if c.leaderLost { return true }
        if case .failed = c.connectionStatus { return true }
        return false
    }

    private func iconName(_ c: GroupListenCoordinator) -> String {
        if c.leaderLost { return "person.fill.questionmark" }
        if case .failed = c.connectionStatus { return "wifi.exclamationmark" }
        return "person.2.wave.2.fill"
    }
}

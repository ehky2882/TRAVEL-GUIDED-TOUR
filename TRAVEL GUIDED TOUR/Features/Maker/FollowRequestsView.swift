import SwiftUI

/// Private-account follow requests (batch D3). Reached from the own-profile
/// header when there are pending requests. Each row is a requester's profile
/// with Approve (→ status `accepted`) / Decline (→ delete the edge) actions.
///
/// `makerId` is the owner's own maker id — the followee side of every edge here
/// (one login = one maker). `onChange` lets the profile refresh its pending
/// count as requests are actioned.
struct FollowRequestsView: View {
    let makerId: UUID
    var onChange: () -> Void = {}

    @Environment(AtlasNavigationState.self) private var navState
    @Environment(FollowService.self) private var followService: FollowService?
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?

    @State private var requests: [FollowRequest] = []
    @State private var loaded = false
    @State private var busyIds: Set<UUID> = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !loaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, AtlasSpacing.xl)
                } else if requests.isEmpty {
                    Text("No pending requests.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, AtlasSpacing.xl)
                } else {
                    ForEach(requests) { req in
                        row(req)
                        if req.id != requests.last?.id { Divider() }
                    }
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
        }
        .background(AtlasColors.secondaryBackground)
        .navigationTitle("Follow Requests")
        .inlineNavigationBarTitle()
        // Render the nav-bar title ourselves so it carries the caption
        // token in ALL CAPS. `.navigationTitle` is kept for the
        // accessibility label; the principal item replaces it visually.
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("FOLLOW REQUESTS")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        .onAppear { navState.push() }
        .onDisappear { navState.pop() }
        .task {
            guard let followService else { loaded = true; return }
            requests = await followService.pendingRequests()
            loaded = true
        }
    }

    private func row(_ req: FollowRequest) -> some View {
        HStack(spacing: AtlasSpacing.md) {
            MakerAvatarView(maker: req.follower, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(req.follower.displayName)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !req.follower.bio.isEmpty {
                    Text(req.follower.bio)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: AtlasSpacing.sm)

            HStack(spacing: AtlasSpacing.md) {
                Button { act(req, approve: true) } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.green)
                        .frame(width: 36, height: 36)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Approve")

                Button { act(req, approve: false) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Decline")
            }
            .disabled(busyIds.contains(req.id))
        }
        .padding(.vertical, AtlasSpacing.sm)
    }

    private func act(_ req: FollowRequest, approve: Bool) {
        guard let followService else { return }
        busyIds.insert(req.id)
        Task {
            defer { busyIds.remove(req.id) }
            do {
                if approve {
                    try await followService.approveRequest(follower: req.followerUserId, on: makerId)
                } else {
                    try await followService.declineRequest(follower: req.followerUserId, on: makerId)
                }
                requests.removeAll { $0.id == req.id }
                if approve { AtlasHaptics.success() } else { AtlasHaptics.selection() }
                // Keep the Me-tab notification badge in sync as the pending
                // set shrinks (makerId is the owner's own maker here).
                await followService.refreshOwnPendingRequests(ownMakerId: makerId)
                onChange()
            } catch {
                // Leave the row in place; a transient failure shouldn't lie.
                toastCenter?.show("Couldn't \(approve ? "approve" : "decline") the request. Try again.")
            }
        }
    }
}

import SwiftUI

/// The list behind a follower / following count tap on a maker page (batch D2).
///
/// Reuses the shared `MakerAvatarView` + a compact row; tapping a row pushes
/// that maker's page onto the current nav stack. The list comes from the
/// `list_followers` / `list_following` SECURITY DEFINER RPCs, which enforce the
/// visibility rule server-side (a private account's list is only returned to its
/// owner) — so it returns empty when hidden.
///
/// On the **own** followers list (`showsPendingRequests`), any pending follow
/// requests render as a section at the very top with Approve / Decline actions
/// — the requests screen is folded in here, so there's never a separate page.
struct FollowListView: View {
    enum Kind {
        case followers, following

        var title: String { self == .followers ? "Followers" : "Following" }

        var emptyMessage: String {
            self == .followers ? "No followers yet." : "Not following anyone yet."
        }
    }

    let makerId: UUID
    let kind: Kind
    /// When true (own followers list), pending follow requests are loaded and
    /// shown as an actionable section pinned above the followers.
    var showsPendingRequests: Bool = false
    /// Called whenever a request is approved/declined so the presenting profile
    /// can refresh its header counts + the Me-tab badge.
    var onRequestsChange: () -> Void = {}

    @Environment(DataService.self) private var dataService
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(FollowService.self) private var followService: FollowService?
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?

    @State private var makers: [Maker] = []
    @State private var requests: [FollowRequest] = []
    @State private var busyIds: Set<UUID> = []
    @State private var loaded = false

    private var showsRequestSection: Bool {
        showsPendingRequests && kind == .followers && !requests.isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !loaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, AtlasSpacing.xl)
                } else {
                    // Pending requests — pinned to the top of the own followers list.
                    if showsRequestSection {
                        sectionHeader("PENDING REQUESTS")
                        ForEach(requests) { req in
                            requestRow(req)
                            if req.id != requests.last?.id { Divider() }
                        }
                        if !makers.isEmpty {
                            sectionHeader("FOLLOWERS")
                                .padding(.top, AtlasSpacing.lg)
                        }
                    }

                    if makers.isEmpty && !showsRequestSection {
                        Text(kind.emptyMessage)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, AtlasSpacing.xl)
                    } else {
                        ForEach(makers) { maker in
                            // Push that maker's page (default `.publicMaker`) onto
                            // the current stack — back returns to this list.
                            NavigationLink { MakerView(maker: maker) } label: { row(maker) }
                                .buttonStyle(.plain)

                            if maker.id != makers.last?.id { Divider() }
                        }
                    }
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
        }
        // Same fixed shade as the rest of the maker/detail surfaces.
        .background(AtlasColors.secondaryBackground)
        .navigationTitle(kind.title)
        .inlineNavigationBarTitle()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        // A pushed detail — full-edge module while it's up.
        .onAppear { navState.push() }
        .onDisappear { navState.pop() }
        .task(id: makerId) {
            guard let followService else { loaded = true; return }
            makers = kind == .followers
                ? await followService.followers(of: makerId)
                : await followService.following(of: makerId)
            if showsPendingRequests && kind == .followers {
                requests = await followService.pendingRequests()
            }
            loaded = true
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
            .padding(.bottom, AtlasSpacing.xs)
    }

    private func row(_ maker: Maker) -> some View {
        HStack(spacing: AtlasSpacing.md) {
            MakerAvatarView(maker: maker, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(maker.displayName)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(subtitle(maker))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
        .contentShape(Rectangle())
    }

    /// A pending-request row: requester profile + green ✓ / red ✗ actions.
    private func requestRow(_ req: FollowRequest) -> some View {
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
                if approve {
                    AtlasHaptics.success()
                    // The approved requester is now a follower — surface them
                    // immediately at the top of the followers below.
                    if !makers.contains(where: { $0.id == req.follower.id }) {
                        makers.insert(req.follower, at: 0)
                    }
                } else {
                    AtlasHaptics.selection()
                }
                await followService.refreshOwnPendingRequests(ownMakerId: makerId)
                onRequestsChange()
            } catch {
                // Leave the row in place; a transient failure shouldn't lie.
                toastCenter?.show("Couldn't \(approve ? "approve" : "decline") the request. Try again.")
            }
        }
    }

    /// Prefer the maker's bio (more informative for user-followers with no
    /// published tours); fall back to their published-tour count.
    private func subtitle(_ maker: Maker) -> String {
        if !maker.bio.isEmpty { return maker.bio }
        let n = dataService.tours(by: maker).count
        return n == 1 ? "1 tour" : "\(n) tours"
    }
}

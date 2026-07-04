import SwiftUI

/// The list behind a follower / following count tap on a maker page (batch D2).
///
/// Reuses the shared `MakerAvatarView` + a compact row; tapping a row pushes
/// that maker's page onto the current nav stack. The list comes from the
/// `list_followers` / `list_following` SECURITY DEFINER RPCs, which enforce the
/// visibility rule server-side (a private account's list is only returned to its
/// owner) — so it returns empty when hidden.
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

    @Environment(DataService.self) private var dataService
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(FollowService.self) private var followService: FollowService?

    @State private var makers: [Maker] = []
    @State private var loaded = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !loaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, AtlasSpacing.xl)
                } else if makers.isEmpty {
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
            loaded = true
        }
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

    /// Prefer the maker's bio (more informative for user-followers with no
    /// published tours); fall back to their published-tour count.
    private func subtitle(_ maker: Maker) -> String {
        if !maker.bio.isEmpty { return maker.bio }
        let n = dataService.tours(by: maker).count
        return n == 1 ? "1 tour" : "\(n) tours"
    }
}

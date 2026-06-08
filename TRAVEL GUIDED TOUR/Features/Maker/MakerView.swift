import SwiftUI

/// Maker page — spec § Key screens #5 / roadmap M-maker.
///
/// Replaces the stub that landed in M-tour-detail. Shows the maker's
/// avatar, display name, bio, optional website link, and the full
/// list of their tours. Each tour row pushes `TourDetailView` onto
/// the navigation stack.
struct MakerView: View {
    let maker: Maker

    @Environment(DataService.self) private var dataService
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(SavedMakersStore.self) private var savedMakersStore
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(\.openURL) private var openURL

    private let avatarSize: CGFloat = 96

    private var isSaved: Bool { savedMakersStore.isSaved(maker.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                header
                    .frame(maxWidth: .infinity)
                    .padding(.top, AtlasSpacing.lg)

                if let urlString = maker.websiteURL,
                   let url = URL(string: urlString) {
                    websiteLink(url: url)
                }

                toursSection
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.bottom, AtlasSpacing.xl)
        }
        // `secondaryBackground` (a fixed RGB, not the level-sensitive
        // `.systemBackground`) so the page reads as the SAME shade as
        // the bottom module + the tour-detail body regardless of how
        // MakerView is reached. Via the tour-detail sheet (elevated
        // userInterfaceLevel) `.systemBackground` resolved to #1C1C1E
        // and happened to match; pushed from Search (base level) it
        // fell to pure black and mismatched the module. Matches the
        // token TourDetailView / ManageDownloadsView already use.
        .background(AtlasColors.secondaryBackground)
        // No visible nav-bar title (owner direction): the masthead
        // already shows the maker name. Empty string keeps the bar +
        // back button while dropping the centered title text. The
        // `navigationTitle` accessibility identity moves to the
        // masthead name in the body.
        .navigationTitle("")
        .inlineNavigationBarTitle()
        // Trailing nav-bar controls mirror the tour-detail sheet:
        // a bookmark (toggles this maker as saved) + a `…` overflow
        // menu (Save · Share · Follow [disabled] · Report).
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    savedMakersStore.toggleSaved(maker.id)
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(isSaved
                    ? "Remove \(maker.displayName) from saved"
                    : "Save \(maker.displayName)")

                overflowMenu
            }
        }
        // Reserve room at the bottom for the mini-player + tab bar
        // stack so the last tour row is reachable above the module.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        // Mark this surface as a pushed detail screen so the bottom
        // module switches to full-edge while it's on top — even
        // when reached from Home.
        .onAppear { navState.push() }
        .onDisappear { navState.pop() }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: AtlasSpacing.md) {
            avatar

            Text(maker.displayName)
                .font(AtlasTypography.caption)
                .textCase(.uppercase)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.center)

            Text(maker.bio)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var avatar: some View {
        Group {
            if let emoji = maker.avatarEmoji, !emoji.isEmpty {
                // Single-glyph brand mark (e.g. the Atlas Studio NYC
                // red apple) rendered inside a muted circular plate.
                // MiniPlayerBar.authorIcon uses the same resolution
                // order at a smaller frame.
                ZStack {
                    Circle().fill(AtlasColors.placeholderWarm)
                    Text(emoji)
                        .font(.system(size: avatarSize * 0.6))
                }
            } else if let urlString = maker.avatarURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Circle().fill(AtlasColors.placeholderWarm)
                    }
                }
            } else {
                // No remote avatar or emoji — fall back to the bundled
                // Atlas Studio brand asset.
                Image("AtlasStudioAvatar")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
    }

    private func websiteLink(url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "link")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.secondaryText)
                Text(url.host ?? url.absoluteString)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.horizontal, AtlasSpacing.md)
            .padding(.vertical, AtlasSpacing.sm)
            .background(AtlasColors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                    .stroke(AtlasColors.secondaryText.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
        }
        .accessibilityLabel("Open \(maker.displayName) website")
    }

    private var toursSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HStack {
                Text("Tours")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
                Spacer()
                Text(tourCountText)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.top, AtlasSpacing.md)

            if makerTours.isEmpty {
                Text("No tours yet.")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .padding(.vertical, AtlasSpacing.md)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(makerTours) { tour in
                        // Opening a tour depends on how MakerView itself
                        // was reached:
                        //  • Top-level push (Library / Search / Home) —
                        //    no detail layer is up, so present the tour
                        //    via the shared `tourPresenter` slide-up
                        //    layer (same as every other tour list). The
                        //    sheet's X close — wired to
                        //    `tourPresenter.dismiss()` — then works.
                        //  • Already inside a detail layer (reached via a
                        //    tour sheet → "Go to creator") — push the
                        //    next tour within that layer's own nav stack
                        //    so we don't double-stack a second layer; the
                        //    X still dismisses the whole layer.
                        Group {
                            if tourPresenter.presentedTour == nil {
                                Button {
                                    tourPresenter.present(tour)
                                } label: {
                                    tourRow(tour)
                                }
                            } else {
                                NavigationLink {
                                    TourDetailView(tour: tour)
                                } label: {
                                    tourRow(tour)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        if tour.id != makerTours.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func tourRow(_ tour: Tour) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            // Square corners per the app-wide "all images square
            // corners" rule (owner, 2026-06-04) — matches the Search
            // result rows.
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 64,
                cornerRadius: 0,
                category: tour.primaryCategory
            )
            .frame(width: 64)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                // Title: BODY, all-caps, single line, tail-truncated —
                // mirrors the Search result rows / Player stop titles.
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Subtitle: duration only (category dropped), one line.
                Text(formattedDuration(tour.totalDurationSeconds))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
    }

    // MARK: - Nav-bar overflow

    /// Top-trailing `…` overflow menu — mirrors the tour-detail sheet's
    /// menu, minus the tour-only items (Download / Go to creator).
    /// Order: Save · Share · Follow [disabled] · Report a concern.
    private var overflowMenu: some View {
        Menu {
            Button {
                savedMakersStore.toggleSaved(maker.id)
            } label: {
                Label(
                    isSaved ? "Remove from saved" : "Save",
                    systemImage: isSaved ? "bookmark.fill" : "bookmark"
                )
            }

            ShareLink(item: shareText, subject: Text(maker.displayName)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Section {
                // Disabled in V1 — the follow graph (a social feature)
                // isn't built. Saving (above) is a separate local
                // bookmark, not a follow. Kept visible to surface the
                // upcoming feature, matching the tour-detail menu.
                Button {} label: {
                    Label("Follow creator", systemImage: "person.badge.plus")
                }
                .disabled(true)
            }

            Section {
                Button(role: .destructive) {
                    if let url = reportURL { openURL(url) }
                } label: {
                    Label("Report a concern", systemImage: "exclamationmark.bubble")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .accessibilityLabel("More options")
        }
    }

    private var shareText: String {
        "\(maker.displayName) on Atlas"
    }

    /// `mailto:` URL for Report a concern. Owner is sole recipient for
    /// V1 (no moderation backend yet); maker name + id let the owner
    /// trace the report. Mirrors `TourDetailView.reportURL`.
    private var reportURL: URL? {
        let to = "eyung@tishman.com"
        let subject = "Atlas — report concern: \(maker.displayName)"
        let body = """
            Maker: \(maker.displayName)
            Maker ID: \(maker.id.uuidString)

            Concern:

            """
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    // MARK: - Derived

    private var makerTours: [Tour] {
        dataService.tours(by: maker)
    }

    private var tourCountText: String {
        let count = makerTours.count
        return count == 1 ? "1 tour" : "\(count) tours"
    }

    private func formattedDuration(_ seconds: Int) -> String {
        AtlasFormatters.duration(seconds: seconds)
    }
}

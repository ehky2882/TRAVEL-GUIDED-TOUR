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

    private let avatarSize: CGFloat = 96

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
        .background(AtlasColors.background)
        .navigationTitle(maker.displayName)
        .inlineNavigationBarTitle()
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
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.center)

            Text(maker.bio)
                .font(AtlasTypography.body)
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
                        NavigationLink {
                            TourDetailView(tour: tour)
                        } label: {
                            tourRow(tour)
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
        HStack(alignment: .top, spacing: AtlasSpacing.md) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 64,
                cornerRadius: 8,
                category: tour.primaryCategory
            )
            .frame(width: 64)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: AtlasSpacing.xs) {
                    Text(tour.primaryCategory.displayName)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                    Text("•")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                    Text(formattedDuration(tour.totalDurationSeconds))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
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

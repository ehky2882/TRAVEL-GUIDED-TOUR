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

    /// Avatar placeholder is a solid grey circle for V1 — matches the
    /// HeroImageView placeholder treatment so layout reads cleanly
    /// before real images land in M-launch-content.
    private var avatar: some View {
        Circle()
            .fill(Color(white: 0.78))
            .frame(width: avatarSize, height: avatarSize)
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
        let minutes = seconds / 60
        if minutes == 0 { return "\(seconds)s" }
        return "\(minutes) min"
    }
}

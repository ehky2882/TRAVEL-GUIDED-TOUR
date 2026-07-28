import SwiftUI

/// The rows that render a list as a list.
///
/// Lifted out of `LibraryView` on 2026-07-27, when the maker page gained
/// a LISTS tab and needed the same rows. They are shared rather than
/// copied on purpose: the Thyssen incident earlier the same week was a
/// case of two things that were supposed to match quietly diverging, and
/// two hand-maintained copies of a row is the same shape of bug in the
/// UI layer.
///
/// **Liked is styled identically to a named list** and that is
/// deliberate — it's the default list, not a special case, so it reads
/// as one of them (owner direction, PR #447). The only thing that marks
/// it out is its placeholder glyph when empty.
///
/// All three rows are dumb: they take what they draw and hold no
/// services, so either screen can use them without inheriting the
/// other's environment.

// MARK: - Shared layout

/// The 56pt cover + title + subtitle + chevron shape every list row
/// wears. Matches the maker row's metrics so Library's two sections read
/// as one system.
private struct ListRowLayout<Cover: View>: View {
    let title: String
    let subtitle: String?
    var showsChevron: Bool = true
    @ViewBuilder let cover: () -> Cover

    var body: some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            cover()
                .frame(width: 56, height: 56)
                .clipped()

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(title)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let subtitle {
                    Text(subtitle)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }
}

/// Corner badge marking a list only its owner can see.
///
/// Sits on the cover rather than beside the title so it reads at a glance down
/// a column of rows, the same job the `WALK` pill does on the maker feed. Only
/// ever appears on your own lists — on someone else's page a hidden list simply
/// isn't there, so there is nothing to mark.
private struct OnlyMeBadge: View {
    var body: some View {
        Image(systemName: "key.fill")
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(AtlasColors.background)
            .padding(4)
            .background(Circle().fill(AtlasColors.accent))
            // Lifts it off a busy photo, same as the grid's status badges.
            .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
            .padding(3)
            .accessibilityLabel("Only you can see this list")
    }
}

/// Square placeholder used when a list has no cover to show yet.
private struct ListCoverPlaceholder: View {
    let systemImage: String
    var tint: Color = AtlasColors.secondaryText

    var body: some View {
        ZStack {
            Rectangle()
                .fill(AtlasColors.placeholderWarm.opacity(0.35))
            Image(systemName: systemImage)
                .font(AtlasTypography.body)
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Cover resolution

/// Where a list's thumbnail comes from: an explicit cover if the owner
/// set one, else the hero of the first tour in the list.
///
/// `TourList.firstTourId` is filled in by the same embed
/// `TourListService.loadMyLists()` already runs, so this costs **no**
/// extra network call. Don't replace it with a per-list query.
enum TourListCover {
    static func imageName(for list: TourList, in dataService: DataService) -> String? {
        if let explicit = list.coverImageURL, !explicit.isEmpty { return explicit }
        guard let firstTourId = list.firstTourId else { return nil }
        return dataService.tour(by: firstTourId)?.heroImageURL
    }

    static func category(for list: TourList, in dataService: DataService) -> TourCategory? {
        guard let firstTourId = list.firstTourId else { return nil }
        return dataService.tour(by: firstTourId)?.primaryCategory
    }
}

// MARK: - Rows

/// A named list — cover, title, tour count.
///
/// Named `NamedListRow`, not `TourListRow`: `TourListService` already has a
/// file-private `TourListRow` for the Supabase row it decodes.
struct NamedListRow: View {
    let list: TourList
    let coverImageName: String?
    let coverCategory: TourCategory?

    var body: some View {
        ListRowLayout(title: list.title, subtitle: countText) {
            Group {
                if let coverImageName {
                    HeroImageView(
                        imageName: coverImageName,
                        height: 56,
                        cornerRadius: 0,
                        category: coverCategory
                    )
                } else {
                    ListCoverPlaceholder(systemImage: "map")
                }
            }
            // No condition on "is this mine" — a list you can see that is
            // marked private is by definition your own.
            .overlay(alignment: .topTrailing) {
                if !list.isPublic { OnlyMeBadge() }
            }
        }
    }

    private var countText: String {
        list.itemCount == 1 ? "1 tour" : "\(list.itemCount) tours"
    }
}

/// Liked — the default list. Styled exactly like a named list; its cover
/// is the most recently liked tour's hero, and the bookmark glyph stands
/// in while it's empty.
struct LikedListRow: View {
    let count: Int
    let coverImageName: String?
    let coverCategory: TourCategory?

    var body: some View {
        ListRowLayout(title: "Liked", subtitle: count == 1 ? "1 tour" : "\(count) tours") {
            if let coverImageName {
                HeroImageView(
                    imageName: coverImageName,
                    height: 56,
                    cornerRadius: 0,
                    category: coverCategory
                )
            } else {
                ListCoverPlaceholder(systemImage: "bookmark.fill", tint: AtlasColors.mapPin)
            }
        }
    }
}

/// Create a new list. An action rather than a list, so it carries no
/// chevron and sits at the top of the section rather than among them
/// (owner direction).
struct NewListRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ListRowLayout(title: "New list", subtitle: nil, showsChevron: false) {
                ListCoverPlaceholder(systemImage: "plus", tint: AtlasColors.mapPin)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New list")
    }
}

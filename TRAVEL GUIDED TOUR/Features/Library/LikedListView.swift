import SwiftUI

/// The **Liked** list's contents.
///
/// Liked is the default list — where a tour goes when the user doesn't pick
/// somewhere (`SaveState`). It opens from a row in Library's Lists section
/// exactly like any named list, so there's one place lists live and Liked isn't
/// a special case sitting off to the side.
///
/// It differs from a named list only in what it *can't* do: it isn't ordered by
/// the user (newest-saved first), can't be renamed, made public, or deleted,
/// and carries no per-tour notes. Backed by `LibraryStore`, so unlike named
/// lists it works signed out.
///
/// **Liked is permanent by construction** (owner question 2026-07-27, "should
/// this folder be locked and never be able to be deleted?" — yes). It is not a
/// `journeys` row with the controls hidden; there is no row to delete and no
/// editor to open. Every profile has one whether or not anything is in it. Keep
/// it that way: the moment Liked becomes a real list, an un-save stops being the
/// only way to remove a save, which is the rule the whole save design rests on.
struct LikedListView: View {
    /// Someone else's saved tour ids, newest first, fetched by whoever pushed
    /// this screen. `nil` means "show mine" — the ordinary case, read straight
    /// from the on-device store so it works signed out.
    var tourIds: [UUID]? = nil
    /// Whose Liked this is, for the title. `nil` for your own.
    var ownerName: String? = nil

    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(TourPresenter.self) private var tourPresenter

    private var tours: [Tour] {
        if let tourIds {
            return tourIds.compactMap { dataService.tour(by: $0) }
        }
        return libraryStore.savedEntries.compactMap { dataService.tour(by: $0.tourId) }
    }

    /// Someone else's empty Liked shouldn't tell *you* to go save something.
    private var isSomeoneElses: Bool { tourIds != nil }

    var body: some View {
        ScrollView {
            if tours.isEmpty {
                Group {
                    if isSomeoneElses {
                        EmptyStateLayout(
                            icon: "bookmark",
                            title: "Nothing saved yet",
                            message: ownerName.map { "\($0) hasn't saved any tours." }
                                ?? "This creator hasn't saved any tours."
                        )
                    } else {
                        LikedEmptyState()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AtlasSpacing.xl)
                .padding(.horizontal, AtlasSpacing.lg)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(tours) { tour in
                        Button {
                            tourPresenter.present(tour)
                        } label: {
                            LibraryTourRow(tour: tour)
                        }
                        .buttonStyle(.plain)

                        if tour.id != tours.last?.id {
                            Divider().padding(.horizontal, AtlasSpacing.lg)
                        }
                    }
                }
                .padding(.vertical, AtlasSpacing.md)
            }
        }
        .background(AtlasColors.secondaryBackground)
        .navigationTitle("Liked")
        .inlineNavigationBarTitle()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
    }
}

/// Shown when nothing has been saved yet — in the Liked list and in Library.
struct LikedEmptyState: View {
    var body: some View {
        EmptyStateLayout(
            icon: "bookmark",
            title: "Nothing saved yet",
            message: "Tap the bookmark on any tour and it lands here in Liked. Sign in to sort your tours into your own lists."
        )
    }
}

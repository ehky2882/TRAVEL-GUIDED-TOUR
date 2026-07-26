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
struct LikedListView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(TourPresenter.self) private var tourPresenter

    private var tours: [Tour] {
        libraryStore.savedEntries.compactMap { dataService.tour(by: $0.tourId) }
    }

    var body: some View {
        ScrollView {
            if tours.isEmpty {
                LikedEmptyState()
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

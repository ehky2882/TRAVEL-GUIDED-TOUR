import SwiftUI

/// Shown in Library when nothing has been saved yet.
///
/// The Liked *screen* is `TourListDetailView` with a `.liked` target (owner
/// direction 2026-08-20 — Liked is a list like any other, so it is the same
/// screen), and that screen writes its own empty copy. This one stays because
/// Library's Saved tab shows the same message without opening anything.
struct LikedEmptyState: View {
    var body: some View {
        EmptyStateLayout(
            icon: "bookmark",
            title: "Nothing saved yet",
            message: "Tap the bookmark on any tour and it lands here in Liked. Sign in to sort your tours into your own lists."
        )
    }
}

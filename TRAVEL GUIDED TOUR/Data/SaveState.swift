import Foundation

/// The single rule for what "saved" means, and what a bookmark tap does.
///
/// Saving is **one** concept: a tour is saved when it belongs to at least one
/// list. There is no separate saved flag living alongside list membership —
/// that split (bookmark → `LibraryStore.savedAt`, "Save to…" →
/// `journey_items`) is exactly what this replaces. It mirrors the maker
/// consolidation in PR #398, where saving a maker was deleted outright rather
/// than kept beside Follow.
///
/// **Liked is the default list** — where a tour lands when the user doesn't
/// pick somewhere. Filing a tour into a named list puts it *there*, not also in
/// Liked. Liked stays backed by `LibraryStore` (local, already synced by
/// `SyncService`) so it keeps working signed out; named lists live in Supabase
/// via `TourListService` and need an account, which was already true.
///
/// The rules live here as pure functions so every bookmark surface — the home
/// cards, tour detail, the player — shares one implementation, and so they can
/// be unit-tested without standing up either store.
enum SaveState {

    /// What tapping the bookmark control should do, given where a tour lives.
    enum TapAction: Equatable {
        /// Not saved anywhere → drop it into the default list.
        case addToLiked
        /// Already saved → show everywhere it lives and let the user file it or
        /// untick it. **Never un-saves on the spot** (owner direction, matching
        /// Spotify's "Add to playlist"): a second tap is far more likely to mean
        /// "put this somewhere" than "throw it away", and silently discarding a
        /// save is the one outcome the user can't easily undo.
        case chooseLists
    }

    /// A tour is saved if it is in at least one list, Liked included.
    ///
    /// Signed out, `listIds` is always empty and this reduces to Liked alone —
    /// exactly today's behaviour for an anonymous user.
    static func isSaved(isLiked: Bool, listIds: Set<UUID>) -> Bool {
        isLiked || !listIds.isEmpty
    }

    /// How many lists a tour belongs to, Liked included.
    static func placeCount(isLiked: Bool, listIds: Set<UUID>) -> Int {
        (isLiked ? 1 : 0) + listIds.count
    }

    /// The rule:
    /// - saved nowhere → save it to Liked, no questions asked
    /// - saved anywhere → open the sheet
    ///
    /// The tap is **add-only**; removing is always a deliberate choice in the
    /// sheet. That holds even when the tour is in exactly one list, where
    /// "just undo it" is tempting — the tap is the same gesture that filed it,
    /// and making it also destroy the save is how people lose things.
    static func tapAction(isLiked: Bool, listIds: Set<UUID>) -> TapAction {
        isSaved(isLiked: isLiked, listIds: listIds) ? .chooseLists : .addToLiked
    }
}

import Foundation

/// The single rule for what "saved" means, and what a bookmark tap does.
///
/// Saving is **one** concept: a tour is saved when it belongs to at least one
/// list. There is no separate saved flag living alongside list membership —
/// that split (bookmark → `LibraryStore.savedAt`, "Add to a Journey" →
/// `journey_items`) is exactly what this replaces. It mirrors the maker
/// consolidation in PR #398, where saving a maker was deleted outright rather
/// than kept beside Follow.
///
/// **Liked is the default list** — where a tour lands when the user doesn't
/// pick somewhere. Filing a tour into a named list puts it *there*, not also in
/// Liked. Liked stays backed by `LibraryStore` (local, already synced by
/// `SyncService`) so it keeps working signed out; named lists live in Supabase
/// via `JourneyService` and need an account, which was already true.
///
/// The rules live here as pure functions so every bookmark surface — the home
/// cards, tour detail, the player — shares one implementation, and so they can
/// be unit-tested without standing up either store.
enum SaveState {

    /// What tapping the bookmark control should do, given where a tour lives.
    enum TapAction: Equatable {
        /// Not saved anywhere → drop it into the default list.
        case addToLiked
        /// Saved in Liked and nowhere else → un-save it.
        case removeFromLiked
        /// Saved in exactly one named list → take it out of that list.
        case removeFromList(UUID)
        /// In more than one place → show the user everywhere it lives and let
        /// them untick what they want it out of.
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

    /// The 0 / 1 / many rule:
    /// - in nothing → save it to Liked
    /// - in exactly one place → remove it from that place, so a second tap
    ///   always undoes the first
    /// - in several → don't guess which one the user meant; open the sheet
    static func tapAction(isLiked: Bool, listIds: Set<UUID>) -> TapAction {
        switch placeCount(isLiked: isLiked, listIds: listIds) {
        case 0:
            return .addToLiked
        case 1:
            if isLiked { return .removeFromLiked }
            // placeCount == 1 && !isLiked ⇒ exactly one list id.
            guard let only = listIds.first else { return .addToLiked }
            return .removeFromList(only)
        default:
            return .chooseLists
        }
    }
}

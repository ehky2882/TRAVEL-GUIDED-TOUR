import Foundation

/// What a list screen is showing.
///
/// Liked and a named list are **the same screen** (owner direction 2026-08-20:
/// *"the default 'liked' playlist should look like every other playlist. (why
/// would it be any different?)"*). They differ only in where the tours come
/// from and in which controls can act — the `MakerView.mode` pattern, for the
/// same reason: two views drifting apart is exactly how the list page ended up
/// with a system nav bar while everything around it had a chrome row.
enum TourListTarget: Identifiable, Hashable {
    /// A row in `journeys` — cloud-backed, ordered by its owner, renameable.
    /// `preloaded` is metadata the presenting screen already had, so the title
    /// draws on the first frame.
    case list(id: UUID, preloaded: TourList?)

    /// The default list. Backed by `LibraryStore`, so it works signed out.
    /// `tourIds` non-nil means someone *else's* Liked, fetched by whoever
    /// opened this screen; nil means read the on-device store.
    case liked(ownerName: String?, tourIds: [UUID]?)

    /// Your own Liked — the ordinary case, read from the on-device store.
    static let ownLiked = TourListTarget.liked(ownerName: nil, tourIds: nil)

    /// Stable across a re-present of the same screen, which is what the
    /// presenting `.onChange` keys on. Deliberately ignores `preloaded` and
    /// `tourIds`: re-presenting the same list with fresher metadata is the
    /// same screen, not a new one.
    var id: String {
        switch self {
        case .list(let id, _):     return "list:\(id.uuidString)"
        case .liked(let owner, _): return "liked:\(owner ?? "")"
        }
    }
}

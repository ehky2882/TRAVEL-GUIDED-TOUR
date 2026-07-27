import Foundation

/// A user-curated, ordered collection of whole tours — the "playlist" of
/// Dozent (design: `docs/lists-design.md`). Any signed-in account can make
/// one ("anyone can be a Dozent"). A TourList never splits a multi-stop tour —
/// its items reference whole `Tour`s by id.
///
/// Backed by the Supabase `lists` table (`backend/journeys.sql`). Tour
/// *content* is not duplicated: `items` hold only tour ids + the curator's
/// per-tour note; the app resolves them against the loaded catalog
/// (`DataService`) for display.
struct TourList: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var coverImageURL: String?
    var isPublic: Bool
    /// Number of tours in the TourList — filled by the list query's embedded
    /// count so a row can show "3 tours" without loading every item.
    var itemCount: Int
    /// The tour id of the TourList's first item (lowest `position`), derived by
    /// the list query's embedded items. Lets a row/detail resolve a cover
    /// thumbnail from that tour's hero without a per-row network call. `nil` for
    /// an empty TourList. Defaults to `nil` so hand-built `TourList(...)` sites
    /// (e.g. `createList`) still compile.
    var firstTourId: UUID? = nil
}

/// One ordered entry in a TourList — a reference to a whole tour plus an
/// optional curator note. `id` is the tour id (a tour appears at most once
/// per TourList, enforced by the table's composite primary key).
struct TourListItem: Identifiable, Hashable, Codable {
    let tourId: UUID
    var position: Int
    var note: String?
    var id: UUID { tourId }
}

import Foundation

/// A user-curated, ordered collection of whole tours — the "playlist" of
/// Dozent (design: `docs/journeys-design.md`). Any signed-in account can make
/// one ("anyone can be a Dozent"). A Journey never splits a multi-stop tour —
/// its items reference whole `Tour`s by id.
///
/// Backed by the Supabase `journeys` table (`backend/journeys.sql`). Tour
/// *content* is not duplicated: `items` hold only tour ids + the curator's
/// per-tour note; the app resolves them against the loaded catalog
/// (`DataService`) for display.
struct Journey: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var coverImageURL: String?
    var isPublic: Bool
    /// Number of tours in the Journey — filled by the list query's embedded
    /// count so a row can show "3 tours" without loading every item.
    var itemCount: Int
}

/// One ordered entry in a Journey — a reference to a whole tour plus an
/// optional curator note. `id` is the tour id (a tour appears at most once
/// per Journey, enforced by the table's composite primary key).
struct JourneyItem: Identifiable, Hashable, Codable {
    let tourId: UUID
    var position: Int
    var note: String?
    var id: UUID { tourId }
}

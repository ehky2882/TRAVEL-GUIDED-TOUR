import Foundation
import Observation
import Supabase

/// Cloud CRUD for the signed-in user's **Journeys** — user-curated, ordered
/// collections of whole tours (design: `docs/journeys-design.md`; schema:
/// `backend/journeys.sql`). Mirrors the shape of `MakerTourService`: a
/// `@MainActor @Observable` service over supabase-swift, holding the user's
/// own journeys in memory and writing through on every mutation.
///
/// RLS (already in `journeys.sql`): a user reads/writes only their own
/// journeys (public ones are world-readable, but this service is scoped to the
/// signed-in owner via `owner_user_id`). Every write requires an authenticated
/// session — anonymous users see an empty list.
@MainActor
@Observable
final class JourneyService {
    /// The signed-in user's own journeys, newest-updated first.
    private(set) var myJourneys: [Journey] = []

    private let auth: AuthService
    private let client: SupabaseClient

    init(auth: AuthService, client: SupabaseClient = SupabaseClientProvider.shared) {
        self.auth = auth
        self.client = client
    }

    private var uid: String? { auth.user?.id.uuidString.lowercased() }

    /// Clear the in-memory list (e.g. on sign-out).
    func clear() { myJourneys = [] }

    // MARK: - Load

    /// Load the current user's journeys with each one's tour count. A failure
    /// leaves the current list unchanged; signed-out clears it.
    func loadMyJourneys() async {
        guard let uid else { myJourneys = []; return }
        do {
            let rows: [JourneyRow] = try await client
                .from("journeys")
                .select("id, title, description, cover_image_url, is_public, journey_items(count)")
                .eq("owner_user_id", value: uid)
                .order("updated_at", ascending: false)
                .execute()
                .value
            myJourneys = rows.map(\.asJourney)
        } catch {
            // Keep whatever we have; the screen still renders.
        }
    }

    /// The ordered items (tour ids + notes) of one journey.
    func items(of journeyId: UUID) async -> [JourneyItem] {
        do {
            let rows: [JourneyItemRow] = try await client
                .from("journey_items")
                .select("tour_id, position, note")
                .eq("journey_id", value: journeyId.uuidString.lowercased())
                .order("position", ascending: true)
                .execute()
                .value
            return rows.map(\.asItem)
        } catch {
            return []
        }
    }

    /// The set of *my* journey ids that already contain `tourId` — drives the
    /// checkmarks in the "Add to a Journey" sheet. Filtered to the user's own
    /// journeys (RLS also returns public ones containing the tour).
    func journeyIdsContaining(tourId: UUID) async -> Set<UUID> {
        let mine = Set(myJourneys.map(\.id))
        do {
            let rows: [MembershipRow] = try await client
                .from("journey_items")
                .select("journey_id")
                .eq("tour_id", value: tourId.uuidString.lowercased())
                .execute()
                .value
            return Set(rows.compactMap { UUID(uuidString: $0.journeyId) }).intersection(mine)
        } catch {
            return []
        }
    }

    // MARK: - Mutations

    /// Create a new journey owned by the current user. Generates the id
    /// client-side (like `MakerTourService`) and prepends it to `myJourneys`.
    @discardableResult
    func createJourney(title: String, description: String?, isPublic: Bool) async throws -> Journey {
        guard let uid else { throw JourneyError.notSignedIn }
        let id = UUID()
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let row = NewJourneyRow(
            id: id.uuidString.lowercased(),
            ownerUserId: uid,
            title: clean,
            description: (desc?.isEmpty ?? true) ? nil : desc,
            isPublic: isPublic
        )
        try await client.from("journeys").insert(row, returning: .minimal).execute()
        let journey = Journey(
            id: id,
            title: clean,
            description: (desc?.isEmpty ?? true) ? nil : desc,
            coverImageURL: nil,
            isPublic: isPublic,
            itemCount: 0
        )
        myJourneys.insert(journey, at: 0)
        return journey
    }

    /// Add a tour to the end of a journey. Positions are the current item
    /// count (0-based, append). Uses upsert so re-adding the same tour is a
    /// no-op rather than a primary-key error. Bumps the local `itemCount`.
    func addTour(_ tourId: UUID, to journeyId: UUID, note: String? = nil) async throws {
        let existing = await items(of: journeyId)
        // Already present → nothing to do (keep its position + note).
        guard !existing.contains(where: { $0.tourId == tourId }) else { return }
        let position = (existing.map(\.position).max() ?? -1) + 1
        let cleanNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let row = NewJourneyItemRow(
            journeyId: journeyId.uuidString.lowercased(),
            tourId: tourId.uuidString.lowercased(),
            position: position,
            note: (cleanNote?.isEmpty ?? true) ? nil : cleanNote
        )
        try await client.from("journey_items").insert(row, returning: .minimal).execute()
        await touch(journeyId)
        adjustCount(journeyId, by: 1)
    }

    /// Remove a tour from a journey. Leaves the remaining positions as-is
    /// (gaps are harmless — ordering is by `position`, not contiguity).
    func removeTour(_ tourId: UUID, from journeyId: UUID) async throws {
        try await client
            .from("journey_items")
            .delete()
            .eq("journey_id", value: journeyId.uuidString.lowercased())
            .eq("tour_id", value: tourId.uuidString.lowercased())
            .execute()
        await touch(journeyId)
        adjustCount(journeyId, by: -1)
    }

    /// Delete a journey (its items cascade via the FK). Removes it from the
    /// in-memory list.
    func deleteJourney(_ journeyId: UUID) async throws {
        try await client
            .from("journeys")
            .delete()
            .eq("id", value: journeyId.uuidString.lowercased())
            .execute()
        myJourneys.removeAll { $0.id == journeyId }
    }

    // MARK: - Helpers

    /// Bump a journey's `updated_at` so it sorts to the top of the list after
    /// an edit. Best-effort — a failure doesn't block the mutation.
    private func touch(_ journeyId: UUID) async {
        try? await client
            .from("journeys")
            .update(TouchRow(updatedAt: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: journeyId.uuidString.lowercased())
            .execute()
    }

    /// Adjust the cached item count for a journey (keeps the list row's
    /// "N tours" in step without a reload).
    private func adjustCount(_ journeyId: UUID, by delta: Int) {
        guard let idx = myJourneys.firstIndex(where: { $0.id == journeyId }) else { return }
        myJourneys[idx].itemCount = max(0, myJourneys[idx].itemCount + delta)
    }

    enum JourneyError: LocalizedError {
        case notSignedIn
        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "You need to be signed in to make a Journey."
            }
        }
    }
}

// MARK: - DTOs

/// Read payload for a `journeys` row + its embedded item count.
private struct JourneyRow: Decodable {
    let id: UUID
    let title: String
    let description: String?
    let coverImageURL: String?
    let isPublic: Bool
    let journeyItems: [CountRow]

    struct CountRow: Decodable { let count: Int }

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case coverImageURL = "cover_image_url"
        case isPublic = "is_public"
        case journeyItems = "journey_items"
    }

    var asJourney: Journey {
        Journey(
            id: id,
            title: title,
            description: description,
            coverImageURL: coverImageURL,
            isPublic: isPublic,
            itemCount: journeyItems.first?.count ?? 0
        )
    }
}

/// Read payload for a `journey_items` row.
private struct JourneyItemRow: Decodable {
    let tourId: UUID
    let position: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case tourId = "tour_id"
        case position, note
    }

    var asItem: JourneyItem { JourneyItem(tourId: tourId, position: position, note: note) }
}

/// Read payload: just the journey_id (membership lookup).
private struct MembershipRow: Decodable {
    let journeyId: String
    enum CodingKeys: String, CodingKey { case journeyId = "journey_id" }
}

/// Insert payload for a new `journeys` row (snake_case columns).
private struct NewJourneyRow: Encodable {
    let id: String
    let ownerUserId: String
    let title: String
    let description: String?
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case ownerUserId = "owner_user_id"
        case isPublic = "is_public"
    }
}

/// Insert payload for a new `journey_items` row.
private struct NewJourneyItemRow: Encodable {
    let journeyId: String
    let tourId: String
    let position: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case journeyId = "journey_id"
        case tourId = "tour_id"
        case position, note
    }
}

/// Update payload: bump `updated_at`.
private struct TouchRow: Encodable {
    let updatedAt: String
    enum CodingKeys: String, CodingKey { case updatedAt = "updated_at" }
}

import Foundation
import Observation
import Supabase

/// Cloud CRUD for the signed-in user's **lists** — user-curated, ordered
/// collections of whole tours (design: `docs/lists-design.md`; schema:
/// `backend/journeys.sql`). Mirrors the shape of `MakerTourService`: a
/// `@MainActor @Observable` service over supabase-swift, holding the user's
/// own lists in memory and writing through on every mutation.
///
/// RLS (already in `journeys.sql`): a user reads/writes only their own
/// lists (public ones are world-readable, but this service is scoped to the
/// signed-in owner via `owner_user_id`). Every write requires an authenticated
/// session — anonymous users see an empty list.
@MainActor
@Observable
final class TourListService {
    /// The signed-in user's own lists, newest-updated first.
    private(set) var myLists: [TourList] = []

    /// Which tours sit in which of the user's lists — `listId → tourIds`.
    /// Built from the same embedded rows `loadMyLists()` already fetches, so
    /// it costs no extra query, and kept in step by every mutation below.
    private(set) var membership: [UUID: Set<UUID>] = [:]

    /// Every tour in *any* of the user's lists, cached as a flat set.
    ///
    /// This is read by `isSaved` on every card in every rail, so it has to be an
    /// O(1) local lookup — a per-tour query would put a network round-trip
    /// behind every bookmark glyph on screen. Recomputed only when membership
    /// changes (a load or a mutation), which is rare by comparison.
    private(set) var allListedTourIds: Set<UUID> = []

    /// Other people's lists this user has saved, newest-saved first.
    ///
    /// Kept apart from `myLists` on purpose: these are **references, not
    /// copies**. The owner still owns the list, so it can gain tours, lose
    /// them, be renamed, be hidden or be deleted out from under the saver —
    /// and it must never appear anywhere the user can edit or delete it.
    private(set) var savedLists: [TourList] = []

    /// Which lists are saved, for an O(1) check while drawing a bookmark.
    /// Held separately from `savedLists` because a list whose owner has since
    /// hidden it is still *saved* even though we can no longer render it —
    /// so the bookmark stays filled and un-saving still works.
    private(set) var savedListIds: Set<UUID> = []

    /// Whether the saves have been fetched at least once for this account.
    /// Distinguishes "no saves" from "haven't looked yet", so a list-detail
    /// screen doesn't re-query on every open just because the set is empty.
    private(set) var hasLoadedSaves = false

    private let auth: AuthService
    private let client: SupabaseClient

    /// The uid the current cache belongs to, so a different account never sees
    /// the previous one's lists (the service isn't torn down on sign-out).
    private var loadedUid: String?

    /// Last-known lists on disk, per account (stale-while-revalidate).
    ///
    /// Without this the service started **empty on every launch** and Library's
    /// Lists tab drew itself three times: Liked alone, then the named lists
    /// popping in, then a whole `SAVED LISTS` section inserting below them —
    /// the jitter. The same pattern already backs `MakerProfileService.myMaker`
    /// and `MakerTourService.myTours` (`ProfileSnapshotStore`), and
    /// `FollowService`'s counts; lists were the one kept-things surface still
    /// waiting on the network to know its own shape.
    ///
    /// Keyed by uid, so one account can never hydrate another's lists.
    private let snapshotStore = ProfileSnapshotStore<Snapshot>("lists")

    /// What survives a launch. Deliberately **not** `hasLoadedSaves`: that flag
    /// is what makes a shared-list screen fetch the save state once per launch
    /// (`TourListDetailView`), and restoring it true would let a bookmark
    /// changed on another device stay wrong until Library was opened.
    /// Internal rather than private so a test can round-trip the real type:
    /// `membership` is a dictionary keyed by `UUID`, which `JSONEncoder` writes
    /// as a flat alternating array rather than an object. If that ever stopped
    /// round-tripping, membership would come back empty and every bookmark
    /// glyph would read wrong on the first frame after launch — silently.
    struct Snapshot: Codable {
        var myLists: [TourList]
        var membership: [UUID: Set<UUID>]
        var savedLists: [TourList]
        var savedListIds: Set<UUID>
    }

    init(auth: AuthService, client: SupabaseClient = SupabaseClientProvider.shared) {
        self.auth = auth
        self.client = client
        // Synchronous, at init: `AuthService` seeds `user` from the persisted
        // session in *its* init, so the uid is already known here and the first
        // frame Library ever draws can be the final layout.
        hydrateFromSnapshot()
    }

    /// Load the cached lists for the signed-in account, if any. Silent no-op
    /// when signed out or nothing has been cached yet.
    private func hydrateFromSnapshot() {
        guard let uid, let snapshot = snapshotStore.load(uid: uid) else { return }
        myLists = snapshot.myLists
        membership = snapshot.membership
        savedLists = snapshot.savedLists
        savedListIds = snapshot.savedListIds
        rebuildAllListed()
        loadedUid = uid
    }

    /// Write the current cache to disk. Called after every load and every
    /// mutation — **a new write path needs a call too**, or the next launch
    /// renders a layout the user already changed.
    private func persistSnapshot() {
        guard let uid else { return }
        snapshotStore.save(
            Snapshot(myLists: myLists,
                     membership: membership,
                     savedLists: savedLists,
                     savedListIds: savedListIds),
            uid: uid
        )
    }

    private var uid: String? { auth.user?.id.uuidString.lowercased() }

    /// Clear all cached state (e.g. on sign-out).
    func clear() {
        // Drop the account's cached copy too: sign-out wipes synced data from
        // the device (PR #283), and a list cache left behind would outlive it.
        snapshotStore.clear(uid: loadedUid)
        myLists = []
        membership = [:]
        allListedTourIds = []
        savedLists = []
        savedListIds = []
        hasLoadedSaves = false
        loadedUid = nil
    }

    /// Drop cached state if the signed-in user changed since it was loaded.
    /// Called at the start of every load so a sign-out or account switch can't
    /// leave the previous user's lists on screen.
    func clearIfUserChanged() {
        if loadedUid != uid { clear() }
    }

    /// Rebuild the flat set after `membership` changes.
    private func rebuildAllListed() {
        allListedTourIds = membership.values.reduce(into: Set<UUID>()) { $0.formUnion($1) }
    }

    /// The user's lists that currently contain `tourId`, read from the cache.
    ///
    /// Synchronous on purpose: the membership sheet and the bookmark controls
    /// both need this while deciding what to draw, and the data already arrived
    /// with `loadMyLists()`.
    func listsContaining(tourId: UUID) -> Set<UUID> {
        Set(membership.filter { $0.value.contains(tourId) }.keys)
    }

    // MARK: - Load

    /// Load the current user's lists with each one's tour count. A failure
    /// leaves the current list unchanged; signed-out clears it.
    func loadMyLists() async {
        clearIfUserChanged()
        guard let uid else { clear(); return }
        do {
            let rows: [TourListRow] = try await client
                .from("journeys")
                .select("id, title, description, cover_image_url, is_public, journey_items(tour_id, position)")
                .eq("owner_user_id", value: uid)
                .order("updated_at", ascending: false)
                .execute()
                .value
            myLists = rows.map(\.asTourList)
            // The embed already carries every item's tour id, so membership
            // comes free with the list query — no second round-trip.
            membership = Dictionary(
                uniqueKeysWithValues: rows.map { ($0.id, Set($0.itemRefs.map(\.tourId))) }
            )
            rebuildAllListed()
            loadedUid = uid
            persistSnapshot()
        } catch {
            // Keep whatever we have; the screen still renders.
        }
    }

    /// Another person's visible lists, for their maker page.
    ///
    /// Takes an **auth account id**, not a maker id — `journeys.owner_user_id`
    /// is an `auth.users` id. `Maker.userId` carries it; nil (every Atlas
    /// studio) means there is nobody to ask about, so return nothing.
    ///
    /// Deliberately **not** stored in `myLists`. Foreign lists are throwaway
    /// view state belonging to whichever page is open; keeping them out of the
    /// service's own-lists cache is what stops one person's lists appearing
    /// under another's name, or surviving a sign-out.
    ///
    /// `is_public` is filtered here as well as by RLS. The server is the real
    /// gate; this just avoids relying on it for a rule the UI also states.
    func publicLists(ofUser ownerUserId: UUID) async -> [TourList] {
        do {
            let rows: [TourListRow] = try await client
                .from("journeys")
                // `owner_user_id` rides along so a list saved straight from
                // this screen already knows whose it is, and Library can name
                // the owner without waiting for its own reload.
                .select("id, title, description, cover_image_url, is_public, owner_user_id, journey_items(tour_id, position)")
                .eq("owner_user_id", value: ownerUserId.uuidString.lowercased())
                .eq("is_public", value: true)
                .order("updated_at", ascending: false)
                .execute()
                .value
            return rows.map(\.asTourList)
        } catch {
            return []
        }
    }

    /// One list plus its ordered items, by id — for a list arriving from a
    /// **share link**, where the app has no context at all.
    ///
    /// Uses the `get_journey` RPC, which has existed in `backend/journeys.sql`
    /// since the original Journeys work and had never been called. It runs
    /// SECURITY INVOKER, so RLS still decides: a link to an Only-me list
    /// returns nothing to anyone but its owner, which is exactly right.
    ///
    /// Returns nil for a list that is gone, hidden, or never existed — the
    /// three cases are indistinguishable from here on purpose, since telling
    /// a stranger which one applies would itself leak something.
    func list(byId listId: UUID) async -> (list: TourList, items: [TourListItem])? {
        do {
            let payload: SharedListPayload? = try await client
                .rpc("get_journey", params: ["p_journey": listId.uuidString.lowercased()])
                .execute()
                .value
            guard let payload else { return nil }
            return (payload.asTourList, payload.asItems)
        } catch {
            return nil
        }
    }

    // MARK: - Saving someone else's list

    /// Is this list one the user has saved? Synchronous — read while drawing.
    func isListSaved(_ listId: UUID) -> Bool { savedListIds.contains(listId) }

    /// Load the lists this user has saved from other people's profiles.
    ///
    /// One query: the saves, with each referenced list embedded (and its items,
    /// so counts and covers come free — same trick as `loadMyLists()`).
    ///
    /// **A save whose list is no longer readable is dropped from `savedLists`
    /// but kept in `savedListIds`.** The owner may have flipped it to Only me,
    /// in which case RLS returns a null embed. Deleting the save row on their
    /// behalf would be wrong — if the owner shares it again it should come
    /// back — so the row stays and simply doesn't render. A list the owner
    /// actually *deleted* takes the save row with it (`on delete cascade`), so
    /// that case cleans itself up.
    func loadSavedLists() async {
        clearIfUserChanged()
        guard let uid else { clear(); return }
        do {
            let rows: [SavedListRow] = try await client
                .from("saved_journeys")
                .select("""
                    journey_id, saved_at, \
                    journeys(id, title, description, cover_image_url, is_public, \
                    owner_user_id, journey_items(tour_id, position))
                    """)
                .eq("user_id", value: uid)
                .order("saved_at", ascending: false)
                .execute()
                .value
            savedLists = rows.compactMap { $0.journeys?.asTourList }
            // From the save rows, not the embeds — a hidden list is still
            // saved, so its bookmark must stay filled.
            savedListIds = Set(rows.map(\.journeyId))
            hasLoadedSaves = true
            loadedUid = uid
            persistSnapshot()
        } catch {
            // Keep whatever we have; the screen still renders.
        }
    }

    /// Load just the ids, so a bookmark can render correctly on a list the user
    /// opens before Library has ever been visited. Cheap — no embed.
    func loadSavedListIds() async {
        clearIfUserChanged()
        guard let uid else { clear(); return }
        do {
            let rows: [SavedListIdRow] = try await client
                .from("saved_journeys")
                .select("journey_id")
                .eq("user_id", value: uid)
                .execute()
                .value
            savedListIds = Set(rows.map(\.journeyId))
            hasLoadedSaves = true
            loadedUid = uid
            persistSnapshot()
        } catch {
            // Keep whatever we have.
        }
    }

    /// Save someone else's list. No-op when signed out — `saved_journeys` is
    /// keyed on the account, so there is nowhere to put it.
    @discardableResult
    func saveList(_ list: TourList) async -> Bool {
        guard let uid else { return false }
        do {
            try await client
                .from("saved_journeys")
                .insert(SavedListInsert(userId: uid, journeyId: list.id.uuidString.lowercased()),
                        returning: .minimal)
                .execute()
            // Patch in place so the bookmark and Library update without a
            // reload — the same rule the membership cache follows.
            savedListIds.insert(list.id)
            if !savedLists.contains(where: { $0.id == list.id }) {
                savedLists.insert(list, at: 0)
            }
            persistSnapshot()
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    func unsaveList(_ listId: UUID) async -> Bool {
        guard let uid else { return false }
        do {
            try await client
                .from("saved_journeys")
                .delete()
                .eq("user_id", value: uid)
                .eq("journey_id", value: listId.uuidString.lowercased())
                .execute()
            savedListIds.remove(listId)
            savedLists.removeAll { $0.id == listId }
            persistSnapshot()
            return true
        } catch {
            return false
        }
    }

    /// The tours another person has saved — their Liked list, newest first.
    ///
    /// Liked is normally backed by the on-device `LibraryStore`, which is what
    /// lets saving work signed out. That store only ever holds *your* saves, so
    /// reading someone else's needs the server copy (`user_library`, kept in
    /// sync by `SyncService`) via the `liked_tour_ids` function — see
    /// `backend/public_liked.sql`.
    ///
    /// Returns empty on any failure, which renders as an empty Liked list. That
    /// is the right failure: a creator who has saved nothing and a creator we
    /// couldn't reach should both look like "nothing here", not an error.
    func likedTourIds(ofUser ownerUserId: UUID) async -> [UUID] {
        do {
            let ids: [UUID] = try await client
                .rpc("liked_tour_ids", params: ["p_user": ownerUserId.uuidString.lowercased()])
                .execute()
                .value
            return ids
        } catch {
            return []
        }
    }

    /// The ordered items (tour ids + notes) of one list.
    func items(of listId: UUID) async -> [TourListItem] {
        do {
            let rows: [TourListItemRow] = try await client
                .from("journey_items")
                .select("tour_id, position, note")
                .eq("journey_id", value: listId.uuidString.lowercased())
                .order("position", ascending: true)
                .execute()
                .value
            return rows.map(\.asItem)
        } catch {
            return []
        }
    }

    /// The set of *my* list ids that already contain `tourId` — drives the
    /// checkmarks in the "Save to…" sheet. Filtered to the user's own
    /// lists (RLS also returns public ones containing the tour).
    func listIdsContaining(tourId: UUID) async -> Set<UUID> {
        let mine = Set(myLists.map(\.id))
        do {
            let rows: [MembershipRow] = try await client
                .from("journey_items")
                .select("journey_id")
                .eq("tour_id", value: tourId.uuidString.lowercased())
                .execute()
                .value
            return Set(rows.compactMap { UUID(uuidString: $0.listId) }).intersection(mine)
        } catch {
            return []
        }
    }

    // MARK: - Mutations

    /// Create a new list owned by the current user. Generates the id
    /// client-side (like `MakerTourService`) and prepends it to `myLists`.
    @discardableResult
    func createList(title: String, description: String?, isPublic: Bool) async throws -> TourList {
        guard let uid else { throw TourListError.notSignedIn }
        let id = UUID()
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let row = NewTourListRow(
            id: id.uuidString.lowercased(),
            ownerUserId: uid,
            title: clean,
            description: (desc?.isEmpty ?? true) ? nil : desc,
            isPublic: isPublic
        )
        try await client.from("journeys").insert(row, returning: .minimal).execute()
        let journey = TourList(
            id: id,
            title: clean,
            description: (desc?.isEmpty ?? true) ? nil : desc,
            coverImageURL: nil,
            isPublic: isPublic,
            itemCount: 0
        )
        myLists.insert(journey, at: 0)
        membership[id] = []
        persistSnapshot()
        return journey
    }

    /// Add a tour to the end of a list. Positions are the current item
    /// count (0-based, append). Uses upsert so re-adding the same tour is a
    /// no-op rather than a primary-key error. Bumps the local `itemCount`.
    func addTour(_ tourId: UUID, to listId: UUID, note: String? = nil) async throws {
        let existing = await items(of: listId)
        // Already present → nothing to do (keep its position + note).
        guard !existing.contains(where: { $0.tourId == tourId }) else { return }
        let position = (existing.map(\.position).max() ?? -1) + 1
        let cleanNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let row = NewTourListItemRow(
            listId: listId.uuidString.lowercased(),
            tourId: tourId.uuidString.lowercased(),
            position: position,
            note: (cleanNote?.isEmpty ?? true) ? nil : cleanNote
        )
        try await client.from("journey_items").insert(row, returning: .minimal).execute()
        await touch(listId)
        adjustCount(listId, by: 1)
        membership[listId, default: []].insert(tourId)
        rebuildAllListed()
        persistSnapshot()
    }

    /// Remove a tour from a list. Leaves the remaining positions as-is
    /// (gaps are harmless — ordering is by `position`, not contiguity).
    func removeTour(_ tourId: UUID, from listId: UUID) async throws {
        try await client
            .from("journey_items")
            .delete()
            .eq("journey_id", value: listId.uuidString.lowercased())
            .eq("tour_id", value: tourId.uuidString.lowercased())
            .execute()
        await touch(listId)
        adjustCount(listId, by: -1)
        membership[listId]?.remove(tourId)
        rebuildAllListed()
        persistSnapshot()
    }

    /// Delete a list (its items cascade via the FK). Removes it from the
    /// in-memory list.
    func deleteList(_ listId: UUID) async throws {
        try await client
            .from("journeys")
            .delete()
            .eq("id", value: listId.uuidString.lowercased())
            .execute()
        myLists.removeAll { $0.id == listId }
        membership[listId] = nil
        rebuildAllListed()
        persistSnapshot()
    }

    /// Update a list's editable metadata (title / description / public).
    /// Updates the in-memory list in place — and moves it to the top, mirroring
    /// the server's updated-at sort — so the detail + list reflect it at once.
    func updateList(id: UUID, title: String, description: String?, isPublic: Bool) async throws {
        guard uid != nil else { throw TourListError.notSignedIn }
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDesc = (desc?.isEmpty ?? true) ? nil : desc
        let row = TourListUpdateRow(
            title: clean,
            description: cleanDesc,
            isPublic: isPublic,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await client
            .from("journeys")
            .update(row)
            .eq("id", value: id.uuidString.lowercased())
            .execute()
        if let idx = myLists.firstIndex(where: { $0.id == id }) {
            var j = myLists.remove(at: idx)
            j.title = clean
            j.description = cleanDesc
            j.isPublic = isPublic
            myLists.insert(j, at: 0)
            persistSnapshot()
        }
    }

    /// Set (or clear, with nil/empty) the curator note on one tour in a list.
    func setNote(_ note: String?, for tourId: UUID, in listId: UUID) async throws {
        let clean = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        try await client
            .from("journey_items")
            .update(NoteRow(note: (clean?.isEmpty ?? true) ? nil : clean))
            .eq("journey_id", value: listId.uuidString.lowercased())
            .eq("tour_id", value: tourId.uuidString.lowercased())
            .execute()
        await touch(listId)
    }

    /// Persist a new order for a list's tours — each item's `position` is set
    /// to its index in `orderedTourIds`. (No unique constraint on position, so a
    /// direct per-row assignment is safe.)
    func reorder(_ orderedTourIds: [UUID], in listId: UUID) async throws {
        for (index, tourId) in orderedTourIds.enumerated() {
            try await client
                .from("journey_items")
                .update(PositionRow(position: index))
                .eq("journey_id", value: listId.uuidString.lowercased())
                .eq("tour_id", value: tourId.uuidString.lowercased())
                .execute()
        }
        await touch(listId)
    }

    // MARK: - Helpers

    /// Bump a list's `updated_at` so it sorts to the top of the list after
    /// an edit. Best-effort — a failure doesn't block the mutation.
    private func touch(_ listId: UUID) async {
        try? await client
            .from("journeys")
            .update(TouchRow(updatedAt: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: listId.uuidString.lowercased())
            .execute()
    }

    /// Adjust the cached item count for a list (keeps the list row's
    /// "N tours" in step without a reload).
    private func adjustCount(_ listId: UUID, by delta: Int) {
        guard let idx = myLists.firstIndex(where: { $0.id == listId }) else { return }
        myLists[idx].itemCount = max(0, myLists[idx].itemCount + delta)
    }

    enum TourListError: LocalizedError {
        case notSignedIn
        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "You need to be signed in to make a list."
            }
        }
    }
}

// MARK: - DTOs

/// Read payload for a `lists` row + its embedded items (tour ids + order).
/// The item *count* is derived client-side from the embedded rows, and the
/// first tour (lowest `position`) drives the TourList's cover thumbnail.
private struct TourListRow: Decodable {
    let id: UUID
    let title: String
    let description: String?
    let coverImageURL: String?
    let isPublic: Bool
    let itemRefs: [ItemRef]
    /// Only selected where it matters (saved lists). Absent from the
    /// own-lists query, hence optional.
    let ownerUserId: UUID?

    /// One embedded `journey_items` row: just enough to count and to find the
    /// first tour for the cover image.
    struct ItemRef: Decodable {
        let tourId: UUID
        let position: Int
        enum CodingKeys: String, CodingKey {
            case tourId = "tour_id"
            case position
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case coverImageURL = "cover_image_url"
        case isPublic = "is_public"
        case itemRefs = "journey_items"
        case ownerUserId = "owner_user_id"
    }

    var asTourList: TourList {
        TourList(
            id: id,
            title: title,
            description: description,
            coverImageURL: coverImageURL,
            isPublic: isPublic,
            itemCount: itemRefs.count,
            firstTourId: itemRefs.min(by: { $0.position < $1.position })?.tourId,
            ownerUserId: ownerUserId
        )
    }
}

/// Read payload for a `saved_journeys` row with the list it points at embedded.
///
/// `journeys` is optional because RLS decides it separately from
/// `saved_journeys`: your save row survives the owner flipping their list to
/// Only me, but the list itself stops being readable — so the embed comes back
/// null and the row is dropped client-side. That is the correct outcome; see
/// `loadSavedLists()`.
private struct SavedListRow: Decodable {
    /// Always present — this is the save itself.
    let journeyId: UUID
    /// The list it points at, or nil if RLS won't return it any more.
    let journeys: TourListRow?

    enum CodingKeys: String, CodingKey {
        case journeyId = "journey_id"
        case journeys
    }
}

/// `get_journey` returns the list and its ordered items as one camelCase
/// object — a different shape from the table selects above, hence its own DTO.
private struct SharedListPayload: Decodable {
    let id: UUID
    let ownerUserId: UUID?
    let title: String
    let description: String?
    let coverImageURL: String?
    let isPublic: Bool
    let items: [Item]

    struct Item: Decodable {
        let tourId: UUID
        let position: Int
        let note: String?
    }

    var asItems: [TourListItem] {
        items
            .sorted { $0.position < $1.position }
            .map { TourListItem(tourId: $0.tourId, position: $0.position, note: $0.note) }
    }

    var asTourList: TourList {
        TourList(
            id: id,
            title: title,
            description: description,
            coverImageURL: coverImageURL,
            isPublic: isPublic,
            itemCount: items.count,
            firstTourId: items.min(by: { $0.position < $1.position })?.tourId,
            ownerUserId: ownerUserId
        )
    }
}

/// Just the ids, for the cheap "is this saved?" load.
private struct SavedListIdRow: Decodable {
    let journeyId: UUID
    enum CodingKeys: String, CodingKey { case journeyId = "journey_id" }
}

/// Write payload for a save. String ids because that is what PostgREST wants
/// on the wire, matching the rest of this service's writes.
private struct SavedListInsert: Encodable {
    let userId: String
    let journeyId: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case journeyId = "journey_id"
    }
}

/// Read payload for a `journey_items` row.
private struct TourListItemRow: Decodable {
    let tourId: UUID
    let position: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case tourId = "tour_id"
        case position, note
    }

    var asItem: TourListItem { TourListItem(tourId: tourId, position: position, note: note) }
}

/// Read payload: just the journey_id (membership lookup).
private struct MembershipRow: Decodable {
    let listId: String
    enum CodingKeys: String, CodingKey { case listId = "journey_id" }
}

/// Insert payload for a new `lists` row (snake_case columns).
private struct NewTourListRow: Encodable {
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
private struct NewTourListItemRow: Encodable {
    let listId: String
    let tourId: String
    let position: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case listId = "journey_id"
        case tourId = "tour_id"
        case position, note
    }
}

/// Update payload: bump `updated_at`.
private struct TouchRow: Encodable {
    let updatedAt: String
    enum CodingKeys: String, CodingKey { case updatedAt = "updated_at" }
}

/// Update payload for a list's editable metadata. Custom-encodes
/// `description` as explicit JSON `null` when nil so clearing it actually
/// clears (Swift's synthesized encoder omits nil optionals, which a PostgREST
/// update would then leave unchanged — memory `reference-supabase-upsert-null-omission`).
private struct TourListUpdateRow: Encodable {
    let title: String
    let description: String?
    let isPublic: Bool
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case title, description
        case isPublic = "is_public"
        case updatedAt = "updated_at"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)   // explicit null clears it
        try c.encode(isPublic, forKey: .isPublic)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

/// Update payload: a list item's note (explicit null clears it).
private struct NoteRow: Encodable {
    let note: String?
    enum CodingKeys: String, CodingKey { case note }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(note, forKey: .note)
    }
}

/// Update payload: a list item's position.
private struct PositionRow: Encodable {
    let position: Int
}

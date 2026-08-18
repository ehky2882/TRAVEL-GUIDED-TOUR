import Foundation
import Observation

/// The places the user has bookmarked.
///
/// **Why this is not part of `LibraryStore`.** Every member of that store is
/// keyed by a tour id — `entries: [LibraryEntry]`, `entry(for tourId:)` — and
/// its `onChange` hook has one specific meaning: *push the tour library to
/// Supabase*. Hanging a second, differently-shaped concern off it would fire
/// that hook for writes that must not be pushed, and would make `applyMerged`
/// (which replaces the whole entry list from a sign-in merge) a hazard for data
/// it knows nothing about.
///
/// **Why a place bookmark is a plain toggle, unlike a tour's.** Tapping the
/// bookmark on a tour is deliberately add-only — a second tap opens the
/// membership sheet rather than un-saving, because a tour can be filed into
/// named lists and one tap must never destroy that filing (owner decision,
/// session 74). A place has no lists to be filed into: it is saved or it is
/// not. So a toggle is unambiguous here, and the rule it appears to break does
/// not apply. **If places ever gain lists, this has to be revisited.**
///
/// Storage is `UserDefaults`, which is what lets saving work while signed out,
/// exactly as bookmarking a tour does. When the user *is* signed in,
/// `SyncService` mirrors this to the `user_saved_places` table on the same
/// terms as saved tours and recently-viewed: pull-merge-push on sign-in,
/// debounced write-through afterwards, and a local wipe on sign-out.
@Observable
final class SavedPlacesStore {
    private static let storageKey = "atlas_saved_places"

    /// Newest first — the order the Library list renders in.
    private(set) var entries: [SavedPlaceEntry] = []

    /// Fired after any user-initiated mutation persists. `SyncService` sets
    /// this to write the change through to Supabase when a user is signed in;
    /// `nil` (anonymous) means purely on-device, exactly as before.
    @ObservationIgnored var onChange: (() -> Void)?

    init() {
        load()
    }

    /// Replace the whole set from a sign-in merge and persist, **without**
    /// firing `onChange` — the sync service pushes the merged state itself, so
    /// firing here would schedule a redundant second write. Same contract as
    /// `LibraryStore.applyMerged`.
    func applyMerged(_ newEntries: [SavedPlaceEntry]) {
        entries = newEntries.sorted { $0.savedAt > $1.savedAt }
        idSet = Set(entries.map(\.placeId))
        persist()
    }

    /// Ids only, for the cheap membership test a view body can call per row.
    private var idSet: Set<UUID> = []

    func isSaved(_ placeId: UUID) -> Bool {
        idSet.contains(placeId)
    }

    /// Save or un-save. Returns the state it landed in, so a caller can report
    /// it without re-reading.
    @discardableResult
    func toggleSaved(_ placeId: UUID) -> Bool {
        if idSet.contains(placeId) {
            entries.removeAll { $0.placeId == placeId }
            idSet.remove(placeId)
        } else {
            entries.insert(SavedPlaceEntry(placeId: placeId, savedAt: Date()), at: 0)
            idSet.insert(placeId)
        }
        persist()
        onChange?()
        // User-initiated only — `applyMerged` deliberately doesn't come
        // through here, so a background sync can never buzz the phone.
        AtlasHaptics.selection()
        return idSet.contains(placeId)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([SavedPlaceEntry].self, from: data) else {
            return
        }
        entries = decoded.sorted { $0.savedAt > $1.savedAt }
        idSet = Set(decoded.map(\.placeId))
    }
}

/// One saved place. A record rather than a bare id so the list can be ordered
/// by when it was saved, matching `LibraryEntry.savedAt`.
struct SavedPlaceEntry: Codable, Hashable, Identifiable {
    let placeId: UUID
    let savedAt: Date

    var id: UUID { placeId }
}

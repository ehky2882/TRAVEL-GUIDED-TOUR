import Foundation
import Observation

/// On-device persistence for "saved makers" — the bookmark on the
/// maker page. Mirrors `LibraryStore`'s shape (a Codable entry list
/// persisted to `UserDefaults`) but keyed by maker id instead of tour
/// id.
///
/// This is a **local personal bookmark, not a social follow graph** —
/// V1 has no backend, auth, or social features. It records "this user
/// saved this maker" on the device only, exactly like saving a tour.
/// The disabled "Follow creator" affordance stays disabled; that's the
/// future social feature, distinct from this local save.
@Observable
final class SavedMakersStore {
    private static let storageKey = "atlas_saved_makers"

    private(set) var entries: [SavedMakerEntry] = []

    /// Fired after any local mutation persists. `SyncService` uses this to
    /// write changes through to Supabase when signed in. `nil` → on-device only.
    @ObservationIgnored var onChange: (() -> Void)?

    init() {
        load()
    }

    /// Replace the full set from a sign-in merge and persist, WITHOUT firing
    /// `onChange` (the sync service pushes the merged state explicitly).
    func applyMerged(_ newEntries: [SavedMakerEntry]) {
        entries = newEntries
        persist()
    }

    /// Saved makers, most-recently-saved first (matches the ordering
    /// `LibraryStore.savedEntries` uses for saved tours).
    var savedEntries: [SavedMakerEntry] {
        entries.sorted { $0.savedAt > $1.savedAt }
    }

    func isSaved(_ makerId: UUID) -> Bool {
        entries.contains { $0.makerId == makerId }
    }

    func toggleSaved(_ makerId: UUID) {
        if let index = entries.firstIndex(where: { $0.makerId == makerId }) {
            entries.remove(at: index)
        } else {
            entries.append(SavedMakerEntry(makerId: makerId, savedAt: Date()))
        }
        save()
        // User-initiated only (sync uses `applyMerged`) — safe to tick.
        AtlasHaptics.selection()
    }

    private func save() {
        persist()
        onChange?()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([SavedMakerEntry].self, from: data) else {
            return
        }
        entries = decoded
    }
}

/// One saved-maker record. `savedAt` drives most-recent-first ordering.
struct SavedMakerEntry: Codable, Identifiable, Hashable {
    let makerId: UUID
    var savedAt: Date

    var id: UUID { makerId }
}

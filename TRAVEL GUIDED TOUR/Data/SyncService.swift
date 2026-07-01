import Foundation
import Observation
import Supabase

/// Syncs a signed-in user's **library** (saved tours + listening progress +
/// completed) and **saved makers** to the Supabase `user_library` /
/// `user_saved_makers` tables, so their data follows them across devices.
///
/// Model:
/// - **On sign-in:** pull the user's remote rows, MERGE them into the local
///   stores (union — nothing on the device is lost), then push the merged
///   state back up so all devices converge.
/// - **While signed in:** every local change write-throughs to Supabase
///   (debounced), as a full-state replace (upsert present rows + delete rows
///   the user removed).
/// - **Anonymous / signed out:** does nothing — the stores stay purely on-device,
///   exactly as before.
///
/// Recents (searches / recently-viewed) are intentionally out of scope for this
/// first cut. Known limitation: an *offline* un-save on one device won't delete
/// the row on another (the sign-in merge is additive); online un-saves DO
/// propagate via write-through. RLS already scopes every row to `auth.uid()`.
@MainActor
@Observable
final class SyncService {
    private let auth: AuthService
    private let library: LibraryStore
    private let savedMakers: SavedMakersStore
    private let client: SupabaseClient

    /// Debounce window for write-through pushes — coalesces rapid changes
    /// (e.g. listening-progress ticks) into one network write.
    private let pushDebounce: Duration

    /// True while the initial sign-in merge is running, so the `applyMerged`
    /// writes and any incidental store mutations don't trigger write-through
    /// before we've pushed the merged state ourselves.
    private var isInitialSyncing = false
    private var libraryPushTask: Task<Void, Never>?
    private var makersPushTask: Task<Void, Never>?

    init(auth: AuthService,
         library: LibraryStore,
         savedMakers: SavedMakersStore,
         client: SupabaseClient = SupabaseClientProvider.shared,
         pushDebounce: Duration = .seconds(2)) {
        self.auth = auth
        self.library = library
        self.savedMakers = savedMakers
        self.client = client
        self.pushDebounce = pushDebounce

        // Write-through hooks: a local change, while signed in, pushes up.
        library.onChange = { [weak self] in self?.scheduleLibraryPush() }
        savedMakers.onChange = { [weak self] in self?.scheduleMakersPush() }

        observeAuth()
        // A restored session (signed in at launch) won't fire an auth change,
        // so kick the initial sync directly if we're already signed in.
        if auth.isSignedIn {
            Task { await initialSync() }
        }
    }

    // MARK: - Auth observation

    private func observeAuth() {
        withObservationTracking {
            _ = auth.user
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.auth.isSignedIn {
                    await self.initialSync()
                } else {
                    self.handleSignedOut()
                }
                self.observeAuth() // re-arm for the next change
            }
        }
    }

    /// On sign-out, clear this account's data from the device. It stays safe in
    /// Supabase (signing back in restores it via `initialSync`), so this is a
    /// LOCAL-only wipe — no remote delete. `applyMerged` persists without firing
    /// the write-through hook, and a signed-out session no-ops any pending push.
    private func handleSignedOut() {
        libraryPushTask?.cancel()
        makersPushTask?.cancel()
        library.applyMerged([])
        savedMakers.applyMerged([])
    }

    // MARK: - Initial sign-in sync (pull → merge → push)

    func initialSync() async {
        guard auth.isSignedIn, !isInitialSyncing else { return }
        isInitialSyncing = true
        defer { isInitialSyncing = false }

        do {
            let remoteLibrary: [UserLibraryRow] =
                try await client.from("user_library").select().execute().value
            let remoteMakers: [UserSavedMakerRow] =
                try await client.from("user_saved_makers").select().execute().value

            library.applyMerged(Self.mergeLibrary(local: library.entries, remote: remoteLibrary))
            savedMakers.applyMerged(Self.mergeSavedMakers(local: savedMakers.entries, remote: remoteMakers))

            try await pushLibrary()
            try await pushMakers()
        } catch {
            // Best-effort: a failed sync leaves the local stores intact and the
            // user fully functional offline. The next change (or next sign-in)
            // retries.
        }
    }

    // MARK: - Write-through (debounced)

    private func scheduleLibraryPush() {
        guard auth.isSignedIn, !isInitialSyncing else { return }
        libraryPushTask?.cancel()
        libraryPushTask = Task { [weak self, pushDebounce] in
            try? await Task.sleep(for: pushDebounce)
            guard !Task.isCancelled, let self else { return }
            try? await self.pushLibrary()
        }
    }

    private func scheduleMakersPush() {
        guard auth.isSignedIn, !isInitialSyncing else { return }
        makersPushTask?.cancel()
        makersPushTask = Task { [weak self, pushDebounce] in
            try? await Task.sleep(for: pushDebounce)
            guard !Task.isCancelled, let self else { return }
            try? await self.pushMakers()
        }
    }

    // MARK: - Push (full-state replace)

    private func pushLibrary() async throws {
        guard let uid = auth.user?.id.uuidString.lowercased() else { return }
        let rows = library.entries.map { UserLibraryRow(entry: $0, userId: uid) }
        if rows.isEmpty {
            try await client.from("user_library").delete().eq("user_id", value: uid).execute()
            return
        }
        try await client.from("user_library").upsert(rows, onConflict: "user_id,tour_id").execute()
        let keep = rows.map(\.tourId).joined(separator: ",")
        try await client.from("user_library").delete()
            .eq("user_id", value: uid)
            .not("tour_id", operator: .in, value: "(\(keep))")
            .execute()
    }

    private func pushMakers() async throws {
        guard let uid = auth.user?.id.uuidString.lowercased() else { return }
        let rows = savedMakers.entries.map { UserSavedMakerRow(entry: $0, userId: uid) }
        if rows.isEmpty {
            try await client.from("user_saved_makers").delete().eq("user_id", value: uid).execute()
            return
        }
        try await client.from("user_saved_makers").upsert(rows, onConflict: "user_id,maker_id").execute()
        let keep = rows.map(\.makerId).joined(separator: ",")
        try await client.from("user_saved_makers").delete()
            .eq("user_id", value: uid)
            .not("maker_id", operator: .in, value: "(\(keep))")
            .execute()
    }

    // MARK: - Pure merge (unit-tested; no network)

    /// Union local + remote library entries. `saved`/`completed` survive if set
    /// on either side; `listenedSeconds` takes the max and `lastListenedAt` the
    /// later; `downloadedAt` stays device-local (never taken from remote).
    nonisolated static func mergeLibrary(local: [LibraryEntry], remote: [UserLibraryRow]) -> [LibraryEntry] {
        var byId: [UUID: LibraryEntry] = [:]
        for entry in local { byId[entry.tourId] = entry }
        for row in remote {
            guard let tid = UUID(uuidString: row.tourId) else { continue }
            if let local = byId[tid] {
                byId[tid] = LibraryEntry(
                    tourId: tid,
                    savedAt: local.savedAt ?? row.savedAt,
                    downloadedAt: local.downloadedAt,
                    listenedSeconds: max(local.listenedSeconds, row.listenedSeconds),
                    lastListenedAt: laterOf(local.lastListenedAt, row.lastListenedAt),
                    completedAt: local.completedAt ?? row.completedAt
                )
            } else {
                byId[tid] = LibraryEntry(
                    tourId: tid,
                    savedAt: row.savedAt,
                    downloadedAt: nil,
                    listenedSeconds: row.listenedSeconds,
                    lastListenedAt: row.lastListenedAt,
                    completedAt: row.completedAt
                )
            }
        }
        return Array(byId.values)
    }

    /// Union local + remote saved makers, keeping the earliest known `savedAt`.
    nonisolated static func mergeSavedMakers(local: [SavedMakerEntry], remote: [UserSavedMakerRow]) -> [SavedMakerEntry] {
        var byId: [UUID: SavedMakerEntry] = [:]
        for entry in local { byId[entry.makerId] = entry }
        for row in remote {
            guard let mid = UUID(uuidString: row.makerId) else { continue }
            if let local = byId[mid] {
                byId[mid] = SavedMakerEntry(makerId: mid, savedAt: min(local.savedAt, row.savedAt))
            } else {
                byId[mid] = SavedMakerEntry(makerId: mid, savedAt: row.savedAt)
            }
        }
        return Array(byId.values)
    }

    nonisolated private static func laterOf(_ a: Date?, _ b: Date?) -> Date? {
        switch (a, b) {
        case let (a?, b?): return Swift.max(a, b)
        case let (a?, nil): return a
        case let (nil, b?): return b
        case (nil, nil): return nil
        }
    }
}

// MARK: - Row DTOs (Supabase `user_*` table shapes)

/// Mirrors a `public.user_library` row. snake_case columns mapped via CodingKeys.
struct UserLibraryRow: Codable {
    let userId: String
    let tourId: String
    let savedAt: Date?
    let downloadedAt: Date?
    let listenedSeconds: Int
    let lastListenedAt: Date?
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tourId = "tour_id"
        case savedAt = "saved_at"
        case downloadedAt = "downloaded_at"
        case listenedSeconds = "listened_seconds"
        case lastListenedAt = "last_listened_at"
        case completedAt = "completed_at"
    }

    init(entry: LibraryEntry, userId: String) {
        self.userId = userId
        self.tourId = entry.tourId.uuidString.lowercased()
        self.savedAt = entry.savedAt
        self.downloadedAt = entry.downloadedAt
        self.listenedSeconds = entry.listenedSeconds
        self.lastListenedAt = entry.lastListenedAt
        self.completedAt = entry.completedAt
    }
}

/// Mirrors a `public.user_saved_makers` row.
struct UserSavedMakerRow: Codable {
    let userId: String
    let makerId: String
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case makerId = "maker_id"
        case savedAt = "saved_at"
    }

    init(entry: SavedMakerEntry, userId: String) {
        self.userId = userId
        self.makerId = entry.makerId.uuidString.lowercased()
        self.savedAt = entry.savedAt
    }
}

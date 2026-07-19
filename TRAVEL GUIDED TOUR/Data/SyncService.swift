import Foundation
import Observation
import Supabase

/// Syncs a signed-in user's **library** (saved tours + listening progress +
/// completed) and **recently-viewed** to the Supabase `user_library` /
/// `user_recently_viewed` tables, so their data follows them across devices.
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
    private let recentlyViewed: RecentlyViewedStore
    private let client: SupabaseClient

    /// Debounce window for write-through pushes — coalesces rapid changes
    /// (e.g. listening-progress ticks) into one network write.
    private let pushDebounce: Duration

    /// True while the initial sign-in merge is running, so the `applyMerged`
    /// writes and any incidental store mutations don't trigger write-through
    /// before we've pushed the merged state ourselves.
    private var isInitialSyncing = false
    private var libraryPushTask: Task<Void, Never>?
    private var recentlyViewedPushTask: Task<Void, Never>?

    init(auth: AuthService,
         library: LibraryStore,
         recentlyViewed: RecentlyViewedStore,
         client: SupabaseClient = SupabaseClientProvider.shared,
         pushDebounce: Duration = .seconds(2)) {
        self.auth = auth
        self.library = library
        self.recentlyViewed = recentlyViewed
        self.client = client
        self.pushDebounce = pushDebounce

        // Write-through hooks: a local change, while signed in, pushes up.
        library.onChange = { [weak self] in self?.scheduleLibraryPush() }
        recentlyViewed.onChange = { [weak self] in self?.scheduleRecentlyViewedPush() }

        // Flush any pending debounced write-through before a sign-out tears down
        // the session. Without this, a save/un-save made within the 2s debounce
        // window is cancelled by `handleSignedOut` and never reaches Supabase —
        // so it resurrects on the next sign-in via the additive merge. `[weak
        // self]` keeps this closure (retained by `auth`) from retaining us back.
        auth.preSignOut = { [weak self] in await self?.flushPendingWrites() }

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
        recentlyViewedPushTask?.cancel()
        library.applyMerged([])
        recentlyViewed.applyMerged([])
    }

    // MARK: - Flush (pre-sign-out)

    /// Immediately push the current signed-in state to Supabase, awaiting the
    /// network write, and cancel the pending debounce Tasks so they don't
    /// double-fire. Called from `AuthService`'s `preSignOut` hook — i.e. *before*
    /// `client.auth.signOut()` clears the session — because once signed out
    /// `auth.user` is nil and every `push*` no-ops on its `guard let uid`. This
    /// is what makes a save/un-save made within the 2s debounce window survive an
    /// immediate sign-out (otherwise `handleSignedOut` just cancels the pending
    /// push). Best-effort: each push's error is swallowed so an offline sign-out
    /// isn't blocked; when online the writes complete before the session ends.
    func flushPendingWrites() async {
        libraryPushTask?.cancel()
        recentlyViewedPushTask?.cancel()
        guard auth.isSignedIn else { return }
        try? await pushLibrary()
        try? await pushRecentlyViewed()
    }

    // MARK: - Initial sign-in sync (pull → merge → push)

    func initialSync() async {
        guard auth.isSignedIn, !isInitialSyncing else { return }
        isInitialSyncing = true
        defer { isInitialSyncing = false }

        do {
            let remoteLibrary: [UserLibraryRow] =
                try await client.from("user_library").select().execute().value
            let remoteViewed: [UserRecentlyViewedRow] =
                try await client.from("user_recently_viewed").select().execute().value

            library.applyMerged(Self.mergeLibrary(local: library.entries, remote: remoteLibrary))
            recentlyViewed.applyMerged(Self.mergeRecentlyViewed(local: recentlyViewed.entries, remote: remoteViewed))

            try await pushLibrary()
            try await pushRecentlyViewed()
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

    private func scheduleRecentlyViewedPush() {
        guard auth.isSignedIn, !isInitialSyncing else { return }
        recentlyViewedPushTask?.cancel()
        recentlyViewedPushTask = Task { [weak self, pushDebounce] in
            try? await Task.sleep(for: pushDebounce)
            guard !Task.isCancelled, let self else { return }
            try? await self.pushRecentlyViewed()
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

    private func pushRecentlyViewed() async throws {
        guard let uid = auth.user?.id.uuidString.lowercased() else { return }
        let rows = recentlyViewed.entries.map { UserRecentlyViewedRow(entry: $0, userId: uid) }
        if rows.isEmpty {
            try await client.from("user_recently_viewed").delete().eq("user_id", value: uid).execute()
            return
        }
        try await client.from("user_recently_viewed").upsert(rows, onConflict: "user_id,tour_id").execute()
        let keep = rows.map(\.tourId).joined(separator: ",")
        try await client.from("user_recently_viewed").delete()
            .eq("user_id", value: uid)
            .not("tour_id", operator: .in, value: "(\(keep))")
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

    /// Union local + remote recently-viewed, keeping the latest `viewedAt` per
    /// tour. Sorting/capping is applied by `RecentlyViewedStore.applyMerged`.
    nonisolated static func mergeRecentlyViewed(local: [RecentlyViewedEntry], remote: [UserRecentlyViewedRow]) -> [RecentlyViewedEntry] {
        var byId: [UUID: RecentlyViewedEntry] = [:]
        for entry in local { byId[entry.tourId] = entry }
        for row in remote {
            guard let tid = UUID(uuidString: row.tourId) else { continue }
            if let local = byId[tid] {
                byId[tid] = RecentlyViewedEntry(tourId: tid, viewedAt: Swift.max(local.viewedAt, row.viewedAt))
            } else {
                byId[tid] = RecentlyViewedEntry(tourId: tid, viewedAt: row.viewedAt)
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

    /// Encode the nullable columns as explicit JSON `null` (not omitted).
    ///
    /// This is load-bearing for **un-save**: `LibraryStore.toggleSaved` clears
    /// `savedAt` to nil but KEEPS the entry (it may still hold progress), so the
    /// row is `upsert`ed — not deleted — on the next push. Swift's *synthesized*
    /// `Encodable` drops nil optionals (`encodeIfPresent`), so `saved_at` would
    /// be absent from the payload, and PostgREST's `ON CONFLICT DO UPDATE` then
    /// leaves the existing column value untouched — the row stays "saved"
    /// remotely and the tour resurrects on the next sign-in merge. Emitting an
    /// explicit `null` forces the upsert to actually clear the column.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userId, forKey: .userId)
        try c.encode(tourId, forKey: .tourId)
        try c.encode(savedAt, forKey: .savedAt)
        try c.encode(downloadedAt, forKey: .downloadedAt)
        try c.encode(listenedSeconds, forKey: .listenedSeconds)
        try c.encode(lastListenedAt, forKey: .lastListenedAt)
        try c.encode(completedAt, forKey: .completedAt)
    }
}

/// Mirrors a `public.user_recently_viewed` row.
struct UserRecentlyViewedRow: Codable {
    let userId: String
    let tourId: String
    let viewedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tourId = "tour_id"
        case viewedAt = "viewed_at"
    }

    init(entry: RecentlyViewedEntry, userId: String) {
        self.userId = userId
        self.tourId = entry.tourId.uuidString.lowercased()
        self.viewedAt = entry.viewedAt
    }
}

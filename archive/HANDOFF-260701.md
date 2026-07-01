# HANDOFF — 2026-07-01 (session 49, code)

## Headline

**Fixed the owner's real-device sync bug: while signed in, un-saving a tour then signing out and back in used to resurrect the tour in Saved.** Two PRs (#291 then the real fix #294) + **TestFlight 1.0 (58)** archived. Pending owner Organizer upload + device retest.

## What happened, in order

1. **#291 — pre-sign-out flush (shipped in build 57).** Diagnosed correctly-but-incompletely: local library changes write-through to Supabase on a **2s debounce** (`scheduleLibraryPush` → `Task { sleep(2s); pushLibrary() }`); signing out inside that window let `handleSignedOut` **cancel** the pending push, so the un-save never reached Supabase. Fix: `SyncService.flushPendingWrites()` (cancels the debounce Tasks, then awaits `pushLibrary/Makers/RecentlyViewed`), awaited via a new **`AuthService.preSignOut`** hook at the top of `signOut()` — *before* `client.auth.signOut()`, while the uid is still valid (`handleSignedOut` runs after, when `auth.user` is already nil, so a push there no-ops). `[weak self]` on the hook avoids a retain cycle (SyncService holds AuthService strongly). Merged, went out in build 57 (alongside "Report a concern").

2. **Owner retested build 57 → STILL resurrected.** The flush was necessary but **not sufficient**: the push it triggered was itself a no-op for the un-save.

3. **#294 — the actual root cause + fix (build 58).**
   - `LibraryStore.toggleSaved` un-saves by setting `savedAt = nil` **but keeps the `LibraryEntry`** (it may still hold listening progress). So on push the row is in `entries` → **upserted, not deleted** (it's in the delete-not-in `keep` list).
   - `UserLibraryRow.savedAt` is `Date?`, and Swift's **synthesized `Encodable` drops nil optionals** (`encodeIfPresent`). Verified empirically with `swift`: `Row(savedAt: nil, listenedSeconds: 42)` → `{"tour_id":…,"listened_seconds":42,"user_id":…}` — **no `saved_at`**.
   - PostgREST's `ON CONFLICT DO UPDATE` only updates columns **present in the payload**, so an absent `saved_at` leaves the existing (still-saved) value untouched → the row stays saved remotely → resurrects via `mergeLibrary`'s `savedAt: local.savedAt ?? row.savedAt` on the next sign-in.
   - **Fix:** custom `UserLibraryRow.encode(to:)` emits the nullable columns (`saved_at`, `downloaded_at`, `last_listened_at`, `completed_at`) as **explicit JSON `null`** so the upsert actually clears them. Only `UserLibraryRow` affected — saved-makers un-save *removes* the entry (deleted via delete-not-in) and its row has no nullable columns; recently-viewed likewise.
   - New unit test `test_libraryRow_encodesNilOptionalsAsExplicitNull` (asserts the fields serialize as `NSNull`, present — pure encoding, no network). `test_sim` **121/121** green.

4. **Build 58** — bump #295 (app-target `CURRENT_PROJECT_VERSION` 57 → 58 both configs; test target stays 1; `MARKETING_VERSION` 1.0). Archived clean from an isolated worktree at **`/tmp/Atlas-20260701-0023-b58.xcarchive`** with `-allowProvisioningUpdates`. Verified: embedded `1.0 (58)`, `UIRequiresFullScreen=true` held, binary greps clean (no `TEMP_LOCAL_DEMO`; `apkcihljybvuyuzpbnqd.supabase.co` + `ehky2882.github.io/…/Tours.json` present). **Open in Organizer; owner uploads manually** (declined upload-automation setup for now).

## Pending / next

- **Owner:** Organizer → Distribute → Upload build 58; then device retest: sign in → un-save a tour **you've listened to** → immediately sign out → sign back in → should **stay un-saved** (also confirm a save-just-before-signout persists).
- **Known follow-up, NOT fixed (flagged):** cross-device **offline** un-saves still won't propagate — `mergeLibrary` is additive union ("saved on either side wins"); needs tombstones/soft-deletes (separate design task).
- Throwaway `auth.users` test rows still owed a cleanup (carried from session 47).

## Tribal knowledge logged

- **`reference-supabase-upsert-null-omission` (memory):** Swift synthesized `Encodable` omits nil optionals → any upsert relying on setting a column to NULL must emit **explicit null** (custom `encode(to:)`); test it directly (`json["col"] is NSNull`), no network needed.
- Shared checkout `/Users/EY/TRAVEL-GUIDED-TOUR` was mid-flight on another session's `claude/share-universal-links` (uncommitted PlayerView/TourDetailView/entitlements/App + new DeepLink files) — did all work in a `git worktree` off `origin/main`, left the primary untouched.

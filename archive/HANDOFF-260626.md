# HANDOFF — session 44 (2026-06-26, code — catalog refresh hardening)

**Session-end snapshot.** Hardened the gh-pages `Tours.json` refresh that
had left two testers stuck on a stale cached catalog for hours, then it
shipped in **TestFlight 1.0 (49)**. This closes the "Build-cut bug to
harden later" note that had been carried in `CLAUDE.md` since build 46.

## What shipped — PR #245 (the four behaviors)

Merged to `main` (`4084ec3`, squash) after owner sim review; carried into
build 49. All behind the existing `CatalogFetching` protocol seam, so it
stays unit-testable with the stub fetcher.

1. **Retry with backoff** — `RemoteCatalogLoader.refresh()` retries up to
   **3 attempts** with ~**1s/2s** exponential backoff + jitter
   (`CatalogRetryPolicy`, injectable; `.none` = single-shot for tests).
   Retryable = `URLError` (timeout/offline/DNS/dropped) + transient server
   (`CatalogFetchError.httpStatus` 5xx/408/429). **Not** retryable = a clean
   4xx (e.g. 404) or a 2xx with undecodable bytes. Returns `nil` **only after
   all attempts fail** — the good local copy is never clobbered.
2. **Longer timeouts** — a dedicated `URLSession` with
   `timeoutIntervalForRequest = 30` + `timeoutIntervalForResource = 60`
   (was a single 15s). The 2.1 MB catalog genuinely times out at 10–15s on
   slow connections (observed while testing).
3. **Refresh on foreground** — `scenePhase → .active` calls
   `DataService.refreshOnForeground()`, **debounced 60s** + an `isRefreshing`
   in-flight guard. So reopening the app picks up new content **with no
   force-quit** — the exact tester complaint.
4. **Version-stamped cache** — the cache is stamped with `CFBundleVersion`
   (sidecar `Tours.cache.version`) and **discarded on load if written by a
   different/absent version**, so a freshly bundled seed isn't shadowed by a
   stale cache after an update (the 47→48 case). Cache-first otherwise.

Files: `Data/RemoteCatalogLoader.swift`, `Data/DataService.swift`,
`TRAVEL_GUIDED_TOURApp.swift`, `RemoteCatalogLoaderTests.swift` (+8 tests).
**`test_sim` 103/103 green** (was 95).

## Verification

- **Unit tests** (the guarantee): retry-succeeds-after-N-transient-failures,
  gives-up-after-max-and-leaves-local-intact, no-retry-on-4xx, retry-on-5xx,
  cache-discarded-on-version-mismatch / missing-stamp, kept-on-match,
  foreground-debounce. Deterministic via injected `CatalogRetryPolicy` (0
  delay) + a counting actor fetcher + injected `now`/`startedAt`.
- **Sim, safe:** deleted the sim's `Tours.cache.json`, relaunched, watched
  the refresh recreate it (2,108,782 bytes / 370 tours / version `48`) in
  ~3s — proves refresh fetches + caches on-device (the bundle seed never
  writes that file).
- **Sim, live end-to-end (owner-authorized):** added a `★` to one title on
  the **live** gh-pages catalog → **backgrounded + reopened** the app (same
  pid 1588, no force-quit) → `★` appeared in ~1s → reverted gh-pages
  **byte-exact** (sha256 `fbc8a334…` restored, 0 `★`, CDN re-verified clean).
  Same trick as the build-46 verification (session 40).

## Process notes

- Worked in a throwaway worktree `git worktree add -b claude/refresh-hardening
  /tmp/refresh-hardening origin/main` — the primary checkout was on a parallel
  session's branch with an uncommitted `TourDetailView.swift` edit; left
  untouched. Build/test from the worktree's own `.xcodeproj`.
- **Pushing the `★` to the live catalog was (correctly) blocked by the
  auto-mode classifier** until the owner explicitly authorized it — "sure" to
  a sim-verification question did not count. Don't mutate the live shared
  catalog without an explicit go-ahead.
- The PR was app code, so per the merge policy it waited for **explicit owner
  OK + visual sim confirmation** — both satisfied, then squash-merged.

## Build 49 (PR #249) — what else it carries

App-code only build (no content change; catalog ships live via the remote
catalog, ~370 tours / 5 makers). Merged since build 48:

- **#244** — Nearby Tours section below the inline Location map (detail sheet).
- **#245** — resilient catalog refresh (this session).
- **#246** — maker-page sort/view persistence; drops "Default," opens on Newest.
- **#247** — home polish batch (placecard / drawer / lock-screen, 7 items).
- **#248** — search polish (caption SEARCH title, empty-state copy, faster
  type-ahead).

## Carried-over / open

- **TODO (deferred by owner 2026-06-21):** 2 dead gallery images — The Oculus
  + The Charging Bull (Wikimedia 404s) — remove or re-source via the pipeline.
- **Optional follow-up not done (by design):** a periodic "re-pull if last
  success older than N min" timer for very long foreground sessions — the
  foreground refresh covers the reopen case; add only if wanted.
- **In flight:** Paris (6th city, `claude/paris-scripts-260622`); V2
  creator-platform design branches (see `ROADMAP.md § V2`).
- gh-pages history has 2 extra commits from the live test (marker + byte-exact
  revert); content matches `main`, so the auto-publish workflow sees no diff.

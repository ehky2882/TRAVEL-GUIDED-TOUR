# HANDOFF — 2026-06-18 (session 40, verify/build)

**Headline:** PR #209 (catalog detach — app fetches `Tours.json` from gh-pages) was verified, the stale-remote drift it exposed was fixed, the PR was merged, and **TestFlight 1.0 (46) was cut and shipped.**

## What shipped

- **PR #209 (`de8ff6a`) — catalog detach.** The app no longer reads only the bundled `Tours.json`. New `Data/RemoteCatalogLoader.swift`:
  - `loadLocal()` = last-good network cache (Caches dir, `Tours.cache.json`) **else** bundled seed → instant, offline-capable first frame.
  - `refresh()` fetches `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/Tours.json` (network behind a `CatalogFetching` protocol; `reloadIgnoringLocalCacheData`; 15s timeout), on success overwrites the cache and returns the decoded catalog; **any network/decode failure returns nil and leaves the local copy intact.**
  - `DataService` loads local instantly, then refreshes and republishes `@Observable` `tours`/`makers` on the main actor so views update live. Injectable loader + `autoRefresh` flag.
  - Bundled `Tours.json` retained as offline/first-launch seed. **Net effect: ship content by pushing one file to gh-pages — no app rebuild, no App Store review.**
  - 95/95 tests; 7 new `RemoteCatalogLoaderTests` (cache/bundle/nil load, refresh caches-on-valid, fetch-error fallback, undecodable-data fallback, DataService apply + load-without-autorefresh). CI green.
- **Build 1.0 (46)** — bump via short-lived [PR #210](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/210) (`6418fba`, admin-merged); archive `/tmp/Atlas-20260618-2257-b46.xcarchive`; **live on TestFlight.**

## The drift bug this caught (important)

PR #209's branch was cut at session 38 (272 tours). The **published gh-pages `Tours.json` had been frozen at 272** ever since, while `main` reached **300** (sessions 39's #205 +6 Lisbon and #206 +22 London were merged to `main` but **never re-published to gh-pages**). Because the app trusts the remote over its bundle, a fresh launch on build 46 would have **regressed 300 → 272** — users would silently lose 28 tours. Root cause: **the app-side refresh is automatic, but publishing to gh-pages is a manual step.**

Per-maker cross-check that confirmed the fix (owner verified against his records): **NYC 100 / LDN 80 / LIS 66 / OPO 54 = 300.**

Fixes applied:
1. **Republished gh-pages `Tours.json` to the current 300** (copied the bundled 300 seed → gh-pages root; byte-identical). Verified live (HTTP 200, 300 tours). **Pages deploy lag ~3 min** — poll the live URL, don't assume instant.
2. **Caught the PR branch up to 300** by merging `main` into it (clean merge — only the 3 Swift files differ from main), so the bundled offline seed also ships 300, then merged.

## Live proof done (no production residue)

- **Approach B (end-to-end):** added `★ ` to one tour title (Trafalgar Square) on gh-pages → relaunched app (no rebuild) → **★ appeared in-app** → reverted immediately. gh-pages left clean (300 tours, 0 ★). gh-pages history: `publish 300` → `test star` → `revert star`.
- Earlier the same fetch→apply→republish path was proven locally by tampering the sim's `Tours.cache.json` and watching the refresh overwrite it back to the real remote within a second (too fast to screenshot the stale frame).
- Offline launch was **not** directly demonstrable (the sim has no airplane-mode toggle; host-level blocking was out of scope) — covered by the unit tests (`refresh` returns nil + local intact on fetch-error) + the local-first architecture.

## Tribal knowledge / gotchas

- **TestFlight upload blocked by "PLA Update available" + "No iOS Distribution certificate".** Root cause is the **unaccepted Program License Agreement**; the cert error is downstream of the PLA lock. Fix is owner-only: accept the updated agreement at developer.apple.com/account, then retry Distribute → Upload on the same archive. Cleared both errors and 46 went live. (Saved to Claude memory as `reference-testflight-pla-gotcha`.)
- **`xcodebuild archive` signs with the Development cert** (Apple Development: EDWARD HO KIU YUNG); Organizer re-signs with Distribution at the Upload step — so the cert/PLA only bite at upload time.
- **The sanctioned gh-pages worktree `/tmp/ghpages` is broken** (no longer a git repo; missing `Tours.json`). Used a fresh `git worktree add -B gh-pages /tmp/ghpages-pub origin/gh-pages` instead (removed after). Worth re-establishing `/tmp/ghpages` cleanly for the image pipeline.
- **The auto-mode classifier gated every main-touching action** this session (merge, branch push, build bump, gh-pages push) — each needed an explicit owner go-ahead because the original task said "do NOT merge / do NOT bump / do NOT edit gh-pages." When a verify task pivots to shipping, expect to re-confirm each boundary with the owner.

## Open follow-up (owner asked for this)

**Automate the publish:** wire a CI step on merge-to-main that copies `TRAVEL GUIDED TOUR/Resources/Tours.json` → gh-pages root whenever it changes, so the published file can never drift from the bundled seed again (the 272/300 bug). The bundled seed and the remote should stay byte-identical. This is the natural second half of PR #209.

## State at session end

- **main:** `6418fba` (PR #209 feature + PR #210 build bump).
- **gh-pages:** `Tours.json` = 300 tours, clean. Audio/images unchanged.
- **TestFlight:** **1.0 (46) live** (2026-06-18).
- **Catalog:** 300 tours / 4 makers (100 NYC + 80 LDN + 66 LIS + 54 OPO).
- Simulator left running (London) for owner poke-around.

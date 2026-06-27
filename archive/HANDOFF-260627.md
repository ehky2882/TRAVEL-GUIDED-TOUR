# HANDOFF — session 46 (2026-06-27, code — V2 Step 2 app cutover to Supabase)

**Session-end snapshot.** The app now reads its catalog from the live
Supabase backend. Shipped to `main` via
**[PR #255](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/255)**
(`fa8ec2a`, squash). Owner reviewed the behavior described and explicitly
OK'd the merge ("i'm good with it for now. merge"). **Shipped in
TestFlight 1.0 (50)** — bump 49→50 via PR #257; archived
(`/tmp/Atlas-20260627-0003-b50.xcarchive`, verified 1.0 (50),
`UIRequiresFullScreen` held, Supabase host + anon key in the binary) and
owner uploaded via Organizer; live 2026-06-27. Build 50 also carries the
session-45 geofence fix (#251).

## What shipped

V2 **Step 2 app-side cutover**. The app fetches the catalog from the
Supabase `get_catalog` RPC (project "Dozent",
`https://apkcihljybvuyuzpbnqd.supabase.co`) **first**, with the gh-pages
`Tours.json` retained as an automatic **fallback mirror**, then the
on-disk cache, then the bundled offline seed. The Step-1 `CatalogFetching`
seam made this a small change — `ToursData`, the models, views, cache, and
bundled seed are all unchanged.

### Files (3, +224/-12)

- **`Data/SupabaseConfig.swift`** (new) — `projectURL` + the client-safe
  **anon/publishable key** (`sb_publishable_…`) + the `get_catalog` RPC
  URL (`catalogRPCURL`). `isConfigured` guard returns false for a
  blank/placeholder key so the loader skips the Supabase source and reads
  gh-pages-only rather than failing every refresh. **The committed key is
  the publishable/anon key — client-safe by design (RLS-gated, ships in the
  binary). The service_role secret is NOT in the repo and must never be.**
- **`Data/RemoteCatalogLoader.swift`** — adds `SupabaseCatalogFetcher`
  (plain `URLSession` POST: `apikey` + `Authorization: Bearer <anon>` +
  `Content-Type: application/json`, `{}` body, 30s/60s timeouts, non-2xx →
  `CatalogFetchError.httpStatus`). Adds a `CatalogSource {fetcher, url}`
  struct and an ordered `sources` array. `refresh()` now iterates sources
  (Supabase → gh-pages) and returns the first decodable catalog (caching
  the raw bytes). A new private `refresh(from:)` holds the per-source
  retry/backoff loop — identical to the old single-source behavior, so the
  existing tests are unaffected. `static defaultSources` builds
  `[supabase?, ghPages]` (supabase only when `SupabaseConfig.isConfigured`).
  The old `init(fetcher:…)` is now a backward-compatible **convenience
  init** wrapping one source against `remoteURL`.
- **`…Tests/RemoteCatalogLoaderTests.swift`** — +3 tests:
  fallback-to-second-source-when-first-fails, first-source-success-skips-
  rest, all-sources-fail-leaves-local-intact.

## Key decision (owner)

**No third-party SDK.** The catalog read is a plain RPC POST, so a
`URLSession` fetcher covers it (exactly what `backend/README.md`
describes). **`supabase-swift` is deferred to Step 3** (auth/sign-in),
where it's genuinely needed. Avoids the first 3rd-party dep + pbxproj
package wrangling for a ~220-line change.

## Verification

- **`test_sim`: 113/113** (110 prior + 3 new). CI green on the PR (Build +
  unit tests + Validate Tours.json).
- **RPC pre-check (`curl`):** `POST …/rpc/get_catalog` with the
  apikey/Bearer headers → HTTP 200, **5 makers / 370 tours / 396 stops**,
  camelCase keys matching `Maker`/`Tour`/`Stop` Codable (all required
  fields present).
- **Live sim (iPhone 17 Pro):** a temporary debug `print` (added, verified,
  then removed before commit) logged
  `🟢 CATALOG REFRESH OK from apkcihljybvuyuzpbnqd.supabase.co — 370 tours,
  5 makers` on launch — proving the data came from Supabase, not the
  gh-pages mirror or bundled seed (gh-pages is the fallback and was never
  contacted). Home rendered the full catalog (rails, maker names, hero
  images, map pins). Capture via `simctl launch --console-pty` (print goes
  to stdout, NOT the unified log — `log stream` won't see it).

## Operational consequence (important)

Supabase is now the **primary** source. **Content changes must reach the
DB** (`python3 backend/seed_from_toursjson.py` → run output in the SQL
Editor; idempotent upsert by id), not only gh-pages — otherwise the gh-pages
fallback mirror could be *newer* than the live source. Both currently
mirror the same `Resources/Tours.json`. Worth automating later: a
publish-to-Supabase step alongside `.github/workflows/publish-catalog.yml`.

## Auto-seed automation (PR #260, activated 2026-06-27)

Closed the "content must reach the DB manually" gap. New `seed-supabase` job
in `.github/workflows/publish-catalog.yml`: on every `main` push touching
`Tours.json` it regenerates `seed_from_toursjson.py` and `psql`-applies it to
the Supabase DB — idempotent (upsert by id), transactional
(`ON_ERROR_STOP=1` + `begin/commit`), serialized (concurrency group), parallel
to and independent of the gh-pages publish (a DB failure never blocks the
mirror).

- **Opt-in via one repo secret**, `SUPABASE_DB_URL` = the Supabase
  **Session-pooler** connection string (IPv4-proxied; the direct URL is
  IPv6-only and would fail on GitHub runners). The job no-ops if the secret is
  unset. **Owner added the secret 2026-06-27** — so it's live.
- **Verified end-to-end:** manual `workflow_dispatch` of "Publish catalog" →
  both jobs green; seed job emitted SQL for 5 makers / 370 tours / 396 stops,
  `psql` printed "Catalog upserted into Supabase"; post-seed `get_catalog` RPC
  still returns 5/370/396.
- **No-delete by design:** upsert-only, never deletes DB rows absent from the
  file — deliberate so future maker-created tours aren't wiped. Retire an
  Atlas tour via `takedown_tour`/`status`, not by dropping it from the file.
- Setup steps + limitation written into `backend/README.md`.

**Net:** content merges now auto-sync to BOTH gh-pages and Supabase. No more
hand-seeding via the SQL Editor.

## Next

- **Build bump 49 → 50 + TestFlight** — DONE this session (see snapshot
  above); listed here only because the original note predates the bump.
- **Step 3 (accounts/auth):** add `supabase-swift`, sign-in UI (Apple /
  email / Google) in the "Me" tab, store sync → `user_*` tables. Owner
  still needs to enable auth providers in the dashboard (B-list in ROADMAP
  § V2 checklist).

## Process notes

- Branched off `origin/main`; `test_sim` green before push; PR green; owner
  OK'd → squash-merged + branch deleted.
- The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so the new
  `SupabaseConfig.swift` was auto-included — no pbxproj edit needed.
- Persistent SourceKit false-positives ("Cannot find 'SupabaseConfig' /
  'ToursData' in scope") appeared in the IDE diagnostics throughout — the
  real `xcodebuild` compiler and the full test run were always green. Stale
  indexer, not a build error.
- macOS has no `timeout`; capture console via a backgrounded
  `simctl launch --console-pty … & sleep N; kill`.

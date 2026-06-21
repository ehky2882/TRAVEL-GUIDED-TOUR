# Backend design (V2)

Status: **foundation design** (2026-06-20). The artifacts (`backend/schema.sql`,
`backend/seed_from_toursjson.py`, `backend/README.md`) exist; no Supabase project is
stood up yet. The app still reads the catalog from gh-pages.

## Why
V1 / build 46 detached the catalog so the app fetches a `{makers, tours}` JSON document
at launch (`RemoteCatalogLoader`, bundled offline seed). That document is still a
hand-edited file. V2 needs a real database so that **makers can create and own content,
accounts and purchases exist, and content is moderated** — none of which a static file
can do. This is the keystone every other V2 feature depends on.

## Decision: Supabase (Postgres)
Chosen over Firebase / CloudKit / custom because it fits a *marketplace* (relational
data: makers ↔ tours ↔ stops ↔ purchases), supports the future web "Atlas Studio",
bundles auth + storage + functions, and has predictable pricing (~$25/mo Pro; free tier
covers build/test). See `cdn-decision.md` for how blob storage relates (kept separate).

## Scope of the foundation
**Build now:** the read-side catalog — `makers`, `tours`, `stops` + a read-API that
returns the exact shape the app already decodes + a migration from `Tours.json`.

**Forward-designed (sketched here, built in later V2 steps):** the maker write-side and
consumer-account tables. Listed below so the foundation schema won't need a rewrite.

## Schema (build-now)
Maps 1:1 to the Swift models (`Tour`, `Stop`, `Maker`, `TourCategory`). Full DDL in
`backend/schema.sql`. Highlights:

- **Enums** (native Postgres): `tour_kind` (single/multiStop), `stop_trigger_mode`
  (geofenced/manual), `tour_category` (the 10 cases), `tour_status`
  (draft/in_review/published/taken_down — forward-design, default `published`).
- **makers / tours / stops** tables, columns 1:1 with the models. **Stops are
  normalized** into their own table (not nested JSON) so makers can reorder/edit them
  later. Each table carries forward-design columns now (`status`, `user_id`,
  `created_at`/`updated_at`/`published_at`) so adding the maker platform won't alter them.
- **RLS:** anon role is read-only and sees only `published` tours (+ their stops/makers).
  Writes are service-role only until per-user policies arrive with the maker platform.

## Read-API (the seam)
`get_catalog()` — a Postgres function (exposed as a Supabase RPC) that returns
`{ "makers": [...], "tours": [ {...tour, "stops": [...] } ] }` with **camelCase keys
matching the Swift `Codable` names**. The app's only change is to point
`RemoteCatalogLoader.remoteURL` at this RPC (plus the `apikey`/bearer headers);
`ToursData` decoding is untouched. Runs as SECURITY INVOKER so RLS applies.

## Migration
`backend/seed_from_toursjson.py` reads `Resources/Tours.json` and emits idempotent
`insert … on conflict (id) do update` SQL for makers → tours → stops (FK order), in a
transaction. Re-runnable after catalog edits. Parity check: row counts must equal the
source file (currently **5 makers / 307 tours / 316 stops**). **Audio + image URLs are
copied as-is** — blob-storage hosting is a separate decision, not part of this step.

## Rollout (de-risked, two phases)
1. **DB as source of truth, app unchanged:** stand up schema + seed; a job exports
   `get_catalog()` → `Tours.json` → gh-pages (reusing the existing auto-publish path), so
   the live app keeps reading gh-pages with zero app risk while the DB is proven.
2. **App reads Supabase directly:** ship the `RemoteCatalogLoader` URL swap (code PR,
   `test_sim` + simulator review). gh-pages export can stay as a fallback mirror.

## Forward-designed tables (later steps, not built yet)
- **profiles** (1:1 with `auth.users`) + `makers.user_id` ownership — Sign in with Apple.
- **maker_applications** — the apply-to-create gate.
- **user_library** (`user_id`, `tour_id`, saved_at, downloaded_at, listened_seconds,
  last_listened_at, completed_at) — server sync of the local `LibraryStore`.
- **user_saved_makers**, **user_recent_searches**, **user_recently_viewed** — sync of the
  matching local stores.
- **purchases** (`user_id`, `tour_id`, price, store transaction id) — paid tours (IAP).
- **moderation_items** / **reports** — review queue + report-a-tour.
- **payout_accounts** — Stripe Connect for maker payouts.
- **analytics_events** — tour starts/completions for maker dashboards.

## Open decisions for later steps
- Server-side proximity (PostGIS) vs the current client-side `toursNearby` sort.
- Per-resource typed endpoints vs the single `get_catalog()` document as the app matures.
- Whether the gh-pages export mirror is retained long-term as an offline/fallback.

## Verification
See `backend/README.md` for the stand-up runbook and the parity / RPC-decode checks.

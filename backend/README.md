# Atlas backend (V2)

The catalog backend — Supabase (Postgres). This directory holds the schema and
the seed migration. It is **tooling + infrastructure-as-code**; nothing here
ships inside the iOS app.

- `schema.sql` — enums, tables (`makers`, `tours`, `stops`), indexes, RLS
  policies, and the `get_catalog()` RPC the app reads.
- `seed_from_toursjson.py` — generates idempotent seed SQL from the source
  catalog (`TRAVEL GUIDED TOUR/Resources/Tours.json`).

Design rationale, schema details, and the forward-designed maker-platform
tables live in [`../docs/backend-design.md`](../docs/backend-design.md).

## Status (2026-06-27)
**Project is LIVE.** Supabase project "Dozent" (free tier) stood up via the
dashboard; `schema.sql` → `accounts.sql` → `storage.sql` → `moderation.sql` all
applied via the SQL Editor; `get_catalog()` verified end-to-end with a one-row
smoke test (Empire State Building).

**Still pending:**
- **Full catalog seed** — load all ~370 tours (step 4 below). The one smoke-test
  row is in; the seed upserts by id so it'll absorb it. ~1 MB file → run via psql,
  not the browser.
- **App cutover** — point `RemoteCatalogLoader` at the RPC (Mac step). The app
  still reads gh-pages today, so nothing is blocked.

> Owner is non-technical on infra — see CLAUDE.md § Session workflow. Any Supabase
> guidance must be exact-copy-paste SQL + click-by-click dashboard steps.

## Stand-up runbook (when ready to build)
You only need a Supabase account at this point — the **free tier** is fine for
building/testing.

1. **Create a project** at supabase.com (free tier). Note the project URL and,
   from Project Settings → API, the **anon** key (public, client-safe) and the
   **service_role** key (secret — used only for seeding/admin, never shipped).
2. **Create the schema:** open the SQL Editor and run `schema.sql` (or
   `supabase db push` if using the CLI).
3. **Generate the seed:** from the repo root —
   ```bash
   python3 backend/seed_from_toursjson.py -o backend/seed.sql
   ```
   (Do not commit `seed.sql` — it's regenerated from `Tours.json`, which is the
   source of truth.)
4. **Load the seed:** run `seed.sql` in the SQL Editor, or
   `psql "$SUPABASE_DB_URL" -f backend/seed.sql`. The seed upserts by `id`, so
   it's safe to re-run after catalog changes.
5. **Verify parity** (counts must match the source catalog):
   ```sql
   select
     (select count(*) from makers) as makers,
     (select count(*) from tours)  as tours,
     (select count(*) from stops)  as stops;
   ```
   ```bash
   python3 -c "import json;d=json.load(open('TRAVEL GUIDED TOUR/Resources/Tours.json'));\
   print(len(d['makers']),'makers',len(d['tours']),'tours',sum(len(t['stops']) for t in d['tours']),'stops')"
   ```
6. **Test the read-API:** call the RPC and confirm it decodes like the app's
   `ToursData`:
   ```bash
   curl -s "https://<project>.supabase.co/rest/v1/rpc/get_catalog" \
     -H "apikey: <ANON_KEY>" -H "Content-Type: application/json" -d '{}' \
   | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d['makers']),'makers',len(d['tours']),'tours')"
   ```
   Diff it against the live gh-pages `Tours.json` — it should be semantically
   equivalent (modulo JSON key order and numeric formatting like `0` vs `0.00`).

## Switching the app over (later code PR, on a Mac)
Thanks to the Step-1 catalog seam, the app change is small:
- Add a `SupabaseCatalogFetcher: CatalogFetching` (or extend
  `URLSessionCatalogFetcher`) that sends the `apikey` + `Authorization: Bearer
  <anon key>` headers, and point `RemoteCatalogLoader.remoteURL` at the
  `get_catalog` RPC. `ToursData`, the models, views, the offline cache, and the
  bundled seed are all unchanged.
- Run `test_sim` + a simulator review before merge (it touches `Data/*.swift`).

De-risked rollout: first keep the live app on gh-pages while a job exports
`get_catalog()` → `Tours.json` → gh-pages (proves the DB end-to-end with zero
app change), then ship the app's URL swap. See the design doc.

## Notes
- The schema/seed can't be executed on the Linux web session (no Postgres) —
  run them against Supabase per the steps above.
- Audio + images are **not** migrated here; their gh-pages/R2 URLs are copied
  as-is into the rows. Blob-storage hosting is a separate decision.

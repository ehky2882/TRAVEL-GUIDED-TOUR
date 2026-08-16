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

**Full catalog seeded (2026-06-27):** all 5 makers / 370 tours / 396 stops loaded
via the SQL Editor (`seed_from_toursjson.py` output split into 4 browser-pasteable
parts), `select count(*)` verified 5/370/396. The DB now mirrors the gh-pages catalog.

**App cutover DONE (PR #255, shipped in TestFlight 1.0 (50)):** the app reads the
`get_catalog` RPC first, gh-pages as fallback mirror.

## Keeping the DB in sync — automated (PR #258-era)

Because Supabase is now the app's **primary** source, every `Tours.json` change
must reach the DB, not just gh-pages. This is automated by the `seed-supabase`
job in `.github/workflows/publish-catalog.yml`: on every push to `main` that
touches `Tours.json` it regenerates the seed (`seed_from_toursjson.py`) and runs
it against the DB with `psql`. It's **idempotent** (upsert by id) and
**transactional** (any bad row rolls the whole apply back). It runs in parallel
with the gh-pages publish and never blocks it.

> **✅ Verified live (2026-06-28).** The `SUPABASE_DB_URL` secret **is set** and the
> `Seed catalog into Supabase` job runs green on content merges — confirmed on the
> "South Bank Mile" merge (the *Apply seed to Supabase* step actually applied, ~71s,
> not a no-op skip), and the live DB matches `Tours.json` exactly (5 / 371 / 406).
> No setup action needed; the steps below are kept for reference / disaster recovery.

**Opt-in — the job no-ops until you add one repo secret (one-time, dashboard only):**

1. **Get the connection string** from Supabase → **Connect** (top bar) or
   **Settings → Database** → **Connection string** → choose the **Session pooler**
   tab (the direct connection is IPv6-only; GitHub runners are IPv4, so the
   *pooler* string is required). Copy the URI — it looks like:
   `postgresql://postgres.apkcihljybvuyuzpbnqd:[YOUR-PASSWORD]@aws-0-<region>.pooler.supabase.com:5432/postgres`
2. **Substitute the password** for `[YOUR-PASSWORD]` (Settings → Database →
   Database password → reset/reveal if you don't have it).
3. **Add it as a GitHub secret:** repo **Settings → Secrets and variables →
   Actions → New repository secret**, name **`SUPABASE_DB_URL`**, value = the
   full URI from step 2. (This is a write credential — keep it only here, never
   in the repo.)

Once the secret exists, merging any catalog change auto-syncs the DB. To force a
full resync anytime: Actions tab → **Publish catalog** → **Run workflow**.

**Limitation (intentional):** the upsert only adds/updates rows present in
`Tours.json` — it does **not** delete DB rows that were removed from the file.
This is deliberate: once makers create their own tours in V2, a "delete anything
not in Tours.json" reconciliation would wipe them. To retire an Atlas-curated
tour, take it down explicitly (`takedown_tour` / set `status`), don't just drop
it from the file.

**Manual fallback (if the secret isn't set):** rerun `seed_from_toursjson.py` and
paste the output into the SQL Editor (idempotent upsert), as during the initial seed.

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

## Paid tours (V2 Step 6, Phase 2) — `paid_tours.sql` + two Edge Functions

Design: `docs/paid-tours-design.md`. Phase 1 (the 10 IAP tier products in App
Store Connect) is already done. This is the backend half. **Owner runs three
things, in this order** — none of it affects the free catalog:

1. **SQL** — SQL Editor → paste **all** of `backend/paid_tours.sql` → Run.
   Expect *"Success. No rows returned."* It adds `tours.price_tier` (NULL =
   free, so every existing tour stays free), the `purchases` / `payouts` /
   `maker_payout_accounts` tables + RLS, the `maker_sales` + `maker_earnings`
   views, and rebuilds `get_catalog()` to emit `priceTier`. Idempotent — safe
   to re-run.
   Verify:
   ```sql
   select count(*) from public.purchases;                      -- 0
   select get_catalog() -> 'tours' -> 0 ? 'priceTier';          -- true
   ```
2. **App Store API key** — App Store Connect → Users and Access → Integrations
   → In-App Purchase → generate a key. **The `.p8` downloads once** — keep it
   safe. Note the Key ID and Issuer ID.
3. **Edge Functions** — deploy both from `backend/functions/`:
   | Function | Verify JWT | Why |
   |---|---|---|
   | `record-purchase` | **ON** | called by the signed-in app; the user's JWT identifies the buyer |
   | `appstore-notifications` | **OFF** | Apple posts here and carries no Supabase JWT |

   Both read the same four secrets (Edge Functions → Secrets, set once):
   `APPSTORE_IAP_KEY` (full `.p8` contents), `APPSTORE_IAP_KEY_ID`,
   `APPSTORE_ISSUER_ID`, `APPSTORE_BUNDLE_ID` (`com.ehky.TRAVEL-GUIDED-TOUR`).
   Then App Store Connect → the app → App Information → **App Store Server
   Notifications** → set the **Production and Sandbox** URLs to
   `https://<project>.supabase.co/functions/v1/appstore-notifications`
   (Version 2).

**Trust model worth knowing:** neither function trusts what the client (or a
POST claiming to be Apple) says happened. Each extracts only a transaction id,
then fetches the authoritative record from Apple's App Store Server API under
our signed key and records *that*. A forged request can't mint an entitlement
or fake a refund. `purchases.apple_transaction_id` is UNIQUE, so the app can
safely replay StoreKit history after a dead spot.

**The one check that can't come from Apple:** the tier products are reusable
across every paid tour, so Apple's receipt says *"someone paid $0.99"* but
never *which tour*. `record-purchase` therefore requires the tour's
`price_tier` to equal the tier actually bought (and refuses free tours) —
without it, a genuine cheap receipt re-sent with a different `tourId` would
unlock an expensive tour and under-credit its maker. If you edit that
function, keep that comparison.

**Who can see what:** buyers read their own `purchases` rows (the entitlement
check). Makers never see buyer identities — they read `maker_sales` /
`maker_earnings`, which omit `user_id`. `maker_payout_accounts` is read-only
to clients: `stripe_account_id` decides where money lands, and every signup
auto-creates a maker row, so a writable policy would let any session redirect
payouts. Its real write path is Stripe Express onboarding via the service
role (Phase 5).

**LIVE PRICING as of 2026-08-15** (owner-confirmed): **all 66 multi-stop walks
are `price_tier = 99` ($0.99)**, plus Empire State Building at 299 (the Phase 3
sandbox test tour). Everything else is NULL = free. ⚠️ **Price lives only in
this table** — not in `Tours.json`, not in git — so a change here leaves no
trace in the repo. Record any pricing change in CLAUDE.md § LIVE PRICING, and
re-derive the truth with:
```sql
select price_tier, kind, count(*) from public.tours
where price_tier is not null group by 1,2 order by 1;
```

**Pricing a tour** (until the Phase 4 maker UI ships, this is the manual path):
```sql
update public.tours set price_tier = 299 where id = '<tour-uuid>';  -- $2.99
update public.tours set price_tier = null where id = '<tour-uuid>'; -- back to free
```
Allowed values are the 10 ASC tiers: 99, 199, 299, 399, 499, 699, 899, 999,
1499, 1999. A tier outside that list is rejected by a CHECK constraint —
widening the menu means creating the ASC product first, then extending the
constraint in `paid_tours.sql`.

**`price_tier` survives content re-seeds.** `seed_from_toursjson.py`
deliberately omits it from both the column list and the upsert's `DO UPDATE`,
because price lives in the DB (maker-set), not in `Tours.json`. Don't add it.

## Notes
- The schema/seed can't be executed on the Linux web session (no Postgres) —
  run them against Supabase per the steps above.
- Audio + images are **not** migrated here; their gh-pages/R2 URLs are copied
  as-is into the rows. Blob-storage hosting is a separate decision.

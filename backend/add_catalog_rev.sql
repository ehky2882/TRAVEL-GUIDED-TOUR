-- Atlas — a monotonic revision on every catalog row.
--
-- 🔴 SAFE TO RE-RUN. Every statement is `if not exists`, and the column is
-- added WITH A DEFAULT, which PostgreSQL 11+ records as metadata only — it
-- does not rewrite the table. Applying this to the live database is cheap.
--
-- ⚠️ YOU DO NOT NEED TO PASTE THIS BY HAND. `seed_from_toursjson.py` emits the
-- same statements as its preamble, so the next content merge applies them
-- automatically. This file exists so the change is reviewable on its own and
-- so a database can be brought up to date without waiting for a seed. Running
-- both is harmless.
--
-- ---------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------
-- `docs/delta-catalog-fetch-design.md` § 6 Phase 0. A changed-since cursor
-- needs to name a point in the catalog's history exactly. `updated_at` cannot:
--
--   * it is a timestamp, so it moves backwards across a clock adjustment;
--   * every row written in one transaction shares `now()`, so "everything
--     after T" either includes a whole transaction or none of it, and two
--     seeds inside the same clock tick are indistinguishable;
--   * `stops` has no `updated_at` at all.
--
-- One sequence shared by all four tables fixes each of those. `rev` is
-- globally ordered across the whole catalog, so "everything above N" is exact
-- and a client only has to remember one number.
--
-- ⚠️ `refreshed_at` on `catalog_snapshot` stays exactly as it is. It is the
-- cheap public freshness token the app already polls (34 bytes) and it is not
-- replaced by this.
--
-- ⚠️ A DELETION bumps nothing — there is no row left to carry a rev. Anything
-- reading these columns to decide "did the catalog change" must also compare
-- row counts. The seed does exactly that; see `emit()`.

create sequence if not exists public.catalog_rev as bigint start 1;

-- Default 1 means every row that already exists reads as revision 1 without a
-- table rewrite, and a cursor of 0 therefore returns the entire catalog —
-- which is what a client with no cursor should get.
alter table public.tours  add column if not exists rev bigint not null default 1;
alter table public.makers add column if not exists rev bigint not null default 1;
alter table public.places add column if not exists rev bigint not null default 1;
alter table public.stops  add column if not exists rev bigint not null default 1;

-- Without these, `where rev > N` is a sequential scan of a table whose average
-- row is several kilobytes of text — which is the whole cost the cursor exists
-- to avoid.
create index if not exists tours_rev_idx  on public.tours  (rev);
create index if not exists makers_rev_idx on public.makers (rev);
create index if not exists places_rev_idx on public.places (rev);
create index if not exists stops_rev_idx  on public.stops  (rev);

-- Keep the sequence ahead of the backfilled default, so the first row actually
-- written by a seed is unambiguously newer than everything that predates this.
select setval('public.catalog_rev', greatest(
    (select last_value from public.catalog_rev),
    coalesce((select max(rev) from public.tours),  1),
    coalesce((select max(rev) from public.makers), 1),
    coalesce((select max(rev) from public.places), 1),
    coalesce((select max(rev) from public.stops),  1)));

comment on sequence public.catalog_rev is
    'Monotonic catalog revision. Bumped by seed_from_toursjson.py on rows that '
    'actually changed. See docs/delta-catalog-fetch-design.md Phase 0.';

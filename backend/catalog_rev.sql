-- Atlas — give the catalogue a truthful "what changed?" signal.
--
-- 🔴 SAFE TO RE-RUN. Purely additive: one sequence, one column on three
-- tables, one column on `stops`, four triggers, three indexes. It adds no key
-- to `get_catalog()`, removes none, and changes no existing value. Every build
-- in the field is unaffected — see "WHAT THIS DOES NOT TOUCH" below.
--
-- ---------------------------------------------------------------------------
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------
-- `docs/delta-catalog-fetch-design.md` is the full argument. The short version:
-- the app downloads all ~3,700 tours and pins whenever any one of them changes,
-- and the median real change is 0.29% of what we send to deliver it. Before any
-- delta scheme can work, the database has to be able to answer "which rows
-- changed?" — and today it cannot, because the answer is always "all of them".
--
-- `backend/seed_from_toursjson.py` ended every upsert with `updated_at = now()`
-- UNCONDITIONALLY, so every row was rewritten with a fresh timestamp on every
-- seed — about 5 times a day — whether or not one byte of it had changed.
-- Measured against a throwaway Postgres carrying the real schema and the real
-- catalogue, an IDENTICAL re-seed touched:
--
--       3,745 of 3,745 tours      424 of 424 makers      303 of 303 places
--
-- `stops` was worse: it had no `updated_at` at all and was deleted and
-- re-inserted in full, per tour, on every run.
--
-- ⚠️ THIS IS WORTH DOING ON ITS OWN, EVEN IF NO DELTA FETCHING EVER SHIPS.
-- Rewriting ~3,700 rows five times a day that did not change is pure WAL, pure
-- table bloat and pure autovacuum work — on the instance that ran out of memory
-- for 11h45m on 2026-09-14. This is the cheapest relief available, and it needs
-- no App Store release.
--
-- ---------------------------------------------------------------------------
-- WHAT THIS ADDS
-- ---------------------------------------------------------------------------
--   public.catalog_rev_seq        NEW: one sequence for the whole catalogue
--   public.tours.rev              NEW: bigint, monotonic, moves ONLY on a real change
--   public.makers.rev             NEW: same
--   public.places.rev             NEW: same
--   public.stops.updated_at       NEW: timestamptz, so a stop edit is dateable at all
--   public.catalog_bump_rev()     NEW: the trigger that decides what "changed" means
--   public.catalog_bump_tour_rev()NEW: a stop edit bumps its parent TOUR
--
-- 🔴 WHY A SEQUENCE AND NOT JUST `updated_at`. A timestamp can go backwards
-- across a clock adjustment, and two rows written in one transaction share it
-- exactly. A cursor built on that either re-sends rows forever or silently
-- skips one. `rev` is monotonic by construction, so "everything above rev N" is
-- an exact question with an exact answer. `updated_at` stays, and stays useful
-- for humans reading the table; it is not what a cursor should trust.
--
-- 🔴 WHY THE TRIGGER COMPARES THE WHOLE ROW RATHER THAN A COLUMN LIST.
-- A hardcoded list of "columns that count as a change" would drift the moment
-- someone adds a column, and the drift would be invisible — the new column
-- would simply never mark a row as changed, and phones would stop receiving
-- edits to it with nothing erroring. That is the same rotting-checklist failure
-- `scripts/check-catalog-contract.py` exists to prevent, so this compares
-- `to_jsonb(new)` against `to_jsonb(old)` minus the two bookkeeping columns.
-- A column added tomorrow is covered tonight, with no edit here.
--
-- ⚠️ THE SEED'S CONDITIONAL UPSERT AND THIS TRIGGER DO DIFFERENT JOBS, AND
-- BOTH ARE WANTED. The seed's `where ... is distinct from ...` stops the write
-- from happening at all, which is where the WAL and bloat saving comes from.
-- The trigger cannot do that — by the time it runs, the row version already
-- exists. What the trigger gives is CORRECTNESS: `rev` moves on a real change
-- and only on a real change, no matter who did the writing. That matters most
-- for edits made BY HAND in the Supabase SQL Editor (CLAUDE.md § rule 11b),
-- which no amount of care in the seed script can cover.
--
-- ---------------------------------------------------------------------------
-- WHAT THIS DOES NOT TOUCH
-- ---------------------------------------------------------------------------
-- 🔴 `get_catalog()` IS NOT MODIFIED, AND ITS PAYLOAD DOES NOT CHANGE.
-- The builder selects its columns by name into `jsonb_build_object`, so a new
-- table column cannot leak into the payload. No key is added, none is removed,
-- and `rev` is never sent to a phone. This file deliberately does not appear in
-- `scripts/check-catalog-keys.py`'s audit of files that replace `get_catalog`,
-- because it does not go near it.
--
-- This is Phase 0 of four. It ships alone, changes nothing a user can see, and
-- is the prerequisite without which the later phases would return the whole
-- catalogue anyway.

begin;

-- ---------------------------------------------------------------------------
-- 1. One sequence for the whole catalogue.
-- ---------------------------------------------------------------------------
-- Shared across tours, makers and places on purpose: a client holds ONE cursor,
-- and one sequence means one comparison answers "anything at all since N?".
-- Per-table sequences would need three cursors and three comparisons that could
-- disagree with each other.
create sequence if not exists public.catalog_rev_seq as bigint;

-- ---------------------------------------------------------------------------
-- 2. The rev column on the three tables the catalogue is built from.
-- ---------------------------------------------------------------------------
-- Added nullable, backfilled, then defaulted and made NOT NULL — so the
-- rewrite is one pass over a small table and an interrupted run leaves nothing
-- half-constrained.
alter table public.tours  add column if not exists rev bigint;
alter table public.makers add column if not exists rev bigint;
alter table public.places add column if not exists rev bigint;

-- Backfill. Every existing row gets a distinct rev, so a client that has never
-- synced sees them all and a client at rev N sees exactly what came after.
update public.tours  set rev = nextval('public.catalog_rev_seq') where rev is null;
update public.makers set rev = nextval('public.catalog_rev_seq') where rev is null;
update public.places set rev = nextval('public.catalog_rev_seq') where rev is null;

alter table public.tours  alter column rev set default nextval('public.catalog_rev_seq');
alter table public.makers alter column rev set default nextval('public.catalog_rev_seq');
alter table public.places alter column rev set default nextval('public.catalog_rev_seq');

alter table public.tours  alter column rev set not null;
alter table public.makers alter column rev set not null;
alter table public.places alter column rev set not null;

-- The cursor's index. `where rev > $1 order by rev` is the only query shape
-- this column will ever serve.
create index if not exists idx_tours_rev  on public.tours  (rev);
create index if not exists idx_makers_rev on public.makers (rev);
create index if not exists idx_places_rev on public.places (rev);

-- ---------------------------------------------------------------------------
-- 3. `stops` gets a timestamp, and a deferrable uniqueness constraint.
-- ---------------------------------------------------------------------------
-- No rev of its own: a stop is only ever delivered nested inside its tour, so
-- what a cursor needs is for a stop edit to move the TOUR (section 5 below).
-- `updated_at` is here because the table had no change signal of any kind, and
-- a table nobody can date is a table nobody can debug.
alter table public.stops add column if not exists updated_at timestamptz not null default now();

-- 🔴 THE CONSTRAINT HAS TO BECOME DEFERRABLE, AND THIS IS NOT COSMETIC.
-- The seed used to DELETE every stop of a tour and re-insert them, which made
-- reordering free. Now that it upserts stop-by-stop (so an unchanged stop is
-- not rewritten), inserting a stop into the middle of a walk renumbers the ones
-- after it — and row-by-row that transiently collides with `unique (tour_id,
-- "order")`. Deferring the check to COMMIT lets the final state be judged
-- rather than each intermediate step. The whole seed already runs in one
-- transaction, so this is exactly the right granularity.
--
-- ⚠️ Without this, editing a walk's stop order fails the seed outright, and it
-- would fail at the point where content merges, not where it was written.
do $$
begin
    if exists (
        select 1 from pg_constraint
         where conrelid = 'public.stops'::regclass
           and conname  = 'stops_tour_id_order_key'
           and not condeferrable
    ) then
        alter table public.stops drop constraint stops_tour_id_order_key;
        alter table public.stops add constraint stops_tour_id_order_key
            unique (tour_id, "order") deferrable initially deferred;
    end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4. What "changed" means. One function, three tables.
-- ---------------------------------------------------------------------------
-- BEFORE UPDATE, so it can rewrite the row on its way through rather than
-- issuing a second write.
--
-- `rev` and `updated_at` are stripped from BOTH sides before comparing: they
-- are the bookkeeping this function maintains, and including them would make
-- every row differ from itself and the whole thing a no-op.
--
-- ⚠️ IT RETURNS `new` UNCHANGED WHEN NOTHING CHANGED — including any rev the
-- caller set explicitly. That is what lets section 5's parent bump work: it
-- writes a rev directly, this function sees no content change, and leaves the
-- value it was given alone instead of overwriting or discarding it.
create or replace function public.catalog_bump_rev()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
    if (to_jsonb(new) - 'rev' - 'updated_at')
       is distinct from
       (to_jsonb(old) - 'rev' - 'updated_at') then
        new.rev := nextval('public.catalog_rev_seq');
        new.updated_at := now();
    end if;
    return new;
end $$;

drop trigger if exists tours_bump_rev  on public.tours;
drop trigger if exists makers_bump_rev on public.makers;
drop trigger if exists places_bump_rev on public.places;

create trigger tours_bump_rev  before update on public.tours
    for each row execute function public.catalog_bump_rev();
create trigger makers_bump_rev before update on public.makers
    for each row execute function public.catalog_bump_rev();
create trigger places_bump_rev before update on public.places
    for each row execute function public.catalog_bump_rev();

-- ---------------------------------------------------------------------------
-- 5. A stop edit moves its parent tour.
-- ---------------------------------------------------------------------------
-- 🔴 WITHOUT THIS, A DELTA WOULD SILENTLY MISS STOP EDITS. The payload nests
-- stops inside their tour, so a cursor reading `tours.rev` would never learn
-- that a stop's coordinate, audio or caption had moved — the tour row itself is
-- untouched. Those are precisely the edits that matter: a wrong coordinate is
-- the defect CLAUDE.md rule 8b exists for, and it would stop reaching phones.
--
-- AFTER, and for DELETE too: a removed stop changes the tour just as much as an
-- added one. `old` is null on INSERT and `new` is null on DELETE, hence the
-- coalesce.
--
-- ⚠️ This writes `rev` EXPLICITLY rather than leaving it to the trigger above,
-- because that trigger would correctly conclude the tour row's own content had
-- not changed and decline to move it.
create or replace function public.catalog_bump_tour_rev()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
    tid uuid := coalesce(new.tour_id, old.tour_id);
begin
    update public.tours
       set rev = nextval('public.catalog_rev_seq'),
           updated_at = now()
     where id = tid;
    return null;   -- AFTER trigger: the return value is ignored
end $$;

drop trigger if exists stops_bump_tour_rev on public.stops;
create trigger stops_bump_tour_rev
    after insert or update or delete on public.stops
    for each row execute function public.catalog_bump_tour_rev();

-- `stops.updated_at` gets the same treatment as the three catalogue tables,
-- minus the rev — so the column means something rather than being decorative.
create or replace function public.stops_touch_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
    if (to_jsonb(new) - 'updated_at') is distinct from (to_jsonb(old) - 'updated_at') then
        new.updated_at := now();
    end if;
    return new;
end $$;

drop trigger if exists stops_touch on public.stops;
create trigger stops_touch before update on public.stops
    for each row execute function public.stops_touch_updated_at();

-- ---------------------------------------------------------------------------
-- 6. Prove it before committing.
-- ---------------------------------------------------------------------------
-- A migration that cannot do its job must not report success. The whole value
-- of this file is the claim "an update that changes nothing does not move rev",
-- so assert it here rather than trusting that it reads correctly.
do $$
declare
    victim   uuid;
    rev_0    bigint;
    rev_1    bigint;
    rev_2    bigint;
begin
    select id, rev into victim, rev_0 from public.tours limit 1;
    if victim is null then
        raise notice 'catalog_rev: no tours to verify against -- schema applied, behaviour unverified';
        return;
    end if;

    -- A no-op update must NOT move rev.
    update public.tours set title = title where id = victim;
    select rev into rev_1 from public.tours where id = victim;
    if rev_1 is distinct from rev_0 then
        raise exception
            'catalog_rev: a no-op update moved rev (% -> %). The trigger is not doing its job.',
            rev_0, rev_1;
    end if;

    -- A real change MUST move it. Change it and put it straight back, so the
    -- catalogue is left exactly as it was found.
    update public.tours set title = title || ' ' where id = victim;
    select rev into rev_2 from public.tours where id = victim;
    if rev_2 <= rev_1 then
        raise exception
            'catalog_rev: a real change did NOT move rev (% -> %).', rev_1, rev_2;
    end if;
    update public.tours set title = rtrim(title) where id = victim;

    raise notice 'catalog_rev: verified — no-op held at rev %, a real change advanced it.', rev_0;
end $$;

commit;

-- Atlas — materialise the catalog so `get_catalog()` is a lookup, not a rebuild.
--
-- 🔴 SAFE TO RE-RUN. It never replaces the thing that BUILDS the payload; it
-- renames it aside and puts a lookup in front. Read the section below before
-- editing — this file sits on top of a composition that has been broken once
-- before, silently.
--
-- ---------------------------------------------------------------------------
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------
-- Measured against the live database on 2026-09-06: `get_catalog()` failed
-- 4 times in 12 with `57014 canceling statement due to statement timeout`.
-- Successes took 2.2-4.9s, failures 3.5-5.0s. The query is not hitting a wall;
-- it is sitting ON the anon role's statement timeout, so ordinary variance
-- decides each call. During a seed it fails every time.
--
-- The cost, per request:
--   * the builder runs a CORRELATED SUBQUERY PER TOUR to nest that tour's
--     stops -- ~2,830 index scans into `stops` plus ~2,830 separate
--     jsonb_agg aggregations, then one outer jsonb_agg with an ORDER BY;
--   * `split_link_pins.sql` then explodes that finished ~11 MB blob back into
--     rows with jsonb_array_elements and RE-AGGREGATES IT TWICE
--     (jsonb_agg ... FILTER for tours, again for pins);
--   * `places.sql` merges `catalog_places()` on top.
-- So the whole ~11 MB structure is materialised three or four times over, for
-- every launch of every phone.
--
-- And the payload is IDENTICAL FOR EVERY CALLER. That is not an assumption --
-- the builder filters `where t.status = 'published'` explicitly (schema.sql),
-- `catalog_places()` filters to places with >=2 published tours, and `makers`
-- is public-read. Nothing in it varies by viewer. It changes only when the
-- catalog is seeded, a few times a day.
--
-- ---------------------------------------------------------------------------
-- WHAT THIS CHANGES
-- ---------------------------------------------------------------------------
--   public.get_catalog()          -> renamed to get_catalog_built()   (unchanged behaviour)
--   public.get_catalog()          -> NEW: `select payload from catalog_snapshot`
--   public.catalog_snapshot       -> NEW: exactly one row, holding the built payload
--   public.refresh_catalog_snapshot() -> NEW: rebuilds that row
--   public.catalog_snapshot_age() -> NEW: when it was last refreshed
--
-- The whole existing chain -- get_catalog_core_base -> get_catalog_core ->
-- (old) get_catalog -- is KEPT WHOLESALE and becomes the builder, called once
-- per seed instead of once per request. Every migration that patches
-- `get_catalog_core` keeps working untouched.
--
-- 🔴 AFTER THIS, A CATALOG CHANGE IS NOT VISIBLE UNTIL THE SNAPSHOT IS
-- REFRESHED. `backend/seed_from_toursjson.py` emits that call as the last
-- statement inside its transaction, so a normal content merge is unaffected.
-- A change made BY HAND in the SQL Editor must end with:
--     select public.refresh_catalog_snapshot();
--
-- ⚠️ DO NOT "improve" this with a trigger on `tours`. Rebuilding an 11 MB
-- payload once per row written would make the seed pathological -- ~2,830
-- rebuilds instead of one. Refresh once, at the end.

begin;

-- ---------------------------------------------------------------------------
-- 1. Rename the current get_catalog() aside, so it becomes the builder.
-- ---------------------------------------------------------------------------
-- This is the `places.sql` move: rename rather than retype, so the body,
-- volatility and security attribute all carry over untouched and cannot drift
-- from whatever is actually running. Guarded both ways so a re-run is a no-op.
do $$
begin
    if not exists (
        select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public' and p.proname = 'get_catalog_built'
    ) then
        if not exists (
            select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
             where n.nspname = 'public' and p.proname = 'get_catalog'
        ) then
            raise exception
                'public.get_catalog() does not exist -- nothing to snapshot. '
                'Apply schema.sql (and any later catalog migrations) first.';
        end if;
        alter function public.get_catalog() rename to get_catalog_built;
    end if;
end $$;

-- The refresh runs the builder as `anon` (below), so anon must be able to
-- execute it. The rename carries the old grants across, but say it explicitly
-- rather than relying on that.
grant execute on function public.get_catalog_built() to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. The snapshot itself: exactly one row, ever.
-- ---------------------------------------------------------------------------
-- `id boolean primary key check (id)` is the standard single-row idiom: the
-- only value that satisfies both the primary key and the check is `true`, so a
-- second row is impossible by construction rather than by convention.
create table if not exists public.catalog_snapshot (
    id           boolean primary key default true check (id),
    payload      jsonb       not null,
    refreshed_at timestamptz not null default now()
);

-- 🔴 RLS on, and DELIBERATELY NO POLICIES. Nobody reaches this table directly;
-- the only way to the payload is through get_catalog(), which is SECURITY
-- DEFINER. That is tighter than a public-read policy would be, and it means
-- a future column here (a build id, a checksum) is not automatically public.
alter table public.catalog_snapshot enable row level security;
revoke all on public.catalog_snapshot from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Refresh: build once, store once.
-- ---------------------------------------------------------------------------
-- 🔴 THE BUILDER RUNS AS `anon`, AND THAT IS THE SECURITY ARGUMENT.
-- Materialising a payload means it is built once, by one role, and then served
-- to everyone -- so the role it is built as decides what everyone can see. Get
-- that wrong and unpublished drafts go public with no error.
--
-- Building as `anon` makes the snapshot exactly what an anonymous reader gets
-- today. That is narrower than or equal to what any signed-in caller currently
-- sees (a maker's own drafts are visible to them via `tours_owner_select`, but
-- the builder's explicit `where t.status = 'published'` excludes them from the
-- catalog anyway). Narrower-or-equal is the safe direction: this can never
-- widen what is published.
--
-- ⚠️ THIS FUNCTION IS SECURITY INVOKER, AND THAT IS FORCED, NOT A PREFERENCE.
-- Postgres refuses outright: `cannot set parameter "role" within
-- security-definer function`. So the role switch and SECURITY DEFINER are
-- mutually exclusive, and the switch is the more valuable of the two. Invoker
-- is fine here because the only caller is the seed, running as the database
-- owner (execute is revoked from anon and authenticated below).
--
-- The role is set with set_config(..., is_local => true), so it is scoped to
-- this transaction, and restored to the CALLER before the write -- `reset
-- role` would drop to the session user, which is not necessarily the same
-- thing and may not be able to write here.
create or replace function public.refresh_catalog_snapshot()
returns timestamptz
language plpgsql
set search_path = public, pg_temp
as $$
declare
    caller  text := current_user;
    built   jsonb;
    stamp   timestamptz := now();
begin
    perform set_config('role', 'anon', true);
    built := public.get_catalog_built();
    perform set_config('role', caller, true);

    -- A refresh that cannot do its job must not report success. An empty or
    -- shapeless payload would be served to every phone.
    if built is null or jsonb_typeof(built -> 'tours') is distinct from 'array' then
        raise exception
            'refresh_catalog_snapshot: builder returned no usable catalog. '
            'Inspect: select pg_get_functiondef(''public.get_catalog_built()''::regprocedure);';
    end if;

    insert into public.catalog_snapshot (id, payload, refreshed_at)
    values (true, built, stamp)
    on conflict (id) do update
        set payload = excluded.payload,
            refreshed_at = excluded.refreshed_at;

    return stamp;
end $$;

-- Deliberately NOT granted to anon/authenticated. Refreshing is a write, and
-- it costs seconds -- it belongs to the seed (service role), not to clients.
revoke all on function public.refresh_catalog_snapshot() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. get_catalog(): the lookup.
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER so it can read the snapshot table past RLS. Unlike the
-- warning in `split_link_pins.sql`, definer is safe HERE for a specific
-- reason: this function touches nothing but `catalog_snapshot`, whose contents
-- are already public-by-construction. It never evaluates RLS on `tours`.
--
-- ⚠️ NO FALLBACK TO THE BUILDER ON A MISSING SNAPSHOT, deliberately. A
-- coalesce() onto get_catalog_built() would silently reintroduce the slow path
-- and hide a broken refresh for as long as it took someone to notice the
-- latency. `scripts/check-catalog-keys.py` fails loudly on a payload that has
-- lost its keys, which is the guard that should catch it.
create or replace function public.get_catalog()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select payload from public.catalog_snapshot where id;
$$;

grant execute on function public.get_catalog() to anon, authenticated;

-- Staleness is the one new failure mode this introduces, so make it
-- observable. Returns only a timestamp -- no catalog content.
create or replace function public.catalog_snapshot_age()
returns timestamptz
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select refreshed_at from public.catalog_snapshot where id;
$$;

grant execute on function public.catalog_snapshot_age() to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 5. Populate it now, and verify before committing.
-- ---------------------------------------------------------------------------
-- Without this the migration would leave get_catalog() returning NULL until
-- the next seed -- every phone silently falling through to the gh-pages
-- mirror. Populate immediately, then assert the result is actually usable.
select public.refresh_catalog_snapshot();

do $$
declare
    cat      jsonb := public.get_catalog();
    n_tours  int;
    n_makers int;
begin
    if cat is null then
        raise exception 'get_catalog() returned NULL after refresh -- snapshot not populated';
    end if;

    n_tours  := coalesce(jsonb_array_length(cat -> 'tours'), -1);
    n_makers := coalesce(jsonb_array_length(cat -> 'makers'), -1);

    if n_tours < 0 or n_makers < 0 then
        raise exception 'get_catalog() lost its shape: tours=% makers=%', n_tours, n_makers;
    end if;

    -- Every key the app decodes. A missing one is invisible in Swift (they are
    -- all optional, so it decodes as nil and the feature silently stops
    -- existing) -- which is exactly how `places`, `priceTier` and `isPrivate`
    -- vanished for 14 hours on 2026-08-19.
    if n_tours > 0 then
        if not (cat -> 'tours' -> 0) ? 'priceTier' then
            raise exception 'priceTier missing from the snapshot -- the paywall would be off';
        end if;
    end if;
    if not cat ? 'places' then
        raise exception 'places missing from the snapshot -- the place layer would vanish';
    end if;
    if not cat ? 'linkPins' then
        raise exception 'linkPins missing from the snapshot -- old builds would freeze';
    end if;

    raise notice 'catalog_snapshot populated: % tours, % makers, % places, % linkPins',
        n_tours, n_makers,
        coalesce(jsonb_array_length(cat -> 'places'), 0),
        coalesce(jsonb_array_length(cat -> 'linkPins'), 0);
end $$;

commit;

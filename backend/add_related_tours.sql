-- add_related_tours.sql
--
-- Migration: two keys, one paste.
--
--   relatedTourIds   the "More like this" neighbours of a tour, as an array
--                    of tour ids. Generated offline by
--                    `scripts/build-embeddings.py --write-related` and shipped
--                    in the catalogue, because the whole point of the feature
--                    is that THE PHONE RUNS NO MODEL. Same-city matches lead,
--                    then cross-city fills.
--
--   createdAt        the EDITORIAL date a tour entered the catalogue, which
--                    four shipped sort controls have been reading as nil on
--                    every real phone since #600/#601: Newest/Oldest on the
--                    maker page, and date ordering on places and lists. They
--                    render, they are tappable, and they do nothing.
--
--
-- 🔴 `createdAt` IS SERVED FROM `authored_on`, **NOT** FROM `created_at`.
--
-- This is the trap this file exists to avoid, and it is the reason the gap sat
-- open rather than being closed with one line. `public.tours.created_at` is
-- `timestamptz not null default now()` — an AUDIT column recording when the
-- row was written. Every row in it holds the moment of a seed run, not the day
-- the tour was authored. Serving it as `createdAt` would light all four sort
-- controls up and order them by seed sequence: fixed-looking, and wrong, which
-- is strictly worse than the visible nothing they do today.
--
-- So the authored date gets its own column, `authored_on date`, seeded from
-- `Tours.json` by `seed_from_toursjson.py`. It is NULLABLE on purpose: 36 of
-- the catalogue's tours genuinely have no authored date, and they must sort
-- last rather than be handed a fabricated one. `created_at` is left entirely
-- alone and keeps meaning what it has always meant.
--
--
-- 🔴 THE LIVE CATALOG RPC IS THREE FUNCTIONS COMPOSED, NOT ONE
--
--     get_catalog()            definer wrapper, adds { places: ... }
--       -> get_catalog_core()  invoker, lifts kind='link' into linkPins
--         -> get_catalog_core_base()   <- THE TOUR KEYS LIVE HERE
--
-- `split_link_pins.sql` renamed the old `get_catalog_core` to
-- `get_catalog_core_base` and wrapped it. **`add_video_role.sql`'s finder
-- predates that rename and searches only ('get_catalog_core','get_catalog') —
-- copying it verbatim finds nothing and raises.** The finder below adds the
-- new name. It fails closed, so the cost of forgetting is a rolled-back
-- transaction rather than a silent regression.
--
-- 🔴 DO NOT model a catalog migration on `add_country.sql`. It carries its own
-- banner: it does `create or replace function public.get_catalog()` with a
-- full inlined body, which severs the wrapper and silently drops every place,
-- `priceTier` and `isPrivate`. That is a real outage this repo has already had
-- (~14 hours, 2026-08-19). PATCH the core; never replace the wrapper.
--
-- 🔴 RUN THIS **BEFORE** THE PR MERGES, NOT AFTER.
--
-- `seed_from_toursjson.py` now writes `related_tour_ids` and `authored_on` in
-- its tours insert, and `publish-catalog.yml` runs that seed under
-- `ON_ERROR_STOP=1` inside a single transaction. So on a database without
-- these columns the WHOLE seed aborts and rolls back, and every content merge
-- stops reaching Supabase until this file has been pasted. It fails loudly
-- (red CI) rather than silently, but it still blocks all content.
--
-- Applying this early is safe and costs nothing: until a re-seed runs, both
-- new columns are NULL for every row, both keys are emitted as null, and the
-- app decodes them as nil — which is exactly what it does today.
--
-- 🔴 THE `refresh_catalog_snapshot()` AT THE END IS LOAD-BEARING, AND LEAVING IT
-- OFF IS EXACTLY THE FAILURE THIS FILE ALREADY CAUSED ONCE (2026-09-15).
--
-- `get_catalog()` is no longer a live composition. Since `catalog_snapshot.sql`
-- it is `select payload from catalog_snapshot` — a lookup at a PRE-BUILT row —
-- and the whole chain below it is kept as the *builder*, run once per seed
-- instead of once per request (the live build was timing out: 4 calls in 12
-- failed with 57014). So patching the builder changes NOTHING a phone can see
-- until the snapshot is rebuilt.
--
-- The first run of this file did exactly that: it patched correctly, printed
-- "Success. No rows returned.", and the live RPC went on serving neither key
-- for another 25 minutes. **A correctly-applied patch is not evidence either.**
-- Verify with `catalog_snapshot_age()` (34 bytes) and the contract checker.
--
-- Idempotent: safe to re-run. Each block returns early if its key is already
-- emitted, and both `alter table` statements are `if not exists`.
--
-- AFTER RUNNING, VERIFY AGAINST THE LIVE RPC — not against "Success. No rows
-- returned.", which a severed function also prints:
--
--     python3 scripts/check-catalog-keys.py
--     python3 scripts/check-catalog-contract.py

begin;

alter table public.tours
    add column if not exists related_tour_ids text[];

alter table public.tours
    add column if not exists authored_on date;


-- 1. relatedTourIds ----------------------------------------------------------

do $migration$
declare
    target   regprocedure;
    src      text;
    patched  text;
begin
    select p.oid::regprocedure
      into target
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in ('get_catalog_core_base', 'get_catalog_core', 'get_catalog')
       and pg_get_functiondef(p.oid) like '%''country''%'
     order by (p.proname = 'get_catalog_core_base') desc,
              (p.proname = 'get_catalog_core') desc
     limit 1;

    if target is null then
        raise exception
            'no catalog function emits country - cannot place relatedTourIds beside it. '
            'Inspect: select proname from pg_proc p join pg_namespace n on n.oid = '
            'p.pronamespace where n.nspname = ''public'' and proname like ''%%catalog%%'';';
    end if;

    src := pg_get_functiondef(target);

    if src like '%relatedTourIds%' then
        raise notice '% already emits relatedTourIds - nothing to patch.', target;
    else
        -- Insert beside `country`, capturing the table alias out of the
        -- existing expression rather than assuming `t.`. Whitespace-
        -- independent, so however the live body happens to be formatted does
        -- not matter.
        patched := regexp_replace(
            src,
            '(''country''\s*,\s*(\w+)\.country\s*,)',
            E'\\1\n          ''relatedTourIds'',      to_jsonb(\\2.related_tour_ids),'
        );

        if patched = src then
            raise exception
                'found % but could not parse its country expression - refusing to guess. '
                'Read it with: select pg_get_functiondef(''%''::regprocedure);', target, target;
        end if;

        execute patched;

        if pg_get_functiondef(target) not like '%relatedTourIds%' then
            raise exception '% still does not emit relatedTourIds after patching.', target;
        end if;

        raise notice '% now emits relatedTourIds.', target;
    end if;
end
$migration$;


-- 2. createdAt ---------------------------------------------------------------

do $migration$
declare
    target   regprocedure;
    src      text;
    patched  text;
begin
    select p.oid::regprocedure
      into target
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in ('get_catalog_core_base', 'get_catalog_core', 'get_catalog')
       and pg_get_functiondef(p.oid) like '%''country''%'
     order by (p.proname = 'get_catalog_core_base') desc,
              (p.proname = 'get_catalog_core') desc
     limit 1;

    if target is null then
        raise exception 'no catalog function emits country - cannot place createdAt beside it.';
    end if;

    src := pg_get_functiondef(target);

    if src like '%''createdAt''%' then
        raise notice '% already emits createdAt - nothing to patch.', target;
    else
        -- `to_char`, not `to_jsonb`, deliberately. The app decodes `createdAt`
        -- as an ISO "YYYY-MM-DD" STRING and sorts it by plain lexicographic
        -- compare (see Tour.createdAt). A bare date rendered through the type's
        -- own output function follows the session's DateStyle, so a database
        -- set to anything but ISO would emit "19-08-2026" and the sort would
        -- silently order by day-of-month. NULL survives `to_char` as NULL.
        patched := regexp_replace(
            src,
            '(''country''\s*,\s*(\w+)\.country\s*,)',
            E'\\1\n          ''createdAt'',           to_char(\\2.authored_on, ''YYYY-MM-DD''),'
        );

        if patched = src then
            raise exception
                'found % but could not parse its country expression - refusing to guess.', target;
        end if;

        execute patched;

        if pg_get_functiondef(target) not like '%''createdAt''%' then
            raise exception '% still does not emit createdAt after patching.', target;
        end if;

        raise notice '% now emits createdAt.', target;
    end if;
end
$migration$;

commit;


-- 🔴 Without this the change is invisible to every phone: `get_catalog()`
-- serves a stored snapshot, so the two new keys do not appear until it is
-- rebuilt. Both come back NULL on every tour until a catalogue re-seed fills
-- the columns, which is correct — the keys exist, the values do not yet.
select public.refresh_catalog_snapshot();

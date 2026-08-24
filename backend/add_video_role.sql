-- add_video_role.sql
--
-- Migration: teach the catalog what a tour's video IS.
--
-- Adds a `video_role text` column to `public.tours` and adds a `videoRole`
-- key to whichever catalog function emits the tour keys.
--
--   NULL / 'gallery'  the clip is extra - b-roll, a moving photograph beside
--                     the still ones. It plays on its own and, if it has
--                     sound, borrows the narration and hands it straight
--                     back. Every video in the catalogue today, and what any
--                     tour without the key keeps doing.
--
--   'narration'       the clip IS the tour. Play, pause or scrub either the
--                     play bar or the picture and both move together. The
--                     AUDIO is the clock and the video is muted.
--
-- Owner decision, 2026-08-24. Do NOT infer this from the data - the tempting
-- rule (single stop, clip has sound, durations match) breaks b-roll the first
-- time a clip happens to be the length of its narration, and it fails
-- silently.
--
--
-- 🔴 THE LIVE CATALOG RPC IS A COMPOSITION, NOT ONE FUNCTION
--
--     get_catalog() = get_catalog_core() || { places: catalog_places() }
--
-- The tour keys live in `get_catalog_core()`. `get_catalog()` itself is three
-- lines. Whoever added places split it exactly so that changing the tour
-- payload would not mean rebuilding everything - and this migration is the
-- case that split was for.
--
-- Two earlier drafts of this file got that wrong, and the wrongness is worth
-- recording because it nearly shipped:
--
--   1. The first followed the `add_country.sql` convention and lifted a full
--      `create or replace` body from `schema.sql` "so the two cannot drift".
--      schema.sql is STALE. That draft would have silently dropped **all 25
--      places, priceTier (every paid tour's price) and isPrivate (private
--      accounts)** - three shipped features, from one paste, no error.
--
--   2. The second patched the live definition instead of replacing it, which
--      was right, but searched `get_catalog()` for `videoURLs` - which is not
--      there, because it is in the core. Its guard fired and rolled back
--      rather than doing something arbitrary, which is the only reason this
--      is a story about two drafts and not about an outage.
--
-- ⚠️ So: to change what the catalog emits, PATCH the function that actually
-- holds the key, and REFUSE if you cannot find it. Never paste a whole
-- `create or replace` from a file in this repo at the live database - no file
-- here matches what is running.
--
--
-- Safe to re-run: `add column if not exists`, and the patch is skipped when
-- the key is already present. Run once in the Supabase SQL Editor (project
-- "Dozent"). Expect "Success. No rows returned." Every existing tour gets
-- NULL, which the app reads as `gallery` - nothing changes until a tour says
-- otherwise.

begin;

alter table public.tours
    add column if not exists video_role text;

do $migration$
declare
    target   regprocedure;
    src      text;
    patched  text;
begin
    -- Find whichever catalog function actually emits the tour keys, rather
    -- than assuming which one it is. Today that is get_catalog_core(); if a
    -- later refactor moves it again, this still finds it.
    select p.oid::regprocedure
      into target
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in ('get_catalog_core', 'get_catalog')
       and pg_get_functiondef(p.oid) like '%videoURLs%'
     order by (p.proname = 'get_catalog_core') desc
     limit 1;

    if target is null then
        raise exception
            'no catalog function emits videoURLs - cannot place videoRole beside it. '
            'Inspect: select proname from pg_proc p join pg_namespace n on n.oid = '
            'p.pronamespace where n.nspname = ''public'' and proname like ''%%catalog%%'';';
    end if;

    src := pg_get_functiondef(target);

    if src like '%videoRole%' then
        raise notice '% already emits videoRole - nothing to patch.', target;
        return;
    end if;

    -- Insert the new key beside videoURLs, capturing the table alias from the
    -- existing expression rather than assuming it. Whitespace-independent, so
    -- it does not care how the live body happens to be formatted - which is
    -- what broke the previous draft.
    patched := regexp_replace(
        src,
        '(''videoURLs''\s*,\s*to_jsonb\(\s*(\w+)\.video_urls\s*\)\s*,)',
        E'\\1\n          ''videoRole'',            to_jsonb(\\2.video_role),'
    );

    if patched = src then
        raise exception
            'found % but could not parse its videoURLs expression - refusing to guess. '
            'Read it with: select pg_get_functiondef(''%%''::regprocedure);', target, target;
    end if;

    execute patched;

    -- Prove it took rather than trusting that it did.
    if pg_get_functiondef(target) not like '%videoRole%' then
        raise exception '% still does not emit videoRole after patching.', target;
    end if;

    raise notice '% now emits videoRole.', target;
end
$migration$;

commit;

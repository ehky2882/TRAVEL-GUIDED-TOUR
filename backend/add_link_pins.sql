-- add_link_pins.sql
--
-- Migration: teach the catalog about LINK PINS.
--
-- A link pin stands for someone else's post — a TikTok, a Reel, a Short —
-- rather than narration Atlas hosts. It appears everywhere a tour appears
-- (map, rails, search, library) and its detail page plays the post through
-- that platform's own embedded player.
--
-- Adds two nullable columns to public.tours and emits them from whichever
-- catalog function actually carries the tour keys:
--
--   source_url      the post this pin stands for. NULL for every other kind.
--   source_author   the creator being credited, e.g. '@someone'.
--
--
-- 🔴 WHY THIS FILE DOES NOT SAY `create or replace function get_catalog()`
--
--     get_catalog() = get_catalog_core() || { places: catalog_places() }
--
-- The live catalog RPC is a COMPOSITION. `get_catalog()` itself is a
-- three-line wrapper; the tour keys live in `get_catalog_core()`. Replacing
-- the wrapper with a full body severs the call to the core and silently drops
-- every place, plus priceTier, isPrivate, country, videoURLs and videoRole -
-- with no error raised. Four files in this directory still contain that
-- statement and carry a banner saying so.
--
-- So this patches, and it REFUSES TO GUESS: if it cannot find and parse the
-- expression it means to sit beside, it raises and the transaction rolls back.
-- A migration that cannot do its job must not report success.
--
-- Modelled on add_video_role.sql, which is the worked example.
--
-- Idempotent: safe to re-run. The column add is `if not exists` and the
-- function patch no-ops when the keys are already present. Run once in the
-- Supabase SQL Editor (project "Dozent"). Expect "Success. No rows returned."
-- Every existing tour gets NULL, which the app reads as "not a link pin" -
-- nothing changes until a tour says otherwise.
--
-- ⚠️ AFTERWARDS, run scripts/check-catalog-keys.py. It asks the live RPC what
-- it actually returns and fails if anything the app decodes went missing. Do
-- not trust "Success. No rows returned." on its own — that is exactly what the
-- clobbered-catalog case printed.

begin;

alter table public.tours
    add column if not exists source_url text;

alter table public.tours
    add column if not exists source_author text;

do $migration$
declare
    target   regprocedure;
    src      text;
    patched  text;
begin
    -- Find whichever catalog function actually emits the tour keys rather
    -- than assuming which one it is. Today that is get_catalog_core(); if a
    -- later refactor moves it again, this still finds it.
    select p.oid::regprocedure
      into target
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in ('get_catalog_core', 'get_catalog')
       and pg_get_functiondef(p.oid) like '%videoRole%'
     order by (p.proname = 'get_catalog_core') desc
     limit 1;

    if target is null then
        raise exception
            'no catalog function emits videoRole - cannot place the link-pin keys '
            'beside it. Has add_video_role.sql been run? Inspect with: select '
            'proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace '
            'where n.nspname = ''public'' and proname like ''%%catalog%%'';';
    end if;

    src := pg_get_functiondef(target);

    if src like '%sourceURL%' then
        raise notice '% already emits sourceURL - nothing to patch.', target;
        return;
    end if;

    -- Insert both keys beside videoRole, capturing the table alias out of the
    -- existing expression rather than assuming it is `t`. Whitespace-
    -- independent, so the live body's formatting cannot break it.
    patched := regexp_replace(
        src,
        '(''videoRole''\s*,\s*to_jsonb\(\s*(\w+)\.video_role\s*\)\s*,)',
        E'\\1\n          ''sourceURL'',            to_jsonb(\\2.source_url),\n'
        '          ''sourceAuthor'',         to_jsonb(\\2.source_author),'
    );

    if patched = src then
        raise exception
            'found % but could not parse its videoRole expression - refusing to '
            'guess. Read it with: select pg_get_functiondef(''%''::regprocedure);',
            target, target;
    end if;

    execute patched;

    -- Prove it took rather than trusting that it did.
    if pg_get_functiondef(target) not like '%sourceURL%'
       or pg_get_functiondef(target) not like '%sourceAuthor%' then
        raise exception '% still does not emit both link-pin keys after patching.',
            target;
    end if;

    raise notice '% now emits sourceURL and sourceAuthor.', target;
end
$migration$;

commit;

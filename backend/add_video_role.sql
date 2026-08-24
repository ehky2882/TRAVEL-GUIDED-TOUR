-- add_video_role.sql
--
-- Migration: teach the catalog what a tour's video IS.
--
-- Adds a `video_role text` column to `public.tours` and adds a `videoRole`
-- key to the `get_catalog()` RPC.
--
--   NULL / 'gallery'  the clip is extra - b-roll, a moving photograph beside
--                     the still ones. It plays on its own and, if it has
--                     sound, borrows the narration and hands it straight
--                     back. This is every video in the catalogue today, and
--                     what any tour without the key keeps doing.
--
--   'narration'       the clip IS the tour. Its soundtrack is the narration,
--                     so the play bar and the picture are one thing: play,
--                     pause or scrub either and both move together. The
--                     AUDIO is the clock and the video is muted.
--
-- Owner decision, 2026-08-24: "i agree we need to define different types of
-- videos." Do NOT infer this from the data - the tempting rule (single stop,
-- clip has sound, durations match) breaks b-roll the first time a clip
-- happens to be the length of its narration, and it fails silently.
--
--
-- 🔴 WHY THIS PATCHES get_catalog INSTEAD OF REPLACING IT
--
-- Every earlier migration rebuilt the whole function by pasting a full
-- `create or replace`, each one lifted from whatever the author had to hand.
-- The result is that NO FILE IN THIS REPO MATCHES THE LIVE FUNCTION, and
-- `schema.sql` least of all:
--
--     live get_catalog has   places, priceTier, isPrivate, country, videoURLs
--     schema.sql has         country, videoURLs
--     paid_tours.sql has     priceTier, videoURLs
--     places_apply.sql has   places
--
-- The first draft of this file followed the `add_country.sql` convention and
-- lifted the body verbatim from `schema.sql` "so the two cannot drift". That
-- convention assumed schema.sql was current. It is not, and running that
-- draft would have silently dropped **all 25 places, priceTier (every paid
-- tour's price) and isPrivate (private accounts)** - three shipped features,
-- from one paste, with no error.
--
-- So this does not rebuild the function. It reads whatever is live, inserts
-- ONE key next to `videoURLs`, and puts it back. Nothing else can be lost,
-- whatever the live definition happens to contain.
--
-- ⚠️ It REFUSES rather than guessing: if the anchor is not found, or the key
-- is somehow still absent afterwards, it raises and the transaction rolls
-- back. A migration that cannot do its job must not report success - the
-- same rule the image and coordinate checkers were rebuilt around.
--
--
-- Safe to re-run: `add column if not exists`, and the patch is skipped when
-- the key is already present. Run once in the Supabase SQL Editor (project
-- "Dozent"). Expect "Success. No rows returned."; the PostgREST schema cache
-- reloads within a few seconds. Every existing tour gets NULL, which the app
-- reads as `gallery` - no behaviour changes until a tour says otherwise.
--
-- After this runs, the `seed-supabase` job (publish-catalog.yml) carries
-- `videoRole` from Tours.json into the column on every content merge.

begin;

alter table public.tours
    add column if not exists video_role text;

do $migration$
declare
    src text;
    patched text;
begin
    select pg_get_functiondef(p.oid)
      into src
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname = 'get_catalog';

    if src is null then
        raise exception 'get_catalog() not found - is this the right database?';
    end if;

    -- Already done: leave the live definition completely alone.
    if src like '%videoRole%' then
        raise notice 'get_catalog already emits videoRole - nothing to patch.';
        return;
    end if;

    -- Insert the new key immediately after videoURLs, whatever the
    -- surrounding whitespace looks like.
    patched := regexp_replace(
        src,
        '(''videoURLs''\s*,\s*to_jsonb\(\s*t\.video_urls\s*\)\s*,)',
        E'\\1\n          ''videoRole'',            to_jsonb(t.video_role),'
    );

    if patched = src then
        raise exception
            'could not find the videoURLs key in get_catalog() - refusing to modify it. '
            'Patch the function by hand rather than replacing it wholesale: a full '
            'create-or-replace from any file in this repo would drop places, priceTier '
            'and isPrivate.';
    end if;

    execute patched;

    -- Prove it took, rather than trusting that it did.
    select pg_get_functiondef(p.oid)
      into src
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname = 'get_catalog';

    if src not like '%videoRole%' then
        raise exception 'get_catalog() still does not emit videoRole after patching.';
    end if;

    raise notice 'get_catalog() now emits videoRole.';
end
$migration$;

commit;

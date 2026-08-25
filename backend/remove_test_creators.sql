-- Remove the four throwaway link-pin creators, and nothing else.
--
-- WHY THIS FILE EXISTS. PR #593 removed the four `TEST -` link pins AND their
-- four creators from Tours.json, for a stated reason:
--
--     "A maker with no tours still counts toward the Dozents number in
--      Settings and appears in creator search with nothing behind it, so
--      leaving them would have quietly overstated the platform."
--
-- The tours went. The creators did not. `seed_from_toursjson.py` is
-- UPSERT-ONLY: it inserts and updates, and the only thing it ever deletes is a
-- tour's own stops before re-inserting them. So removing a maker from
-- Tours.json is not a delete, and all four were still being served -- at
-- 2026-08-25 03:20 the live RPC returned 49 makers, 11 of them with no tours.
--
-- 🔴 SEVEN OF THOSE ELEVEN ARE REAL PEOPLE AND MUST SURVIVE.
--   'New Creator' x2, 'EHKY-APPL', 'Kathy Ng', 'Shawn Tay', 'hgc9kfnf77',
--   '🏆 kiubert 🏆' -- real sign-ups who have not published yet. Owner
--   decision 2026-08-25: clear the test creators, keep the real accounts.
--
-- ⚠️ WRITTEN AS ONE STATEMENT, DELIBERATELY, AND THE SHAPE IS THE LESSON.
-- The first version of this file put the delete first and a tidy summary
-- select last. The Supabase SQL Editor shows only the LAST result, so the
-- owner ran it, saw the summary, and had no way to tell that the delete had
-- matched nothing -- the four creators were still live afterwards. A
-- destructive statement must BE the visible result, so `returning` is the
-- receipt. For the same reason there is no explicit begin/commit: the editor
-- manages its own transaction, and wrapping it invites a silent rollback.
--
-- SAFE TO RE-RUN -- the second run returns no rows.

delete from public.makers m
where
    -- (1) An explicit list. A pattern on the display name could one day match
    --     a real creator who calls themselves something similar; four literal
    --     uuids cannot match anything else, ever.
    m.id in (
        'fed471cd-70b8-5092-97de-fd4b71df6b41',  -- TikTok @tiktok
        '6d73290a-7ca8-56fe-b6d3-93d319e35a4d',  -- YouTube @jawed
        '4288a1c9-477d-58c4-8222-c0616335f3c1',  -- YouTube @Blippi
        'bc528ec4-008a-5413-8773-32c54391c0fb'   -- Instagram @nasainternships
    )
    -- (2) No account behind it. If one of those ids were ever wrong and landed
    --     on a real sign-up, this stops the delete dead.
    and m.user_id is null
    -- (3) And nothing published. ⚠️ THIS is the guard that protects the Atlas
    --     studios, which ALSO have user_id null by design -- what saves them
    --     is having tours. `tours.maker_id` is already `on delete restrict`,
    --     so Postgres would refuse regardless; this states the intent instead
    --     of relying on an error message.
    and not exists (
        select 1 from public.tours t where t.maker_id = m.id
    )
returning m.display_name, m.id;

-- Expect FOUR rows back, naming the four creators above. Zero rows means the
-- delete matched nothing -- see the note about the editor's role below.
--
-- ⚠️ IF IT RETURNS ZERO ROWS while those creators are still live, the likely
-- cause is the role the editor is running as. `public.makers` has RLS and a
-- public-read policy but no delete policy, so running as `anon` or
-- `authenticated` filters the delete to zero rows and still reports success.
-- Run as `postgres`, which bypasses RLS.

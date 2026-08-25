-- Remove the four throwaway link-pin creators and the taken-down tours that
-- keep them alive. Nothing else.
--
-- WHY THIS FILE EXISTS. PR #593 removed the four `TEST -` link pins AND their
-- four creators from Tours.json, for a stated reason:
--
--     "A maker with no tours still counts toward the Dozents number in
--      Settings and appears in creator search with nothing behind it, so
--      leaving them would have quietly overstated the platform."
--
-- Neither actually left the database. `seed_from_toursjson.py` is UPSERT-ONLY:
-- it inserts and updates, and the only thing it ever deletes is a tour's own
-- stops before re-inserting them. Removing something from Tours.json is not a
-- delete.
--
-- 🔴 THE PART THAT COST TWO FAILED PASTES: THE TOURS WERE TAKEN DOWN, NOT
-- DELETED. Each of the four creators still owns exactly one tour with
-- `status = 'taken_down'` -- almost certainly `takedown_tour()`, run in another
-- session. A taken-down tour is INVISIBLE to every ordinary read: `get_catalog`
-- serves published only, and so does the RLS policy behind PostgREST. So the
-- catalog said those creators had no tours, a direct API read agreed, and both
-- were wrong. **Anything that reasons about "does this maker have tours" must
-- query the table as `postgres`, or it is reading a filtered view and will
-- conclude the opposite of the truth.**
--
-- ⚠️ AND THE FIRST VERSION OF THIS FILE MADE THAT INVISIBLE. Its maker delete
-- carried a `not exists (select 1 from tours ...)` guard, which the hidden rows
-- failed -- so the statement matched zero rows and reported "Success. No rows
-- returned." `tours.maker_id` is `on delete restrict`, so WITHOUT that guard
-- Postgres would have raised a foreign-key violation naming the exact blocking
-- row. **A guard that turns a loud, specific error into silence is worse than
-- no guard.** It is kept below only because by then the tours are gone.
--
-- 🔴 SEVEN OTHER MAKERS HAVE NO TOURS AND ARE REAL PEOPLE.
--   'New Creator' x2, 'EHKY-APPL', 'Kathy Ng', 'Shawn Tay', 'hgc9kfnf77',
--   '🏆 kiubert 🏆' -- real sign-ups who have not published yet. Owner
--   decision 2026-08-25: clear the test creators, keep the real accounts.
--   Every one of them carries a `user_id`; none of the four below does.
--
-- SAFE TO RE-RUN -- the second run deletes nothing and still reports 0 / 0.

-- 1. The tours. Cascades to stops, saved-library rows, recently-viewed,
--    journey items and group sessions; nulls the tour on any report.
--    ⚠️ `purchases.tour_id` is `on delete restrict`, so if one of these had
--    ever been bought this statement raises rather than destroying the record
--    of a sale. They are free test pins, so it will not fire -- but that is
--    the reason it is safe to run this without checking first.
delete from public.tours t
where t.maker_id in (
        'fed471cd-70b8-5092-97de-fd4b71df6b41',  -- TikTok @tiktok
        '6d73290a-7ca8-56fe-b6d3-93d319e35a4d',  -- YouTube @jawed
        '4288a1c9-477d-58c4-8222-c0616335f3c1',  -- YouTube @Blippi
        'bc528ec4-008a-5413-8773-32c54391c0fb'   -- Instagram @nasainternships
      )
  -- Only ever the withdrawn ones. If one of these creators somehow has a
  -- PUBLISHED tour, it is real content and this must not touch it.
  and t.status = 'taken_down';

-- 2. The creators, now that nothing points at them.
delete from public.makers m
where
    -- An explicit list. A pattern on the display name could one day match a
    -- real creator who calls themselves something similar; four literal uuids
    -- cannot match anything else, ever.
    m.id in (
        'fed471cd-70b8-5092-97de-fd4b71df6b41',
        '6d73290a-7ca8-56fe-b6d3-93d319e35a4d',
        '4288a1c9-477d-58c4-8222-c0616335f3c1',
        'bc528ec4-008a-5413-8773-32c54391c0fb'
    )
    -- No account behind it. If one of those ids were ever wrong and landed on
    -- a real sign-up, this stops the delete dead.
    and m.user_id is null
    -- And nothing left, of ANY status -- see the warning above about why a
    -- guard like this must never be the only thing standing between you and
    -- an explanation.
    and not exists (
        select 1 from public.tours t where t.maker_id = m.id
    );

-- 3. The receipt. Both numbers must come back 0. This is the last statement
--    on purpose: the SQL Editor shows only the final result, so the thing it
--    shows has to be the thing that answers the question.
select
    (select count(*) from public.tours
      where maker_id in ('fed471cd-70b8-5092-97de-fd4b71df6b41',
                         '6d73290a-7ca8-56fe-b6d3-93d319e35a4d',
                         '4288a1c9-477d-58c4-8222-c0616335f3c1',
                         'bc528ec4-008a-5413-8773-32c54391c0fb'))  as tours_left,
    (select count(*) from public.makers
      where id in ('fed471cd-70b8-5092-97de-fd4b71df6b41',
                   '6d73290a-7ca8-56fe-b6d3-93d319e35a4d',
                   '4288a1c9-477d-58c4-8222-c0616335f3c1',
                   'bc528ec4-008a-5413-8773-32c54391c0fb'))        as creators_left;

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
-- The discriminator is mechanical rather than a judgement call: every test
-- creator was minted by scripts/make-link-pin.py and carries NO auth user,
-- while all seven real sign-ups do. That is asserted below, not assumed.
--
-- SAFE TO RE-RUN -- the second run deletes nothing and reports 0.

begin;

with gone as (
    delete from public.makers m
    where
        -- (1) An explicit list. A pattern on the display name could one day
        --     match a real creator who calls themselves something similar;
        --     four literal uuids cannot match anything else, ever.
        m.id in (
            'fed471cd-70b8-5092-97de-fd4b71df6b41',  -- TikTok @tiktok
            '6d73290a-7ca8-56fe-b6d3-93d319e35a4d',  -- YouTube @jawed
            '4288a1c9-477d-58c4-8222-c0616335f3c1',  -- YouTube @Blippi
            'bc528ec4-008a-5413-8773-32c54391c0fb'   -- Instagram @nasainternships
        )
        -- (2) No account behind it. If one of those ids were ever wrong and
        --     landed on a real sign-up, this stops the delete dead.
        and m.user_id is null
        -- (3) And nothing published. ⚠️ THIS is the guard that protects the
        --     Atlas studios, which ALSO have user_id null by design -- what
        --     saves them is having tours. `tours.maker_id` is already
        --     `on delete restrict`, so Postgres would refuse regardless; this
        --     states the intent instead of relying on an error message.
        and not exists (
            select 1 from public.tours t where t.maker_id = m.id
        )
    returning m.id
)
select
    (select count(*) from gone)                          as creators_removed,
    (select count(*) from public.makers)                 as makers_remaining,
    (select count(*) from public.makers m
       where not exists (select 1 from public.tours t
                          where t.maker_id = m.id))      as remaining_with_no_tours;

commit;

-- Read-only receipt: every creator still served that has no tours. After this
-- runs it should list exactly the seven real sign-ups and none of the four
-- names above.
select m.display_name,
       case when m.user_id is null then 'no account -- investigate'
            else 'real sign-up -- keep' end as kind
from public.makers m
where not exists (select 1 from public.tours t where t.maker_id = m.id)
order by 2, 1;

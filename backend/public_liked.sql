-- ---------------------------------------------------------------------------
-- Liked on other people's pages
-- ---------------------------------------------------------------------------
-- WHAT THIS DOES (plain English): lets a creator's page show what they have
-- saved, so everyone's profile has a LIKED list like yours does.
--
-- HOW TO RUN IT: Supabase dashboard -> SQL Editor -> New query -> paste all of
-- this -> Run. Safe to run more than once.
--
-- WHY A FUNCTION AND NOT JUST A PERMISSION: what people save lives in
-- `user_library`, which each person can read only for themselves. That is the
-- right default and should stay. This adds one narrow, read-only opening in it
-- rather than unlocking the table.
--
-- ⚠️ WHAT THIS PUBLISHES: the tours a person has saved become visible to
-- anyone who opens their profile. Nothing else does — not what they have
-- downloaded, not how far through a tour they got, not what they finished.
-- Those columns sit in the same table and are deliberately not returned.
--
-- Owner decision, 2026-07-27: yes, saves are public, in line with "if a
-- profile is public then everything is public".
-- ---------------------------------------------------------------------------

-- Tour ids a person has saved, newest first.
--
-- SECURITY DEFINER so it can see past the own-rows-only rule on user_library.
-- That makes the function body the security boundary, so it is deliberately
-- tiny: one table, one filter, one column out. Do not widen it to `select *`.
create or replace function public.liked_tour_ids(p_user uuid)
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
    select tour_id
    from public.user_library
    where user_id = p_user
      and saved_at is not null
    order by saved_at desc;
$$;

-- Explicit grants. `revoke ... from public` first because Postgres grants
-- EXECUTE to everyone by default on a new function, and privileges accumulate —
-- deleting a grant statement later does not take the privilege back.
revoke all on function public.liked_tour_ids(uuid) from public;
grant execute on function public.liked_tour_ids(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Check it worked: swap in a real account id (any `userId` from get_catalog).
--   select * from public.liked_tour_ids('00000000-0000-0000-0000-000000000000');
-- An account that has saved nothing returns no rows, which is correct — that
-- is an empty LIKED list, not an error.
-- ---------------------------------------------------------------------------

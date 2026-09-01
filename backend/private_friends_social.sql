-- ---------------------------------------------------------------------------
-- A private account's followers / following, visible to its accepted followers
-- ---------------------------------------------------------------------------
-- WHAT THIS DOES (plain English): if someone has a private account and they
-- have accepted your follow request, you can now see who follows them and who
-- they follow. Before this, those two lists were hidden from everyone except
-- the account's own owner — so a friend who had accepted you still showed
-- "No followers yet.", which is what the owner reported on 2026-09-01.
--
-- Strangers still see nothing. A public account is unchanged.
--
-- HOW TO RUN IT: Supabase dashboard -> SQL Editor -> New query -> paste all of
-- this -> Run. It is safe to run more than once.
--
-- ✅ SAFE TO RE-RUN, GENUINELY. Unlike `public_lists.sql`, `paid_tours.sql`,
--    `add_country.sql` and `add_video_urls.sql`, this file does NOT contain
--    `create or replace function public.get_catalog()`. It touches only the
--    two follow-list RPCs and adds one helper, so it cannot sever the
--    `get_catalog` wrapper or drop `places` / `priceTier` / `isPrivate`.
--
-- WHY THE OLD RULE WAS WRONG: `social.sql` gated both lists on
-- `owns_maker(m)` alone. That reads as "private means only I can see it",
-- but the owner's model has always been that an accepted follower is a
-- friend and sees what a friend sees:
--
--   "if a maker is public then everything is public. if maker is private but
--    you are friends then you should be able to see your friend's list."
--
-- ⚠️ WHAT THIS DOES *NOT* DO: it does not hide a private account's TOURS from
--    strangers. Those still ship inside the one public `get_catalog` payload,
--    which has no viewer, so every user of the app sees them. That is the
--    separate "private should hide everything" project — see CLAUDE.md.
-- ---------------------------------------------------------------------------

begin;

-- ---------------------------------------------------------------------------
-- 1. One place that answers "may the caller see this maker's social graph?"
--    Public account -> yes. Your own account -> yes. Private account you have
--    been accepted to follow -> yes. Everyone else -> no.
--
--    This is deliberately a named helper rather than the same `exists (...)`
--    pasted into both RPCs below: the identical question is already inlined
--    twice in `social.sql` and once more in `follow_state`, and a fourth copy
--    is how the three drift apart.
--
--    A signed-out caller has a null `auth.uid()`, so both the ownership and
--    the accepted-follower tests are false and a private account stays hidden.
-- ---------------------------------------------------------------------------
create or replace function public.can_see_social(m uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select
        -- public account (or no such maker — the RPCs return nothing anyway)
        not exists (select 1 from public.makers mk
                    where mk.id = m and mk.is_private)
        -- or it is mine
        or public.owns_maker(m)
        -- or they accepted me: same expression `follow_state` calls isFollowing
        or exists (select 1 from public.follows f
                   where f.followee_id = m
                     and f.follower_id = auth.uid()
                     and f.status = 'accepted');
$$;

revoke all on function public.can_see_social(uuid) from public;
grant execute on function public.can_see_social(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Followers of `m`. Body unchanged from `social.sql` apart from the gate.
-- ---------------------------------------------------------------------------
create or replace function public.list_followers(m uuid)
returns setof public.makers language plpgsql stable security definer set search_path = public as $$
begin
    if not public.can_see_social(m) then
        return;  -- private, and the caller is neither its owner nor a friend
    end if;
    return query
        select fm.* from public.follows f
        join public.makers fm on fm.user_id = f.follower_id
        where f.followee_id = m and f.status = 'accepted'
        order by f.created_at desc;
end; $$;
grant execute on function public.list_followers(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Makers that `m`'s owner follows. Same gate.
-- ---------------------------------------------------------------------------
create or replace function public.list_following(m uuid)
returns setof public.makers language plpgsql stable security definer set search_path = public as $$
begin
    if not public.can_see_social(m) then
        return;
    end if;
    return query
        select fe.* from public.follows f
        join public.makers me on me.user_id = f.follower_id  -- follower's own maker
        join public.makers fe on fe.id = f.followee_id       -- the followee
        where me.id = m and f.status = 'accepted'
        order by f.created_at desc;
end; $$;
grant execute on function public.list_following(uuid) to anon, authenticated;

commit;

-- ---------------------------------------------------------------------------
-- Check it worked. Paste your friend's maker id in place of <MAKER_ID>; you
-- can read it off their profile URL, or find it with the first query.
--
--   -- who is private?
--   select id, display_name, is_private from public.makers where is_private;
--
--   -- should now return true for a private account that has accepted you,
--   -- and false for a private account that has not
--   select public.can_see_social('<MAKER_ID>');
--
--   -- should now list their followers instead of coming back empty
--   select id, display_name from public.list_followers('<MAKER_ID>');
--
-- ⚠️ Run these while SIGNED IN AS YOURSELF (the SQL Editor runs as the service
--    role, where `auth.uid()` is null — so it will report false/empty there
--    even after this works). The honest test is the app itself.
-- ---------------------------------------------------------------------------

-- Atlas backend — social layer (V2 batch D): the follow model + private accounts.
--
-- Run AFTER backend/schema.sql + backend/accounts.sql (needs public.makers plus
-- the owns_maker()/is_admin() helpers). Owner decisions (2026-07-04):
--   • Follow model (asymmetric, Instagram-style) — not symmetric "friends".
--   • New accounts default PUBLIC (instant follow); Private = approve each request.
--   • v1 scope = follow/unfollow, follower+following counts, followers/following
--     lists, and (private) approve/decline. A "following" home feed is a later
--     extension and needs NO schema change (it reads the same follows table).
--
-- A profile IS a maker (the app's model), so "following someone" = following
-- their maker row. The follower is the auth user (auth.uid()); the followee is a
-- makers.id. Seed studios (user_id NULL) can be followed but never follow.

begin;

-- Private-account flag. Public (false) → follows auto-accept; private (true) →
-- follows land as 'pending' until the maker's owner approves.
alter table public.makers add column if not exists is_private boolean not null default false;

-- ===========================================================================
-- follows: follower_id (a user) → followee_id (a maker/profile)
-- ===========================================================================
create table if not exists public.follows (
    follower_id uuid not null references auth.users (id) on delete cascade,
    followee_id uuid not null references public.makers (id) on delete cascade,
    status      text not null default 'accepted' check (status in ('pending', 'accepted')),
    created_at  timestamptz not null default now(),
    primary key (follower_id, followee_id)
);
create index if not exists follows_followee_idx on public.follows (followee_id, status);
create index if not exists follows_follower_idx on public.follows (follower_id, status);

-- On follow: block self-follow, and set status from the followee's privacy.
create or replace function public.set_follow_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
    if exists (select 1 from public.makers m
               where m.id = new.followee_id and m.user_id = new.follower_id) then
        raise exception 'cannot follow your own profile';
    end if;
    if exists (select 1 from public.makers m
               where m.id = new.followee_id and m.is_private) then
        new.status := 'pending';
    else
        new.status := 'accepted';
    end if;
    return new;
end; $$;

drop trigger if exists follows_set_status on public.follows;
create trigger follows_set_status before insert on public.follows
    for each row execute function public.set_follow_status();

-- ===========================================================================
-- RLS: follow as yourself; manage your own follows + your own followers.
-- Public counts/lists come from the SECURITY DEFINER RPCs below, so the table
-- itself only needs to expose rows to the two parties of each edge.
-- ===========================================================================
alter table public.follows enable row level security;

drop policy if exists follows_select_own on public.follows;
create policy follows_select_own on public.follows
    for select using (
        follower_id = auth.uid()           -- who I follow + my pending requests
        or public.owns_maker(followee_id)  -- my followers + requests sent to me
    );

drop policy if exists follows_insert_self on public.follows;
create policy follows_insert_self on public.follows
    for insert to authenticated
    with check (follower_id = auth.uid());

-- Unfollow (my row) OR remove/decline a follower (I own the followee).
drop policy if exists follows_delete on public.follows;
create policy follows_delete on public.follows
    for delete to authenticated
    using (follower_id = auth.uid() or public.owns_maker(followee_id));

-- Approve a pending request (I own the followee).
drop policy if exists follows_update_owner on public.follows;
create policy follows_update_owner on public.follows
    for update to authenticated
    using (public.owns_maker(followee_id))
    with check (public.owns_maker(followee_id));

grant select, insert, update, delete on public.follows to authenticated;

-- ===========================================================================
-- Reads (SECURITY DEFINER so counts/lists are correct across RLS, with the
-- public/private visibility rule baked in).
-- ===========================================================================

-- Counts + the current viewer's relationship to maker `m`, in one call.
create or replace function public.follow_state(m uuid)
returns jsonb language sql stable security definer set search_path = public as $$
    select jsonb_build_object(
        'followers', (select count(*) from public.follows f
                        where f.followee_id = m and f.status = 'accepted'),
        'following', (select count(*) from public.follows f
                        join public.makers mk on mk.user_id = f.follower_id
                        where mk.id = m and f.status = 'accepted'),
        'isFollowing', exists (select 1 from public.follows f
                        where f.followee_id = m and f.follower_id = auth.uid()
                              and f.status = 'accepted'),
        'isPending', exists (select 1 from public.follows f
                        where f.followee_id = m and f.follower_id = auth.uid()
                              and f.status = 'pending'),
        -- pending requests waiting for the OWNER of `m` (0 for non-owners).
        'pendingRequests', (select count(*) from public.follows f
                        where f.followee_id = m and f.status = 'pending'
                              and public.owns_maker(m))
    );
$$;
grant execute on function public.follow_state(uuid) to anon, authenticated;

-- Followers of `m` (their maker profiles). Public maker → anyone; private maker
-- → only its owner. Followers without a maker profile are omitted.
create or replace function public.list_followers(m uuid)
returns setof public.makers language plpgsql stable security definer set search_path = public as $$
begin
    if exists (select 1 from public.makers mk where mk.id = m and mk.is_private)
       and not public.owns_maker(m) then
        return;  -- private list hidden from non-owners
    end if;
    return query
        select fm.* from public.follows f
        join public.makers fm on fm.user_id = f.follower_id
        where f.followee_id = m and f.status = 'accepted'
        order by f.created_at desc;
end; $$;
grant execute on function public.list_followers(uuid) to anon, authenticated;

-- Makers that `m`'s owner follows. Same visibility rule as followers.
create or replace function public.list_following(m uuid)
returns setof public.makers language plpgsql stable security definer set search_path = public as $$
begin
    if exists (select 1 from public.makers mk where mk.id = m and mk.is_private)
       and not public.owns_maker(m) then
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

-- Pending follow requests waiting for the caller (their follower profiles).
create or replace function public.list_follow_requests()
returns setof public.makers language sql stable security definer set search_path = public as $$
    select fm.* from public.follows f
    join public.makers me on me.id = f.followee_id and public.owns_maker(me.id)
    join public.makers fm on fm.user_id = f.follower_id
    where f.status = 'pending'
    order by f.created_at;
$$;
grant execute on function public.list_follow_requests() to authenticated;

commit;

-- get_catalog(): expose is_private so the app can show the private indicator +
-- request-vs-instant follow behavior. (Re-apply the makers block in schema.sql
-- with 'isPrivate', m.is_private added — counts stay on the RPCs above.)

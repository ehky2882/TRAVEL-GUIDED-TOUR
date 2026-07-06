-- Atlas backend — accounts, auth, consumer sync, maker self-serve + moderation (V2 Step 3)
--
-- Run AFTER backend/schema.sql (the catalog foundation — PR #218). This layer is
-- additive: it adds auth-linked tables (profiles, consumer-sync tables, reports),
-- and the write/RLS policies that let signed-in users own makers/tours/stops and
-- that route every published change through moderation.
--
-- Owner decisions (2026-06-21) encoded here:
--   * Makers are SELF-SERVE: any signed-in user can create one maker profile and
--     author tours. Tours go to a moderation queue (status='in_review') and only an
--     admin can publish.
--   * Sign-in providers: Apple + email + Google (configured in Supabase Auth, not SQL).
--   * Consumers get accounts now: optional sign-in enables cross-device sync of
--     library / saved makers / recent searches / recently viewed. Anonymous use still
--     works entirely on-device.
--
-- Design rationale + the RLS model summary live in docs/accounts-design.md.

begin;

-- ===========================================================================
-- 0. Helpers
-- ===========================================================================

-- profiles is created below; is_admin()/owns_maker()/owns_tour() are SECURITY
-- DEFINER so they can read past RLS without recursing into the policies that call
-- them. search_path pinned to public for safety.

-- ===========================================================================
-- 1. profiles — 1:1 with auth.users, for EVERY signed-in user (consumer or maker)
-- ===========================================================================
create table if not exists public.profiles (
    id           uuid primary key references auth.users (id) on delete cascade,
    display_name text,
    avatar_url   text,
    is_admin     boolean not null default false,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

-- Auto-create a profile row AND a maker row when a new auth user signs up
-- (Apple/email/Google all land in auth.users; their name/avatar arrive in
-- raw_user_meta_data). One login = one profile = one maker page, so EVERY
-- account is a maker from signup — even before it publishes a tour. This is
-- why the Settings "Makers" count (get_catalog returns all maker rows) counts
-- every account. (Owner decision 2026-07-05.)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
    insert into public.profiles (id, display_name, avatar_url)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
        new.raw_user_meta_data->>'avatar_url'
    )
    on conflict (id) do nothing;

    -- Maker profile for the new account (empty bio; MakerProfileService.ensureMaker
    -- reuses this row on first edit/authoring thanks to uniq_makers_user_id).
    insert into public.makers (id, display_name, bio, user_id)
    select gen_random_uuid(),
           coalesce(new.raw_user_meta_data->>'full_name',
                    new.raw_user_meta_data->>'name', 'New Creator'),
           '',
           new.id
    where not exists (select 1 from public.makers where user_id = new.id);

    return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- One-time backfill: give any pre-existing account (signed up before the maker
-- auto-create above) a maker row so it counts too. Guarded + idempotent.
insert into public.makers (id, display_name, bio, user_id)
select gen_random_uuid(), coalesce(p.display_name, 'New Creator'), '', p.id
from public.profiles p
where not exists (select 1 from public.makers m where m.user_id = p.id);

-- Is the current request an admin (the Atlas moderation team)?
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
    select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

-- A user must never be able to grant themselves admin. Reset the flag on any
-- non-admin update that tries to change it.
create or replace function public.protect_profile_admin_flag()
returns trigger language plpgsql security definer set search_path = public as $$
begin
    if new.is_admin is distinct from old.is_admin and not public.is_admin() then
        new.is_admin := old.is_admin;
    end if;
    new.updated_at := now();
    return new;
end; $$;

drop trigger if exists profiles_protect_admin on public.profiles;
create trigger profiles_protect_admin
    before update on public.profiles
    for each row execute function public.protect_profile_admin_flag();

alter table public.profiles enable row level security;
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
    for select using (id = auth.uid() or public.is_admin());
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles
    for update using (id = auth.uid()) with check (id = auth.uid());

-- ===========================================================================
-- 2. Maker ownership (self-serve) — makers/tours/stops already exist in schema.sql
-- ===========================================================================

-- One maker profile per real user; the Atlas-owned studios keep user_id = NULL.
create unique index if not exists uniq_makers_user_id
    on public.makers (user_id) where user_id is not null;

create or replace function public.owns_maker(m uuid)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.makers where id = m and user_id = auth.uid());
$$;

create or replace function public.owns_tour(t uuid)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (
        select 1 from public.tours tr
        join public.makers mk on mk.id = tr.maker_id
        where tr.id = t and mk.user_id = auth.uid()
    );
$$;

-- makers: public read already granted in schema.sql. Add owner write + admin.
drop policy if exists makers_owner_insert on public.makers;
create policy makers_owner_insert on public.makers
    for insert with check (user_id = auth.uid());
drop policy if exists makers_owner_update on public.makers;
create policy makers_owner_update on public.makers
    for update using (user_id = auth.uid() or public.is_admin())
    with check (user_id = auth.uid() or public.is_admin());
drop policy if exists makers_admin_delete on public.makers;
create policy makers_admin_delete on public.makers
    for delete using (public.is_admin());

-- tours: public read of published already in schema.sql. Add owner/admin paths.
-- Owners may see their own drafts, and create/edit tours ONLY in a non-published
-- status — publishing is admin-only. (App submits edits to a published tour with
-- status='in_review' to send it back through moderation.)
drop policy if exists tours_owner_select on public.tours;
create policy tours_owner_select on public.tours
    for select using (public.owns_tour(id) or public.is_admin());
drop policy if exists tours_owner_insert on public.tours;
create policy tours_owner_insert on public.tours
    for insert with check (public.owns_maker(maker_id) and status in ('draft', 'in_review'));
drop policy if exists tours_owner_update on public.tours;
create policy tours_owner_update on public.tours
    for update using (public.owns_tour(id))
    with check (public.owns_tour(id) and status in ('draft', 'in_review', 'taken_down'));
drop policy if exists tours_owner_delete on public.tours;
create policy tours_owner_delete on public.tours
    for delete using (public.owns_tour(id) or public.is_admin());
drop policy if exists tours_admin_all on public.tours;
create policy tours_admin_all on public.tours
    for all using (public.is_admin()) with check (public.is_admin());

-- stops: public read of published already in schema.sql. Owner/admin full write.
drop policy if exists stops_owner_select on public.stops;
create policy stops_owner_select on public.stops
    for select using (public.owns_tour(tour_id) or public.is_admin());
drop policy if exists stops_owner_write on public.stops;
create policy stops_owner_write on public.stops
    for all using (public.owns_tour(tour_id) or public.is_admin())
    with check (public.owns_tour(tour_id) or public.is_admin());

-- ===========================================================================
-- 3. Consumer account sync — server mirrors of the on-device stores
--    (LibraryStore / RecentSearchStore / RecentlyViewedStore / saved makers)
-- ===========================================================================
create table if not exists public.user_library (
    user_id          uuid not null references auth.users (id) on delete cascade,
    tour_id          uuid not null references public.tours (id) on delete cascade,
    saved_at         timestamptz,
    downloaded_at    timestamptz,
    listened_seconds int not null default 0,
    last_listened_at timestamptz,
    completed_at     timestamptz,
    updated_at       timestamptz not null default now(),
    primary key (user_id, tour_id)
);

create table if not exists public.user_saved_makers (
    user_id  uuid not null references auth.users (id) on delete cascade,
    maker_id uuid not null references public.makers (id) on delete cascade,
    saved_at timestamptz not null default now(),
    primary key (user_id, maker_id)
);

create table if not exists public.user_recently_viewed (
    user_id   uuid not null references auth.users (id) on delete cascade,
    tour_id   uuid not null references public.tours (id) on delete cascade,
    viewed_at timestamptz not null default now(),
    primary key (user_id, tour_id)
);

create table if not exists public.user_recent_searches (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references auth.users (id) on delete cascade,
    query       text not null,
    searched_at timestamptz not null default now()
);
create index if not exists idx_recent_searches_user on public.user_recent_searches (user_id, searched_at desc);

-- Each user reads/writes only their own rows.
alter table public.user_library        enable row level security;
alter table public.user_saved_makers   enable row level security;
alter table public.user_recently_viewed enable row level security;
alter table public.user_recent_searches enable row level security;

drop policy if exists user_library_own on public.user_library;
create policy user_library_own on public.user_library
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists user_saved_makers_own on public.user_saved_makers;
create policy user_saved_makers_own on public.user_saved_makers
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists user_recently_viewed_own on public.user_recently_viewed;
create policy user_recently_viewed_own on public.user_recently_viewed
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists user_recent_searches_own on public.user_recent_searches;
create policy user_recent_searches_own on public.user_recent_searches
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ===========================================================================
-- 4. Moderation — report-a-tour + the in-review queue
--    (the queue itself is just tours.status = 'in_review'; admins see all tours
--     via tours_admin_all and publish by setting status='published')
-- ===========================================================================
do $$ begin
    create type report_status as enum ('open', 'reviewed', 'actioned', 'dismissed');
exception when duplicate_object then null; end $$;

create table if not exists public.reports (
    id               uuid primary key default gen_random_uuid(),
    tour_id          uuid references public.tours (id) on delete set null,
    reporter_user_id uuid references auth.users (id) on delete set null,
    reason           text not null,
    details          text,
    status           report_status not null default 'open',
    created_at       timestamptz not null default now()
);
create index if not exists idx_reports_status on public.reports (status, created_at);

alter table public.reports enable row level security;
drop policy if exists reports_insert_any on public.reports;
create policy reports_insert_any on public.reports
    for insert with check (true);                 -- anyone (anon or signed-in) may report
drop policy if exists reports_admin_read on public.reports;
create policy reports_admin_read on public.reports
    for select using (public.is_admin());
drop policy if exists reports_admin_update on public.reports;
create policy reports_admin_update on public.reports
    for update using (public.is_admin()) with check (public.is_admin());

-- Convenience view for the moderation team (respects the caller's RLS).
create or replace view public.moderation_queue with (security_invoker = true) as
    select * from public.tours where status = 'in_review';

-- ===========================================================================
-- 5. Grants (RLS is the real gate; these expose the tables to the API roles)
-- ===========================================================================
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.makers, public.tours, public.stops to authenticated;
grant select, insert, update, delete
    on public.user_library, public.user_saved_makers,
       public.user_recently_viewed, public.user_recent_searches
    to authenticated;
grant insert on public.reports to anon, authenticated;
grant select, update on public.reports to authenticated;
grant select on public.moderation_queue to authenticated;

commit;

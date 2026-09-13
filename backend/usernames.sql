-- usernames.sql
--
-- Every row in public.makers gets a PLATFORM and a HANDLE, unique as a pair.
-- Design and owner decisions: docs/usernames-design.md (decided 2026-09-12,
-- all nine recommendations).
--
--   platform   'dozent' | 'instagram' | 'tiktok' | 'youtube'
--   handle     lowercase, no '@'.  instagram/urbanistariel, dozent/kathyng
--
-- The display name is NOT touched, for any row. Duplicates stay allowed there.
--
-- 🔴 NOTHING HERE DELETES, MERGES OR RENAMES AN ACCOUNT. (Owner, 2026-09-12:
-- "definitely do not delete any users.") Every row keeps its id, its display
-- name, its tours and its sign-in. The backfill only ADDS two fields.
--
-- HOW TO RUN: paste the whole file into the Supabase SQL Editor (project
-- "Dozent") and press Run once. The last thing it shows is one row of
-- numbers, which is the proof — see the bottom of this file for what they
-- must say. Safe to re-run: the second run changes nothing.
--
-- ⚠️ If the Editor warns about "destructive operations", that is the
-- `drop trigger if exists` / `drop constraint if exists` lines, which make the
-- file re-runnable. Nothing that holds data is dropped.
--
-- WHAT OLD APP BUILDS SEE. 1.1.1 saves a profile with an upsert that does not
-- send a handle. On insert the trigger below fills one in; on update Postgres
-- only sets the columns the save sent, so the handle is left alone. An old
-- phone can neither erase a handle nor fail to save for lack of one.

begin;

-- Re-runnable: take the guard off while the backfill runs, put it back after.
drop trigger if exists makers_handle_guard on public.makers;

-- ===========================================================================
-- 1. The columns
-- ===========================================================================
alter table public.makers add column if not exists platform text;
alter table public.makers add column if not exists handle   text;
-- True while the handle was given out automatically: the first change from an
-- automatic handle does not start the 30-day clock.
alter table public.makers add column if not exists handle_auto boolean not null default false;
alter table public.makers add column if not exists handle_changed_at timestamptz;

-- ===========================================================================
-- 2. Reserved words, and handles recently given up (held 30 days)
--    Readable by nobody but the functions below.
-- ===========================================================================
create table if not exists public.reserved_handles (
    handle text primary key,
    reason text not null
);

insert into public.reserved_handles (handle, reason) values
    ('dozent', 'brand'), ('atlas', 'brand'),
    ('admin', 'official'), ('administrator', 'official'), ('support', 'official'),
    ('help', 'official'), ('official', 'official'), ('staff', 'official'),
    ('moderator', 'official'), ('mod', 'official'), ('team', 'official'),
    ('system', 'official'), ('root', 'official'), ('api', 'official'),
    ('null', 'technical'), ('undefined', 'technical'), ('everyone', 'official'),
    ('instagram', 'platform'), ('tiktok', 'platform'), ('youtube', 'platform'),
    ('apple', 'company'), ('google', 'company'),
    ('about', 'website path'), ('privacy', 'website path'), ('terms', 'website path'),
    ('confirmed', 'website path'), ('settings', 'app word'), ('login', 'app word'),
    ('signin', 'app word'), ('signup', 'app word'), ('account', 'app word'),
    ('user', 'auto-assigned shape'), ('creator', 'fallback name'),
    ('newcreator', 'fallback name')
on conflict (handle) do nothing;

create table if not exists public.released_handles (
    platform    text not null,
    handle      text not null,
    maker_id    uuid,
    released_at timestamptz not null default now(),
    primary key (platform, handle)
);

alter table public.reserved_handles enable row level security;
alter table public.released_handles enable row level security;
revoke all on public.reserved_handles from anon, authenticated;
revoke all on public.released_handles from anon, authenticated;

-- ===========================================================================
-- 3. The rules, as functions
-- ===========================================================================

-- Why a Dozent handle is not allowed, or NULL if it is. `p_system` = the
-- database itself is assigning it (studios' `atlas.`, automatic `user.`),
-- which may use the shapes a person may not choose.
create or replace function public.handle_problem(h text, p_system boolean)
returns text language plpgsql stable security definer set search_path = public as $$
begin
    if h is null or h = '' then return 'is empty'; end if;
    if length(h) < 3 or length(h) > 24 then return 'must be 3 to 24 characters'; end if;
    if h !~ '^[a-z0-9._]+$' then return 'may use only letters, numbers, . and _'; end if;
    if h !~ '^[a-z0-9].*[a-z0-9]$' then return 'must start and end with a letter or number'; end if;
    if position('..' in h) > 0 then return 'may not have two dots in a row'; end if;
    if h !~ '[a-z]' then return 'must contain a letter'; end if;
    if not p_system then
        if exists (select 1 from public.reserved_handles r where r.handle = h)
           or h like 'dozent%' or h like 'atlas%' or h like 'user.%' then
            return 'reserved';
        end if;
        -- A creator we pin, on any platform, keeps their handle on Dozent too.
        if exists (select 1 from public.makers m where m.platform <> 'dozent' and m.handle = h) then
            return 'reserved';
        end if;
    end if;
    return null;
end $$;

-- Is this Dozent handle in use, or held after being given up, by anyone
-- other than `p_id`? (A person may always take back their own old handle.)
create or replace function public.handle_taken(h text, p_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.makers m
                    where m.platform = 'dozent' and m.handle = h and m.id is distinct from p_id)
        or exists (select 1 from public.released_handles r
                    where r.platform = 'dozent' and r.handle = h
                      and r.released_at > now() - interval '30 days'
                      and r.maker_id is distinct from p_id);
$$;

-- The automatic handle: from the display name in plain letters and numbers
-- (`Kathy Ng` -> `kathyng`), or `user.` + six characters of the id when the
-- name gives nothing usable. A clash gets a number: `kathyng2`.
create or replace function public.derive_account_handle(p_name text, p_id uuid)
returns text language plpgsql stable security definer set search_path = public as $$
declare
    base text;
    cand text;
    n    int := 2;
begin
    base := left(regexp_replace(lower(coalesce(p_name, '')), '[^a-z0-9]+', '', 'g'), 24);
    if coalesce(p_name, '') = 'New Creator' or public.handle_problem(base, false) is not null then
        base := 'user.' || left(replace(p_id::text, '-', ''), 6);
    end if;
    cand := base;
    while public.handle_taken(cand, p_id) loop
        cand := left(base, 22) || n;
        n := n + 1;
    end loop;
    return cand;
end $$;

revoke all on function public.handle_problem(text, boolean)     from public, anon, authenticated;
revoke all on function public.handle_taken(text, uuid)          from public, anon, authenticated;
revoke all on function public.derive_account_handle(text, uuid) from public, anon, authenticated;

-- ===========================================================================
-- 4. Backfill — every existing row, no action from anyone
-- ===========================================================================

-- 4a. Pinned creators: `Instagram @urbanistariel` -> instagram / urbanistariel
update public.makers
   set platform = lower(substring(display_name from '^(TikTok|Instagram|YouTube) @')),
       handle   = lower(substring(display_name from '^(?:TikTok|Instagram|YouTube) @(.+)$'))
 where handle is null
   and user_id is null
   and display_name ~ '^(TikTok|Instagram|YouTube) @.+$';

-- 4b. Atlas studios: `Atlas Studio NYC` -> dozent / atlas.nyc
update public.makers
   set platform = 'dozent',
       handle   = 'atlas.' || lower(right(display_name, 3))
 where handle is null
   and user_id is null
   and display_name ~ '^Atlas Studio [A-Za-z]{3}$';

-- 4c. Everyone else — the people with accounts. Oldest first, so if two names
--     make the same handle, the LATER signup is the one that gets a number.
do $backfill$
declare
    r record;
begin
    for r in select id, display_name from public.makers
              where handle is null
              order by created_at, id
    loop
        update public.makers
           set platform    = 'dozent',
               handle      = public.derive_account_handle(r.display_name, r.id),
               handle_auto = true
         where id = r.id;
    end loop;
end
$backfill$;

-- ===========================================================================
-- 5. Constraints — from here on, no row can exist without a valid pair
-- ===========================================================================
alter table public.makers alter column platform set not null;
alter table public.makers alter column handle   set not null;

alter table public.makers drop constraint if exists makers_platform_known;
alter table public.makers add  constraint makers_platform_known
    check (platform in ('dozent', 'instagram', 'tiktok', 'youtube'));

alter table public.makers drop constraint if exists makers_handle_normalised;
alter table public.makers add  constraint makers_handle_normalised
    check (handle = lower(handle) and handle !~ '^@' and handle !~ '\s'
           and length(handle) between 1 and 64);

-- A signed-in person is always on Dozent — otherwise anyone could set their
-- own row to 'instagram' and take a real creator's handle there.
alter table public.makers drop constraint if exists makers_person_on_dozent;
alter table public.makers add  constraint makers_person_on_dozent
    check (user_id is null or platform = 'dozent');

create unique index if not exists makers_platform_handle_key
    on public.makers (platform, handle);

-- ===========================================================================
-- 6. The guard — every future insert and update
-- ===========================================================================
create or replace function public.makers_handle_guard()
returns trigger language plpgsql security definer set search_path = public as $$
declare
    problem      text;
    name_changed boolean;
begin
    if new.handle is not null then
        new.handle := lower(btrim(new.handle));
        if left(new.handle, 1) = '@' then new.handle := substr(new.handle, 2); end if;
    end if;

    if tg_op = 'UPDATE' then
        -- The bookkeeping belongs to this trigger, never to the client.
        new.handle_auto       := old.handle_auto;
        new.handle_changed_at := old.handle_changed_at;
        if new.handle is null   then new.handle   := old.handle;   end if;
        if new.platform is null then new.platform := old.platform; end if;
        name_changed := new.display_name is distinct from old.display_name;
    else
        new.handle_auto       := false;
        new.handle_changed_at := null;
        name_changed := true;
    end if;

    if new.user_id is not null then
        -- ---- a person with an account ----
        if new.platform is not null and new.platform <> 'dozent' then
            raise exception using errcode = '23514',
                message = 'accounts are always on Dozent';
        end if;
        new.platform := 'dozent';

        -- Impersonation: a person's display name may not dress up as a pinned
        -- creator or a studio. Only checked when the name is being set.
        if name_changed and (new.display_name ~* '^\s*(tiktok|instagram|youtube)\s*@'
                             or new.display_name ~* '^\s*atlas\s+studio') then
            raise exception using errcode = '23514',
                message = 'That display name looks like an official or pinned account. Please choose another.';
        end if;

        if tg_op = 'INSERT' then
            if new.handle is null then
                new.handle      := public.derive_account_handle(new.display_name, new.id);
                new.handle_auto := true;
            elsif exists (select 1 from public.makers m where m.id = new.id and m.handle = new.handle) then
                -- An upsert of an existing row re-sending its own unchanged
                -- handle. Postgres fires this INSERT branch before it finds the
                -- conflict, so without this an automatic `user.` handle would
                -- be refused as "reserved" on an ordinary profile save.
                null;
            else
                problem := public.handle_problem(new.handle, false);
                if problem is null and public.handle_taken(new.handle, new.id) then
                    problem := 'is taken';
                end if;
                if problem is not null then
                    raise exception using errcode = '23514', message = 'That username ' || problem || '.';
                end if;
            end if;
        elsif new.handle is distinct from old.handle then
            problem := public.handle_problem(new.handle, false);
            if problem is null and public.handle_taken(new.handle, new.id) then
                problem := 'is taken';
            end if;
            if problem is not null then
                raise exception using errcode = '23514', message = 'That username ' || problem || '.';
            end if;
            if not old.handle_auto
               and old.handle_changed_at > now() - interval '30 days'
               and not public.is_admin() then
                raise exception using errcode = '23514',
                    message = 'A username can be changed once every 30 days.';
            end if;
            -- Hold the old one for 30 days so nobody can grab it straight away.
            insert into public.released_handles (platform, handle, maker_id, released_at)
            values ('dozent', old.handle, old.id, now())
            on conflict (platform, handle)
                do update set maker_id = excluded.maker_id, released_at = excluded.released_at;
            new.handle_changed_at := now();
            new.handle_auto       := false;
        end if;
    else
        -- ---- a pinned creator or a studio (seed / owner, never a signed-in person) ----
        if new.handle is null then
            if new.display_name ~ '^(TikTok|Instagram|YouTube) @.+$' then
                new.platform := coalesce(new.platform,
                    lower(substring(new.display_name from '^(TikTok|Instagram|YouTube) @')));
                new.handle   := lower(substring(new.display_name from '^(?:TikTok|Instagram|YouTube) @(.+)$'));
            elsif new.display_name ~ '^Atlas Studio [A-Za-z]{3}$' then
                new.handle   := 'atlas.' || lower(right(new.display_name, 3));
            else
                new.handle      := public.derive_account_handle(new.display_name, new.id);
                new.handle_auto := true;
            end if;
        end if;
        new.platform := coalesce(new.platform, 'dozent');
    end if;

    return new;
end $$;

revoke all on function public.makers_handle_guard() from public, anon, authenticated;

create trigger makers_handle_guard
    before insert or update on public.makers
    for each row execute function public.makers_handle_guard();

-- ===========================================================================
-- 7. The availability check for Edit Profile — a few bytes, signed-in only
--    Returns: 'available' | 'yours' | 'taken' | 'reserved' | 'invalid: <why>'
-- ===========================================================================
create or replace function public.handle_available(p_handle text)
returns text language plpgsql stable security definer set search_path = public as $$
declare
    h       text := lower(btrim(coalesce(p_handle, '')));
    me      uuid;
    problem text;
begin
    if left(h, 1) = '@' then h := substr(h, 2); end if;
    select m.id into me from public.makers m where m.user_id = auth.uid();
    if me is not null and exists (select 1 from public.makers m where m.id = me and m.handle = h) then
        return 'yours';
    end if;
    problem := public.handle_problem(h, false);
    if problem = 'reserved' then return 'reserved'; end if;
    if problem is not null then return 'invalid: ' || problem; end if;
    if public.handle_taken(h, me) then return 'taken'; end if;
    return 'available';
end $$;

revoke all on function public.handle_available(text) from public, anon;
grant execute on function public.handle_available(text) to authenticated;

-- ===========================================================================
-- 8. The catalogue: add `platform` and `handle` beside `isPrivate`
--
-- 🔴 PATCH THE LIVE FUNCTION, NEVER REPLACE IT FROM A FILE. No file in this
-- repo matches what is running; replacing from one is how places, priceTier
-- and isPrivate vanished for 14 hours on 2026-08-19. Same shape as
-- backend/add_video_role.sql: find by CONTENT, insert, refuse if the anchor
-- is not found exactly once, prove it took.
-- ===========================================================================
do $catalog$
declare
    target  regprocedure;
    src     text;
    patched text;
    anchor  constant text := '(''isPrivate''\s*,\s*(\w+)\.is_private)';
    hits    int;
begin
    select p.oid::regprocedure
      into target
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in ('get_catalog_core_base', 'get_catalog_core', 'get_catalog_built', 'get_catalog')
       and pg_get_functiondef(p.oid) ~ anchor
     order by array_position(array['get_catalog_core_base', 'get_catalog_core',
                                   'get_catalog_built', 'get_catalog']::text[], p.proname::text)
     limit 1;

    if target is null then
        raise exception 'no catalog function emits isPrivate - cannot place platform/handle beside it. '
            'Inspect: select proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace '
            'where n.nspname = ''public'' and proname like ''%%catalog%%'';';
    end if;

    src := pg_get_functiondef(target);

    if src ~ '''handle''\s*,\s*\w+\.handle' then
        raise notice '% already emits handle - nothing to patch.', target;
        return;
    end if;

    select count(*) into hits from regexp_matches(src, anchor, 'g');
    if hits <> 1 then
        raise exception 'found isPrivate % times in % - expected exactly 1, refusing to guess.', hits, target;
    end if;

    patched := regexp_replace(
        src, anchor,
        E'\\1,\n          ''platform'',       \\2.platform,\n          ''handle'',         \\2.handle'
    );

    if patched = src then
        raise exception 'could not patch % - refusing to guess.', target;
    end if;

    execute patched;

    if pg_get_functiondef(target) !~ '''handle''\s*,\s*\w+\.handle' then
        raise exception '% still does not emit handle after patching.', target;
    end if;

    raise notice '% now emits platform and handle.', target;
end
$catalog$;

commit;

-- ===========================================================================
-- 9. Rebuild the catalogue snapshot. LOAD-BEARING: phones read the snapshot,
--    so without this line nobody sees the new keys. Outside the transaction
--    on purpose — if the rebuild is slow, the migration above is already kept.
-- ===========================================================================
select public.refresh_catalog_snapshot();

-- ===========================================================================
-- 10. The receipt — the Editor shows only this last result, so it is the proof.
--
--   makers == with_handle          every row has one
--   duplicate_handles      = 0
--   accounts_off_dozent    = 0
--   catalog_serves_handle  = true
--   snapshot_rebuilt_at    = a minute ago
-- ===========================================================================
select
    (select count(*) from public.makers)                                  as makers,
    (select count(*) from public.makers where handle is not null)         as with_handle,
    (select count(*) from (select 1 from public.makers
                            group by platform, handle having count(*) > 1) d) as duplicate_handles,
    (select count(*) from public.makers
      where user_id is not null and platform <> 'dozent')                 as accounts_off_dozent,
    (select count(*) from public.makers where platform <> 'dozent')       as pinned_creators,
    (select count(*) from public.makers where user_id is not null)        as accounts,
    (select (payload -> 'makers' -> 0) ? 'handle' from public.catalog_snapshot) as catalog_serves_handle,
    (select refreshed_at from public.catalog_snapshot)                    as snapshot_rebuilt_at;

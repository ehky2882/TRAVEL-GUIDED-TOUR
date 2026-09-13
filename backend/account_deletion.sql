-- account_deletion.sql
--
-- The database half of "Delete my account" (Settings → Account). The other
-- half is the `delete-account` Edge Function (backend/functions/delete-account),
-- which calls this AS THE SIGNED-IN PERSON, then removes their uploaded files,
-- deletes their login, and rebuilds the catalogue snapshot.
--
-- WHY IT EXISTS
-- -------------
-- Apple App Review Guideline 5.1.1(v): an app that lets people create an
-- account must let them start deleting it from inside the app. And the privacy
-- policy (site/privacy/index.html) already promises what deletion means:
--
--   "Delete your account and we remove your profile, synced library and
--    creator content; records we must keep for legal or financial reasons are
--    retained in minimal form."
--
-- That sentence is the specification this file is built to.
--
-- WHAT DELETING THE LOGIN ALREADY DOES (no code needed)
-- -----------------------------------------------------
-- Deleting the `auth.users` row cascades: profiles, user_library,
-- user_saved_makers, user_recently_viewed, user_recent_searches,
-- user_saved_places, journeys, group sessions, follows. `purchases.user_id` is
-- `on delete set null`, so purchase records survive with the person removed —
-- the "minimal form" the policy promises.
--
-- WHAT IT DOES NOT DO, AND THIS FILE DOES
-- --------------------------------------
-- Every account gets a maker row at signup (`handle_new_user`), and
-- `makers.user_id` is `on delete set null`. So on its own, deleting the login
-- would leave the person's name, photo, bio and links behind on an orphaned
-- creator page. And `tours.maker_id` / `purchases.tour_id` are `on delete
-- restrict`, so their tours cannot simply cascade away.
--
-- Owner decision, 2026-09-13 ("Remove unsold, keep sold"):
--   • A tour NOBODY bought is deleted, with its stops (and, in the Edge
--     Function, its audio and photos).
--   • A tour SOMEONE bought stays, so the buyer keeps what they paid for. Its
--     creator page is anonymised to "Former creator" — name, photo, bio and
--     links removed.
--
-- 🔴 ONLY THE ACCOUNT HOLDER CAN TRIGGER THIS
-- -----------------------------------------
-- Standing decision: we never delete a user's account. This is the person
-- deleting their own. So the function takes NO user id — it acts only on
-- `auth.uid()`, the id inside the caller's own verified token — and it is not
-- executable by `anon`. There is no admin path and no parameter to point it at
-- anyone else. Everything it does, a signed-in person can already do to their
-- own rows through RLS (`tours_owner_delete`, `makers_owner_update`); it just
-- does it in one transaction.
--
-- HOW TO APPLY: paste this whole file into the Supabase SQL Editor and Run.
-- It only creates/replaces one function and adjusts grants — it deletes nothing
-- when applied. The last statement prints a receipt row to check.
--
-- Safe to re-run.

create or replace function public.delete_my_account_content()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    me            uuid := auth.uid();
    my_makers     uuid[];
    removed_tours uuid[];
    kept_tours    uuid[];
begin
    if me is null then
        raise exception using errcode = '42501',
            message = 'delete_my_account_content: sign in required';
    end if;

    select coalesce(array_agg(m.id), '{}') into my_makers
      from public.makers m
     where m.user_id = me;

    -- Hold this person's tours while we decide which were bought. A purchase
    -- being recorded at the same instant takes a key-share lock on its tour,
    -- so it waits for this transaction instead of racing it.
    perform 1 from public.tours t where t.maker_id = any(my_makers) for update;

    -- Unsold tours go. Stops cascade; other people's library rows, journey
    -- items and group sessions for these tours cascade too; reports keep the
    -- report and lose the link (`on delete set null`).
    with gone as (
        delete from public.tours t
         where t.maker_id = any(my_makers)
           and not exists (select 1 from public.purchases p where p.tour_id = t.id)
        returning t.id
    )
    select coalesce(array_agg(gone.id), '{}') into removed_tours from gone;

    -- What survives is exactly the set somebody paid for.
    select coalesce(array_agg(t.id), '{}') into kept_tours
      from public.tours t
     where t.maker_id = any(my_makers);

    -- Anonymise the creator page. The Edge Function deletes the row outright
    -- after the login is gone, whenever nothing restricts it (no kept tours,
    -- no purchases, no payouts) — so for almost everyone this is a brief
    -- intermediate state. The username (`handle`) is released there too: the
    -- usernames guard refuses a handle change on a row that still has an
    -- account behind it, by design.
    update public.makers m
       set display_name    = 'Former creator',
           bio             = '',
           avatar_url      = null,
           avatar_emoji    = null,
           avatar_initials = null,
           avatar_color    = null,
           website_url     = null,
           link_2_url      = null,
           link_3_url      = null,
           updated_at      = now()
     where m.id = any(my_makers);

    -- The username. `usernames.sql` holds a given-up handle for 30 days so
    -- nobody can take it over straight away and pass as the person who left;
    -- `handle_taken()` honours these rows. The handle itself is replaced (or
    -- the row deleted) by the Edge Function once the login is gone — the
    -- guard refuses that change while an account is still attached. Guarded,
    -- so this file also runs on a database without usernames.
    if to_regclass('public.released_handles') is not null
       and exists (select 1 from information_schema.columns
                    where table_schema = 'public' and table_name = 'makers'
                      and column_name = 'handle') then
        execute $sql$
            insert into public.released_handles (platform, handle, maker_id, released_at)
            select 'dozent', m.handle, m.id, now()
              from public.makers m
             where m.id = any($1) and m.handle is not null
            on conflict (platform, handle)
                do update set maker_id = excluded.maker_id, released_at = excluded.released_at
        $sql$ using my_makers;
    end if;

    -- Other people following or saving this creator: that relationship was
    -- with a person who has now left. (Guarded so a renamed or dropped table
    -- can never make deletion itself fail.)
    if to_regclass('public.follows') is not null then
        execute 'delete from public.follows where followee_id = any($1)' using my_makers;
    end if;
    if to_regclass('public.user_saved_makers') is not null then
        execute 'delete from public.user_saved_makers where maker_id = any($1)' using my_makers;
    end if;

    return jsonb_build_object(
        'makerIds',       to_jsonb(my_makers),
        'removedTourIds', to_jsonb(removed_tours),
        'keptTourIds',    to_jsonb(kept_tours)
    );
end $$;

-- Signed-in people only. Supabase grants new functions to anon directly, so
-- revoking from `public` alone would NOT be enough.
revoke all on function public.delete_my_account_content() from public, anon;
grant execute on function public.delete_my_account_content() to authenticated;

-- The Edge Function rebuilds the catalogue snapshot afterwards, as service
-- role, so a deleted tour or creator name stops being served. catalog_snapshot.sql
-- revokes this from anon/authenticated only; say the service-role grant
-- explicitly rather than relying on Supabase's default privileges.
grant execute on function public.refresh_catalog_snapshot() to service_role;

-- Receipt. Expect: is_security_definer = true, anon_can_run = false,
-- signed_in_can_run = true, service_can_refresh = true.
select
    p.prosecdef                                                         as is_security_definer,
    has_function_privilege('anon', p.oid, 'execute')                    as anon_can_run,
    has_function_privilege('authenticated', p.oid, 'execute')           as signed_in_can_run,
    has_function_privilege('service_role',
        'public.refresh_catalog_snapshot()'::regprocedure, 'execute')   as service_can_refresh
from pg_proc p
where p.oid = 'public.delete_my_account_content()'::regprocedure;

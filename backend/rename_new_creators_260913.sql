-- rename_new_creators_260913.sql
--
-- ✅ APPLIED by the owner, 2026-09-13 01:26 UTC. Kept as the record of what ran.
-- 🔴 DO NOT RE-RUN AS A POLICY. Owner, 2026-09-13: "change them to the
-- '@username' for now. we'll only do this this one time." New signups that
-- arrive with no name still become "New Creator" — deliberately unchanged.
--
-- What it did: the accounts still called "New Creator" (the fallback name
-- `handle_new_user()` gives when Apple / email supply none) took their
-- username as their display name — `New Creator` -> `@user.f15619`. Usernames
-- were not touched; nothing was deleted or merged. An explicit owner
-- instruction, and the ONLY rename of accounts on record: the standing rule
-- is still that we never rename, merge or delete an account.
--
-- Receipt the owner saw: still_new_creator 0 · named_after_username 16 ·
-- snapshot_rebuilt_at 2026-09-13 01:26:31 UTC.
-- Verified from outside the same hour via PostgREST counts: 0 rows named
-- "New Creator", 16 accounts named `@user.*`, 28 accounts in total (unchanged).
--
-- The app hides the username line under a name that already IS the username
-- (`Maker.profileHandleLine`, PR #849), so these pages do not say it twice.

update public.makers
   set display_name = '@' || handle,
       updated_at   = now()
 where display_name = 'New Creator'
   and user_id is not null;

-- Phones read a saved copy of the catalogue, so rebuild it.
select public.refresh_catalog_snapshot();

-- The proof.
select
  (select count(*) from public.makers where display_name = 'New Creator') as still_new_creator,
  (select count(*) from public.makers
    where user_id is not null and display_name = '@' || handle)         as named_after_username,
  (select refreshed_at from public.catalog_snapshot)                    as snapshot_rebuilt_at;

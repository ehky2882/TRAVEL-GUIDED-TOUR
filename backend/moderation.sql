-- Atlas backend — moderation admin helpers (V2 Step 5, minimal)
--
-- Run AFTER backend/accounts.sql (needs is_admin()). For the V2-launch minimal
-- moderation model (owner decision 2026-06-21): the Atlas team is emailed when a
-- tour is submitted or a report is filed (see backend/functions/notify-moderation/),
-- then acts manually. These helpers make "act manually" a one-liner instead of a
-- raw UPDATE, and keep the publish/takedown gate in one audited place.
--
-- The review queue itself is the moderation_queue view from accounts.sql
-- (tours where status='in_review').

begin;

-- Publish a reviewed tour (admin only). published_at set once, on first publish.
create or replace function public.publish_tour(t uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
    if not public.is_admin() then
        raise exception 'not authorized';
    end if;
    update public.tours
       set status = 'published',
           published_at = coalesce(published_at, now()),
           updated_at = now()
     where id = t;
end; $$;

-- Take a tour down (admin only).
create or replace function public.takedown_tour(t uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
    if not public.is_admin() then
        raise exception 'not authorized';
    end if;
    update public.tours set status = 'taken_down', updated_at = now() where id = t;
end; $$;

grant execute on function public.publish_tour(uuid)  to authenticated;
grant execute on function public.takedown_tour(uuid) to authenticated;

commit;

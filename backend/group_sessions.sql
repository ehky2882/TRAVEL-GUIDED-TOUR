-- Atlas backend — Group Listen "Hosted" mode (V2 feature: group-listen)
--
-- Run AFTER backend/accounts.sql (needs auth.users). This backs the ONLINE
-- "Hosted" group-listen mode only — the offline "Nearby" mode (MultipeerConnectivity)
-- needs no backend. Design: docs/group-listen-design.md.
--
-- NOT NEEDED until Group Listen Phase 2 (Hosted mode). Do not apply preemptively;
-- included so the local session that builds Hosted mode has the schema ready.
--
-- Live sync itself uses Supabase **Realtime broadcast + presence** on a channel named
-- by session id (lower-latency + ephemeral; gives the roster for free). This table is
-- only for: code→session lookup, the last-known state (so late-joiners snap in), the
-- current leader (for handoff), and the Pro flag. No `supabase_realtime` publication is
-- required for broadcast/presence.

begin;

create table if not exists public.group_sessions (
    id             uuid primary key default gen_random_uuid(),
    code           text not null unique,               -- short join code, e.g. 'MET-4821'
    tour_id        uuid not null references public.tours (id) on delete cascade,
    host_user_id   uuid not null references auth.users (id) on delete cascade,
    leader_user_id uuid not null references auth.users (id) on delete cascade, -- current leader (starts = host)
    session_epoch  int  not null default 0,            -- bumped on leadership handoff; clients ignore lower epochs
    is_pro         boolean not null default false,     -- Pro Guide session
    status         text not null default 'active',     -- 'active' | 'ended'
    last_state     jsonb,                              -- last GroupPlaybackState, so late-joiners sync immediately
    created_at     timestamptz not null default now(),
    ended_at       timestamptz
);

-- Fast lookup of the active session for a join code.
create unique index if not exists idx_group_sessions_active_code
    on public.group_sessions (code) where status = 'active';

alter table public.group_sessions enable row level security;

-- Read: any signed-in user may read an ACTIVE session. The join code is the capability
-- (you must know it to find the row), and the row holds no sensitive data.
drop policy if exists group_sessions_read on public.group_sessions;
create policy group_sessions_read on public.group_sessions
    for select to authenticated using (status = 'active');

-- Create: a signed-in user may open a session they host (and initially lead).
drop policy if exists group_sessions_create on public.group_sessions;
create policy group_sessions_create on public.group_sessions
    for insert to authenticated
    with check (host_user_id = auth.uid() and leader_user_id = auth.uid());

-- Update: only the current leader or the host may mutate it (broadcast last_state, end it,
-- reassign leadership). Leadership *claims* by other members go through claim_leadership().
drop policy if exists group_sessions_update on public.group_sessions;
create policy group_sessions_update on public.group_sessions
    for update to authenticated
    using (leader_user_id = auth.uid() or host_user_id = auth.uid())
    with check (leader_user_id = auth.uid() or host_user_id = auth.uid());

-- Leadership handoff / takeover. A member claims the lead (e.g. the leader dropped).
-- Free sessions: any signed-in caller may claim (co-located, account-gated, socially
-- trusted). Pro sessions: only the host may reassign. Bumps the epoch so stale
-- broadcasts from the old leader are ignored.
create or replace function public.claim_leadership(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
declare s public.group_sessions;
begin
    select * into s from public.group_sessions where id = p_session and status = 'active';
    if not found then raise exception 'no active session'; end if;
    if s.is_pro and s.host_user_id <> auth.uid() then
        raise exception 'only the host can reassign leadership in a Pro session';
    end if;
    if auth.uid() is null then raise exception 'must be signed in'; end if;
    update public.group_sessions
       set leader_user_id = auth.uid(),
           session_epoch  = session_epoch + 1
     where id = p_session;
end; $$;

grant select, insert, update on public.group_sessions to authenticated;
grant execute on function public.claim_leadership(uuid) to authenticated;

commit;

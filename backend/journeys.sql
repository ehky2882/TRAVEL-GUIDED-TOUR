-- Atlas backend — Journeys (user-curated collections of tours)
--
-- Run AFTER backend/accounts.sql (needs auth.users, public.tours, public.is_admin()).
-- Design: docs/journeys-design.md. A Journey is an ordered, editable list of WHOLE tours
-- (single- or multi-stop; multi-stop tours are never split). Any signed-in account can
-- create Journeys ("anyone can be a Dozent"); public Journeys are world-readable like
-- published tours. Tour *content* is not duplicated — journey_items store only tour ids.
--
-- NOT NEEDED until the Journeys feature is built. Included so the local session that
-- builds it has the schema ready.

begin;

-- ===========================================================================
-- journeys
-- ===========================================================================
create table if not exists public.journeys (
    id              uuid primary key default gen_random_uuid(),
    owner_user_id   uuid not null references auth.users (id) on delete cascade,
    title           text not null,
    description     text,
    cover_image_url text,                              -- optional; can default to first tour's hero
    is_public       boolean not null default false,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);
create index if not exists idx_journeys_owner  on public.journeys (owner_user_id);
create index if not exists idx_journeys_public on public.journeys (is_public) where is_public;

-- ===========================================================================
-- journey_items — ordered tour references + per-tour curator note
-- ===========================================================================
create table if not exists public.journey_items (
    journey_id uuid not null references public.journeys (id) on delete cascade,
    tour_id    uuid not null references public.tours (id) on delete cascade,
    position   int  not null,
    note       text,                                  -- the curator's per-tour note
    added_at   timestamptz not null default now(),
    primary key (journey_id, tour_id)                 -- a tour appears once per Journey
);
create index if not exists idx_journey_items_order on public.journey_items (journey_id, position);

-- ===========================================================================
-- saved_journeys — a user saving someone else's Journey (mirrors user_saved_makers)
-- ===========================================================================
create table if not exists public.saved_journeys (
    user_id    uuid not null references auth.users (id) on delete cascade,
    journey_id uuid not null references public.journeys (id) on delete cascade,
    saved_at   timestamptz not null default now(),
    primary key (user_id, journey_id)
);

-- ===========================================================================
-- RLS
-- ===========================================================================
alter table public.journeys       enable row level security;
alter table public.journey_items  enable row level security;
alter table public.saved_journeys enable row level security;

-- journeys: readable by owner always, by anyone if public; writable by owner; admin moderates.
drop policy if exists journeys_read on public.journeys;
create policy journeys_read on public.journeys
    for select using (owner_user_id = auth.uid() or is_public);
drop policy if exists journeys_owner_write on public.journeys;
create policy journeys_owner_write on public.journeys
    for all using (owner_user_id = auth.uid()) with check (owner_user_id = auth.uid());
drop policy if exists journeys_admin on public.journeys;
create policy journeys_admin on public.journeys
    for all using (public.is_admin()) with check (public.is_admin());

-- journey_items: visible if the parent journey is visible; writable by the journey's owner.
drop policy if exists journey_items_read on public.journey_items;
create policy journey_items_read on public.journey_items
    for select using (
        exists (
            select 1 from public.journeys j
            where j.id = journey_items.journey_id
              and (j.owner_user_id = auth.uid() or j.is_public or public.is_admin())
        )
    );
drop policy if exists journey_items_owner_write on public.journey_items;
create policy journey_items_owner_write on public.journey_items
    for all using (
        exists (select 1 from public.journeys j
                where j.id = journey_items.journey_id and j.owner_user_id = auth.uid())
    ) with check (
        exists (select 1 from public.journeys j
                where j.id = journey_items.journey_id and j.owner_user_id = auth.uid())
    );

-- saved_journeys: each user manages only their own saves.
drop policy if exists saved_journeys_own on public.saved_journeys;
create policy saved_journeys_own on public.saved_journeys
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ===========================================================================
-- get_journey() — a Journey + its ordered items (tour ids + notes) in one call,
-- for the detail screen / shared deep link. Runs SECURITY INVOKER so RLS applies
-- (a private Journey is only returned to its owner).
-- ===========================================================================
create or replace function public.get_journey(p_journey uuid)
returns jsonb language sql stable as $$
    select jsonb_build_object(
        'id',            j.id,
        'ownerUserId',   j.owner_user_id,
        'title',         j.title,
        'description',   j.description,
        'coverImageURL', j.cover_image_url,
        'isPublic',      j.is_public,
        'items', coalesce((
            select jsonb_agg(
                jsonb_build_object('tourId', i.tour_id, 'position', i.position, 'note', i.note)
                order by i.position
            )
            from public.journey_items i
            where i.journey_id = j.id
        ), '[]'::jsonb)
    )
    from public.journeys j
    where j.id = p_journey;
$$;

-- ===========================================================================
-- Grants (RLS is the real gate). Public Journeys are readable by anon (like tours);
-- creating/saving requires an authenticated user.
-- ===========================================================================
grant select on public.journeys, public.journey_items to anon, authenticated;
grant insert, update, delete on public.journeys, public.journey_items to authenticated;
grant select, insert, update, delete on public.saved_journeys to authenticated;
grant execute on function public.get_journey(uuid) to anon, authenticated;

commit;

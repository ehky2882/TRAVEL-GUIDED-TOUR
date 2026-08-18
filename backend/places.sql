-- Atlas / Dozent — the place layer
-- =================================================================
-- A "place" is a physical site that more than one tour describes. Until this
-- table existed, every tour owned its own map pin, so two tours on the same
-- coordinate produced a cluster pin that no camera could separate and no tap
-- could open.
--
-- IDENTITY IS EXACT COORDINATE EQUALITY (owner decision, 2026-08-18).
-- A 40 m proximity rule was measured against the live catalog first and
-- rejected: it produced 43 places of which 19 were wrong, merging LACMA with
-- the Academy Museum, two unrelated Sydney restaurants, and chaining three
-- separate La Boca venues into one site. Anything looser than an exact match
-- must be approved by a human before a user ever sees it.
--
-- Places are CONTENT: they live in Tours.json and arrive here through the same
-- seeding path as makers and tours, so the gh-pages mirror and the bundled
-- offline catalog carry them too. (Contrast tours.price_tier, which lives ONLY
-- here so a content re-seed can never wipe pricing.)
--
-- Idempotent. Safe to run more than once. Paste into the Supabase SQL Editor.
-- =================================================================

create table if not exists public.places (
    id             uuid primary key,
    name           text not null,
    description    text,
    latitude       double precision not null,
    longitude      double precision not null,
    city           text,
    address        text,
    hero_image_url text,
    -- Further photos, shown after the hero in the place page's carousel.
    -- Empty everywhere today; the column exists so step 4's editorial pass has
    -- somewhere to put them without another migration.
    additional_image_urls text[],
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now()
);

-- Idempotent upgrade path: the table shipped before place photos existed, so a
-- database created by the first version of this file needs the column added.
-- `if not exists` makes running the whole file safe either way.
alter table public.places add column if not exists additional_image_urls text[];

-- A tour belongs to at most one place. `on delete set null` so removing a
-- place never removes tours — the tours are the valuable thing.
alter table public.tours
    add column if not exists place_id uuid references public.places(id) on delete set null;

create index if not exists tours_place_id_idx on public.tours(place_id);

-- Read-only to clients, like the rest of the catalog. Writes arrive from the
-- seeding path under the service role only.
alter table public.places enable row level security;

drop policy if exists places_public_read on public.places;
create policy places_public_read on public.places
    for select using (true);

revoke insert, update, delete on public.places from anon, authenticated;
grant select on public.places to anon, authenticated;


-- =================================================================
-- Exposing places through get_catalog()
--
-- 🔴 This deliberately does NOT rewrite get_catalog's body. Four files in this
-- repo have rebuilt that function at different times (schema, add_video_urls,
-- public_lists, paid_tours) and there is no way to tell from the repo which
-- version is live. Retyping it from the newest file on disk risks silently
-- dropping whatever the *other* files added — `videoURLs` or `userId` would
-- simply stop being emitted, and nothing would error.
--
-- So we wrap it. The existing function is renamed once and called unchanged;
-- this layer only appends a `places` key. Whatever it returns today, it keeps
-- returning.
--
-- ⚠️ CONSEQUENCE WORTH KNOWING: if you ever re-run one of those older files,
-- its `create or replace function public.get_catalog()` will overwrite this
-- wrapper and places will quietly vanish from the payload. Re-run this file
-- afterwards to restore it.
-- =================================================================

-- Just the places array, so the wrapper below stays a one-liner.
create or replace function public.catalog_places()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
    select coalesce(jsonb_agg(p), '[]'::jsonb)
    from (
        select
            pl.id,
            pl.name,
            pl.description,
            pl.latitude,
            pl.longitude,
            pl.city,
            pl.address,
            pl.hero_image_url as "heroImageURL",
            pl.additional_image_urls as "additionalImageURLs",
            (
                select coalesce(jsonb_agg(t.id), '[]'::jsonb)
                from public.tours t
                where t.place_id = pl.id
                  and t.status = 'published'
            ) as "tourIds"
        from public.places pl
        -- A place needs at least two published tours to mean anything; one
        -- would draw a count badge reading "1".
        where (
            select count(*) from public.tours t2
            where t2.place_id = pl.id and t2.status = 'published'
        ) >= 2
    ) p;
$$;

-- Rename the current get_catalog aside, exactly once. Guarded so re-running
-- this whole file is a no-op rather than a second rename.
do $$
begin
    if not exists (
        select 1 from pg_proc
        where proname = 'get_catalog_core'
          and pronamespace = 'public'::regnamespace
    ) then
        alter function public.get_catalog() rename to get_catalog_core;
    end if;
end $$;

-- The public entry point: whatever the catalog was, plus places.
-- `||` merges at the top level, so every existing key is preserved untouched.
create or replace function public.get_catalog()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
    select public.get_catalog_core()
         || jsonb_build_object('places', public.catalog_places());
$$;

grant execute on function public.get_catalog() to anon, authenticated;
grant execute on function public.catalog_places() to anon, authenticated;

-- Verify after running:
--   select jsonb_array_length(get_catalog() -> 'places');   -- expect 24
--   select jsonb_array_length(get_catalog() -> 'tours');    -- expect 1350
--   select jsonb_array_length(get_catalog() -> 'makers');   -- expect 30

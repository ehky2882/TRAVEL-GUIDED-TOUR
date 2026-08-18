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
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now()
);

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


-- =================================================================
-- The 24 places themselves, and which tours belong to each.
--
-- Generated from Tours.json. Re-running is safe: places upsert by id,
-- and membership is cleared before being reassigned so a tour that
-- leaves a place doesn't keep a stale link.
-- =================================================================

insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('62188f13-c864-5759-84d6-164a052e951a', 'Centraal Station', null, 52.379, 4.9002, 'Amsterdam', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('41dd8a45-b3f0-5846-8d5b-b65dd31f89dd', 'Dam Square', null, 52.3731, 4.89135, 'Amsterdam', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('73f7a252-3d50-59ce-a5cc-d8d3215fd77e', 'Rijksmuseum', null, 52.36, 4.8853, 'Amsterdam', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('e71fe7f3-d16d-578f-94b2-adb21a47055e', 'Waterlooplein', null, 52.3694, 4.9014, 'Amsterdam', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('4690687e-da8b-52d8-8a80-c87c6beb1c13', 'Westerkerk', null, 52.3747, 4.8839, 'Amsterdam', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('60270b85-f701-5e6f-8cd0-8118ad672de0', 'Brandenburg Gate', null, 52.5163, 13.3777, 'Berlin', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('49d92f6a-35b9-5b3e-94c1-8a0baa1c74af', 'Hackesche Höfe', null, 52.5251, 13.4024, 'Berlin', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('0abbc584-b2bb-5caa-8916-8d002a06d1df', 'Oberbaumbrücke', null, 52.5018, 13.4457, 'Berlin', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('b1032711-ccb5-58d7-8a0d-89c1b53ed1d8', 'Potsdamer Platz', null, 52.5096, 13.3759, 'Berlin', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('da072e04-47a9-5f02-a4f6-a31c89df2594', 'Al Shindagha', null, 25.268, 55.2901, 'Dubai', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('ddaeb5dd-9cfd-554f-9498-792d27b42ef1', 'The Marina Walk', null, 25.0811, 55.1406, 'Dubai', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('912c6376-cf5a-5695-9ded-771d564d4b43', 'The Textile Souk', null, 25.263, 55.2961, 'Dubai', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('635ff732-727b-5762-9557-0b7fa65be6fb', 'Walt Disney Concert Hall', null, 34.0553, -118.2498, 'Los Angeles', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('2cd38ec7-d093-52e6-b957-5088fd3e68f3', 'Dorchester Square', null, 45.4997, -73.571, 'Montreal', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('51e74e21-10a6-5250-a5f3-64525c3b3745', 'Notre-Dame Basilica', null, 45.50451, -73.55627, 'Montreal', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('3d3ee7cd-0e8a-5a56-9aa0-4b4fd1430822', 'Square Saint-Louis', null, 45.5165, -73.5665, 'Montreal', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('4435887d-53bd-5064-b27c-83c22a14a94e', 'Largo di Torre Argentina', null, 41.8955, 12.4768, 'Rome', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('8c87e077-1caf-5005-afea-df268e4ea3b2', 'Piazza del Popolo', null, 41.9109, 12.4763, 'Rome', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('aa7c725d-ab51-5a26-92f1-6349f3fe6fcf', 'The Circus Maximus', null, 41.8859, 12.4853, 'Rome', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('7e9e741b-c141-5561-85fa-626deebea2a8', 'The Colosseum', null, 41.8902, 12.4922, 'Rome', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('2712fd32-85e0-53a8-b35c-7699c3f86a86', 'Art Gallery of Ontario', null, 43.6536, -79.3925, 'Toronto', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('6477a6fa-400d-542c-9765-59b9fb0101c1', 'CN Tower', null, 43.6426, -79.3871, 'Toronto', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('7f9a43cb-8b18-55d1-9a05-3ba5cc82ab06', 'Royal Ontario Museum', null, 43.6677, -79.3948, 'Toronto', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();
insert into public.places (id, name, description, latitude, longitude, city, address, hero_image_url) values ('14774d3b-7bd4-564c-a833-a4e145136bf4', 'Union Station', null, 43.6453, -79.3806, 'Toronto', null, null) on conflict (id) do update set name = excluded.name, description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude, city = excluded.city, address = excluded.address, hero_image_url = excluded.hero_image_url, updated_at = now();

-- membership
update public.tours set place_id = null where place_id is not null;
update public.tours set place_id = '62188f13-c864-5759-84d6-164a052e951a' where id in ('699295da-c427-522e-9c4a-17c5057f2d3a', 'a48cc6fe-7c4b-5a82-a91c-474c9964a648');
update public.tours set place_id = '41dd8a45-b3f0-5846-8d5b-b65dd31f89dd' where id in ('80943c5f-f117-59a3-bfcc-e55d8a78b63f', 'e816a1e6-2368-55d1-a947-9059c5645bb7');
update public.tours set place_id = '73f7a252-3d50-59ce-a5cc-d8d3215fd77e' where id in ('35d28cdd-df23-5b4d-99b8-ef54948db57d', 'e2e6d14f-aec1-546c-8930-3d2c4a72c6d8');
update public.tours set place_id = 'e71fe7f3-d16d-578f-94b2-adb21a47055e' where id in ('8b127963-bdb4-5e8d-8b89-f7e427e09380', 'f10df936-6cc7-52ff-90c4-2a73faebb54a');
update public.tours set place_id = '4690687e-da8b-52d8-8a80-c87c6beb1c13' where id in ('0d0c581a-5e72-5aa4-a1e5-b8a70bf23f0d', '0e0bbe76-3b8d-5ace-934c-991b9c8c3997');
update public.tours set place_id = '60270b85-f701-5e6f-8cd0-8118ad672de0' where id in ('17b809c4-9de8-564c-ab43-c09a9c9cc2c9', '893d656a-6ec8-5520-b5f8-fd63c60ae4b5');
update public.tours set place_id = '49d92f6a-35b9-5b3e-94c1-8a0baa1c74af' where id in ('03e5c64c-8ea5-57b5-8d9d-0ec003b4f1ed', 'e3f6f384-4168-5656-a35b-1546b03fe0f0');
update public.tours set place_id = '0abbc584-b2bb-5caa-8916-8d002a06d1df' where id in ('ad28fb21-7e62-5252-8679-7e2f37b20c66', 'dc88f86f-d38c-5344-9c53-26e4ef9f97bf');
update public.tours set place_id = 'b1032711-ccb5-58d7-8a0d-89c1b53ed1d8' where id in ('03c0f1c1-0a74-521c-88b3-87927f33f954', '76127777-fee0-53a2-809c-d00386c0f2fe');
update public.tours set place_id = 'da072e04-47a9-5f02-a4f6-a31c89df2594' where id in ('32130aa0-c428-5cb8-bf65-49d780ad4d02', 'cb214a2c-ae60-5242-a96c-a27e21e76523');
update public.tours set place_id = 'ddaeb5dd-9cfd-554f-9498-792d27b42ef1' where id in ('54206005-4cd6-52f9-8cbc-965ee288e59d', 'c84a6965-b12e-5238-8ffc-93258015d57f');
update public.tours set place_id = '912c6376-cf5a-5695-9ded-771d564d4b43' where id in ('22bd261c-2628-5e99-813a-58065f05d116', '296d2093-704e-5892-a8c6-ee614a63cd4a');
update public.tours set place_id = '635ff732-727b-5762-9557-0b7fa65be6fb' where id in ('9bca06a3-7d7d-571c-a1c3-9e243dd82d6e', 'e22f888b-f47f-5f4e-9cfe-cd6842e7d671');
update public.tours set place_id = '2cd38ec7-d093-52e6-b957-5088fd3e68f3' where id in ('697e4008-1260-5ea6-8d61-107a45d725e9', 'fd836835-98e7-5174-b87c-5d4b63fa08e9');
update public.tours set place_id = '51e74e21-10a6-5250-a5f3-64525c3b3745' where id in ('602d0b82-1817-593c-a3fa-6dc962a73faf', 'f1299ecf-7c16-56e0-bc2a-d2f6c3c16ebc');
update public.tours set place_id = '3d3ee7cd-0e8a-5a56-9aa0-4b4fd1430822' where id in ('05c51585-2ac1-5f1d-8b90-8ef8a4dcc09b', '6d3f40c1-6c3a-53e9-a090-d163082c47e2');
update public.tours set place_id = '4435887d-53bd-5064-b27c-83c22a14a94e' where id in ('18696d8a-c775-51c5-b9d8-4129ed1ff1a1', 'b898ab3b-374b-50bd-a53b-dbbacf55a12e');
update public.tours set place_id = '8c87e077-1caf-5005-afea-df268e4ea3b2' where id in ('675cff67-7f73-543a-8339-61b55d4a8ec8', 'c15de21e-c8e2-5e35-8fea-c389b51ad4c2');
update public.tours set place_id = 'aa7c725d-ab51-5a26-92f1-6349f3fe6fcf' where id in ('b7505267-48e7-5ad6-8924-a1e347750012', 'c7d6db46-7c8a-59a3-92af-7f3429d719df');
update public.tours set place_id = '7e9e741b-c141-5561-85fa-626deebea2a8' where id in ('1f0bf5a5-e56d-5648-8b34-be4bc9cd10da', '9c40bfd5-5e9c-55c4-a38a-c16bd38ccbf8');
update public.tours set place_id = '2712fd32-85e0-53a8-b35c-7699c3f86a86' where id in ('4a191d84-138a-5b84-a851-530ab411f77d', 'de8989de-b757-5ffd-82cc-82f6ee3d17f6');
update public.tours set place_id = '6477a6fa-400d-542c-9765-59b9fb0101c1' where id in ('463962a5-669f-5d58-9c35-7be9a99dfe1b', 'e39a0068-04b9-521b-9f24-db0dfb46f3df');
update public.tours set place_id = '7f9a43cb-8b18-55d1-9a05-3ba5cc82ab06' where id in ('096a3cba-09b6-57e7-8379-2e49f3a7b507', '0d3e20aa-bd74-524f-a147-6273f94b2355');
update public.tours set place_id = '14774d3b-7bd4-564c-a833-a4e145136bf4' where id in ('c65f4997-55ed-5ab7-ab20-617e784e2175', 'e7b135f9-f4d8-51a5-93d5-6c17f4367682');

-- Verify (expect 24, then 1350, then 30):
--   select jsonb_array_length(get_catalog() -> 'places');
--   select jsonb_array_length(get_catalog() -> 'tours');
--   select jsonb_array_length(get_catalog() -> 'makers');

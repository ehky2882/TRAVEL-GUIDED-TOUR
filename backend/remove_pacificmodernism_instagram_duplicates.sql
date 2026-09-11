-- Removes the two @pacificmodernism Instagram-sourced link pins that PR #804
-- replaced with their TikTok equivalents (145 Natoma Street, The Wind Harp).
--
-- 🔴 Why this file exists at all: `seed_from_toursjson.py` is UPSERT-ONLY.
-- Deleting a pin from Resources/Tours.json reaches the gh-pages mirror and
-- the bundled offline seed, but never reaches Postgres — the app's PRIMARY
-- source (docs/lessons.md, "Deleting from Tours.json does NOT remove it from
-- Postgres"). A removal is always a two-part change: the catalogue edit
-- (#804, already merged) PLUS this SQL, run once against the live database.
--
-- Safe to paste into the Supabase SQL Editor as-is. `on delete cascade` on
-- every table that references a tour (accounts.sql, group_sessions.sql,
-- journeys.sql, schema.sql) means any user-side row pointing at these two
-- pins (a save, a library entry) is cleaned up automatically; the only
-- non-cascading reference is paid_tours.sql's `on delete restrict`, which
-- cannot fire here — these are free link pins, priceUSD 0, never purchasable.
--
-- NOT SAFE TO RE-RUN blindly on a different pair of ids without checking
-- them against the live catalogue first — this file names two specific rows.

begin;

delete from public.stops
where tour_id in (
  'A5879E64-1CC9-5C51-A7D8-95B158797781',  -- 145 Natoma Street stop
  'B6608806-059D-5495-B8D3-D01295CC91EB'   -- The Wind Harp stop
);

delete from public.tours
where id in (
  'A5879E64-1CC9-5C51-A7D8-95B158797781',  -- 145 Natoma Street (Instagram)
  'B6608806-059D-5495-B8D3-D01295CC91EB'   -- The Wind Harp (Instagram)
);

-- The Instagram-platform maker row for @pacificmodernism. Only removed if
-- nothing else still references it (it should be orphaned by the two
-- deletes above — the TikTok pins from #804 use a different maker row,
-- keyed on platform+handle, so this one has no other pins pointing at it).
delete from public.makers
where id = '06A62BFA-999A-5E44-B684-812271F99F95'
  and not exists (
    select 1 from public.tours where maker_id = '06A62BFA-999A-5E44-B684-812271F99F95'
  );

-- get_catalog() serves a materialised snapshot, so the RPC would keep
-- serving these two rows until the snapshot is rebuilt.
select public.refresh_catalog_snapshot();

commit;

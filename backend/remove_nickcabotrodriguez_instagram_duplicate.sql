-- Removes the one @nickcabotrodriguez Instagram-sourced link pin that
-- duplicates his own TikTok post of the same video (Isle of Capri, the
-- "History of Restaurants Episode 5" reel). Owner's call, 2026-09-20.
--
-- 🔴 Why this file exists at all: `seed_from_toursjson.py` is UPSERT-ONLY.
-- Deleting a pin from Resources/Tours.json reaches the gh-pages mirror and
-- the bundled offline seed, but never reaches Postgres — the app's PRIMARY
-- source (docs/lessons.md, "Deleting from Tours.json does NOT remove it from
-- Postgres"). A removal is always a two-part change: the catalogue edit
-- PLUS this SQL, run once against the live database.
--
-- ⚠️ THE MAKER ROW IS DELIBERATELY KEPT. Unlike the @pacificmodernism case
-- this file is modelled on, Instagram @nickcabotrodriguez still has THREE
-- other pins (Museum of Chinese in America, Church of St Vincent de Paul,
-- Hollywood First National Bank Building), so deleting it would orphan them.
-- Verified against the catalogue before this file was written.
--
-- Safe to paste into the Supabase SQL Editor as-is. `on delete cascade` on
-- every table that references a tour means any user-side row pointing at
-- this pin (a save, a library entry) is cleaned up automatically; the only
-- non-cascading reference is paid_tours.sql's `on delete restrict`, which
-- cannot fire here — it is a free link pin, priceUSD 0, never purchasable.
--
-- NOT SAFE TO RE-RUN blindly on different ids. This file names one row.

begin;

delete from public.stops
where tour_id = '0A3CF38F-EA7C-58D9-9AC7-D8DCFCA99A52';  -- Isle of Capri stop

delete from public.tours
where id = '0A3CF38F-EA7C-58D9-9AC7-D8DCFCA99A52';       -- Isle of Capri (Instagram)

-- get_catalog() serves a materialised snapshot, so the RPC would keep
-- serving this row until the snapshot is rebuilt.
select public.refresh_catalog_snapshot();

commit;

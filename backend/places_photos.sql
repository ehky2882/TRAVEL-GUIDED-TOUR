-- Place photos — one small upgrade to a database that already has the place
-- layer applied (backend/places_apply.sql, run 2026-08-18).
--
-- WHAT THIS DOES
--   1. Adds one column to `places` for extra photos of a site.
--   2. Teaches the catalog to send that column to the app.
--
-- WHAT IT DOES NOT DO
--   Nothing is deleted, nothing is renamed, no tour or place row changes. The
--   column starts empty on every place, so the app looks exactly the same the
--   moment after you run it. It matters later, when place photos are written.
--
-- SAFE TO RUN TWICE. Both statements are written so a second run is a no-op.
--
-- HOW TO RUN IT
--   Supabase dashboard -> SQL Editor -> New query -> paste all of this -> Run.
--   Expect: "Success. No rows returned."

-- 1. The column. `if not exists` is what makes a repeat run harmless.
alter table public.places add column if not exists additional_image_urls text[];

-- 2. Send it to the app. This replaces one function body; it does not touch
--    get_catalog itself, which already calls this one.
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

grant execute on function public.catalog_places() to anon, authenticated;

-- Check it worked — run this on its own afterwards, expect 24:
--   select jsonb_array_length(get_catalog() -> 'places');

-- ============================================================================
-- 🔴 NO LONGER SAFE TO RE-RUN. THIS FILE WOULD DESTROY THE PLACE LAYER.
--
-- It contains `create or replace function public.get_catalog()`. That was
-- correct when written. It is not any more.
--
-- `places.sql` RENAMED the then-current `get_catalog` to `get_catalog_core`
-- and made `get_catalog` a three-line wrapper:
--
--     get_catalog() = get_catalog_core() || { places: catalog_places() }
--
-- So replacing `get_catalog()` today overwrites the WRAPPER with a full body,
-- severing the call to the core. The result: all 25 places gone, and every
-- key the core has gained since this file was written gone with them -
-- `priceTier`, `isPrivate`, `country`, `videoURLs`, `videoRole`. No error.
-- The app simply stops receiving them.
--
-- ⚠️ The "idempotent - safe to re-run" note below refers to the table and
-- policy statements, which are still fine. It does NOT cover the function.
--
-- TO CHANGE WHAT THE CATALOG EMITS: patch `get_catalog_core`, never replace
-- `get_catalog`. Read `pg_get_functiondef`, insert your key, execute it back,
-- and raise if the anchor is missing so the transaction rolls back.
-- `backend/add_video_role.sql` is the worked example.
-- ============================================================================

-- add_video_urls.sql
--
-- Migration: add gallery-video support to the catalog.
--
-- Adds a `video_urls text[]` column to `public.tours` and rebuilds the
-- `get_catalog()` RPC so it emits the `videoURLs` key the app now reads.
-- Videos render as extra swipeable pages after the photos in the tour's
-- gallery carousel (owner decision, 2026-07-19). Files are hosted on
-- gh-pages under `videos/`, same as audio + images.
--
-- Idempotent + safe to re-run: `add column if not exists` + `create or
-- replace function`. Run once in the Supabase SQL Editor (project
-- "Dozent"). "Success. No rows returned." is the expected result; the
-- PostgREST schema cache reloads within a few seconds. Existing tours
-- get `video_urls = NULL` (the app treats null/empty exactly as before —
-- image-only gallery).
--
-- After this runs, the `seed-supabase` job (publish-catalog.yml) carries
-- `videoURLs` from Tours.json into the column on every content merge, so
-- adding a video is: upload the .mp4 to gh-pages → add `videoURLs` to the
-- tour in Tours.json → merge.

begin;

alter table public.tours
    add column if not exists video_urls text[];

create or replace function public.get_catalog()
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'makers', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id',             m.id,
          'displayName',    m.display_name,
          'avatarURL',      m.avatar_url,
          'avatarEmoji',    m.avatar_emoji,
          'avatarInitials', m.avatar_initials,
          'avatarColor',    m.avatar_color,
          'bio',            m.bio,
          'websiteURL',     m.website_url,
          'link2URL',       m.link_2_url,
          'link3URL',       m.link_3_url
        ) order by m.display_name
      )
      from public.makers m
    ), '[]'::jsonb),
    'tours', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id',                   t.id,
          'title',                t.title,
          'shortDescription',     t.short_description,
          'longDescription',      t.long_description,
          'makerId',              t.maker_id,
          'heroImageURL',         t.hero_image_url,
          'additionalImageURLs',  to_jsonb(t.additional_image_urls),
          'videoURLs',            to_jsonb(t.video_urls),
          'kind',                 t.kind::text,
          'introAudioURL',        t.intro_audio_url,
          'totalDurationSeconds', t.total_duration_seconds,
          'walkingDistanceMeters',t.walking_distance_meters,
          'centroidLatitude',     t.centroid_latitude,
          'centroidLongitude',    t.centroid_longitude,
          'city',                 t.city,
          'primaryCategory',      t.primary_category::text,
          'tags',                 to_jsonb(t.tags),
          'priceUSD',             t.price_usd,
          'stops', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'id',                   s.id,
                'order',                s."order",
                'title',                s.title,
                'caption',              s.caption,
                'latitude',             s.latitude,
                'longitude',            s.longitude,
                'audioURL',             s.audio_url,
                'audioDurationSeconds', s.audio_duration_seconds,
                'triggerMode',          s.trigger_mode::text,
                'triggerRadiusMeters',  s.trigger_radius_meters,
                'imageURL',             s.image_url,
                'transcriptText',       s.transcript_text
              ) order by s."order"
            )
            from public.stops s
            where s.tour_id = t.id
          ), '[]'::jsonb)
        ) order by t.title
      )
      from public.tours t
      where t.status = 'published'
    ), '[]'::jsonb)
  );
$$;

grant execute on function public.get_catalog() to anon, authenticated;

commit;

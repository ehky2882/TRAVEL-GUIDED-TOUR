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

-- add_country.sql
--
-- Migration: add `country` to the catalog.
--
-- Adds a `country text` column to `public.tours` and rebuilds the
-- `get_catalog()` RPC so it emits the `country` key the app now reads.
-- Settings → About shows a "Countries" count beside Tours, Dozents and
-- Cities (owner, 2026-08-19).
--
-- WHY A COLUMN RATHER THAN A LOOKUP IN THE APP: a city launch merges as
-- content and reaches phones over the air with no build, so a city→country
-- table compiled into the binary would start understating the day a new
-- city landed. Stored here, the country travels with the tour like `city`
-- does and the count keeps itself current.
--
-- Idempotent + safe to re-run: `add column if not exists` + `create or
-- replace function`. Run once in the Supabase SQL Editor (project
-- "Dozent"). "Success. No rows returned." is the expected result; the
-- PostgREST schema cache reloads within a few seconds.
--
-- Existing rows get `country = NULL` for the few seconds until the
-- `seed-supabase` job (publish-catalog.yml) next runs, which fills every
-- row from Tours.json and carries the value on every content merge after.
-- Until a country is served, the app HIDES the Countries row rather than
-- showing 0 — so there is no window in which a wrong number is on screen,
-- and nothing needs rebuilding once this runs.

begin;

alter table public.tours
    add column if not exists country text;

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
          'link3URL',       m.link_3_url,
          -- The maker's auth user id, or NULL for the Atlas-owned studios.
          -- Needed to look up that person's lists: `journeys.owner_user_id`
          -- is an auth.users id, and without this the client has no way to
          -- name whose lists it is asking for.
          'userId',         m.user_id
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
          'country',              t.country,
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

commit;

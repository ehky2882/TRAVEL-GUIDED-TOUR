-- add_video_role.sql
--
-- Migration: teach the catalog what a tour's video IS.
--
-- Adds a `video_role text` column to `public.tours` and rebuilds
-- `get_catalog()` so it emits the `videoRole` key the app now reads.
--
--   NULL / 'gallery'  the clip is extra — b-roll, a moving photograph beside
--                     the still ones. It plays on its own and, if it has
--                     sound, borrows the narration and hands it straight
--                     back. This is every video in the catalogue today, and
--                     what any tour without the key keeps doing.
--
--   'narration'       the clip IS the tour. Its soundtrack is the narration,
--                     so the play bar and the picture are one thing: play,
--                     pause or scrub either and both move together. The
--                     AUDIO is the clock and the video is muted — the tour
--                     player already owns the lock screen, background
--                     playback, the geofence hand-off, Group Listen,
--                     downloads, progress and speed, and a narration clip is
--                     a passenger on all of it.
--
-- Owner decision, 2026-08-24: "i agree we need to define different types of
-- videos." Do NOT infer this from the data — the tempting rule (single stop,
-- clip has sound, durations match) breaks b-roll the first time a clip
-- happens to be the length of its narration, and it fails silently.
--
-- Idempotent + safe to re-run: `add column if not exists` + `create or
-- replace function`. Run once in the Supabase SQL Editor (project "Dozent").
-- "Success. No rows returned." is expected; the PostgREST schema cache
-- reloads within a few seconds. Every existing tour gets NULL, which the app
-- reads as `gallery` — i.e. no behaviour changes until a tour says otherwise.
--
-- After this runs, the `seed-supabase` job (publish-catalog.yml) carries
-- `videoRole` from Tours.json into the column on every content merge.
--
-- The get_catalog body below is lifted VERBATIM from schema.sql so the two
-- cannot drift.

begin;

alter table public.tours
    add column if not exists video_role text;

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
          'videoRole',            to_jsonb(t.video_role),
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

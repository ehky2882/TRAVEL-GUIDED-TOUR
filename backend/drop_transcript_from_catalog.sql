-- =================================================================
-- STOP SENDING THE NARRATION SCRIPTS IN THE CATALOGUE
--
-- WHY (plain English): every time a phone asks for the tour list, the
-- database sends back the full written script of every stop's narration --
-- 1,924 of them, 3.8 million characters. Nothing in the app has ever shown
-- them. They are 37.5% of the bytes Supabase bills us for, on every single
-- fetch, forever.
--
-- Measured against the LIVE payload on 2026-09-10:
--     with transcripts   2.945 MB gzipped
--     without            1.840 MB gzipped
--     saving             1.105 MB  =  37.5%
--
-- This is the change that gets the project back inside the free egress
-- allowance (Supabase over-quota notice, 2026-09-10: 11.82 GB against 5 GB,
-- and 100.0% of it PostgREST -- i.e. this payload and nothing else).
--
-- 🔴 NOTHING IS DELETED. `stops.transcript_text` keeps every character. This
-- only stops it being SENT in the catalogue. The maker edit path reads and
-- writes it directly against the `stops` table (MakerTourService.swift), so
-- transcript editing is untouched.
--
-- WHY THIS IS SAFE FOR PHONES THAT ALREADY HAVE THE APP:
--   * `Stop.transcriptText` is `String?` in Swift, so an absent key decodes
--     as nil -- no crash, no failed decode, on any build ever shipped.
--   * No consumer screen reads it. Verified by grep across the whole app:
--     the only readers are Models/Stop.swift (the declaration),
--     MakerTourService (which queries the table directly, not this RPC),
--     TourWizardRules and CreateTourWizardView -- all maker-side.
--   So this is not a feature being withdrawn. It is a field nobody was
--   looking at, being taken off the wire.
--
-- ⚠️ `longDescription` was considered in the same pass and DELIBERATELY KEPT.
-- It is only 8.2% of the billed bytes once compressed (the "18%" in earlier
-- notes was a RAW-bytes figure, which is not what is billed), and unlike the
-- transcripts it IS used -- TourDetailView renders it and SearchView searches
-- it. Removing it would be a visible regression for 8%. Do not.
--
-- =================================================================
-- HOW TO RUN IT: paste this whole file into the Supabase SQL Editor and
-- press Run. It is idempotent -- running it twice is harmless.
--
-- ⚠️ THE LAST LINE IS LOAD-BEARING. `get_catalog()` serves a pre-built
-- snapshot row, so redefining the builder alone changes NOTHING that a phone
-- can see until the snapshot is rebuilt. That is what the final
-- `refresh_catalog_snapshot()` does. Without it this file appears to succeed
-- and does nothing.
--
-- VERIFY AFTERWARDS, rather than trusting "Success. No rows returned.":
--     python3 scripts/check-catalog-keys.py
--     python3 scripts/check-catalog-contract.py
-- =================================================================

-- This is `get_catalog_core()` exactly as it stands in
-- backend/restore_catalog_keys.sql, with ONE line removed: the
-- 'transcriptText' entry in the stops object. Everything else is byte-for-byte
-- the same, deliberately -- a rewrite here is how keys get lost (see the
-- 2026-08-19 incident, where `places`, `priceTier` and `isPrivate` vanished
-- for 14 hours because each one is optional in Swift and simply decoded as
-- nil).
create or replace function public.get_catalog_core()
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
          'userId',         m.user_id,
          'isPrivate',      m.is_private
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
          'priceTier',            t.price_tier,
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
                'imageURL',             s.image_url
                -- 'transcriptText' REMOVED HERE. 37.5% of the billed bytes,
                -- read by nothing. The column still holds every character;
                -- the maker edit path queries `stops` directly.
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

grant execute on function public.get_catalog_core() to anon, authenticated;

-- 🔴 Without this the change is invisible to every phone. get_catalog() reads
-- a stored snapshot; this is what rebuilds it from the new definition.
select public.refresh_catalog_snapshot();

-- Expect the row count to be unchanged and the payload to be much smaller:
--   select jsonb_array_length(get_catalog() -> 'tours');   -- unchanged
--   select jsonb_array_length(get_catalog() -> 'places');  -- unchanged
--   select (get_catalog() -> 'tours' -> 0 -> 'stops' -> 0 ? 'transcriptText')
--       as transcript_still_sent;                          -- expect: f

-- =================================================================
-- restore_catalog_keys.sql
--
-- WHAT BROKE. add_country.sql rebuilt get_catalog() from schema.sql's body.
-- schema.sql has never carried three things that later migrations added, so
-- rebuilding from it silently dropped them from the live payload:
--
--     places      (places_apply.sql)  -> place pages and merged capsule pins
--                                        disappear from the map
--     priceTier   (paid_tours.sql)    -> every paid walk decodes as FREE
--     isPrivate   (social.sql)        -> every private account reads as public
--
-- Nothing errored. All three are optional in Swift, so they decode as nil and
-- the features just stop existing. Verified live 2026-08-20: places absent,
-- priceTier absent on 1419/1419 tours, isPrivate absent on 39/39 makers.
-- The DATA is intact — all 25 places are still in the table. Only the function
-- stopped emitting them.
--
-- places_apply.sql predicted exactly this and says "re-run this file
-- afterwards". 🔴 DO NOT DO THAT ON ITS OWN. Its rename step is guarded on
-- get_catalog_core already existing, so re-running it would rebuild the
-- wrapper around the STALE core — restoring places while dropping `country`
-- straight back out again. This file refreshes the core first, then rewraps.
--
--
-- =================================================================
-- 🔴 SUPERSEDED 2026-08-25 — DO NOT RUN THIS FILE AS IT STANDS.
--
-- `backend/split_link_pins.sql` has since been applied to the live database.
-- It renamed the then-current `get_catalog_core` aside to
-- `get_catalog_core_base` and made `get_catalog_core` a THIN WRAPPER that
-- lifts `kind = 'link'` tours out of `tours` into a sibling `linkPins` array.
--
-- The statement below is `create or replace function public.get_catalog_core()`
-- with a full inline body. Running it now REPLACES that wrapper, severs the
-- call to `get_catalog_core_base`, and puts link pins straight back inside
-- `tours`.
--
-- WHY THAT IS SERIOUS, and it is not a cosmetic regression. `TourKind` is a
-- closed enum in every build shipped before the split, and `[Tour]` decodes as
-- ONE array — so a single `kind: "link"` element fails the WHOLE catalog
-- decode, and `RemoteCatalogLoader`'s `try?` reads that as a failed fetch and
-- keeps its last good copy. Nothing errors. Those phones simply stop receiving
-- all new content, silently and permanently. That outage is exactly what
-- split_link_pins.sql was written to end, and there are 57 link pins live now
-- rather than the 4 there were then.
--
-- This is the same class of failure this file's own header describes — a
-- migration rebuilding the catalog function from a body that predates a later
-- key — one layer further down. See CLAUDE.md § "create or replace
-- get_catalog() NOW DESTROYS THE PLACE LAYER".
--
-- IF THESE KEYS EVER NEED RESTORING AGAIN:
--   1. Patch `get_catalog_core_base` — that is where the tour keys now live.
--      Read it with pg_get_functiondef, insert the key, execute it back, and
--      raise if the anchor is missing so the transaction rolls back.
--      `backend/add_video_role.sql` is the worked example.
--   2. Do NOT replace `get_catalog_core` or `get_catalog` with an inline body.
--   3. If this file is ever run anyway, re-apply `split_link_pins.sql`
--      immediately afterwards to rebuild the wrapper.
--
-- VERIFY, ALWAYS, rather than trusting "Success. No rows returned.":
--     python3 scripts/check-catalog-keys.py
-- It fails when `linkPins` vanishes from the live payload, which is precisely
-- the damage this file would do.
-- =================================================================
--
-- Idempotent. Safe to run more than once. Paste the whole file.
-- =================================================================

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
          -- The maker's auth user id, or NULL for the Atlas-owned studios.
          -- Needed to look up that person's lists: `journeys.owner_user_id`
          -- is an auth.users id, and without this the client has no way to
          -- name whose lists it is asking for.
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

-- The public entry point: whatever the core returns, plus places.
-- `||` merges at the top level, so every core key is preserved untouched.
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
grant execute on function public.get_catalog_core() to anon, authenticated;

-- Verify after running. Expect, in order: 25, 1419, 39, 66, and a row of
-- three `t` values.
--   select jsonb_array_length(get_catalog() -> 'places');
--   select jsonb_array_length(get_catalog() -> 'tours');
--   select jsonb_array_length(get_catalog() -> 'makers');
--   select count(*) from jsonb_array_elements(get_catalog() -> 'tours') e
--     where (e ->> 'priceTier') is not null;
--   select (get_catalog() -> 'tours' -> 0 ? 'country')   as has_country,
--          (get_catalog() -> 'tours' -> 0 ? 'priceTier') as has_price_tier,
--          (get_catalog() -> 'makers' -> 0 ? 'isPrivate') as has_is_private;

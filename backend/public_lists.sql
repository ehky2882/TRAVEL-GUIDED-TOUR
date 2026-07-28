-- ---------------------------------------------------------------------------
-- Public lists on maker pages
-- ---------------------------------------------------------------------------
-- WHAT THIS DOES (plain English): lets the app show a creator's lists on their
-- page, and makes a new list visible by default instead of hidden.
--
-- HOW TO RUN IT: Supabase dashboard -> SQL Editor -> New query -> paste all of
-- this -> Run. It is safe to run more than once.
--
-- WHY IT IS NEEDED: lists are filed under the owner's *account* id, but the
-- creator profile the app downloads never included one — so the app had no way
-- to ask "give me this person's lists". Step 1 adds it.
--
-- Owner decisions, 2026-07-27:
--   * a new list should be VISIBLE unless marked otherwise
--   * every existing list becomes visible (step 3) — this one is not reversible
--     by re-running the script, so it is deliberately last and clearly marked
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 1. Send the maker's account id with the catalog.
--    Identical to the version in schema.sql apart from the 'userId' line, so
--    re-running schema.sql later will not undo this.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- 2. New lists are visible by default.
--    Was `default false`, which is backwards from "lists show unless marked
--    private". Affects only lists created from now on.
-- ---------------------------------------------------------------------------
alter table public.journeys alter column is_public set default true;

-- ---------------------------------------------------------------------------
-- 3. Make every EXISTING list visible.
--    ⚠️ One-way. Requested explicitly by the owner. Safe in practice: no list
--    has ever been readable by anyone, because the app had no public-read path
--    until now — so nothing is being revealed that someone had already seen.
--    Delete this statement if you would rather switch lists on one at a time.
-- ---------------------------------------------------------------------------
update public.journeys set is_public = true where is_public = false;

-- ---------------------------------------------------------------------------
-- Check it worked: this should list your lists with `is_public` all true.
--   select id, title, is_public from public.journeys order by updated_at desc;
-- And this should show a userId on your own maker (null on Atlas studios):
--   select jsonb_path_query_first(
--     public.get_catalog(), '$.makers[*] ? (@.userId != null)');
-- ---------------------------------------------------------------------------

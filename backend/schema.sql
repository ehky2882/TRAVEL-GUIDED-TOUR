-- Atlas backend — catalog schema (V2 Step 2: backend foundation)
--
-- Postgres / Supabase DDL for the read-side catalog: makers, tours, stops.
-- Columns map 1:1 to the Swift models (Tour / Stop / Maker / TourCategory).
-- The app reads the catalog via the get_catalog() RPC at the bottom, which
-- returns the exact { makers, tours:[{...stops}] } JSON shape that
-- ToursData already decodes — so the app change is just a URL swap.
--
-- Forward-designed columns (status, user_id, timestamps) are included now so
-- the maker platform (later V2 steps) won't require a schema rewrite. The
-- maker write-side tables (profiles, applications, library sync, purchases,
-- moderation, payouts) are intentionally NOT created here — see
-- docs/backend-design.md for their sketch.
--
-- Run once on a fresh Supabase project (SQL editor or `supabase db push`).
-- Idempotent-ish: uses `if not exists` / `create or replace` where possible.

begin;

-- ---------------------------------------------------------------------------
-- Enums (closed sets — adding a value later requires ALTER TYPE ... ADD VALUE)
-- ---------------------------------------------------------------------------
do $$ begin
  create type tour_kind as enum ('single', 'multiStop');
exception when duplicate_object then null; end $$;

do $$ begin
  create type stop_trigger_mode as enum ('geofenced', 'manual');
exception when duplicate_object then null; end $$;

do $$ begin
  create type tour_category as enum (
    'history', 'architecture', 'visualArt', 'musicAndPerformance',
    'literature', 'foodAndDrink', 'natureAndParks', 'hiddenGems',
    'culturalHeritage', 'sacredSites'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type tour_status as enum ('draft', 'in_review', 'published', 'taken_down');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- makers
-- ---------------------------------------------------------------------------
create table if not exists public.makers (
    id            uuid primary key,
    display_name  text not null,
    avatar_url    text,
    avatar_emoji  text,
    avatar_initials text,
    avatar_color  text,
    bio           text not null,
    website_url   text,
    link_2_url    text,
    link_3_url    text,
    -- forward-design (maker platform): the auth user who owns this maker.
    -- NULL for the current Atlas-owned studios.
    user_id       uuid references auth.users (id) on delete set null,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- tours (stops normalized into their own table for future maker editing)
-- ---------------------------------------------------------------------------
create table if not exists public.tours (
    id                      uuid primary key,
    title                   text not null,
    short_description       text not null,
    long_description        text not null,
    maker_id                uuid not null references public.makers (id) on delete restrict,
    hero_image_url          text not null,
    additional_image_urls   text[],
    video_urls              text[],
    kind                    tour_kind not null,
    intro_audio_url         text,
    total_duration_seconds  int not null,
    walking_distance_meters int,
    centroid_latitude       double precision not null,
    centroid_longitude      double precision not null,
    city                    text,
    primary_category        tour_category not null,
    tags                    text[] not null default '{}',
    price_usd               numeric(10,2) not null default 0,
    -- forward-design (maker platform / moderation):
    status                  tour_status not null default 'published',
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now(),
    published_at            timestamptz
);

-- ---------------------------------------------------------------------------
-- stops
-- ---------------------------------------------------------------------------
create table if not exists public.stops (
    id                     uuid primary key,
    tour_id                uuid not null references public.tours (id) on delete cascade,
    "order"                int not null,
    title                  text not null,
    caption                text,
    latitude               double precision not null,
    longitude              double precision not null,
    audio_url              text not null,
    audio_duration_seconds int not null,
    trigger_mode           stop_trigger_mode not null,
    trigger_radius_meters  int not null default 30,
    image_url              text,
    transcript_text        text,
    unique (tour_id, "order")
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
create index if not exists idx_tours_maker_id   on public.tours (maker_id);
create index if not exists idx_tours_category    on public.tours (primary_category);
create index if not exists idx_tours_status      on public.tours (status);
create index if not exists idx_stops_tour_id     on public.stops (tour_id);

-- ---------------------------------------------------------------------------
-- Row-Level Security: anonymous role gets read-only access to published
-- content. Writes are service-role only (the seed/admin) until the maker
-- platform adds per-user policies.
-- ---------------------------------------------------------------------------
alter table public.makers enable row level security;
alter table public.tours  enable row level security;
alter table public.stops  enable row level security;

drop policy if exists makers_public_read on public.makers;
create policy makers_public_read on public.makers
    for select using (true);

drop policy if exists tours_public_read on public.tours;
create policy tours_public_read on public.tours
    for select using (status = 'published');

drop policy if exists stops_public_read on public.stops;
create policy stops_public_read on public.stops
    for select using (
        exists (
            select 1 from public.tours t
            where t.id = stops.tour_id and t.status = 'published'
        )
    );

-- ---------------------------------------------------------------------------
-- get_catalog() — returns the catalog in the EXACT shape ToursData decodes:
--   { "makers": [...], "tours": [ { ...tour, "stops": [...] } ] }
-- camelCase keys match the Swift Codable property names. SECURITY INVOKER
-- (default) so RLS applies — anon sees published tours only.
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

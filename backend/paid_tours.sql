-- Atlas backend — paid tours (V2 Step 6, Phase 2)
--
-- Adds the money layer designed in docs/paid-tours-design.md:
--   • tours.price_tier          — NULL = free (whole catalog today); else the
--                                 USD price in cents, one of the 10 tiers
--                                 created in App Store Connect (Phase 1).
--   • purchases                 — one row per Apple sale. THE source of truth
--                                 for buyer entitlements AND maker earnings
--                                 (Apple's data cannot rebuild it — treat as
--                                 financial data). Written ONLY by the
--                                 record-purchase Edge Function (service role);
--                                 clients can only read their own rows.
--   • payouts                   — one row per monthly Stripe transfer to a
--                                 maker; purchases point at the payout that
--                                 covered them.
--   • maker_payout_accounts     — the maker's Stripe Connect account id.
--                                 DELIBERATE deviation from the design doc's
--                                 "makers.stripe_account_id": makers has a
--                                 public-read RLS policy, so a column there
--                                 would be visible to every client. This
--                                 table is owner + admin only.
--   • maker_earnings            — per-maker earnings view (the Phase 4
--                                 Earnings screen reads this).
--   • get_catalog()             — rebuilt to emit 'priceTier' per tour.
--
-- Money constants (design doc §money flow): Apple keeps 15% (Small Business
-- Program) → Atlas platform fee 20% of the remainder → maker share is
-- 0.85 * 0.80 = 68% of the sticker price. If either rate ever changes,
-- update maker_net_cents() below — historical payout rows are unaffected
-- (payouts store computed amounts).
--
-- Run AFTER schema.sql + accounts.sql (needs tours, makers, is_admin(),
-- owns_maker()). Idempotent — safe to re-run.

begin;

-- ---------------------------------------------------------------------------
-- tours.price_tier — NULL = free. Cents, restricted to the 10 ASC tiers.
-- The App Store product id is derived: 'tour.tier.' || lpad(price_tier, 3)
-- (099, 199, …, 1499, 1999). Widening the menu later = create the ASC
-- product, then extend this CHECK.
-- ---------------------------------------------------------------------------
alter table public.tours add column if not exists price_tier int;

alter table public.tours drop constraint if exists tours_price_tier_allowed;
alter table public.tours add constraint tours_price_tier_allowed
    check (price_tier is null or price_tier in
           (99, 199, 299, 399, 499, 699, 899, 999, 1499, 1999));

-- ---------------------------------------------------------------------------
-- purchases — one row per Apple transaction. Insert path: record-purchase
-- Edge Function (service role, bypasses RLS). apple_transaction_id is UNIQUE
-- so StoreKit-history replays after a failed recording call are idempotent.
-- ---------------------------------------------------------------------------
create table if not exists public.purchases (
    id                            uuid primary key default gen_random_uuid(),
    -- entitlement key. Row survives account deletion (set null) so the
    -- maker's earnings history is never destroyed.
    user_id                       uuid references auth.users (id) on delete set null,
    -- restrict: a sold tour can be taken down but never hard-deleted.
    tour_id                       uuid not null references public.tours (id) on delete restrict,
    maker_id                      uuid not null references public.makers (id) on delete restrict,
    -- the tier ACTUALLY bought (from the Apple product id), in cents — kept
    -- even if the tour's price_tier changes later.
    price_tier                    int not null,
    apple_transaction_id          text not null unique,
    apple_original_transaction_id text,
    -- 'Production' or 'Sandbox'. Sandbox rows are excluded from earnings.
    apple_environment             text not null default 'Production',
    purchased_at                  timestamptz not null,
    refunded_at                   timestamptz,
    -- set by the monthly payout run (Phase 5); NULL = not yet paid out.
    payout_id                     uuid,
    created_at                    timestamptz not null default now()
);

create index if not exists idx_purchases_user_id  on public.purchases (user_id);
create index if not exists idx_purchases_maker_id on public.purchases (maker_id);
create index if not exists idx_purchases_tour_id  on public.purchases (tour_id);

-- ---------------------------------------------------------------------------
-- payouts — one row per Stripe transfer (Phase 5 writes these).
-- ---------------------------------------------------------------------------
create table if not exists public.payouts (
    id                 uuid primary key default gen_random_uuid(),
    maker_id           uuid not null references public.makers (id) on delete restrict,
    amount_cents       int not null,
    currency           text not null default 'usd',
    stripe_transfer_id text,
    period_start       date,
    period_end         date,
    notes              text,
    created_at         timestamptz not null default now()
);

create index if not exists idx_payouts_maker_id on public.payouts (maker_id);

-- purchases.payout_id → payouts (added after payouts exists).
do $$ begin
  alter table public.purchases
      add constraint purchases_payout_fk
      foreign key (payout_id) references public.payouts (id) on delete set null;
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- maker_payout_accounts — Stripe Connect account per maker (owner-private).
-- ---------------------------------------------------------------------------
create table if not exists public.maker_payout_accounts (
    maker_id          uuid primary key references public.makers (id) on delete cascade,
    stripe_account_id text not null,
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- maker share of one sale, in cents. 0.85 (post-Apple) * 0.80 (post-Atlas).
-- ---------------------------------------------------------------------------
create or replace function public.maker_net_cents(tier int)
returns int language sql immutable as $$
    select round(tier * 0.85 * 0.80)::int;
$$;

-- ---------------------------------------------------------------------------
-- maker_earnings — what the Phase 4 Earnings screen shows. security_invoker
-- so the caller's RLS on purchases applies (a maker only aggregates rows
-- they're allowed to see; admin sees all).
-- Production, non-refunded sales only.
-- ---------------------------------------------------------------------------
create or replace view public.maker_earnings
with (security_invoker = true) as
select
    p.maker_id,
    count(*)                                                    as units_sold,
    sum(p.price_tier)                                           as gross_cents,
    sum(public.maker_net_cents(p.price_tier))                   as earned_cents,
    sum(public.maker_net_cents(p.price_tier))
        filter (where p.payout_id is null)                      as accrued_unpaid_cents,
    sum(public.maker_net_cents(p.price_tier))
        filter (where p.payout_id is not null)                  as paid_out_cents
from public.purchases p
where p.refunded_at is null
  and p.apple_environment = 'Production'
group by p.maker_id;

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
alter table public.purchases             enable row level security;
alter table public.payouts               enable row level security;
alter table public.maker_payout_accounts enable row level security;

-- purchases: buyers read their own; makers read sales of their tours
-- (earnings); admin reads all. NO client writes — inserts come from the
-- record-purchase Edge Function via the service role, refund updates from the
-- appstore-notifications function, payout stamps from the Phase 5 run.
drop policy if exists purchases_own_read on public.purchases;
create policy purchases_own_read on public.purchases
    for select using (
        user_id = auth.uid()
        or public.owns_maker(maker_id)
        or public.is_admin()
    );

-- payouts: the paid maker + admin.
drop policy if exists payouts_read on public.payouts;
create policy payouts_read on public.payouts
    for select using (public.owns_maker(maker_id) or public.is_admin());

drop policy if exists payouts_admin_write on public.payouts;
create policy payouts_admin_write on public.payouts
    for all using (public.is_admin()) with check (public.is_admin());

-- maker_payout_accounts: the owning maker + admin, read and write (the
-- "Set up payouts" flow stores the Stripe account id from the app).
drop policy if exists payout_accounts_owner on public.maker_payout_accounts;
create policy payout_accounts_owner on public.maker_payout_accounts
    for all using (public.owns_maker(maker_id) or public.is_admin())
    with check (public.owns_maker(maker_id) or public.is_admin());

grant select on public.purchases, public.payouts, public.maker_earnings
    to authenticated;
grant select, insert, update, delete on public.maker_payout_accounts
    to authenticated;

-- ---------------------------------------------------------------------------
-- get_catalog() — full rebuild, unchanged except the new 'priceTier' key
-- (NULL / absent-equivalent for free tours; older app builds ignore it).
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

grant execute on function public.get_catalog() to anon, authenticated;

commit;

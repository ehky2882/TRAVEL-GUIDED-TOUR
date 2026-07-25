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
-- The App Store product id is 'tour.tier.' + the cents value, zero-padded to
-- at least 3 digits: 99 → tour.tier.099, 199 → tour.tier.199, …,
-- 1499 → tour.tier.1499. Widening the menu later = create the ASC product,
-- then extend this CHECK **and** the same list on purchases below.
-- ---------------------------------------------------------------------------
alter table public.tours add column if not exists price_tier int;

-- Safety net: get_catalog() below reads video_urls, and a `language sql`
-- body is parsed at CREATE time — so on a project where add_video_urls.sql
-- was never applied, the whole transaction would abort with "column
-- t.video_urls does not exist". No-op where it already exists.
alter table public.tours add column if not exists video_urls text[];

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
    -- even if the tour's price_tier changes later. CHECK-constrained to the
    -- same closed set below.
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

-- Same closed tier set as tours.price_tier — a typo'd ASC product id must
-- never become an unbounded number in the earnings math. Widening the menu
-- means updating BOTH lists.
alter table public.purchases drop constraint if exists purchases_price_tier_allowed;
alter table public.purchases add constraint purchases_price_tier_allowed
    check (price_tier in (99, 199, 299, 399, 499, 699, 899, 999, 1499, 1999));

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
-- maker_sales — a maker's own sales WITHOUT the buyer's identity.
--
-- Makers need per-sale rows to build an Earnings screen, but they must not be
-- able to enumerate which accounts bought what (purchases.user_id). So this
-- view omits user_id and is a **definer** view (no security_invoker) that
-- self-scopes with owns_maker()/is_admin() — the underlying RLS on purchases
-- can therefore stay buyer-only. Never add user_id here.
-- ---------------------------------------------------------------------------
-- security_barrier so the planner can't push a cheap user-supplied qual
-- ahead of the owns_maker() check and probe rows through timing/errors.
create or replace view public.maker_sales
with (security_barrier = true) as
select
    p.id,
    p.tour_id,
    p.maker_id,
    p.price_tier,
    p.apple_environment,
    p.purchased_at,
    p.refunded_at,
    p.payout_id
from public.purchases p
where public.owns_maker(p.maker_id) or public.is_admin();

-- ---------------------------------------------------------------------------
-- maker_earnings — what the Phase 4 Earnings screen shows. Built on
-- maker_sales (already scoped to the caller) + payouts.
--
-- paid_out_cents comes from what Stripe ACTUALLY transferred
-- (payouts.amount_cents), not from re-running maker_net_cents() over old
-- sales — otherwise changing the platform fee would silently re-value every
-- historical payout and disagree with the bank.
--
-- Sales counters are Production, non-refunded only. refunded_after_payout_cents
-- surfaces money already paid out on a sale later refunded, so a clawback is
-- visible instead of just vanishing from the totals. NOTE it IS recomputed
-- from the current rate (unlike paid_out_cents) — it's an at-a-glance
-- exposure figure, not a settled amount; the authoritative clawback number
-- has to come from the payout run that actually paid the sale. A real
-- clawback/adjustment row type is a Phase 5 decision.
--
-- A maker with no sales and no payouts yields NO row (not a zeroed one) —
-- the Phase 4 Earnings screen must handle "no row" as zero.
-- ---------------------------------------------------------------------------
create or replace view public.maker_earnings
with (security_barrier = true) as
with sales as (
    select
        s.maker_id,
        count(*) filter (where s.refunded_at is null)              as units_sold,
        coalesce(sum(s.price_tier)
            filter (where s.refunded_at is null), 0)               as gross_cents,
        coalesce(sum(public.maker_net_cents(s.price_tier))
            filter (where s.refunded_at is null), 0)               as earned_cents,
        coalesce(sum(public.maker_net_cents(s.price_tier))
            filter (where s.refunded_at is null
                      and s.payout_id is null), 0)                 as accrued_unpaid_cents,
        coalesce(sum(public.maker_net_cents(s.price_tier))
            filter (where s.refunded_at is not null
                      and s.payout_id is not null), 0)             as refunded_after_payout_cents
    from public.maker_sales s
    where s.apple_environment = 'Production'
    group by s.maker_id
),
paid as (
    select po.maker_id, coalesce(sum(po.amount_cents), 0) as paid_out_cents
    from public.payouts po
    where public.owns_maker(po.maker_id) or public.is_admin()
    group by po.maker_id
)
select
    maker_id,
    coalesce(sales.units_sold, 0)                   as units_sold,
    coalesce(sales.gross_cents, 0)                  as gross_cents,
    coalesce(sales.earned_cents, 0)                 as earned_cents,
    coalesce(sales.accrued_unpaid_cents, 0)         as accrued_unpaid_cents,
    coalesce(paid.paid_out_cents, 0)                as paid_out_cents,
    coalesce(sales.refunded_after_payout_cents, 0)  as refunded_after_payout_cents
from sales full outer join paid using (maker_id);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
alter table public.purchases             enable row level security;
alter table public.payouts               enable row level security;
alter table public.maker_payout_accounts enable row level security;

-- purchases: the BUYER reads their own rows (that's the entitlement check);
-- admin reads all. Makers deliberately do NOT get a policy here — they see
-- their sales through maker_sales / maker_earnings, which omit the buyer's
-- user_id, so a maker can't enumerate who bought what.
-- NO client writes at all — inserts come from the record-purchase Edge
-- Function via the service role, refund updates from appstore-notifications,
-- payout stamps from the Phase 5 run.
drop policy if exists purchases_own_read on public.purchases;
create policy purchases_own_read on public.purchases
    for select using (user_id = auth.uid() or public.is_admin());

-- payouts: the paid maker + admin.
drop policy if exists payouts_read on public.payouts;
create policy payouts_read on public.payouts
    for select using (public.owns_maker(maker_id) or public.is_admin());

-- Admin write. The Phase 5 payout run uses the service role (which bypasses
-- RLS entirely), so this exists for an in-app/admin path; the matching grant
-- is below — a policy without one is inert (PostgREST fails on the grant
-- before RLS is consulted).
drop policy if exists payouts_admin_write on public.payouts;
create policy payouts_admin_write on public.payouts
    for all using (public.is_admin()) with check (public.is_admin());

-- maker_payout_accounts: READ-ONLY to clients (owning maker + admin).
--
-- Deliberately not client-writable: stripe_account_id is where the money
-- goes, so it must never be settable by a request. Anyone signed in gets a
-- maker row (accounts.sql auto-creates one on signup), so a writable policy
-- here would let a hostile session point payouts at an arbitrary Stripe
-- account. The real write path is Stripe Express onboarding's callback,
-- recorded server-side via the service role (Phase 5).
drop policy if exists payout_accounts_owner on public.maker_payout_accounts;
create policy payout_accounts_owner on public.maker_payout_accounts
    for select using (public.owns_maker(maker_id) or public.is_admin());

grant select on public.purchases, public.payouts,
                public.maker_sales, public.maker_earnings,
                public.maker_payout_accounts
    to authenticated;
-- Gated to admins by payouts_admin_write above.
grant insert, update, delete on public.payouts to authenticated;

-- Grants are cumulative and an earlier revision of this file granted writes
-- on maker_payout_accounts. Deleting the grant statement does NOT take it
-- back, so revoke explicitly — otherwise an upgraded database keeps the
-- write privilege, currently blocked only by the absence of a write policy.
revoke insert, update, delete on public.maker_payout_accounts from authenticated;
-- Same reasoning for purchases: no client has ever been meant to write here.
revoke insert, update, delete on public.purchases from authenticated, anon;

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

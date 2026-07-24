# Paid Tours & Revenue Split — Design (V2 Step 6)

**Status:** Decided with owner 2026-07-24 (chat session). Not yet built. This doc records the decisions and the phased plan.

## What we're building, in one paragraph

Dozents (makers) can mark a tour as **paid** at one of three price tiers. Tourists buy it in-app through **Apple In-App Purchase**. Every sale is recorded in **Supabase** (which tour, which maker, which buyer — Apple never knows tours exist), which both unlocks the tour for the buyer and accrues earnings for the maker. Once a month, **Stripe Connect** deposits each maker's share into their bank account. Atlas keeps a platform fee.

## The money flow (example: one $2.99 sale)

| Step | Amount |
|---|---|
| Tourist pays Apple | $2.99 |
| Apple keeps 15% (Small Business Program) | −$0.45 |
| Atlas receives | $2.54 |
| Atlas platform fee 20% | −$0.51 |
| **Maker earns** | **~$2.03** (minus small Stripe payout fee) |

Apple pays Atlas ~30–45 days after month end, so maker payouts run on the same delay (e.g. July sales paid out in September). The Earnings screen must state this plainly.

## Decisions of record

1. **Sales model: à la carte** — each tour bought individually. No subscription/bundles in v1.
2. **Pricing: maker picks from 3 curated tiers** — $1.99 / $2.99 / $4.99. (Apple offers ~900 price points; we can widen the menu later without schema change.)
3. **Platform fee: 20%** of the post-Apple amount. Adjustable for future makers.
4. **Payment rails: Apple IAP only in v1** (StoreKit 2). Rationale: works worldwide (external-link route is US/EU-storefront only and legally unstable post-Dec-2025 appeal), best impulse-buy conversion, single flow. A web-portal channel (Stripe checkout on a website, same Supabase entitlements) is a possible later hybrid for trip-planning purchases — deliberately deferred.
5. **IAP product mapping: 3 reusable tier products**, NOT one product per tour. Apple products are created once, by hand, in App Store Connect (`tour.tier.199` / `tour.tier.299` / `tour.tier.499`). Apple cannot create products at runtime; a maker flipping "Paid" only points their tour at an existing tier. **Consequence: the Supabase `purchases` table is the source of truth for entitlements AND payouts** — Apple's data cannot rebuild it. Treat it as financial data (verified writes, backups, monthly reconciliation vs Apple's per-tier unit counts).
6. **Payouts: Stripe Connect Express**, monthly. Stripe hosts maker onboarding (bank + tax details — Atlas never touches them) and issues tax forms. Payout = Stripe Transfer of each maker's accrued balance.
7. **Free tours stay free.** Paid is opt-in per tour. Existing catalog unaffected.

## How attribution works (the 3-product design's key mechanism)

At purchase time the app knows which tour is on screen. After Apple's payment sheet succeeds, the app sends the signed StoreKit transaction **plus the tour id** to a Supabase Edge Function, which:

1. Verifies the JWS signature is genuinely Apple's (anti-spoofing).
2. Inserts a `purchases` row: `user_id, tour_id, maker_id (derived from tour), tier, apple_transaction_id (unique — idempotent retries), purchased_at`.

That one row = the buyer's entitlement + the maker's ledger entry. Refunds arrive via App Store Server Notifications → mark the row refunded → next payout reduced. If the recording call fails (dead spot), the app replays StoreKit transaction history on next launch; the unique transaction id makes re-sends safe.

Entitlements are keyed to the Supabase account, so a new phone restores purchases by signing in.

## Phased build plan

**Phase 0 — Paperwork (owner, ~1–2 wks elapsed; hand-held click-by-click).**
Apple Paid Apps agreement + banking/tax in App Store Connect · Small Business Program enrollment (15% not 30%) · Stripe account + enable Connect · (recommended) business entity/LLC. Gates everything; start first.

**Phase 1 — Apple products (owner + Claude, ~30 min).**
Create the 3 tier products in App Store Connect.

**Phase 2 — Backend (Claude, 1 session).**
`purchases` table + RLS · `tours.price_tier` (nullable = free) · earnings/payouts ledger · `makers.stripe_account_id` · Edge Function: verify Apple transaction + insert purchase · App Store Server Notifications endpoint (refunds) · `get_catalog` emits price tier. All owner SQL is copy-paste blocks per house style.

**Phase 3 — Buyer side in app (Claude, 1–2 sessions).**
Price badge on paid tours · Buy button → StoreKit 2 `purchase()` → record to backend · locked/unlocked playback gating · entitlement check on launch/sign-in · transaction-history replay. Ships via ci.yml → testflight.yml; owner tests with Apple sandbox (fake money).

**Phase 4 — Maker side in app (Claude, 1–2 sessions).**
Tour editor: **Paid** toggle + tier picker (submit/moderation flow unchanged) · Profile: "Set up payouts" → Stripe Express onboarding link · **Earnings** screen (sales, accrued balance, payout history, the payment-delay note).

**Phase 5 — Payouts (Claude + owner, small).**
Monthly job: aggregate un-paid-out purchase rows per maker → Stripe Transfers → write payout rows. v1 = owner presses one button monthly; automate later. Monthly reconciliation: purchases-per-tier vs Apple's reported units.

**Phase 6 — Dress rehearsal.**
One real paid tour → sandbox purchase on owner's device → verify unlock + earnings row + a test payout → go live.

## Explicitly deferred

Web checkout channel (hybrid) · wider price menu · bundles/city passes/subscriptions · promo codes · maker-configurable platform fees · automated payout scheduling.

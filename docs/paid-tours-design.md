# Paid Tours & Revenue Split — Design (V2 Step 6)

**Status:** Decided with owner 2026-07-24 (chat session). Not yet built. This doc records the decisions and the phased plan.

## What we're building, in one paragraph

Dozents (makers) can mark a tour as **paid** at one of ten price tiers. Tourists buy it in-app through **Apple In-App Purchase**. Every sale is recorded in **Supabase** (which tour, which maker, which buyer — Apple never knows tours exist), which both unlocks the tour for the buyer and accrues earnings for the maker. Once a month, **Stripe Connect** deposits each maker's share into their bank account. Atlas keeps a platform fee.

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
2. **Pricing: maker picks from 10 curated tiers** — $0.99 / $1.99 / $2.99 / $3.99 / $4.99 / $6.99 / $8.99 / $9.99 / $14.99 / $19.99 (owner widened from the original 3, 2026-07-24, low-end-dense spread). Apple offers ~900 price points; the menu can widen further without schema change.
3. **Platform fee: 20%** of the post-Apple amount. Adjustable for future makers.
4. **Payment rails: Apple IAP only in v1** (StoreKit 2). Rationale: works worldwide (external-link route is US/EU-storefront only and legally unstable post-Dec-2025 appeal), best impulse-buy conversion, single flow. A web-portal channel (Stripe checkout on a website, same Supabase entitlements) is a possible later hybrid for trip-planning purchases — deliberately deferred.
5. **IAP product mapping: 10 reusable tier products**, NOT one product per tour. Apple products are created once, by hand, in App Store Connect (`tour.tier.099`, `tour.tier.199`, `tour.tier.299`, `tour.tier.399`, `tour.tier.499`, `tour.tier.699`, `tour.tier.899`, `tour.tier.999`, `tour.tier.1499`, `tour.tier.1999` — the ID suffix is the USD price × 100). Apple cannot create products at runtime; a maker flipping "Paid" only points their tour at an existing tier. **Consequence: the Supabase `purchases` table is the source of truth for entitlements AND payouts** — Apple's data cannot rebuild it. Treat it as financial data (verified writes, backups, monthly reconciliation vs Apple's per-tier unit counts).
6. **Payouts: Stripe Connect Express**, monthly. Stripe hosts maker onboarding (bank + tax details — Atlas never touches them) and issues tax forms. Payout = Stripe Transfer of each maker's accrued balance.
7. **Free tours stay free.** Paid is opt-in per tour. Existing catalog unaffected.

## How attribution works (the reusable-tier design's key mechanism)

At purchase time the app knows which tour is on screen. After Apple's payment sheet succeeds, the app sends the signed StoreKit transaction **plus the tour id** to a Supabase Edge Function, which:

1. Verifies the JWS signature is genuinely Apple's (anti-spoofing).
2. Inserts a `purchases` row: `user_id, tour_id, maker_id (derived from tour), tier, apple_transaction_id (unique — idempotent retries), purchased_at`.

That one row = the buyer's entitlement + the maker's ledger entry. Refunds arrive via App Store Server Notifications → mark the row refunded → next payout reduced. If the recording call fails (dead spot), the app replays StoreKit transaction history on next launch; the unique transaction id makes re-sends safe.

Entitlements are keyed to the Supabase account, so a new phone restores purchases by signing in.

## Phased build plan

**Phase 0 — Paperwork (owner, ~1–2 wks elapsed; hand-held click-by-click). ✅ DONE 2026-07-24.**
Apple Paid Apps agreement + banking/tax in App Store Connect (all Active as of Jul 24, 2026) · Small Business Program enrolled (15% not 30%) · Stripe account created, platform-oriented ("build a platform"), in **sandbox** mode. Two items deliberately deferred, neither blocks building: **Stripe live activation** (waits on the entity decision — verifying as individual then re-verifying as LLC would be duplicate work) and the **LLC decision** (owner to consult an accountant; sole proprietor is workable to start).

**Phase 1 — Apple products (owner + Claude, ~30 min). ✅ DONE 2026-07-24.**
All **10** tier products created in App Store Connect (Claude drove the owner's Chrome; owner picked the 10-tier low-end-dense menu during the session). Each is **Non-Consumable**, reference name `Tour Tier <price>`, product ID `tour.tier.<price×100>`, base price set (US base, Apple auto-priced all 175 regions), and one **English (U.S.)** localization — display name **"Premium Audio Tour"**, description **"Unlocks this audio tour"** (identical across tiers by design; the payment sheet also shows the price). All 10 sit in **"Prepare for Submission"** — that's the correct resting state: sandbox purchases (Phase 3/6) work from here. Left deliberately undone until go-live: the per-product **review screenshot** and **"Add for Review"** (the first non-consumable IAP must be submitted together with an app version).

**Phase 2 — Backend (Claude, 1 session). ✅ WRITTEN 2026-07-25 — owner still to apply.**
Shipped as `backend/paid_tours.sql` + two Edge Functions (`backend/functions/record-purchase`, `backend/functions/appstore-notifications`); runbook in `backend/README.md` § "Paid tours". Contents: `tours.price_tier` (NULL = free, CHECK-constrained to the 10 ASC tiers) · `purchases` table + RLS (buyer reads own, maker reads their sales, admin reads all; **no client writes** — the Edge Function inserts via the service role) · `payouts` ledger · `maker_earnings` view · `get_catalog()` rebuilt to emit `priceTier`.

Two deliberate deviations from the sketch above:
- **`maker_payout_accounts` table, not `makers.stripe_account_id`.** `makers` carries a public-read RLS policy, so a column there would expose every maker's Stripe account id to any client. The separate table is owner + admin only.
- **Neither function trusts the caller's payload.** Each extracts only a transaction id, then fetches the authoritative record from Apple's App Store Server API under our signed ES256 key and records *that* — so a forged POST can neither mint an entitlement nor fake a refund. Requires an App Store Connect **In-App Purchase API key** (`.p8`, downloads once) in four shared Edge secrets.

`price_tier` is deliberately absent from `seed_from_toursjson.py` (price lives in the DB, maker-set; a content re-seed must not reset it).

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

# HANDOFF — 2026-07-24 (session 69: paid tours Phase 1 — 10 IAP tier products)

## What happened

**V2 Step 6 (paid tours) moved from design to execution.** Two things shipped, no app code touched:

1. **Design doc merged to `main`** — `docs/paid-tours-design.md` via [PR #422](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/422) (squash `c154807`, doc-only auto-merge class). It records every money decision (à la carte, Apple IAP only, 20% platform fee, Stripe Connect Express monthly payouts, Supabase `purchases` table as the source of truth) and the Phase 0–6 plan. Read it before any monetization work.
2. **Phase 1 complete — all tier IAP products created in App Store Connect.** ASC → app "Atlas Audio Tours" (6771030927) → Distribution → In-App Purchases now shows **"Drafts (10)"**.

## The owner decision of this session: 10 tiers, not 3

Mid-session the owner asked for more than the doc's 3 tiers ("theoretically i can have as many tiers as i like?" — yes: each tier is one reusable non-consumable product; Apple allows up to 10,000 IAPs/app). Owner picked **10 tiers, $0.99–$19.99, low-end-dense**:

| Price | Product ID | ASC Apple ID |
|---|---|---|
| $0.99 | `tour.tier.099` | 6794384981 |
| $1.99 | `tour.tier.199` | 6794385777 |
| $2.99 | `tour.tier.299` | 6794386327 |
| $3.99 | `tour.tier.399` | 6794386951 |
| $4.99 | `tour.tier.499` | 6794387684 |
| $6.99 | `tour.tier.699` | 6794388191 |
| $8.99 | `tour.tier.899` | 6794388544 |
| $9.99 | `tour.tier.999` | 6794389811 |
| $14.99 | `tour.tier.1499` | 6794390459 |
| $19.99 | `tour.tier.1999` | 6794390716 |

Every product: **Non-Consumable** · reference name `Tour Tier <price>` · US (USD) base price, Apple auto-priced all 175 regions (defaults accepted) · one **en-US** localization — display name **"Premium Audio Tour"**, description **"Unlocks this audio tour"** (identical across tiers by design; the payment sheet shows the price, and the products are reused across every paid tour so they can't name a specific tour).

## Deliberately NOT done (correct, don't "fix")

- **No review screenshots, no "Add for Review".** All 10 products rest in **"Prepare for Submission"** — sandbox purchasing (Phases 3/6) works from this state. ASC's banner: the **first non-consumable IAP must be submitted with a new app version** — that pairing happens at go-live (Phase 6).
- **Stripe stays in sandbox** until the owner's LLC/entity decision (Phase 0 note; non-blocking).

## Process notes

- **Claude drove the owner's real Chrome (Claude-in-Chrome) through ASC** — first use of this path for owner-dashboard work. Works well. Gotchas: `form_input` sets ASC's `<select>`s fine but **silently fails on ASC textboxes** (React) — click the field then `type` instead; the price dropdown is a searchable custom button (click → type "14.99" → click the match); dialogs re-render so re-`find` refs after each step.
- Design-doc PR had no CI checks (path-filtered) — merged clean.

## NEXT — Phase 2 (backend, 1 session)

Per `docs/paid-tours-design.md`: `purchases` table + RLS · `tours.price_tier` (nullable = free) · earnings/payouts ledger · `makers.stripe_account_id` · Edge Function verifying the Apple JWS + inserting purchase rows (idempotent on `apple_transaction_id`) · App Store Server Notifications endpoint (refunds) · `get_catalog` emits the price tier. All owner SQL as copy-paste blocks per house style. Then Phase 3 (buyer UI, StoreKit 2) → 4 (maker UI) → 5 (payouts) → 6 (dress rehearsal).

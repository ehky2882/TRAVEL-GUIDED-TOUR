# Stripe account review — questions and submitted answers

Record of Stripe's Restricted Businesses review of the Dozent account, so that any
follow-up answers stay consistent with what has already been filed. **Read this before
answering anything further from Stripe.**

## The load-bearing facts (verified, reusable in any answer)

| | |
|---|---|
| Merchant of record | **Apple**, for 100% of consumer transactions (StoreKit 2 IAP only) |
| What Stripe does | **Connect Express payouts to creators** — a payout rail, nothing else |
| Consumer card payments processed by Stripe | **Zero.** Stripe never touches a cardholder |
| Chargeback exposure to Stripe | **None** — refunds are handled by Apple |
| Payouts through Stripe to date | **None, ever.** The rail has never carried a transaction |
| Consumer purchases to date | **One real sale** — $0.99, 2026-09-01, one hour after release. Three earlier rows are sandbox tests (see Purchase evidence) |
| Regulated party | **Stripe**, by design — Connect Express exists so the platform is not the money transmitter |
| Catalogue | 1,553 tours across 31 Atlas studios, plus **1,717 link pins** — map pins to public TikTok/YouTube/Instagram posts, credited to ~343 third-party accounts |
| Third-party creators | **None paid, none onboarded to Connect.** Link pins are attributions to public posts, not paid placements. **The only creator of any paid tour is the account holder** (owner, 2026-09-11) |
| Pricing | Free, or one-time unlock at 10 fixed tiers $0.99–$19.99. No subscriptions, no trials |
| Physical goods | None. Digital audio, delivered in-app |
| Pre-publication review | Every tour is human-reviewed; publish is admin-only and enforced in the database (`publish_tour()` behind `is_admin()`), not just in the UI |
| Acceptable Use Policy | https://dozent.world/acceptable-use/ — its prohibited list maps closely onto Stripe's Restricted Businesses list |

## Round 1 — 2026-08-18 (submitted; returned "In review. No further action is required.")

Stripe flagged the account against the **Restricted Businesses** list. The task text was
ambiguous between two entries — *"Content creation platforms"* and *"Travel reservation
services and clubs"* — and the app's App Store category is literally Travel, so the
response named both readings and answered each.

Key points made: Apple is merchant of record; Stripe is payout-only; no bookings, dates,
seats or supplier inventory and nothing delivered at a future date (killing the travel
reading); money transmission answered pre-emptively (Connect Express means Stripe, not
Dozent, is the regulated party); no transactions processed and no payouts made.

**The full submitted text was not saved.** Summary only, in `CLAUDE.md` § Current State
(2026-08-18). Do not contradict the points above.

## Round 2 — 2026-08-19 (the "Information needed for your Stripe account" form)

Four fields. Answers as submitted:

### Q1. "Please explain which products or services you plan to sell through Stripe."

> Nothing is sold through Stripe. We do not use Stripe to accept payment from customers,
> and no cardholder transacts with us through Stripe.
>
> Dozent is an iOS app selling self-guided audio walking tours — narrated recordings tied
> to GPS locations, played in the app. All consumer purchases are made through Apple
> In-App Purchase, where Apple is the merchant of record. Apple takes the payment, handles
> all refunds and chargebacks, and remits our share to us.
>
> We use Stripe for one purpose: Stripe Connect Express, to pay content creators their
> share of revenue we have already received from Apple. Stripe is a payout rail, not a
> payment-acceptance channel. Money moves one way — out to creators — and never from a
> consumer through Stripe to us.
>
> We have processed no transactions and made no payouts to date. The app has not been
> publicly released; version 1.1 is awaiting App Store review. All 1,418 tours currently
> in the catalogue are produced in-house by our own studios; no third-party creator has
> yet published or been paid.

### Q2. "Please confirm your target audience." → **I'm planning to sell to individual end customers**

Reasoning, recorded because it is a genuine judgement call: the end users are individual
consumers, so this is the honest option. "Other" is arguably more literally correct
(nothing is sold *through Stripe* to anyone) but reads as evasive on a form where a plain
option fits, and risks reopening a review that had already returned "no further action
required." The tension is reconciled explicitly in the Details box.

### Q3. "Details" (optional — filled deliberately; this is where the Restricted Businesses concern is answered)

> **Products and inventory.** Digital audio only — narrated tours streamed or downloaded
> in the app. No physical inventory, nothing to fulfil.
>
> **Pricing.** Most tours are free. Paid tours are one-time unlocks at ten fixed price
> points between $0.99 and $19.99, using Apple's in-app purchase tiers. No subscriptions,
> no recurring billing, no trials.
>
> **Shipping.** Not applicable — delivery is digital and immediate, in-app.
>
> **Creator vetting and content control.** Every tour is reviewed by a person before it
> can be seen or purchased: a submission enters a review queue and is published only by an
> administrator, a gate enforced in our database rather than only in the interface. Our
> Acceptable Use Policy (https://dozent.world/acceptable-use/) prohibits adult and sexual
> content, hate speech, violent extremism, illegal activity, weapons, drugs, tobacco,
> gambling, cryptocurrency and securities offerings, counterfeit goods and infringing
> material. Users can report any tour from inside the app, which alerts us directly, and
> we can remove a tour from circulation immediately. Creators who receive payouts onboard
> through Stripe Connect Express, so identity and bank verification is performed by Stripe.
>
> **On audience:** our end users are individual consumers, but those purchases are
> processed by Apple, not Stripe. The only party ever paid through Stripe is a content
> creator.

### Q4. "Do you plan to sell physical goods?" → **No**

## Round 3 — 2026-08-19 ("Additional details needed about your business")

Two fields: a **Website URL**, and an optional box for "if we've misunderstood or
miscategorised your business."

### Website URL

**Submitted: `https://dozent.world/about/`** — the strongest of the available options,
since it describes the product in full, and the splash page at the apex does not.

**⚠️ This WAS the weak point of the whole file — ✅ RESOLVED 2026-09-01 by the public release.
See round 5; the answer is now the App Store listing.** At the time of round 3 Stripe had asked for
"an active website link where we can view the products and services that you will be processing
through your Stripe account," and nothing could satisfy it:

- `dozent.world` was a splash page reading **COMING SOON**
- `dozent.world/about/` described the product well but showed **no actual products**
- there was no public App Store page — 1.1 had never been released

**This, not the wording, is the likeliest reason rounds 1–4 kept coming back.** Four rounds of
argument could not substitute for a reviewer being able to look at the thing.

### Optional box — submitted text

> We may be creating confusion by answering as though we process product sales through
> Stripe, so to be explicit: we do not, and we do not plan to.
>
> Dozent's consumer sales happen entirely inside an iOS app through Apple In-App Purchase.
> Apple is the merchant of record — Apple takes the payment, handles refunds and
> chargebacks, and remits our share to us. Stripe is not in that path and never sees a
> cardholder.
>
> Our Stripe account exists to do one thing: pay content creators, through Connect
> Express, out of revenue Apple has already remitted to us. The only money that will ever
> move through Stripe is an outbound transfer from us to a creator's own connected
> account. There are no consumer charges to review, no inventory, no shipping and no
> chargeback exposure to Stripe.
>
> Because the app has not yet been publicly released — version 1.1 is in App Store review
> — the tours are not purchasable anywhere yet, and we have processed no transactions and
> made no payouts to date.
>
> If it would assist your review, we would be glad to provide a TestFlight build so you
> can see the app and its full catalogue directly.
## Round 4 — 2026-09-11 (a repeat of the round-3 form)

A fourth request arrived. The owner submitted the same four load-bearing facts again, with
`https://dozent.world/about/` as the website URL.

**No new argument was made, because there was none left to make.** Rounds 1–3 had already said
everything true about the architecture. What the response could not do — then — was let a reviewer
*see* a product, because none of `dozent.world`, `/about/` or the App Store showed one.

**⚠️ Submitted before the app went live, and superseded within hours by round 5.** Recorded here only
so the count is right and nobody mistakes round 5 for round 4.

## Round 5 — 2026-09-11 (SUBMITTED by the owner)

**The app went live on 2026-09-01**, and that is the whole change. Stripe had asked four times for
"an active website link where we can view the products and services." There is now one:

**Website URL: `https://apps.apple.com/us/app/dozent/id6771030927`**

**Not `dozent.world/about/` this time, and not the deferred `/tours/` page.** The App Store listing
carries ten screenshots, the full description, the category, the price and the seller name — and it
carries Apple's authority rather than being a page we built to satisfy a reviewer. **It is also
evidence for the merchant-of-record claim rather than an assertion of it**: the listing shows Apple
selling the app.

### Verified live before drafting (2026-09-11)

| | |
|---|---|
| App Store | `id6771030927`, v1.1.1, released 2026-09-01T15:23:09Z, Travel, Free |
| Seller (public) | EDWARD HO KIU YUNG |
| Support URL on listing | `dozent.world` |
| Live catalogue (`get_catalog`) | 1,553 tours · 404 makers · 142 places · 1,717 link pins |
| Priced tours | **66, all at tier 99 ($0.99)** — still the documented uniform test state |
| `dozent.world/tours/` | 404 — never built, and now dead scope |

### The two facts that changed, and why they had to

**1. "No transactions processed" became false and was removed.** The app has been selling for ten
days. See Purchase evidence below. The replacement wording claims only what is checkable.

**2. "All content is first-party Atlas studios" became false and was disclosed.** The app now carries
1,717 link pins credited to ~343 TikTok/YouTube/Instagram accounts. A reviewer opening Dozent sees a
map full of other people's videos — which reads *more* like a content creation platform, the exact
category flagged in round 1. **Leaving that to be discovered would have been the worst outcome**, so
round 5 names it in one sentence on our own terms.

### 🔴 THE FORM GREW A THIRD FIELD — check the form, do not assume round 3's shape

Rounds 3 and 4 were **two fields** (Website URL + an optional "misunderstood or miscategorized"
box). Round 5 carries the same title — *"Additional details needed about your business"* — and the
same two fields, **plus a new required box above them**: *"Please provide any additional information
about the products and services you'll be processing through your Stripe account."*

**A single block of prose drafted for the old shape had to be split across two boxes on the spot.**
The owner caught it by sending a screenshot before pasting. **Always ask to see the form.**

### Box 1 (new, required) — "products and services you'll be processing through your Stripe account"

**Answered the question literally, because the literal answer is "nothing".**

> Nothing is processed through our Stripe account. We do not use Stripe to accept payment from
> customers, and no cardholder transacts with us through Stripe.
>
> Dozent is a GPS-triggered audio tour app, released on the App Store on 1 September 2026:
> https://apps.apple.com/us/app/dozent/id6771030927
>
> Listeners download narrated walking tours that play automatically when they reach each stop. The
> app is free to download. Most tours are free, and paid tours are one-time unlocks at fixed Apple
> price tiers starting at $0.99. There are no subscriptions and no physical goods.
>
> Apple is the merchant of record for 100% of consumer purchases, through In-App Purchase. Apple
> takes the payment, handles all refunds and chargebacks, and remits our share to us. Stripe is not
> in that path and never sees a cardholder, so there is no chargeback exposure to Stripe.
>
> Our Stripe account exists for one purpose: Stripe Connect Express, to pay content creators their
> share of revenue Apple has already remitted to us. The only money that would ever move through
> Stripe is an outbound transfer from us to a creator's own connected account.
>
> No payout has ever been made through Stripe. Today the only creator of any paid tour is the
> account holder, so the only transfer possible right now would be from us to ourselves. Since
> release the app has recorded a single consumer purchase, of one $0.99 tour, processed entirely by
> Apple; Apple has not yet remitted those proceeds, as its first payment cycle has not completed.

### Box 2 — Website URL

**Submitted: `https://apps.apple.com/us/app/dozent/id6771030927`**

### Box 3 (optional) — "misunderstood or miscategorized"

**Filled, not skipped — it is the only place the original Restricted Businesses flag gets answered.**

> We believe our account was flagged against the Restricted Businesses list, and the original notice
> was ambiguous between two entries: "Content creation platforms" and "Travel reservation services
> and clubs." Our App Store category is Travel, so we will address both.
>
> We are not a travel reservation service. There are no bookings, dates, seats or supplier
> inventory, and nothing is delivered at a future date. A purchase unlocks an audio file
> immediately, in-app.
>
> On the content platform reading: Stripe is a payout rail for us, not a payment-acceptance channel,
> and it has never carried a transaction. We are not a money transmitter — Connect Express exists
> precisely so that Stripe, not the platform, is the regulated party.
>
> Every tour is reviewed by a person before it can be seen or purchased, and publishing is
> restricted to an administrator, enforced in our database rather than only in the interface. Our
> Acceptable Use Policy prohibits adult content, hate speech, violent extremism, illegal activity,
> weapons, drugs, gambling, cryptocurrency and securities offerings, counterfeit goods and
> infringing material. Users can report any tour from inside the app.
>
> For completeness: the app also displays publicly available social media posts pinned to map
> locations, credited to their original creators. These are links to public posts, not paid
> placements, and no payment of any kind is involved.
>
> Our app is now publicly available, so the product can be viewed directly at the link above.
>
> Policies: https://dozent.world/acceptable-use/ · https://dozent.world/terms/ ·
> https://dozent.world/privacy/

**🔴 Naming the actual number is the point, not a weakness.** A business with one ninety-nine-cent
sale is self-evidently not what a Restricted Businesses list exists to catch, and it is checkable
against a listing the reviewer can now open. Rounds 1–4 argued architecture; round 5 offers arithmetic.

## Purchase evidence — the `purchases` table, read 2026-09-11

The owner asked whether a friend's purchase had worked, having received nothing from Apple. Four rows,
none refunded:

| Date (UTC) | Tour | Tier | Apple transaction id | Reading |
|---|---|---|---|---|
| **2026-09-01 16:22** | **Fifth Avenue Walk** (NYC) | 99 | **410003411523521** | **Production — one real sale** |
| 2026-08-28 01:33 | Golden Gate Park: The Music Concourse | 99 | 2000001228058648 | Sandbox |
| 2026-08-17 00:10 | AMNH: Four Facades | 99 | 2000001222234867 | Sandbox |
| 2026-08-12 23:42 | Empire State Building | 299 | 2000001220498950 | Sandbox |

- **The sandbox/production split is read off the transaction-id shape and the dates.** The three
  `2000001…` ids are Apple's sandbox format and all predate the 1 September release. The
  `410003411523521` id is a different shape and landed **59 minutes after the app went live**.
- **The Empire State Building row corroborates the whole reading.** Tier 299 on 2026-08-12, while
  § LIVE PRICING records that tour being priced at 299 for the Phase 3 sandbox test and **reset to
  free on 2026-08-16**. It is free in the live catalogue today. A documented test purchase, exactly
  where it should be.
- **✅ THE ES256-vs-"legacy secret" RISK IS CLOSED BY EVIDENCE.** The session-79 note flagged that a
  real signed-in user's token might fail the `record-purchase` JWT gate, and that it could not be
  tested until a logged-in buyer existed. Four rows exist, written after Apple's server API verified
  each receipt. **Real user tokens pass. Do not re-open this without a new failure.**
- **⚠️ No Apple remittance is arithmetic, not a bug.** Apple pays ~30–45 days after the fiscal month
  closes, holds proceeds until a minimum threshold (commonly ~$10 USD), and requires complete tax and
  banking forms. One $0.99 sale nets roughly **$0.84** at the 15% Small Business Program rate. **At
  this volume there will be no Apple payment for a long time, and that says nothing about the code.**
- **⚠️ The four tables cannot be read with the publishable key** — `purchases`, `maker_sales`,
  `maker_earnings` and `payouts` all return `[]` to an anonymous caller because RLS is working.
  **An empty result from outside is not evidence of an empty table.** Read them in the SQL Editor.

## Process warnings (carried forward, plus one new)

- **Stripe's textareas are React-controlled and can display text that is not what submits.** Paste
  rather than type, then reload and confirm before submitting. This cost a whole round in August, and
  the owner — not any automated check — caught it.
- **Check the live system, not a project note, before asserting a fact to Stripe.** `CLAUDE.md`
  claimed the account was in test mode; it was activated. That nearly went to a financial institution
  as a false statement.
- **🔴 NEW, AND THE MOST EXPENSIVE ONE SO FAR: a fact that was true in round 1 can be false by round
  5, and re-sending it is how a true answer becomes a false one.** Both "no transactions processed"
  and "all content is first-party" were accurate when first written and had quietly stopped being so.
  **Before every submission, re-verify every factual claim against the live system** — the App Store
  lookup API, `get_catalog`, and the `purchases` table — rather than copying forward what closed the
  last round.
- **🔴 ASK TO SEE THE FORM BEFORE DRAFTING A WORD.** Round 5 reused round 3's title exactly —
  *"Additional details needed about your business"* — and had **three fields, not two**. A response
  drafted for the old shape had to be split across two boxes at the moment of pasting, and only
  because the owner sent a screenshot first. **The title does not identify the form.**
- **Save the submitted text here at the time of submission.** Round 1's wording is lost.

## Open items

- **✅ The public catalogue page at `dozent.world/tours/` is DEAD SCOPE — do not build it.** It was
  deferred in round 3 pending whether the written answers would close the review, and its trigger
  ("Stripe comes back a fourth time, or asks about the website specifically") did fire. But the App
  Store listing now does that job better and with Apple's authority behind it. A public tour catalogue
  is a marketing decision now, not a Stripe one.
- **The TestFlight offer made in round 3 is still live and unanswered**, and is now largely moot —
  anyone can download the released app.
- **Stripe's standing cannot be checked from this environment.** No API, no dashboard access. The
  outcome reaches the owner, not a session. **Never report Stripe status from `CLAUDE.md`.**
- **Apple tax/banking forms are unverifiable from here** (no API). If a payment is ever genuinely
  overdue, check Business → Agreements, Tax, and Banking before suspecting the code.
- **EU DSA trader declaration** — the app is declared non-trader while selling paid IAP tiers.
  Unrelated to Stripe, same sole-proprietor-vs-LLC decision.
- **The LLC decision.** Note that Apple publishes the seller as **EDWARD HO KIU YUNG**, while the
  website says "operated by AHWY/EHKY" — so the legal name is public regardless, and the App Store
  listing now corroborates identity in a way the site deliberately does not.

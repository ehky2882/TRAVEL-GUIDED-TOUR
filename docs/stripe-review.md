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
| Transactions / payouts to date | **None**, ever |
| Regulated party | **Stripe**, by design — Connect Express exists so the platform is not the money transmitter |
| Catalogue | 1,418 tours, 31 makers — **all first-party Atlas studios; no third-party creator has published or been paid** |
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

## Process warnings

- **Stripe's textareas are React-controlled and can display text that is not what
  submits.** Paste rather than type, then reload the page and confirm the text is still
  there before submitting. This cost a whole round in August, and the owner — not any
  automated check — was the one who caught it.
- **Check the live system, not a project note, before asserting a fact to Stripe.**
  `CLAUDE.md` claimed the account was in test mode; it was activated. That nearly went to
  a financial institution as a false statement.
- **Save the submitted text here, in this file, at the time of submission.** Round 1's
  wording is lost, which made round 2 harder than it needed to be.

## Round 3 — 2026-08-19 ("Additional details needed about your business")

Two fields: a **Website URL**, and an optional box for "if we've misunderstood or
miscategorised your business."

### Website URL

**Submitted: `https://dozent.world/about/`** — the strongest of the available options,
since it describes the product in full, and the splash page at the apex does not.

**⚠️ This is the weak point of the whole file.**
Stripe asked for "an active website link where we can view the products and services that
you will be processing through your Stripe account," and today:

- `dozent.world` is a splash page reading **COMING SOON**
- `dozent.world/about/` describes the product well but shows **no actual products**
- there is no public App Store page — 1.1 has never been released

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

## Open risk and the trigger for acting on it

**A public catalogue page at `dozent.world/tours/` was proposed and deliberately deferred
(owner decision, 2026-08-19).** The reasoning for deferring: three rounds in, it is worth
seeing whether the written answers close the review before investing in the page.

**Build it if any of these happen:**

- Stripe comes back a fourth time, or asks about the website specifically
- The account is restricted, or payouts are blocked
- Third-party creators are about to be onboarded (at which point a public catalogue is
  needed anyway)

Everything required already exists: 1,418 tours with titles, descriptions, cities,
durations and hero images in `Tours.json` and on the gh-pages CDN. It is website-only work
in `site/` — no Swift, no app build, no App Store involvement — and the auto-merge class
under CLAUDE.md § Merging PRs. Match `site/atlas.css`; state pricing in prose ("most tours
free; paid tours are one-time unlocks from $0.99 to $19.99") rather than per-tour, because
`price_tier` lives only in Supabase and is not in `Tours.json`.

The other standing offer, if a reviewer says they cannot verify the product: **give them a
TestFlight build.** It was offered in the round-3 text above.

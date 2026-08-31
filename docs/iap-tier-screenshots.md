# In-app purchase tiers — the review screenshots

Apple wants one **review screenshot per purchase**, showing that purchase where
it appears in the app. Fourteen tiers means fourteen screenshots, and each has
to show its own real price — which is the whole reason nine of them have been
sitting in `MISSING_METADATA` since August. Every walk costs $0.99 today, so
there was no $2.99 paywall to photograph.

This is one sitting, not a project. Price is stored in Supabase, not in the
binary, so a tour can be moved through every tier in a few minutes.

## The menu

| Tier | Product id | Tier | Product id |
|---|---|---|---|
| $0.99 | `tour.tier.099` | $8.99 | `tour.tier.899` |
| $1.99 | `tour.tier.199` | $9.99 | `tour.tier.999` |
| $2.99 | `tour.tier.299` | $12.99 | `tour.tier.1299` |
| $3.99 | `tour.tier.399` | $14.99 | `tour.tier.1499` |
| $4.99 | `tour.tier.499` | $17.99 | `tour.tier.1799` |
| $5.99 | `tour.tier.599` | $19.99 | `tour.tier.1999` |
| $6.99 | `tour.tier.699` | | |
| $7.99 | `tour.tier.799` | | |

**599, 799, 1299 and 1799 are new** (owner decision 2026-08-31) and their App
Store products do not exist yet — create those four first.

⚠️ **`backend/widen_price_tiers.sql` must be applied before any tour can be
priced at one of the four new tiers.** Until it is, the `CHECK` constraint
rejects the update. **Do NOT re-run `paid_tours.sql` to pick this up** — it
would destroy the place layer; its own header explains why.

## Before you start

- Apply `backend/widen_price_tiers.sql` in the Supabase SQL Editor.
- Create the four new products in App Store Connect, matching the existing ten:
  **Non-Consumable**, reference name `Tour Tier <price>`, US base price with
  Apple auto-pricing, display name **Premium Audio Tour**, description
  **Unlocks this audio tour**. The copy is identical across tiers on purpose —
  the payment sheet shows the price.
- Sign in on the device, and make sure the tour below is **not already bought**
  on that account, or the paywall will not render.

## The tour to use

**The South Bank Mile** (London, 10 stops) —
`7fa917ae-1898-4f8c-a5b7-de75f8fa54bb`

Any paid walk works. This one is long enough that a price reads as reasonable
at every rung, which matters when a reviewer sees $17.99.

## The loop

For each tier, run the update, force-quit and reopen the app so the catalogue
refetches, open the tour, and photograph the paywall.

```sql
-- one at a time; substitute the tier
update public.tours set price_tier = 599
 where id = '7fa917ae-1898-4f8c-a5b7-de75f8fa54bb';
```

Tiers in order: `99, 199, 299, 399, 499, 599, 699, 799, 899, 999, 1299, 1499,
1799, 1999`.

⚠️ **The price on screen comes from StoreKit, not from us.** A tier whose App
Store product does not exist yet renders the fallback text instead of a real
price, and a fallback price in a review screenshot is exactly what gets it
rejected. Create all four products before starting.

## Putting it back

```sql
update public.tours set price_tier = 99
 where id = '7fa917ae-1898-4f8c-a5b7-de75f8fa54bb';
```

⚠️ Verify afterwards, against the live RPC rather than the SQL Editor's success
line:

```sql
select price_tier, count(*) from public.tours
 where price_tier is not null group by 1 order by 1;
```

Every multi-stop walk should read 99. See CLAUDE.md § LIVE PRICING — the
uniform $0.99 is **one maker's temporary test state, not a rule**, and it is the
thing this session is most likely to disturb by accident.

## Uploading

🔴 **The screenshot must be a native device size. A cropped image is
rejected** with `IMAGE_INCORRECT_DIMENSIONS`, after uploading cleanly and going
`FAILED` on Apple's side minutes later. **1320 × 2868** (iPhone 17 Pro Max) was
accepted; a 1206 × 2105 crop was not.

Then, per product: App Store Connect → the purchase's **own page** → the **Add
for Review** dropdown → pick the draft submission. It is not on the version
page, not on the App Review page, and there is **no API path** to it.

⚠️ **`bundle exec fastlane release` does not attach purchases.** It submits the
version and nothing else — an approved binary whose Buy buttons lead nowhere.

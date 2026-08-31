-- ---------------------------------------------------------------------------
-- widen_price_tiers.sql — the price menu goes 10 tiers → 14.
--
-- Owner decision 2026-08-31: fill the working band with dollar steps, keep the
-- top end coarse. Adds **599, 799, 1299, 1799**:
--
--   0.99 1.99 2.99 3.99 4.99 5.99 6.99 7.99 8.99 9.99   12.99 14.99 17.99 19.99
--
-- Below $10 a dollar is a real positioning decision, so every rung exists.
-- Above it nobody distinguishes $16.99 from $17.99, and each rung costs an App
-- Store product plus a review screenshot — so the steps widen.
--
-- 🔴 WHY THIS IS ITS OWN FILE INSTEAD OF AN EDIT TO paid_tours.sql.
-- `paid_tours.sql` contains `create or replace function public.get_catalog()`,
-- and since `places.sql` that function is a WRAPPER over `get_catalog_core`.
-- Re-running it today would overwrite the wrapper with a full body and
-- silently drop `places`, `priceTier` and `isPrivate` from the payload — with
-- no error. Its own header says so. **Do not re-run paid_tours.sql to pick up
-- the new tiers.** This file changes the two CHECK constraints and nothing
-- else; it never mentions get_catalog.
--
-- ⚠️ NO APP BUILD IS NEEDED. `Tour.storeProductId` computes the id from the
-- number (`"tour.tier." + %03d`), so every shipped build already understands
-- any tier. What gates a new tier is this constraint plus the App Store
-- product existing and approved.
--
-- Idempotent — safe to re-run. Read-only against every table's data.
-- ---------------------------------------------------------------------------

begin;

-- Both lists must always match: a tour can only be priced at a tier a purchase
-- is allowed to record, or the earnings math takes an unbounded number.
alter table public.tours drop constraint if exists tours_price_tier_allowed;
alter table public.tours add constraint tours_price_tier_allowed
    check (price_tier is null or price_tier in
           (99, 199, 299, 399, 499, 599, 699, 799, 899, 999,
            1299, 1499, 1799, 1999));

alter table public.purchases drop constraint if exists purchases_price_tier_allowed;
alter table public.purchases add constraint purchases_price_tier_allowed
    check (price_tier in
           (99, 199, 299, 399, 499, 599, 699, 799, 899, 999,
            1299, 1499, 1799, 1999));

-- Verify inside the transaction and RAISE rather than half-apply. Widening a
-- closed set cannot orphan an existing row — but assert it rather than assume,
-- because a hand-edited price would fail the constraint at ADD time and this
-- says which table.
do $$
declare
    bad_tours int;
    bad_buys  int;
    n_cons    int;
begin
    select count(*) into bad_tours
      from public.tours
     where price_tier is not null
       and price_tier not in (99, 199, 299, 399, 499, 599, 699, 799, 899, 999,
                              1299, 1499, 1799, 1999);

    select count(*) into bad_buys
      from public.purchases
     where price_tier not in (99, 199, 299, 399, 499, 599, 699, 799, 899, 999,
                              1299, 1499, 1799, 1999);

    if bad_tours > 0 or bad_buys > 0 then
        raise exception
            'price tier outside the allowed set: % tours, % purchases',
            bad_tours, bad_buys;
    end if;

    select count(*) into n_cons
      from pg_constraint
     where conname in ('tours_price_tier_allowed', 'purchases_price_tier_allowed');

    if n_cons <> 2 then
        raise exception
            'expected both tier constraints to exist, found %', n_cons;
    end if;

    raise notice 'price tiers widened to 14; % tours and % purchases checked, 0 outside the set',
        (select count(*) from public.tours where price_tier is not null),
        (select count(*) from public.purchases);
end $$;

commit;

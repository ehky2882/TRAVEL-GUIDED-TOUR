-- Pull four link pins and two pinned-creator rows from the LIVE catalog.
-- Owner instruction 2026-08-28: "Pull empire theatre, Brooklyn bridge caissons
-- and the octagon. In fact pull the user nycunfilteredstories."
--
-- 🔴 WHY THIS FILE HAS TO EXIST AT ALL.
-- `seed_from_toursjson.py` is UPSERT-ONLY by design (so a content re-seed can
-- never wipe maker-created rows). Deleting a pin from Tours.json therefore
-- removes it from the gh-pages mirror and from the bundled offline seed, and
-- leaves it untouched in Postgres — which is the source the app reads FIRST.
-- Without this file the four pins stay on every phone.
--
-- Safe to run once; safe to re-run (the deletes simply match nothing the
-- second time). Paste the whole thing into the Supabase SQL Editor and Run.
--
-- ⚠️ Supabase may warn about "destructive operations". That is expected — this
-- file deletes rows on purpose. The verify block at the end prints what is
-- left, and the whole thing is one transaction, so if any statement fails
-- nothing is applied.

begin;

-- 1. The four link pins.
--    `stops` cascades from `tours`, so their placeholder stops go too, as do
--    any saved-library / recently-viewed / list rows referencing them.
--    `purchases.tour_id` is ON DELETE RESTRICT, but these are free pins
--    (price_tier is null), so nothing can be referencing them there.
delete from public.tours where id in (
    '9fe2a045-a1e7-58a3-b06b-1cde9da3c2bc',  -- Verrazzano-Narrows Bridge
    'a557a03a-9b88-59bf-8463-6b1f7fdf55d2',  -- Empire Theatre, 42nd Street
    '25a8af20-3b33-5a9f-885d-90553f97c095',  -- The Brooklyn Bridge Caissons
    'c79c2fd5-4583-50d8-8f9f-0ec311cf5530'   -- The Octagon, Roosevelt Island
);

-- 2. The two creator rows, now that nothing references them.
--    `tours.maker_id` is ON DELETE RESTRICT, so this MUST come second — and it
--    is also the safety net: if a pin above somehow survived, this fails and
--    the transaction rolls back rather than half-applying.
--    Both are pinned-creator rows we minted (user_id is null); neither is a
--    real signed-up account.
delete from public.makers where id in (
    '7b5265cd-e6d6-534d-a501-d0bc50369bf8',  -- Instagram @nycunfilteredstories
    'fa4a1e67-9ac1-5c60-a33f-21981130397d'   -- Instagram @theironwil
);

-- 3. Verify inside the transaction: raise (and roll everything back) if any of
--    the six rows is still there.
do $$
declare
    n_tours  int;
    n_makers int;
begin
    select count(*) into n_tours from public.tours where id in (
        '9fe2a045-a1e7-58a3-b06b-1cde9da3c2bc',
        'a557a03a-9b88-59bf-8463-6b1f7fdf55d2',
        '25a8af20-3b33-5a9f-885d-90553f97c095',
        'c79c2fd5-4583-50d8-8f9f-0ec311cf5530');
    select count(*) into n_makers from public.makers where id in (
        '7b5265cd-e6d6-534d-a501-d0bc50369bf8',
        'fa4a1e67-9ac1-5c60-a33f-21981130397d');
    if n_tours <> 0 or n_makers <> 0 then
        raise exception 'pull incomplete: % tour(s) and % maker(s) still present',
            n_tours, n_makers;
    end if;
    raise notice 'pull complete: 4 pins and 2 creator rows removed';
end $$;

commit;

-- 4. Read the result back. Expect linkPins 150 and neither creator listed.
--    (`tours` and `makers` totals stay ABOVE the catalogue's own figures --
--    the long-standing Zxxx test tour and upsert-only maker accumulation from
--    real signups. Assert on the link-pin count, not the totals.)
select
    jsonb_array_length(public.get_catalog() -> 'linkPins') as link_pins,
    jsonb_array_length(public.get_catalog() -> 'tours')    as tours,
    jsonb_array_length(public.get_catalog() -> 'makers')   as makers,
    jsonb_array_length(public.get_catalog() -> 'places')   as places;

-- Pull link pins from the LIVE catalog. One paste closes everything outstanding.
--
-- Owner instruction 2026-08-29: "pull the instagram zacherlhaus one" — the same
-- clip of Plecnik's Zacherlhaus was cross-posted to TikTok and Instagram, so it
-- shipped as two pins on one coordinate. The TikTok one STAYS.
--
-- 🔴 THIS FILE SUPERSEDES `pull_nycunfilteredstories.sql` AND REPEATS ITS
-- DELETIONS, because the live catalog shows they were never applied: on
-- 2026-08-29 the RPC was still serving all four of those pins and both creator
-- rows, eight days after they left Tours.json. Running the older file as well
-- is harmless (both are idempotent); running THIS one is sufficient.
--
-- 🔴 WHY A SQL FILE IS NEEDED AT ALL.
-- `seed_from_toursjson.py` is UPSERT-ONLY by design (so a content re-seed can
-- never wipe maker-created rows). Deleting a pin from Tours.json therefore
-- removes it from the gh-pages mirror and from the bundled offline seed, and
-- leaves it untouched in Postgres — which is the source the app reads FIRST.
-- Without this file the pins stay on every phone.
--
-- Safe to run once; safe to re-run (the deletes simply match nothing the second
-- time). Paste the whole thing into the Supabase SQL Editor and press Run.
--
-- ⚠️ Supabase may warn about "destructive operations". That is expected — this
-- file deletes rows on purpose. The verify block at the end prints what is
-- left, and the whole thing is one transaction, so if any statement fails
-- nothing is applied.

begin;

-- 1. This session's pin.
--    `stops` cascades from `tours`, so its placeholder stop goes too, as do any
--    saved-library / recently-viewed / list rows referencing it.
--    `purchases.tour_id` is ON DELETE RESTRICT, but a link pin is free
--    (price_tier is null), so nothing can be referencing it there.
delete from public.tours where id in (
    '488afba8-9b62-5334-9e76-a9b078be3e80'   -- Zacherlhaus (Instagram @about_buildings)
);

-- ⚠️ `Instagram @about_buildings` is NOT deleted. It still carries six other
--    pins (St Alban the Martyr, Blenheim Palace, Orford Ness, the Royal
--    Hospital Chelsea stable block, the Florence Charterhouse, Assisi), and
--    `tours.maker_id` is ON DELETE RESTRICT, so deleting it would fail anyway.
--    Its TikTok twin `TikTok @about_buildings` keeps thirteen pins, including
--    the Zacherlhaus post that stays.

-- 2. The four pins from the 2026-08-28 pull, repeated because the live catalog
--    shows they are still present. Owner instruction that day: "Pull empire
--    theatre, Brooklyn bridge caissons and the octagon. In fact pull the user
--    nycunfilteredstories."
delete from public.tours where id in (
    '9fe2a045-a1e7-58a3-b06b-1cde9da3c2bc',  -- Verrazzano-Narrows Bridge
    'a557a03a-9b88-59bf-8463-6b1f7fdf55d2',  -- Empire Theatre, 42nd Street
    '25a8af20-3b33-5a9f-885d-90553f97c095',  -- The Brooklyn Bridge Caissons
    'c79c2fd5-4583-50d8-8f9f-0ec311cf5530'   -- The Octagon, Roosevelt Island
);

-- 3. Their two creator rows, now that nothing references them.
--    `tours.maker_id` is ON DELETE RESTRICT, so this MUST come after the pins —
--    and it is also the safety net: if a pin above somehow survived, this fails
--    and the transaction rolls back rather than half-applying.
--    Both are pinned-creator rows we minted (user_id is null); neither is a
--    real signed-up account.
delete from public.makers where id in (
    '7b5265cd-e6d6-534d-a501-d0bc50369bf8',  -- Instagram @nycunfilteredstories
    'fa4a1e67-9ac1-5c60-a33f-21981130397d'   -- Instagram @theironwil
);

-- 4. Verify inside the transaction: raise (and roll everything back) if any of
--    the five pins or two creator rows is still there, or if the six surviving
--    Instagram @about_buildings pins were touched.
do $$
declare
    n_tours  int;
    n_makers int;
    n_keep   int;
begin
    select count(*) into n_tours from public.tours where id in (
        '488afba8-9b62-5334-9e76-a9b078be3e80',
        '9fe2a045-a1e7-58a3-b06b-1cde9da3c2bc',
        'a557a03a-9b88-59bf-8463-6b1f7fdf55d2',
        '25a8af20-3b33-5a9f-885d-90553f97c095',
        'c79c2fd5-4583-50d8-8f9f-0ec311cf5530');
    select count(*) into n_makers from public.makers where id in (
        '7b5265cd-e6d6-534d-a501-d0bc50369bf8',
        'fa4a1e67-9ac1-5c60-a33f-21981130397d');
    select count(*) into n_keep from public.tours
        where maker_id = '9aa4659b-4fee-586a-926d-0a9264cad908';
    if n_tours <> 0 or n_makers <> 0 then
        raise exception 'pull incomplete: % pin(s) and % creator row(s) still present',
            n_tours, n_makers;
    end if;
    if n_keep <> 6 then
        raise exception 'expected 6 surviving Instagram @about_buildings pins, found %', n_keep;
    end if;
    raise notice 'pull complete: 5 pins and 2 creator rows removed; 6 kept';
end $$;

commit;

-- 5. Read the result back. Expect link_pins = 168.
--    (`tours` and `makers` totals stay ABOVE the catalogue's own figures — the
--    long-standing Zxxx test tour and upsert-only maker accumulation from real
--    signups. Assert on the link-pin count, not the totals.)
select
    jsonb_array_length(public.get_catalog() -> 'linkPins') as link_pins,
    jsonb_array_length(public.get_catalog() -> 'tours')    as tours,
    jsonb_array_length(public.get_catalog() -> 'makers')   as makers,
    jsonb_array_length(public.get_catalog() -> 'places')   as places;

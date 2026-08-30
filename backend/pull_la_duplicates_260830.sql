-- Pull two duplicate Los Angeles link pins from the LIVE catalog, plus the
-- creator row and the place page that only existed because of them.
--
-- Owner instruction 2026-08-30:
--   "hotel casa del mar - remove one of the tours. doesnt matter which one.
--    this also means this locaiton doesnt need a place page anymore"
--   "castle green in pasadena - take out the youtube version of the tour"
--
-- 🔴 WHY A SQL FILE IS NEEDED AT ALL.
-- `seed_from_toursjson.py` is UPSERT-ONLY by design (so a content re-seed can
-- never wipe maker-created rows). Deleting a pin from Tours.json therefore
-- removes it from the gh-pages mirror and from the bundled offline seed, and
-- leaves it untouched in Postgres — which is the source the app reads FIRST.
-- Without this file both duplicates stay on every phone.
--
-- Safe to run once; safe to re-run (the deletes simply match nothing the second
-- time). Paste the whole thing into the Supabase SQL Editor and press Run.
--
-- ⚠️ Supabase may warn about "destructive operations". That is expected — this
-- file deletes rows on purpose. The verify block at the end raises rather than
-- half-applying, and the whole thing is one transaction.

begin;

-- 1. The two duplicate pins.
--    `stops` cascades from `tours`, so each placeholder stop goes too, as do
--    any saved-library / recently-viewed / list rows referencing them.
--    `purchases.tour_id` is ON DELETE RESTRICT, but a link pin is free
--    (price_tier is null), so nothing can be referencing it there.
delete from public.tours where id in (
    -- Hotel Casa del Mar, Santa Monica. The creator posted the same script
    -- twice, months apart. This is the LATER post; its thumbnail is a downward
    -- view onto a patio with a palm trunk through the middle and only a sliver
    -- of the building, so the earlier post's lobby-staircase frame is the
    -- better map pin and is the one kept.
    'cc95f611-1372-5583-9234-8909afd6456d',

    -- Castle Green, Pasadena. Same subject as the surviving TikTok pin; the
    -- owner asked specifically for the YouTube version to go.
    '678625ac-2c18-5054-97b4-e2a2acccb62d'
);

-- 2. The YouTube creator row, now that nothing references it.
--    `tours.maker_id` is ON DELETE RESTRICT, so this MUST come after the pins —
--    and it is also the safety net: if the pin above somehow survived, this
--    fails and the transaction rolls back rather than half-applying.
--    The Castle Green YouTube pin was this row's ONLY entry (the @theironwil /
--    @morganjamesjr precedent: pull the sole creator row with the sole pin).
--    ⚠️ This is a DIFFERENT row from `TikTok @thedesigndetourist`
--    (67ca14a6-…), which keeps 19 pins including the Castle Green one we are
--    keeping. Do not confuse the two — the uuid5 scheme keys on
--    `<platform>:@handle`, so one creator on two platforms is two rows.
delete from public.makers where id in (
    'de9eedae-9bf0-52c5-9067-a38eede85e77'   -- YouTube @Thedesigndetourist
);

-- 3. The Hotel Casa del Mar place page.
--    A place needs two members to mean anything, and it only ever had the two
--    duplicate pins. `tours.place_id` is ON DELETE SET NULL, so the surviving
--    pin is unlinked automatically.
--    ⚠️ Even without this delete the place would stop being served —
--    `catalog_places()` filters to places with >= 2 published tours — but the
--    row would linger and a future session would read 41 places in the table
--    against 40 in the catalogue.
delete from public.places where id = 'ee70c29e-77b1-5af2-96ff-140dcc0e9918';

-- 4. Verify inside the transaction: raise (and roll everything back) if any of
--    the deletions missed, or if a survivor was taken by mistake.
do $$
declare
    n_gone     int;
    n_maker    int;
    n_place    int;
    n_survivor int;
    n_tiktok   int;
begin
    select count(*) into n_gone from public.tours where id in (
        'cc95f611-1372-5583-9234-8909afd6456d',
        '678625ac-2c18-5054-97b4-e2a2acccb62d');
    select count(*) into n_maker from public.makers
        where id = 'de9eedae-9bf0-52c5-9067-a38eede85e77';
    select count(*) into n_place from public.places
        where id = 'ee70c29e-77b1-5af2-96ff-140dcc0e9918';
    -- The two pins that must SURVIVE: Hotel Casa del Mar (lobby staircase)
    -- and Castle Green (TikTok).
    select count(*) into n_survivor from public.tours where id in (
        '6cca19e3-f189-5f8a-ad59-9adcd1673cd4',
        '67f5d022-9cb1-59ae-9531-73959546d01d');
    select count(*) into n_tiktok from public.tours
        where maker_id = '67ca14a6-3350-5c91-842f-81d05800d035';

    if n_gone <> 0 or n_maker <> 0 or n_place <> 0 then
        raise exception 'pull incomplete: % pin(s), % creator row(s), % place(s) still present',
            n_gone, n_maker, n_place;
    end if;
    if n_survivor <> 2 then
        raise exception 'expected both surviving pins, found %', n_survivor;
    end if;
    if n_tiktok <> 19 then
        raise exception 'expected 19 surviving TikTok @thedesigndetourist pins, found %', n_tiktok;
    end if;
    raise notice 'pull complete: 2 pins, 1 creator row and 1 place removed; 2 pins kept';
end $$;

commit;

-- 5. Read the result back. Expect link_pins = 242 and places = 40.
--    (`tours` and `makers` totals stay ABOVE the catalogue's own figures — the
--    long-standing Zxxx test tour and upsert-only maker accumulation from real
--    signups. Assert on the link-pin and place counts, not the totals.)
select
    jsonb_array_length(public.get_catalog() -> 'linkPins') as link_pins,
    jsonb_array_length(public.get_catalog() -> 'places')   as places,
    jsonb_array_length(public.get_catalog() -> 'tours')    as tours,
    jsonb_array_length(public.get_catalog() -> 'makers')   as makers;

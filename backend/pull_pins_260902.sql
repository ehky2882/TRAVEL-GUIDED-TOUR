-- Pull two Hong Kong link pins from the LIVE catalog.
--
-- Owner instructions 2026-09-02, against `@shivanidukhandee`'s Hong Kong batch:
--   * "Take out"             -> Xiang Bo Bo
--   * "Take out (duplicate)" -> Cheung Hing Coffee Shop - Pineapple Bun Hunt
--
-- 🔴 WHY A SQL FILE IS NEEDED AT ALL.
-- `seed_from_toursjson.py` is UPSERT-ONLY by design, so that a content re-seed
-- can never wipe maker-created rows. Deleting a pin from Tours.json therefore
-- removes it from the gh-pages mirror and from the bundled offline seed, and
-- leaves it UNTOUCHED in Postgres -- which is the source the app reads FIRST.
-- Without this file both pins stay on every phone indefinitely. That gap once
-- went unnoticed for eight days (`pull_nycunfilteredstories.sql`).
--
-- Safe to run once; safe to re-run (the deletes simply match nothing the second
-- time). Paste the whole thing into the Supabase SQL Editor and press Run.
--
-- ⚠️ Supabase may warn about "destructive operations". That is expected -- this
-- file deletes rows on purpose. The whole thing is one transaction, so if any
-- statement fails nothing at all is applied, and the verify block at the end
-- raises rather than reporting a false success.

begin;

-- 1. The two pins.
--    `stops` cascades from `tours`, so each placeholder stop goes too, as do
--    any saved-library / recently-viewed / list rows referencing them.
--    `purchases.tour_id` is ON DELETE RESTRICT, but a link pin is free
--    (price_tier is null), so nothing can be referencing it there.
delete from public.tours where id in (
    'c28b8953-9ca5-507d-8d3b-8cdc4c127b63',  -- Xiang Bo Bo
    'c4071953-6434-554d-a268-e9862f46f3d7'   -- Cheung Hing Coffee Shop - Pineapple Bun Hunt
);

-- ⚠️ The maker row `Instagram @shivanidukhandee` is deliberately NOT deleted.
--    It keeps 104 other pins, and `tours.maker_id` is ON DELETE RESTRICT, so
--    deleting it would fail anyway. That restrict doubles as the safety net:
--    if a surviving pin still pointed at a maker being removed, the whole
--    transaction would roll back rather than half-apply.

-- 2. Verify INSIDE the transaction, and raise rather than report success.
do $$
declare
    gone   int;
    kept   int;
    twin   int;
begin
    select count(*) into gone from public.tours
      where id in ('c28b8953-9ca5-507d-8d3b-8cdc4c127b63',
                   'c4071953-6434-554d-a268-e9862f46f3d7');
    if gone <> 0 then
        raise exception 'expected both pins gone, still found %', gone;
    end if;

    -- the surviving Cheung Hing Coffee Shop pin must still be there: the
    -- instruction was "duplicate", not "remove the venue".
    select count(*) into twin from public.tours
      where id = 'd3bb855c-bda5-5e54-97d4-2e79d66229a5';
    if twin <> 1 then
        raise exception 'the Cheung Hing Coffee Shop pin that should REMAIN is missing (found %)', twin;
    end if;

    select count(*) into kept from public.tours t
      join public.makers m on m.id = t.maker_id
      where m.display_name = 'Instagram @shivanidukhandee';
    raise notice 'OK: both pins deleted; @shivanidukhandee keeps % pins; the surviving Cheung Hing pin is intact', kept;
end $$;

commit;

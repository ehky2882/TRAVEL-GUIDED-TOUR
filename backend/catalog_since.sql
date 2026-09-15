-- Atlas — `get_catalog_since(rev)`: send only what changed.
--
-- 🔴 SAFE TO RE-RUN. It adds two functions and touches nothing that exists.
-- It does NOT redefine `get_catalog`, `get_catalog_built`, `get_catalog_core`
-- or `get_catalog_core_base` — backend/README.md explains why replacing any of
-- those wholesale silently drops keys.
--
-- Requires: backend/catalog_snapshot.sql and backend/catalog_rev.sql.
--
-- ---------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------
-- Measured 2026-09-14: the app downloads 2,427,222 compressed bytes whenever
-- anything changes, to deliver a median 7,019 bytes of actual new content —
-- about 345x more than needed. That is the egress bill, and the same design is
-- what took the backend down for ~11h45m on 2026-09-14.
--
-- 🔴 THE HARD CONSTRAINT IS "ONE SHAPER, NOT TWO".
-- docs/delta-catalog-fetch-design.md § Phase 1: a hand-written second shaper
-- would drift from the real builder, and the drift would be INVISIBLE — new
-- builds quietly receiving a different tour shape from old ones. That is the
-- 2026-08-19 incident (`places`, `priceTier` and `isPrivate` gone for 14 hours)
-- waiting to happen again, restricted to whichever rows changed that day.
--
-- It cannot be solved by copying the builder either, because backend/README.md
-- is explicit that NO FILE IN THIS DIRECTORY MATCHES WHAT IS RUNNING: the live
-- definition is the accumulation of migrations that each rebuilt the function
-- from whatever their author had.
--
-- So this does not shape anything. It FILTERS THE SNAPSHOT that `get_catalog()`
-- already serves, and returns those elements byte for byte. There is no second
-- shaper to drift, by construction rather than by discipline. A key added to
-- the builder tomorrow appears here the same day, with no change to this file.
-- scripts/check-catalog-keys.py fails any file that redefines
-- `get_catalog_since` without calling `catalog_pick`, so it stays that way.
--
-- ⚠️ The snapshot is rebuilt inside the same seed transaction that writes the
-- rows (seed_from_toursjson.py), so a row whose rev has advanced is always
-- already present in the payload. The two cannot disagree.
--
-- ⚠️ STOPS ARE NOT QUERIED HERE, AND THAT IS NOT AN OVERSIGHT.
-- `catalog_rev.sql` puts `rev` on tours, makers and places only, and gives
-- `stops` an AFTER INSERT OR UPDATE OR DELETE trigger that bumps its PARENT
-- TOUR's rev. So a stop edit — including a stop DELETION, which carries no row
-- to hold a rev of its own — already shows up as a change to the tour that
-- owns it. Querying stops here would be redundant, and on a deletion it would
-- be wrong.
--
-- ⚠️ DELETIONS OF WHOLE ROWS ARE NOT TRACKED, deliberately. `removedIds` is
-- always empty. The seed is upsert-only for tours and pins, so a deletion never
-- reaches Postgres from a catalogue edit anyway (CLAUDE.md § Egress).
-- Pretending to track them would be worse than saying so: the client reconciles
-- on a schedule instead (§ 5 of the design doc). A `catalog_tombstones` table
-- is the eventual answer and can wait.

-- Filter one section of the snapshot down to a set of ids, preserving element
-- order and the exact bytes.
--
-- ⚠️ `lower()` on both sides is not defensive noise. CLAUDE.md records that pin
-- ids are UPPERCASE in Tours.json and lowercase out of Postgres, and that a
-- naive comparison "reports every pin as missing". A case mismatch here would
-- not error — it would silently return an empty delta forever, which reads
-- exactly like "nothing changed".
create or replace function public.catalog_pick(section jsonb, ids text[])
returns jsonb
language sql
immutable
as $$
    select coalesce(jsonb_agg(e order by ord), '[]'::jsonb)
      from jsonb_array_elements(coalesce(section, '[]'::jsonb))
           with ordinality as t(e, ord)
     where lower(e->>'id') = any (select lower(unnest(ids)));
$$;

create or replace function public.get_catalog_since(client_rev bigint)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    head       bigint;
    tour_ids   text[];
    pin_ids    text[];
    maker_ids  text[];
    place_ids  text[];
    snap       jsonb;
    stamp      timestamptz;
begin
    if client_rev is null or client_rev < 0 then
        raise exception 'get_catalog_since: client_rev must be >= 0, got %', client_rev;
    end if;

    -- The cursor to store for next time, taken from the ROWS rather than from
    -- `catalog_rev_seq`. The sequence can run ahead of anything actually
    -- written — a rolled-back seed or a bump on a row that was then filtered
    -- out — and a cursor above a real row's rev would skip that row forever.
    select greatest(
        coalesce((select max(rev) from public.tours),  0),
        coalesce((select max(rev) from public.makers), 0),
        coalesce((select max(rev) from public.places), 0)) into head;

    select coalesce(array_agg(t.id::text), '{}') into tour_ids
      from public.tours t
     where t.status = 'published' and t.kind is distinct from 'link'
       and t.rev > client_rev;

    select coalesce(array_agg(t.id::text), '{}') into pin_ids
      from public.tours t
     where t.status = 'published' and t.kind = 'link'
       and t.rev > client_rev;

    select coalesce(array_agg(m.id::text), '{}') into maker_ids
      from public.makers m where m.rev > client_rev;

    select coalesce(array_agg(p.id::text), '{}') into place_ids
      from public.places p where p.rev > client_rev;

    select refreshed_at into stamp from public.catalog_snapshot where id;

    -- 🔴 The common call answers "nothing" and must cost nothing. Returning
    -- here avoids detoasting the ~8 MB payload at all — the single most
    -- expensive thing this function could do, and pointless when no row moved.
    if cardinality(tour_ids) = 0 and cardinality(pin_ids) = 0
       and cardinality(maker_ids) = 0 and cardinality(place_ids) = 0 then
        return jsonb_build_object(
            'rev', head, 'refreshedAt', stamp,
            'tours', '[]'::jsonb, 'linkPins', '[]'::jsonb,
            'makers', '[]'::jsonb, 'places', '[]'::jsonb,
            'removedIds', '[]'::jsonb);
    end if;

    select payload into snap from public.catalog_snapshot where id;
    if snap is null then
        raise exception
            'catalog snapshot missing - apply backend/catalog_snapshot.sql';
    end if;

    return jsonb_build_object(
        'rev',         head,
        'refreshedAt', stamp,
        'tours',       public.catalog_pick(snap->'tours',    tour_ids),
        'linkPins',    public.catalog_pick(snap->'linkPins', pin_ids),
        'makers',      public.catalog_pick(snap->'makers',   maker_ids),
        'places',      public.catalog_pick(snap->'places',   place_ids),
        -- Always empty. See the header — this is stated, not forgotten.
        'removedIds',  '[]'::jsonb);
end $$;

grant execute on function public.get_catalog_since(bigint) to anon, authenticated;
grant execute on function public.catalog_pick(jsonb, text[]) to anon, authenticated;

comment on function public.get_catalog_since(bigint) is
    'Catalog rows whose rev exceeds the client cursor, filtered out of the '
    'snapshot get_catalog() serves so the shaping cannot drift. removedIds is '
    'always empty; see backend/catalog_since.sql.';

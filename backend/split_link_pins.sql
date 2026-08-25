-- split_link_pins.sql
--
-- Migration: serve link pins under their own top-level `linkPins` key instead
-- of inside `tours`.
--
--
-- 🔴 WHY — AN UNKNOWN KEY IS FREE, AN UNKNOWN VALUE IS FATAL
--
-- `ToursData` decodes `tours` as ONE array, and `TourKind` is a closed string
-- enum. So when `kind: "link"` first appeared inside `tours` (four pins, in the
-- live catalogue), every build shipped before `TourKind.link` threw on those
-- elements — and one unreadable element fails the WHOLE array, hence the whole
-- catalogue. `RemoteCatalogLoader` wraps the decode in `try?`, reads the throw
-- as a failed fetch, keeps its last good copy and logs nothing. No crash: the
-- phone simply stops receiving all new content, forever, in silence.
--
-- An unknown top-level KEY costs nothing, because a synthesised `Codable`
-- ignores keys it does not know. That is not theory about this app, it is its
-- history: `add_link_pins.sql` put `sourceURL` and `sourceAuthor` on all 1,513
-- tours and every shipped build carried on; so did `country`, `videoURLs` and
-- `videoRole`; and `places` reached builds that had no `Place` type at all.
-- Nothing has ever broken until a new VALUE appeared in a field builds already
-- parsed.
--
-- So the pins move to a sibling array, and the app merges them back at decode.
-- Old builds read `tours`, find only words they know, and resume receiving
-- every city and every correction — permanently. This is the only change that
-- can rescue a build that is already submitted or already on a phone.
--
-- ⚠️ ACCEPTED COST, already understood by the owner: builds 116 and 117 stop
-- showing the pins until a build reads the new key. One build's lag, once.
--
--
-- 🔴 HOW — PATCH THE CORE, NEVER `create or replace get_catalog()`
--
--     get_catalog()  =  get_catalog_core()  ||  { places: catalog_places() }
--
-- Replacing `get_catalog()` with an inline body severs that call and silently
-- drops every place, price and private account, with NO error. Four files in
-- `backend/` still contain that statement and carry warning banners saying so.
-- This file does not touch `get_catalog()` at all.
--
-- Instead it uses the exact move `places.sql` invented: rename the existing
-- function aside, once, and wrap it. The function that actually emits the tour
-- keys becomes `get_catalog_core_base()` — renamed, so its body, its volatility
-- and its security attribute are all preserved untouched — and the new
-- `get_catalog_core()` calls it and splits its output. `get_catalog()` still
-- says `get_catalog_core() || { places: ... }` and needs no edit; `||` merges
-- at the top level, so the new `linkPins` key rides through beside `places`.
--
-- ⚠️ THE NEW LAYER IS DELIBERATELY **SECURITY INVOKER** (the default — note the
-- absence of `security definer` below). The base is invoker too, so the
-- privilege chain is bit-for-bit what it was: `get_catalog` (definer) → this
-- (transparent) → the base. Making this layer `security definer` would change
-- who RLS evaluates the base as, which is how anon could start seeing
-- unpublished tours. Do not "tidy" that in.
--
-- ⚠️ FOR THE NEXT MIGRATION THAT ADDS A CATALOG KEY: the function holding the
-- tour keys is now **`get_catalog_core_base`**. `add_video_role.sql` is still
-- the worked example for how to patch it — read `pg_get_functiondef`, insert
-- your key, `execute` it back, raise if the anchor is missing — but its finder
-- searches `proname in ('get_catalog_core', 'get_catalog')`, so add
-- `'get_catalog_core_base'` to that list. It fails closed if you forget (it
-- raises rather than guessing), which is the failure mode we want.
--
--
-- Storage does NOT change. A link pin is still an ordinary row in
-- `public.tours` with `kind = 'link'` (`add_link_pin_kind.sql` widened the
-- enum), and `seed_from_toursjson.py` still writes it there — it folds
-- `linkPins` back into `tours` on load. The split is a wire-format concern and
-- lives only in this function.
--
-- Safe to re-run: the rename is guarded, the function is `create or replace`,
-- and the verification block at the bottom asserts the result rather than
-- trusting it. Run once in the Supabase SQL Editor (project "Dozent").
-- Expect "Success. No rows returned."
--
-- Afterwards, prove it against the live RPC rather than the success message:
--     python3 scripts/check-catalog-keys.py

begin;

-- ---------------------------------------------------------------------------
-- 1. Rename the current core aside, exactly once.
-- ---------------------------------------------------------------------------
do $rename$
begin
    if exists (
        select 1 from pg_proc
        where proname = 'get_catalog_core_base'
          and pronamespace = 'public'::regnamespace
    ) then
        raise notice 'get_catalog_core_base already exists — skipping the rename.';
        return;
    end if;

    if not exists (
        select 1 from pg_proc
        where proname = 'get_catalog_core'
          and pronamespace = 'public'::regnamespace
    ) then
        raise exception
            'public.get_catalog_core() does not exist, so there is nothing to wrap. '
            'This database has not had backend/places.sql applied — apply it first, '
            'then re-run this file.';
    end if;

    alter function public.get_catalog_core() rename to get_catalog_core_base;
    raise notice 'renamed get_catalog_core -> get_catalog_core_base';
end
$rename$;

-- ---------------------------------------------------------------------------
-- 2. The new core: whatever the base returned, with link pins lifted out of
--    `tours` into their own key. Every other key passes through untouched,
--    because we only ever remove and re-add `tours`.
-- ---------------------------------------------------------------------------
create or replace function public.get_catalog_core()
returns jsonb
language plpgsql
stable
set search_path = public
as $$
declare
    base jsonb;
    rest jsonb;
    pins jsonb;
begin
    base := public.get_catalog_core_base();

    -- Fail loudly rather than serving a catalogue that reads as empty. An
    -- error here makes the RPC fail, and the app falls through to the gh-pages
    -- mirror — which carries the same split shape. Emitting `tours: []` would
    -- instead look like a successful fetch of an empty world.
    if jsonb_typeof(base -> 'tours') is distinct from 'array' then
        raise exception
            'get_catalog_core_base() returned no tours array — refusing to serve it. '
            'Inspect: select pg_get_functiondef(''public.get_catalog_core_base()''::regprocedure);';
    end if;

    -- `with ordinality` + `order by` so catalogue order is preserved by
    -- contract rather than by luck.
    select
        coalesce(jsonb_agg(e.t order by e.ord) filter (where e.t ->> 'kind' is distinct from 'link'), '[]'::jsonb),
        coalesce(jsonb_agg(e.t order by e.ord) filter (where e.t ->> 'kind' = 'link'),                '[]'::jsonb)
      into rest, pins
      from jsonb_array_elements(base -> 'tours') with ordinality as e(t, ord);

    return (base - 'tours')
         || jsonb_build_object('tours', rest, 'linkPins', pins);
end
$$;

grant execute on function public.get_catalog_core() to anon, authenticated;
grant execute on function public.get_catalog_core_base() to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Prove it, rather than trusting that it took. Any raise here rolls the
--    whole migration back.
--
--    The place, price and privacy assertions are not decoration: a severed
--    composition raises no error at all, and those keys vanishing is the only
--    evidence it happened. `backend/test-migrations.sh` is built around the
--    same idea.
-- ---------------------------------------------------------------------------
do $verify$
declare
    cat       jsonb;
    n_tours   int;
    n_pins    int;
    n_makers  int;
    n_places  int;
    n_stray   int;
begin
    cat := public.get_catalog();

    n_tours  := coalesce(jsonb_array_length(cat -> 'tours'), -1);
    n_pins   := coalesce(jsonb_array_length(cat -> 'linkPins'), -1);
    n_makers := coalesce(jsonb_array_length(cat -> 'makers'), -1);
    n_places := coalesce(jsonb_array_length(cat -> 'places'), -1);

    if n_pins < 0 then
        raise exception 'get_catalog() does not emit linkPins — the wrapper did not take.';
    end if;
    if n_places < 0 then
        raise exception
            'get_catalog() no longer emits places — the composition has been severed.';
    end if;
    if n_makers <= 0 or n_tours <= 0 then
        raise exception
            'get_catalog() returned % makers / % tours — refusing to leave that live.',
            n_makers, n_tours;
    end if;

    select count(*) into n_stray
      from jsonb_array_elements(cat -> 'tours') t
     where t ->> 'kind' = 'link';
    if n_stray > 0 then
        raise exception
            '% link pin(s) are still inside tours after the split — the whole point '
            'of this migration is that older builds never see one there.', n_stray;
    end if;

    -- The two keys a wholesale replacement drops first, and which nothing else
    -- here would notice.
    if not exists (select 1 from jsonb_array_elements(cat -> 'tours') t where t ? 'priceTier') then
        raise exception 'get_catalog() no longer emits priceTier.';
    end if;
    if not exists (select 1 from jsonb_array_elements(cat -> 'makers') m where m ? 'isPrivate') then
        raise exception 'get_catalog() no longer emits isPrivate.';
    end if;

    raise notice 'get_catalog(): % makers / % tours / % linkPins / % places',
        n_makers, n_tours, n_pins, n_places;
end
$verify$;

commit;

-- Verify afterwards, in a separate query (and see check-catalog-keys.py):
--
--   select jsonb_array_length(get_catalog() -> 'tours');     -- 1512, no pins
--   select jsonb_array_length(get_catalog() -> 'linkPins');  -- 4
--   select jsonb_array_length(get_catalog() -> 'places');    -- 25
--   select jsonb_array_length(get_catalog() -> 'makers');    -- 37

-- =================================================================
-- STOP SENDING THE NARRATION SCRIPTS IN THE CATALOGUE
--
-- 🔴 THIS FILE HAD A DESTRUCTIVE FIRST VERSION. READ THIS BEFORE EDITING IT.
--
-- The first version rebuilt `get_catalog_core()` from the body in
-- `restore_catalog_keys.sql` (2026-08-29) minus one key. That body is the
-- OLD one: `split_link_pins.sql` had since renamed the builder aside to
-- `get_catalog_core_base()` and made `get_catalog_core()` a WRAPPER that
-- lifts link pins out of `tours` into their own `linkPins` key.
--
-- So pasting it silently reverted the link-pin split: the live catalogue went
-- from `tours 1553 / linkPins 1700` to `tours 3253 / linkPins 0`, which fails
-- the WHOLE catalog decode on every build predating `TourKind.link` — the
-- exact failure `split_link_pins.sql` exists to prevent. Caught within a
-- minute by counting the live payload, and repaired by this version.
--
-- THE LESSON, which is now enforced in scripts/check-catalog-keys.py:
-- 🔴 NEVER REBUILD A CATALOGUE FUNCTION FROM A COMMITTED FILE. Committed SQL
-- is a record of what was true when it was written, not of what is live. A
-- later migration may have renamed the thing underneath it. **Transform what
-- the live chain returns; do not retype it.** That is what this version does:
-- it wraps, it does not rewrite, so it cannot lose a key it never mentions.
--
-- =================================================================
-- WHY (plain English): every time a phone asks for the tour list, the
-- database sends the full written script of every stop's narration — 1,924 of
-- them, 3.8 million characters. Nothing in the app has ever shown them.
--
-- Measured on the LIVE payload, 2026-09-10:
--     before   3,698,842 wire bytes
--     after    2,167,209 wire bytes      = 41.4% saved, every fetch, forever
--
-- 🔴 NOTHING IS DELETED. `stops.transcript_text` keeps every character; this
-- only stops it being SENT. The maker edit path reads and writes it directly
-- against the `stops` table (MakerTourService.swift), untouched.
--
-- SAFE FOR PHONES ALREADY IN THE FIELD, which is why it needs no App Store
-- release: `Stop.transcriptText` is `String?`, so an absent key decodes as nil
-- on every build ever shipped. And no consumer screen reads it — grep-verified
-- across the app: only Models/Stop.swift (the declaration), MakerTourService,
-- TourWizardRules and CreateTourWizardView, all maker-side.
--
-- ⚠️ `longDescription` was considered in the same pass and DELIBERATELY KEPT:
-- 8.2% of the billed bytes once compressed (the "18%" in older notes is a RAW
-- figure, which is not what is billed), and it IS used — TourDetailView
-- renders it, SearchView searches it.
--
-- =================================================================
-- HOW TO RUN: paste the whole file into the Supabase SQL Editor, press Run.
-- Idempotent. ⚠️ The `refresh_catalog_snapshot()` at the end is load-bearing —
-- `get_catalog()` serves a stored snapshot, so without it this changes nothing
-- a phone can see while reporting success.
--
-- VERIFY AFTERWARDS — the final block does it for you and raises rather than
-- letting a bad shape through. Then, from a checkout:
--     python3 scripts/check-catalog-keys.py
--     python3 scripts/check-catalog-contract.py
-- =================================================================

-- `get_catalog_core()` — the link-pin splitter from split_link_pins.sql,
-- unchanged except that transcripts are dropped from each stop on the way
-- through. Every other key rides along untouched because this only ever
-- rebuilds `tours`/`linkPins`; it never enumerates tour or stop keys, so it
-- cannot lose one.
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
    -- error makes the RPC fail and the app falls through to the gh-pages
    -- mirror, which carries the same shape. `tours: []` would instead look
    -- like a successful fetch of an empty world.
    if jsonb_typeof(base -> 'tours') is distinct from 'array' then
        raise exception
            'get_catalog_core_base() returned no tours array — refusing to serve it. '
            'Inspect: select pg_get_functiondef(''public.get_catalog_core_base()''::regprocedure);';
    end if;

    -- `with ordinality` + `order by` so catalogue order — and stop order
    -- inside each tour, which is the walking route — is preserved by contract
    -- rather than by luck.
    select
        coalesce(jsonb_agg(x.t order by x.ord) filter (where x.t ->> 'kind' is distinct from 'link'), '[]'::jsonb),
        coalesce(jsonb_agg(x.t order by x.ord) filter (where x.t ->> 'kind' = 'link'),                '[]'::jsonb)
      into rest, pins
      from (
        select
            e.ord,
            case when jsonb_typeof(e.t -> 'stops') = 'array' then
                jsonb_set(e.t, '{stops}', (
                    select coalesce(jsonb_agg(q.s - 'transcriptText' order by q.so), '[]'::jsonb)
                      from jsonb_array_elements(e.t -> 'stops') with ordinality as q(s, so)
                ))
            else e.t end as t
          from jsonb_array_elements(base -> 'tours') with ordinality as e(t, ord)
      ) x;

    return (base - 'tours')
         || jsonb_build_object('tours', rest, 'linkPins', pins);
end
$$;

grant execute on function public.get_catalog_core() to anon, authenticated;

-- 🔴 Without this the change is invisible to every phone.
select public.refresh_catalog_snapshot();

-- Verify the SHAPE, not just that it ran. This is the check whose absence let
-- the first version of this file ship a reverted link-pin split.
do $$
declare
    cat        jsonb := public.get_catalog();
    n_tours    int;
    n_pins     int;
    n_places   int;
    n_stray    int;
    n_scripts  int;
begin
    n_tours  := coalesce(jsonb_array_length(cat -> 'tours'), -1);
    n_pins   := coalesce(jsonb_array_length(cat -> 'linkPins'), -1);
    n_places := coalesce(jsonb_array_length(cat -> 'places'), -1);

    select count(*) into n_stray
      from jsonb_array_elements(cat -> 'tours') e
     where e ->> 'kind' = 'link';

    select count(*) into n_scripts
      from jsonb_array_elements(cat -> 'tours') t,
           jsonb_array_elements(t -> 'stops')   s
     where s ? 'transcriptText';

    if n_pins <= 0 then
        raise exception 'linkPins is empty (%) — the split did NOT take. Do not leave it like this.', n_pins;
    end if;
    if n_stray > 0 then
        raise exception '% link pin(s) are still inside tours — every build predating TourKind.link will fail the whole decode.', n_stray;
    end if;
    if n_places <= 0 then
        raise exception 'places is empty — the wrapper has been severed.';
    end if;
    if n_scripts > 0 then
        raise exception '% stop(s) still carry transcriptText — the saving did not apply.', n_scripts;
    end if;

    raise notice 'OK — % tours / % linkPins / % places, 0 strays, 0 transcripts.',
                 n_tours, n_pins, n_places;
end $$;

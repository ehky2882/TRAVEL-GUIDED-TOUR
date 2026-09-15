# Handoff — 2026-09-15: delta catalogue fetching, Phases 0→2

**What shipped:** `get_catalog_since(rev)` is **live on production**, and the client that
consumes it is built and tested on device. The catalogue no longer has to be sent whole.

| | |
|---|---:|
| full catalogue (what every phone downloads today) | **2,427,222 B** |
| a real delta — 43 changed rows | **19,496 B** — 124× smaller |
| nothing changed | **131 B** — ~19,000× smaller |

🔴 **No phone has any of this yet.** Phase 2 (#914) ships with 1.1.3. Until then the egress bill
is exactly what it was.

---

## What was done

| | |
|---|---|
| **Phase 0** | shipped by a *parallel* session as #904 while this one built its own. Theirs merged; **this session's duplicate on `claude/scale-pinned-tours-automation-dba3lx` must never be merged** |
| **Phase 1** | `backend/catalog_since.sql` + `backend/test-catalog-since.sh` → **#912**, merged, and pasted into the Supabase SQL Editor by the owner |
| **Phase 2** | `Data/CatalogDeltaMerge.swift`, `RemoteCatalogLoader` changes, 24 unit tests → **#914**, merged `24903b8` |
| **Board** | **#916**, merged |

### The design decision worth keeping

`CatalogDeltaMerge` merges **raw JSON, not `ToursData`.** Decoding and re-encoding would write
only the four keys `ToursData.encode` knows and the properties `Tour` declares — so **any key this
build does not model would be deleted from the cache by the first merge.** In a repo whose
recurring failure is a key quietly vanishing (2026-08-19: `places`, `priceTier`, `isPrivate`, 14
hours), that is not a trade worth making for tidier code. `testKeysThisBuildDoesNotModelSurvive`
fails if it ever stops being true.

The same principle held on the server: `get_catalog_since` **filters the existing snapshot** rather
than shaping rows itself. Confirmed on production data — a delta pin comes back with 24 keys and
**`stops[].transcriptText` absent**, although nothing in the SQL excludes it. It is absent because
the snapshot dropped it in #795. One shaper, so a field removed months ago cannot reappear through
a second code path.

### Two claims of mine that were wrong, and how

🔴 **A stop-reorder crash I reported as a production bug did not exist.** I claimed #904's guarded
`stops` upsert would hit `unique (tour_id, "order")` on a reorder, and filed it as an owner item.
It came from a failure in **my own test harness**, not the repo's. `backend/test-seed-idempotence.sh`
passes on main's byte-identical generator, including a reversal case I added to try to catch it.
Retracted, owner item deleted, no PR opened. **Run a claim through the test the repo already has
before reporting it.**

⚠️ **I told the owner a device test would exercise the uppercase/lowercase id trap. It cannot.**
The app's catalogue comes from Supabase, lowercase on both sides, and a gh-pages download clears
the cursor (`RemoteCatalogLoader.headRev` returns nil with no delta fetcher), so a mirror-built
cache — where `Tours.json`'s UPPERCASE pin ids live — can never be delta-merged. Said before
checking; corrected to the owner unprompted.

⚠️ **And the first device test proved less than it appeared to.** 3,901 held across five cold
launches — but head `rev` never moved, so every launch was told nothing had changed and *skipped*
the download. The merge never ran. It took a deliberate `rev` bump (plus #917 landing 37 corrected
coordinates in the same window) to produce a delta worth merging. **A green result from a test that
could not have failed is not a result.**

### Two corrections to the project record, both verified

1. **The live database IS reachable from a web session** — the anon key in `SupabaseConfig.swift`
   is publishable by design. Earlier handoffs saying otherwise are wrong.
2. **PostgreSQL installs in this container** (`apt-get install -y postgresql`), so
   `backend/test-migrations.sh` and the seed tests run here. SQL work does not need a Mac.

### Traps met along the way

- **`grep -m1 MARKETING_VERSION project.pbxproj` reads the TESTS target** and returns `1.0`. The
  app target was 1.1.3 all along. Match on `PRODUCT_BUNDLE_IDENTIFIER` before believing a version.
- **`INSERT … ON CONFLICT` burns sequence values for rows it does not write**, so
  `catalog_rev_seq` advances ~4,700 per seed while only the genuinely-changed rows carry a new
  `rev`. Gaps in `rev` are normal; do not read them as lost writes.
- **A 16-minute CI job was runner contention**, not a hang — a parallel session pushed five commits
  in ten minutes and saturated the macOS pool.
- **`updated_at` cannot bump `rev`** — `catalog_bump_rev()` excludes it deliberately. To force a
  delta with zero content change, set `rev = nextval('public.catalog_rev_seq')` directly (the
  trigger declines, so the explicit value stands) and then `refresh_catalog_snapshot()`.

## Still open

- ~~**#914**~~ — **MERGED** (`24903b8`) on a 3,901 device reading, confirmed by the owner.
- **Phase 3, removals** — `removedIds` is always empty, so a *deletion* still needs a full
  download. Compounds the upsert-only deletion gap: `seed_from_toursjson.py` never deletes.
- **First-sync cost** — a new install still pulls 2.4 MB. City-scoped fetching, not delta, is the
  answer to that, and it is unbuilt.

---

# Second half of the day: the place spine, and the first pin audit

The owner asked what remained to build **before approaching content creators**. Re-derived rather
than quoted, the answer was the place spine — so step 1 of it got built, and it immediately
contradicted the spec written an hour earlier.

## #924 — `scripts/spine-build.py`

**Three measurements changed the design:**

1. **The data source had to change.** The spec said Geofabrik `.osm.pbf`. From a web session
   `download.geofabrik.de` returns **http=000** and Overpass is blocked too (as #913 recorded).
   `query.wikidata.org` answers. Wikidata is a smaller universe than OSM but it is the one that is
   **reachable** — a different claim from better.
2. 🔴 **Admin containment undercounts 49×.** "Things whose `P131*` chain reaches this city" gives
   London **557**; `wikibase:around` at 15 km gives **27,295**. Cities model hierarchies
   differently, so containment returns a plausible-looking wrong number and a spine built on it
   would have left London near-empty **with nothing downstream to flag it**. The selftest now
   asserts `P131*` is absent from the query.
3. 🔴 **The match rate splits by CREATOR, not by city.** Harvested Tokyo (1,204 features) and
   midtown Manhattan (4,244) and matched against all 415 catalogue pins inside those boxes:

   | creator | rate |
   |---|---:|
   | `@archimarathon` · `@archiwhisperer` (architecture) | **83%** · **78%** |
   | `@hereinnyc` · `@urbanistariel` (urbanism) | **59%** · **54%** |
   | `@japanbyfood` · `@nom_life` (food) | **25%** · **14%** |

   Wikidata knows buildings, not restaurants. **It lands where the volume is** — the two deepest
   creators in the catalogue, `@urbanistariel` (326 pins) and `@hereinnyc` (262), are exactly the
   urbanism profile. **The design therefore gets a routing rule, not one geocoder:** spine for
   architecture/urbanism creators, `parse-caption-address.py` + GSI for food and retail.

⚠️ **The incompleteness guard earned its place on first use.** The first Manhattan harvest used
4 km tiles, hit one WDQS timeout, printed **COULD NOT VERIFY** and exited 2 — and had found **640
fewer** features than the complete 2 km run. A partial harvest reporting success would have
silently understated coverage.

## #927 — `check-coordinates.py --pins`

**The 2,318 link pins had never been machine-audited as a set.** The existing Nominatim path could
not do it: `from_catalog` reads `d["tours"]` and matches `Atlas Studio {CODE}`, so **no pin can
ever match it**. So `--pins` asks a different question offline — *is this point inconsistent with
its own neighbours and its own stated city* — and runs over every pin in about a second.

**CITY-OUTLIER: 0.** No pin is in the wrong city; #913/#917/#920's Tokyo precision work closed that
class entirely.

## #930 — 26 owner-approved coordinate fixes

| | before | after |
|---|---:|---:|
| LOW-PRECISION | 36 | **13** |
| SHARED-POINT | 11 | **6** |
| any flag | 42 (1.8%) | **19 (0.8%)** |

One targeted Wikidata radius query per pin, matched on the **place name** where the pin has one.
34 entries moved, not 26: **a place IS a coordinate**, so moving one moves all its members — the
extra 8 are Atlas studio tours that sat on the same coarse point. 9 places moved.

---

## 🔴 What this half cost, and the rules it bought

**1. Two retractions in one afternoon, both from checks I wrote myself.**
The stop-reorder crash (above), and **"~32 link pins are invisible on the map"** — false: 18 of the
19 oversized coordinate groups were **already collapsed into place pages**, and the real residue
was **2 pins**. I had counted raw coordinate groups without checking the mechanism built to solve
them. A follow-up check then looked for a `placeId` field on pins **which does not exist**
(membership is `place.tourIds`) and nearly produced the opposite wrong answer.

> **A finding that contradicts a mechanism the repo already built is probably wrong about the
> mechanism.**

The same error appeared a third time inside `--pins` itself: the first version flagged **210 pins**
as SHARED-POINT, almost all correctly placed. Teaching it about `place.tourIds` took it to **11**.

**2. Proximity is not a match.** Six candidates were refused for landing on the wrong building:

| pin | matched | |
|---|---|---|
| The Tomb of Elizabeth I | Queen Elizabeth **Hall** | a concert venue 1.1 km away |
| Hotel Siro | Hotel Resol **Ikebukuro** | different hotel |
| The Bellwood / Gyukatsu Ichi Ni San | **"Shibuya"** / **"Akihabara"** | bare district names |

Pin titles are **editorial** — *"The Security Council Chamber"* — so there is nothing for a matcher
to grab. **The place name is the signal that works.**

**3. Stop at the cheap check when it is conclusive.** A 407-byte column select answered "did the
migration reach production"; a redundant second confirmation through `get_catalog_since` cost
**2.75 MB** in a session whose subject is egress. Recorded in `docs/lessons.md`.

**4. A miscount in my own summary.** I asked the owner to approve "the 24 confident ones" from a
list that held **26**. Caught before applying; what landed is exactly what they read.

**5. A find-and-replace clobbered an existing function.** Patching `--pins` in, a
`total = len(rows)` replacement matched the drop/maker `report()` instead of `report_pins()`.
Repaired, and verified by `git diff --stat` reading **193 insertions, 0 deletions**. A string
replace that does not name its target function is a loaded gun in a 568-line file.

---

## Still open

- **13 low-precision pins** remain, and they are the ones no gazetteer can fix — Hotel Siro,
  Gyukatsu Ichi Ni San, The Bellwood: venues Wikidata has never heard of. Route:
  `parse-caption-address.py` + GSI, or the owner.
- **East Side Gallery** (moves 420 m along a ~1.3 km wall) and **Fíkovna** (matched a generic entry
  named *"orangery"*) await an owner decision.
- **Phase 3 of the delta work — removals — is not built.**
- 🔴 **1.1.3 is not released.** Nothing from the delta work reaches a phone until it is.
- **The spine covers two cities.** Widening it, and wiring `--spine-id` into `make-link-pin.py`,
  are the next steps in `docs/place-spine-design.md`.

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
| **Phase 2** | `Data/CatalogDeltaMerge.swift`, `RemoteCatalogLoader` changes, 24 unit tests → **#914** |
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

- **#914** — merges on a 3,901 device reading. Not merged as of this writing.
- **Phase 3, removals** — `removedIds` is always empty, so a *deletion* still needs a full
  download. Compounds the upsert-only deletion gap: `seed_from_toursjson.py` never deletes.
- **First-sync cost** — a new install still pulls 2.4 MB. City-scoped fetching, not delta, is the
  answer to that, and it is unbuilt.

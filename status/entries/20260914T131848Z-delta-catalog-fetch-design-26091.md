# Scoped delta/incremental catalogue fetching (design doc, no code)

_2026-09-14 13:18 UTC · branch `delta-catalog-fetch-design-26091`_

Scoping only — no app code, no migration. `docs/delta-catalog-fetch-design.md`.

**The headline, and it contradicts `CLAUDE.md`:** `longDescription` is **43.9%
of the compressed payload**, not the 8.2% recorded in `CLAUDE.md` § Egress.
Confirmed by two independent methods and at three gzip levels. It is still not
droppable (it is non-optional in `Models/Tour.swift`, so removing it would
empty the catalogue on every phone in the field), but the 8.2% line should be
corrected before someone decides something on it.

**Measured live 2026-09-14 13:10 UTC:** the payload is **2,427,222 bytes**
compressed — **+6.6% since the 2,276,264 recorded on 12 September**, roughly
3% a day. PostgREST compresses at **gzip level 1**, so Python's default level 9
understates the bill ~15% and mis-ranks text fields.

**The case for delta fetching, measured:** replaying the last 30 content
commits, the **median change is 7,019 bytes gzipped — 0.29%** of what we send
to deliver it. `Tours.json` changed on **28 of the last 30 days**, across 156
commits (~5.2/day), which is why the shipped version check saves little for a
once-a-day user: there is nearly always something new, and something new costs
the whole catalogue.

**Blocker found:** `seed_from_toursjson.py` sets `updated_at = now()`
**unconditionally** on every tour, maker and place, so every row looks changed
after every seed — a cursor on `updated_at` would return everything today.
`stops` has no `updated_at` at all and is deleted/re-inserted per tour on every
run. Fixing that is Phase 0, needs no app release, and independently removes
~3,674 row rewrites × 5.2 seeds a day from the instance that ran out of memory
last night.

**Recommendation:** four phases; Phase 0 (half a day, database only, touches no
phone) first. ~4 days of work to the point the bill falls, plus an App Review
cycle and install-base migration before the daily figure actually moves.

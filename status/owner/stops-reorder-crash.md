# Phase 0 on main crashes the seed on any stop reorder (reproduced)

_opened 2026-09-15 · clear with `git rm status/owner/stops-reorder-crash.md`_

🔴 **The Phase 0 on `main` (#904, already applied to production) will CRASH the
seed the first time anyone reorders the stops of a multi-stop tour.**

**Reproduced, not theorised.** `main`'s `seed_from_toursjson.py:396` deletes stops
with `where tour_id = … and id not in (…)`. `public.stops` has
`unique (tour_id, "order")` (`schema.sql:116`). Deleting every stop first — what
the code did before #904 — made reordering trivially safe because nothing was
left to collide with. Deleting only by **id** keeps the old rows, so setting the
first stop's order hits the second stop's row before the second has moved:

```
ERROR:  duplicate key value violates unique constraint "stops_tour_id_order_key"
```

**Why this matters more than it looks:** the seed is ONE transaction with
`ON_ERROR_STOP=1`. A failure rolls the whole thing back, so **that content merge
delivers nothing at all** — not just the reordered tour. Content silently stops
reaching the app until someone diagnoses it.

⚠️ **It is invisible until it fires.** #904 passes an idempotence test perfectly
(an unchanged re-seed writes zero rows — verified). Only a *reorder* triggers it,
and reorders are rare, so this can sit dormant for weeks.

**The fix is one line and needs no migration:** delete by the **`(id, "order")`
pair** rather than by `id`. Every row whose pair is not one about to be written
is removed first, so the survivors already hold their final order under their
final id and no insert can collide. A reorder just deletes both rows and
re-inserts them.

Working fix + a regression test that catches it are on
`claude/scale-pinned-tours-automation-dba3lx` (`backend/test-seed.sh`, phase 2).
**Only you can decide whether to take it as a small PR against `main`** — the rest
of that branch duplicates #904 and should NOT be merged.

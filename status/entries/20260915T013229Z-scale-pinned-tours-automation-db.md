# Phase 0 duplicated #904 — and #904 crashes the seed on any stop reorder (reproduced)

_2026-09-15 01:32 UTC · branch `scale-pinned-tours-automation-db`_

🔴 **This session duplicated Phase 0.** Another session shipped it as **#904**
while this one was building it; `main` also carries **#908** (board) and **#909**
(1.1.3 bump). My four Phase 0 commits are **NOT on main and should not be merged
as they are** — they overlap #904.

🔴 **But #904 has a reproduced bug, and it is live.** `main`'s
`seed_from_toursjson.py:396` deletes stops by **id only**, so any **stop reorder**
hits `unique (tour_id, "order")`:
`ERROR: duplicate key value violates unique constraint "stops_tour_id_order_key"`.
The seed is one transaction with `ON_ERROR_STOP=1`, so **that whole content merge
delivers nothing**. Logged as `status/owner/stops-reorder-crash.md`.
⚠️ **#904 passes an idempotence test perfectly** — only a reorder fires it.

**What is worth taking from this branch (not the whole thing):**
1. **The `(id, "order")` stops delete** — the fix, no migration needed.
2. **`backend/test-seed.sh` phase 2** — mutation test (reorder / removal / edit)
   that catches it. Verified to FAIL on both #904's generator and a naive variant.
3. **Conditional snapshot refresh** — #904 still rebuilds and moves `refreshed_at`
   on an unchanged seed, telling every phone to re-download 2.4 MB for nothing.
4. **`backend/catalog_since.sql`** — Phase 1, new work, needs rebasing on #904.

**Phase 1 is built and tested** (`backend/test-catalog-since.sh`): delta is
**139 bytes** when nothing changed, **1,952** for a 3-row change, and **every delta
row is byte-identical to `get_catalog()`'s** across all four sections. It achieves
that by **filtering the snapshot rather than shaping rows**, so the "one shaper,
not two" constraint holds *by construction* — `backend/README.md` says no file
here matches what is running, so a hand-written shaper could not have been
written correctly anyway. `check-catalog-keys.py` now fails any file redefining
`get_catalog_since` without calling `catalog_pick`; its audit window was widened
from 900 chars to the end of the function (a plpgsql declare block pushed the
real call past it), **selftest still 14/14**.

⚠️ **CORRECTION to earlier sessions' claims, including mine: the live database IS
reachable from a web session** via the anon key in `SupabaseConfig.swift`.
Verified: `catalog_snapshot_age` = 2026-09-14T20:25:43Z, `tours.rev` present with
real values, `get_catalog_since` → 404 (not deployed). **`check-catalog-contract.py`
pulls the full 2.4 MB catalogue — do not run it casually.**

⚠️ **PostgreSQL installs in a web session** (`apt-get install -y postgresql`), so
`backend/test-migrations.sh` and the new tests all run here. Earlier handoffs
saying a Mac is needed for SQL work are wrong.

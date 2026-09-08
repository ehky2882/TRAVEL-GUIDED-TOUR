# HANDOFF 2026-09-06 — the catalog RPC is failing a third of the time; materialise it

**Session 146 (continued) — backend.** Owner asked whether the tours were live. They are — but
checking it against the live systems rather than assuming turned up a real, standing fault in the
**primary** catalog source, which this change fixes.

Branch: the designated `claude/new-tour-links-lze4ab`, restarted off `main` (its PR #737 is merged,
and a merged PR is finished). **No Swift, no `Tours.json`, no gh-pages push, no build.**

---

## What was found, measured rather than inferred

`get_catalog()` — the RPC the app reads **first** — returns `500 / 57014 canceling statement due to
statement timeout`. Sampled 12 times at 10-second intervals, long after any seed:

```
OK 4.1s · OK 2.2s · OK 3.0s · OK 2.2s · OK 3.1s · OK 2.6s
FAIL 5.0s · FAIL 3.7s · OK 4.9s · OK 2.6s · FAIL 4.6s · FAIL 3.5s      → 8 ok / 4 fail
```

**33% failure rate.** Successes 2.2–4.9s, failures 3.5–5.0s — the query is not hitting a wall, it is
sitting **on** the anon role's statement timeout, so ordinary variance decides each call.

⚠️ **My first two readings were each one sample of a flapping signal** — reported first as "down",
then as "recovered". Neither was right. **Sample a flapping endpoint before characterising it.**

🔴 **AND A LATER 8-SAMPLE WINDOW CAME BACK 8/8 CLEAN — THAT IS NOT A CONTRADICTION, AND A FUTURE
READER WILL THINK IT IS.** Re-sampled at 13:15 while this PR's CI ran: **8 ok / 0 fail**, latencies
**2.2–4.9s** — *the identical band as the failing run*. Nothing improved; the query still sits on
the timeout and simply did not cross it in eight tries. **A clean window is the expected behaviour
of a 33%-failure endpoint** (0.67⁸ ≈ 4%, so it is uncommon but unremarkable), and it is exactly the
reading that would tempt someone to close this as "cannot reproduce". **The latency band, not the
pass/fail count, is what says whether this is fixed** — after the migration it should be a
sub-second lookup, and anything still measured in seconds means the snapshot is not being served.

**The database is healthy** — light reads on `tours` / `places` / `makers` return 200 in 0.25–0.9s.
It is `get_catalog` specifically.

### Why it is slow

- The builder nests each tour's stops with a **correlated subquery per tour** — ~2,830 index scans
  into `stops` plus ~2,830 separate `jsonb_agg`s, then one outer `jsonb_agg` with an ORDER BY.
- `split_link_pins.sql` then **explodes that finished ~11 MB blob back into rows** with
  `jsonb_array_elements` and **re-aggregates it twice** (`FILTER` for tours, again for pins).
- `places.sql` merges `catalog_places()` on top.

So the ~11 MB structure is materialised three or four times **per request**.

### 🔴 And the payload is identical for every caller

Verified, not assumed: the builder filters `where t.status = 'published'` explicitly (schema.sql
:288), `catalog_places()` filters to places with ≥2 published tours, `makers` is public-read.
Nothing varies by viewer. It changes only when the catalog is seeded — a few times a day — and we
rebuild it from scratch thousands of times a day.

⚠️ **The gh-pages mirror is already the materialised version, and it beats the "primary" source**:
same JSON, pre-built, **HTTP 200 in 0.9s, every time.**

---

## The fix — `backend/catalog_snapshot.sql`

| | |
|---|---|
| `get_catalog()` | renamed to **`get_catalog_built()`** (unchanged) |
| `get_catalog()` | **NEW** — `select payload from catalog_snapshot` |
| `catalog_snapshot` | **NEW** — exactly one row, holding the built payload |
| `refresh_catalog_snapshot()` | **NEW** — rebuilds that row |
| `catalog_snapshot_age()` | **NEW** — when it was last refreshed |

**The whole existing chain is kept wholesale** and becomes the builder, called once per seed instead
of once per request. Every migration that patches `get_catalog_core` keeps working untouched — this
follows the `places.sql` rename-and-wrap precedent rather than replacing anything.

Reads become a primary-key lookup. An 11 MB jsonb lives out-of-line in TOAST, compressed, so
fetching it is a sequential chunk read plus decompression — no scans, no sorts, no aggregation.
Latency stops scaling with catalogue size and becomes pure transfer, which the mirror already proves
at 0.9s.

### 🔴 It also fixes a torn read, which is the better argument

Today a client landing mid-seed can be served a **partially updated catalogue**. Observed live at
03:52 on 2026-09-06: the RPC returned **`tours` 1553 (new) alongside `places` 121 (old)**. The
builder is `stable`, so it is consistent *within* one statement — but the seed commits progressively
across many. With a single-row snapshot refreshed as the seed's last act, MVCC keeps every reader on
the previous **complete** catalogue until commit, then moves them to the new complete one. Never a
blend. It also ends the read-vs-seed contention behind the clustered failures.

### ⚠️ Two design points that are forced, not preferences

- **`refresh_catalog_snapshot()` is SECURITY INVOKER.** Postgres refuses outright: *"cannot set
  parameter `role` within security-definer function"*. The role switch and definer are mutually
  exclusive, and the switch is worth more. **Found by running it, not by reading.**
- **The builder runs as `anon`.** Materialising means one role builds the payload and everyone is
  served it, so the build role decides what the world can see. Building as `anon` makes the snapshot
  exactly what an anonymous reader gets today — **narrower than or equal to** any signed-in caller's
  view, never wider. That is the safe direction.

### ⚠️ Deliberate non-choices

- **No trigger on `tours`.** The instinct is wrong: it would rebuild 11 MB per row written, ~2,830
  times per seed. Refresh once, at the end.
- **No fallback to the builder on a missing snapshot.** A `coalesce()` onto `get_catalog_built()`
  would silently reintroduce the slow path and hide a broken refresh. The migration populates the
  snapshot and asserts it before committing; `check-catalog-keys.py` is the standing guard.

---

## Verification

- **`backend/test-migrations.sh` — 4 migrations applied, idempotent, all catalog keys and places
  intact**, against a real throwaway Postgres 16 cluster.
- 🔴 **6 faults injected, 6/6 caught, control clean before and after**: the refresh silently
  stopping; the builder running as the caller instead of `anon`; `get_catalog()` going back to
  building live; the single-row constraint dropped; `anon` given direct table access; the builder
  deleted rather than renamed aside. **The anchor for each mutation is asserted to appear exactly
  once** — a fault that fails to apply is a false pass.
- The two assertions that matter most were checked individually rather than trusted because the run
  went red: **`UNPUBLISHED CONTENT LEAKED into the snapshot`** and **`anon can read
  catalog_snapshot DIRECTLY`** both fire on their own faults.
- ⚠️ **A negative control was added for the leak test**: built as the table owner the draft *does*
  come through, so that assertion is testing the role rather than passing for free.
- **New harness coverage:** stale-before / fresh-after (proves it is a snapshot in both directions),
  exactly one row and a second row refused, `anon` blocked from the table but able to call
  `get_catalog()`, and `get_catalog_built()` still present under its new name.
- ⚠️ **The fixture never modelled `anon` at all** — no grants, no RLS, no unpublished row. It was
  describing a database that could not have worked (today's `get_catalog()` is invoker, so anon must
  already have select on `tours`). Fixed, and used to prove the security property.
- `scripts/check-catalog-keys.py --selftest` **13/13** (was 8; +5 cases for the file audit, which
  had no coverage at all).
- Seed regenerates clean at **346 / 2,830 / 3,202 / 129**, **0 `images//`**, refresh emitted **inside
  the transaction** immediately before `commit`.
- The seed's guard block tested **both ways** against Postgres: with the function absent it emits a
  notice and returns 0 (an unmigrated database seeds exactly as before); with it present it calls it.
- `Tours.json` **untouched** — asserted, not assumed.
- ⚠️ **`main` moved TWICE while this was being written**, so every figure above was re-derived on the
  final base rather than carried forward: [#740](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/740)
  added four Miami/Little Rock places (**125 → 129**, which is why the seed count here is not the 125
  an earlier draft recorded), then [#741](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/741)
  flipped that PR's line on the board. **The `ROADMAP.md` conflict was resolved by DROPPING this
  branch's copies of two paragraphs, not by merging them** — #740 had rewritten both, so the stashed
  versions were the stale ones (2,598 ch against 4,849, and 2,466 against 2,642). The resolver
  asserts the upstream copy is **at least as long** before discarding, so a resolution cannot
  silently lose content.
- ⚠️ **#741 was another session's docs-only PR flipping an already-merged line, and it touched exactly
  the `STATUS.md` lines this change needed.** Merged first (Automation Rule #4's auto-merge class,
  all four checks green) rather than hand-resolving afterwards — a conflicted PR triggers no CI at
  all, so racing it would have cost a check run for nothing.

---

## 🔴 Ordering — merge first, apply second

The seed change is backward-compatible (guarded by `to_regprocedure`), so merging before the SQL is
applied is safe and does nothing. **The reverse is not**: applying the SQL while the old seed is
still live would upsert rows and never refresh, leaving every phone on a stale catalogue with
nothing erroring.

**Owner step, once, in the Supabase SQL Editor:** paste `backend/catalog_snapshot.sql`. It ends by
populating and verifying the snapshot, so "Success" means it is already serving.

⚠️ **After this, a hand edit in the SQL Editor is not visible until you run
`select public.refresh_catalog_snapshot();`.** Normal content merges handle it themselves.

---

## Still open

- **`Why the Cliff House Was Built`** — its hero is a blurred, unreadable smear in the source
  thumbnail, so the choice is keep or pull. Owner's call.
- ✅ **Eastern State Penitentiary — CLOSED 2026-09-07 ([#743](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/743)), and the
  framing below was WRONG.** Owner: *"eastern state already has a place. move 'inside the abandoned
  eastern…' into that place"*. **The place has existed with two members since the session-144 batch** —
  it was never a candidate; only the third pin sat outside it. That pin moved 3.78 m onto the place
  coordinate and is now its third member. ⚠️ The original note, kept for the record: *"a place
  candidate the checker structurally cannot see: the new pin is 3.7 m from the existing two-member
  place, so it never reaches EXACT and shows only as a 4 m NEAR pair."* The **measurement** was right
  and the **conclusion drawn from it** was not — 3.7 m from an existing place means a pin outside a
  place, not a place waiting to be made. **Read what a distance is measured FROM before naming what
  it implies.**

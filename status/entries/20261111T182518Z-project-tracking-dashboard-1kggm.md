# Merged #1180: owner's place backlog answered — places 528 -> 609, owner board 40 -> 18

_2026-11-11 18:25 UTC · branch `project-tracking-dashboard-1kggm`_

Merged on the owner's word ("merge 1180 when green"), after CI reported 7/7 and
a fetch confirmed `main` had not moved from the PR's base (`e0afd49`).

**Re-derived from `main` at `c209e92`, not quoted:**

| | base `e0afd49` | merged `c209e92` |
|---|---|---|
| places | 528 | **609** |
| link pins | 4,789 | **4,790** |
| tours | 2,499 | 2,499 |
| makers | 810 | 810 |
| cities / countries | 1,094 / 104 | 1,094 / 104 |

So the change was **+81 places** (81 new, 12 joins — a join merges members into an
existing place and adds none) and **+1 pin** (Napoleon's Tomb). Everything else held.

🔴 **The squash commit message on `main` is WRONG about the absolute figures, and
that cannot be edited out of history.** It says "Places 513 -> 594" because I copied
those numbers out of the PR body instead of re-deriving them, which is the exact trap
`CLAUDE.md` § Key facts documents at length. The PR body had been written against a
base of 513; by merge time the base was 528. **The delta in that message (+81) is
right and the catalogue is right** — `#1180` updated § Key facts itself, correctly, to
4790 pins / 7777 stops / 609 places, which is what I re-derived independently above.
Only my prose is wrong. Anyone reading `git log` for a place count should read the
catalogue instead.

**Corroborated before merging, independently of the PR's own claims:**
- `scripts/join-places.py --max-move 100` run read-only against `main` found 8
  same-name joins at 0–100 m (Colosseum, Carpenter Center, Battersea, Hampton Court,
  Depot Boijmans, Deichman Bjørvika, Operaparken, Karl-Marx-Hof) — every one of them
  in `#1180`'s list of 12.
- Three of its place questions were sampled and confirmed genuinely open, with
  unjoined entries at 0 m, 1 m and 9 m.

**Owner board: 40 → 18 items**, verified by counting `status/owner/*.md` on `main`.
`#1180` also recorded 18 tenant/neighbour pairs the owner declined, in `DECLINED_PAIRS`,
so the scanners will not re-offer them — which is the fix for the nine declined pairings
that previously lived only as prose in one session's conversation.

Post-merge `Publish catalog` (run 420) was in flight when this was written: it rebuilds
More-like-this, republishes the gh-pages mirror and reseeds Supabase. ⚠️ A reseed is
upsert-only, so the 4 dropped @welldonestuff links reach the mirror and the bundled seed
but **not** Postgres. If those rows must go, that is an SQL paste, not a reseed.

# Rescue the 100k scaling design and an unseen owner decision from an abandoned branch

_2026-09-16 12:58 UTC · branch `salvage-scaling-design-260916`_

Two files rescued **verbatim** from `claude/scale-pinned-tours-automation-dba3lx`,
which has been abandoned unmerged since 2026-09-15. Neither had ever reached
`main`, so neither was visible to any session or to the owner.

- `docs/scaling-to-100k-design.md` — the ingestion plan, plus two live-defect
  findings that have nothing to do with scaling.
- `status/owner/auto-created-places.md` — **an owner decision that has been
  invisible for two days.** It gates section A1 of that plan.

**Why the branch was abandoned, in its author's own words:** it built Phase 0 of
the delta design in parallel with #904 and later recorded that its own commits
*"duplicate it and should not be merged"*. It also filed, then **retracted**, a
claim that #904's Phase 0 crashed the seed on a stop reorder — the retraction
says the failure was in that session's own fixture, not in `main`.

🔴 **The branch also carries `backend/add_catalog_rev.sql`, a SECOND migration
doing the same job as the `backend/catalog_rev.sql` already applied to
production**, and a `backend/catalog_since.sql` 126 lines different from the one
live via #912. Nothing on it should be merged. Once this lands, it is safe to
delete and **deleting it is the point** — left alone, a future session could hand
the owner a duplicate migration to paste.

⚠️ **Finding 1 of that doc was re-derived today and is worse than written:** 307
coordinate groups (was 205), 28 of them larger than 3 (was 19), and **46 entries
invisible on the map** (was ~32), largest group 8. **And a second stacking limit
the original audit missed:** `HomeView.swift:633` `maxStackedPlacecards = 4`
alongside `TourSetMap.swift:243` `maxStacked = 3` — a fix must address both.

Both files carry a dated banner saying what has since shipped (Phase 0 #904,
Phase 1 #912, Phase 2 #914) so neither becomes the next stale document.

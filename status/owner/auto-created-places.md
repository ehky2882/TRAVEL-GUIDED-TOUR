# Approve auto-created places (gates the 100k densify plan)

_opened 2026-09-14 · **surfaced 2026-09-16** · clear with `git rm status/owner/auto-created-places.md`_

> ⚠️ **This item was written on 2026-09-14 and sat on an abandoned branch, so it never
> reached the board and the owner never saw it.** Re-derived on 2026-09-16, the problem
> it describes is **bigger than it says**: 28 coordinate groups now hold more than 3
> entries and **46 entries are invisible on the map**, against the ~32 recorded below.
> ⚠️ There is also a second limit the original missed — `HomeView.swift` carries its own
> `maxStackedPlacecards = 4` beside `TourSetMap`'s `maxStacked = 3`.

**Densifying to 3–4 creators per landmark needs auto-created places, and today the
rule forbids it.**

`Models/Place.swift` states a place *"must be approved by a human, never
auto-created."* At ~25–30k places that cannot hold — and the map enforces it:
**`TourSetMap.maxStacked = 3`**, so a fourth pin on one coordinate is
**permanently invisible**, not merely crowded.

The design (`docs/scaling-to-100k-design.md`) makes grouping safe by construction:
place identity comes from the OpenStreetMap feature id, so two pins about the same
cathedral resolve to the same place without anyone judging it.

⚠️ `docs/places.md` still leaves **part-vs-whole explicitly undecided** — owner:
*"I THINK THE PART AND WHOLE IS A JUDGEMENT CALL"*. That question is NOT settled by
a gazetteer and would need its own answer.

**Only you can decide this.** It gates section A1 of the plan. Nothing ships until
you say yes.

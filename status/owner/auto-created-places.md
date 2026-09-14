# Approve auto-created places (gates the 100k densify plan)

_opened 2026-09-14 · clear with `git rm status/owner/auto-created-places.md`_

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

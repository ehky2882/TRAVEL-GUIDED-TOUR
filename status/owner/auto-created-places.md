# Approve auto-created places (gates the 100k densify plan)

_opened 2026-09-14 · **surfaced 2026-09-16** · clear with `git rm status/owner/auto-created-places.md`_

> ⚠️ **This item was written on 2026-09-14 and sat on an abandoned branch, so it never
> reached the board and the owner never saw it.**
>
> 🔴 **CORRECTED 2026-09-16 — the "invisible pins" evidence in this item is FALSE.**
> It said 28 coordinate groups exceed the cap and **46 entries are invisible on the map**.
> Measured on `d8fabd53`: **0 entries are invisible.** All 29 oversized coordinate groups
> are fully inside place pages, and a place renders as **one pin that opens its own screen**
> (`TourSetMap.swift:26`, `onPlaceTapped` line 105) — a member cannot be truncated by
> `prefix(maxStacked)`. The 46 was a count of RAW coordinate groups with place membership
> not excluded; **PR #924 had already retracted that exact arithmetic**, and the retraction
> was not carried forward. Membership lives in `place.tourIds`, not a field on the pin.
>
> **The DECISION below still stands on its own merits** — it is about minting places in
> bulk at ~25–30k, not about anything currently broken. Nothing on the map is being lost
> today, so this is not urgent; it is only blocking.

**Densifying to 3–4 creators per landmark needs auto-created places, and today the
rule forbids it.**

`Models/Place.swift` states a place *"must be approved by a human, never
auto-created."* At ~25–30k places that cannot hold — and the map enforces it:
**`TourSetMap.maxStacked = 3`**, so a fourth pin on one coordinate WOULD be
permanently invisible — ⚠️ **which is why places matter, and why none is invisible
today: every oversized group is already a place.** The cap is a reason the spine
must mint places reliably, not evidence of present breakage.

The design (`docs/scaling-to-100k-design.md`) makes grouping safe by construction:
place identity comes from the OpenStreetMap feature id, so two pins about the same
cathedral resolve to the same place without anyone judging it.

⚠️ `docs/places.md` still leaves **part-vs-whole explicitly undecided** — owner:
*"I THINK THE PART AND WHOLE IS A JUDGEMENT CALL"*. That question is NOT settled by
a gazetteer and would need its own answer.

**Only you can decide this.** It gates section A1 of the plan. Nothing ships until
you say yes.

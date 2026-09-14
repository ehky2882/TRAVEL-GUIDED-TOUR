# HANDOFF — 2026-09-14: Gandhi Bhawan becomes a place

Owner: *"1. yes"* — to making the two Gandhi Bhawan pins a place, put to them in `HANDOFF-260914-chandigarh.md`.

## What changed

- New place **Gandhi Bhawan**, `uuid5(NAMESPACE_URL, "atlas-place:chandigarh:gandhi-bhawan")`, city
  Chandigarh, address "Panjab University, Chandigarh".
- Members: @archimarathon's *Gandhi Bhawan* (`AF9EAD7B…`) and @blessedarch's *Gandhi Bhawan*
  (`591A2058…`). Both thumbnails show the building (the folded roof; the "TRUTH IS GOD" entrance).
- Point **30.761821, 76.7713672**: @archimarathon's pin, which reverse-geocodes onto OSM **Gandhi Bhavan**.
  @blessedarch's pin — moved off a sports pitch onto the building in #903 — moved a further 0.02 m onto it,
  because a place's identity is exact coordinate equality.
- Description kept to what the posts and thumbnails show: Pierre Jeanneret (named in @archimarathon's
  caption), the folded roof, the "Truth is God" entrance.

## Order

Built on #903's commit, because #903 is what moved @blessedarch's pin onto the building. Rebased onto
`main` after #903 merged.

## Checks

`validate-tours.swift` 0 errors; `validate-tours-mirror.py` 0 errors, selftest 32/32; seed clean;
`check-place-candidates.py` loses exactly the Gandhi Bhawan TIGHT pair.

## Still waiting on the owner

- **Tokyo:** 26 pins added 2026-09-14 where different venues share one neighbourhood point — owner said *wait*.
- **PR #896:** 20 more Tokyo pins, all 4-decimal coordinates — no decision on commenting.

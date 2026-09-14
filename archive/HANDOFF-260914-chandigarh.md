# HANDOFF — 2026-09-14: Chandigarh — two pins on a sports pitch, and Maison Pierre Jeanneret

Owner: *"whats the issue with chandigarh? i also see that the house of pierre jeannerat needs to be a place"*

## The Panjab University pair

Two pins sat on one identical point, **30.7602415, 76.7664916**, which OSM and Nominatim both place on a
**sports pitch in Sector 14** — neither building:

| Pin | Thumbnail shows | Moved to | Now sits on |
|---|---|---|---|
| `18099446…` **The Fine Arts Museum at Panjab University** (@archimarathon) | red-brick building signed "Fine Arts Museum" | 30.762347, 76.7722 (centroid of OSM relation 2051982) | The Museum of Fine Arts |
| `591A2058…` **Gandhi Bhawan** (@blessedarch) | the "TRUTH IS GOD" entrance under the folded roof | 30.761821, 76.771367 (OSM Gandhi Bhavan building) | Gandhi Bhavan |

Both subjects were right; only the shared coordinate was wrong. @archimarathon's own **Gandhi Bhawan** pin
(`AF9EAD7B…`) was already on the building, 498 m from the pitch.

⚠️ **Now a place candidate:** the two Gandhi Bhawan pins sit on one building (0.02 m apart, TIGHT tier).
Two names for one thing is always a place (`docs/places.md` Rule 1), but a place is an owner call — put to
the owner, not created.

## Maison Pierre Jeanneret — new place

Owner-requested. Two pins, both showing the house (brick jaali screens, rubble-stone wall):
@archimarathon *Maison Pierre Jeanneret* (`657C1195…`) and @blessedarch *House of Pierre Jeanneret*
(`62B2EAC9…`). They sat 0.1 m apart, so they never formed an exact group.

- Place `ef757419-a4b7-54a9-b105-60be584b105b` = `uuid5(NAMESPACE_URL, "atlas-place:chandigarh:maison-pierre-jeanneret")`.
- Point **30.744817, 76.807566** — @archimarathon's pin, which reverse-geocodes onto OSM **Maison Jeanneret
  Museum**, Uttar Marg, Sector 5. @blessedarch's pin moved 0.1 m onto it (exact equality is the rule).
- Named with the museum's own name; description kept to what both captions say.

## Checks

`validate-tours.swift` 0 errors; `validate-tours-mirror.py` 0 errors, selftest 32/32; seed 303 places.
`check-place-candidates.py`: EXACT 15 → 14 (the pitch group gone), NEAR 44 → 43, and the two
Chandigarh TIGHT entries swap — Jeanneret resolved by the place, Gandhi Bhawan new.

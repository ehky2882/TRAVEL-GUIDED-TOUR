# Five orphan pins folded into the places they already sat on

_2026-09-16 17:19 UTC · branch `five-orphan-pins-into-places-260`_

Owner decision, 2026-09-16: *"MAKE INTO PLACE - FORD, MET BREUER, BARBICAN,
SAGRADA, CRYSTAL BRIDGES"*.

Five link pins were sitting on the exact spot of a place they were not members
of. Each place goes 2 → 3 members; `places` stays 334, membership 816.

🔴 **Why the existing sweep missed them, and it is worth keeping.** These pins
carry **7 decimal places** where their place carries **6** — `40.7498787` against
`40.749879`. They round to the same point but are not equal, so an
exact-coordinate matcher does not see them. They are **2–5 cm** apart: the same
spot by any physical standard, a different one to `==`.

A place IS a coordinate and `validate-tours.swift` requires a member's first stop
to sit exactly on it, so each pin's centroid **and** first stop were snapped onto
the place. The largest move is 5.11 cm.

**After: 0 partially-claimed coordinate groups catalogue-wide** (was 12 before
#952, 5 after it). A follow-up sweep for non-members within **5 m** of any place
returns **0**, so this class is now empty rather than merely reduced.

⚠️ **The generalisable bit:** any check that pairs entries with places on exact
coordinate equality has this blind spot. It found nothing else today, but the
next batch authored at 7 dp would slip through the same way. A tolerance of a
metre or two would close it — deliberately NOT changed here, because
`check-place-candidates.py` is being actively developed by another session
(#950's NAME tier) and two sessions editing one checker is how this repo gets
conflicts.

⚠️ Rule 2's `swift scripts/validate-tours.swift` could **not** be run — no Swift
in a remote container. CI's `Validate Tours.json` is the stand-in and must be
green before merge; it is the check that enforces the first-stop-on-coordinate
rule this change depends on.

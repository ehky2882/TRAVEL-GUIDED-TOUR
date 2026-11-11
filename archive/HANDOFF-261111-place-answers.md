# HANDOFF 2026-11-11: the owner answered 77 place questions

## What happened
The owner's list had grown to 40 items, most of them place questions left by
city launches and triage batches since late September. I re-checked them
against the live catalogue (`check-place-candidates.py`, `join-places.py
--max-move 200`), numbered them, and put them to the owner in four groups:
J (join an existing place), P (new place, same thing twice), Q (part of a
larger site) and N (my read is *not* a place).

- **"DROP THOSE LINKS"**: the 4 @welldonestuff reels lost from #1032 will
  not be restored. Item cleared.
- **"j all yes"**: 10 joins. Eight were applied with `join-places.py
  --max-move 100 --apply`. The other two (MoMA: Abby Aldrich Rockefeller and
  Great Court, British Museum) have different names, so the tool doesn't
  match them; they were joined with the same `apply_join`. Parliament Square →
  Houses of Parliament (192 m) was deliberately NOT joined: a square is not
  the building.
- **"p all yes"**: 67 new places, 513 → 580. The anchor is the Atlas tour's
  point except where a pin is provably more accurate:
  - **MAC Niterói**: the pins are on the museum; the tour was 197 m north.
  - **Seagram**: the pin is precise; the tour's coordinate was rounded to
    4 decimals.
  - **Genex**: the *Western City Gate* pin matches the OSM building; the
    tour's coordinate was rounded from degrees-minutes-seconds.
  - **Heap Seng Leong**: OneMap puts 10 North Bridge Rd exactly on the
    *(kopi + kaya toast)* pin.
  - **Syracuse Cathedral**: the pin nearer the cathedral body; the other was
    on the piazza.
  - **Little Island**: the island's centre, so the SW Overlook tour moved
    89 m.

  The largest moves were Sedesowce (331 m, to the tour at the estate's
  west end, as the item proposed), Berlin Wall Memorial (216 m, the visitor
  centre pin onto the memorial grounds tour), and the WU Library and Otto
  Wagner Pavilion pins (172 m and 149 m, onto the buildings).

## Missed: two questions I left off the P list
**Kolumba** (Cologne, two pins) and **FENIX** (Rotterdam, tour + pin, 0 m)
are same-site pairs whose names differ, so the NAME report did not show
them and I did not add them by hand. They were put to the owner separately.
They are still open in `place-triage-261020` and `rotterdam-launch`.

## Still open for the owner
Q1–Q16 (part-vs-whole) and the N list (confirm). Five owner items were
cleared outright, and 16 partly answered ones carry an `> ✅ Answered` line.

## Checks
`validate-tours-mirror.py`: 0 errors, 2463 tours + 4721 pins + 580 places.
`check-place-candidates.py`: NAME is now empty. `join-places.py`: only
Parliament Square remains, which is deliberate.

## Follow-up: Kolumba and FENIX
The owner said yes ("kolumba and fenix yes"), so both are now places at 0 m and nothing moved. Places 580 → 582. `place-triage-261020` is cleared.

## Follow-up: part-vs-whole Q1–Q6
- **YES:** Q1 Teshima Art Museum + café (35 m), Q2 Nezu Museum + garden (26 m), Q3 Museum of
  Anthropology + Tláloc Monolith (38 m), Q5 Abraj Al Bait mall + pin (49 m). Each sits on the tour's
  or museum pin's point.
- **NO:** Q4 Lycabettus Funicular / Mount Lycabettus, Q6 Clock Tower museum / Fairmont. Both are in
  `DECLINED_PAIRS` (`scripts/make-place-menu.py`) and in the `docs/places.md` 2026-11-11 table.
- `main` (#1177–#1179) was merged into the branch first. The spine cache conflict took `main`'s copy
  and re-ran `spine-lookup.py`.
- Places: 586.
- Q7 **YES**: City of Arts and Sciences, on El Umbracle's point (81 m pin move). Q8 **YES**: Richard Sorge Park,
  on the monument (164 m pin move). Q9 **NO**: Weir Greenhouse stays out of Green-Wood. Places: 588.

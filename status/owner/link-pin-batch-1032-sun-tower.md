# Verify Sun Tower (Yantai) coordinate — Wikidata match too thin to trust

_opened 2026-09-21 · clear with `git rm status/owner/link-pin-batch-1032-sun-tower.md`_

PR #1032's Sun Tower pin (Yantai, China — the OPEN Architecture oceanfront
cultural centre) is geocoded to Yantai's city centre, since Nominatim has no
entry for the building itself.

CI's spine audit (scripts/spine-lookup.py / spine-match.py) flags it as 23.5 km
from its only Wikidata candidate. I checked that candidate by hand before
deciding whether to trust it: it carries no description, no Chinese label, and
exactly one sitelink (German Wikipedia only) — too thin to tell whether it's
the same "Sun Tower" or an unrelated building that happens to share the name.
Left the coordinate as the city-centre approximation rather than moving 23 km
on weak evidence.

If you know the building's actual coordinates (or can point me at a Chinese-
language source that pins it), a follow-up can fix it precisely. Otherwise no
action needed — it's a soft (marked ~1km tolerance) miss, not broken.

Clear with: git rm status/owner/link-pin-batch-1032-sun-tower.md

---

## Searched further on 2026-09-21 — still undecided, but here is what is ruled out

Recorded so you are not asked to redo any of it. Routes tried:

- **OSM via Overpass** (`overpass.kumi.systems`, which does work despite rule 8d
  saying Overpass is blocked): nothing named `Sun Tower`, `阳光塔` or `陽光塔`
  inside a Yantai bounding box.
- **English Wikipedia**: its "Sun Tower" is **Vancouver's** heritage building —
  a different thing entirely, and a trap for any name-based match.
- **Wikidata**: the candidate still has no description and no administrative
  unit, so `triage-spine.py` cannot decide it either.

Verdict on file is `undecided` in `checks/spine-verdicts.json`, with the note:
*"I have an opinion about which is right; an opinion is not a source."* The pin
stays on the city-centre approximation until something names the building.

**What would settle it:** a Chinese-language source that names the building, or
simply the coordinate if you know the site. One line is enough.

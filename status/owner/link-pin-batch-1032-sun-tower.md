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

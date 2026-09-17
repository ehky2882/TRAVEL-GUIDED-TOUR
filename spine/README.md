# `spine/` — the Wikidata lookup cache

`scripts/spine-lookup.py` writes `lookups.json.gz` here: one record per catalogue
entry, holding the name it asked Wikidata for and the geolocated items that came
back within `--bound-km`.

**It is data, not source.** `scripts/spine-match.py` reads it offline and bands
every entry — so the expensive half runs once, and the analysis is free to
re-run, tune and put in CI.

🔴 **The cache is also the resume state.** A full sweep is ~4.5 hours at the rate
WDQS politely allows. Interrupt it at any point and run it again; every entry
whose title and coordinate have not changed is skipped.

⚠️ **A record is keyed by a digest of the title, the coordinate and the bound.**
Move an entry or rename it and the answer is re-asked automatically — a cached
candidate list is only valid for the point it was measured from.

## Not committed yet

`lookups.json.gz` is `.gitignore`d until the first sweep completes. A partial
cache is worse than none in the one way that matters: `spine-match.py` reports
`NOT-ASKED` and exits 2 (COULD NOT VERIFY) for every entry missing from it, so
committing a half-finished one would put a permanently red check in CI while
looking like coverage. Commit it, drop these lines, and wire the CI job in the
same change.

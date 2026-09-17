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

## The cache is committed, including while it is still partial

A full sweep is ~4.5 hours and this session's container is not guaranteed to
outlive it, so `lookups.json.gz` is committed as it fills rather than only at the
end. It projects to **~0.4 MB complete** — measured at 225 entries, not guessed —
so a checkpoint costs almost nothing and protects hours of other people's
bandwidth as much as ours.

🔴 **A partial cache must not be wired into CI.** `spine-match.py` reports
`NOT-ASKED` for every entry missing from it and exits **2 — COULD NOT VERIFY**,
which is the correct answer and a permanently red check. Wire the CI job in the
same change that commits the *finished* sweep, never before: a red check nobody
can fix reads as coverage and gets ignored, which is how a check stops being one.

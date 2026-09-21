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

🔴 **That promise was true of the fetcher and false of the reporter, for four
days.** `spine-lookup.py` consulted the digest and re-asked; `spine-match.py`
never looked at it and printed the cached distance regardless. So on
2026-09-21 the audit reported **all nine coordinates that had just been
corrected as still broken** — Belgrade Tower read 2,329 m out while sitting on
Wikidata's own point, a 0 m agreement. Refreshing 59 rows took 9 queries and
moved CONFIRMS from 1,764 to 1,778.

The nuisance direction is the harmless one. **A coordinate moved to the WRONG
place keeps reporting its OLD distance too** — so the one check that exists to
police such a move is blind to exactly the edit it was built for, and CI stays
green. `spine-match.py` now bands those rows **STALE**, gives them **no
distance at all** (a number measured from a point an entry no longer sits on is
a confident wrong answer, not a weak one), leaves them out of the coverage
denominator, and exits **2 — COULD NOT VERIFY**. The cure is one command, named
in the output. `scripts/mutate-spine-match.py` holds the mutants that keep it
honest.

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

## `features.json.gz` — what KIND of thing each matched item is

`scripts/spine-features.py` asks Wikidata for each matched item's `instance of`
and `area`, ~300 QIDs to a query. **It is not a re-sweep**: the 4,566 lookups
took about an hour, this takes well under a minute, and it only asks about items
that were actually matched.

It exists because the first full audit produced **145 DISAGREES** and reading
them showed the list was dominated by one class that is not an error at all — a
four-mile boulevard, a 2,168 km² national park, a 12 km bridge. A site with no
single point has no single coordinate: ours sits at the entrance or the famous
view, the gazetteer's at a centroid, and neither is wrong. Separating those took
the list to **86**.

⚠️ The types are a **reporting aid, never a verdict**. An extended site is still
listed, under a heading that says what it is.

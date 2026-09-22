# Review 5 spine-audit coordinate flags on PR #1054 (believed Wikidata-elsewhere)

_opened 2026-09-22 · clear with `git rm status/owner/pr-1054-spine-disagrees.md`_

# FYI: 5 spine-audit "DISAGREES" flags on PR #1054's new pins — believed Wikidata-elsewhere

PR #1054 (88 new @historicpubcrawls link pins) triggered `spine-lookup.py` + `spine-match.py`
for the first time on these entries, and 5 came back flagged 🔴 DISAGREES (our coordinate is
far from what Wikidata says). I checked all 5 by hand before deciding whether to move anything,
per the runbook's "never move a pin on a distance alone" rule.

**One of the six original flags WAS a real error and has already been fixed in this PR**:
Lamb & Flag, London was geocoded to a same-named pub in Marylebone (James Street) instead of
the actual "London's Most Violent Pub" on Rose Street, Covent Garden. Independently verified via
OSM (33 Rose Street, WC2E 9EB) — matches Wikidata's coordinate to within 2 m. Fixed.

**The remaining 5 look like Wikidata-elsewhere false matches, not errors on our side** — each of
our coordinates is corroborated by the post's own caption address, and each Wikidata alternative
is either a thin/low-notability item or geographically implausible for the caption's context:

| Entry | Ours (address-corroborated) | Wikidata's candidate | Why I think Wikidata is the wrong one |
|---|---|---|---|
| The Sun Inn (Richmond, London) | 7 Church Road, Mortlake — matches the "Richmond to Riverside" route | 29.2 km away, near Enfield; 1 sitelink | A different Sun Inn entirely; Mortlake is genuinely on the Richmond riverside walk |
| The Roebuck (Richmond, London) | 130 Richmond Hill — the well-known view pub | 15.3 km away, near Borough; 2 sitelinks | Plausibly a different, Wikipedia-notable Roebuck; ours matches "Richmond Hill" specifically |
| Hedigan's (The Brian Boru), Dublin | 5 Prospect Rd, Glasnevin, D09 PP93 — exact postcode match to the caption | 3.7 km away; **0 sitelinks** (no Wikipedia article at all) | A bare, low-confidence Wikidata item vs. an exact address match |
| The Marquis, London (×2 pins) | 51-52 Chandos Place, Covent Garden — matches "Covent Garden" named twice in captions | 2.3 km away, near Pimlico; 1 sitelink | Thin Wikidata item, no textual corroboration |

Not moving any of these without your OK — the runbook is explicit that a Wikidata distance is
evidence, not a verdict, and three pins moved on distance alone once came out 11 m right, 220 m
wrong and 100 m wrong. If you'd like these recorded as ruled `wikidata-elsewhere` in
`checks/spine-verdicts.json` (so they stop showing up on every future audit), say so and a
follow-up can add them — otherwise this is FYI only; the pins are live as address-verified.

Clear with: `git rm status/owner/pr-1054-spine-disagrees.md`

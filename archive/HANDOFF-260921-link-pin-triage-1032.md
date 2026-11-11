# HANDOFF 2026-09-21 — Triaged 62 links into 54 pins, caught a duplicate batch and two bad coordinates before merging

[#1032](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1032), merged.

## What happened

Owner pasted a pile of 62 Instagram links with no context beyond "a couple of creators." Triaged
before minting anything, per the standing rule: fetched every caption via the embed endpoint,
which surfaced **6 distinct creators**, not "a couple" — **@dvirshastel** (35 posts, food) and
**@welldonestuff** (21, architecture/engineering marvels) dominate, plus one post each from four
others. Flagged the creator-count surprise to the owner before proceeding.

**Two posts named no subject anywhere in the caption.** Per the owner's instruction to check the
video when the caption comes up empty, opened each thumbnail and read the on-screen title card:
"First Twin Towers" → **The San Remo** (145 Central Park West); an unnamed Rome gelato stop →
**Gelateria Fassi**. Several more gave only an Instagram `@handle` for the venue (Kapara, JWO
Lekkernijen, Turbo, Café Papeneiland, Casa Montaña, Le Dauphin, Chapel Market Kitchen, Esh Pita
Bar, Manari Taverna, Van Dobben, Ouzeri Karayiannis, Trattoria Sostanza) — resolved each to a real
name + address by web search, not guessed.

Owner reviewed the full triage table and called it: skip Kapara (closed) and Sala de Despiece
(moved address, ambiguous which one applied), pin two the auto-triage had flagged as THIN/MULTI
on a caption-regex false positive (a Tokyo t-shirt shop with no-inline video; Arnfeldt, a seasonal
restaurant), confirmed "995 Duck" as the correct name (caption misspelled it "955"), and confirmed
the engineering/dam posts fit the app. Pin the rest.

## Two things nothing upstream would have caught

> 🔴 **CORRECTED 2026-09-21 (later the same day).** The paragraph below is **wrong** and is
> left in place rather than rewritten, because the record of what was believed is part of the
> account. The four existing entries are **NOT** other `@welldonestuff` posts — they are by
> **@taylinmaylin** (Calgary Central Library) and **@pasttworld** (the other three). A different
> creator on the same subject is a **second take**, which the owner has twice asked to keep
> (#1040: Fraunces Tavern, Ye Olde Cheshire Cheese, the Stonewall Inn), so all four should have
> been pinned. The owner caught it: *"i dont have a duplicate at calgary central library unless
> you say the tour by taylinmaylin is the same thing?"* ⚠️ **They could not be restored**, because
> neither this handoff, the PR body, the deleted branch nor anything else in the tree recorded the
> four **source URLs** — the one irreplaceable part. See `docs/lessons.md` and
> `docs/link-pin-runbook.md` § *Anything you DROP must keep its link*.

**Four pins would have duplicated existing content.** `merge-link-pins.py --check` flagged Calgary
Central Library, Guangzhou Circle, Huajiang Grand Canyon Bridge, and Three Gorges Dam as sitting
**0 m** from an entry already in the catalog — a different `@welldonestuff` post about the exact
same landmark, pinned earlier. Dropped from the batch (58 → 54) rather than putting two map pins
on one spot; logged as `status/owner/link-pin-batch-1032-duplicates.md` since the choice (keep the
old post, swap in the new one, or allow both) is the owner's per rule 8c.

**CI's spine-coordinate audit failed on push** — the 54 new pins weren't in the committed Wikidata
lookup cache (`spine/lookups.json.gz`) yet, so `spine-match.py` exited 2 ("could not run") rather
than a soft finding. Ran `scripts/spine-lookup.py` to fill the cache, which then surfaced **5 of my
own pins** sitting well off their subject's real Wikidata coordinate — all five geocoded from a
city/region name because Nominatim had nothing for the specific structure:

| entry | off by | verdict |
|---|---|---|
| Sun Tower (Yantai) | 23.5 km | **not moved** — its only Wikidata candidate has 1 sitelink (German Wikipedia only), no description, no Chinese label. Too thin to trust for a 23 km jump; flagged to the owner instead of guessed |
| Ruyi Bridge | 21.7 km | moved — Wikidata gives a description matching the caption exactly ("scenic bridge in Shenxianju, Taizhou") and 8 sitelinks |
| Xiaolangdi Dam | 2.6 km | moved — Chinese label is literally "Xiaolangdi Water Conservancy Hub Project," confirmed same dam |
| Beijing Daxing Airport | 1.6 km | moved — 51 sitelinks, unambiguous |
| Zayed National Museum | 1.2 km | moved — 11 sitelinks, description matches |

Checked each Wikidata candidate's label, description, and sitelink count by hand before trusting
any of them — rule 8d's warning that a distance alone moved pins wrong before (11 m right, 220 m
wrong, 100 m wrong) applies exactly as much to a session's own new content as to old.

## State

- **54 pins live** (`Tours.json` + `gh-pages` heroes, uploaded via git plumbing since `gh` CLI
  wasn't available in this environment — read `origin/gh-pages` shallow, `git commit-tree`, one
  push, no 4 GB checkout).
- `spine/lookups.json.gz` carries all 54 new subjects.
- Two open owner items: `link-pin-batch-1032-duplicates.md` (FYI, no action needed unless the
  owner wants the newer post swapped in), `link-pin-batch-1032-sun-tower.md` (needs a real
  coordinate for the Yantai Sun Tower — Wikidata can't supply one confidently).

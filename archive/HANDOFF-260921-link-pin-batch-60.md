# HANDOFF 2026-09-21 — Triaged 62 links into 60 pins across 6 creators, caught a tag-vocabulary miss and a hero filename collision before merging

[#1040](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1040), merged.

## What happened

Owner pasted a pile of 62 links (31 Instagram, 31 TikTok) with no context beyond "a couple of
creators." Triaged before minting anything: pulled every caption via oEmbed, which surfaced **6
distinct creators**, not "a couple" — **Historic Pub Crawls** (TikTok, 31 posts, a numbered
pub-crawl series across NYC/London/Glasgow/Inverness/Galway/Cork/Derry/Boston), **clayton.chambrs**
(Instagram, 15, menswear/vintage shop finds), **rasulal1yev** (Instagram, 10, history/landmarks),
**cookwithanana** (Instagram, 3, Italian food), plus one post each from **drewfromladue** and
**bsc_.hoi**. This is a different batch from #1032's dvirshastel/welldonestuff triage the same
morning — checked every shortcode against `Tours.json` before starting to be sure.

Reverse-geocoded every resolved address and presented a full proposed subject/category/tags table
to the owner before minting anything, per the standing rule. Owner's calls:

- Pin everything proposed, plus three landmarks (Fraunces Tavern, Ye Olde Cheshire Cheese,
  Stonewall Inn) that sit at the same coordinates as existing catalog entries from other creators
  — explicitly wanted both, since a different creator's take on the same landmark is fine side by
  side (rule 8c cuts the other way by default; owner overrode it here).
- Skip one TikTok post (byte-identical caption to another post in the same batch, same bar — Dead
  Rabbit) and one Instagram post (a docuseries teaser about "Umbria's peaks" generally, no fixed
  venue).
- **Five clayton.chambrs posts named no subject and no @handle anywhere in the caption** — nothing
  short of watching the video would resolve them, and this session has no video/frame-extraction
  path for TikTok or Instagram. Owner watched them and supplied street addresses; reverse-searching
  each address (not guessing) turned up: Applied Art Forms (Utrechtsestraat 139, Amsterdam — their
  new flagship, confirmed by a match on "wall of vinyl and custom sound system": the brand makes
  turntable/speaker furniture), Colbo (51 Orchard St, NYC), Goodhood (15 Hanbury St, London), Sabre
  Paris (39 Rue de Poitou), and a second Concrete Matter visit (Gasthuismolensteeg 12, Amsterdam —
  same address as another post in the same batch).

## Two things nothing upstream would have caught

**Six of the first-pass tags weren't in the app's controlled vocabulary.** `Tag.swift` is a closed
479-tag list across 5 facets; `Music`, `Film Location`, `Design`, `Tradition`, `Sacred Sites`, and
`Community` all read as plausible free-text tags but aren't in it — `validate-tours-mirror.py`
caught all 23 affected pins as errors (`control DIRTY`) on the first validation pass. Swapped for
vocabulary equivalents (`Performance`, `History`, `Monument`, `Faith`, `Religious Building`) and
added a `Place type` tag to seven landmark entries that were missing one (`Museum`, `Religious
Building`, `Park`, `Monument`, `Notable Building`) while fixing the errors, since they were already
open. Re-ran clean: 0 errors, selftest 37/37, control clean.

**The two "Concrete Matter" pins collided on their derived hero filename.** `make-link-pin.py`
derives a pin's filename from title + handle; both posts (different Instagram reels, same shop,
same creator) produced `concrete-matter-claytonchambrs_hero.webp`, so the second invocation
silently overwrote the first's cropped hero on disk — both catalog entries ended up pointing at one
image before the bug was caught. `check-image-duplicates.py --pins` (shared-URL check) flagged it
in one run. Fixed by re-cropping the first post's hero under `--slug concrete-matter-2` and
repointing that pin's `heroImageURL` + `stops[0].imageURL`. Uploaded as a second, separate gh-pages
commit (one file, additions-only diff) rather than touching the live file the other pin still
references — per rule 9, a corrected image is a new filename, never overwritten bytes.

## State

- **60 pins live** (`Tours.json` 3348 → 3408 linkPins; `gh-pages` heroes, uploaded via git plumbing
  in two commits since `gh` CLI wasn't available in this environment — read `origin/gh-pages`
  shallow, `git commit-tree`, push, no 4 GB checkout). Filenames diffed against the catalog diff:
  60/60 align. All 60 heroes byte-hashed unique after the Concrete Matter fix.
- CI's spine-coordinate audit passed clean on the first push (unlike #1032 same morning, which
  needed a manual `spine-lookup.py` cache fill) — all 60 subjects were either already in the
  Wikidata lookup cache or resolved without a spine mismatch.
- 6 pins won't play inline (Instagram licensed-music restriction: two Concrete Matter posts,
  Labour and Wait, Applied Art Forms, Colbo, E. Dehillerin, Re:think CPH) — tapping opens Instagram
  instead; flagged in the PR body, no owner action needed.
- No open owner items from this batch.

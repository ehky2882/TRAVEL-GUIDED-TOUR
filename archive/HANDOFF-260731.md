# HANDOFF — 2026-07-31 (session 80, web/PM, content)

## What shipped

**🇦🇪 Dubai is live — 26 tours under a new 21st maker, Atlas Studio DXB.**
Branch `claude/dubai-audio-upload-0yclol`. Content only: `Tours.json` +
`drafts/AUDIO-PENDING-SURVEY.md` + `CLAUDE.md`. Reaches users over the air
after merge (publish-catalog seeds Supabase + the gh-pages mirror); **no app
build needed.**

| | before | after |
|---|---:|---:|
| tours | 1014 | **1040** |
| makers | 20 | **21** |
| stops | 1280 | **1320** |

- **22 single-stop tours**, geofenced 30 m, ids `atlas-{tour,stop}:dxb:<slug>`.
- **4 walks**, stops geofenced 40 m with a `manual` intro at stop 0:
  - `dubai-creekcrossing-walk` — "The Creek Crossing" (intro+4, 1.2 km, culturalHeritage)
  - `dubai-oldquarter-walk` — "The Old Quarter" (intro+4, 2.0 km, culturalHeritage)
  - `dubai-downtown-walk` — "The Downtown Loop" (intro+3, 1.8 km, architecture)
  - `dubai-marinajbr-walk` — "Marina & JBR — An Evening in Two Waters" (intro+3, 3.2 km, architecture)
- **Maker id** `e94b8814-2c31-5113-963c-1743e6c86b4b` = uuid5 `atlas-maker:dxb`.
- **40 MP3s**, 5,012 s (~1h24m), on gh-pages as `audio/<slug>.mp3` (singles) and
  `audio/<walkslug>_stop{N}.mp3` (walks, intro = `_stop0`).
- **Categories:** 9 culturalHeritage · 8 architecture · 3 history ·
  3 natureAndParks · 1 each musicAndPerformance / sacredSites / visualArt.

## The transport question, settled

The owner pasted a **Dropbox shared-folder link (`/scl/fo/…`)**. It downloaded
headlessly on the first attempt with `dl=1` — an 82 MB zip — exactly as Ho Chi
Minh City did.

**This is not the Montreal situation.** Montreal's four-attempt fight was about
Dropbox **Transfer** links (`/t/…`), which fetch their file list via JS after
page load and hide the download behind an undocumented internal API; about a
SharePoint work-tenant link, which is an identity boundary; and about Chromium
being unable to reach the network at all through the agent proxy.

**Check the URL shape before declaring a link undownloadable:**
`/scl/fo/` = shared folder = works with `dl=1`.
`/t/` = Transfer = ask for a chat attachment instead.

## Two staging-README errors that would have shipped defects

Both were caught by the validator or by comparing against recent cities. **Both
will recur on Berlin and Chicago, whose READMEs were written the same way.**

1. **Singles: `stop0.imageURL`.** `drafts/dubai-batch1/README.md` says `null`.
   Montreal, Rome and Madrid set it to the tour hero on **100%** of their
   singles. Dubai now sets it. (Catalog-wide it is 353/966, but every recent
   city sets it — the nulls are older cities.) Same class of staleness as the
   Rome READMEs saying `kind: "singleStop"` when the value is `single`.

2. **Walks: `additionalImageURLs`.** Each walk README lists *every* stop image
   in stop order — but each walk's hero is picked from among those same stop
   images, so the spec **hard-errors** the validator's
   `heroImageURL also appears in additionalImageURLs` check, and would render
   the same photo twice in the carousel. Montreal's walks already drop the
   hero: 6 stops → 4 gallery entries. Dubai now does too (5 → 3, 4 → 2).

   The walk READMEs predate that validator check. **Fix them before the next
   city wires in.**

## The validator nearly lied

The Python mirror of `validate-tours.swift` (no Swift toolchain on Linux) was
**self-tested against 18 injected fault classes — 18/18 caught** — before its
clean run was trusted.

Its **first revision silently parsed zero tags**, because `load_vocab` matched
`(facet: .placeType, tags: [ … ])` while `Tag.swift` actually writes
`(.placeType, [ … ])`. That produced 4,687 bogus errors across the whole
catalog, which is the only reason it got noticed — a subtler parse failure
would have passed everything and looked like success.

**A mirror validator that parses Swift source must assert a non-empty parse.**
`load_vocab` now raises if it finds 0 facets.

Final: **0 errors, 0 warnings across all 1040 tours.** 0 duplicate
tour/stop/maker ids. uuid5 scheme reverse-verified against the live
YUL/ROM/MAD/AMS/SGN makers before minting DXB.
`check-image-duplicates.py --maker DXB` clean over 72 images.

## gh-pages: the working tree is a dead end, use plumbing

A full `git fetch origin gh-pages` **times out** — the branch is a large binary
tree. A blobless fetch (`--filter=blob:none`) works. But **after that, every
index operation hangs**, because it tries to fetch missing blobs on demand:
`git checkout`, `git add`, `git diff --cached`, and a plain `git write-tree` all
died at the 2-minute mark in a `--no-checkout` worktree.

**What works — pure plumbing, no working tree at all:**

```bash
git fetch --filter=blob:none origin gh-pages
export GIT_INDEX_FILE=/tmp/x.index
git read-tree origin/gh-pages                      # instant; trees only
git hash-object -w -- <file>                       # per new blob
git update-index --add --cacheinfo 100644,<sha>,<path>
git write-tree --missing-ok                        # plain form HANGS
git commit-tree <tree> -p origin/gh-pages -m "…"
git push origin <commit>:refs/heads/gh-pages
```

Before committing, `git diff-tree -r --name-status origin/gh-pages <tree>`
confirmed **exactly 40 additions, 0 deletions, nothing outside `audio/`**.
That is the plumbing equivalent of the "never `git add -A` in a `--no-checkout`
worktree" rule — it proves the same thing directly.

## Deploy verification

The Pages deploy **lagged the push by ~9 minutes** and served 404 the whole
time. Rather than wait blind, the run was checked against the Actions API and
found **`in_progress`, not `cancelled`** — the distinction CLAUDE.md warns
about, and the reason to check rather than assume.

Then **all 40 MP3s were confirmed by hashing the downloaded bytes against the
uploaded blob SHAs**, not by the push succeeding. All **112** Dubai asset URLs
(72 images + 40 audio) live-checked **200**.

## Captions: the rule now spans paragraphs

Several Dubai scripts open with a one-sentence hook that is a bare instruction
("Walk up onto the bridge and stop wherever the rail is free."). The previous
first-paragraph-only splitter could not extend past a single-sentence opening
paragraph, so that would have shipped as the entire caption — the Rome
"Start with the holes." failure in a new guise.

Captions now absorb sentences across the whole transcript until they clear 60
characters. Shortest shipped is exactly 60. The abbreviation guard
(`St./Mt./Dr./Ave.`…) is retained even though Dubai barely needs it.

`transcriptText` = the display script with its header stripped — **two distinct
shapes this batch**: a single `DUBAI NN — …` title line (4 singles + Creek
Crossing/Old Quarter walks) and an `ATLAS — DUBAI / Walk Wn / Segment nn /
(clean version)` block terminated by `---` (Downtown/Marina walks) — plus all
**30 `[beat]` markers** removed.

## Open / owner's call

- **⚠️ Two heroes ship flagged**, at the owner's explicit prior direction,
  re-surfaced this session and left as-is:
  - `al-shindagha_hero` — googleusercontent source, licence unverifiable,
    upscaled ~1.6× from 1200×550 so visibly softer than its neighbours.
  - `difc-gate_hero` — garbled signage lettering, i.e. likely AI-generated
    rather than a photograph of the real Gate Building. **`difc-gate_2` is a
    verified photograph and is a one-line promotion.**
- **11 credit-required images** logged in `drafts/CREDITS.md` (Dubai section).
  ⚠️ `al-shindagha_2` is **FAL (Free Art License)** — copyleft, same obligation
  as BY-SA, not more permissive.
- **PR #475 (`claude/hero-verify`) also edits `drafts/AUDIO-PENDING-SURVEY.md`**,
  in the Chicago section (~line 247); this session's edits are in the PENDING
  table (~line 47) and the Dubai block (~line 173). Different regions, so a
  clean auto-merge is likely — and per the tracker's own collision rule the
  **content wire-in lands first** and the docs PR rebases onto it. #475's reuse
  audit independently confirms Dubai's 4 walks reuse the correct images.
- **Chicago's tracker block called ORD "the 21st maker"** — corrected to 22nd,
  since DXB took that slot.

## Queue after Dubai

**Berlin (36 tours / 57 MP3s) + Chicago (30 tours / 53 MP3s) = 66 tours /
110 MP3s.** Both image-complete and awaiting narration only. Both have
pick-map READMEs on `main`. **Both carry the two README errors described
above** — fix those before wiring either in.

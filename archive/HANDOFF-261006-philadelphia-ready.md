# HANDOFF 2026-10-06: Philadelphia staged, imaged (25/30) and voiced. Launch held for images

**State:** Atlas Studio PHL is ready to launch except for images. 🔴 **The owner said "dont launch the
tours until i've backfilled everything"**, and `drafts/philadelphia-batch1/tools/wire_philly.py` enforces
it: the script exits `NOT READY` until every single and walk connective has an image.

## What exists
- **Scripts and coordinates** (PR #1120):
  - 30 singles in `drafts/philadelphia-batch1/`.
  - 5 walks / 36 segments in `drafts/philadelphia-walks/`.
  - Source: the owner's OneDrive `261002_PHILADELPHIA`. The author's newest handoff is №13, in `PHILLY W5`; the root copy (№8) is stale.
  - `author/` holds №13 and its master list: judgment calls (i)–(lxii) and the pre-record flags.
  - Coordinates are the subjects' own OSM objects. `check-coordinates`: no gross errors, no bias.
- **Images** (PR #1124): 124 files on gh-pages for 25 tours, picked by the owner in the
  [Philadelphia Image Picks](https://claude.ai/artifact/Ky2zRMHBARidzPDbgzsq5B) page.
  - None needs credit: Unsplash, Pexels, and public-domain Commons.
  - Records: `image-manifest.json` (picked) and `image-candidates.json` (all 354 picker codes and their sources).
- **Audio** (this session): 66 MP3s on gh-pages, hash-verified, each transcript-matched to its own script. Recorded in `audio-manifest.json`.
- **Assembler:** `wire_philly.py`. A dry run (stand-ins for the missing images) gave 35 tours with 0 validator errors.

## What is owed (owner)
- **Images still missing:**
  - Singles: 08 Reading Terminal, 15 Congress Hall, 18 Head House, 19 Penn's Landing.
  - Walk connectives: W1-3 Lombard & Pine, W2-5 Dilworth Park, W4-4 Arch Street.
- The owner will backfill: from the picker, with their own photos, or with a fresh search.
- ⚠️ **Christ Church's only "free" candidate (picker 05-12, Pexels) is NOT Philadelphia's Christ Church.** Its steeple is a cupola with no spire, so it looks like Christ Church in Alexandria, Virginia. Never use it. The owner supplied the real one on 2026-10-07 (`christ-church-philadelphia_hero.webp`).
- The author's **pronunciation pass** was owed before recording. Nothing here confirms it. Listen for *Schuylkill*, *Lenape* and *Reading* ("redding") on device.

## How to launch
`drafts/philadelphia-batch1/README.md` § How to launch. In short:
1. Process the backfill and add its rows to `image-manifest.json`.
2. Push to gh-pages once, then hash-verify.
3. Run `wire_philly.py --created <date>`.
4. Run the checks in `HANDOFF-261002-next-city.md` §4.

Expect one place candidate: **Eastern State Penitentiary**, where the tour sits on the same point as 3 creator pins.

## Lessons from this city (image sourcing)
- **Commons `deepcat:` search is polluted.** For 23 thin subjects it pulled dancers, a road in Ohio, coins and press events. Reading each category's own files (categorymembers, depth 1) was clean. Prefer that.
- **Gemini Gate B under-recognises squares and plain brick buildings.** Rittenhouse Square, Washington Square and President's House each passed 0 photos. For Commons category members, run Gate A only and judge the subject yourself on contact sheets.
- **For famous Philadelphia landmarks, free modern photos are mostly CC BY-SA.** The owner did not pick any CREDIT NEEDED photo this time, and left those rows empty instead.
- **The Unsplash index is thin for exact landmark names.** "Rittenhouse Square" returned 1 result in total. Pexels was deeper.
- **A source script that saves only at the end loses everything on a timeout.** Save after every subject.

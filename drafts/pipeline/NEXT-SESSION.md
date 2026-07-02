# START HERE — next session (image-staging handoff, 2026-07-02)

Fresh session? Read this first, then `PROCESS.md`. Everything below is committed on
branch **`claude/dreamy-wozniak-nM6a4`**; images are on **gh-pages**. `/tmp` is gone —
re-fetch candidates as needed; pipeline scripts are in this folder (`drafts/pipeline/`).

## Immediate next action (LA tour 09)
**El Pueblo / Olvera Street** is the one unfinished LA tour. The owner is pasting their
OWN Olvera Street photos and wants **one of the street shots as the hero**. At the moment
of the previous session's end, those pastes hadn't flushed to disk yet (paste lag) AND the
image-read API had degraded. To finish it:
1. Extract the owner's latest pasted images from the transcript (see PROCESS.md "Owner-pasted
   images"); wait a turn if the distinct-count hasn't risen.
2. Read to confirm they're Olvera Street; pick the street one as hero.
3. `crop.py` → `el-pueblo-olvera-street_hero.webp` + `_2..`; push to gh-pages.
4. Update `drafts/la-batch1/README.md` (mark 09 done) — owner-supplied = no credit.

## LA status
- **Scripts received:** 01, 02, 04, 08, 09, 12, 13, 15 — all staged in `drafts/la-batch1/`.
- **Images DONE + pushed:** 01 Disney Hall, 02 The Broad, 04 Grand Central Market,
  08 Union Station, 12 Walk of Fame, 13 Chinese Theatre, 15 Hollywood Sign.
- **Pending images:** 09 El Pueblo (above).
- **Gaps not yet sent:** LA tours 03, 05, 06, 07, 10, 11, 14 (+ beyond). Owner will send more.
- **LA credit so far:** only `walt-disney-concert-hall_6.webp` (WD53 organ, Daniel Hartwig,
  CC BY 2.0). See `drafts/CREDITS.md`.
- **Maker:** create **Atlas Studio LAX** at first LA wire-in.

## Whole-app state (all audio-pending unless noted)
- **LIVE (have audio):** NYC, London, Lisbon, Porto, Hong Kong, San Francisco.
- **Toronto** — COMPLETE: 38 singles (`drafts/toronto-batch1..10`) + 4 walks
  (`toronto-{oldtown,downtownspine,museummile,kensington}-walk`). Maker: Atlas Studio YYZ.
- **Madrid** — 30 singles (`drafts/madrid-batch1..7`) + 4 walks (austrias, paseo-del-arte,
  retiro, royal). Maker: Atlas Studio MAD.
- **Paris** — 45 singles (`drafts/paris-batch1..4` on branch **`claude/paris-scripts-260622`**)
  + 5 walks (islands, leftbank, marais, montmartre, triumphalway on the dreamy branch).
  Maker: Atlas Studio PAR. NB: Paris singles are on a SEPARATE branch — consolidate before wire-in.
- **LA** — in progress (this handoff).

## Credits
Master index: `drafts/CREDITS.md` (Toronto detailed inline + per-city IMAGE-CREDITS-*.txt on
gh-pages for SF/London/Paris/Madrid/NYC). ~120 attribution-obligated images app-wide, mostly
London + SF. Surface them (per-tour line or an attributions screen) before anything ships live.

## Wire-in (how any of this goes live)
Per city: create the maker, then for each tour add a `Tours.json` entry (singles: `kind single`,
geofenced radius 40; walks: `kind multiStop`, intro stop 0 manual). Durations via `mutagen`;
`additionalImageURLs` already point at gh-pages. `swift scripts/validate-tours.swift`, merge to
main → auto-publishes to gh-pages + seeds Supabase → live to build-46+ users, no App Store review.

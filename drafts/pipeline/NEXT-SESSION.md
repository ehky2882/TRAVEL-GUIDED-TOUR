# START HERE — next session (image-staging handoff, 2026-07-06)

Fresh session? Read this first, then `PROCESS.md`. Everything below is committed on
branch **`claude/dreamy-wozniak-nM6a4`**; images are on **gh-pages**. `/tmp` is gone —
re-fetch candidates as needed; pipeline scripts are in this folder (`drafts/pipeline/`).

## Immediate next action (LA)
**LA batches 1–8 image-COMPLETE — 34 tours staged.** Batch 8 (`drafts/la-batch8/`, in progress)
= 43 The Getty Center, 44 Rodeo Drive & Beverly Hills — pushed 2026-07-06 (`242a90c`). **All ship-safe — 0 new credits.**
- **43 Getty Center:** "Getty" stock polluted with the Getty **Villa** (Roman colonnades/gardens) + a Barcelona Pavilion + Griffith Obs + Louvre Abu Dhabi — verify pixels. Hero G6 = white travertine Meier campus. NB: the Irwin **Central Garden** is NOT in the shipped set (search returned Villa gardens); add later if wanted.
- **44 Rodeo Drive:** hero R2 = iconic corner (green dome + Torso statue). Gallery = Via Rodeo lane (R37) + sign (R7) + Beverly Hills garden sign (R30). Dropped false matches: R28 (Prada = Las Vegas), R8 (Czech storefront).

Batch 7 (`drafts/la-batch7/`)
= 36 LA Memorial Coliseum, 39 The Huntington, 40 Gamble House, 41 Old Pasadena — pushed 2026-07-06 (Coliseum+Gamble `b2f4def`; Huntington `3f9cb1c`; Old Pasadena `275df5c`). **4 new credits (Huntington hero + Gamble ×3 — all CC BY-SA).**
- **36 Coliseum:** all ship-safe (Pexels); C18 hero + 4 gallery.
- **39 The Huntington:** hero is the **Huntington Art Gallery** (beige Beaux-Arts mansion) — re-sourced after owner doubted a Wrigley-Mansion look-alike. Hero UW2 = Wikimedia CC BY-SA 3.0 (Matthew Field); gallery U6/U9/U8 = Unsplash (gardens).
- **40 Gamble House:** DW20 hero + DW8/DW7/DW22; 3 of 4 are Wikimedia CC BY-SA (Cullen328 ×2, Codera23), DW22 is PD. Stock polluted with "gambling" images — verified pixels.
- **41 Old Pasadena:** HARD stock subject — most candidates were look-alikes (Mexican colonial streets, downtown LA Broadway/Globe Theatre, Hollywood backlots, Chinatown, Olvera St). Only 3 location-confirmed, all ship-safe: O2 (Colorado Blvd corner — hero), O16 (ornate facade), O17 (OLD TOWN clock).
- **Batch 6 (`drafts/la-batch6/`, pushed 2026-07-02):** 30 Venice Boardwalk, 31 Venice Canals, 34 Science Center/Endeavour, 35 NHM — all ship-safe, 0 credits.
- **Sourcing lesson (batches 2–6):** hidden/generic/ambiguously-named subjects mis-match badly (Greek Theatre→Hollywood Bowl, Capitol→CA/US Capitols, MOCA→The Broad, Science Center→Griffith Obs, NHM→London NHM) — verify pixels; owner-paste or CC-flag when ship-safe stock is wrong/absent.
**Next LA work:** wait for the owner to send more LA scripts (gaps below), then image-stage per PROCESS.md.

## LA status
- **Scripts received:** b1 = 01,02,04,08,09,12,13,15; b2 = 19,20,24,28; b3 = 03,05,06,07; b4 = 10,11,14,16; b5 = 21,22,25,29; b6 = 30,31,34,35; b7 = 36,39,40,41; b8 = 43,44 (`drafts/la-batch1..8/`).
- **Images DONE + pushed:** ALL 34 received tours (b1 ×8, b2 ×4, b3 ×4, b4 ×4, b5 ×4, b6 ×4, b7 ×4, b8 ×2).
- **Gaps not yet sent:** LA tours 17, 18, 23, 26, 27, 32, 33, 37, 38, 42 (+ beyond). Owner sends more.
- **LA credits so far (12):** WD53 (CC BY 2.0), La Brea hero (CC BY-SA 4.0), MOCA ×3 (b3), Academy Y40 (CC BY-SA 4.0, author TBD) + Greek RG3 (CC BY-SA 3.0) + RG1 (CC BY-SA 4.0); **b7: the-huntington_hero (Matthew Field CC BY-SA 3.0) + gamble-house_hero/_2/_3 (Cullen328 CC BY-SA 3.0 ×2, Codera23 CC BY-SA 4.0)**. See `drafts/CREDITS.md`.
- **Maker:** create **Atlas Studio LAX** at first LA wire-in.
- **API keys loaded this session:** Unsplash, Pexels, Pixabay all provided + verified (paste fresh next session).

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

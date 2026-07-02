# START HERE — next session (image-staging handoff, 2026-07-02)

Fresh session? Read this first, then `PROCESS.md`. Everything below is committed on
branch **`claude/dreamy-wozniak-nM6a4`**; images are on **gh-pages**. `/tmp` is gone —
re-fetch candidates as needed; pipeline scripts are in this folder (`drafts/pipeline/`).

## Immediate next action (LA)
**LA batches 1–6 ALL image-COMPLETE — 28 tours staged.** Batch 6 (`drafts/la-batch6/`)
= 30 Venice Boardwalk, 31 Venice Canals, 34 Science Center/Endeavour, 35 Natural History Museum — pushed 2026-07-02 (`c1cf0fb` for 30/31, `c47375f` for 34/35). **All ship-safe — 0 new credits.**
- **30/31 Venice:** deep clean ship-safe (verified CA not Italy).
- **34 Science Center/Endeavour:** Endeavour horizontal-display hero; new 2024 vertical config not in stock. "Science Center" stock noisy (Griffith Obs, Palm Springs museum, TX science center).
- **35 Natural History Museum:** "dueling dinosaurs" hero; NHM exterior thin in stock (dome→Griffith Obs). "Natural History Museum" mis-matches London NHM/British Museum.
- **Sourcing lesson (batches 2–6):** hidden/generic/ambiguously-named subjects mis-match badly (Greek Theatre→Hollywood Bowl, Capitol→CA/US Capitols, MOCA→The Broad, Science Center→Griffith Obs, NHM→London NHM) — verify pixels; owner-paste or CC-flag when ship-safe stock is wrong/absent.
**Next LA work:** wait for the owner to send more LA scripts (gaps below), then image-stage per PROCESS.md.

## LA status
- **Scripts received:** b1 = 01,02,04,08,09,12,13,15; b2 = 19,20,24,28; b3 = 03,05,06,07; b4 = 10,11,14,16; b5 = 21,22,25,29; b6 = 30,31,34,35 (`drafts/la-batch1..6/`).
- **Images DONE + pushed:** ALL 28 received tours (b1 ×8, b2 ×4, b3 ×4, b4 ×4, b5 ×4, b6 ×4).
- **Gaps not yet sent:** LA tours 17, 18, 23, 26, 27, 32, 33 (+ beyond). Owner sends more.
- **LA credits so far (8, unchanged — b6 added none):** WD53 (CC BY 2.0), La Brea hero (CC BY-SA 4.0), MOCA ×3 (b3), Academy Y40 (CC BY-SA 4.0, author TBD) + Greek RG3 (CC BY-SA 3.0) + RG1 (CC BY-SA 4.0). See `drafts/CREDITS.md`.
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

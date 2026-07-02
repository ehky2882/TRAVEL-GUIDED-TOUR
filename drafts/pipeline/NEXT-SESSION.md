# START HERE — next session (image-staging handoff, 2026-07-02)

Fresh session? Read this first, then `PROCESS.md`. Everything below is committed on
branch **`claude/dreamy-wozniak-nM6a4`**; images are on **gh-pages**. `/tmp` is gone —
re-fetch candidates as needed; pipeline scripts are in this folder (`drafts/pipeline/`).

## Immediate next action (LA)
**LA batches 1–5 ALL image-COMPLETE — 24 tours staged.** Batch 5 (`drafts/la-batch5/`)
= 21 Academy Museum, 22 Petersen, 25 Griffith Park/Greek Theatre, 29 Third Street Promenade — pushed 2026-07-02 (`336b527` for 21/22/25, `0f01128` for 29).
- **21 Academy Museum:** Renzo Piano sphere (Y5, ship-safe) hero; gold cylinder not in stock. Y40 gallery = CC BY-SA.
- **22 Petersen:** unmistakable red+silver ribbon building, deep ship-safe.
- **25 Griffith Park & Greek Theatre:** Greek Theatre building NOT in ship-safe stock (stock returns the Hollywood Bowl!); hero = Griffith Park vista (R11, ship-safe) + 2 CC BY-SA Greek Theatre shots (owner-OK'd).
- **29 Third Street Promenade:** first stock set owner-doubted → re-sourced (dropped car-streets/pier/beach); owner then supplied 2 own photos (hero + wide street) + Q3/Q16 stock. No credit.
- **Sourcing lesson (batches 2–5):** hidden/generic/ambiguously-named subjects mis-match badly (Greek Theatre→Hollywood Bowl, Capitol→CA/US Capitols, MOCA→The Broad) — verify pixels; owner-paste or CC-flag when ship-safe stock is wrong/absent.
**Next LA work:** wait for the owner to send more LA scripts (gaps below), then image-stage per PROCESS.md.

## LA status
- **Scripts received:** b1 = 01,02,04,08,09,12,13,15; b2 = 19,20,24,28; b3 = 03,05,06,07; b4 = 10,11,14,16; b5 = 21,22,25,29 (`drafts/la-batch1..5/`).
- **Images DONE + pushed:** ALL 24 received tours (b1 ×8, b2 ×4, b3 ×4, b4 ×4, b5 ×4).
- **Gaps not yet sent:** LA tours 17, 18, 23, 26, 27 (+ beyond). Owner sends more.
- **LA credits so far (8):** WD53 (CC BY 2.0), La Brea hero (CC BY-SA 4.0), MOCA ×3 (b3), Academy Y40 (CC BY-SA 4.0, author TBD) + Greek RG3 (CC BY-SA 3.0) + RG1 (CC BY-SA 4.0). See `drafts/CREDITS.md`.
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

# START HERE — next session (image-staging handoff, 2026-07-02)

Fresh session? Read this first, then `PROCESS.md`. Everything below is committed on
branch **`claude/dreamy-wozniak-nM6a4`**; images are on **gh-pages**. `/tmp` is gone —
re-fetch candidates as needed; pipeline scripts are in this folder (`drafts/pipeline/`).

## Immediate next action (LA)
**LA batches 1 (8 tours), 2 (4 tours), 3 (4 tours) ALL image-COMPLETE.** Batch 3 (`drafts/la-batch3/`)
= 03 MOCA Grand Ave, 05 Angels Flight, 06 Bradbury, 07 City Hall — all image-staged + pushed 2026-07-02 (`103c448`).
- **03 MOCA:** owner-OK'd CC BY-SA (M32 hero + M28/M31 gallery — all credit-logged). Isozaki building
  is deliberately hidden → not in ship-safe stock (returns The Broad/Disney/Moab); only Wikimedia CC had it.
- **05 Angels Flight / 06 Bradbury / 07 City Hall:** deep clean ship-safe stock. Bradbury hero = interior atrium.
- **La Brea / MOCA sourcing lesson:** low/hidden or generic-looking subjects mis-match badly in stock
  (wrong museums, neighbor buildings, desert "Moab") — verify pixels; iconic shots often only exist as CC BY-SA.
**Next LA work:** wait for the owner to send more LA scripts (gaps below), then image-stage per PROCESS.md.

## LA status
- **Scripts received:** batch 1 = 01,02,04,08,09,12,13,15; batch 2 = 19,20,24,28; batch 3 = 03,05,06,07 (`drafts/la-batch1..3/`).
- **Images DONE + pushed:** ALL 16 received tours (batch 1 ×8, batch 2 ×4, batch 3 ×4).
- **Gaps not yet sent:** LA tours 10, 11, 14, 16, 17, 18, 21–23, 25–27 (+ beyond). Owner sends more.
- **LA credits so far (5):** `walt-disney-concert-hall_6` (CC BY 2.0), `la-brea-tar-pits_hero` (CC BY-SA 4.0),
  `moca-grand-avenue_hero`+`_2`+`_3` (CC BY-SA 3.0 / CC BY 2.0 / CC BY-SA 4.0). See `drafts/CREDITS.md`.
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

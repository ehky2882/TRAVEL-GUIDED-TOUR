# START HERE — next session (image-staging handoff, 2026-07-02)

Fresh session? Read this first, then `PROCESS.md`. Everything below is committed on
branch **`claude/dreamy-wozniak-nM6a4`**; images are on **gh-pages**. `/tmp` is gone —
re-fetch candidates as needed; pipeline scripts are in this folder (`drafts/pipeline/`).

## Immediate next action (LA)
**LA batches 1 (×8), 2 (×4), 3 (×4), 4 (×4) ALL image-COMPLETE — 20 tours staged.** Batch 4 (`drafts/la-batch4/`)
= 10 Little Tokyo, 11 Last Bookstore, 14 Dolby Theatre, 16 Capitol Records — pushed 2026-07-02 (`e71ed38`).
- **10 Little Tokyo:** thin/noisy (stock returns Chinatown / Tokyo Japan / El Capitan) — 3 verified ship-safe.
- **11 Last Bookstore:** deep clean ship-safe (book tunnel/vortex/banking hall). 14 Dolby: owner-supplied facade hero + ship-safe gallery (clean facades were all CC).
- **16 Capitol Records:** owner rejected first stock set (a *different* round tower); correct = P53 hero (Public Domain) + P20 (Pexels), both ship-safe. "Capitol" mis-matches CA/US Capitols + a WV music hall.
- **Batch 4 = zero credit obligations** (all ship-safe / PD / owner-supplied).
- **Sourcing lesson (batches 2–4):** hidden/generic/ambiguously-named subjects mis-match badly — verify pixels; owner-paste or CC-flag when ship-safe stock is wrong or absent.
**Next LA work:** wait for the owner to send more LA scripts (gaps below), then image-stage per PROCESS.md.

## LA status
- **Scripts received:** b1 = 01,02,04,08,09,12,13,15; b2 = 19,20,24,28; b3 = 03,05,06,07; b4 = 10,11,14,16 (`drafts/la-batch1..4/`).
- **Images DONE + pushed:** ALL 20 received tours (b1 ×8, b2 ×4, b3 ×4, b4 ×4).
- **Gaps not yet sent:** LA tours 17, 18, 21, 22, 23, 25, 26, 27 (+ beyond). Owner sends more.
- **LA credits so far (5, unchanged):** `walt-disney-concert-hall_6` (CC BY 2.0), `la-brea-tar-pits_hero` (CC BY-SA 4.0),
  `moca-grand-avenue_hero`+`_2`+`_3` (CC BY-SA 3.0 / CC BY 2.0 / CC BY-SA 4.0). Batch 4 added none. See `drafts/CREDITS.md`.
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

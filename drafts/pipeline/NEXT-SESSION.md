# START HERE — next session (image-staging handoff, 2026-07-02)

Fresh session? Read this first, then `PROCESS.md`. Everything below is committed on
branch **`claude/dreamy-wozniak-nM6a4`**; images are on **gh-pages**. `/tmp` is gone —
re-fetch candidates as needed; pipeline scripts are in this folder (`drafts/pipeline/`).

## Immediate next action (LA)
**LA batch 1 COMPLETE (8 tours). LA batch 2 COMPLETE (4 tours).** Batch 2 (`drafts/la-batch2/`)
= 19 LACMA, 20 La Brea, 24 Griffith, 28 Santa Monica — all image-staged + pushed 2026-07-02
(`ea793bb` Griffith/SantaMonica/LaBrea-hero, `72c0176` LACMA).
- **19 LACMA:** owner pasted 2 photos of the finished Zumthor David Geffen Galleries (hero = ribbon
  across Wilshire + Urban Light; `_2` = concrete-underside detail) + L25/L27 Urban Light stock gallery.
- **20 La Brea:** hero-only, W8 CC BY-SA 4.0 (owner-OK'd; credit logged).
- **24 Griffith / 28 Santa Monica:** deep clean stock, hero + 5 gallery each.
- **La Brea sourcing lesson (logged in batch-2 README):** stock "La Brea Tar Pits" returns WRONG
  museums (mammoth skeletons look alike) — verify pixels; the good iconic shots are all CC BY-SA.
**Next LA work:** wait for the owner to send more LA scripts (gaps below), then image-stage per PROCESS.md.

## LA status
- **Scripts received:** batch 1 = 01,02,04,08,09,12,13,15 (`drafts/la-batch1/`); batch 2 = 19,20,24,28 (`drafts/la-batch2/`).
- **Images DONE + pushed:** batch 1 all 8; batch 2 all 4 (19 LACMA, 20 La Brea hero-only, 24 Griffith, 28 Santa Monica).
- **Gaps not yet sent:** LA tours 03, 05, 06, 07, 10, 11, 14, 16, 17, 18, 21–23, 25–27 (+ beyond). Owner sends more.
- **LA credit so far:** `walt-disney-concert-hall_6.webp` (WD53, CC BY 2.0) + `la-brea-tar-pits_hero.webp`
  (Downtowngal, CC BY-SA 4.0). See `drafts/CREDITS.md`.
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

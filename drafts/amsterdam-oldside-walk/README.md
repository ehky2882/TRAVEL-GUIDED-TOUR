# Amsterdam — Old Side multi-stop WALK (image-staging COMPLETE — zero new images)

The second Amsterdam **multi-stop walk** — the medieval port / "tolerance ledger": Centraal Station →
Zeedijk/Nieuwmarkt → Oude Kerk → De Wallen → Our Lord in the Attic → Dam. ~2 km, ~60 min. Every stop
reuses a hero already staged + live from the single-stop tours, so **no new image sourcing was needed.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (`00_intro.txt`) — manual trigger, `introAudioURL: null`, plays at start in front of Centraal.
- **Stops 1–6** — geofenced, radius **40 m**.
- **Audio:** owner records 7 MP3s (intro + 6 stops); slug stems = the `.txt` filenames here
  (`amsterdam_oldside_multistop_00_intro.mp3`, `…_01_centraal_station.mp3`, …).
- **⚠️ Sensitivity:** stop 4 (De Wallen) passes through the red-light district; the reused
  `de-wallen_hero` is the clean gabled-house-fronts frame (no red-light content), consistent with the
  single-stop tour. The narration gives the on-the-ground rules.

## Stops → reused hero (one image per stop, in order)
| # | Stop | script | reused image (already live) | coord |
|---|------|--------|-----------------------------|-------|
| 0 | Intro (front of Centraal) | `00_intro` | — (walk hero, below) | — |
| 1 | Centraal Station | `01_centraal_station` | `centraal-station_hero.webp` | `52.37900, 4.90020` |
| 2 | Zeedijk / Nieuwmarkt | `02_zeedijk_nieuwmarkt` | `zeedijk-chinatown_hero.webp` (alt: `nieuwmarkt-de-waag_hero.webp`) | `52.37320, 4.90030` |
| 3 | Oude Kerk | `03_oude_kerk` | `oude-kerk_hero.webp` | `52.37440, 4.89810` |
| 4 | De Wallen | `04_de_wallen` | `de-wallen_hero.webp` | `52.37360, 4.89750` |
| 5 | Our Lord in the Attic | `05_our_lord_in_the_attic` | `our-lord-in-the-attic_hero.webp` | `52.37490, 4.89870` |
| 6 | Dam Square | `06_dam_square` | `dam-square-royal-palace_hero.webp` | `52.37310, 4.89135` |

- **heroImageURL (walk):** `oude-kerk_hero.webp` (the oldest building — the heart of the old side). **Owner-confirmed.**
- **additionalImageURLs** (6, in stop order): `centraal-station_hero.webp`, `zeedijk-chinatown_hero.webp`, `oude-kerk_hero.webp`, `de-wallen_hero.webp`, `our-lord-in-the-attic_hero.webp`, `dam-square-royal-palace_hero.webp`.
- **Credit:** Oude Kerk hero + Our Lord in the Attic hero are Wikimedia **CC** (already logged in `drafts/CREDITS.md` from the single-stop tours — inherited, no new credit). The other 4 reused images are ship-safe. Net: this walk inherits 2 existing credits, adds none.

## Wire-in checklist (do when audio arrives)
1. Under maker **Atlas Studio AMS**, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ams:old-side-walk`; stops `atlas-stop:ams:old-side-walk:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (trim outer whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`.
   - Stops 1–6: `triggerMode: geofenced`, `radiusMeters: 40`, coords above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 6 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~2000** (intro says "about two kilometres").
   - `centroid` (avg of stops 1–6): **`52.37470, 4.89769`**.
   - Category: `culturalHeritage` (or `history`).
2. `swift scripts/validate-tours.swift` → fix any errors.
3. Credits: the 2 inherited CC images are already in `drafts/CREDITS.md` — nothing new to log.

## Note
- Stop 2 combines **Zeedijk + Nieuwmarkt** (the sea-dike/Chinatown into the Nieuwmarkt square). Default image = the Zeedijk/He-Hua-Temple hero; swap to `nieuwmarkt-de-waag_hero` if you'd rather the stop show De Waag.
- The single-stop tours reused here (Centraal #37, Zeedijk #07, Oude Kerk #04, De Wallen #03, Our Lord #05, Dam Square #01) stay separate; the walk has its own per-stop narration, only the images are shared.

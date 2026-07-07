# Amsterdam — Jordaan multi-stop WALK (image-staging COMPLETE — zero new images)

The fourth Amsterdam **multi-stop walk** — the workers' quarter that became the most-loved:
Westerkerk/Anne Frank → Homomonument → Jordaan & hofjes → Noordermarkt → Brouwersgracht. ~2 km, ~60 min.
Every stop reuses a hero already staged + live from the single-stop tours, so **no new image sourcing.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (`00_intro.txt`) — manual trigger, `introAudioURL: null`, plays on Westermarkt.
- **Stops 1–5** — geofenced, radius **40 m**.
- **Audio:** owner records 6 MP3s (intro + 5 stops); slug stems = the `.txt` filenames here
  (`amsterdam_jordaan_multistop_00_intro.mp3`, `…_01_westerkerk_anne_frank.mp3`, …).
- **⚠️ Sensitivity:** stop 1 (Anne Frank House) + stop 2 (Homomonument) are handled respectfully — the
  reused heroes are the dignified exteriors/memorial, consistent with the single-stop tours.

## Stops → reused hero (one image per stop, in order)
| # | Stop | script | reused image (already live) | coord |
|---|------|--------|-----------------------------|-------|
| 0 | Intro (Westermarkt) | `00_intro` | — (walk hero, below) | — |
| 1 | Westerkerk + Anne Frank House | `01_westerkerk_anne_frank` | `westerkerk_hero.webp` (alt: `anne-frank-house_hero.webp`) | `52.37470, 4.88390` |
| 2 | Homomonument | `02_homomonument` | `homomonument_hero.webp` | `52.37430, 4.88420` |
| 3 | Jordaan & hofjes | `03_jordaan_hofjes` | `jordaan_hero.webp` | `52.37460, 4.88190` |
| 4 | Noordermarkt | `04_noordermarkt` | `noordermarkt-brouwersgracht_hero.webp` (the Noorderkerk) | `52.37870, 4.88600` |
| 5 | Brouwersgracht | `05_brouwersgracht` | `noordermarkt-brouwersgracht_2.webp` (the canal warehouses) | `52.38040, 4.88900` |

_(Neat fit: single-stop tour #22 "Noordermarkt / Brouwersgracht" has hero = Noorderkerk and `_2` = Brouwersgracht, which split exactly across walk stops 4 and 5.)_

- **heroImageURL (walk):** proposed `jordaan_hero.webp` (JD11 — the Westertoren over a canal with a bike, the quintessential Jordaan; also anchors the walk's start). Alt: `westerkerk_hero.webp` (the tower). **Owner to confirm.**
- **additionalImageURLs** (5, in stop order): `westerkerk_hero.webp`, `homomonument_hero.webp`, `jordaan_hero.webp`, `noordermarkt-brouwersgracht_hero.webp`, `noordermarkt-brouwersgracht_2.webp`.
- **Credit:** inherits **3 existing CC credits** (Homomonument hero, Noordermarkt/Noorderkerk hero, Brouwersgracht `_2`) — already logged in `drafts/CREDITS.md` from the single-stop tours; **adds none**. Westerkerk + Jordaan heroes are ship-safe.

## Wire-in checklist (do when audio arrives)
1. Under maker **Atlas Studio AMS**, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ams:jordaan-walk`; stops `atlas-stop:ams:jordaan-walk:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (trim outer whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, coords above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 5 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~2000** (intro says "about two kilometres").
   - `centroid` (avg of stops 1–5): **`52.37654, 4.88500`**.
   - Category: `culturalHeritage` (or `history`).
2. `swift scripts/validate-tours.swift` → fix any errors.
3. Credits: the 3 inherited CC images are already in `drafts/CREDITS.md` — nothing new to log.

## Note
- Single-stop tours reused here (Westerkerk #19, Anne Frank House #18, Homomonument #20, Jordaan #21,
  Noordermarkt/Brouwersgracht #22) stay separate; the walk has its own per-stop narration, only the images are shared.

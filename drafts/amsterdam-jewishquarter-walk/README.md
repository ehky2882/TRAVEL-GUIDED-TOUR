# Amsterdam — Jewish Quarter multi-stop WALK (image-staging COMPLETE — zero new images)

The fifth Amsterdam **multi-stop walk** — "the quietest walk in the city," about memory:
Waterlooplein/Rembrandt House → Portuguese Synagogue → Names Monument → Hollandsche Schouwburg/Holocaust Museum → Hortus Botanicus. ~1.5 km, ~45 min.
Every stop reuses a hero already staged + live from the single-stop tours, so **no new image sourcing.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (`00_intro.txt`) — manual trigger, `introAudioURL: null`, plays at Waterlooplein.
- **Stops 1–5** — geofenced, radius **40 m**.
- **Audio:** owner records 6 MP3s (intro + 5 stops); slug stems = the `.txt` filenames here
  (`amsterdam_jewishquarter_multistop_00_intro.mp3`, `…_01_waterlooplein_rembrandt_house.mp3`, …).
- **⚠️ Sensitivity:** this is a memorial walk — the Portuguese Synagogue, the Names Monument and the
  Hollandsche Schouwburg / National Holocaust Museum are handled with dignity. The reused heroes are
  the dignified exteriors / memorial architecture / name-walls, consistent with the single-stop tours
  (no graphic imagery — memorial architecture only).

## Stops → reused hero (one image per stop, in order)
| # | Stop | script | reused image (already live) | coord |
|---|------|--------|-----------------------------|-------|
| 0 | Intro (Waterlooplein) | `00_intro` | — (walk hero, below) | — |
| 1 | Waterlooplein & the Rembrandt House | `01_waterlooplein_rembrandt_house` | `waterlooplein-rembrandt-house_hero.webp` (Rembrandt House front facade) | `52.36940, 4.90140` |
| 2 | Portuguese Synagogue | `02_portuguese_synagogue` | `portuguese-synagogue_hero.webp` (Esnoga exterior brick block) | `52.36760, 4.90520` |
| 3 | National Holocaust Names Monument | `03_names_monument` | `names-monument_hero.webp` (wall + "Namenmonument") | `52.36560, 4.90680` |
| 4 | Hollandsche Schouwburg / Holocaust Museum | `04_schouwburg_holocaust_museum` | `hollandsche-schouwburg-holocaust-museum_hero.webp` (memorial theatre facade) | `52.36620, 4.91060` |
| 5 | Hortus Botanicus / Plantage | `05_hortus` | `hortus-botanicus-plantage_hero.webp` (glasshouse) | `52.36680, 4.90880` |

_(Every one of these five single-stop tours (#31–#35 in the batch) already has a live, owner-picked hero — the Jewish Quarter walk simply chains them in walking order.)_

- **heroImageURL (walk):** `portuguese-synagogue_hero.webp` (PS44 — the vast plain-brick Esnoga, the district's enduring landmark and the walk's calm centre). **Owner-confirmed.** (`names-monument_hero.webp` still serves as stop 3's image.)
- **additionalImageURLs** (5, in stop order): `waterlooplein-rembrandt-house_hero.webp`, `portuguese-synagogue_hero.webp`, `names-monument_hero.webp`, `hollandsche-schouwburg-holocaust-museum_hero.webp`, `hortus-botanicus-plantage_hero.webp`.
- **Credit:** inherits **3 existing CC credits** (Waterlooplein/Rembrandt House hero, Portuguese Synagogue hero, Names Monument hero) — already logged in `drafts/CREDITS.md` from the single-stop tours; **adds none**. Hollandsche Schouwburg hero is PD; Hortus hero is ship-safe stock.

## Wire-in checklist (do when audio arrives)
1. Under maker **Atlas Studio AMS**, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ams:jewishquarter-walk`; stops `atlas-stop:ams:jewishquarter-walk:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (trim outer whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, coords above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 5 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~1500** (intro: "short, flat and unhurried… five stops, all within a few minutes of each other").
   - `centroid` (avg of stops 1–5): **`52.36712, 4.90656`**.
   - Category: `culturalHeritage` (or `history`).
2. `swift scripts/validate-tours.swift` → fix any errors.
3. Credits: the 3 inherited CC images are already in `drafts/CREDITS.md` — nothing new to log.

## Note
- Single-stop tours reused here (Waterlooplein/Rembrandt House #31, Portuguese Synagogue #32,
  Names Monument #33, Hollandsche Schouwburg/Holocaust Museum #34, Hortus Botanicus #35) stay separate;
  the walk has its own per-stop narration, only the images are shared.
- This is the 5th and final Amsterdam walk. Grand total staged: **33 single-stop tours + 5 multi-stop walks.**

# 🇺🇸 Chicago — batch 1 master pick-map

**Status: tours 01–08 image-staging COMPLETE — awaiting narration MP3s. Scripts 09–16 staged, images pending.**
New maker **Atlas Studio ORD** 🇺🇸 — the 21st maker. Maker id (uuid5 of `atlas-maker:ord`): `f34cd76e-1e41-5c38-865d-d8eccd775cd3`.

Single source of truth for slug ↔ coordinate ↔ category ↔ hero/gallery. Scripts sit beside this file: `NN_<slug>.txt` is the narration that becomes `transcriptText`; `NN_<slug>_TTS.txt` is the voice-direction variant and is **not** the transcript.

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/` · **audio slug = the `slug` column** (`audio/<slug>.mp3`).

## Tours 01–08 — images complete

| # | Tour | slug | script | category | coord | images | tags | credit |
|---|------|------|--------|----------|-------|--------|------|--------|
| 01 | Cloud Gate (The Bean) | `cloud-gate` | `01_cloud_gate` | `visualArt` | `41.88265, -87.62325` | hero + 3 | Monument, Art, Contemporary, Iconic Landmark, Public Art, Free to Visit | — |
| 02 | The Chicago Riverwalk at DuSable Bridge ⚠️ see Sensitivity | `dusable-bridge-riverwalk` | `02_dusable_bridge_riverwalk` | `history` | `41.88870, -87.62450` | hero + 3 | Bridge, Engineering, History, Free to Visit | — |
| 03 | The Art Institute | `art-institute` | `03_art_institute` | `culturalHeritage` | `41.87965, -87.62375` | hero + 2 | Museum, Art, Beaux-Arts, Iconic Landmark, Renzo Piano | — (`_3` owner-supplied) |
| 04 | Willis Tower ⚠️ see Vantage | `willis-tower` | `04_willis_tower` | `architecture` | `41.87860, -87.63760` | hero + 3 | Tower, Architecture, Modernist, Iconic Landmark | — |
| 05 | The Historic Water Tower | `historic-water-tower` | `05_historic_water_tower` | `history` | `41.89725, -87.62445` | hero + 2 | Monument, History, Victorian, Free to Visit | **`_2` + `_3` CC** — see CREDITS |
| 06 | The Wrigley Building & Tribune Tower | `wrigley-tribune` | `06_wrigley_tribune` | `architecture` | `41.88960, -87.62430` | hero + 2 | Notable Building, Architecture, Gothic, Iconic Landmark | — |
| 07 | Buckingham Fountain | `buckingham-fountain` | `07_buckingham_fountain` | `culturalHeritage` | `41.87575, -87.61885` | hero + 3 | Monument, Art, Beaux-Arts, Free to Visit, After Dark | — |
| 08 | Marina City ⚠️ see Vantage | `marina-city` | `08_marina_city` | `architecture` | `41.88760, -87.63430` | hero + 4 | Notable Building, Architecture, Modernist, Engineering | — |

## Tours 09–16 — scripts staged, images pending

`09_the_rookery` · `10_pritzker_pavilion` · `11_navy_pier` · `12_michigan_avenue_streetwall` · `13_cultural_center` · `14_daley_plaza_picasso` · `15_monadnock_building` · `16_lasalle_canyon_board_of_trade`

## ⚠️ transcriptText — strip the header block

**Every Chicago script opens with a four-line header terminated by a `---` rule:**

```
ATLAS — CHICAGO
Stop 04: Willis Tower (exterior street vantage)
T1 Essentials | Clean version

---
```

`transcriptText` starts **after** the `---`. Also drop `[beat]` lines and trim whitespace. This is the same trap that caught the Dubai walks; it is recorded here so no wire-in session rediscovers it.

## ⚠️ Vantage — two tours geofence where the listener stands, not at the landmark

| Tour | Script sends you to | Geofence coord (used) | Landmark itself |
|------|--------------------|----------------------|-----------------|
| 04 Willis Tower | Wacker Drive between Adams and Jackson, looking up | `41.87860, -87.63760` | `41.87880, -87.63590` (~150 m away) |
| 08 Marina City | Wacker Drive / Riverwalk, south bank, looking north across the river | `41.88760, -87.63430` | `41.88815, -87.63430` (~60 m away) |

Both scripts open by placing the listener at a specific vantage — Willis explicitly ('step back toward the river … look up until the building stops'), Marina City implicitly ('somewhere along Wacker Drive or the Riverwalk with a clear view north'). At the catalog-standard **30 m** radius the difference matters for Willis: geofencing the tower base would fire the audio ~150 m from where the narration assumes you are.

## ⚠️ Sensitivity — tour 02

Script 02 is pointedly critical of the **Fort Dearborn relief** on the DuSable Bridge's southwest tower, whose 1920s sculptors 'treated the removal of the Potawatomi from this land as an adventure story.' **Do not use that relief as the hero or a gallery image.** The staged set is bridge, bascule leaves, corner tower houses and Riverwalk only. The tour also names Jean Baptiste Point DuSable, the city's first non-Native permanent settler — handle both with the same care applied to Berlin's memorials and Amsterdam's Jewish Quarter.

## Wire-in checklist (when audio arrives)

1. Create maker **Atlas Studio ORD** 🇺🇸 (id above; 21st maker).
2. Add each tour `kind: single`, ids `atlas-tour:ord:<slug>` / `atlas-stop:ord:<slug>` (uuid5, `NAMESPACE_URL`).
   - One stop, `order: 0`, `triggerMode: geofenced`, `radiusMeters: 30` (catalog-wide city-launch default).
   - Stop `imageURL: null`; the tour carries `heroImageURL` + `additionalImageURLs`.
   - `city: "Chicago"`; `priceUSD: 0`; `introAudioURL: null`; `walkingDistanceMeters: null`.
   - `centroidLatitude`/`centroidLongitude` = the coord above.
   - `totalDurationSeconds` read from the delivered MP3 — do not estimate.
3. `swift scripts/validate-tours.swift` before pushing; merge auto-publishes to gh-pages + Supabase.
4. Surface `drafts/CREDITS.md` (Chicago section).

## Images

Filenames follow the convention `<slug>_hero.webp`, then `<slug>_2.webp` … `<slug>_N.webp` in gallery order — all 1200×900 WebP q82, live on `gh-pages`, coverage verified.

**Credit exposure is 2 images out of 33.** Only `historic-water-tower_2` (Ed Schipul, CC BY-SA 2.0) and `historic-water-tower_3` (Joi Ito, CC BY 2.0) owe attribution; both were resolved by **SHA-1 reverse-lookup** against the Commons `allimages` API, never by dimension match. Everything else is ship-safe stock, plus one owner-supplied image: `art-institute_3.webp`, the Modern Wing (Renzo Piano, 2009) — which is why tour 03 carries the **Renzo Piano** architect tag.

## Sourcing notes

Thin subjects needed a Wikimedia Commons pass because stock searches returned the wrong thing entirely:

- **Art Institute** — stock returned Tribune Tower, the Field Museum, the Chicago Theatre, a zoo manhole cover, a drive-in called *Art's*, and actual lions in a zoo enclosure.
- **Willis Tower** — mostly generic skylines, several showing the John Hancock Center instead, and almost nothing from the street-level Wacker vantage the script asks for.
- **Water Tower** — lighthouses, Tribune Tower, rooftop water tanks and University of Chicago buildings; roughly two genuine hits in 45.
- **The Rookery** (tour 09) — 'Rookery' pulled Frank Lloyd Wright's Guggenheim and Fallingwater, prairie houses, and literal rookeries (egrets).
- **Modern Wing** — the Commons category is lowercase `Art Institute of Chicago modern wing`, not the title-case name; guessing the category name wasted a fetch. Search for the category, don't assume it.

Always verify the pixels; never trust a result title.

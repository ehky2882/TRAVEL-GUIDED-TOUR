# 🇦🇪 Dubai — batch 1 master pick-map (22 single-stop tours)

**Status: image-staging COMPLETE — awaiting narration MP3s.** New maker **Atlas Studio DXB** 🇦🇪 (`atlas-maker:dxb`).

This is the single source of truth for slug ↔ coordinate ↔ category ↔ hero/gallery. Scripts live beside this file (`NN_<slug>.txt` = the narration copy that becomes `transcriptText`; `NN_<slug>_TTS.txt` = the voice-direction variant, **not** the transcript).

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/` · **audio slug = the `slug` column** (MP3 stem, `audio/<slug>.mp3`).

## Tours

| # | Tour | slug | script | category | coord | images | tags | credit |
|---|------|------|--------|----------|-------|--------|------|--------|
| 01 | Al Fahidi Historical Neighbourhood | `al-fahidi` | `01_al_fahidi` | `culturalHeritage` | `25.26370, 55.29790` | hero + 3 | District, History, Free to Visit | — |
| 02 | The Abra Crossing | `abra-crossing` | `02_abra_crossing` | `culturalHeritage` | `25.26400, 55.29470` | hero + 3 | Waterfront, Maritime, Free to Visit | — |
| 03 | The Gold Souk | `gold-souk` | `03_gold_souk` | `culturalHeritage` | `25.27140, 55.29750` | hero + 3 | Market, Commerce, Free to Visit | **hero + _3 CC** — see CREDITS |
| 04 | The Spice Souk | `spice-souk` | `04_spice_souk` | `culturalHeritage` | `25.26810, 55.29610` | hero + 3 | Market, Commerce, Free to Visit | — (hero owner-supplied) |
| 05 | Al Seef | `al-seef` | `05_al_seef` | `culturalHeritage` | `25.26050, 55.29970` | hero + 1 | Waterfront, Commerce, Free to Visit | — |
| 06 | Burj Khalifa | `burj-khalifa` | `06_burj_khalifa` | `architecture` | `25.19720, 55.27440` | hero + 3 | Tower, Architecture, Contemporary, Iconic Landmark | — |
| 07 | The Dubai Fountain | `dubai-fountain` | `07_dubai_fountain` | `musicAndPerformance` | `25.19540, 55.27460` | hero + 3 | Public Square, Performance, After Dark, Free to Visit | — |
| 08 | Museum of the Future | `museum-of-the-future` | `08_museum_of_the_future` | `architecture` | `25.21930, 55.28210` | hero + 3 | Notable Building, Architecture, Contemporary, Iconic Landmark | — |
| 09 | Jumeirah Mosque | `jumeirah-mosque` | `09_jumeirah_mosque` | `sacredSites` | `25.23350, 55.26580` | hero + 2 | Religious Building, Faith, Iconic Landmark | **all 3 CC** — see CREDITS |
| 10 | Etihad Museum | `etihad-museum` | `10_etihad_museum` | `history` | `25.23960, 55.28270` | hero + 1 | Museum, History, Contemporary | **_2 CC** — see CREDITS |
| 11 | The Textile Souk | `textile-souk` | `11_textile_souk` | `culturalHeritage` | `25.26300, 55.29610` | hero + 2 | Market, Commerce, Free to Visit | **hero CC** — see CREDITS |
| 12 | Al Shindagha | `al-shindagha` | `12_al_shindagha` | `history` | `25.26800, 55.29010` | hero + 1 | District, History, Maritime | **_2 CC (FAL)** — see CREDITS; ⚠️ hero flagged below |
| 13 | Al Fahidi Fort (Dubai Museum) | `al-fahidi-fort` | `13_al_fahidi_fort` | `history` | `25.26350, 55.29720` | hero + 2 | Museum, History | **all 3 CC** — see CREDITS |
| 14 | The Dhow Wharfage | `dhow-wharfage` | `14_dhow_wharfage` | `culturalHeritage` | `25.26630, 55.30630` | hero only | Waterfront, Maritime, Commerce, Free to Visit | — (hero only) |
| 15 | Dubai Frame | `dubai-frame` | `15_dubai_frame` | `architecture` | `25.23520, 55.30040` | hero + 4 | Tower, Architecture, Contemporary, Viewpoint | — |
| 16 | The DIFC Gate | `difc-gate` | `16_difc_gate` | `architecture` | `25.20890, 55.28170` | hero + 1 | Notable Building, Architecture, Commerce | — (hero owner-supplied; ⚠️ flagged below) |
| 17 | Alserkal Avenue | `alserkal-avenue` | `17_alserkal_avenue` | `visualArt` | `25.14360, 55.22750` | hero only | District, Art, Contemporary, Hidden Gem | — (CC0; hero only) |
| 18 | Kite Beach | `kite-beach` | `18_kite_beach` | `natureAndParks` | `25.18150, 55.22030` | hero + 3 | Waterfront, Maritime, Free to Visit | — |
| 19 | Madinat Jumeirah | `madinat-jumeirah` | `19_madinat_jumeirah` | `architecture` | `25.13400, 55.18490` | hero + 3 | District, Architecture, Commerce | — |
| 20 | The Marina Walk | `marina-walk` | `20_marina_walk` | `architecture` | `25.08110, 55.14060` | hero + 2 | Waterfront, Architecture, Contemporary, Free to Visit | — |
| 21 | JBR — The Beach | `jbr-the-beach` | `21_jbr_the_beach` | `natureAndParks` | `25.07740, 55.13210` | hero + 3 | Waterfront, Commerce, Free to Visit | — |
| 22 | Palm West Beach | `palm-west-beach` | `22_palm_west_beach` | `natureAndParks` | `25.11170, 55.13710` | hero + 2 | Waterfront, Engineering, Free to Visit | — |

**Image filenames** follow the standard convention: `<slug>_hero.webp`, then `<slug>_2.webp` … `<slug>_N.webp` in gallery order (all 1200×900 WebP q82, live on `gh-pages`).

## Wire-in checklist (when audio arrives)

1. Create maker **Atlas Studio DXB** 🇦🇪 — `atlas-maker:dxb` (uuid5, `NAMESPACE_URL`). 20th maker.
2. Add 22 tours, `kind: single`, ids `atlas-tour:dxb:<slug>` / `atlas-stop:dxb:<slug>` (uuid5).
   - One stop, `order: 0`, `triggerMode: geofenced`, `radiusMeters: 30` (catalog-wide city-launch default).
   - Stop `imageURL: null`; the tour carries `heroImageURL` + `additionalImageURLs`.
   - `city: "Dubai"`; `priceUSD: 0`; `introAudioURL: null`; `walkingDistanceMeters: null`.
   - `centroidLatitude`/`centroidLongitude` = the stop coord above.
   - `totalDurationSeconds` read from the delivered MP3 (do not estimate).
   - ⚠️ **`transcriptText` = the `.txt` body with the title line and any `[beat]` / direction lines stripped.** Several Dubai scripts open with the tour title on line 1 — it is a heading, not narration; leaving it in double-prints the title in the app.
3. Run `swift scripts/validate-tours.swift` before pushing; merge auto-publishes to gh-pages + Supabase.
4. Surface `drafts/CREDITS.md` (Dubai section) — 11 CC-credited images.

## ⚠️ Provenance flags (raised at staging, shipped at the owner's explicit direction)

> **One of the two flags below has since been withdrawn as mistaken — see the DIFC entry.**

- **`al-shindagha_hero.webp`** — owner-supplied from a `googleusercontent.com` link. Source resolution was **1200×550**, so reaching 1200×900 required ~1.6× vertical upscale; it will look softer than every other hero. The link also carries no resolvable licence. Flagged at the time; the owner reviewed and reaffirmed this image over the sourced alternative (SHN12). **Swap is one line if it reads badly on device.**
- **`difc-gate_hero.webp`** — owner-supplied. **This was previously flagged here as "likely AI-generated". That flag was WRONG and is withdrawn (2026-07-29).** Re-examined at full size: the architecture is the DIFC Gate Building exactly and specifically — the trabeated arch, the lattice glazing in the opening, Gate Avenue's parterre hedges, and the Sheikh Zayed Road towers behind — and the Arabic on the advertising banner (*اتخذ قرارات استثمارية صائبة*) is crisply and correctly formed, which generative models reliably mangle. The "garbled lettering" that prompted the flag is a ~150-px wayfinding pillar, illegible purely because of resolution. **It is a genuine photograph of the correct subject; nothing needs changing.** (`difc-gate_2.webp` / DIG31 remains a good gallery shot.)
- **Lesson:** judge a supplied image at full size before calling it synthetic. A cropped corner of any photograph looks like nothing in particular, and small signage is illegible in every real photo too.

## Notes

- **Souks:** the owner's standing instruction is **place/architecture over product** — arcade, lane and shopfront views rather than close-ups of the goods. Gold and Spice Souk were re-sourced from Wikimedia Commons specifically to satisfy this; keep it in mind for any future souk imagery.
- **Sensitivity:** Jumeirah Mosque uses dignified exteriors only.
- The 4 Dubai walks are staged separately — `drafts/dubai-{creekcrossing,oldquarter,downtown,marinajbr}-walk/`, each with its own README wire-in spec. They reuse the heroes above except for two walk-only stop images (`dubai-downtown_stop3.webp` = Souk Al Bahar bridge, `dubai-marinajbr_stop2.webp` = the Marina→JBR seam).

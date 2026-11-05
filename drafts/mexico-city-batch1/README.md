# Mexico City batch 1: Atlas Studio MEX (35 singles), wired 2026-11-05

Source: contributor drop (Dropbox, arthur.yung). 35 `output <Name> <lat>, <lon>` folders with scripts numbered 01–36
(19 is absent from the drop). Each folder holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt`, one MP3 (96–121 s)
and 1–8 photos at 1200×900 WebP (164 delivered). Accented letters in folder and image names arrived as `#Uxxxx`
escapes, so the assembler matches folders by **script number**.

`scripts/` holds both texts as delivered. `coordinates.tsv` lists slug · lat · lon · radius · category · city, as wired.

`tools/wire_mexico_city.py` is the assembler (`python3 -I wire_mexico_city.py <unzipped drop> <stage dir>`), adapted
from `drafts/athens-batch1/tools/wire_athens.py`. Run it once only: it refuses colliding tour ids. Slugs carry a
**`mex-` prefix**: audio at `audio/mex-<slug>.mp3`, images at `images/mex-<slug>_hero.webp`, `_2.webp`, … in the drop's order.

- **Maker:** Atlas Studio MEX 🇲🇽, platform `dozent`, handle `atlas.mex`, uuid5 `atlas-maker:mex`
  = `04e05651-d6d0-514e-9724-ccffca65d17f`.
- **Ids:** `atlas-tour:mex:mex-<slug>`, stops `atlas-stop:mex:mex-<slug>:1`.

## Coordinates
Four folder-name coordinates were not at their venue and were corrected:

| Tour | Drop point | Wired point |
|---|---|---|
| LAGO | Calle Nápoles 45, Colonia Juárez (~4 km off) | 19.417232, -99.199780: OSM restaurant node on the Lago Mayor shore, 2nd Section |
| Issi | Cerrada Monte Tauro (~770 m N) | 19.41066, -99.21776: midpoint of Calle Mayorga (a ~100 m street; venue at no. 118) |
| UNAM | ~700 m S of the Central Library | 19.33335, -99.18645: the lawn just east of the library (OSM library 19.3334, -99.1873) |
| Bosque de Chapultepec | Zoo enclosures, ~380 m W of the lake | 19.42280, -99.18440: east shore of the 1st Section boating lake, castle to the east |

`check-coordinates.py --drop` showed no directional bias (19/31 north, median +9.7 m, p = 0.28). Reverse geocoding
put the other 31 on the street their script names, within a building or two of the stated number. Arca Tierra sits at
the Cuemanco canal, while the script stands the listener on a chinampa reached by trajinera. It may fire at the landing.

## Wiring
- **City:** `Mexico City` for all 35 (Xochimilco, Coyoacán and the other boroughs are part of the city). Country `Mexico`.
- **Geofence:** 25 m for venues, 30 m for hotels, small museums and San Ángel, 40 m for the larger museums, Vasconcelos,
  Camino Real and LAGO, 50 m for markets, squares, Arca Tierra and Anthropology, 60 m for Alameda, Chapultepec and UNAM,
  80 m for the Zócalo. No two of the 35 circles overlap.
- **Bilingual `English | Español`** on 8 (Vasconcelos Library, Chapultepec Park, Jamaica Market, the Rivera–Kahlo
  House-Studio, Anthropology, Tamayo, UNAM, Garibaldi). Brand names, and names used as-is in English (Alameda Central,
  Zócalo, Museo Jumex), keep one.
- **Text:** `longDescription` = hook + paragraph 3, `shortDescription` cut at 145 characters, `[beat]` stripped.
  Captions written by hand from each script's orientation paragraph.
- **Photos:** 163 shipped. The drop's `lago-2` was byte-identical to `bosque-de-chapultepec_2` (an aerial of the
  lakes that does not show LAGO's roof). It stays with the park and is skipped for LAGO.

## Architect tags (Job 5): 14 new names, one line in each list
Alberto Kalach (Vasconcelos, Kurimanzutto) · Ambrosi Etchegaray (Círculo Mexicano) · Ricardo Legorreta (Camino Real) ·
Javier Sánchez (CondesaDF restoration) · Alfonso Ramírez Ponce (LAGO) · PPAA (Lamartine, Octavia Casa, Sandra Weil) ·
Juan O'Gorman (Casa Estudio, UNAM library) · Pedro Ramírez Vázquez, Jorge Campuzano, Rafael Mijares (Anthropology) ·
Teodoro González de León, Abraham Zabludovsky (Tamayo) · Mario Pani, Enrique del Moral (UNAM). Existing tag used:
David Chipperfield (Jumex).
**Not** tagged: Naso (LAGO's 2022 renovation; the contributor said no), India Mahdavi and Savvy (interiors), Mathias
Goeritz, Isamu Noguchi and Luis Barragán (art at Camino Real, not the building), Félix Candela (LAGO's architect's
teacher), Pedro Reyes (Carla Fernández's flagship, not this shop).

## Places
None created or joined. Two same-name pairs (Vasconcelos, Tamayo) and the Tláloc/Anthropology part-vs-whole
question are on Edward's board (`status/owner/mexico-city-launch.md`).

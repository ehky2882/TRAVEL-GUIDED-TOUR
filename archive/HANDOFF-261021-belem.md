# HANDOFF 2026-10-21: Belém launches (Atlas Studio BEL 🇧🇷, 11 singles)

**What shipped:** a new studio, **Atlas Studio BEL**, the 50th, with 11 single-stop audio tours of Belém (Pará,
Brazil) and no walks.
- **Maker:** platform `dozent`, handle `atlas.bel`, uuid5 `atlas-maker:bel` = `bd867715-70c6-5d98-b4da-2bdcb9db4905`.
- **Ids:** `atlas-tour:bel:<slug>`, stops `atlas-stop:bel:<slug>:1`; every slug starts `bel-`.
- **Catalogue:** tours 2120 → 2131, makers 709 → 710, stops 2579 → 2590, cities 994 → 995 (Belém is new; the
  catalogue had nothing there). Countries and places did not move.

**Source:** a Dropbox drop from arthur.yung (the contributor), 11 folders. Triage went to the contributor first and
they approved all 11, supplied two corrected coordinates, confirmed the photos are fine to use, and chose to add
Museu das Amazônias despite the dating issue below.
- **Audio:** 112–121 s each. Not transcribed against the scripts.
- **Photos:** 41, no byte duplicates, all 1200×900 WebP. Theatro da Paz has two. No licence recorded per image.
- **Text:** `longDescription` = hook + paragraph 3, as in Vienna, Warsaw and Oslo. `shortDescription` cut at 145
  characters. Captions written by hand from each script's orientation paragraph.
- **Bilingual `English | Portuguese`** on 5 tours: Docks Station | Estação das Docas, Museum of the Amazons | Museu
  das Amazônias, Bolonha Palace | Palacete Bolonha, Doca Linear Park | Parque Linear da Doca, Ver-o-Peso Market |
  Mercado Ver-o-Peso. Theatro da Paz (known in English by its Portuguese name) and the venues keep one name.
- **Geofence:** 40 m for venues; 50 m for the museum, palace, theatre and hotel; 60 m for Estação das Docas,
  Parque Linear and Ver-o-Peso (long sites).

**Coordinates.** `check-coordinates.py --drop` on decoded names: 1 GROSS (Rua Belém), a geocoder error — the venue
geocode matched a different restaurant 9 km away; the script's address, Av. Generalíssimo Deodoro 468, is 16 m from
the point. 6 UNVERIFIABLE, checked by hand: Casa do Saulo 17 m from the Casa das Onze Janelas, Ver-o-Peso 35 m from
the Mercado de Ferro, Palacete Bolonha 19 m, Theatro da Paz 39 m; the docks, museum and hotel points sit on Av.
Marechal Hermes along the waterfront warehouses. Bias: too few point-like matches to measure.
- ⚠️ **Muamba:** the contributor's Google Maps pin (-1.44632, -48.49860) is 13 m from the folder's point, on the
  waterfront by Estação das Docas. But the **script** places the bar in Vila Container on Av. Governador Magalhães
  Barata (number 62, per Exame and the MinC guide), ~2.2 km east near the Basílica, and its sign-off walks the
  listener to the Basílica "just a short walk away". Either the bar has moved to the waterfront and the narration's
  directions are out of date, or the pin is wrong. On Edward's board.
- **Ver-o-Pesinho:** moved to the contributor's Google Maps pin (-1.45728, -48.48769). Listings give Tv. Benjamin
  Constant 1793; the folder's point was a block over on Tv. Rui Barbosa.

**Content.** ⚠️ **Museu das Amazônias** says the galleries "reopened in November 2026"; local press (O Liberal,
Diário do Pará) gives the reopening as **3 November 2026**, so until then the line is ahead of events. Added on the
contributor's instruction. Theatro da Paz's UNESCO line (Theatres of the Amazon, July 2026) was verified: inscribed
27 July 2026 at the 48th session.

**Architect tags (Job 5), 3 new names on one line in each list:** Antonio Landi (Casa das Onze Janelas, converted
into the Royal Military Hospital), Francisco Bolonha (Palacete Bolonha), Natureza Urbana (Parque Linear da Doca). All
three credited in the tours' own scripts. Not added (not named in the scripts): the theatre's engineer and the Docas
restoration architect.

**Places:** none. `check-place-candidates` and `join-places --max-move 100` list nothing in Belém.

**gh-pages:** `21c11f9b`, one commit adding 52 files (11 audio, 41 images), built with plumbing. Diff was 52 A only.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (41) ·
`spine-lookup` 11 answered, 0 failed.

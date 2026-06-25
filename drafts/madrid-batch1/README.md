# Madrid — single-stop tours, batch 1 (audio pending) — NEW CITY

Image-staged 2026-06-24. **New city: Madrid** 🇪🇸 — the first Madrid tours. All
single-stop, geofenced. Maker: **Atlas Studio MAD** (🇪🇸 — *does not exist yet;
create it in `Tours.json` when wiring the first Madrid tour; shared by all Madrid
tours, like PAR/SFO*).

When audio lands per tour: single-stop `Tour` (`kind=single`, 1 stop),
`heroImageURL` + `additionalImageURLs`, `caption`=first sentence,
`transcriptText`=non-TTS script here, `city="Madrid"`. Run validator. Audio
`madrid_NN_<name>_TTS.mp3` → gh-pages `audio/<slug>.mp3`.

| # | Tour | slug | coord (lat, lon) | suggested category | hero | gallery |
|---|------|------|------------------|--------------------|------|---------|
| 01 | Puerta del Sol | `puerta-del-sol` | 40.4169, -3.7035 | culturalHeritage | PS2 (square at dusk) | 3 (_2 Casa de Correos, _3 statue, _4 wide) |
| 02 | Plaza Mayor | `plaza-mayor-madrid` | 40.4155, -3.7074 | history | PM1 (Casa de la Panadería) | 3 (_2 square, _3 Philip III, _4 statue) |
| 03 | Mercado de San Miguel | `mercado-de-san-miguel` | 40.4154, -3.7090 | foodAndDrink | MS2 (market hall + crowds) | 3 (_2 exterior, _3 food interior, _4 exterior[CC0]) |
| 04 | Palacio Real | `palacio-real` | 40.4180, -3.7144 | architecture | PR1 (facade) | 3 (_2 plaza, _3 night, _4 gardens) |
| 05 | Gran Vía | `gran-via` | 40.4203, -3.7058 | architecture | GV1 (avenue+Metropolis) | 3 (_2 Metropolis dusk, _3 Metropolis, _4 Carrión) |
| 06 | Templo de Debod | `templo-de-debod` | 40.4240, -3.7177 | history | TD1 (temple reflection) | 3 (_2 people, _3 night, _4 with tower) |

Coords approximate landmark centroids; geofence ~40 m. **All images ship-safe**
(Unsplash/Pexels/Pixabay; one Mercado gallery shot CC0) — `IMAGE-CREDITS-madrid.txt`.

**Blocked on:** (1) narration MP3s; (2) the **Atlas Studio MAD** maker.

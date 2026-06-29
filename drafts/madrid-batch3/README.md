# Madrid — single-stop tours, batch 3 (audio pending)

Image-staged 2026-06-29. Continues the Madrid city build (see `madrid-batch1`,
`madrid-batch2`). All **single-stop**, geofenced, maker **Atlas Studio MAD**
(🇪🇸 — *does not exist yet; create it in `Tours.json` when wiring the first
Madrid tour; shared by all Madrid tours, like PAR/SFO*).

When audio lands per tour: single-stop `Tour` (`kind=single`, 1 stop),
`heroImageURL` + `additionalImageURLs` (gallery), `caption`=first sentence,
`transcriptText`=non-TTS script here, `city="Madrid"`. Run validator. Audio
`madrid_NN_<name>_TTS.mp3` → gh-pages `audio/<slug>.mp3`.

- **Scripts:** `madrid_NN_<name>.txt` (display) + `..._TTS.txt` (audio source).
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`. Sourced via the
  pipeline (Unsplash/Pexels/Pixabay → Gemini verify gate), Wikimedia for thin
  subjects, plus owner-supplied. Owner picked hero + gallery by number.
- **Licenses:** most ship-safe (no attribution); a few CC BY-SA + owner-supplied
  — logged in `IMAGE-CREDITS-madrid-batch3.txt`.

| # | Tour | slug | coord (lat, lon) | category | hero | gallery | license note |
|---|------|------|------------------|----------|------|---------|--------------|
| 07 | Catedral de la Almudena | `catedral-de-la-almudena` | 40.4158, -3.7144 | sacredSites | A1 | 7 (_2.._8) | ship-safe |
| 08 | Plaza de Oriente & Teatro Real | `plaza-de-oriente` | 40.4180, -3.7108 | culturalHeritage | O3 | 7 (_2.._8) | ship-safe |
| 11 | Plaza de España | `plaza-de-espana` | 40.4234, -3.7122 | culturalHeritage | E3 | 2 (_2, _3) | ship-safe |
| 13 | Círculo de Bellas Artes | `circulo-de-bellas-artes` | 40.4186, -3.6962 | hiddenGems | C2 | 3 (_2.._4) | ship-safe |
| 17 | CaixaForum Madrid | `caixaforum-madrid` | 40.4111, -3.6936 | architecture | X3 | 1 (_2) | **CC BY-SA 4.0** (both) |
| 19 | Fuente de Neptuno | `fuente-de-neptuno` | 40.4154, -3.6939 | culturalHeritage | N3 | 2 (_2, _3) | hero (CC BY-SA 3.0) + _3 (CC BY-SA 4.0); _2 ship-safe |
| 24 | Palacio de Cristal | `palacio-de-cristal` | 40.4137, -3.6824 | architecture | P1 | 6 (_2.._7) | ship-safe |
| 26 | Plaza de Santa Ana / Barrio de las Letras | `plaza-de-santa-ana` | 40.4147, -3.6989 | culturalHeritage | owner | 1 (_2) | owner-supplied |

Coords approximate landmark centroids; geofence ~40 m. Categories owner-confirmed
defaults (Plaza de España could be `natureAndParks`; Círculo could be `visualArt`).

**Image pick map (owner, 2026-06-29):**
- Almudena — hero A1; gallery A3, A5, A6, A7, A9, A13, A12
- Plaza de Oriente — hero O3; gallery O2, O5, O6, O7, O8, O11, O13
- Plaza de España — hero E3; gallery E6, E7
- Círculo de Bellas Artes — hero C2; gallery C1, C5, C6
- CaixaForum — hero X3; gallery X2  (both Wikimedia CC BY-SA 4.0)
- Fuente de Neptuno — hero N3 (CC BY-SA 3.0); gallery N1 (ship-safe), N4 (CC BY-SA 4.0)
- Palacio de Cristal — hero P1; gallery P4, P5, P7, P8, P11, P13
- Plaza de Santa Ana — hero + _2 owner-supplied (García Lorca statue / Teatro Español)

**Blocked on:** (1) narration MP3s; (2) the **Atlas Studio MAD** maker.

# Nairobi — cave_bureau city guide (batch 1)

Seventeen single-stop scripts, one per venue in the [Architecture Hunter Nairobi city guide curated by cave_bureau](https://architecturehunter.com/guide/nairobi_cave_bureau/) (2025). Written in the Atlas British voice (`atlas-audio-tour` skill). Primary sources for each venue were read before writing; they are listed in each tour's `.md` file.

Each tour has three files: `NN-slug.md` (script, sources, respellings), `NN-slug.txt` (clean, carries `[beat]`), `NN-slug-tts.txt` (TTS-safe: no `[beat]`, names respelled, no hyphens, no acronym capitals).

**Not wired.** No audio exists yet and nothing is in `Tours.json`. Maker/studio code is undecided (owner's call).

| # | Slug | Title | Coordinate | Guide category | Words |
|---|---|---|---|---|---|
| 01 | `beit-e-selam` | Beit é Selam | -1.2623316, 36.8052166 | dine | 416 |
| 02 | `road-house-grill-kilimani` | Road House Grill | -1.2849379, 36.7931475 | dine | 397 |
| 03 | `kosewe-ranalo-foods` | K'Osewe Ranalo Foods | -1.2828721, 36.8218418 | dine | 400 |
| 04 | `chronos-lavington` | Chronos | -1.2799339, 36.7702097 | drink | 395 |
| 05 | `the-mist-the-mall-westlands` | The Mist | -1.2643982, 36.8027955 | drink | 378 |
| 06 | `ngong-house` | Ngong House | -1.3690338, 36.7507493 | stay | 378 |
| 07 | `ololo-safari-lodge` | Ololo Safari Lodge | -1.3875375, 36.8322352 | stay | 372 |
| 08 | `chester-house-nairobi` | Chester House | -1.2845799, 36.8186918 | stay | 354 |
| 09 | `toi-market` | Toi Market | -1.304679, 36.7777294 | shop | 379 |
| 10 | `maasai-market-nairobi` | Maasai Market | -1.2871757, 36.8231204 | shop | 371 |
| 11 | `nairobi-city-market` | Nairobi City Market | -1.2836408, 36.8194576 | shop | 367 |
| 12 | `paradise-lost-mbai-caves` | Paradise Lost — the Mbai Caves | -1.1918716, 36.8279837 | visit | 392 |
| 13 | `karura-forest` | Karura Forest | -1.2368316, 36.8303801 | visit | 361 |
| 14 | `ngara-nairobi` | Ngara | -1.2762891, 36.8256833 | visit | 388 |
| 15 | `nairobi-national-park` | Nairobi National Park | -1.3824923, 36.86102 | observe | 363 |
| 16 | `kicc-rooftop` | KICC Rooftop | -1.288693, 36.823103 | observe | 373 |
| 17 | `giraffe-centre-nairobi` | Giraffe Centre | -1.3763639, 36.7443169 | observe | 383 |

## Coordinates — read before wiring

- The coordinates are the place coordinates (`!3d`/`!4d`) inside each Google Maps link in the guide, **not** the guide's `data-map-latitude/longitude`, which for several venues is the map *viewport* (Chronos was 16 km west in the viewport field; Road House 3.9 km; Toi, Supreme Court, Paradise Lost, Karura and Giraffe Centre all differed).
- **10 Maasai Market** uses the guide's pin (the Supreme Court building). The Saturday market is in the car park behind the courts; re-pin on the car park if the owner prefers.
- **13 Karura Forest** is the Google pin for the forest; a gate (Kiambu Road or Limuru Road) would geofence better.
- **15 Nairobi National Park** is a point inside the park. The script is written for a listener in a vehicle anywhere in the park; the Main Gate / Ivory Burning Site would be a more practical geofence.
- **16 KICC Rooftop**: Nairobi already has creator pins (e.g. Britam Tower, United Nations HQ) but no KICC entry. Run `check-place-candidates.py` after wiring anyway.

## Facts deliberately softened

- **City Market as an aircraft hangar** — the guide repeats it, travel sites repeat it, but the historical sources describe a purpose-built 1932 municipal market. The script presents it as a story the building tells about itself.
- **Paradise Lost age** — the Nation's "2.5 million years" is not used; the NMK dating (8,000–12,000-year-old human remains) is.
- **Ngong House ownership** (former Belgian diplomat) is from older press and is framed as "is said to".
- **Chester House facing Uhuru Park** — framed as the guide's description; the building is on Koinange Street, a short walk north of the park.

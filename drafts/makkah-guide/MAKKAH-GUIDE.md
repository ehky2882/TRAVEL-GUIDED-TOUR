# Makkah — Atlas audio guide scripts

Thirty-eight single-stop tours, one per listing in the Architecture-Hunter-style Makkah city guide
(Stay · Dine · Drink · Shop · Visit · Observe), written to the **atlas-audio-tour** skill:
British conversational voice, position check in paragraph two, 2–4 featured items each with a gift
detail, an editorial pivot, one `[beat]`, and an explore-further close.

**Every script was written only after its sources were fetched and read** (listed under each tour).
Where a source contradicted the original guide, the source won — see *What changed from the guide* below.

## Files

| File | What it is |
|---|---|
| `scripts/NN_slug_clean.txt` | Authoring script. Keeps `[beat]` and normal spelling. |
| `scripts/NN_slug_tts-safe.txt` | For the TTS engine. Phonetic respellings (plain lowercase-style words, no caps, no hyphens), no brackets or markup, `[beat]` replaced by a paragraph break, every number and year spelled out in full. Titles respelled where the title itself trips TTS. |
| `scripts/NN_slug.md` | One Markdown file per tour: Google Maps name, coordinates, length, the clean script, the TTS-safe script, its respelling table and the sources read. |
| `MAKKAH-GUIDE.md` | This file: index of all 38 tours, coordinates, what changed from the guide and the sourcing flags. |
| `source/*.txt`, `tools/build.py` | Edit the source, re-run `python3 tools/build.py`; it rebuilds both txt sets and this file, and fails if a TTS-safe file still holds a digit, hyphen, bracket, non-ASCII letter, all-caps word or unrespelled apostrophe name. |

Every script carries a `[beat]`, so every tour has a TTS-safe version.

## Access note (applies to every tour)

The haram of Makkah, everything inside the Mecca Gate boundary, is open to **Muslims only**. Mina,
Muzdalifah and Arafat are closed to ordinary visitors during the Hajj, and the Mashaaer metro runs
only in the Hajj season. Several scripts say so where it matters; none of them invites a non-Muslim
listener to enter.

## What changed from the guide — read before wiring anything

Reading the primary sources overturned five of the original picks. They are **not** scripted:

| Guide pick | What the sources showed | Action |
|---|---|---|
| **Mama Jamila Cafe** (Drink) | Google listing marked **permanently closed**. | Dropped. |
| **Al Tekkeya Café** (Drink) | Not a heritage café. Hyatt's own page: a **grab-and-go market** inside the Jabal Omar Hyatt Regency selling sandwiches, pastries and Starbucks drinks. The guide's "Ottoman takiyya" framing had no source. | Dropped. |
| **Dates Market, Al-Kakiyah** (Shop) | The only substantive source (Times Indonesia, June 2026) describes the Kakiyah market as a three-storey **general wholesale market** (perfume, clothing, prayer mats, toys), not a date souq. No source describes the OSM "سوق التمور" node. | Dropped. Re-source before re-adding. |
| **Souq al-Aziziya** (Shop) | No source describes the market itself. One aggregator placed it "a 10-minute walk from the Grand Mosque"; it is about 5 km away. | Dropped. |
| **Masjid Namirah** (Observe, paired with Arafat) | Kept inside tour 37, but the guide's claim that its western part lies outside Arafat had no source and was cut. | Folded into 37. |

Corrections made inside scripts that keep their venue:

- **Abraj Al-Bait** — designed by Dar Al-Handasah (hotel complex) with SL Rasch (the clock); built by the Saudi Binladin Group. The guide credited Dar Al-Handasah alone; the scripts name no architect for the tower, and only Dar Al-Handasah for the Jamaraat Bridge, where Wikipedia states it.
- **Al Baik** — founded in **Jeddah** (1974); first Makkah branch 1990. Wanderlog's "originated in Mecca" is wrong.
- **Hira Cultural District** — district opened January 2023; the **Holy Qur'an Museum opened March 2025**, not 2023.
- **Makkah Library** — founding year is disputed (1950, 1953, 1954 across sources); the script says "around nineteen fifty".
- **Kamal Ismail's Thassos-marble and refused-fee stories** — sourced only to magazines and a LinkedIn post; left out.

## Thin sourcing — flagged, not hidden

These venues were scripted from the Google listing (via Wanderlog's mirror of it) plus review summaries,
because no first-party website exists. Each script states only what those sources state.

- **07 Arika Um Qasem** — 9 Google ratings; one blog line. Shortest script in the set.
- **11 nootropic**, **12 Asante**, **13 Cultivo** — independent cafés with Instagram/Google presence only. Asante's FineDine menu link did not render.
- **25 Tuwa Well** — visitors report it closed for renovation at times; the script says so.
- **38 Arak Park** — DiscoverMakkah and Google listing only; no opening date found.

## Coordinates

WGS-84, as listed in the guide. Source per row: **Google** = Google's own place pin (read via Wanderlog,
which stores the Google placeId); **OSM** = OpenStreetMap; **Wikipedia** = article coordinates.
**32 Jabal Thawr** uses the OSM summit, because Google's "Thowr Mountain" pin sits ~700 m away.

## Index

| # | Category | Google Maps name | Coordinates (WGS-84) | Coord source | Words | Est. length | Tour file |
|---|---|---|---|---|---|---|---|
| 01 | Stay | Raffles Makkah Palace | `21.419223, 39.824979` | OSM | 288 | ~1:51 | [01_raffles-makkah-palace.md](scripts/01_raffles-makkah-palace.md) |
| 02 | Stay | Fairmont Makkah Clock Royal Tower | `21.418038, 39.825302` | OSM | 301 | ~1:56 | [02_makkah-clock-royal-tower-fairmont.md](scripts/02_makkah-clock-royal-tower-fairmont.md) |
| 03 | Stay | Conrad Jabal Omar Makkah | `21.419329, 39.822078` | OSM | 316 | ~2:02 | [03_conrad-jabal-omar-makkah.md](scripts/03_conrad-jabal-omar-makkah.md) |
| 04 | Dine | Al Shorfa Restaurant | `21.419733, 39.82646` | Google | 270 | ~1:44 | [04_al-shorfa-restaurant.md](scripts/04_al-shorfa-restaurant.md) |
| 05 | Dine | Kabsa Hashi | `21.452752, 39.868801` | Google | 269 | ~1:43 | [05_kabsa-hashi.md](scripts/05_kabsa-hashi.md) |
| 06 | Dine | Al Qarmoshi Yemeni Restaurant | `21.426602, 39.807081` | Google | 252 | ~1:37 | [06_al-qarmoshi-yemeni-restaurant.md](scripts/06_al-qarmoshi-yemeni-restaurant.md) |
| 07 | Dine | Arika Um Qasem | `21.386563, 39.792393` | Google | 222 | ~1:25 | [07_arika-um-qasem.md](scripts/07_arika-um-qasem.md) |
| 08 | Dine | Al Romansiah - الرومانسية | `21.400914, 39.880772` | Google | 279 | ~1:47 | [08_al-romansiah.md](scripts/08_al-romansiah.md) |
| 09 | Dine | Al Baik Aziziya Makkah | `21.416927, 39.861186` | Google | 282 | ~1:48 | [09_al-baik-aziziya-makkah.md](scripts/09_al-baik-aziziya-makkah.md) |
| 10 | Drink | Cafe Moment | `21.420311, 39.823815` | Google | 296 | ~1:54 | [10_cafe-moment.md](scripts/10_cafe-moment.md) |
| 11 | Drink | nootropic cafe and roastery مقهى ومحمصة نوتروبك | `21.440653, 39.800355` | Google | 249 | ~1:36 | [11_nootropic-cafe-and-roastery.md](scripts/11_nootropic-cafe-and-roastery.md) |
| 12 | Drink | Asante Roastery \| محمصة اسانتي | `21.352867, 39.895026` | Google | 255 | ~1:38 | [12_asante-roastery.md](scripts/12_asante-roastery.md) |
| 13 | Drink | cultivo cafe and roastry  مقهى ومحمصة كالتيفو | `21.46286, 39.967878` | Google | 247 | ~1:35 | [13_cultivo-cafe-and-roastry.md](scripts/13_cultivo-cafe-and-roastry.md) |
| 14 | Shop | Abdul Samad Al Qurashi | `21.418569, 39.825599` | OSM | 288 | ~1:51 | [14_abdul-samad-al-qurashi.md](scripts/14_abdul-samad-al-qurashi.md) |
| 15 | Shop | Abraj Al-Bait Shopping Center | `21.418597, 39.826666` | Google | 298 | ~1:55 | [15_abraj-al-bait-shopping-center.md](scripts/15_abraj-al-bait-shopping-center.md) |
| 16 | Visit | Masjid al-Haram | `21.423658, 39.82536` | Google | 348 | ~2:14 | [16_masjid-al-haram.md](scripts/16_masjid-al-haram.md) |
| 17 | Visit | Safaa and Marwah (Saee) | `21.422076, 39.827531` | Google | 325 | ~2:05 | [17_safa-and-marwah.md](scripts/17_safa-and-marwah.md) |
| 18 | Visit | Makkah Al Mukarramah Library | `21.424907, 39.829817` | Google | 280 | ~1:48 | [18_makkah-al-mukarramah-library.md](scripts/18_makkah-al-mukarramah-library.md) |
| 19 | Visit | Exhibition of the Two Holy Mosques Architecture | `21.433782, 39.754361` | Google | 305 | ~1:57 | [19_exhibition-two-holy-mosques-architecture.md](scripts/19_exhibition-two-holy-mosques-architecture.md) |
| 20 | Visit | The Kiswa Factory of the Holy Ka'aba | `21.434722, 39.756922` | Google | 304 | ~1:57 | [20_kiswa-factory.md](scripts/20_kiswa-factory.md) |
| 21 | Visit | Mecca Museum | `21.446147, 39.807936` | Google | 287 | ~1:50 | [21_mecca-museum.md](scripts/21_mecca-museum.md) |
| 22 | Visit | Hira Cultural District | `21.456188, 39.869063` | Google | 302 | ~1:56 | [22_hira-cultural-district.md](scripts/22_hira-cultural-district.md) |
| 23 | Visit | Hira Cave, Mount of Light | `21.457254, 39.858974` | Google | 294 | ~1:53 | [23_hira-cave-mount-of-light.md](scripts/23_hira-cave-mount-of-light.md) |
| 24 | Visit | Bay'ah Mosque | `21.424717, 39.867493` | OSM | 231 | ~1:29 | [24_bayah-mosque.md](scripts/24_bayah-mosque.md) |
| 25 | Visit | Tuwa Well | `21.431619, 39.816657` | Google | 247 | ~1:35 | [25_tuwa-well.md](scripts/25_tuwa-well.md) |
| 26 | Visit | Masjid al Jinn | `21.433454, 39.828965` | OSM | 285 | ~1:50 | [26_masjid-al-jinn.md](scripts/26_masjid-al-jinn.md) |
| 27 | Visit | Al Muallaa Cemetery | `21.435021, 39.827908` | Google | 266 | ~1:42 | [27_al-muallaa-cemetery.md](scripts/27_al-muallaa-cemetery.md) |
| 28 | Visit | Aisha Al Rajhi Mosque | `21.381866, 39.873747` | Google | 259 | ~1:40 | [28_aisha-al-rajhi-mosque.md](scripts/28_aisha-al-rajhi-mosque.md) |
| 29 | Visit | Jamaraat Bridge | `21.420775, 39.873156` | OSM | 325 | ~2:05 | [29_jamaraat-bridge.md](scripts/29_jamaraat-bridge.md) |
| 30 | Visit | Haramain High Speed Railway - Makkah | `21.417655, 39.788532` | OSM | 308 | ~1:58 | [30_haramain-high-speed-railway-makkah.md](scripts/30_haramain-high-speed-railway-makkah.md) |
| 31 | Visit | Mecca Gate | `21.362361, 39.666722` | Wikipedia | 244 | ~1:34 | [31_mecca-gate.md](scripts/31_mecca-gate.md) |
| 32 | Visit | Jabal Thawr | `21.377, 39.849868` | OSM (summit) | 216 | ~1:23 | [32_jabal-thawr.md](scripts/32_jabal-thawr.md) |
| 33 | Observe | Al Kaaba | `21.422545, 39.82619` | Google | 309 | ~1:59 | [33_al-kaaba.md](scripts/33_al-kaaba.md) |
| 34 | Observe | Makkah Clock Tower | `21.419341, 39.825412` | Google | 282 | ~1:48 | [34_makkah-clock-tower.md](scripts/34_makkah-clock-tower.md) |
| 35 | Observe | Mina | `21.414605, 39.894564` | Google | 268 | ~1:43 | [35_mina.md](scripts/35_mina.md) |
| 36 | Observe | Jamarat (Mina Station 3) | `21.418396, 39.87064` | OSM | 260 | ~1:40 | [36_jamarat-mina-station-3.md](scripts/36_jamarat-mina-station-3.md) |
| 37 | Observe | Mt Arafat | `21.354885, 39.984116` | Google | 291 | ~1:52 | [37_mt-arafat.md](scripts/37_mt-arafat.md) |
| 38 | Observe | Arak Park | `21.383342, 39.876428` | Google | 246 | ~1:35 | [38_arak-park.md](scripts/38_arak-park.md) |

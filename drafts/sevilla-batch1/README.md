# Sevilla batch 1: 37 single-stop scripts, drafted 2026-11-11

A Sevilla city guide in the Architecture Hunter format (Stay · Dine · Drink · Shop · Visit · Observe), turned
into one Atlas audio script per venue. Written to `anthropic-skills:atlas-audio-tour`: British conversational
voice, position check in the second paragraph, one editorial pivot, at most one `[beat]`, and a specific
"explore further" pointer to finish.

**Status: scripts only.** No audio, images, maker or `Tours.json` wiring yet.

## Files (in `scripts/`)
- `NN_<slug>_clean.txt`: the clean script. `[beat]` stays in as an authoring marker.
- `NN_<slug>_tts-safe.txt`: for the narration tool. Spanish names are respelled phonetically (lowercase,
  no hyphens, no all-caps), `[beat]` becomes a paragraph break, there are no brackets or quote marks,
  and every number is spelled out. The titles are respelled too.
- `NN_<slug>.md`: the clean script plus Google Maps name, coordinates, the respellings used and the sources.

`tools/build.py` regenerates every TTS-safe and `.md` file from the clean scripts
(`python3 -I tools/build.py scripts`). `tools/respellings.py` holds the respelling table (Sevillian seseo).
`tools/venues.py` holds names, coordinates and sources. **Edit the clean script, then rebuild.** Never
hand-edit a TTS file.

## Index
| # | Category | Title | Google Maps name | Coordinates (WGS-84) | Words |
|---|---|---|---|---|---|
| 01 | Stay | Hotel Alfonso XIII | Hotel Alfonso XIII, a Luxury Collection Hotel, Seville | 37.381516, -5.992719 | 357 |
| 02 | Stay | Corral del Rey | Corral del Rey | 37.389431, -5.990357 | 322 |
| 03 | Stay | Hotel Mercer Sevilla | Hotel Mercer Sevilla | 37.387564, -5.997425 | 330 |
| 04 | Stay | Palacio de Villapanés | Hotel CoolRooms Palacio Villapanés | 37.391578, -5.986392 | 309 |
| 05 | Stay | Casa 1800 | Hotel Casa 1800 Sevilla | 37.385853, -5.990801 | 328 |
| 06 | Dine | Eslava | Eslava | 37.397548, -5.996924 | 316 |
| 07 | Dine | La Brunilda | La Brunilda Tapas | 37.388319, -5.999398 | 292 |
| 08 | Dine | Bodeguita Casablanca | Bodeguita Casablanca | 37.383728, -5.994098 | 294 |
| 09 | Dine | Las Golondrinas | Bar Las Golondrinas | 37.384866, -6.005512 | 311 |
| 10 | Dine | Abantal | Abantal | 37.387929, -5.983713 | 312 |
| 11 | Drink | El Rinconcillo | El Rinconcillo | 37.39334, -5.988294 | 323 |
| 12 | Drink | Casa Morales | Casa Morales | 37.386527, -5.994614 | 309 |
| 13 | Drink | Bar Garlochí | Garlochí | 37.390488, -5.989532 | 300 |
| 14 | Drink | Bar Alfalfa | Bar Alfalfa | 37.389982, -5.990161 | 303 |
| 15 | Drink | Mercado de Feria | Mercado de Feria | 37.399474, -5.991191 | 310 |
| 16 | Shop | Cerámica Santa Ana | Cerámica Santa Ana | 37.385356, -6.00393 | 319 |
| 17 | Shop | Populart | Populart | 37.385919, -5.990579 | 290 |
| 18 | Shop | Mercado de Triana | Mercado de Triana | 37.385749, -6.00355 | 346 |
| 19 | Shop | Calle Sierpes | Calle Sierpes | 37.391094, -5.994567 | 333 |
| 20 | Visit | Real Alcázar de Sevilla | Real Alcázar de Sevilla | 37.38321, -5.990183 | 460 |
| 21 | Visit | Setas de Sevilla | Setas de Sevilla | 37.393119, -5.991853 | 340 |
| 22 | Visit | Plaza de España | Plaza de España | 37.376974, -5.986939 | 374 |
| 23 | Visit | Casa de Pilatos | Casa de Pilatos | 37.390239, -5.987249 | 346 |
| 24 | Visit | Palacio de las Dueñas | Palacio de las Dueñas | 37.395381, -5.989412 | 304 |
| 25 | Visit | Palacio de Lebrija | Palacio de Lebrija | 37.389953, -5.993269 | 312 |
| 26 | Visit | Hospital de los Venerables | Hospital de los Venerables | 37.38524, -5.990332 | 366 |
| 27 | Visit | Hospital de la Santa Caridad | Hospital de la Santa Caridad | 37.384081, -5.995231 | 384 |
| 28 | Visit | Centro Andaluz de Arte Contemporáneo | Centro Andaluz de Arte Contemporáneo | 37.398068, -6.007729 | 350 |
| 29 | Visit | Pabellón de la Navegación | Pabellón de la Navegación | 37.394268, -6.007796 | 334 |
| 30 | Visit | CaixaForum Sevilla | CaixaForum Sevilla | 37.393635, -6.009293 | 303 |
| 31 | Observe | Puente de Isabel II | Puente de Isabel II | 37.386277, -6.00243 | 343 |
| 32 | Observe | Calle Betis | Calle Betis | 37.383296, -5.999693 | 326 |
| 33 | Observe | Parque de María Luisa | Parque de María Luisa | 37.374771, -5.988794 | 336 |
| 34 | Observe | Alameda de Hércules | Alameda de Hércules | 37.398883, -5.993735 | 350 |
| 35 | Observe | Iglesia de San Luis de los Franceses | Iglesia de San Luis de los Franceses | 37.39836, -5.988269 | 351 |
| 36 | Observe | Plaza del Salvador | Plaza del Salvador | 37.390021, -5.993103 | 385 |
| 37 | Observe | Puente del Alamillo | Puente del Alamillo | 37.413359, -5.990634 | 328 |

Coordinates were checked against OpenStreetMap (Nominatim). Pins that are approximate:
- **02 Corral del Rey:** pinned to the building at Calle Corral del Rey 10–12. The hotel itself isn't on OSM.
- **16 Cerámica Santa Ana:** pinned to Calle San Jorge, near the corner with the Plaza del Altozano.
- **36 Plaza del Salvador:** the centre of the square.

⚠️ **03 Mercer corrected:** Nominatim's "Mercer Hotel" node sits on Calle Hernando Colón, which is wrong. The
hotel is at Calle Castelar 26, now pinned at 37.387564, -5.997425.

## Things to check before recording
- **27 Hospital de la Santa Caridad:** the church and hospital have been under restoration, with works
  announced in 2025 to last about two years. The script works from the street and says so. Confirm access
  before recording.
- **29 Pabellón de la Navegación:** the museum closed on 21 June 2026 when its operating agreement
  expired. The script says so and works from the outside. Re-check before release.
- **10 Abantal:** the star is described as first won in 2009. Whether it is held in the current Michelin
  guide was not confirmed (the guide page returned empty), so the script does not claim it.
- **13 Garlochí:** the 1978 opening comes from guides. The Queen Elizabeth altar (September 2022) is from
  eldiario.es.
- **14 Bar Alfalfa:** the bar facts are thin (Italian owners, a tiny corner bar), so the script leans on the
  Candilejo legend, which is well documented.

## Sources
Every venue's `.md` lists what was read before writing. Most were fetched and read in full: official
sites, Wikipedia (EN/ES), Metalocus, Arquitectura Viva, eldiario.es, Time Out and long-form food writing.
Where a page refused the fetch (Frommer's, Atlas Obscura, Archello: 403; Michelin: empty), the facts were
taken from the search excerpt and cross-checked against a second source. Anything that could not be
confirmed was cut from the script.

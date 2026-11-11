# Osaka: an architect's city guide, 34 audio scripts (drafted 2026-11-11)

These are the scripts for the Osaka city guide written in the Architecture Hunter format, with recommendations for where to
stay, dine, drink, shop, visit and observe. Each venue is its own single-stop tour, written in the Atlas British voice
(atlas-audio-tour skill) in the Fukuoka batch's house style. The narrator never says they are an architect. **No audio
has been recorded yet, and nothing here is wired into `Tours.json`.**

## Files
- `scripts/NN_<slug>_clean.txt` is the script as written: years as digits, with one `[beat]` authoring marker.
- `scripts/NN_<slug>_tts-safe.txt` is the version for the TTS tool. It uses phonetic respellings (lowercase, no hyphens,
  no all-caps), spells out years and numbers ("eighteen ten"), uses no brackets or markup, and replaces `[beat]` with a
  paragraph break. Titles that trip TTS are respelled too ("Tsoo ten kahkoo", "Hahjeemay").
- `scripts/NN_<slug>.md` holds the clean script plus the respellings it used, the coordinates and the sources read
  before writing.
- `scripts/00_index.md` lists all 34.
- `tools/scripts_a.py` and `tools/scripts_b.py` hold the script text. `tools/build.py` regenerates every file and
  checks the TTS-safe files: no digits, hyphens, brackets or all-caps words. **Edit the script text in the two
  `scripts_*.py` files, then run `python3 -I tools/build.py`, rather than editing the `.txt` files by hand.**

## Corrections the sources forced (against the first draft of the guide)
- **Zentis Osaka:** the interiors are by **Tara Bernerd & Partners**, not Tom Dixon. The exterior is by Kajima Design.
- **VS.:** Tadao Ando **supervised** the design and **Nikken Sekkei** designed it. Ando did not design it alone.
- **Nakanoshima Museum of Art:** the architect is **Katsuhiko** Endo (not Katsuhiro).
- **Hotel Noum Osaka:** no source says the building was once something else, so the script doesn't claim it.

## Lines that will date
- Tsutenkaku says "seventy years old this year": the second tower turned 70 on 28 October 2026.
- Osaka Gas Building mentions a planned renewal (west annex around 2027, renovation around 2031).
- VS. has no permanent collection, and Umekita Park is due to be finished in 2027.
- Hajime: the script gives only the historical fact that it won three Michelin stars about 18 months after opening. It
  does not claim a current star count.

## Unverified and left out on purpose
The angry-chef statue at Daruma, the Shinsekai "Ship's Cat" sculpture, the Hundertwasser plant's completion year, the
Chikatsu Asuka tower and the Gas Building Shokudo's current opening hours. None of these could be confirmed from a
primary source.

## Coordinates
The coordinates are in each tour's `.md` file, taken from OpenStreetMap venue records or Japan's GSI address lookup
(house-number precision). **VS. is approximate (±100 m):** it is the centroid of Umekita Park North Park. Run
`python3 scripts/check-coordinates.py` before any of these are wired into the catalog.

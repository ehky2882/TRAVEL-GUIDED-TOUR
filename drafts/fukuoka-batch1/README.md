# Fukuoka batch 1: city-guide audio scripts (30 singles), drafted 2026-11-06

Thirty single-stop scripts written from a guest-architect-style Fukuoka city guide (Stay, Dine, Drink, Shop, Visit, Observe).
Not wired into `Tours.json`: no audio, no images, no maker yet.

- `scripts/NN_<slug>_clean.txt`: the script as written. It keeps `[beat]` and years as digits.
- `scripts/NN_<slug>_tts-safe.txt`: phonetic respellings (no caps, no hyphens), years spelled out, `[beat]` removed.
- `scripts/NN_<slug>.md`: the clean script, plus the respellings used, the Google Maps name, the WGS-84 coordinate and the sources read.
- `scripts/00_INDEX.md`: all thirty in one table.
- `tools/source_clean.txt` is the single source of truth. Edit it, then run `python3 -I tools/build.py` to regenerate everything,
  with `tools/meta.json` supplying the respellings, coordinates and sources.

## Corrections made against the earlier list
- **Books Kubrick Keyaki-dori closed on 20 July 2026** (official site). Tour 13 is the Hakozaki shop instead.
- **manu coffee Haruyoshi** is officially at Watanabe-dori 3-11-2. The pin stands; OSM and GSI agree within 10 m.

## Coordinates to look at before wiring
- **Nakasu Yatai:** approximate.
- **Nexus World:** the Portzamparc block.
- **Island City:** the park centroid.
- **Kawabata:** the OSM arcade point, which may not be the zenzai square the script names.
- **Address-only pins** (GSI): Il Palazzo, Coffee Bimi, B·B·B Potters, Books Kubrick, Ishimura Manseido, Canal City.
- Run `scripts/check-coordinates.py` when this becomes a real drop.

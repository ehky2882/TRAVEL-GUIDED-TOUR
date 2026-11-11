# Nice batch 1: 31 single-stop scripts (staged, no audio yet)

Written 2026-11-11 from the Architecture Hunter-style Nice guide (Stay · Dine · Drink · Shop · Visit · Observe).
Voice and structure follow the `atlas-audio-tour` skill. Every venue's facts came from primary or near-primary
sources read before writing (the venue's own site where it had one, then Ministère de la Culture, Wikipedia,
Michelin, Gault&Millau, the Nice tourist office and press). Where sources disagreed, the script either uses the
safe common ground or leaves the claim out.

- `scripts.src.txt` is the single source. `tools/build_scripts.py` (run `python3 -I tools/build_scripts.py`) writes
  `scripts/NN_<slug>_clean.{txt,md}` and `scripts/NN_<slug>_tts-safe.{txt,md}`. **Edit the source, then rebuild.**
- **Clean** keeps `[beat]` as an authoring marker. **TTS-safe** uses phonetic respellings (lowercase, no hyphens), has
  no `[beat]` or markup, spells every number in words, and respells the titles. "Nice" is respelled "Neece" throughout,
  or a British voice reads it as the adjective.
- `coordinates.tsv`: WGS-84 points, each matched to an OpenStreetMap object by name and address.

## Things to check before recording
- **17 MAMAC is closed for renovation until 2028** (Nice tourist office). The script says so and works from outside.
  Update it when the museum reopens.
- **13 Café du Cycliste** opens 08:30 daily (brand site). Hours anywhere else are not stated in the scripts on purpose.
- **16 Florian**: the free workshop tours are offered at the Nice shop (France Vélo Tourisme); confirm they still run.
- **01 Negresco**: the script says it opened "just before the First World War". Sources split between 1912 and 1913.
- **Corrections to the first guide list** (in chat, not in the catalogue): Gustave Eiffel did not design the Negresco's
  glass roof (Niermans did). Les Distilleries Idéales dates from the last couple of decades, not the 19th century.
  Le Plongeoir's diving board dates from 1941.

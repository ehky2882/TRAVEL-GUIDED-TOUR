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

## Images: picker published 2026-11-12, waiting on the owner's picks
- Picker: https://claude.ai/artifact/2D3hgbfutVP3VHMdRgouE3 (version 2). It has 170 candidates for 24 tours. **7 tours have none:**
  04 Windsor, 05 Chez Pipo, 17 MAMAC, 18 Chagall, 21 Villa Arson, 24 Lascaris and 29 Tête Carrée. 19 Matisse has only one.
- Version 2 (2026-11-12) added 13 public-domain Wikimedia Commons photos once Commons stopped returning 429:
  Arts Asiatiques (2), Sainte-Jeanne-d'Arc (3), Paillon (5) and Masséna (3). Commons offered nothing usable for the other
  seven: only other Windsor hotels, paintings, a 1910 postcard and a 1930s black-and-white photo.
- Sources: Unsplash, Pexels and (version 2) public-domain Commons. In version 1 Commons returned HTTP 429 throughout, and Openverse has almost no
  public-domain photos of these subjects. **No Gemini key was available, so both gates were run by eye** (Claude looked at
  every candidate): modern colour photo, and the right subject with its look-alikes rejected (Place Masséna for Garibaldi,
  Bordeaux's Miroir d'eau, Prague's Kafka head, St Basil's).
- `image-candidates.json` maps every picker code (`NN-k`) to its source page, photographer and download URL, plus the reason
  each thin tour is thin. Several venues (restaurants, shops) show their dishes or street, not the venue itself.

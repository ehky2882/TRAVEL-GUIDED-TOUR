# Grands Ensembles — batch 1 (8 single-stop tours, scripts staged)

A themed series on post-war and late-modernist social housing around Paris.
Each location is its own single-stop tour. **Scripts only — no audio, no images
wired, nothing in `Tours.json` yet.** Maker is undecided: the series spans eight
communes, so it is not obviously Atlas Studio PAR. That is the owner's call.

| # | Tour | Commune | Lat, Lon | Words |
|---|---|---|---|---|
| 01 | The Aillaud Towers (Tours Nuages) | Nanterre | 48.889872019056696, 2.226992520173109 | 414 |
| 02 | Cité de la Muette and the Drancy Memorial | Drancy | 48.91915597553556, 2.4550710393194985 | 421 |
| 03 | La Grande Borne | Grigny | 48.652242798164714, 2.375369277186132 | 436 |
| 04 | Les Arcades du Lac | Montigny-le-Bretonneux | 48.76701302046429, 2.046248488948336 | 387 |
| 05 | Les Étoiles de Renaudie | Ivry-sur-Seine | 48.813755821253395, 2.3850938211113766 | 389 |
| 06 | Les Orgues de Flandre | Paris (19e) | 48.8897756873707, 2.3750060164409814 | 384 |
| 07 | Les Arènes de Picasso | Noisy-le-Grand | 48.83902884679481, 2.555522868151227 | 367 |
| 08 | Les Choux de Créteil (Résidence ARPEJ Les Choux) | Créteil | 48.78510463252899, 2.444722571831556 | 390 |

Coordinates are the owner's, as supplied. They have **not** been run through
`check-coordinates.py`; do that before wiring.

## Files

For each tour, in `scripts/`:

- `NN-slug.txt` is the clean script and the source of truth. `[beat]` marks a pause.
- `NN-slug.md` holds the clean script plus metadata, the respellings table and the sources read.
- `NN-slug_tts.txt` is the TTS-safe version: phonetic respellings in lowercase, no hyphens, no
  brackets, and `[beat]` turned into a paragraph break.

`tools/build.py` regenerates the `.md` and `_tts.txt` files from the clean `.txt`. It exits 1
if a TTS file still contains a digit, an accent or a hyphen.

## Facts deliberately left out (could not be confirmed from a source)

- Arcades du Lac: the facade materials and colours, and any film appearances.
- Arènes de Picasso: the number of storeys, and the Berrocal sculpture (it appeared in a
  search snippet only). The *Brazil* connection belongs to the nearby Espaces d'Abraxas, not
  the Arènes, and the script says so.
- Drancy: the memorial's opening days. They are perishable, so the script says only that
  entry is free.

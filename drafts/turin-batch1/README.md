# Turin batch 1 — Atlas Studio TRN (29 singles) — LIVE 2026-10-29

Source: contributor drop (Dropbox, arthur.yung), 29 `output <Name> <lat>, <lon>` folders with scripts numbered 01–30.
**No. 18 is missing on purpose**: the contributor dropped it as not a good tour. Each folder holds
`NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt` (every clean script opens with a title line and carries one `[beat]`),
one MP3 (96–127 s) and 1–5 photos at 1200×900 WebP (113 in all, no byte duplicates). Accented folder names arrived
mangled by the zip (`Caff#U00e8`, `Bal#U00f4n`, `Madamador#U00e8`); the assembler matches on the folder-name prefix.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
Every coordinate comes from its folder name, except one:
- **Marco Polo** moved 295 m, from Via Ottavio Revel 11 to **45.0661078, 7.6703748**: the contributor gave the address
  as Corso Vittorio Emanuele II 86 (inner courtyard), and that is OSM's point for No. 86.

`tools/wire_turin.py` is the assembler (`python3 -I wire_turin.py <unzipped drop> <stage dir>`). Run it once: it
refuses colliding tour ids. Slugs carry a **`trn-` prefix**: audio at `audio/trn-<slug>.mp3`, images at
`images/trn-<slug>_hero.webp`, `_2.webp`, … in the drop's numeric order.

- **Geofence:** 20 m for the Galleria Subalpina pair (Gilibert and Luxemburg, 26 m apart) and for Piano 35; 30 m for
  Pepino (72 m from the Egyptian Museum); 40 m for venues; 50 m for the Mole, the skyscraper, the Balôn and the
  Mountain Museum terrace; 60 m for Porta Palazzo.
- **Piano 35 sits 6.5 m from the Intesa Sanpaolo Skyscraper tour** (the bar is at the top of the tower), so both fire
  together at street level, and its script opens "You're about 150 m above Turin". Kept on the contributor's instruction.
- **Bilingual `English | Italian`** on 7: Balôn Flea Market | Mercato del Balôn, Sandretto Re Rebaudengo Foundation |
  Fondazione …, Intesa Sanpaolo Skyscraper | Grattacielo Intesa Sanpaolo, Egyptian Museum | Museo Egizio, National
  Museum of the Italian Risorgimento | Museo Nazionale …, National Mountain Museum | Museo Nazionale della Montagna,
  Pfatisch Pastry Shop | Pasticceria Pfatisch. Proper names (the cafés, shops, Mole) keep one name.
- **Titles tidied from the folder names:** "Torino" and shop slogans dropped; the `|` in "San Carlo Dal 1973 | La Moda
  a Torino" removed, since the app reads `|` as the bilingual split.

Full account: `archive/HANDOFF-261029-turin.md`.

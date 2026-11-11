# Rotterdam batch 1 — Atlas Studio RTM (28 singles) + Portugalia Tasca (AMS) — LIVE 2026-10-27

Source: contributor drop (Dropbox, arthur.yung), 29 `output <Name> <lat>, <lon>` folders with scripts numbered 01–29.
Each holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt` (every clean script opens with a title line and carries one
`[beat]`), one MP3 and 2–8 photos at 1200×900 WebP.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
Every coordinate comes from its folder name, except two:
- **FENIX** moved 135 m, from the Wilhelminapier side of the Rijnhaven onto the building, at the existing
  *FENIX Migration Museum* creator pin's point (51.9020903, 4.4843147) — contributor's instruction.
- **Supernova Hotel** had no coordinate in its folder name; OSM's node at 's-Gravendijkwal 68 (51.916468, 4.4631211).

`tools/wire_rotterdam.py` is the assembler (`python3 -I wire_rotterdam.py <unzipped drop> <stage dir>`). Run it once:
it refuses colliding tour ids. Slugs carry an **`rtm-` prefix** (`ams-` for Portugalia Tasca): audio at
`audio/rtm-<slug>.mp3`, images at `images/rtm-<slug>_hero.webp`, `_2.webp`, … in the drop's numeric order.
Five folders carried photos under another venue's filename (Bakehouse, Bertmans, Crave, Room Mate Bruno,
de Maaskantine); each was opened and is the right venue, so they were simply renamed. `OX_3o.webp` is photo 3.

**Portugalia Tasca** (script 25) is in Amsterdam, so it went to **Atlas Studio AMS**, not RTM. The Fotomuseum photos
were replaced by the contributor mid-triage (the first set showed the old Las Palmas building, not Pakhuis Santos).

Bilingual `English | Dutch` on the 6 tours whose names genuinely differ. Full account: `archive/HANDOFF-261027-rotterdam.md`.

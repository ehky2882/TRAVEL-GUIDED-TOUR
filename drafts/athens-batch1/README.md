# Athens batch 1 — Atlas Studio ATH (29 singles) — wired 2026-11-04

Source: contributor drop (Dropbox, arthur.yung), 29 `output <Name> <lat>, <lon>` folders with scripts numbered 01–30
(26 absent from the drop). Each folder holds `athens_NN_<slug>.txt` + `athens_NN_<slug>_TTS.txt`, one MP3 (77–138 s)
and 2–8 photos at 1200×900 WebP (127 in all, no byte duplicates). En dashes in folder names arrived as `#U2013`; the
assembler matches on a folder-name prefix.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.

`tools/wire_athens.py` is the assembler (`python3 -I wire_athens.py <unzipped drop> <stage dir>`), adapted from
`drafts/mecca-batch1/tools/wire_mecca.py`. Run it once: it refuses colliding tour ids. Slugs carry an **`ath-`
prefix**: audio at `audio/ath-<slug>.mp3`, images at `images/ath-<slug>_hero.webp`, `_2.webp`, … in the drop's order.

- **Maker:** Atlas Studio ATH, platform `dozent`, handle `atlas.ath`, uuid5 `atlas-maker:ath`
  = `a274e39f-e266-5eae-b21a-8d9fad136299`.
- **Ids:** `atlas-tour:ath:ath-<slug>`, stops `atlas-stop:ath:ath-<slug>:1`.

## Coordinates
Every coordinate comes from its folder name except one. **Lycabettus Funicular** was moved ~20 m to OSM's
*Σταθμός Ανάβασης* (the ascending/lower station, Aristippou 1: 37.9803157, 23.7440055), at the contributor's request.
`check-coordinates.py --drop` could not certify the batch (Nominatim dropped 16–20 of 72 calls on two runs), but every
forward hit it made sat 4–81 m from its point, with SNFCC at 149 m (a large site; the point is at the foot of the
park, as the script says). Hand lookups put Shila, Benaki Pireos 138, Taf, Kombologadiko, Nolan and Agios Dimitrios
Loumbardiaris within 25 m. Melissinos, Little Tree, Seychelles, Karamanlidika, Xenodocheio Milos and Varvakios were not
reached by the geocoder; each sits on the street its script names.

## Wiring
- **City:** `Athens` for 28; `Kallithea` for SNFCC (its municipality). Country `Greece`.
- **Geofence:** 25 m for venues in the dense centre, 30 m for the Modernist and the funicular, 40 m for the Grande
  Bretagne and Benaki, 50 m for museums, the market, the Conservatoire, the Conrad and the Pikionis paths, 60 m for
  Anafiotika, 80 m for SNFCC. No two of the 29 circles overlap.
- **Bilingual `English | Ελληνικά`** on 16. Brand-name hotels, bars and shops keep one name; Xenodocheio Milos keeps
  *Milos* in Latin letters (the restaurant brand).
- **Text:** `longDescription` = hook + paragraph 3, `shortDescription` cut at 145 characters, `[beat]` stripped.
  Captions written by hand from each script's orientation paragraph.

## Architect tags (Job 5): 11 new names, one line in each list
K-Studio (Perianth) · FORMrelated (Modernist) · Kostas Voutsinas (Grande Bretagne, 1957 rebuild) · Dimitris Pikionis ·
Michael Photiadis (with Tschumi, Acropolis Museum) · Takis Zenetos (Fix/EMST) · Ioannis Despotopoulos (Conservatoire) ·
Emmanouil Vourekas, Prokopis Vasileiadis, Antonis Georgiadis, Spyros Staikos (Hilton/Conrad, all four at the
contributor's request). Existing tags used: Bernard Tschumi, Renzo Piano.
**Not** tagged: Theophil Hansen (his mansion was demolished in 1957; the script says so), Yannis Moralis (painter of
the Conrad reliefs), Aeter Architects and AvroKO (restoration and interiors), and the Benaki and EMST conversion
architects (not named in the scripts).

## Places
None created or joined. The contributor asked to stack Atlantikos, The Clumsies and Diporto on the existing creator
pins; that is Edward's call and is on his board (`status/owner/athens-launch.md`) with the Lycabettus part-vs-whole
question.

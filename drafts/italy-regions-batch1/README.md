# Italy regions batch 1: 16 singles across nine regions, six new studios, wired 2026-11-27

Source: contributor drop (Dropbox). 16 `output <Name> <lat>, <lon>` folders (scripts 06, 27–31, 54–61, 68, 69). The
Castel Savoia folder carries coordinates only, and the Ponte delle Torri folder has no space before them. Each holds
`<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3 (101–121 s) and 2–6 photos at 1200×900 WebP (68 delivered, 66
shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run on the SUPPLIED points (15 of 16: it could not parse the
Ponte delle Torri folder name; that point was checked by hand and sits 10 m from the OSM bridge).
`tools/wire_italy_regions.py` is the assembler (`python3 -I wire_italy_regions.py <unzipped drop> <stage dir>`), adapted
from `drafts/sardinia-batch1/tools/wire_sardinia.py`. Run it once only. Slugs carry the studio prefix:
`audio/<code>-<slug>.mp3`, `images/<code>-<slug>_hero.webp`, `_2.webp`, …

- **Six new makers**, platform `dozent`, handle `atlas.<code>`, id uuid5 `atlas-maker:<code>`, inserted after CAG in this
  order (the 78th to 83rd studios), on the contributor's choice ("codes fine"):

  | Studio | Region | uuid5 |
  |---|---|---|
  | Atlas Studio AOT 🇮🇹 | Aosta Valley | `49a646f8-27b1-52d2-b0eb-6da3e1d5ae82` |
  | Atlas Studio TRS 🇮🇹 | Friuli (Trieste) | `4efbe89f-c552-5ca8-b3ac-acb550d5fd16` |
  | Atlas Studio PEG 🇮🇹 | Umbria (Perugia) | `a80e1b9f-48b5-52ef-8a7b-1f1779a4a3a4` |
  | Atlas Studio SUF 🇮🇹 | Calabria (Lamezia) | `94438230-d491-5a06-906a-2865d30d0021` |
  | Atlas Studio RAN 🇮🇹 | Ravenna | `acb0e2f1-a01a-576f-8316-af6487f3ffb5` |
  | Atlas Studio AOI 🇮🇹 | Marche (Ancona) | `cc29a316-746c-574f-8927-c0019a21f2ef` |

  Five tours went to existing studios: Ieranto and Salerno to **NAP**, Matera to **BRI** (Bari is Matera's airport), the
  Parco degli Acquedotti and Villa Gregoriana to **ROM**.
- **Ids:** `atlas-tour:<code>:<code>-<slug>`, stops `atlas-stop:<code>:<code>-<slug>:1`.
- **gh-pages:** `050f11d`, one commit, 82 files added (16 audio + 66 images), A only.
- Triaged first; all 16 taken, none skipped. No site was already in the catalogue (nearest: the @about_buildings pins
  in Ravenna and Assisi, 800 m+ away).
- **Photos:** two dropped, on the contributor's word. The delivered Ponte delle Torri hero is **Gravina in Puglia's
  Ponte Acquedotto**, not Spoleto; it was dropped and `ponte-delle-torri_2` promoted to hero. Ieranto `_4` is the beach
  at Marina del Cantone, not the bay.
- **Coordinates:** one moved. Bosco di San Francesco's supplied point was the Santa Croce complex, mid-walk and ~1.1 km
  from where the script starts; now 43.0747, 12.6071, the north edge of the Upper Basilica lawn (OSM "Piazza Superiore
  di San Francesco"), where FAI's entrance door is in the perimeter wall. Radius 60 m covers the square; the door's exact
  side was not confirmable from a public source. The other 15 kept as supplied: 12 within 35 m of their OSM feature,
  Salerno ~60 m from the atrium, Recanati 107 m from the garden centroid (on the Leopardi study centre beside it), the
  aqueducts 185 m from the Aqua Claudia arches inside the park. Bias 9/11 north, +16.6 m, p = 0.065 (too few to call).
- **Architect tags (Job 5):** Emilio Stramucci (Castel Savoia), Domenico Fontana (Salerno, for the crypt; on the
  contributor's OK). Not tagged: Pistoletto (an artist; the Third Paradise is land art), Ghinelli (designed the earlier
  Rotonda platforms, not today's building), Cardelli (surname only), the Cividale master builders, Palladio (studied the
  Tivoli temple, did not build it).
- **Place questions:** none. `check-place-candidates.py` and `join-places.py --max-move 100` are identical to `main`.
- **Perishable lines in the audio:** the Sila says the site "is closed until further notice" (pinned anyway, on the
  contributor's word); Matera says the castle "has been under restoration … for some years"; Recanati says "the visit
  now includes" projections. Fixing any means re-recording.

## Tours

| Studio | Title | City | Category |
|---|---|---|---|
| AOT | Savoy Castle \| Castel Savoia | Gressoney-Saint-Jean | history |
| NAP | Ieranto Bay \| Baia di Ieranto | Massa Lubrense | natureAndParks |
| TRS | Aquileia Basilica \| Basilica di Aquileia | Aquileia | sacredSites |
| PEG | St Francis's Wood \| Bosco di San Francesco | Assisi | natureAndParks |
| BRI | Tramontano Castle \| Castello Tramontano | Matera | history |
| NAP | Salerno Cathedral \| Duomo di Salerno | Salerno | sacredSites |
| SUF | The Giants of the Sila \| I Giganti della Sila | Spezzano della Sila | natureAndParks |
| RAN | Mausoleum of Theodoric \| Mausoleo di Teodorico | Ravenna | history |
| AOI | Garden on the Hill of the Infinite \| Orto sul Colle dell'Infinito | Recanati | literature |
| RAN | Palace of Theodoric \| Palazzo di Teodorico | Ravenna | history |
| ROM | Park of the Aqueducts \| Parco degli Acquedotti | Rome | natureAndParks |
| TRS | Devil's Bridge \| Ponte del Diavolo | Cividale del Friuli | history |
| PEG | Bridge of Towers \| Ponte delle Torri | Spoleto | architecture |
| AOI | Rotonda a Mare | Senigallia | architecture |
| RAN | Basilica of Sant'Apollinare in Classe \| Sant'Apollinare in Classe | Ravenna | sacredSites |
| ROM | Villa Gregoriana | Tivoli | natureAndParks |

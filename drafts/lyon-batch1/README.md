# Lyon batch 1: Atlas Studio LYS (34 singles), wired 2026-11-14

Source: contributor drop (Dropbox). 34 `output <Name> <lat>, <lon>` folders, scripts numbered 01–34. Each holds
`NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt`, one MP3 (99–132 s, 3,946 s in all) and 1–6 photos at 1200×900 WebP
(144 delivered, 143 shipped: L'Antiquaire `_6` is byte-identical to `_5` and was dropped; Villa Florentine's `_3o`
was read as `_3`). Non-ASCII letters arrive as `#Uxxxx` escapes and were decoded on the unzipped copy first.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_lyon.py` is the assembler
(`python3 -I wire_lyon.py <unzipped drop> <stage dir>`), adapted from `drafts/nice-batch1/tools/wire_nice.py`.
Run it once only. Slugs carry an **`lys-` prefix**: `audio/lys-<slug>.mp3`, `images/lys-<slug>_hero.webp`, `_2.webp`, …

- **Maker:** Atlas Studio LYS 🇫🇷, platform `dozent`, handle `atlas.lys`, uuid5 `atlas-maker:lys`
  = `666b2520-de5e-5261-9834-031e34ca8adb`. The 66th studio.
- **Ids:** `atlas-tour:lys:lys-<slug>`, stops `atlas-stop:lys:lys-<slug>:1`.
- **gh-pages:** `f0c486d`, one commit, 177 files added (34 audio + 143 images), A only.
- Triaged first and approved by the contributor (arthur.yung) "all as proposed": 34 pinned, none skipped.

## Coordinates
`check-coordinates.py --drop`: 0 GROSS. 3 UNVERIFIABLE, read by hand and on their subject: Marché de la Création
(Quai Romain Rolland), Tour Rose (16 Rue du Bœuf), Les Halles (OSM 45.76283, 4.85055). Large-site distances checked by
hand: Lugdunum is on 17 Rue Cléberg; Parc de la Tête d'Or is on the Porte des Enfants du Rhône, as the script says.
**Moved (contributor OK):** Couvent de La Tourette, ~125 m west of the building on the slope → 45.8220812, 4.6253229
(the OSM node *Couvent de la Tourette*).
BIAS: 8/16 north, median +1.7 m, p = 1. No northward offset this time, but n is small.

## Wiring
- Country `France`. City `Lyon` on 31; **Villeurbanne** (town hall), **Éveux** (La Tourette) and **Colombier-Saugnieu**
  (TGV station) are new cities. `priceUSD` 0.
- Geofence 20–30 m for restaurants, bars, shops, hotels and courtyards; 40–60 m for museums, parks, stations and the
  quay market. No overlaps.
- **Bilingual** `English | French` on 13 of 34: La Tourette, Confluences, Cité Musée Tony Garnier, Opéra, Villeurbanne
  town hall, Saint-Exupéry station, Tour Rose, Mur des Canuts, Jardin Rosa Mir, Jardin des Curiosités, Cube Orange,
  Parc de la Tête d'Or, Marché de la Création. Venues, brands and names used as-is keep one.
- Text: `longDescription` = hook + paragraph 3; `shortDescription` cut at 145 characters; captions written by hand from
  each script's orientation paragraph.
- Two tags added after the validator warned: *Notable Building* on Mur des Canuts, *Art* on Jardin des Curiosités.

## Architect tags (Job 5): 12 new names, one line in each list
Déborah Hirigoyen (La Commune) · Iannis Xenakis (La Tourette's windows) · Coop Himmelb(l)au (Confluences) · Robert
Giroud and Môrice Leroux (Villeurbanne) · Jakob + MacFarlane (Cube Orange) · Jacques-Germain Soufflot (Hôtel-Dieu
facade) · Bernard Zehrfuss (Lugdunum) · Antoine-Marie Chenavard and Jean-Marie Pollet (the 1831 opera house) · Tony
Garnier (Cité Tony Garnier) · Denis & Eugène Bühler (Tête d'Or). Existing tags used: Le Corbusier, Jean Nouvel,
Santiago Calatrava.
**Not** tagged: Philippe Starck (MOB: "among the partners"), Sebastiano Serlio (Tour Rose: "linked to"), Vlan Paysages
(Curiosités: "with the help of"), Jules Senis (Rosa Mir: a mason), CitéCréation (muralists).

## Places — for Edward, nothing created or joined
`status/owner/place-lyon.md`: Cour des Voraces (LYS) vs *Cour des Voraces: Lyon's Hidden Traboules* (existing pin),
12 m. `check-place-candidates.py` pairs them; `join-places.py --max-move 100` raised nothing.
Co-located but not places: Lugdunum (museum) is 99 m from the Ancient Theatre of Fourvière pin.

## Not checked
Restaurant awards (Michelin stars, Bib Gourmands) and the 2026 Food & Wine market ranking are quoted from the scripts
and were not verified.

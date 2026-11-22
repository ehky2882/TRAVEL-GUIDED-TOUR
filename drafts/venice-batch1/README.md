# Venice batch 1: Atlas Studio VCE (31 singles), wired 2026-11-22

Source: contributor drop (Dropbox). 31 `output <Name> <lat>, <lon>` folders (one spelled `outut`), scripts numbered
01–31. Each holds `<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3 (89–136 s, 3,485 s in all) and 2–6 photos at
1200×900 WebP (144 delivered, 144 shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_venice.py` is the assembler
(`python3 -I wire_venice.py <unzipped drop> <stage dir>`), adapted from `drafts/florence-batch1/tools/wire_florence.py`.
Run it once only. Slugs carry a **`vce-` prefix**: `audio/vce-<slug>.mp3`, `images/vce-<slug>_hero.webp`, `_2.webp`, …

- **Maker:** Atlas Studio VCE 🇮🇹, platform `dozent`, handle `atlas.vce`, uuid5 `atlas-maker:vce`
  = `e5956ad8-b758-595b-a7e9-364b921c7439`. The 68th studio.
- **Ids:** `atlas-tour:vce:vce-<slug>`, stops `atlas-stop:vce:vce-<slug>:1`.
- **gh-pages:** `8d56664`, one commit, 175 files added (31 audio + 144 images), A only.
- Triaged first. The contributor (arthur.yung) approved "add all 31", with Venissa and Al Gatto Nero listed as Venice.

## Coordinates
`check-coordinates.py --drop`: 2 GROSS, both checked by hand and kept as supplied.
- **Al Timon**: the geocoder matched a different Al Timon (San Polo 3057). OSM's Al Timon, Fondamenta degli Ormesini
  2754, is 15 m from the supplied point.
- **Cimitero di San Michele**: 237 m is to the island's centroid. The supplied point is ~60 m from San Michele in Isola,
  at the landing the script stands you on.

BIAS 11/12 north, median +6.9 m, p = 0.0063: the **northward offset is still present upstream**. Small here, inside
every geofence. 7 UNVERIFIABLE (venue not geocoded); none read as wrong against its script.

## Wiring
- Country `Italy`. City `Venice` on all 31, including Venissa (Mazzorbo) and Al Gatto Nero (Burano), on the
  contributor's instruction. No new city: link pins already covered Venice. `priceUSD` 0.
- Geofence 20 m for restaurants, bars and shops; 25–30 m for hotels and the foundations; 35–60 m for churches,
  bridges, the Dogana, the Giardini and San Michele. San Giorgio Maggiore and the Cini Foundation are 35 m each so
  they do not overlap. No overlaps.
- **Bilingual** `English | Italian` on 11 of 31: Querini Stampalia, Olivetti, Giorgio Cini, Giardini, San Giorgio
  Maggiore, Bovolo, Costituzione, Iuav Tolentini, San Michele, St Mark's, Rialto. Venues, brands and names used as-is
  in English (Punta della Dogana, Libreria Acqua Alta, Fondazione Prada) keep one.
- Text: `longDescription` = hook + paragraph 3; `shortDescription` cut at 145 characters; captions written by hand from
  each script's orientation paragraph. One text fix: a stray `,.` in the Iuav script (text only; audio untouched).
- *Architecture* added to Il Palazzo Experimental after the validator warned it had no Theme tag.

## Architect tags (Job 5): 14 new names, one line in each list
Jacopo Sansovino and Patricia Urquiola (Ca' di Dio) · Dorothée Meilichzon (Il Palazzo Experimental interiors) ·
Gian Giacomo de' Grigi (Palazzo Papadopoli / Aman) · Lodovico Cadorin (Florian's 1858 rooms) · Giuseppe Benoni
(Dogana, with Tadao Ando) · Andrea Palladio (San Giorgio; Cini cloister and refectory) · Baldassare Longhena (Cini
library and staircase) · Domenico Rossi (Ca' Corner della Regina / Prada) · Sverre Fehn (Nordic Pavilion, with Hoffmann
and Scarpa) · Giorgio Spavento (Bovolo) · Vincenzo Scamozzi (Tolentini convent, with Scarpa) · Mauro Codussi (San
Michele in Isola, with Chipperfield) · Antonio da Ponte (Rialto).
**Not** tagged: Giovanni Candi (Bovolo, "some guides"), Simone Sorella (built San Giorgio's front to Palladio's
design), Sergio Los (completed the Iuav gate from Scarpa's design), Mariano Fortuny (not an architect).

## Places — for Edward, nothing created or joined
`status/owner/place-venice.md`: Libreria Acqua Alta (8 m, @chloecotter), St Mark's Basilica (17 m, @urbanistari),
Negozio Olivetti (21 m, @about_buildings), Caffè Florian (25 m, @urbanistari), Fondazione Querini Stampalia (61 m from
the existing place). `join-places.py --max-move 100` raised nothing new from this batch.

## Not checked
Historical claims, dates and awards are quoted from the scripts and were not independently verified.

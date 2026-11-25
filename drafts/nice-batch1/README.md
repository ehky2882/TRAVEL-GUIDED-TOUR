# Nice batch 1: Atlas Studio NCE (32 singles), wired 2026-11-13

Source: contributor drop (Dropbox). 32 `output <Name> <lat>, <lon>` folders, scripts numbered 01–32. Each holds
`NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt`, one MP3 (89–129 s, 3,308 s in all) and 2–6 photos at 1200×900 WebP
(130 delivered, 130 shipped, no byte duplicates). Non-ASCII letters arrive as `#Uxxxx` escapes; they were decoded on the
unzipped copy before `check-coordinates.py` ran, and the assembler matches folders by script number either way.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_nice.py` is the assembler
(`python3 -I wire_nice.py <unzipped drop> <stage dir>`), adapted from `drafts/brasilia-batch1/tools/wire_brasilia.py`.
Run it once only. Slugs carry an **`nce-` prefix**: `audio/nce-<slug>.mp3`, `images/nce-<slug>_hero.webp`, `_2.webp`, …

- **Maker:** Atlas Studio NCE 🇫🇷, platform `dozent`, handle `atlas.nce`, uuid5 `atlas-maker:nce`
  = `d4bc287f-3584-5f25-9479-331c0ee1205d`.
- **Ids:** `atlas-tour:nce:nce-<slug>`, stops `atlas-stop:nce:nce-<slug>:1`.
- **gh-pages:** `66dd828`, one commit, 162 files added (32 audio + 130 images), A only.

## Coordinates
`check-coordinates.py --drop`: 1 GROSS, cleared by hand. The geocoder matched Chez Pipo's other branch in Caucade (6.9 km);
the point is on Rue Bavastro, as the script says. 5 UNVERIFIABLE (cathedral, Negresco, Acchiardo, MAMAC, Chagall), each
read by hand and on their subject; Acchiardo is 11 m from 38 Rue Droite.
**Moved (contributor OK):** Les Délices de Candice, ~72 m north of the shop → 43.696614, 7.27507 (17 Rue de la Préfecture:
script, acceslibre, OSM address point).
BIAS: 12/15 north, median +8.4 m, p = 0.035 — the upstream northward offset looks present but n is small. Not corrected.

## Wiring
- City `Nice`, country `France`, all 32. `priceUSD` 0.
- Geofence 20–25 m for shops, cafés and restaurants (15 m for Chez Acchiardo and Les Distilleries Idéales, 33 m apart);
  40–60 m for buildings, museums, parks and squares. No overlaps.
- **Bilingual** `English | French` on the 7 of 32 where the names differ (MAMAC, Museum of Asian Arts, Saint Joan of Arc,
  Saint Nicholas Cathedral, Castle Hill, Rauba-Capèu War Memorial, Square Head). Venues, brands and names used as-is keep one.
- Text: `longDescription` = hook + paragraph 3; `shortDescription` cut at 145 characters; captions written by hand from
  each script's orientation paragraph.

## Architect tags (Job 5): 15 new names, one line in each list
Édouard-Jean Niermans (Negresco) · Studio Mumbai (Hôtel du Couvent) · René Livieri (Le Plongeoir) · Yves Bayard (MAMAC,
Tête Carrée) · Henri Vidal (MAMAC) · André Hermant (Chagall) · Jean-François Bodin (Matisse, 1993 wing) · Michel Marot
(Villa Arson) · Jacques Droz (Sainte-Jeanne-d'Arc) · Mikhail Preobrazhensky (Saint-Nicolas) · Roger Séassal (Rauba-Capèu)
· Michel Péna (Promenade du Paillon, landscape) · Francis Chapus (Tête Carrée) · Antoine Spinelli (Place Garibaldi) ·
Hans-Georg Tersling (Masséna). Existing tag used: Kenzō Tange (Asian Arts).
**Not** tagged: Sacha Sosno and Alfred Janniot (sculptors), Henri Fisch (Chagall garden, not the subject), Studio
Méditerranée (Couvent co-architect, credited secondarily), Spinelli on Café de Turin (the arcades, not the café).

## Places — for Edward, nothing created or joined
`status/owner/place-nice.md`: Hôtel Le Negresco (NCE) vs Hotel Negresco (@insightcities), 49 m. Found by hand —
`check-place-candidates.py` did not pair them (the names differ). `join-places.py --max-move 100` raised nothing.
Co-located but not places: Café de Turin on Place Garibaldi; Tête Carrée behind MAMAC (~160 m).

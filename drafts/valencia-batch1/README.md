# Valencia batch 1 — Atlas Studio VLC (30 singles) — LIVE 2026-11-01

Source: contributor drop (Dropbox, arthur.yung), 30 `output <Name> <lat>, <lon>` folders with scripts numbered 01–30
(one folder arrived as `outptu …`). Each folder holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt` (title line +
one `[beat]`), one MP3 (102–120 s) and 1–6 photos at 1200×900 WebP (129 in all, no byte duplicates). Accented folder
names arrived mangled by the zip (`Cervecer#U00eda`, `H#U014dch#U014d`); the assembler matches on the folder-name
prefix after the first word.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.

`tools/wire_valencia.py` is the assembler (`python3 -I wire_valencia.py <unzipped drop> <stage dir>`), adapted from
`drafts/santiago-batch1/tools/wire_santiago.py`. Run it once: it refuses colliding tour ids. Slugs carry a **`vlc-`
prefix**: audio at `audio/vlc-<slug>.mp3`, images at `images/vlc-<slug>_hero.webp`, `_2.webp`, … in the drop's order.

## Coordinates
Every coordinate comes from its folder name, except three:
- **Turia Gardens** moved ~320 m from the riverbed between the Trinitat and Real bridges onto OSM's point for the
  **Pont de la Trinitat**, **39.479023, -0.372695**. The script stands mid-bridge, and its dates and "oldest bridge"
  are the Trinitat's. Its "two stone statues of saints" are also right: Ponzanelli's Sant Lluís Bertran and Sant Tomàs de
  Villanueva, moved there from the Pont de Sant Josep in the 1940s.
- **Palace of the Marqués de Dos Aguas** moved ~100 m south onto OSM's point for the palace, **39.4725, -0.3748026**
  (the door faces Carrer del Poeta Querol).
- **Genuí Cosmopolita**: the contributor supplied the farmhouse's own point, **39.57743843741576, -0.47309236114223435**.

`check-coordinates.py --drop` found no GROSS and **no directional bias (8/23 north, median −4.6 m, p = 0.21)**. 19 came
back UNVERIFIABLE, almost all mangled accents. Re-checked by street address: 21 sit within ~60 m. Chapeau (number 5 Carrer
d'Hernán Cortés, contributor-supplied) is ~30 m from the street's Colón end, where number 5 is. Hospes reverse-geocodes
to 14 Navarro Reverter. Espai Alfaro sits in Godella's Obradors industrial estate, as the script says. Cabecera Park
(lake edge) and the Albufera (the Gola de Pujol viewpoint) are areas, given 80 m and 120 m geofences.

## Wiring
- **City:** real municipalities, on the contributor's instruction: **Godella** (Espai Alfaro), **Bétera** (Genuí),
  **Benimantell** (VIVOOD, Alicante province). The Albufera stays **Valencia**: it is inside the city's limits.
- **Geofence:** 40 m for venues; 50 m for Bombas Gens, the Central Market, the Silk Exchange, the Turia bridge, Espai
  Alfaro and Veles e Vents; 60 m for the cathedral square, the Umbracle, Parc Central and Genuí; 80 m for Cabecera and
  VIVOOD; 120 m for the Albufera. No two Valencia tours' circles overlap.
- **Bilingual `English | Valencian`** (the contributor chose Valencian over Spanish) on 9: Cabecera Park | Parc de
  Capçalera, Central Market | Mercat Central, Hortensia Herrero Art Centre (CAHH) | Centre d'Art Hortensia Herrero,
  El Umbracle | L'Umbracle, Turia Gardens | Jardí del Túria, Silk Exchange | Llotja de la Seda, Palace of the Marqués
  de Dos Aguas | Palau del Marqués de Dosaigües, Albufera Natural Park | Parc Natural de l'Albufera, Valencia Cathedral
  | Catedral de València. Venues known by one name keep it.
- **Text:** `longDescription` = hook + paragraph 3, as in Santiago; `shortDescription` cut at 145 characters; `[beat]`
  stripped from the transcript. Captions written by hand from each script's orientation paragraph.

## Architect tags (Job 5): 16 new names, one line in each list
Cayetano Borso di Carminati (Bombas Gens) · Eduardo de Miguel, Arancha Muñoz, Vicente Corell (Cabecera Park) ·
Alejandro Soler March, Francisco Guardia Vial (Central Market) · Ramón Esteve (Chapeau) · Emilio Giménez (Espai Alfaro) ·
Francisco Mora Berenguer (Mercado de Colón, on Habitual) · Pere Compte (Silk Exchange) · Hipólito Rovira (Dos Aguas
portal) · Francisco Javier Goerlich (Palacio Santa Clara) · Kathryn Gustafson (Parc Central) · Daniel Mayo, Agustín
Marí, Pablo Vázquez (VIVOOD).
Existing tags used: Santiago Calatrava, David Chipperfield, Fermín Vázquez, Ricardo Bofill, Annabelle Selldorf.
**Not** tagged: interior designers only (Francesc Rifé, Tomás Alía, Ramón Bandrés, Silvia Bellot, Julio Guixeres), the
sculptor Ignacio Vergara (carved the Dos Aguas portal, did not design it), Fran Silvestre (has an office at Espai
Alfaro), Demetrio Ribes (named only for the station nearby).

## Places
None created. `check-place-candidates` output is identical with and without the batch; `join-places --max-move 100`
found nothing in Spain. **One question for Edward:** El Umbracle is 81 m from the existing *City of Arts and Sciences*
creator pin. That is part-vs-whole, which `docs/places.md` leaves undecided (`status/owner/place-umbracle-city-of-arts.md`).

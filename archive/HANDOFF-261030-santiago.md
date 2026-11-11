# HANDOFF 2026-10-30: Santiago launches (Atlas Studio SCL 🇨🇱, 22 singles)

**What shipped:** a new studio, **Atlas Studio SCL**, the 56th, with 22 single-stop audio tours of Santiago and no walks.
- **Maker:** platform `dozent`, handle `atlas.scl`, uuid5 `atlas-maker:scl` = `3c0fd7b0-53d7-5108-95ff-1a9c7a58af8c`.
- **Ids:** `atlas-tour:scl:scl-<slug>`, stops `atlas-stop:scl:scl-<slug>:1`.
- **Catalogue:** tours 2245 → 2267, makers 727 → 728, stops 2704 → 2726, cities 1076 → 1077, **countries 103 → 104**
  (Chile is new: nothing in the catalogue was in Chile). Places (507) did not move.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 22 folders numbered 01–22. Triage went to
the contributor first; they approved all 22, chose `Santiago` as the city for every tour (including the two mountain
tours), chose "Gran Torre Costanera" as the tower's title, kept Mestizo Italia, and approved the "Cristián Donoso
Atelier & La Clé" title for the folder whose name and script disagreed.
- **Audio:** 100–122 s each. Not transcribed against the scripts.
- **Photos:** 95 delivered and shipped, all 1200×900 WebP, no byte duplicates.
- **Text:** `longDescription` = hook + paragraph 3, as in Turin; `shortDescription` cut at 145 characters; `[beat]`
  stripped from the transcript. Captions written by hand from each script's orientation paragraph.
- **Bilingual `English | Spanish`** on 5 — see `drafts/santiago-batch1/README.md`.

**Coordinates.** `check-coordinates.py --drop`: 2 GROSS — MUT (real, 260 m north) and La Mesa (false: the geocoder
matched "La Buena Mesa" 6 km away) — and 17 UNVERIFIABLE, mostly mangled accents and venue names OSM lacks.
Re-checked by street address and name: 19 of 22 within ~50 m. **Three moved**: MUT 260 m (it sat on El Bosque Norte),
the Pre-Columbian museum ~90 m (north of Bandera 361), Plaza de Armas ~115 m (it sat on Bandera behind the cathedral,
outside the square). Two of the three were displaced north, as was Magnolia by 30 m (left: within its geofence);
bias over the 17 measurable was 10/17 north, median +1.5 m, p = 0.63 — too small a sample to call.

**Architect tags (Job 5), 6 new names on one line in each list:** Smiljan Radić (Pre-Columbian museum's 2014
extension, Mestizo, Mestizo Italia), Cazú Zegers (Hotel Magnolia, the Umbral), Izquierdo Lehmann (Patricia Ready
gallery), Martín Correa and Gabriel Guarda (the Benedictine monastery church), Eduardo Costabal Zegers (the 1929
Magnolia house). Existing tag used: César Pelli (Gran Torre Costanera). **Not** tagged: Elton Léniz (credited only as
working with Izquierdo Lehmann), Felipe Sahli (The Singular's hotelier), Federico Assler (sculptor), Vicente Gajardo
(artist). Radić's 2026 Pritzker, which the Mestizo script states, was checked and is right.

**Places:** none. `check-place-candidates` output is identical with and without the batch; `join-places --max-move 100`
found nothing in Chile. Mestizo and Mestizo Italia are separate buildings, not a place.

**gh-pages:** `91c33081`, one commit adding 117 files (22 audio, 95 images), built with plumbing. Diff was 117 A only.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours (Taller Roca Negra was given `Museum` to
clear a missing-place-type warning) · filenames align (117) · `spine-lookup` 22 answered, 0 failed · no overlapping
geofences among the 22.

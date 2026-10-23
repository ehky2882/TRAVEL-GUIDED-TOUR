# HANDOFF 2026-10-23: Lille launches (Atlas Studio LIL 🇫🇷, 19 singles)

**What shipped:** a new studio, **Atlas Studio LIL**, the 52nd, with 19 single-stop audio tours of Lille and its
metropolis, and no walks.
- **Maker:** platform `dozent`, handle `atlas.lil`, uuid5 `atlas-maker:lil` = `88c4d25c-0e2c-522a-ba1d-e55f60f5ef11`.
- **Ids:** `atlas-tour:lil:<slug>`, stops `atlas-stop:lil:<slug>:1`; every slug starts `lil-`.
- **Catalogue:** tours 2149 → 2168, makers 714 → 715, stops 2608 → 2627, cities 998 → 1002 (Lille, Wasquehal,
  Tourcoing, Croix). Countries (103) and places (507) did not move.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 19 folders numbered 01–20 with no 14.
Triage went to the contributor first; they approved all 19 with titles as proposed and confirmed the photos are good
to use. The missing 14 was asked about and not answered; this batch ships the 19 that exist.
- **Audio:** 103–125 s each. Not transcribed against the scripts. Most clean scripts open with a title line, so a
  recording may open by reading the title (as Helsinki's Central Station and Kuurna).
- **Photos:** 77, no byte duplicates, all 1200×900 WebP; every hero looked at and on-subject. Place aux Oignons and
  Rue de la Clef have one photo each.
- **Text:** `longDescription` = hook + paragraph 3, as in Helsinki; Le Fresnoy's also carries its full name
  ("Le Fresnoy – Studio national des arts contemporains"), since the title is the short name. `shortDescription` cut
  at 145 characters. Captions written by hand from each script's orientation paragraph.
- **Bilingual `English | French`** on 5 tours: Old Stock Exchange | La Vieille Bourse, Lille Opera | Opéra de Lille,
  Wazemmes Market | Marché de Wazemmes, Notre-Dame-de-la-Treille Cathedral | Cathédrale Notre-Dame-de-la-Treille,
  Palace of Fine Arts | Palais des Beaux-Arts de Lille. Venues and names used as-is keep one name.
- **Geofence:** 40 m for venues; 50 m for the Bourse, the Opéra, the cathedral and Le Fresnoy; 60 m for Wazemmes,
  the Palais des Beaux-Arts, Le Tripostal, Rue de la Clef and Villa Cavrois.
- **Perishable content in the audio (flagged to the contributor, shipped as recorded):** Le Fresnoy says *"Panorama 28
  runs until early January 2027"*; Le Tripostal mentions an exhibition *"due to open this autumn"*. Restaurant scripts
  name their current chefs (Le Braque, Le Cerisier, Bienheureux, Sébastopol).

**Coordinates.** `check-coordinates.py --drop`: 0 GROSS, 5 UNVERIFIABLE (the escaped accents in the folder names
defeated the geocoder). Every point was then checked by hand against its script's own street address: all 19 within
75 m (Atelier Kumø, flagged at 389 m, sits at no. 11 between nos. 7 and 13, exactly as the script stands the
listener; the Opéra, flagged at 143 m, is 15 m from the building). Bias: 7/10 north, median +4.1 m, p = 0.34 — not
callable on this sample. No coordinate was moved.

**Architect tags (Job 5), 12 new names on one line in each list:** Julien Destrée (Vieille Bourse), Bernard Tschumi
(Le Fresnoy), Louis-Marie Cordonnier (Opéra), Charles Benvignat (Méert's 1839 interior), César Joly (Halles de
Wazemmes), Charles Leroy and Pierre-Louis Carlier (cathedral), Édouard Bérard, Fernand Delmas, Jean-Marc Ibos and
Myrto Vitart (Palais des Beaux-Arts), Robert Mallet-Stevens (Villa Cavrois). All credited in the tours' own scripts.
Left out: Peter Rice (the cathedral's engineer), Ladislas Kijno and Georges Jeanclos (artists), Victor Baltard (an
influence only), Léonce Hainiez (built the Théâtre Sébastopol, not the restaurant the tour is about).

**Places:** one candidate, for the owner — JaJa and Clivia Nobili, 14 m apart on Rue Saint-André: two different shops,
and co-location is not identity, so my read is **not** a place. `join-places --max-move 100` lists nothing in Lille;
the only nearby entries are the La Piscine pins in Roubaix, an unrelated subject.

**gh-pages:** `055e1a50`, one commit adding 96 files (19 audio, 77 images), built with plumbing. Diff was 96 A only.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (96) ·
`spine-lookup` 19 answered, 0 failed.

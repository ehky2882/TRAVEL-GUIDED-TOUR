# HANDOFF 2026-10-21: Oslo launches (Atlas Studio OSL 🇳🇴, 17 singles)

**What shipped:** a new studio, **Atlas Studio OSL**, the 49th, with 17 single-stop audio tours of Oslo and no walks.
- **Maker:** platform `dozent`, handle `atlas.osl`, uuid5 `atlas-maker:osl` = `69406f5a-56cf-5e65-bd64-d1091e3824ca`.
- **Ids:** `atlas-tour:osl:<slug>`, stops `atlas-stop:osl:<slug>:1`; every slug starts `osl-`.
- **Catalogue:** tours 2103 → 2120, makers 708 → 709, stops 2562 → 2579. Cities, countries and places did not move;
  creator pins already covered Oslo (Holmenkollen is filed as city Oslo).

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 17 folders. Triage went to the
contributor first, and they approved all 17. Script number 16 is absent on purpose.
- **Audio:** 93–115 s each. Not transcribed against the scripts. (élan and Kafeteria August are byte-different but the
  same length to the frame — checked, not a duplicate.)
- **Photos:** 67, no byte duplicates, all 1200×900 WebP. Moniker has one photo; Havnelageret, Summit Bar and Tim
  Wendelboe two. The contributor says all are good to use; no licence recorded per image (on the owner's board).
- **Text:** `longDescription` = hook + paragraph 3, as in Vienna and Warsaw. `shortDescription` cut at 145 characters.
  Captions written by hand from each script's orientation paragraph.
- **Bilingual `English | Norwegian`** on 6 tours: Astrup Fearnley Museet, Holmenkollen skimuseum, Havnelageret
  (English "Harbour Warehouse"; the script's own title was "Langkaia 1 (Havnelageret)"), Oslo rådhus, Operahuset,
  Vigelandsparken. Deichman Bjørvika, MUNCH, Amerikalinjen, Sommerro and the venues keep one name.
- **Geofence:** 40 m for venues; 50 m for museums, City Hall, Opera, Deichman, Havnelageret, Vigeland; 60 m for
  Holmenkollen.

**Coordinates.** `check-coordinates.py --drop` on decoded names: 2 GROSS, both geocoder errors (Sommerro matched a
Sommerro in Marka 10 km away; Aesop matched the Homansbyen shop — the script is Prinsens gate 21, and the supplied
point is 30 m from that address). 6 UNVERIFIABLE, checked by street address or venue name by hand: all 11–73 m, on
their buildings. **MUNCH moved** from the building's north tip to the west quay (59.9058, 10.7546), because the script
stands the listener "on the open quayside at the museum's foot". City Hall sits 45 m north of the centroid on purpose
(the Fridtjof Nansens plass courtyard). 🔴 **Bias: 10/11 north, median +10.4 m, p = 0.012** — the upstream
northward offset seen in Barcelona and Milan is still present. Harmless at these radii, but upstream is not fixed.

**Architect tags (Job 5), 9 new names on one line in each list:** Snøhetta (6 tours — it was not a tag before),
Bjercke & Eliassen, Narud Stokke Wiig, Lundhagem, Bredo Henrik Berntsen, Juan Herreros, Arnstein Arneberg, Magnus
Poulsson, Gustav Vigeland. Reused: Renzo Piano, Atelier Oslo, Julien De Smedt (Holmenkollen, for the jump the script
covers). Narud Stokke Wiig and Vigeland were tagged on the contributor's explicit instruction. Left out: Hjalmar
Welhaven (collector, not the museum's architect) and the artists (Werenskiold, Krohg, Borgfelt, Sørensen, Rolfsen).

**Places, for Edward:** `status/owner/oslo-launch.md`. Opera House (27 m from a pin) and Deichman Bjørvika (24 m from
the existing three-pin place) both qualify in my reading. The Future Library pin is part-vs-whole.

**gh-pages:** `2f6e5a3a`, one commit adding 84 files (17 audio, 67 images), built with plumbing. Diff was 84 A only.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (67) ·
`spine-lookup` 17 answered, 0 failed · `check-place-candidates` and `join-places` as above.

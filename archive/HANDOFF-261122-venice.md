# HANDOFF 2026-11-22: Venice launches (Atlas Studio VCE 🇮🇹, 31 singles)

**What shipped:** a new studio, **Atlas Studio VCE**, the 68th, with 31 single-stop audio tours of Venice and no walks.
- **Maker:** platform `dozent`, handle `atlas.vce`, uuid5 `atlas-maker:vce` = `e5956ad8-b758-595b-a7e9-364b921c7439`.
- **Catalogue:** tours 2630 → 2661, makers 851 → 852, stops 3118 → 3149. Cities (1159), countries (105) and places
  (610) did not move: creator pins already covered Venice, and Venissa (Mazzorbo) and Al Gatto Nero (Burano) are
  listed as Venice on the contributor's instruction.

**Source:** a Dropbox drop from the contributor (arthur.yung), 31 folders. Triaged first; approved "add all 31".
Full wiring record: `drafts/venice-batch1/README.md`.
- Audio 89–136 s, 3,485 s. Photos 144 delivered and shipped. Bilingual on 11 of 31 (Italian).
- gh-pages `8d56664`: 175 A only.

**Coordinates:** 2 GROSS, both false alarms checked by hand (Al Timon matched a namesake; San Michele measured to the
island centroid). Nothing moved. **Bias 11/12, +6.9 m, p = 0.0063: the northward offset is still present upstream.**

**Architect tags (Job 5):** 14 new names on one line in each list. **Places:** five questions for Edward,
`status/owner/place-venice.md` (Acqua Alta, St Mark's, Olivetti, Florian, Querini Stampalia).

**Checks:** `validate-tours-mirror` 0 errors, no warnings from the new tours · filenames align (175) · no geofence
overlaps · `spine-lookup` 31 asked, 0 failed · `join-places --max-move 100` nothing new · `check-place-candidates` only
the five above. Live-URL hash check and `check-image-duplicates --maker VCE`: see the PR.

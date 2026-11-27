# HANDOFF 2026-11-27: Sardinia batch (Atlas Studio CAG 🇮🇹 launches, 4 singles)

**What shipped:** 4 single-stop audio tours from a contributor drop under a new studio, **Atlas Studio CAG** (Cagliari),
the 77th: Batteria Militare Talmone (Palau), Idrovora di Sassu (Arborea), Saline Conti Vecchi (Assemini), Ville Jacques
Couëlle (Arzachena). No walks. The first Atlas content in Sardinia.
- **Maker:** platform `dozent`, handle `atlas.cag`, uuid5 `atlas-maker:cag` = `af7a7d00-f807-59b5-81be-cf0eff2d6d6c`.
- **Catalogue:** tours 2724 → 2728, makers 879 → 880, stops 3212 → 3216, cities 1220 → 1224. Countries (106) and
  places (610) did not move.

**Source:** Dropbox drop, 4 folders, scripts 76, 77, 79, 86. Triaged first, all 4 taken. Full record:
`drafts/sardinia-batch1/README.md`. Audio 103–119 s. Photos 14 delivered and shipped. Bilingual on all 4 (Italian).
gh-pages `2b32475`: 18 A only.

**Coordinates:** Sassu was GROSS (12 km, supplied point near Cabras) and moved onto OSM; Saline (220 m) and Talmone
(94 m) moved onto their OSM features; Couëlle kept as supplied. All on the contributor's OK.
**Architect tags (Job 5):** Flavio Scano, Jacques Couëlle.
**Place questions:** none from the scripts. The @rayisaplace Couëlle pin (1.5 km, Cala di Volpe) is a different site.
**Open:** perishable lines in the Saline ("closed for maintenance") and Couëlle ("not open every day yet") audio.
**Offered, not done:** adding the Jacques Couëlle tag to the @rayisaplace pin — awaiting the contributor's yes.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (18) · `spine-lookup`
4 asked, 0 failed · `join-places --max-move 100` and `check-place-candidates` list nothing new vs main.

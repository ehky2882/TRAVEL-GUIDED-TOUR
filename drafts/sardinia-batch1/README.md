# Sardinia batch 1: Atlas Studio CAG (4 singles), wired 2026-11-27

Source: contributor drop (Dropbox). 4 `output <Name> <lat>, <lon>` folders (scripts 76, 77, 79, 86). Each holds
`<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3 (103–119 s) and 2–6 photos at 1200×900 WebP (14 delivered, 14 shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run on the SUPPLIED points. `tools/wire_sardinia.py` is the
assembler (`python3 -I wire_sardinia.py <unzipped drop> <stage dir>`), adapted from `drafts/puglia-batch1/tools/wire_puglia.py`.
Run it once only. Slugs carry the studio prefix: `audio/cag-<slug>.mp3`, `images/cag-<slug>_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio CAG 🇮🇹 (Cagliari), platform `dozent`, handle `atlas.cag`, uuid5 `atlas-maker:cag` =
  `af7a7d00-f807-59b5-81be-cf0eff2d6d6c`. The 77th studio, inserted after BRI. One studio for all four Sardinian sites,
  on the contributor's choice (arthur.yung: "go, CAG, Arzachena"), over OLB.
- **Ids:** `atlas-tour:cag:cag-<slug>`, stops `atlas-stop:cag:cag-<slug>:1`.
- **gh-pages:** `2b32475`, one commit, 18 files added (4 audio + 14 images), A only.
- Triaged first; all 4 taken, none skipped. The first Atlas content in Sardinia.
- **Coordinates — three moved off the supplied point**, onto the OSM feature by name, approved by the contributor:
  - Idrovora di Sassu: **GROSS, 12 km out.** The folder's point is on SP5 near Cabras, north of Oristano; the script
    and OSM put the station at Arborea. Now 39.8232643, 8.5772244 (OSM building "Idrovora Sassu", SP49).
  - Saline Conti Vecchi: 220 m out in the salt pans; now on the visitor buildings, 39.2239149, 9.0238286.
  - Batteria Militare Talmone: 94 m; now on the OSM ruins, 41.2044453, 9.3395558.
  - Ville Jacques Couëlle: kept as supplied. No OSM node by name; the point reverse-geocodes to Via Monti Tundi,
    Abbiadori, consistent with the script. City is **Arzachena** (contributor's choice over Porto Cervo).
  - 🔴 The Sassu offset is the third wrong point from this upstream pipeline that is not a ~10 m northward bias.
- **Architect tags (Job 5):** Flavio Scano (Idrovora di Sassu), Jacques Couëlle (the villas). Vietti, Busiri Vici and
  Savin Couëlle are mentioned but did not build these villas; Luigi Conti Vecchi reclaimed the lagoon, not a building.
- **Place questions:** none raised by `check-place-candidates.py` or `join-places.py`. Noted for Edward: the
  @rayisaplace pin "The Houses Without Right Angles" (Couëlle, set near Cala di Volpe) is 1.5 km from the villas tour —
  different buildings, so expected to stay separate.
- **Perishable lines in the audio:** Saline Conti Vecchi says the historic rooms are "closed for maintenance at the
  moment"; Ville Couëlle says they "aren't open every day yet". Will date; fixing means re-recording.

## Tours

| Studio | Title | City | Category |
|---|---|---|---|
| CAG | Talmone Battery \| Batteria Militare Talmone | Palau | history |
| CAG | Sassu Pumping Station \| Idrovora di Sassu | Arborea | architecture |
| CAG | Conti Vecchi Saltworks \| Saline Conti Vecchi | Assemini | natureAndParks |
| CAG | Jacques Couëlle Villas \| Ville Jacques Couëlle | Arzachena | architecture |

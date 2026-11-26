# HANDOFF 2026-11-26: Liguria batch (Atlas Studio GOA 🇮🇹 launches, 6 singles)

**What shipped:** 6 single-stop audio tours from a contributor drop, under a new studio, **Atlas Studio GOA** (Genoa
and the Ligurian coast), the 72nd: Villa Rezzola and Tellaro (Lerici), San Fruttuoso Abbey (Camogli), Antica Barberia
Giacalone (Genoa), Casa Carbone (Lavagna), Casa e Collezione Laura (Ospedaletti). No walks.
- **Maker:** platform `dozent`, handle `atlas.goa`, uuid5 `atlas-maker:goa` = `fd5fca23-af5f-5a67-a9d1-4268e5535354`.
- **Catalogue:** tours 2683 → 2689, makers 874 → 875, stops 3171 → 3177, cities 1187 → 1192. Countries (106) and
  places (610) did not move.

**Source:** Dropbox drop, 6 folders, scripts 44–49. Triaged first; the contributor (arthur.yung) chose GOA for all
six, asked for Tellaro (~280 m) and Villa Rezzola (~105 m) to be moved onto the points their scripts stand you at, and
kept Giacalone to one name. Full record: `drafts/liguria-batch1/README.md`.
- Audio 94–114 s. Photos 27 delivered and shipped. Bilingual on 2 of 6 (Italian).
- gh-pages `7db9ac2`: 33 A only.

**Architect tags:** none (no architect credited in any script). **Places:** none.

**Checks:** `validate-tours-mirror` 0 errors, no warnings from the new tours · filenames align (33) ·
`spine-lookup` 6 asked, 0 failed · `join-places --max-move 100` and `check-place-candidates` raised nothing new.

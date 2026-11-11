# HANDOFF 2026-10-22: Helsinki launches (Atlas Studio HEL 🇫🇮, 19 singles)

**What shipped:** a new studio, **Atlas Studio HEL**, the 51st, with 19 single-stop audio tours of Helsinki and no walks.
- **Maker:** platform `dozent`, handle `atlas.hel`, uuid5 `atlas-maker:hel` = `3446cd26-dde6-5c9d-8a09-16ce6c35fd49`.
- **Ids:** `atlas-tour:hel:<slug>`, stops `atlas-stop:hel:<slug>:1`; every slug starts `hel-`.
- **Catalogue:** tours 2130 → 2149, makers 710 → 711, stops 2589 → 2608. Cities (995), countries (103) and places
  (507) did not move; creator pins already covered Helsinki.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 19 folders. Triage went to the
contributor first; they approved all 19 as proposed, said to move the Katajanokka pin, and confirmed there is no
script 17.
- **Audio:** 103–145 s each. Not transcribed against the scripts. (Lokal and Savoy are the same length to the frame
  and byte size, but their decoded audio differs — checked, not a duplicate.) Central Station and Kuurna came from a
  different pipeline whose script starts with a title line; the recording may open by reading the title.
- **Photos:** 70, no byte duplicates, all 1200×900 WebP. Katajanokka and Pataässä have two. The contributor confirmed
  on 2026-10-22 that they are cleared and fine to use; no licence recorded per image (on the owner's board).
- **Text:** `longDescription` = hook + paragraph 3, as in Vienna, Warsaw, Oslo and Belém. `shortDescription` cut at
  145 characters. Captions written by hand from each script's orientation paragraph.
- **Bilingual `English | Finnish`** on 6 tours: Tanssin talo, Hakaniementori, Helsingin päärautatieasema,
  Kulttuurisauna (English "Culture Sauna"), Viinibaari Apotek, Yrjönkadun uimahalli. Business names keep one name
  (Nolla, not Ravintola Nolla; Pataässä; Kuurna; Sea Horse; BasBas Kulma).
- **Geofence:** 40 m for venues; 50 m for the Dance House, Katajanokka and the swimming hall; 60 m for Hakaniemi,
  Central Station and Majamaja.
- **Perishable content in the audio:** opening hours for Artek, Hopia, Apotek, Nolla, Kulttuurisauna and the
  swimming hall's men's/women's days; BasBas mentions Sirkus opening September 2026. Gallery Lemmetti is by
  appointment only (the script says so).

**Coordinates.** `check-coordinates.py --drop`: 0 GROSS, 11 UNVERIFIABLE. Seven of those reverse-geocode onto the
venue by name (Basbas Kulma, Hopia, Yrjönkadun uimahalli, Lokal+, Pataässä, Hakaniementori, Kulttuurisauna); every
point was then checked by hand against the script's own street address: 17 within 25 m, Central Station 65 m from
the station centroid (on Kaivokatu facing the entrance, as the script stands it), Majamaja 74 m from the headland
centroid. **Katajanokka moved** 60.16611, 24.96807 (Linnankatu) → 60.16800, 24.96315 (Luotsikatu 1), ~330 m, on the
contributor's instruction. Bias: 6/11 north, median +3.1 m, p = 1 — no sign of the upstream offset, but the sample
is small.

**Architect tags (Job 5), 11 new names on one line in each list:** Eliel Saarinen (Central Station, Katajanokka),
Herman Gesellius, Armas Lindgren, Selim A. Lindqvist (Katajanokka), JKMM Architects, ILO Architects (Dance House),
Einar Flinckenberg (Hakaniemi market hall), Tuomas Toivonen, Nene Tsuboi (Kulttuurisauna), Pekka Littow (Majamaja),
Väinö Vähäkallio (Yrjönkatu Swimming Hall). Reused: Alvar Aalto, Aino Aalto (Artek, Savoy), Ilse Crawford (Savoy).
All credited in the tours' own scripts. Left out: Tom Dixon (helped launch Artek 2nd Cycle, did not design the
shop), W. G. Palmqvist (the Cable Factory, not the Dance House), IMA Design (Lapuan Kankurit interior — offered as
optional, not picked), Emil Wikström (sculptor).

**Places:** none. `check-place-candidates` and `join-places --max-move 100` list nothing in Helsinki; the four
existing Helsinki pins (National Library Rotunda, Sibelius Monument, Temppeliaukio, Pakila) are unrelated subjects.

**gh-pages:** `265d8963`, one commit adding 89 files (19 audio, 70 images), built with plumbing. Diff was 89 A only.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (89) ·
`spine-lookup` 19 answered, 0 failed.

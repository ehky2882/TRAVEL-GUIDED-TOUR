# HANDOFF 2026-10-15: Mumbai launches (Atlas Studio BOM 🇮🇳, 28 singles)

**What shipped:** a new studio, **Atlas Studio BOM**, the 45th: 28 single-stop audio tours of Mumbai, no walks.
- **Maker:** platform `dozent`, handle `atlas.bom`, uuid5 `atlas-maker:bom` = `c8cebea9-8d66-58ea-97bd-dc4ba3b0bf64`.
- **Ids:** `atlas-tour:bom:<slug>`, stops `atlas-stop:bom:<slug>:1`; every slug starts `bom-`.
- **Catalogue:** tours 1983 → 2011, makers 699 → 700. Cities, countries and places did not move, because creator pins
  already counted Mumbai, India.
- **Naming:** the contributor asked for "Atlas Studio + city abbreviation"; BOM is Mumbai's IATA code.

**Source:** Dropbox drop from arthur.yung (the contributor, not the owner), 28 folders numbered 01–33 with
19, 20, 22, 25 and 27 missing (asked; no answer yet). Triage was put to the contributor first; nothing skipped.
- **Audio:** 102–136 s each, all present. Three were misnamed in the drop and renamed; their durations match their
  scripts (the three longest scripts are the three longest files). Not transcribed against the scripts.
- **Photos:** 73, all already 1200×900; supplied by the contributor, licence unrecorded.
- **Text:** titles bilingual (`English | मराठी`) for the 12 landmarks with a Marathi name; restaurants, hotels, clubs and the school keep one name (proper-noun rule, as SGN and RAK).
  `longDescription` = hook + paragraph 3; `shortDescription` cut at 145 with whitespace collapsed.
- **Geofence:** 40 m venues; 50–75 m for districts, the waterfronts, the beach, the clubs, museums and landmarks.

**Coordinates.** `check-coordinates.py --drop`: 1 GROSS (Chowpatty), 12 UNVERIFIABLE, bias 11/17 north, median +2.5 m,
p = 0.33 (no northward drift). Moved, on the contributor's OK:
- **Bandra–Worli Sea Link** onto Bandra Fort (19.0418641, 72.8183782), where the script stands; was ~870 m south, mid-bay.
- **CSMVS**: its folder had no coordinate; OSM museum node (18.9269268, 72.8326498).
- **Girgaon Chowpatty** ~90 m west off Birla Krida Kendra onto the sand (18.95420, 72.81370).
- **ELCO** and **Taj Mahal Palace** moved exactly onto the existing link pins for the same venues (were 15 m / 10 m off).
- Eau Bar and The Oberoi kept as supplied (contributor: taken from Google Maps).

**Architect tags (Job 5):** Frederick William Stevens (BMC), George Wittet (Gateway; CSMVS), Sitaram Khanderao Vaidya
and D. N. Mirza (Taj), John Adams (Royal Bombay Yacht Club), Claude Batley (Bombay Gymkhana), F. G. B. Hawkins
(Willingdon), J. Campbell and G. E. Gosling (David Sassoon Library). Not tagged: R. F. Chisholm (lost the BMC
competition), Abha Narain Lambah (restoration), Shonan Purie Trehan (interior refresh).

**gh-pages:** `54b2bb94`, 101 added (28 audio, 73 images), nothing modified, built with plumbing on a blobless fetch.

**Checks:** validate-tours-mirror 0 errors, no warnings on the new tours; spine-lookup answered all 28;
check-place-candidates lists ELCO and Taj as EXACT pairs (by design, see above); join-places nothing.

**For Edward:** `status/owner/mumbai-launch.md`: two place questions, photo licences, missing numbers.

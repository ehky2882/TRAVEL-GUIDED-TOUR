# HANDOFF 2026-10-16: Udaipur launches (Atlas Studio UDR 🇮🇳, 23 singles)

**What shipped:** a new studio, **Atlas Studio UDR**, the 46th: 23 single-stop audio tours of Udaipur, no walks.
- **Maker:** platform `dozent`, handle `atlas.udr`, uuid5 `atlas-maker:udr` = `370fb311-760d-5657-8d8d-f27da57914b6`.
- **Ids:** `atlas-tour:udr:<slug>`, stops `atlas-stop:udr:<slug>:1`; every slug starts `udr-`.
- **Catalogue:** tours 2011 → 2034, makers 700 → 701, cities 988 → 990 (Udaipur, and Delwara for RAAS Devigarh).
  Countries and places did not move. Udaipur had no entries at all before this.

**Source:** Dropbox drop from arthur.yung (the contributor, not the owner), 23 folders numbered 01–24; 19 left out on
purpose. Triage was put to the contributor first; nothing skipped. Udaan Park's MP3 was missing in the first download
and added by the contributor.
- **Audio:** 81–116 s each, durations track script length, no duplicates. Not transcribed against the scripts.
- **Photos:** 94, all already 1200×900, no byte duplicates. Contributor: "royalty-free, good to use".
- **Text:** `longDescription` = hook + paragraph 3; `shortDescription` cut at 145. Captions hand-written from each
  script's orientation paragraph (the "Vantage" lines here are bare neighbourhood names).
- **Bilingual titles (`English | हिन्दी`)** on the 7 landmarks, checked against Google Maps' Hindi labels (headless
  Chromium, `hl=hi`): City Palace सिटी पैलेस, Gulab Bagh गुलाब बाग, Fateh Sagar Pal फ़तेह सागर पाल, Karni Mata करणी माता
  (Maps: करणी माता मंदिर), Udaan Park उड़ान पार्क, Old City Market मोचीवाडा (Maps' spelling, adopted). Manjhi Ka Ghat
  kept as मांझी का घाट: Maps lists it as "मांजी राज का घट" (the old name, with घट a typo for घाट) and as अम्बराई घाट.
  Venues keep one name (proper-noun rule, as BOM/SGN/RAK), although Maps has transliterations for them.
- **Geofence:** 40 m venues; 50–75 m for the palace, the fort, the lakeshore, the garden, the market and the parks.

**Coordinates.** `check-coordinates.py --drop`: 1 GROSS (Gulab Bagh, 446 m from the garden centroid — the script stands
at a gate of a large garden; kept, radius 75 m), 17 UNVERIFIABLE (read by hand), bias 8/13 north, median +2.5 m,
p = 0.58, sample too small. Karni Mata: folder point (trailhead) used over the script header's temple point, ~350 m
apart — contributor confirmed the trailhead. Ladu and Tapri Niwas share one point (same site; contributor OK).

**Architect tags (Job 5):** Studio Saar (Third Space; Udaan Park), Studio Rust (Ninkasi's interior). Not tagged:
Viral Munshi (Kaladwas restoration architect — restoration, as Lambah in BOM). Oberoi script names no architect.

**gh-pages:** `68475ef2`, 117 added (23 audio, 94 images), nothing modified, built with plumbing on a blobless fetch.

**Checks:** validate-tours-mirror 0 errors, no warnings on the new tours; spine-lookup answered all 23;
check-place-candidates: Tapri Niwas/Ladu EXACT (co-located shop + tea house) and Ninkasi/Aosa 17 m; join-places nothing.

**For Edward:** `status/owner/udaipur-launch.md`.

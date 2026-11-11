# HANDOFF 2026-10-27: Naples launches (Atlas Studio NAP 🇮🇹, 19 singles)

**What shipped:** a new studio, **Atlas Studio NAP**, the 54th, with 19 single-stop audio tours of Naples and no walks.
- **Maker:** platform `dozent`, handle `atlas.nap`, uuid5 `atlas-maker:nap` = `7e8369f6-3020-5033-9b31-6f2fc5123e8e`.
- **Ids:** `atlas-tour:nap:nap-<slug>`, stops `atlas-stop:nap:nap-<slug>:1`.
- **Catalogue:** tours 2197 → 2216, makers 719 → 720, stops 2656 → 2675. Cities (1004), countries (103) and places
  (507) did not move: creator pins already covered Naples.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 19 folders. Triage went to the contributor
first; they approved all 19, had the two Certosa photos dropped from Castel Sant'Elmo, kept the three Cristallini tours
with the smallest trigger zones, chose plain "Castel Sant'Elmo", kept L'Antiquario's dated "this year" line, and
supplied a new Doctor Vintage point (6 m from the original).
- **Audio:** 103–123 s each. Not transcribed against the scripts.
- **Photos:** 79 delivered, 77 shipped, all 1200×900 WebP, no byte duplicates; every photo looked at. The Ex Chiesa hero
  shows the street corner (with a mural) rather than the facade the script describes; kept as delivered.
- **Text:** `longDescription` = hook + paragraph 3, as in Rotterdam; `shortDescription` cut at 145 characters; `[beat]`
  stripped from the transcript. Captions written by hand from each script's orientation paragraph.
- **Bilingual `English | Italian`** on 3: San Carlo Theatre | Teatro di San Carlo, Cristallini Hypogeum | Ipogeo dei
  Cristallini, Former Church of Santa Maria della Misericordia ai Vergini | Ex Chiesa di Santa Maria della Misericordia
  ai Vergini.
- **Geofence:** 20 m for the Via dei Cristallini trio (still overlapping, 12–21 m apart), 40 m for venues, 50 m for the
  theatre, the Royal Continental and Rua Catalana, 60 m for Castel Sant'Elmo.

**Coordinates.** `check-coordinates.py --drop`: 0 GROSS, 11 UNVERIFIABLE, all then checked by street address in
Nominatim: within ~45 m except the Cristallini pair (street centroid only; both are 12–18 m from the Ipogeo's confirmed
point) and Ex Voto (geocoder picked a Via Carlo Poerio in Torre Annunziata; the supplied point is on the Naples street).
Castel Sant'Elmo is 91 m from OSM's centroid, at the gate ramp as scripted. Bias: 10/14 north, median +14.0 m,
p = 0.18 — not callable on this sample.

**Architect tags (Job 5), 4 new names on one line in each list:** Pedro Luis Escrivá (Castel Sant'Elmo), Giovanni
Antonio Medrano and Antonio Niccolini (San Carlo), Ferdinando Chiaramonte (Royal Continental). Existing tag used:
Gio Ponti (Royal Continental: furniture, rooftop pool, logo). **Not** tagged Roberto Fernandes (engineer), Riccardo
Dalisi (street sculpture, not a building) or Hypereden (SuperOtium's interiors only).

**Places:** none. `check-place-candidates` lists only the Cristallini trio under TIGHT (three businesses side by side;
co-location is not identity); `join-places --max-move 100` found nothing in Naples. ScottoJonno and SuperOtium sit
126–157 m from the existing National Archaeological Museum pin — different subjects.

**gh-pages:** `546fd8f6`, one commit adding 96 files (19 audio, 77 images), built with plumbing. Diff was 96 A only.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (96) ·
`spine-lookup` 19 answered, 0 failed.

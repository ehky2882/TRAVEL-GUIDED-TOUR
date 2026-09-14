# HANDOFF — 2026-09-14: the 19 drop-pipeline coordinate repairs

Second set from the catalogue-wide sweep of 2026-09-12 (report:
https://claude.ai/code/artifact/3a3e10d1-ced8-4837-a5cf-669619c9d48b). The first set, 13
hand-typed locations, is `HANDOFF-260913-coordinates.md` / #881.

Owner: *"fix the next set of 19."*

## What moved

All 19 carried a full-precision (14–15 dp) coordinate from the upstream drop pipeline, and every
one sat **north** of its venue, the same screen-pixel offset Rule 8b describes for Barcelona and
Milan. Each was moved to the spot its own script puts the listener, then reverse-geocoded:

| Entry | Now at | Moved |
|---|---|---|
| Notre-Dame Cathedral Basilica of Saigon | Our Lady of Peace statue, facing the doors | 3.7 km |
| Blue Temple (Wat Rong Suea Ten), Chiang Rai | the temple | 2.8 km |
| Yongma Land, Seoul | the site | 1.5 km |
| Pinacoteca de São Paulo | the Praça da Luz side (the entrance the script describes) | ~930 m |
| Teatro Oficina | 520 Rua Jaceguai | ~855 m |
| Memorial da América Latina | the *Mão* sculpture, which the script opens on | ~730 m |
| MASP | under the building, in the vão livre | ~785 m |
| Edifício Copan | the building | ~740 m |
| Dorasan Station, Paju | the station | ~710 m |
| Baan Kang Wat, Chiang Mai | the courtyard cluster | ~690 m |
| Seodaemun Prison History Hall | 251 Tongil-ro | ~660 m |
| Auditório Ibirapuera (Ibirapuera Park walk stop 1) | the auditorium | ~650 m |
| SESC Pompéia | 93 Rua Clélia | ~640 m |
| Carl Eldhs Ateljémuseum, Stockholm | Bellevueparken | 470 m |
| Wat Asokaram, Samut Prakan | the temple | 420 m |
| Boulders Beach, Cape Town | **the Penguin Viewing Path boardwalk, over Foxy Beach** | 357 m |
| Ho Kham Luang, Chiang Mai | the pavilion | 331 m |
| MAR — Museu de Arte do Rio | the Praça Mauá side | 323 m |
| Cidade das Artes, Rio | the raised plaza | 274 m |

- ⚠️ **Boulders Beach** was placed on the boardwalk, not on the swimming beach OSM names "Boulders
  Beach" 200 m south: the script says *"on the boardwalk above Boulders Beach… you'll spot African
  penguins"*, and the only mapped penguin boardwalk (`Penguin Viewing Path`) overlooks Foxy Beach.
- **Ibirapuera Park walk:** centroid re-derived; `walkingDistanceMeters` 3000 → 2000, because the
  misplaced auditorium stop had added a ~650 m detour to the straight-line route. It is an estimate
  either way; worth a sanity check against the walk's own script if anyone has one.
- No copies this time: each wrong coordinate was used by exactly one entry, and none was a place.
- Checks: `validate-tours.swift` 0 errors, warnings identical to `main`; `validate-tours-mirror.py`
  0 errors, selftest 32/32; seed generates cleanly; place-candidate EXACT and TIGHT identical to `main`.

## Still open

- The **17 "probably off"** locations in the report.
- ~1,140 coordinates the sweep could not verify, weighted toward pipeline cities. The measured
  bias (median +20 m north) means most pipeline entries still sit slightly north; at a 30 m
  geofence that usually still fires, so only the gross ones were moved.

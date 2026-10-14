# HANDOFF 2026-10-14: Hanoi launches (Atlas Studio HAN 🇻🇳, 28 singles)

**What shipped:** a new studio, **Atlas Studio HAN**, the 43rd — 28 single-stop audio tours of Hanoi, no walks.
- **Maker:** platform `dozent`, handle `atlas.han`, uuid5 `atlas-maker:han` = `6d677b5b-b2d9-5435-a040-586c9fb5766b`.
- **Ids:** `atlas-tour:han:<slug>`, stops `atlas-stop:han:<slug>:1`; every slug starts `han-`.
- **Catalogue:** tours 1942 → 1970, makers 680 → 681. Cities and countries did not move: a creator pin
  (Bảo Tàng Đạo Mẫu) already counted Hanoi, Vietnam.
- **Naming:** the contributor asked for "Atlas Studio + city abbreviation"; HAN is Nội Bài's IATA code.

**Source:** Dropbox drop from arthur.yung (the contributor, not the owner), 28 folders numbered 01–28, none missing.
Scripts are in the Atlas British register and cite their sources in a header (every one cites the
"Architecture Hunter Hanoi guide" among others). Triage was put to the contributor first; nothing skipped.
- **Audio:** 127–153 s each. faster-whisper tiny.en on the first 60 s: every file best-matches its own script
  (0 mismatches). Low raw ratios on a few are digits ("10-10", "44B") versus spelled-out numbers, confirmed by reading the transcripts.
  Mémoire 15's MP3 arrived as `M#U00e9moire 15.mp3` (mangled é) and was renamed.
- **Captions** are the script's "Vantage" line; titles are bilingual (`English | Tiếng Việt`) where a Vietnamese
  name exists, as for SGN. `longDescription` = hook + paragraph 3; `shortDescription` cut at 145.
- **Geofence:** 40 m venues; 50–75 m for the district, square, citadel, bridge, large museums and rural sites.

**Coordinates.** `check-coordinates.py --drop`: 0 GROSS, 11 UNVERIFIABLE, bias 9/22 north, median −0.9 m, p = 0.52
(no northward drift). Every unverifiable point was reverse-geocoded onto its stated street by hand.
- **Moved, on the contributor's OK:** Old Quarter onto OSM's Bạch Mã Temple (21.035934, 105.850988; was 74 m east
  at 47 Hàng Buồm). Long Biên Bridge to ~150 m out from the Hanoi abutment (21.04063, 105.85166; was ~470 m out).
- Checked and kept: Citadel 9 m from Đoan Môn; Ba Đình 12 m from the Mausoleum; JW Marriott 102 m from OSM's hotel
  node (lakeside vantage, 75 m radius); Bát Tràng Museum has no OSM node.

**Architect tags (Job 5):** VTN Architects (Bát Tràng House), 1+1>2 Architects (Bát Tràng Museum, Jackfruit
Village), G8A Architecture (Concrete Flakes), gmp Architekten (National Assembly, Ba Đình), Garol Isakovich
(Mausoleum; Hồ Chí Minh Museum), Hà Đức Lịnh (Museum of Ethnology). Carlos Zapata already existed (JW Marriott).
**Gustave Eiffel deliberately NOT on Long Biên** — the script says the attribution is a myth (Daydé et Pillé).
Interior designer Véronique Dollfus and Ernest Hébrard (named, but not the architect of the subject) not tagged.

**gh-pages:** `656d924`, 136 added (28 audio, 108 images), nothing modified, built in a blobless shallow clone.
A first push was rejected because another session moved gh-pages; rebuilt on the new tip.

**Checks:** validate-tours-mirror 0 errors, no warnings on the new tours; check-place-candidates and join-places
have no Hanoi rows; spine-lookup answered all 28.

**For Edward:** `hanoi-photo-licences` (108 photos, licence unrecorded) and `hanoi-editorial-calls` (two private
home addresses, nine commercial venues with Silk Path the weakest, 35 orphan gh-pages files from an abandoned
earlier attempt).

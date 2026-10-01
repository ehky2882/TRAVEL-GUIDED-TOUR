# Handoff 2026-10-01: 54 link pins from 7 creators, 4 architect tags, Wat Rong Khun fix

## What shipped (one PR)
- **54 link pins** triaged from 58 pasted links (2 repeats, so 56 distinct). By creator: IG @ricardotecuenta 27 (Spanish captions), IG @courtneyinruins 13 (Egypt), IG @briandphillips 8, IG @italian_history_with_joseph 3, and one each from IG @archiwhisperer, IG @matthewables (Gadsby's Tavern) and TikTok @agathusstudios (Deplar Farm, a hotel the contributor chose to pin).
- **Skipped by the contributor:** the Estadio Jalisco/Akron two-stadium video and "Angkor" (the whole archaeological park). No same-creator duplicates existed.
- Each pin was minted with a single `--url` run so it could take its own `--title`. Batch mode derives titles from captions, which is useless for Spanish captions.
- **The contributor asked for same-subject pins to be "stacked".** Each such pin sits on the existing entry's exact coordinate. The place grouping itself went to Edward as `status/owner/place-batch-261001.md`, following the skill's rule that only Edward rules on places. `make-places.py` marks 9 of them PROVEN.
- **New architect tags:** John Pawson, Aldo Rossi, Luis Barragán and César Pelli, in `Tag.swift` and `validate-tours.swift`. They were also applied to the two Petronas pins by @pasttworld, San Cataldo by @matter.by.millie, and Cuadra San Cristóbal.
- **Wat Rong Khun (Atlas CNX tour) moved 6.5 km** from 19.8827, 99.7682 to OSM's temple-grounds centroid 19.82388, 99.76290 (stop and centroid). OSM has no separate main-chapel feature, and the trigger radius is 30 m.

## Coordinates worth knowing
- **Chur shelters:** 46.84625, 9.52663 (de.wikipedia). **Sennefer TT96:** OSM tomb node 25.73140, 32.60674. **Casa Cristo:** OSM feature at Pedro Moreno 1612, 20.67556, −103.37081. Nominatim's first answer for "Casa Cristo, Guadalajara" was in Guadalajara, *Spain*, and "Catedral de Guadalajara" returned Sigüenza, so always add Jalisco/México.
- **Spine audit:** three verdicts recorded. Kom El Shoqafa is `wikidata-wrong` (Wikipedia agrees with our point to 20 m). Garuda Wisnu Kencana is `extended-feature` (our point is 8 m from the statue item). Tuna el-Gebel is `extended-feature`. The **Terracotta Army** pin moved to Wikidata's Pit 1 point (34.385, 109.273056).

## Gotchas
- `upload-images.py` got **HTTP 403** from the proxy on `gh api` writes. The git-plumbing route (`--filter=blob:none --depth=1` fetch, one tree, one commit, 55 adds only) worked.
- Nominatim and Wikidata both rate-limit (429) after ~10 quick requests. Space them 2 s apart.

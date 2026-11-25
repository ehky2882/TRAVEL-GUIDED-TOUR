# Handoff 2026-11-18: triage batch, 69 link pins

Contributor: arthur.yung. 82 Instagram links (76 unique, 6 pasted twice) from 16 creators were triaged first, and nothing was minted until the contributor approved.

## Outcome
- **69 pinned** from 14 creators, 52 of them @pauleldwinglade's architecture films. 9 new creators. 26 new cities. 1 new country: **Slovenia** (Plečnik House, Ljubljana). No new place.
- **Skipped (contributor's word):** Clan Jetties, Penang (several jetties) · "Among the Stave Churches of Norway" (several churches) · sand bubbler crabs on The Datai's beach · @drifterkait's Japanese fish-market sashimi bowl (no place named; probably Aomori's Nokke-don, unconfirmed) · `DfzSPgSu6Rt` (embed off, no caption or handle) · @alievanana "art schools" (archive photo, no place).
- **Held:** The Ahwahnee (@preetigills, `DfnsVZDPDb9`, Yosemite Valley 37.746244,-119.5743, history; Notable Building, Venue, Food). Approved. Its caption was read during triage, but the embed then turned into EmbedBrokenMedia, and the link-preview fallback stopped returning og tags from this session. Retry it from a fresh session.
- **Same-creator duplicates:** none. No post was live, and no creator already had a pin of the same subject.
- **Place questions for Edward:** 16 (7 joins, 7 new places, 2 part-vs-whole), on `status/owner/place-triage-261118.md`. Nothing was joined or created.

## How the places were found
- **Cover frames:** the street signs (West St / W 10th St) identified the Holland Hotel at 396 West St. The pink scalloped facade identified Cloud House as Peter Morris's at 20 Vicar's Road, Gospel Oak (Camden planning records).
- **Caption address:** Shokudo Hitonitachi, 渡辺通5-5-5, Fukuoka. Geocoded with GSI at street-number precision.
- **Approximate:** White Eagle Lodge (postcode GU33 7HY centroid; OSM does not map the temple). Kraken wine cellar (the OSM "Kraken" at Dražin Vrt, between Orahovac and Perast, which matches the guides' meeting point).
- Where an entry for the subject already existed, its coordinate was reused, so the place joins are all 0 m.
- **Spine:** one new DISAGREE, Gipsoteca Canoviana (571 m). Ruled `wikidata-wrong` in `checks/spine-verdicts.json`, because the museum's address, Via Canova 74, is the OSM node and the pin.
- Wikipedia and Wikidata returned 429 from this session. Nominatim and GSI worked.

## Mechanics
- Each pin was minted with its own `--url` run, so each could carry its own title, category and tags. The outputs were combined into one pins.json and merged disk-to-disk.
- After the merge, a Theme or Place-type tag was added to the 56 pins that lacked one, chosen by category. The validator reports 0 errors.
- **gh-pages:** plumbing commit e62910e, 69 additions and 0 modifications. `gh` auth was broken in this session.
- Architects with no tag yet: Andrea Palladio, Dorte Mandrup, Jan Santini Aichel, James Gorst. They were not added; that is a Job 5 PR if wanted.

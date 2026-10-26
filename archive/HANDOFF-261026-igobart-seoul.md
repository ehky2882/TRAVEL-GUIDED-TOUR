# Handoff 2026-10-26: 54 Seoul/NYC creator pins (@igobart_ and others)

## What happened
- A contributor pasted 71 Instagram reels and asked for a triage first. Captions came from oEmbed (`make-link-pin.oembed`); every cover frame was opened. Most @igobart_ captions name no place, so subjects were identified from on-screen signs (Teobangnae, Buruttrak, Chamsaejip's "정종.대포"), hashtags (#프랑스 → the French Embassy, #칠궁, #도선사, #수성동계곡, #국립민속박물관), and searching each name in Korean.
- **Approved 56, minted 54.** Two were held because neither has an honest coordinate: `DcS-_PWREdH` (an unnamed building at 28-1 Samcheong-dong) and `DYbvRWfMnGu` (a Namsan staircase, guessed only).
- **Skipped (15), on the contributor's word:**
  - 3 @visitseoul_official reposts of Bart's own videos.
  - Pancho Aréna, a multi-location story.
  - 2 possible ads: Longboat Smoker / LOFOTEN, Hyundai Motorstudio Busan.
  - 9 posts with no identifiable location (listed in the PR).
- Pins were minted one `--url` at a time, because batch mode drops `--title`, and @igobart_'s captions are questions ("Why is this apartment building curved?"), not names.
- **#35 is the Gungsan tunnel, not Gaehwasan.** The caption's #마곡 points at Gungsan (Gayang-dong, found 2008), not the Gaehwasan guess offered in triage.

## Checks
- validate-tours-mirror: 0 errors. New-pin warnings are "no Theme / Place type tag", the same kind as 673 existing ones.
- Hero filenames match the catalog. gh-pages: one commit, 54 `A`, 0 modifications.
- Places:
  - `join-places --max-move 100` found nothing involving the new pins.
  - `check-place-candidates` paired Weir Greenhouse ↔ Green-Wood Cemetery at 155 m. That is part-vs-whole, so it went to the owner.
- spine-match: two new findings, both name collisions: Choansan → Choansan Sports Town, and Japanese House of Flatbush → the Flatbush neighbourhood.

## Lesson
- Overpass is blocked from this container, and Nominatim/Photon return only street centroids for Korean addresses. Wikidata SPARQL by Korean label gave real points for heritage sites (Bongeunsa, Chilgung, Bibong, 4·19 Cemetery, Namyeong-dong).
- Nine coordinates remain street- or site-level. They are listed in `status/owner/igobart-seoul-pins.md`.

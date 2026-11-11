# Handoff 2026-10-07: triage batch, 88 pins (mostly @hungrywolfgrams)

## What happened

A contributor (arthur.yung) pasted 120 Instagram reel links (119 unique), asked for a triage first, then approved most of it.

- **Creators:** @hungrywolfgrams 94 (restaurant reviews), @ricardotecuenta 12, @jenniferdeborahwalker 2, and one each from @archimarathon, @englishheritage, @insightcities, @paris_and_beyond_tours, @breatheart_hk, @pastsighted, @archiwhisperer, @explorehometogether, @southlondonstuff, @gbnews and @nycrehistory.
- **Merged: 88 pins.** That is 76 restaurants (Melbourne/Victoria, Sydney, KL/PJ/Subang Jaya, Bangkok, Seoul, Shanghai, Hong Kong), the Blue House in Seoul, and 11 places from the other creators.
- **Skipped on the contributor's say:** 3 roundups (Melbourne Part 11, Melbourne Part 13, Seoul Part 10), 5 supper clubs in private homes, 2 finished pop-ups, Toddy Shop (possibly closed).
- **Skipped as duplicates:** 10 already live, 2 same-creator repeats (Leça pools, Kossuth mausoleum), and 5 repeats inside the batch. The batch repeats were Brae, Moonah, Yeodongsik (old Lidcombe shop) and two Xip Wah Lau posts, one of them under its old name, Lammeeya.
- **Held for Edward:** `status/owner/triage-batch-261007.md`.
  - Napoleon's Tomb is a tour company's advert. The contributor said pin it, but advertising is Edward's call.
  - Hermès Williamsburg's only image has a play button baked in.
  - Barragunda needs a coordinate.
  - Seagram Building is a place question.

## How the coordinates were found

None of the reels carry a location.

- **Restaurant names:** taken from the @-tag in each caption.
- **Addresses:** web search, then turned into coordinates in this order:
  1. the Michelin Guide page's own map pin (`data-lat`/`data-lng`, the first on the page; later ones are neighbours);
  2. OSM via Nominatim and Photon;
  3. Wikidata P625.
- **Michelin slugs that match no venue return junk coordinates** (Osaka, New York, Lake Como). Only accept a hit inside the right city.
- **Overpass is blocked** by the egress proxy. **The Wikipedia API rate-limited** after one query. The Wikidata SPARQL endpoint worked.
- **From the contributor:** Katsumo, Migak and Ichikawa. The cover frames gave the name and suburb; nothing online gave an address.
- **Street-level only, within roughly 100–200 m:** 4oz Day (Gimsangok-ro), Gai Express (Lorong Datuk Sulaiman 1), Dubu Dubu and Ramen Minamo (both Jalan 24/70A), The Magic Wok (Jalan SS22/35), Chipta 11A (the 7-Eleven it sits beside), Teramoto (between Crown and Bourke on Devonshire St), Yiaga (the Fitzroy Gardens pavilion by the Tudor Village). Tighten them if anyone has a better pin.
- **Rōnin:** "445 Little Collins St" alone geocodes to the Swanston end, about 700 m out. Number 447 resolves properly; that is what was used.

## Mechanics

- **Minting:** pins were minted one URL at a time, so each could carry its own `--title`, category and tags. Batch mode derives titles from captions, and @hungrywolfgrams captions open with a whole paragraph.
- **Title check:** `merge-link-pins.py` refused "A Hereford Beefstouw" as an unverifiable title. That is the restaurant's real name, so it went in with `--allow-unverifiable-title`.
- **Image upload:** `upload-images.py` failed with `gh api` returning 403 through the proxy. The heroes went up as one plumbing commit, `275c457` on gh-pages, after a `--filter=blob:none --depth=1` fetch of gh-pages, which costs 20 MB rather than about 4 GB. That commit holds 89 heroes. The Napoleon hero is among them and is unreferenced until Edward decides.
- **Inline playback:** Instagram withholds the video for 9 of the merged pins because of licensed music, so tapping them opens Instagram.

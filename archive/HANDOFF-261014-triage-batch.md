# Handoff 2026-10-14: triage batch, 52 pins merged

## What happened

A contributor (arthur.yung) pasted 80 links, of which 79 were unique (the Hohenzollern Bridge reel appeared twice). They came from about 35 creators. The contributor asked for a triage first, then said: pin all 59 proposed, skip 12, 48 and 50, and pin overlaps with existing entries because the creators differ.

- **Merged: 52 pins, 17 new creators.**
  - Singapore: @sofunsowhat ×8, Odette.
  - Hong Kong: @always.elin ×6.
  - Beijing, Shanghai and Paris: @mandi.ni_ ×7.
  - Zürich: @uliana_switzerland ×5 and Zürcher Brockenhaus.
  - Paris Le Corbusier and Brno Mies: @sashi_trip_tip.
  - Other singles: Mercury Tower and Grand Lisboa (@pasttworld), Titik Dua (@archimarathon), Brion Tomb (@ninosbuildings), the AWA Tower and Grace Bros pair (@realhistorywalkingtours), and others.
- **Skipped as duplicates (11).**
  - 4 were already live: Steinway Hall, Carnegie Hall, Karen Blixens Plads and Former Kowloon British School.
  - 7 repeated a place the same creator already has: Gandhi Bhawan, the Salgótarjáni cemetery, Maison Ozenfant, Pavillon Suisse, Cité de Refuge, Palihotel Melrose and Balfron Tower. The three sashi_trip_tip short links resolve to the exact videos already pinned. `triage-account.py` missed them because it compares URLs, and these were `vm.tiktok.com` links.
- **Skipped on the contributor's say (3):** Din Tai Fung Beijing (branch unknown), a Shanghai "aesthetic neighbourhood" reel, and a private collector's home in Brooklyn.
- **Held for Edward:** `status/owner/triage-batch-261014.md`. It lists 6 place questions, 7 pins held for a hero, and 6 posts held for an answer.

## The seven held pins

Their posts have embedding off, so the only cover carries a baked-in ▶. A cloud session could not fetch a public-domain replacement, because `upload.wikimedia.org` returned HTTP 429 to every request. Re-mint each with one `make-link-pin.py --url` call. Titles, categories and coordinates:

| Post | Title | Lat, lon | City | Category | Tags |
|---|---|---|---|---|---|
| `instagram.com/reel/DczsMcxM1Jx` | Asador Etxebarri | 43.11591, -2.598439 | Atxondo | foodAndDrink | Food, Venue |
| `instagram.com/reel/DeXbDrONfn1` | Cologne Cathedral | 50.941303, 6.958138 | Cologne | sacredSites | Religious Building, Gothic, Iconic Landmark, Faith |
| `instagram.com/reel/Dc33SnHo9KN` | Hohenzollern Bridge | 50.941437, 6.9657041 | Cologne | architecture | Bridge, Engineering, Iconic Landmark |
| `instagram.com/reel/DdRpnXNIhM4` | Chocolate Museum | 50.931982, 6.9644356 | Cologne | foodAndDrink | Museum, Food |
| `instagram.com/reel/DdhHgZ6Ioh1` | NS-Dok (EL-DE-Haus) | 50.940564, 6.9502382 | Cologne | history | Museum, Remembrance, War, History |
| `instagram.com/reel/DdCLsUmIsT7` | Golden Chamber, St Ursula | 50.945708, 6.9543226 | Cologne | sacredSites | Religious Building, Faith, Hidden Gem |
| `instagram.com/reel/DdmVItao15a` | Motorworld Köln | 50.98076, 6.8982697 | Cologne | hiddenGems | Museum, Free to Visit, Engineering |

## How places were identified

- **Captions:** most posts named their place directly.
- **Cover frames** (`fetch-cover.py`):
  - AWA Tower and the Grace Bros building in Sydney
  - Lama Temple and the National Museum of China
  - Duck de Chine at 1949 The Hidden City
  - the Brion Tomb
  - the Camera Museum
  - Grand Lisboa
- **Video frames:** when the cover was not enough, the reel's own MP4 came from the embed page's `video_url`. Frames were sampled at one every 2 s with ffmpeg and read as a contact sheet.
  - Mercury Tower, Malta: named in the subtitles.
  - Yan Garden 檐庭 at Mandarin Oriental Qianmen: the coaster.
  - Mount Street Printers: the awning.
  - Double RL, 6 Newburgh St, London: the map card and door number.
  - The To Summer shop is the 观香夏铺 concept, not the Hunan Rd flagship; that is why it is held.
- **Addresses:** web search on the venue name (Michelin, Time Out, Goop, Booking). Coordinates came from Nominatim, Hong Kong's ALS geocoder for Wan Chai and Lyndhurst Terrace, and Photon.

**Street-level coordinates only.** Tighten these if anyone has a better pin:

- **Fu 1088:** the Zhenning Rd / Yuyuan Rd corner.
- **Yan Garden:** Caochang 10th Alley inside the hotel.
- **Sanzin:** Av. Hidalgo in Centro. No geocoder places number 1503, so it could be a few hundred metres out.
- **Titik Dua:** Jl. Cok Rai Pudak.

**Wikidata:** the API returned non-JSON from the cloud session. Only SPARQL answered, and it found no labels.

## Mechanics

- **Minting:** pins were minted one URL at a time with `--title`, because batch mode derives titles from captions.
- **Image upload:** `upload-images.py` hit `gh api` 403 through the proxy, as before. The heroes went up as one plumbing commit, `8943ee2` on gh-pages: 52 additions, nothing else. The first push was rejected because gh-pages had moved, so the commit was rebuilt on the new tip.
- **Unused avatars:** two TikTok avatars `make-link-pin.py` wrote, for makers that already exist, were not uploaded.
- **Checks:**
  - Validator: 0 errors, 4290 pins.
  - Hero filenames match the catalogue diff exactly.
  - `spine-lookup.py`: 52 asked, 0 failed.
  - `join-places.py`: nothing for the new pins.
  - `check-place-candidates.py`: the six NAME/NEAR overlaps listed on Edward's board. The TIGHT pairs (MYKA beside Social Goods, Santa Nata beside Lan Fong Yuen, Double RL beside Horatio) are neighbouring businesses, not places.
- **Inline playback:** Instagram withholds the video for 5 of the merged pins (Old Crematorium, Sanzin, Chess Forum, Sun Kwai Heung, Odette), so tapping them opens Instagram.

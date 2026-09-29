# Handoff 2026-09-25: Miami staged — 30 scripts, coordinates, 74 images

Named for its subject: `HANDOFF-260925-six-creator-batch.md` and
`-where-to-taste.md` were already taken. Check the directory before picking a
filename — two handoffs were overwritten on 2026-09-14 by not doing so.

## What happened

The owner delivered **30 Miami tour scripts** (clean + TTS, 01–30, no gaps,
every one paired) and asked for images to be sourced. No audio yet.

Staged on `claude/new-city-staging-260925`. Tracker row landed on `main` the
same session (PR #1089), so `TOTAL PENDING` now reads 30.

Miami will be the **36th bureau** — Atlas Studio MIA,
`aed488af-23d3-514f-90f1-035ca2285d0d`, verified by recomputing ATL's id
against the live catalogue before use. The city had **no Atlas tours** and 39
creator link pins.

## Coordinates — the expensive part

**The scripts carry no coordinates**, only a prose position paragraph. This is
the Atlanta shape, where eleven of thirty derived points came out wrong and
every one was invisible to the validator, to CI and to every URL check.

All 30 were derived, audited and hand-read. `check-coordinates.py` reported
**GROSS none** and **no directional bias** (10/24 north, median −0.0 m,
p = 0.54) — so this drop is *not* from the pipeline that pushed Barcelona and
Milan ~10 m north. Six came back **UNVERIFIABLE**, which is not a pass; each
was reverse-geocoded at its own point and recorded in the pick-map.

**Two coordinates a geocoder returns wrongly** — both caught, both documented:

| subject | what search returns | why it is wrong |
|---|---|---|
| Cuban Memorial Boulevard | the park relation's centroid | the median runs **south** from Calle Ocho while the Bay of Pigs column stands at its **north** end — the centroid is **576 m away** |
| Bayfront Park | a **Metromover station** | search ranks the transit stop above the park |

**Trigger radii are sized per stop (30–120 m), not fixed at 30.** Eleven stops
are written from across the street or along a pedestrian mall, where a 30 m
circle on a building centroid cannot contain the listener. The catalogue
already runs 30–120 m. **Do not normalise them back.**

🔴 **Lummus Park is two different parks 5 km apart** — stop 06 on Miami Beach,
stop 18 downtown. Slugs are `ocean-drive-art-deco` and `lummus-park-downtown`;
**neither may be shortened to `lummus-park`**. That collision is how London's
Natural History Museum played Los Angeles' narration for six and a half weeks.

**Stops 08 and 25 overlap deliberately** — Máximo Gómez Park and the Tower
Theater genuinely share a corner, 33 m apart. Flagged to the owner, left as-is.

## Images — 74 live, hash-verified

206 candidates verified from 1,487 sourced; owner picked 77 across 26 tours;
**74 uploaded and byte-verified live** (all matched, none missing, none
mismatched). All PD/CC0 Commons, so **no attribution is owed** and
`drafts/CREDITS.md` gains no rows.

### Three lessons this batch paid for

1. 🔴 **A 429 is not an empty result.** The Holocaust Memorial first read as
   *zero coverage* — its only query had been throttled. Re-run, it returned 35
   usable candidates and 7 verified. An important subject was one step from
   being reported unsourceable.
2. 🔴 **`verify.py` re-sorted every pool by pixel area**, silently discarding
   the relevance ranking, so the gates kept seeing the biggest wrong-city
   photos. Stop 09 went from 0 verified to 6 the moment it was fixed. The line
   now carries a comment: *ranked order — do NOT re-sort by size*.
3. 🔴 **A gate prompt can be wrong.** Gate B for stop 09 said "a grey marble
   column", copied from the script. The monument is **dark polished granite**,
   so the gate correctly rejected the one right image. ⚠️ **The script's
   "this column of gray marble" does not match the stone — worth telling the
   author.**

### What ranking had to defend against

Sorting by megapixels surfaced whichever wrong-city photo had the best camera:
the **Great Miami River in Ohio** (Dayton, I-75 bridges) for stop 01, a **US
Army 173rd Airborne ceremony** for stop 09 (my own `brigade` token pulled it
up), and **DuPont in Wilmington, Delaware** for stop 14. All correctly rejected
by Gate B, but they wasted verification budget until the ranking was fixed.

### Unsplash contributed nothing

**Zero verified images across 144 candidates.** Stock returns the city, not the
place — `freedom tower miami` has no results at all while `miami` has 4,497.
Use Commons for named subjects; Unsplash only for atmosphere.

## 🔴 Owed

- **Three picks not uploaded** — `dupont-building_hero`,
  `little-haiti-cultural-complex_hero`, `bacardi-building_3`. Wikimedia
  rate-limited after ~2,000 requests and the obtainable copies crop below
  1200×900. **Held rather than shipped upscaled** — two are heroes. All three
  originals are comfortably large; re-fetch the original `upload.wikimedia.org`
  URL when the limit clears. **Nothing needs re-picking.**
- **Four tours have no picks** — 07 `lincoln-road`, 21 `south-pointe-park`,
  27 `overtown-interchange`, 30 `virginia-key-beach`. Candidates are sourced.
- **Four subjects want owner photographs** — `little-haiti-cultural-complex`
  (1 candidate), `gesu-church`, `tower-theater`, `lyric-theater` (3 each).
- **Narration audio for all 30.** Ask for a Dropbox `/scl/fo/` folder link,
  **never** a Transfer `/t/` link — Transfer has no direct-download URL and
  Chromium cannot reach Dropbox through this proxy.

⚠️ `miami-circle_6.webp` shipped with a **1.06× upscale** (crop was 1132×849).
Six percent, not visible — recorded so it is not rediscovered as a defect.


## Update 2026-09-29 — six owner photographs, and an upload path that died

The owner supplied photographs that resolved **three of the four thin subjects**.
All six files are **live and hash-verified** on gh-pages:

| # | slug | hero | gallery kept |
|---|------|------|--------------|
| 25 | `tower-theater` | `tower-theater_hero-2.webp` | `_3` (their earlier Commons pick) |
| 26 | `lyric-theater` | `lyric-theater_hero-2.webp` | `_3` |
| 15 | `gesu-church` | `gesu-church_hero-2.webp` | `_3` |

Each went out under a **new filename** rather than overwriting the live
`_hero.webp`, per Image Pipeline step 9, and each owner's earlier Commons pick was
**preserved as `_3`** rather than discarded — so every gallery gained an image.
Owner-supplied, so **no attribution is owed**.

🔴 **The session's image upload path failed after the third file.** Images 1–3
(Tower, Lyric hero, Gesu) reached `…/images/N.webp` normally; every image after
that rendered in the conversation but **never wrote a file**, across four
attempts and two subjects, with 25 GB free. Not a user error and not fixable
from inside the session. **If images stop arriving, check
`ls <session>/images/` before asking the owner to resend** — and move to a fresh
session rather than retrying.

⚠️ A **ChatGPT `/s/` share link cannot be used as an image source**: it renders
client-side behind auth and exposes no image URL. Ask for a direct file link or
an attachment. If an image ever *is* generated rather than photographed, it must
not ship — Gate A exists to reject exactly that, and a synthetic picture of a
real building is the one failure a listener standing in front of it would catch.

### Still owed after this update

- **Lyric gallery shot** and **South Pointe hero** — both sent, neither arrived.
- **Four tours unpicked**: 07 `lincoln-road`, 21 `south-pointe-park`,
  27 `overtown-interchange`, 30 `virginia-key-beach`.
- **`little-haiti-cultural-complex`** — still one usable Commons image, the
  weakest coverage in the batch; its hero is also one of the three held-back
  re-fetches below.
- **Three Commons re-fetches**, still throttled as of 2026-09-29:
  `dupont-building_hero`, `little-haiti-cultural-complex_hero`,
  `bacardi-building_3`. Held rather than shipped upscaled. Re-fetch the original
  `upload.wikimedia.org` URL. **Nothing needs re-picking.**
- **Narration audio for all 30** — the real gate on Miami going live.

**80 images now live**: 74 Commons + 6 owner.

## Where things are

| | |
|---|---|
| scripts, pick-map, coordinates, image manifest | `claude/new-city-staging-260925`, `drafts/miami-batch1/` |
| tracker row | `main` (PR #1089) |
| 74 images | `gh-pages`, commit `499486e3` |
| picking page | a private Artifact; rebuild from `picks_manifest.json` if needed |


## 🔴 Correction 2026-09-29 — the Commons picks are NOT public domain

**Everything above that says "all PD/CC0 Commons, no attribution owed" is wrong.**
A later session tried to finish the three held-back re-fetches, found the DuPont
photo's Flickr source page says **CC BY 2.0**, and then checked every pick.

**Of the 77 Commons picks (74 on gh-pages plus the 3 held back), at least 61 require attribution.** Only 3 are confirmed CC0.

| licence | picks |
|---|---:|
| CC BY (2.0 / 3.0 / 4.0) | 31 |
| CC BY-SA (2.0 / 3.0 / 4.0) | 30 |
| CC0 | 3 |
| not found in Openverse | 13 |

**This includes all three held-back re-fetches** (DuPont CC BY 2.0, Little Haiti
CC BY 3.0, Bacardi-lit-up CC BY 2.0). **Do not re-fetch and upload them.** Under
the PD-only policy, they are not waiting on a throttle. They need the owner's
decision.

**How it was checked.** Each pick's Commons filename (the manifest's `src`) was
matched exactly against Openverse's Wikimedia index, which records the licence.
Commons filenames are unique, so an exact title match is the same file. The
Commons API itself was still returning **429** to this container, so the
licences could not be read from Commons directly. The 13 "not found" were not
confirmed either way. One is a NARA photograph, which is very likely PD. The
others need a Commons lookup once the throttle clears.

**How it happened.** The pipeline notes say "PD/CC0-only search", but the pool
was evidently drawn from Commons categories with no licence filter. Openverse
applies a `license=cc0,pdm` filter, but Commons category listings apply none.
Nothing in the manifest records a licence (`num, slug, code, name, src, orig,
sha` only), so no later step could have caught it. **Record the licence per pick
at sourcing time.**

**Exposure right now: none in the app.** No Miami tour is wired, and no catalogue
entry points at these files. They are on gh-pages, unreferenced. The 6 owner
photographs are unaffected.

**Owner decision owed** (`status/owner/miami-image-licences.md`):
1. **Approve as CC** and add 61+ rows to `drafts/CREDITS.md`. Those rows must be
   surfaced before Miami ships, as the ledger requires for every CC image.
2. **Swap them** for owner photographs or Unsplash, which needs no credit line.
   Unsplash gave zero verified images for Miami's named subjects, though.
3. **A mix**: keep CC where nothing else exists, swap the rest.

### Per-image licence (Openverse, 2026-09-29)

| file | licence | Commons source |
|---|---|---|
| `royal-palm-hotel-site_hero.webp` | CC0 | View of the Miami River from the South Miami Avenue bridge 2026-04-06.jpg |
| `freedom-tower_hero.webp` | not found | Freedom Tower Miami (top), NE view.jpg |
| `freedom-tower_3.webp` | not found | Miami freedom tower night.jpg |
| `bayfront-park_hero.webp` | not found | Torch of Friendship - panoramio.jpg |
| `bayfront-park_2.webp` | CC0 | Challenger Memorial (Miami) by night (January 2022) - inscription.JPG |
| `bayfront-park_3.webp` | CC0 | Challenger Memorial (Miami) by night (January 2022).JPG |
| `miami-circle_2.webp` | CC BY-SA 3.0 | Miami Circle aerial view with river and tower.JPG |
| `miami-circle_4.webp` | CC BY-SA 3.0 | Miami FL Miami Circle pano01.jpg |
| `brickell-avenue-bridge_hero.webp` | CC BY 2.0 | Brickell Avenue Bridge from northwest in 2015.jpg |
| `brickell-avenue-bridge_2.webp` | CC BY-SA 2.0 | Brickell Avenue Bridge at night with bascule span open (2017).jpg |
| `brickell-avenue-bridge_3.webp` | CC BY 2.0 | Miami River Downtown Miami Florida 1 May 2023.jpg |
| `ocean-drive-art-deco_hero.webp` | CC BY-SA 4.0 | Ocean Drive in the Miami Beach Art Deco Historic District.jpg |
| `ocean-drive-art-deco_2.webp` | CC BY-SA 4.0 | Ocean Drive NB past 11th Street Miami Beach at night.jpeg |
| `ocean-drive-art-deco_3.webp` | CC BY 3.0 | Ocean Drive - panoramio (1).jpg |
| `maximo-gomez-park_hero.webp` | CC BY 2.0 | Domino Park Little Havana, Miami Florida 6 June 2024.jpg |
| `maximo-gomez-park_2.webp` | CC BY-SA 4.0 | Domino Club – Florida Heritage; Máximo Gómez Park (Domino Park), Little Havana, Miami, Florida (2019) (6).jpg |
| `cuban-memorial-boulevard_hero.webp` | CC BY 2.0 | Cuban Memorial Boulevard Calle Ocho Little Havana, Miami 2023.jpg |
| `the-barnacle_hero.webp` | CC BY 2.0 | The Barnacle Coconut Grove (16815440570).jpg |
| `the-barnacle_2.webp` | CC BY 2.0 | The Barnacle Coconut Grove (16815512178).jpg |
| `vizcaya_hero.webp` | CC BY 2.0 | Vizcaya Museum and Gardens 060524 DSC6661.jpg |
| `vizcaya_2.webp` | CC BY 2.0 | Vizcaya Museum and Gardens 060524 DSC6702.jpg |
| `vizcaya_3.webp` | CC BY 2.0 | Vizcaya Museum and Gardens 060524 DSC6700.jpg |
| `vizcaya_4.webp` | CC BY 2.0 | Vizcaya Museum and Gardens 060524 DSC6677.jpg |
| `vizcaya_5.webp` | CC BY 2.0 | Vizcaya Museum and Gardens 060524 DSC6697.jpg |
| `wynwood-walls_hero.webp` | CC BY 2.0 | April 7, 2015 - Wynwood Miami - 07.jpg |
| `wynwood-walls_3.webp` | CC BY 2.0 | Wynwood Mural (16811746490).jpg |
| `wynwood-walls_5.webp` | CC BY 2.0 | Wynwood Murals (12926225503).jpg |
| `wynwood-walls_6.webp` | CC BY 2.0 | April 7, 2015 - Wynwood Miami - 05.jpg |
| `dade-county-courthouse_2.webp` | CC BY 2.0 | The Miami Dade County Flagler Courthouse.jpg |
| `gesu-church_hero.webp` | CC BY-SA 4.0 | Gesu Catholic Church (Miami, Florida).jpg |
| `gesu-church_2.webp` | CC BY 2.0 | Gesu Catholic Church Downtown Miami - exterior - 26 November 2022 - Inscription.jpg |
| `miami-dade-cultural-center_hero.webp` | CC BY 2.0 | Cultural Center Downtown Miami FL, construction in background, 4 May 2023.jpg |
| `miami-dade-cultural-center_2.webp` | CC BY 2.0 | Miami-Dade Cultural Center, Miami FL 7 January 2023 - 05.jpg |
| `miami-dade-cultural-center_3.webp` | CC BY 2.0 | Miami-Dade Cultural Center, Miami FL 7 January 2023 - 04.jpg |
| `miami-dade-cultural-center_4.webp` | CC BY 2.0 | Miami-Dade Cultural Center, Miami FL 7 January 2023 - 06.jpg |
| `miami-dade-cultural-center_5.webp` | CC BY 2.0 | Miami-Dade Cultural Center, Miami FL 7 January 2023 - 03.jpg |
| `ferre-park_hero.webp` | CC BY-SA 4.0 | Bicentennial Park June 2014.JPG |
| `ferre-park_2.webp` | CC BY 2.0 | PAMM MRD 21.jpg |
| `ferre-park_3.webp` | CC BY 2.0 | PAMM MRD 28.jpg |
| `lummus-park-downtown_2.webp` | CC BY 2.0 | Fort Dallas William English Plantation Lummus Park Historic District (30642638520).jpg |
| `lummus-park-downtown_3.webp` | CC BY 2.0 | William Wagner House Circa 1855 Lummus Park Historic District (22765725588).jpg |
| `espanola-way_hero.webp` | not found | Miami Beach - Española Way Reconstruction February 2016 01 View East Mid Street.jpg |
| `casa-casuarina_hero.webp` | CC BY-SA 4.0 | Gianni versace miami home.JPG |
| `casa-casuarina_3.webp` | CC BY-SA 4.0 | Casa Casuarina at night Versace Mansion, hotel restaurant at 1116 Ocean Drive, Miami Beach.jpg |
| `holocaust-memorial-miami-beach_hero.webp` | CC BY-SA 4.0 | Miami Beach - South Beach Monuments - Holocaust Memorial 28.jpg |
| `holocaust-memorial-miami-beach_2.webp` | not found | Reaching sky - Flickr - LANSA301.jpg |
| `holocaust-memorial-miami-beach_3.webp` | CC BY-SA 4.0 | Miami Beach - South Beach Monuments - Holocaust Memorial 01.jpg |
| `fontainebleau_hero.webp` | CC BY 4.0 | Fontainebleau Miami Beach Aerial 2025.jpg |
| `fontainebleau_3.webp` | CC BY-SA 3.0 | Fontainebleau-10.jpg |
| `fontainebleau_4.webp` | CC BY-SA 4.0 | Fontainebleau Miami interior FL3.jpg |
| `tower-theater_hero.webp` | CC BY-SA 4.0 | Tower Theater (Miami, Florida).jpg |
| `lyric-theater_hero.webp` | CC BY-SA 4.0 | Miami Lyric Theater (4).jpg |
| `lyric-theater_2.webp` | CC BY-SA 4.0 | Miami Lyric Theater (1).jpg |
| `royal-palm-hotel-site_2.webp` | not found | TRAFFIC INTERCHANGE CUTS THROUGH THE HEART OF DOWNTOWN MIAMI - NARA - 544634.jpg |
| `freedom-tower_2.webp` | CC BY 2.0 | Miami Florida 2018-01-16 - Freedom Tower.jpg |
| `miami-circle_hero.webp` | CC BY-SA 3.0 | Miami Circle aerial view.JPG |
| `miami-circle_3.webp` | CC BY-SA 3.0 | Brickell Point Site 2012-09-15 16-54-59.jpg |
| `miami-circle_5.webp` | not found | Miami FL Miami Circle plaque01.jpg |
| `miami-circle_6.webp` | not found | Miami Circle (9081683470).jpg |
| `cuban-memorial-boulevard_2.webp` | not found | Josemartibust.jpg |
| `wynwood-walls_2.webp` | CC BY-SA 2.0 | Wynwood Walls Miami Florida October 2013.jpg |
| `wynwood-walls_4.webp` | not found | -RETNA Wynwood Walls (8170950212).jpg |
| `dade-county-courthouse_hero.webp` | CC BY-SA 4.0 | Miami-Dade County Courthouse - Miami - Daniel Di Palma Photography 06.jpg |
| `dupont-building_hero.webp` | CC BY 2.0 (its Flickr source page) (held, not uploaded) | Entrance Alfred I DuPont Building (8344800391).jpg |
| `lummus-park-downtown_hero.webp` | CC BY-SA 4.0 | Lummus Park Historic Distric - Miami - Daniel Di Palma Photography 03.jpg |
| `lummus-park-downtown_4.webp` | CC BY-SA 4.0 | Lummus Park Historic Distric - Miami - Daniel Di Palma Photography 01 Wagner House and Fort Dallas.jpg |
| `lummus-park-downtown_5.webp` | not found | Miami FL Lummus Park HD Wagner Homestead plaque01.jpg |
| `casa-casuarina_2.webp` | CC BY-SA 4.0 | Casa Casuarina Pool.jpg |
| `jewish-museum-of-florida_hero.webp` | CC BY-SA 3.0 | Miami Beach FL Beth Jacob Hall msm01.jpg |
| `jewish-museum-of-florida_2.webp` | CC BY-SA 3.0 | Miami Beach FL Beth Jacob Hall msm07.jpg |
| `fontainebleau_2.webp` | CC BY-SA 3.0 | Fontainebleau-1.jpg |
| `tower-theater_2.webp` | CC BY 2.0 | Tower Theater - Looks Like That 70's show.jpg |
| `bacardi-building_hero.webp` | CC BY-SA 2.0 | 20131012 Miami 3615 Bacardi annex.jpg |
| `bacardi-building_2.webp` | CC BY-SA 2.0 | 20131019 Miami 3688 Bacardi plaza.jpg |
| `bacardi-building_3.webp` | CC BY 2.0 (its Flickr source, via Openverse) (held, not uploaded) | Miami Bacardi Building lit up.jpg |
| `bacardi-building_4.webp` | CC BY-SA 4.0 | Bacardi Building Biscayne Boulevard Miami.jpg |
| `little-haiti-cultural-complex_hero.webp` | CC BY 3.0 (held, not uploaded) | Little Haiti south.jpg |
| `tower-theater_hero-2.webp`, `lyric-theater_hero-2.webp`, `gesu-church_hero-2.webp` + 3 more | owner photograph, no credit owed | — |

## Update 2026-09-29 (later) — South Pointe hero and Lyric gallery shot

The two photos that "never arrived" last session were re-sent and are now on gh-pages
(commit `2d9d2c2b`):

| # | slug | file | role | sha256 |
|---|------|------|------|--------|
| 21 | `south-pointe-park` | `south-pointe-park_hero.webp` | hero | `8ec72f6f9b1d…` |
| 26 | `lyric-theater` | `lyric-theater_4.webp` | gallery (after `_2`, `_3`) | `212703a3a2c6…` |

⚠️ **Both are owner photographs that were edited with an AI tool.** The session flagged the
signs of it (warped sign lettering, smudged crowds, identical 1448×1086 size, no camera
metadata). The owner confirmed *"photo that was edited in AI... just use them"*. **This is
the owner's decision. Do not remove them as a Gate A failure.** Owner-supplied, so no
attribution is owed.

**The upload path still does not write files**, but a pasted image **is** recoverable.
It is stored base64 in the session transcript (`~/.claude/projects/<proj>/<session>.jsonl`,
content blocks with `type: image`). Decode it from there instead of asking the owner to resend.

South Pointe now has a hero; `lincoln-road`, `overtown-interchange` and `virginia-key-beach`
still have no picks.

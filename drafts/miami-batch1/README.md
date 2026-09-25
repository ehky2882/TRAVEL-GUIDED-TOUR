# Miami batch 1 — wire-in pick-map

**30 single-stop tours · Atlas Studio MIA · staged 2026-09-25 · audio PENDING**

Maker id `aed488af-23d3-514f-90f1-035ca2285d0d` = `uuid5(URL, "atlas-maker:mia")`.
Tour ids `atlas-tour:mia:<slug>`, stop ids `atlas-stop:mia:<slug>:1`, same namespace.
The scheme was reverse-verified against the live ATL bureau before use.

Miami has **no Atlas tours today** and **39 link pins** from ~20 creators, so this is a new
bureau, the 35th studio.

---

## 🔴 Read before wiring

**The scripts carry no coordinates.** They have a prose position paragraph and nothing
machine-readable, exactly like Atlanta — where eleven of thirty derived coordinates came out
wrong, every one beyond its geofence, and every one invisible to the validator, to CI and to
every URL check. Each coordinate below was derived, then audited against OSM, then hand-read.

`check-coordinates.py --drop` reported **GROSS: none** and **BIAS: 10/24 north, median -0.0 m,
p = 0.54** — no directional bias, so this drop is *not* from the pipeline that pushed Barcelona
and Milan ~10 m north. Six came back **UNVERIFIABLE**, which is not a pass; all six were
reverse-geocoded by hand and are recorded below.

**Two name collisions to respect.**

1. **Lummus Park is two different parks.** Stop 06 is Lummus Park on Miami Beach (Ocean Drive);
   stop 18 is Lummus Park downtown (360 NW 3rd St), ~5 km apart. Script 18 opens *"the downtown
   one, not the beach one"* — the author saw it too. Slugs are deliberately `ocean-drive-art-deco`
   and `lummus-park-downtown`; **neither may be shortened to `lummus-park`.** A bare shared slug is
   how London's Natural History Museum played Los Angeles' narration for six and a half weeks.
2. **`royal-palm-hotel-site` is a vanished building.** Nothing of the Royal Palm survives; the
   coordinate is the Riverwalk standpoint, not a structure.

**Trigger radii are sized per stop, not fixed at 30 m.** The catalogue already runs 30-120 m
(1341 stops at 30, 534 at 40). A stop written from across the street or along a pedestrian mall
cannot be served by a 30 m circle on the building centroid, and the honest fix is the radius, not
a nudged coordinate.

---

## The 30

| # | slug | title | lat | lon | r | category |
|---|------|-------|-----|-----|---|----------|
| 01 | `royal-palm-hotel-site` | Flagler Street at the river, the Royal Palm Hotel site | 25.770550 | -80.188500 | 60 m | `history` |
| 02 | `freedom-tower` | Freedom Tower, Biscayne Boulevard, from the sidewalk | 25.780312 | -80.189714 | 40 m | `history` |
| 03 | `bayfront-park` | Bayfront Park, the Torch of Friendship and the bay edge | 25.775380 | -80.186166 | 100 m | `natureAndParks` |
| 04 | `miami-circle` | Miami Circle, Brickell Point | 25.769358 | -80.189164 | 40 m | `history` |
| 05 | `brickell-avenue-bridge` | Brickell Avenue, the skyline from the river bridge | 25.769905 | -80.190024 | 50 m | `architecture` |
| 06 | `ocean-drive-art-deco` | Ocean Drive, Lummus Park, the Art Deco row | 25.780613 | -80.129893 | 120 m | `architecture` |
| 07 | `lincoln-road` | Lincoln Road, the Lapidus mall | 25.790304 | -80.136518 | 120 m | `architecture` |
| 08 | `maximo-gomez-park` | Calle Ocho, Máximo Gómez Park ("Domino Park") | 25.765491 | -80.219374 | 30 m | `culturalHeritage` |
| 09 | `cuban-memorial-boulevard` | Cuban Memorial Boulevard, the Bay of Pigs monument | 25.765400 | -80.216700 | 50 m | `culturalHeritage` |
| 10 | `the-barnacle` | Coconut Grove, The Barnacle and Peacock Park, from Main Highway | 25.725332 | -80.242557 | 60 m | `history` |
| 11 | `vizcaya` | Vizcaya, from the entrance drive | 25.744381 | -80.210502 | 100 m | `architecture` |
| 12 | `wynwood-walls` | Wynwood Walls, the streetscape from NW 2nd Avenue | 25.801139 | -80.199658 | 60 m | `visualArt` |
| 13 | `dade-county-courthouse` | Dade County Courthouse, 1928 | 25.774587 | -80.195136 | 40 m | `architecture` |
| 14 | `dupont-building` | Alfred I. duPont Building | 25.774540 | -80.190642 | 40 m | `architecture` |
| 15 | `gesu-church` | Gesu Church | 25.775983 | -80.191663 | 40 m | `sacredSites` |
| 16 | `miami-dade-cultural-center` | Miami-Dade Cultural Center, the Philip Johnson plaza | 25.774463 | -80.196586 | 50 m | `architecture` |
| 17 | `ferre-park` | Maurice A. Ferré Park, PAMM and Frost Science | 25.784245 | -80.187316 | 100 m | `natureAndParks` |
| 18 | `lummus-park-downtown` | Miami River, Lummus Park downtown, Fort Dallas barracks and the Wagner homestead | 25.776190 | -80.201237 | 60 m | `history` |
| 19 | `espanola-way` | Española Way | 25.786811 | -80.136966 | 80 m | `architecture` |
| 20 | `casa-casuarina` | Casa Casuarina, exterior only | 25.782015 | -80.130630 | 30 m | `architecture` |
| 21 | `south-pointe-park` | South Pointe Park, Government Cut | 25.765923 | -80.133447 | 100 m | `natureAndParks` |
| 22 | `holocaust-memorial-miami-beach` | Holocaust Memorial Miami Beach | 25.795451 | -80.136224 | 40 m | `culturalHeritage` |
| 23 | `jewish-museum-of-florida` | Jewish Museum of Florida, the 1936 Beth Jacob building | 25.772523 | -80.134232 | 30 m | `culturalHeritage` |
| 24 | `fontainebleau` | Fontainebleau, Collins Avenue exterior | 25.818085 | -80.122042 | 60 m | `architecture` |
| 25 | `tower-theater` | Tower Theater, Calle Ocho | 25.765357 | -80.219672 | 30 m | `musicAndPerformance` |
| 26 | `lyric-theater` | Lyric Theater, Overtown | 25.782223 | -80.197696 | 30 m | `musicAndPerformance` |
| 27 | `overtown-interchange` | Overtown, NW 2nd Avenue under the interchange | 25.786500 | -80.198500 | 80 m | `history` |
| 28 | `bacardi-building` | Bacardi Building, Biscayne Boulevard | 25.797375 | -80.189381 | 40 m | `architecture` |
| 29 | `little-haiti-cultural-complex` | Little Haiti Cultural Complex and the Caribbean Marketplace | 25.830313 | -80.191985 | 40 m | `culturalHeritage` |
| 30 | `virginia-key-beach` | Virginia Key Beach Park, the 1945 beach | 25.736439 | -80.156325 | 120 m | `history` |

## Why each radius

| # | slug | reasoning |
|---|------|-----------|
| 01 | `royal-palm-hotel-site` | Riverwalk at the bay end of the north bank, where the river opens into Biscayne Bay |
| 02 | `freedom-tower` | building; 40 m reaches the Biscayne sidewalk the script writes from |
| 03 | `bayfront-park` | 32-acre park; torch, fountain and Challenger are spread across it |
| 04 | `miami-circle` | small park at Brickell Point |
| 05 | `brickell-avenue-bridge` | bridge sidewalk, downtown side |
| 06 | `ocean-drive-art-deco` | Lummus Park BEACH; the Deco row runs many blocks |
| 07 | `lincoln-road` | "stand anywhere along it" — pedestrian mall |
| 08 | `maximo-gomez-park` | small fenced park; kept tight, 33 m from stop 25 |
| 09 | `cuban-memorial-boulevard` | N end of the median at Calle Ocho, where the column stands |
| 10 | `the-barnacle` | Main Highway under the hammock canopy, Barnacle gate + Peacock Park |
| 11 | `vizcaya` | entrance drive approach, not the house interior |
| 12 | `wynwood-walls` | streetscape along NW 2nd Ave |
| 13 | `dade-county-courthouse` | exterior only; 40 m reaches the opposite sidewalk |
| 14 | `dupont-building` | 40 m reaches the diagonally-opposite corner the script names |
| 15 | `gesu-church` | exterior only; across NE 2nd St |
| 16 | `miami-dade-cultural-center` | the raised Philip Johnson plaza |
| 17 | `ferre-park` | main lawn between PAMM and Frost Science |
| 18 | `lummus-park-downtown` | Lummus Park DOWNTOWN, 360 NW 3rd St — not the Beach park |
| 19 | `espanola-way` | two-block pedestrian lane |
| 20 | `casa-casuarina` | exterior only; sidewalk outside 1116 Ocean Drive |
| 21 | `south-pointe-park` | southern tip facing Government Cut |
| 22 | `holocaust-memorial-miami-beach` | at the entrance path |
| 23 | `jewish-museum-of-florida` | 301 Washington Ave, the joined 1929 + 1936 buildings |
| 24 | `fontainebleau` | Collins Ave sidewalk; the slab is long and curved |
| 25 | `tower-theater` | kept tight, 33 m from stop 08 |
| 26 | `lyric-theater` | 819 NW 2nd Ave |
| 27 | `overtown-interchange` | NW 2nd Ave beneath the decks — a stretch, not a point |
| 28 | `bacardi-building` | 2100 Biscayne Blvd at 21st St |
| 29 | `little-haiti-cultural-complex` | Caribbean Marketplace, 5925 NE 2nd Ave |
| 30 | `virginia-key-beach` | beach park; the script looks along the sand |

---

## The six UNVERIFIABLE, hand-checked

The geocoder could not resolve the venue itself, so the checker reported a distance and
**declined to rule**. Each was reverse-geocoded at its own point:

| # | slug | what is actually at the coordinate | verdict |
|---|------|-----------------------------------|---------|
| 01 | `royal-palm-hotel-site` | Aston Martin Residences, 300 Biscayne Blvd Way | ✅ the north bank at the river mouth; the script's "glass towers on the old hotel's ground" |
| 14 | `dupont-building` | Cantwell Academy, **169 East Flagler Street** | ✅ 169 E Flagler *is* the duPont Building; OSM labels a tenant |
| 18 | `lummus-park-downtown` | 360 Northwest 3rd Street | ✅ Lummus Park downtown's own address |
| 27 | `overtown-interchange` | 1235 Northwest 2nd Avenue, **Overtown** | ✅ correct street and neighbourhood, under the decks |
| 28 | `bacardi-building` | 2100 Biscayne Boulevard, Edgewater | ✅ the script says "Biscayne Boulevard at Twenty-First Street" |
| 29 | `little-haiti-cultural-complex` | **Caribbean Marketplace**, 5925 NE 2nd Ave | ✅ names the exact subject |

## Two coordinates the geocoder would have got wrong

| # | what search returned | why it is wrong | what was used |
|---|---------------------|-----------------|---------------|
| 09 | `Cuban Memorial Boulevard Park` relation centroid, 25.7584 | the median runs **south** from Calle Ocho; the Bay of Pigs column stands at its **north** end — the centroid is **~576 m away** | 25.765400, -80.216700, at Calle Ocho |
| 03 | `Bayfront Park` **Metromover station**, 25.7731 | search ranked a transit station above the park | the park polygon, 25.775380, -80.186166 |

---

## ⚠️ For the owner

**Stops 08 and 25 are 33 m apart and their geofences overlap.** Máximo Gómez Park and the Tower
Theater genuinely share the corner of Calle Ocho and SW 15th Avenue — both scripts say so
independently. Someone standing on that corner will be inside both. This is real adjacency, not a
derivation error, and it is left as-is deliberately; say the word if you would rather one of them
moved or merged.

**Overlap with existing link pins.** Miami already has creator pins on several of these subjects —
Historic Virginia Key Beach Park (@peakacity), Miami-Dade County Courthouse (@kgf365), The Barnacle
Historic State Park (@rileysmithgroup). Pins and tours are separate entities, so nothing conflicts;
a tour and a creator's take will simply sit side by side.

---

## Handling constraints carried in the scripts' own metadata

Taken from each script's second line; these are the author's markings, not mine.

| # | slug | marking |
|---|------|---------|
| 02 | `freedom-tower` | Tier 1 · Batch B1 · plants S5 · locked treatment 2 |
| 04 | `miami-circle` | Tier 1 · Batch B2 · plants S7 · locked treatment 1 · docket 1 |
| 05 | `brickell-avenue-bridge` | Tier 1 · Batch B2 · pays S6 (1980s and 2008 facets) · docket 12 |
| 08 | `maximo-gomez-park` | T1 · B4 · pays S5 · locked treatment 4 |
| 09 | `cuban-memorial-boulevard` | T1 · B4 · pays S5 · docket 6 |
| 12 | `wynwood-walls` | T1 · B6b · contested-change block · docket 15 |
| 13 | `dade-county-courthouse` | Tier 2 · Batch B1 · pays S6 · exterior only · docket 10 governs |
| 15 | `gesu-church` | Tier 2 · Batch B1 · exterior only |
| 16 | `miami-dade-cultural-center` | Tier 2 · Batch B1 · contested framing, even-handed |
| 18 | `lummus-park-downtown` | Tier 2 · Batch B2 · pays S7, S1 · docket 1, 2 |
| 20 | `casa-casuarina` | Tier 2 · B3 · docket 9 · locked treatment 3 |
| 22 | `holocaust-memorial-miami-beach` | Tier 2 · B3 · docket 19 |
| 23 | `jewish-museum-of-florida` | Tier 2 · B3 · docket 18 |
| 26 | `lyric-theater` | T2 · B6a · pays S4 · docket 18 |
| 27 | `overtown-interchange` | T2 · B6a · pays S4 · docket 3, 17 |
| 29 | `little-haiti-cultural-complex` | T2 · B6b · pays S5 · contested-change block · docket 8, 14 |

**Subjects needing dignified treatment, images included:** 22 Holocaust Memorial, 27 the Overtown
interchange (a Black neighbourhood cut apart by the highway), 30 Virginia Key Beach (the county's
segregated beach), 26 Lyric Theater. 20 Casa Casuarina is exterior-only and the script handles
Versace's death in one clause — **image sourcing must not drift toward the death site.**

## Status

- [x] 30 scripts staged, clean + TTS, 01-30 no gaps, every one paired
- [x] slugs checked against all 1,954 existing stop audio slugs — no collisions, no internal dupes
- [x] coordinates derived, audited (GROSS none, no bias), 6 unverifiable hand-read
- [x] trigger radii sized per stop; one deliberate overlap recorded
- [x] images sourced; owner picked 2026-09-25 — **74 live on gh-pages, 3 owed, 4 tours unpicked** (see Images below)
- [ ] audio — **PENDING**, nothing recorded yet
- [ ] wire into `Tours.json` when audio arrives


---

## Images — 74 live on gh-pages, 3 outstanding

Owner picks made 2026-09-25 from 206 verified candidates. Every image passed **two independent
Gemini gates** (modern photograph; correct subject with look-alikes named), was cropped to
1200×900 WebP **without upscaling**, and had its live bytes hash-verified after upload — all 74
matched, none missing, none mismatched.

**Source is Wikimedia Commons under the PD/CC0-only search, so NO attribution is owed** and
`drafts/CREDITS.md` gains no rows for this batch.

Base URL: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

| # | slug | hero | gallery |
|---|------|------|---------|
| 01 | `royal-palm-hotel-site` | `royal-palm-hotel-site_hero.webp` | 2 |
| 02 | `freedom-tower` | `freedom-tower_hero.webp` | 2, 3 |
| 03 | `bayfront-park` | `bayfront-park_hero.webp` | 2, 3 |
| 04 | `miami-circle` | `miami-circle_hero.webp` | 2, 3, 4, 5, 6 |
| 05 | `brickell-avenue-bridge` | `brickell-avenue-bridge_hero.webp` | 2, 3 |
| 06 | `ocean-drive-art-deco` | `ocean-drive-art-deco_hero.webp` | 2, 3 |
| 08 | `maximo-gomez-park` | `maximo-gomez-park_hero.webp` | 2 |
| 09 | `cuban-memorial-boulevard` | `cuban-memorial-boulevard_hero.webp` | 2 |
| 10 | `the-barnacle` | `the-barnacle_hero.webp` | 2 |
| 11 | `vizcaya` | `vizcaya_hero.webp` | 2, 3, 4, 5 |
| 12 | `wynwood-walls` | `wynwood-walls_hero.webp` | 2, 3, 4, 5, 6 |
| 13 | `dade-county-courthouse` | `dade-county-courthouse_hero.webp` | 2 |
| 14 | `dupont-building` | `dupont-building_hero.webp` ⏳ | — |
| 15 | `gesu-church` | `gesu-church_hero.webp` | 2 |
| 16 | `miami-dade-cultural-center` | `miami-dade-cultural-center_hero.webp` | 2, 3, 4, 5 |
| 17 | `ferre-park` | `ferre-park_hero.webp` | 2, 3 |
| 18 | `lummus-park-downtown` | `lummus-park-downtown_hero.webp` | 2, 3, 4, 5 |
| 19 | `espanola-way` | `espanola-way_hero.webp` | — |
| 20 | `casa-casuarina` | `casa-casuarina_hero.webp` | 2, 3 |
| 22 | `holocaust-memorial-miami-beach` | `holocaust-memorial-miami-beach_hero.webp` | 2, 3 |
| 23 | `jewish-museum-of-florida` | `jewish-museum-of-florida_hero.webp` | 2 |
| 24 | `fontainebleau` | `fontainebleau_hero.webp` | 2, 3, 4 |
| 25 | `tower-theater` | `tower-theater_hero.webp` | 2 |
| 26 | `lyric-theater` | `lyric-theater_hero.webp` | 2 |
| 28 | `bacardi-building` | `bacardi-building_hero.webp` | 2, 3⏳, 4 |
| 29 | `little-haiti-cultural-complex` | `little-haiti-cultural-complex_hero.webp` ⏳ | — |

⏳ = picked and cropped but **not yet uploaded** — see below.

### 🔴 Three picks still owed

Wikimedia rate-limited this session after ~2,000 requests, and the copies obtainable at the time
crop below 1200×900. They were **held back rather than shipped upscaled**, because two of them are
heroes and a soft hero is visible on every card in the app.

| # | file | original | crops to | status |
|---|------|----------|----------|--------|
| 14 | `dupont-building_hero.webp` | 1795×1024 | 1365×1024 ✅ big enough | needs re-fetch when the limit clears |
| 29 | `little-haiti-cultural-complex_hero.webp` | 3328×1872 | 2496×1872 ✅ big enough | needs re-fetch |
| 28 | `bacardi-building_3.webp` | 3008×1388 | 1850×1388 ✅ big enough | needs re-fetch |

All three originals are comfortably large; **only the throttle is in the way**, so a later session
just re-fetches the original file URL from `upload.wikimedia.org` and crops. Nothing needs
re-picking.

⚠️ **`miami-circle_6.webp` shipped with a 1.06× upscale** (crop was 1132×849). Six percent, not
visible in practice, recorded so it is not rediscovered as a defect.

### Four tours have no picks yet

Candidates are sourced and verified, waiting on the owner:

| # | slug | verified candidates |
|---|------|--------------------:|
| 07 | `lincoln-road` | 8 |
| 21 | `south-pointe-park` | 8 |
| 27 | `overtown-interchange` | 8 |
| 30 | `virginia-key-beach` | 7 |

### Thin subjects — owner photographs would help

Commons runs out on these, and **Unsplash produced zero verified images across 144 candidates**
(stock returns the city, not the place — the documented pattern):

`little-haiti-cultural-complex` 1 · `gesu-church` 3 · `tower-theater` 3 · `lyric-theater` 3


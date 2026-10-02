# Boston batch 1: wire-in pick-map

**30 single-stop tours · Atlas Studio BOS (`cebccd48-7b4b-5719-bb5b-194734d5db8e`) · staged 2026-10-02 · scripts only, no audio yet**

The owner's drop (OneDrive folder `260928_BOSTON`) held the author's non-gated corpus: **30 singles (01–30) and 5 walks** (`drafts/boston-walks/`), each as a clean + `_TTS` pair, plus the author's master list, scope proposal and handoff №15. **A further 15 "T3" singles are GATED by the author** (master list §3) and were not written. Do not treat them as missing.

Boston is the **39th studio**. The city already has **28 creator link pins** but no Atlas tours.

## Owed before wire-in
1. **Audio:** 30 MP3s. Name them `<slug>.mp3` from the table below (gh-pages `audio/`).
2. **Images: 28 of 30 tours done (2026-10-02).** Still owed: **22** Hanover Street and **26** Commonwealth Avenue Mall. For each, the picker had no usable or chosen photo, so it needs an owner photo or a re-run.

## Coordinates: derived 2026-10-02, audited
**The scripts carry no coordinates.** Each point was geocoded from the script's own position paragraph against OpenStreetMap (Nominatim; Overpass is blocked from web sessions). The OSM object is named in every row.
- `check-coordinates.py` (`coordinate-audit.txt`): **GROSS none**, and **no directional bias** (11/26 north, median −0.0 m, p = 0.56).
- **Every non-zero distance was read by hand:**
  - `uss-constitution`, 467 m: the checker matched an information board on North Washington St, and our point reverse-geocodes to the ship. OSM's address label says "East Cambridge", but the point is Pier One in Charlestown.
  - `greenway-north-end`, 373 m: the point lies inside the Rose Kennedy Greenway polygon (way 94482763), 40 m from its centroid.
  - The rest are streets, squares or areas with no single point.
- **Four points are computed rather than geocoded**, each sitting where its script stands:
  - 21: the Charles St x Mount Vernon St intersection.
  - 22: Hanover x Prince.
  - 26: the east end of the Mall polygon at Arlington St.
  - 30: Johnston Gate, on the Harvard Yard boundary at Mass Ave.
- **A stop sits ON its subject** (owner, 2026-09-23). Where the script stands across a street or along a mall, the trigger radius is sized to reach the listener (30–120 m). **Do not normalise the radii.**
- **Slugs were checked against every file on gh-pages:** no clashes. Do not shorten them: `long-wharf-boston`, `chinatown-gate-boston` and `kings-chapel` stay as written.

| # | Title | Slug | lat | lon | r (m) | category | script | point / note |
|---|---|---|---|---|---:|---|---|---|
| 01 | Massachusetts State House | `massachusetts-state-house` | 42.358602 | -71.063875 | 60 | architecture | `boston_01_state_house.txt` | building centroid (OSM way 29718019); script stands on the Common's Beacon St path facing north, ~70 m |
| 02 | Boston Common | `boston-common` | 42.355467 | -71.066412 | 100 | natureAndParks | `boston_02_boston_common.txt` | Soldiers and Sailors Monument on Flagstaff Hill (node 358277245), where the script stands; inside the Common |
| 03 | Old State House and the Massacre Site | `old-state-house` | 42.358731 | -71.057468 | 40 | history | `boston_03_old_state_house.txt` | building (way 29608515); script on State St below Devonshire facing the east end |
| 04 | Faneuil Hall | `faneuil-hall` | 42.360034 | -71.056234 | 50 | history | `boston_04_faneuil_hall.txt` | building (way 29551702); script in Dock Square on the city side |
| 05 | Acorn Street and Louisburg Square | `acorn-street-louisburg-square` | 42.358444 | -71.068764 | 50 | architecture | `boston_05_acorn_street_louisburg_square.txt` | Louisburg Square (way 405903268); script at the Mount Vernon St end looking north |
| 06 | Paul Revere House | `paul-revere-house` | 42.363738 | -71.053683 | 30 | history | `boston_06_paul_revere_house.txt` | building (way 240376785) in North Square |
| 07 | Old North Church | `old-north-church` | 42.366316 | -71.054448 | 60 | sacredSites | `boston_07_old_north_church.txt` | church (way 29650592); script at the Unity St end of the Paul Revere Mall facing the church's back |
| 08 | Bunker Hill Monument | `bunker-hill-monument` | 42.376352 | -71.060767 | 60 | history | `boston_08_bunker_hill_monument.txt` | obelisk (way 212124093) in Monument Square |
| 09 | USS Constitution and the Charlestown Navy Yard | `uss-constitution` | 42.372439 | -71.056546 | 60 | history | `boston_09_uss_constitution_navy_yard.txt` | the ship at Pier One (way 166151194); OSM's address label says Cambridge, the point is Charlestown Navy Yard |
| 10 | The Public Garden | `boston-public-garden` | 42.354128 | -71.069899 | 60 | natureAndParks | `boston_10_public_garden.txt` | the lagoon foot bridge (way 822707193), where the script stands |
| 11 | Copley Square | `copley-square` | 42.349985 | -71.076544 | 70 | architecture | `boston_11_copley_square.txt` | square (way 1239199995); script at the central fountain |
| 12 | Fenway Park | `fenway-park` | 42.346461 | -71.097100 | 120 | culturalHeritage | `boston_12_fenway_park.txt` | stadium relation 11188464; script on the Jersey St sidewalk outside |
| 13 | Granary Burying Ground | `granary-burying-ground` | 42.357133 | -71.061785 | 40 | history | `boston_13_granary_burying_ground.txt` | burying ground (way 29861355); script at the Tremont St gateway |
| 14 | Park Street Church | `park-street-church` | 42.356858 | -71.062042 | 40 | sacredSites | `boston_14_park_street_church.txt` | church (way 240317867); script at Park x Tremont |
| 15 | Old South Meeting House | `old-south-meeting-house` | 42.356983 | -71.058377 | 40 | history | `boston_15_old_south_meeting_house.txt` | building (node 367781324); script at Washington x Milk |
| 16 | King's Chapel and its burying ground | `kings-chapel` | 42.358013 | -71.060027 | 40 | sacredSites | `boston_16_kings_chapel.txt` | church (way 29551954); script at Tremont x School |
| 17 | Boston City Hall and Plaza | `boston-city-hall-plaza` | 42.360323 | -71.059098 | 90 | architecture | `boston_17_city_hall_plaza.txt` | plaza (node 7335431272); script on the Congress St side facing City Hall |
| 18 | Quincy Market | `quincy-market` | 42.360208 | -71.054913 | 60 | history | `boston_18_quincy_market.txt` | market hall (way 29573399); script at its east end looking back along it |
| 19 | Robert Gould Shaw and 54th Regiment Memorial | `shaw-54th-memorial` | 42.357481 | -71.063501 | 30 | history | `boston_19_shaw_memorial.txt` | memorial (node 358276404) at Beacon x Park |
| 20 | African Meeting House and Abiel Smith School | `african-meeting-house` | 42.359956 | -71.065471 | 30 | culturalHeritage | `boston_20_african_meeting_house_smith_school.txt` | building (way 405880946) in Smith Court |
| 21 | Charles Street and the Flat of the Hill | `charles-street-beacon-hill` | 42.357781 | -71.070284 | 40 | history | `boston_21_charles_street_flat_of_the_hill.txt` | Charles St x Mount Vernon St intersection (ways 825494584 / 825494585), where the script stands |
| 22 | Hanover Street | `hanover-street-north-end` | 42.364322 | -71.053916 | 50 | culturalHeritage | `boston_22_hanover_street.txt` | Hanover St x Prince St intersection beside St Leonard's (ways 109301987 / 8643944), where the script stands |
| 23 | Copp's Hill Burying Ground | `copps-hill-burying-ground` | 42.367366 | -71.055912 | 50 | history | `boston_23_copps_hill_burying_ground.txt` | burying ground (way 29837117); script at its northwest edge above Snowhill St |
| 24 | The Greenway at the North End | `greenway-north-end` | 42.362281 | -71.055680 | 60 | natureAndParks | `boston_24_greenway_north_end.txt` | North End Parks (node 5922346085); script under the pergola facing Hanover St |
| 25 | Long Wharf | `long-wharf-boston` | 42.360316 | -71.048073 | 80 | history | `boston_25_long_wharf.txt` | Long Wharf (way 29861778); script at the far end by the compass rose |
| 26 | Commonwealth Avenue Mall | `commonwealth-avenue-mall` | 42.353618 | -71.071715 | 60 | natureAndParks | `boston_26_commonwealth_avenue_mall.txt` | east end of the Mall polygon (way 820334088) at Arlington St, where the script stands looking west |
| 27 | The Boston Marathon finish line | `boston-marathon-finish-line` | 42.349751 | -71.078616 | 40 | culturalHeritage | `boston_27_marathon_finish_line.txt` | finish-line node 7644779165 on Boylston St |
| 28 | Christian Science Plaza | `christian-science-plaza` | 42.344457 | -71.083372 | 120 | sacredSites | `boston_28_christian_science_plaza.txt` | plaza (relation 1723651); script at the Huntington Ave end of the reflecting pool |
| 29 | Chinatown Gate | `chinatown-gate-boston` | 42.351189 | -71.059752 | 50 | culturalHeritage | `boston_29_chinatown_gate.txt` | gate (way 212123982, OSM name "China Trade Gate"); script across Surface Rd on the Greenway side |
| 30 | Harvard Yard | `harvard-yard` | 42.374766 | -71.118519 | 50 | history | `boston_30_harvard_yard.txt` | Johnston Gate: the Harvard Yard boundary (relation 17336107) at Mass Ave, 15 m from the 'Mass Ave @ Johnston Gate' stop |

## After wire-in
- **Places:** `boston-city-hall-plaza` (17) sits 92 m from the existing creator pin **Boston City Hall**. A plaza and its building is part-vs-whole, which is explicitly undecided (`docs/places.md`), so put it to the owner. Trinity Church (beside 11) and the Public Library (beside 27) are different subjects, so not places.
- Run `check-place-candidates.py` and `join-places.py --max-move 100` (CLAUDE.md rule 8c).

## The author's open items (handoff №15 §5), for the owner
- **Pronunciation pass before recording:** Faneuil above all; also Abiel, Mather, Schön, Cossutta, McLaughlin, Lansdowne, Cato, Belknap, Copp's, Sasaki, Trumbull, Zakim, Tremont, Boylston.
- **Flag 115:** re-verify the Faneuil Hall renaming status at record time. It is the corpus's one rewrite-risk flag.
- **On-site and outreach flags 57, 86–115:** the master list (not in the repo) carries them.

## Images (owner-picked 2026-10-02, live on gh-pages `56d6b026`)

**Picked in the Boston Image Picks artifact.** All 83 are Unsplash, Pexels or public domain, so no credit is owed. Every candidate passed both Gemini gates (a modern colour photograph; the right subject, with its look-alikes named) and then a by-eye review that pulled 54 of 258. Hashes and sources are in `image-manifest.json`. ⚠️ `chinatown-gate-boston_2.webp` is a panorama crop upscaled about 5%.

| # | Hero | Gallery |
|---|---|---|
| 01 | `massachusetts-state-house_hero.webp` | `massachusetts-state-house_2.webp`, `massachusetts-state-house_3.webp`, `massachusetts-state-house_4.webp` |
| 02 | `boston-common_hero.webp` | `boston-common_2.webp`, `boston-common_3.webp` |
| 03 | `old-state-house_hero.webp` | `old-state-house_2.webp`, `old-state-house_3.webp`, `old-state-house_4.webp` |
| 04 | `faneuil-hall_hero.webp` | `faneuil-hall_2.webp` |
| 05 | `acorn-street-louisburg-square_hero.webp` | `acorn-street-louisburg-square_2.webp`, `acorn-street-louisburg-square_3.webp` |
| 06 | `paul-revere-house_hero-2.webp` (owner photo, 2026-10-02) | `paul-revere-house_hero.webp` (the original pick 06-1, kept under its filename) |
| 07 | `old-north-church_hero-2.webp` (owner photo, 2026-10-02) | `old-north-church_hero.webp` (the original pick 07-1, kept under its filename) |
| 08 | `bunker-hill-monument_hero.webp` (owner photo, 2026-10-02) | — |
| 09 | `uss-constitution_hero.webp` | `uss-constitution_2.webp`, `uss-constitution_3.webp`, `uss-constitution_4.webp` |
| 10 | `boston-public-garden_hero.webp` | `boston-public-garden_2.webp`, `boston-public-garden_3.webp`, `boston-public-garden_4.webp`, `boston-public-garden_5.webp`, `boston-public-garden_6.webp`, `boston-public-garden_7.webp`, `boston-public-garden_8.webp`, `boston-public-garden_9.webp`, `boston-public-garden_10.webp` |
| 11 | `copley-square_hero.webp` | `copley-square_2.webp`, `copley-square_3.webp`, `copley-square_4.webp` |
| 12 | `fenway-park_hero.webp` | `fenway-park_2.webp`, `fenway-park_3.webp`, `fenway-park_4.webp`, `fenway-park_5.webp` |
| 13 | `granary-burying-ground_hero.webp` | — |
| 14 | `park-street-church_hero-2.webp` (owner photo, 2026-10-02) | `park-street-church_hero.webp` (the original pick 14-1, kept under its filename) |
| 15 | `old-south-meeting-house_hero.webp` | `old-south-meeting-house_2.webp`, `old-south-meeting-house_3.webp`, `old-south-meeting-house_4.webp` |
| 16 | `kings-chapel_hero.webp` (owner photo, 2026-10-02) | — |
| 17 | `boston-city-hall-plaza_hero.webp` | `boston-city-hall-plaza_2.webp`, `boston-city-hall-plaza_3.webp`, `boston-city-hall-plaza_4.webp` |
| 18 | `quincy-market_hero.webp` | `quincy-market_2.webp` |
| 19 | `shaw-54th-memorial_hero.webp` (owner photo, 2026-10-02) | — |
| 20 | `african-meeting-house_hero.webp` (owner photo, 2026-10-02; appears to show the Abiel Smith School at Joy St x Smith Court, which the tour also covers) | — |
| 21 | `charles-street-beacon-hill_hero.webp` | `charles-street-beacon-hill_2.webp`, `charles-street-beacon-hill_3.webp`, `charles-street-beacon-hill_4.webp` |
| 23 | `copps-hill-burying-ground_hero.webp` (owner photo, 2026-10-02) | — |
| 24 | `greenway-north-end_hero.webp` | `greenway-north-end_2.webp`, `greenway-north-end_3.webp` |
| 25 | `long-wharf-boston_hero.webp` | `long-wharf-boston_2.webp`, `long-wharf-boston_3.webp`, `long-wharf-boston_4.webp`, `long-wharf-boston_5.webp`, `long-wharf-boston_6.webp` |
| 27 | `boston-marathon-finish-line_hero.webp` | — |
| 28 | `christian-science-plaza_hero.webp` | `christian-science-plaza_2.webp` |
| 29 | `chinatown-gate-boston_hero.webp` | `chinatown-gate-boston_2.webp`, `chinatown-gate-boston_3.webp`, `chinatown-gate-boston_4.webp`, `chinatown-gate-boston_5.webp` |
| 30 | `harvard-yard_hero.webp` | `harvard-yard_2.webp`, `harvard-yard_3.webp`, `harvard-yard_4.webp` |
| W4-4 | `boston-the-other-bank_stop4.webp` | `boston-the-other-bank_stop4-2.webp`, `boston-the-other-bank_stop4-3.webp`, `boston-the-other-bank_stop4-4.webp`, `boston-the-other-bank_stop4-5.webp` |

The `W4-4` row is the walk connective (W4-4, the bridge), not a single tour: `boston-the-other-bank_stop4.webp` is its stop image, and the `-2…-5` files are extras for the W4 walk gallery.

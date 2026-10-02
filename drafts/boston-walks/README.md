# Boston walks W1–W5: wire-in pick-map

**5 multi-stop walks, 29 segments · Atlas Studio BOS (`cebccd48-7b4b-5719-bb5b-194734d5db8e`) · staged 2026-10-02 · scripts only**

The walks come from the same drop as `drafts/boston-batch1/` (the author's handoff №15: *"BOSTON NON-GATED CORPUS COMPLETE — 30 singles + 5 walks"*). Every walk component is a T1/T2 single or a walk-only connective, and **no walk follows the Freedom Trail's route or order** (master list §4).

| Walk | Title | Tour slug | Segments | Spine |
|---|---|---|---:|---|
| W1 | *Downhill* | `boston-downhill-walk` | 6 | S1, the hill that lost its top |
| W2 | *The Second Revolution* | `boston-second-revolution-walk` | 6 | S2 |
| W3 | *Under the Artery* | `boston-under-the-artery-walk` | 6 | S5 + S4 |
| W4 | *The Other Bank* | `boston-the-other-bank-walk` | 5 | S3 |
| W5 | *The Name Above the Door* | `boston-name-above-the-door-walk` | 6 | S8 |

**Ids at wire-in:** uuid5 `atlas-tour:bos:<tour slug>` and `atlas-stop:bos:<tour slug>:<order>`, the Miami walk scheme. **Audio:** `audio/<tour slug>_stop<order>.mp3`. The intro is stop 0.

## Coordinates
- **Every intro shares stop 1's point.** Each intro is spoken from the first stop's standpoint, and existing walks do the same (intro to stop 1 at 0 m on AMNH, Wren's City, Ancient Rome and others).
- **A stop that revisits a single reuses that single's coordinate EXACTLY** (see `drafts/boston-batch1/coordinates.tsv`).
- **The six connectives** were geocoded from their scripts. The OSM object is named in each row.
- ⚠️ **W5-2 (Joy St) is about 35 m from W5-1 (Smith Court)**, so their circles overlap. The script stands at the top of Joy St where Smith Court meets it, so this is intended.

| Stop | Label | lat | lon | r (m) | Audio (owed) | Script | Point / note |
|---|---|---|---|---:|---|---|---|
| W1-0 | Intro | 42.358602 | -71.063875 | 60 | `boston-downhill-walk_stop0.mp3` | `boston_downhill_multistop_00_intro.txt` | reuses single 01 `massachusetts-state-house` exactly |
| W1-1 | Massachusetts State House | 42.358602 | -71.063875 | 60 | `boston-downhill-walk_stop1.mp3` | `boston_downhill_multistop_01_state_house.txt` | reuses single 01 `massachusetts-state-house` exactly |
| W1-2 | Charles Street and the flat | 42.357781 | -71.070284 | 40 | `boston-downhill-walk_stop2.mp3` | `boston_downhill_multistop_02_charles_street.txt` | reuses single 21 `charles-street-beacon-hill` exactly |
| W1-3 | Public Garden | 42.354128 | -71.069899 | 60 | `boston-downhill-walk_stop3.mp3` | `boston_downhill_multistop_03_public_garden.txt` | reuses single 10 `boston-public-garden` exactly |
| W1-4 | Commonwealth Avenue Mall | 42.353618 | -71.071715 | 60 | `boston-downhill-walk_stop4.mp3` | `boston_downhill_multistop_04_commonwealth_avenue_mall.txt` | reuses single 26 `commonwealth-avenue-mall` exactly |
| W1-5 | Copley Square | 42.349985 | -71.076544 | 70 | `boston-downhill-walk_stop5.mp3` | `boston_downhill_multistop_05_copley_square.txt` | reuses single 11 `copley-square` exactly |
| W2-0 | Intro | 42.358731 | -71.057468 | 40 | `boston-second-revolution-walk_stop0.mp3` | `boston_second_revolution_multistop_00_intro.txt` | reuses single 03 `old-state-house` exactly |
| W2-1 | Old State House | 42.358731 | -71.057468 | 40 | `boston-second-revolution-walk_stop1.mp3` | `boston_second_revolution_multistop_01_old_state_house.txt` | reuses single 03 `old-state-house` exactly |
| W2-2 | Granary Burying Ground | 42.357133 | -71.061785 | 40 | `boston-second-revolution-walk_stop2.mp3` | `boston_second_revolution_multistop_02_granary_burying_ground.txt` | reuses single 13 `granary-burying-ground` exactly |
| W2-3 | Park Street Church | 42.356858 | -71.062042 | 40 | `boston-second-revolution-walk_stop3.mp3` | `boston_second_revolution_multistop_03_park_street_church.txt` | reuses single 14 `park-street-church` exactly |
| W2-4 | Shaw Memorial | 42.357481 | -71.063501 | 30 | `boston-second-revolution-walk_stop4.mp3` | `boston_second_revolution_multistop_04_shaw_memorial.txt` | reuses single 19 `shaw-54th-memorial` exactly |
| W2-5 | Phillips Street (connective) | 42.360191 | -71.069047 | 30 | `boston-second-revolution-walk_stop5.mp3` | `boston_second_revolution_multistop_05_phillips_street.txt` | new: Lewis and Harriet Hayden House, 66 Phillips St (OSM way 405841672); script on the sidewalk opposite |
| W3-0 | Intro | 42.360323 | -71.059098 | 90 | `boston-under-the-artery-walk_stop0.mp3` | `boston_under_the_artery_multistop_00_intro.txt` | reuses single 17 `boston-city-hall-plaza` exactly |
| W3-1 | City Hall Plaza | 42.360323 | -71.059098 | 90 | `boston-under-the-artery-walk_stop1.mp3` | `boston_under_the_artery_multistop_01_city_hall_plaza.txt` | reuses single 17 `boston-city-hall-plaza` exactly |
| W3-2 | Haymarket stalls (connective) | 42.361507 | -71.056176 | 50 | `boston-under-the-artery-walk_stop2.mp3` | `boston_under_the_artery_multistop_02_haymarket_stalls.txt` | new: Blackstone Street (OSM way 8651226) |
| W3-3 | The Greenway at Hanover Street | 42.362281 | -71.055680 | 60 | `boston-under-the-artery-walk_stop3.mp3` | `boston_under_the_artery_multistop_03_greenway_hanover_crossing.txt` | reuses single 24 `greenway-north-end` exactly |
| W3-4 | Hanover Street | 42.364322 | -71.053916 | 50 | `boston-under-the-artery-walk_stop4.mp3` | `boston_under_the_artery_multistop_04_hanover_street.txt` | reuses single 22 `hanover-street-north-end` exactly |
| W3-5 | Copp's Hill Burying Ground | 42.367366 | -71.055912 | 50 | `boston-under-the-artery-walk_stop5.mp3` | `boston_under_the_artery_multistop_05_copps_hill.txt` | reuses single 23 `copps-hill-burying-ground` exactly |
| W4-0 | Intro | 42.372439 | -71.056546 | 60 | `boston-the-other-bank-walk_stop0.mp3` | `boston_the_other_bank_multistop_00_intro.txt` | reuses single 09 `uss-constitution` exactly |
| W4-1 | USS Constitution and the Navy Yard | 42.372439 | -71.056546 | 60 | `boston-the-other-bank-walk_stop1.mp3` | `boston_the_other_bank_multistop_01_uss_constitution.txt` | reuses single 09 `uss-constitution` exactly |
| W4-2 | Bunker Hill Monument | 42.376352 | -71.060767 | 60 | `boston-the-other-bank-walk_stop2.mp3` | `boston_the_other_bank_multistop_02_bunker_hill.txt` | reuses single 08 `bunker-hill-monument` exactly |
| W4-3 | City Square (connective) | 42.371628 | -71.061930 | 50 | `boston-the-other-bank-walk_stop3.mp3` | `boston_the_other_bank_multistop_03_city_square.txt` | new: City Square Park (OSM way 29836178) |
| W4-4 | Charlestown Bridge (connective) | 42.368545 | -71.059621 | 60 | `boston-the-other-bank-walk_stop4.mp3` | `boston_the_other_bank_multistop_04_charlestown_bridge.txt` | new: middle of the bridge (OSM way 833702344, now named the William Felton "Bill" Russell Bridge) |
| W5-0 | Intro | 42.359956 | -71.065471 | 30 | `boston-name-above-the-door-walk_stop0.mp3` | `boston_the_name_above_the_door_multistop_00_intro.txt` | reuses single 20 `african-meeting-house` exactly |
| W5-1 | Smith Court, the African Meeting House | 42.359956 | -71.065471 | 30 | `boston-name-above-the-door-walk_stop1.mp3` | `boston_the_name_above_the_door_multistop_01_smith_court.txt` | reuses single 20 `african-meeting-house` exactly |
| W5-2 | Joy Street (connective) | 42.360065 | -71.065077 | 40 | `boston-name-above-the-door-walk_stop2.mp3` | `boston_the_name_above_the_door_multistop_02_joy_street.txt` | new: Joy St x Smith Court, top of the slope |
| W5-3 | Government Center (connective) | 42.359683 | -71.059335 | 50 | `boston-name-above-the-door-walk_stop3.mp3` | `boston_the_name_above_the_door_multistop_03_government_center.txt` | new: Government Center station headhouse on the plaza edge (OSM node 13879289318) |
| W5-4 | Quincy Market | 42.360208 | -71.054913 | 60 | `boston-name-above-the-door-walk_stop4.mp3` | `boston_the_name_above_the_door_multistop_04_quincy_market.txt` | reuses single 18 `quincy-market` exactly |
| W5-5 | Faneuil Hall | 42.360034 | -71.056234 | 50 | `boston-name-above-the-door-walk_stop5.mp3` | `boston_the_name_above_the_door_multistop_05_faneuil_hall.txt` | reuses single 04 `faneuil-hall` exactly |

## Flags for the owner and the author
- 🔴 **The "Charlestown Bridge" (W4-4) is now named the William Felton "Bill" Russell Bridge** in OpenStreetMap: it is the replacement North Washington Street bridge. The script calls it the Charlestown Bridge throughout, so the author should check the name before recording.
- The author notes **W4-02 runs 343 words** (three over the cap): trim at record time or accept.

## Owed before wire-in
- **29 MP3s.**
- **Images for the connectives:**
  - **W4-4 is DONE:** `boston-the-other-bank_stop4.webp`, plus 4 extras.
  - **Still owed: W2-5** Phillips Street, **W3-2** Haymarket, **W4-3** City Square, **W5-2** Joy Street and **W5-3** Government Center. The picker had verified photos for W3-2 and W5-3, but none was picked.
  - Every other segment reuses its single's hero. Intros carry no image, per the walk convention.

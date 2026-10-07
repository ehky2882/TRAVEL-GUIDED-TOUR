# Philadelphia batch 1: wire-in pick-map

**30 single-stop tours · Atlas Studio PHL (`e6977a1f-af18-5f64-923a-052c350ce76e`) · staged 2026-10-02 · scripts only, no audio yet**

The owner's drop (OneDrive folder `261002_PHILADELPHIA`) held the author's non-gated corpus: **30 singles (01–30) and 5 walks** (`drafts/philadelphia-walks/`). Each script comes as a clean + `_TTS` pair. The drop also held several copies of the author's master list and handoff. **A further 15 "T3" singles are GATED by the author** (master list §3) and were not written. Do not treat them as missing.

🔴 **The root folder's handoff is STALE (№8, written before the walks). The newest is №13, inside `PHILLY W5`.** It is kept here as `author/handoff-13.md`, beside its master list (`author/master-list-session9.md`). Both carry the pronunciation library, the pre-record flags and the judgment calls awaiting the owner.

Philadelphia is the **40th studio**. The city already has **12 creator link pins** but no Atlas tours.

## Owed before wire-in
1. 🔴 **The author's pronunciation pass, before recording.** The author calls it "the one hard blocker": a native pass on *Lenape*, *Lenapehoking*, *Schuylkill*, *Wissahickon* and *Deborah's*. Also apply "Reading" → "redding" in 08's TTS at record (handoff №13 §4).
2. **Audio: DONE (2026-10-06).** All 66 MP3s (30 singles + 36 walk segments) are on gh-pages as `audio/<slug>.mp3` and `audio/<walk-slug>_stop<N>.mp3`, hash-verified live. Each file was transcript-matched to its own script (faster-whisper on its first 30 s; the lowest score was 0.90, and none matched another script better). They are 128 kbps / 44.1 kHz **mono**, 40–194 s each, 8,327 s in total. Durations and hashes are in `audio-manifest.json`. ⚠️ The author's pronunciation pass (item 1) was owed before recording. Nothing here can confirm it happened, so listen for *Schuylkill*, *Lenape* and *Reading* on device.
3. **Images: 25 of 30 tours done (2026-10-03), 124 files on gh-pages, all hash-verified live.** The owner picked them in the [Philadelphia Image Picks](https://claude.ai/artifact/Ky2zRMHBARidzPDbgzsq5B) page. None needs a credit (`drafts/CREDITS.md`). The files are `images/<slug>_hero.webp`, then `_2`, `_3` and so on, in the owner's gallery order. The manifest is `image-manifest.json`. **05 Christ Church and 08 Reading Terminal Market: owner photos, 2026-10-07** (05 hero only; 08 hero + 2 gallery, the gallery two apparently AI-edited). **Still owed:** 15, 18, 19 (Congress Hall, Head House, Penn's Landing), plus the three walk connectives (W1-3, W2-5, W4-4). The owner left those rows unpicked. For 15 and 18 the picker's options were almost all CC BY-SA; 19 also had credit-free options. Ask before re-sourcing.

## The assembler must strip a metadata header
🔴 **Most clean scripts carry metadata above their first `---` line.** There is a title line, and from B3 onward also `Vantage:` and `Spines:` lines. The narration starts after the `---`. `transcriptText`, `caption` and `shortDescription` must be built from the text **after the first `---`** only, or the app will show "Spines: S4 · docket 8".

## Coordinates: derived 2026-10-02, audited
**The scripts carry no coordinates.** Each point is the subject's own OpenStreetMap object, found by name with Nominatim. Overpass is blocked from web sessions. The OSM object is named in every row.
- `check-coordinates.py` (`coordinate-audit.txt`): **GROSS none**, and **no directional bias** (13/27 north, median +0.0 m, p = 1). That result is expected, because the points came from the same geocoder, so they are not upstream pipeline coordinates. The independent check is that every row names an OSM object that carries the subject's own name.
- **A stop sits ON its subject** (owner, 2026-09-23). Where the script stands across a street, the trigger radius is sized to reach the listener (25–100 m). **Do not normalise the radii.**
- **Geofence overlaps on Independence Mall, deliberate:**
  - 01 Independence Hall ↔ 15 Congress Hall: 54 m apart, radii 40 + 25.
  - 02 Liberty Bell ↔ 03 President's House: 58 m apart, radii 30 + 25.

  Boston shipped tighter (Granary ↔ Park Street).
- **19 is pinned at the cruiser *Olympia*,** where the script stands. The script says the Great Plaza was demolished in 2024 and Penn's Landing is under construction.
- **21 Eastern State Penitentiary sits on exactly the same point as three existing creator pins.** That makes it a place candidate after launch; put it to the owner.
- **28 covers two sites.** It is pinned at the burial ground (5th & Arch), and the script then walks two blocks east to the Arch Street Meeting House (OSM way 298694561).
- **Slugs were checked against every file on gh-pages:** no clashes.

| # | Title | Slug | lat | lon | r (m) | category | script | point / note |
|---|---|---|---|---|---:|---|---|---|
| 01 | Independence Hall | `independence-hall` | 39.948887 | -75.150026 | 40 | history | `philadelphia_01_independence_hall.txt` | building (OSM way 25271595); script on the north side of Chestnut St between 5th and 6th, facing it |
| 02 | The Liberty Bell | `liberty-bell-center` | 39.949954 | -75.150205 | 30 | history | `philadelphia_02_liberty_bell.txt` | building (way 40086417); script on the Chestnut St sidewalk at its south end |
| 03 | The President's House | `presidents-house-site` | 39.950465 | -75.150089 | 25 | history | `philadelphia_03_presidents_house.txt` | open-air site (way 87325590) at 6th & Market, where the script stands |
| 04 | Elfreth's Alley | `elfreths-alley` | 39.952772 | -75.142381 | 40 | architecture | `philadelphia_04_elfreths_alley.txt` | the alley (way 12150950); script at its mouth on 2nd St looking east |
| 05 | Christ Church | `christ-church-philadelphia` | 39.950730 | -75.143880 | 40 | sacredSites | `philadelphia_05_christ_church.txt` | church (way 332757057); script on 2nd St beside it |
| 06 | City Hall and William Penn | `philadelphia-city-hall` | 39.952399 | -75.162989 | 70 | architecture | `philadelphia_06_city_hall_penn.txt` | building (relation 4720912); the courtyard is its centre, where the script stands |
| 07 | Philadelphia Museum of Art Steps and Eakins Oval | `philadelphia-museum-of-art-steps` | 39.964945 | -75.180080 | 70 | culturalHeritage | `philadelphia_07_art_museum_steps.txt` | the East Terrace steps (way 1387913459); script at Eakins Oval then the top of the steps |
| 08 | Reading Terminal Market | `reading-terminal-market` | 39.953144 | -75.159049 | 50 | foodAndDrink | `philadelphia_08_reading_terminal_market.txt` | market (way 42784822); script at 12th & Arch |
| 09 | Rittenhouse Square | `rittenhouse-square` | 39.949466 | -75.171890 | 70 | natureAndParks | `philadelphia_09_rittenhouse_square.txt` | park (way 32122312); script in the middle by the pool |
| 10 | Franklin Court | `franklin-court` | 39.949638 | -75.146596 | 40 | history | `philadelphia_10_franklin_court.txt` | courtyard (relation 9808332); script under the steel frame |
| 11 | Logan Square | `logan-square` | 39.957937 | -75.170592 | 60 | natureAndParks | `philadelphia_11_logan_square.txt` | Swann Memorial Fountain (node 1015369635), Logan Circle; script at the fountain's rim |
| 12 | Washington Square | `washington-square-philadelphia` | 39.947095 | -75.152708 | 50 | history | `philadelphia_12_washington_square.txt` | memorial (node 11084813612), west side of the square; script on its plaza |
| 13 | Carpenters' Hall | `carpenters-hall` | 39.948142 | -75.147215 | 35 | history | `philadelphia_13_carpenters_hall.txt` | building (way 261314259); script in its court off Chestnut St |
| 14 | Betsy Ross House | `betsy-ross-house` | 39.952285 | -75.144625 | 30 | history | `philadelphia_14_betsy_ross_house.txt` | building (way 353034105); script in front on Arch St |
| 15 | Congress Hall | `congress-hall` | 39.948981 | -75.150645 | 25 | history | `philadelphia_15_congress_hall.txt` | building (way 40083518); script at 6th & Chestnut |
| 16 | Second Bank of the United States | `second-bank-of-the-united-states` | 39.948572 | -75.148410 | 35 | architecture | `philadelphia_16_second_bank.txt` | building (way 261314260); script on the south side of Chestnut facing the portico |
| 17 | Mother Bethel AME Church | `mother-bethel-ame-church` | 39.943325 | -75.151761 | 40 | sacredSites | `philadelphia_17_mother_bethel.txt` | church (way 338920265), 6th & Lombard; script across the corner |
| 18 | Head House Square and the Shambles | `head-house-square` | 39.942647 | -75.145359 | 50 | history | `philadelphia_18_head_house_square.txt` | the Shambles (way 705214912); script at the Pine St end |
| 19 | Penn's Landing and the Delaware | `penns-landing` | 39.943521 | -75.140996 | 60 | history | `philadelphia_19_penns_landing.txt` | the cruiser Olympia (way 170349584) at the Seaport Museum basin, where the script stands |
| 20 | Race Street Pier and the Ben Franklin Bridge | `race-street-pier` | 39.953099 | -75.138665 | 60 | natureAndParks | `philadelphia_20_race_street_pier.txt` | pier (way 259095154); script at the pier tip |
| 21 | Eastern State Penitentiary | `eastern-state-penitentiary` | 39.968341 | -75.172663 | 80 | history | `philadelphia_21_eastern_state.txt` | prison (way 320052082); script on Fairmount Ave opposite the gatehouse. Same point as 3 existing creator pins |
| 22 | Fairmount Water Works | `fairmount-water-works` | 39.966189 | -75.183525 | 60 | history | `philadelphia_22_fairmount_water_works.txt` | Water Works (node 1847081969); script on the terrace above the dam |
| 23 | Boathouse Row | `boathouse-row` | 39.969414 | -75.187107 | 100 | architecture | `philadelphia_23_boathouse_row.txt` | the row (relation 15693769) along the east bank of the Schuylkill |
| 24 | Rodin Museum | `rodin-museum` | 39.961929 | -75.173951 | 50 | visualArt | `philadelphia_24_rodin_museum.txt` | museum (way 183625405); script at the Parkway gate |
| 25 | Masonic Temple and North Broad | `masonic-temple-philadelphia` | 39.953620 | -75.162657 | 35 | architecture | `philadelphia_25_masonic_temple.txt` | building (way 309294828), 1 N Broad St; script on the west sidewalk of Broad |
| 26 | Chinatown Friendship Gate | `chinatown-friendship-gate` | 39.953719 | -75.156265 | 30 | culturalHeritage | `philadelphia_26_chinatown_friendship_gate.txt` | the gate (way 486671294) over 10th St |
| 27 | Franklin Square | `franklin-square` | 39.955658 | -75.150435 | 70 | natureAndParks | `philadelphia_27_franklin_square.txt` | park (way 705322048); script at the central fountain |
| 28 | Christ Church Burial Ground and Arch Street Meeting House | `christ-church-burial-ground` | 39.951776 | -75.148134 | 40 | history | `philadelphia_28_burial_ground_arch_street_meeting.txt` | cemetery (way 49961134) at 5th & Arch; the script then walks to Arch Street Meeting House (way 298694561) |
| 29 | LOVE Park and Dilworth Park | `love-park` | 39.954149 | -75.165745 | 50 | natureAndParks | `philadelphia_29_love_park_dilworth_park.txt` | park (way 50171181); script beside the LOVE sculpture |
| 30 | One Liberty Place and the Skyline | `one-liberty-place` | 39.952579 | -75.168134 | 60 | architecture | `philadelphia_30_one_liberty_place.txt` | tower (way 42784982); script at 16th & Market |

**City:** `Philadelphia`, **country:** `United States` for all 30, matching the 12 existing pins.
**Ids at wire-in:** uuid5 `atlas-tour:phl:<slug>`, and `atlas-stop:phl:<slug>:1` at order 0 (the BOS/MIA scheme).

## How to launch (once every image is in)

🔴 **Owner, 2026-10-06: "dont launch the tours until i've backfilled everything".** The assembler enforces this: it exits `NOT READY` while any single or walk connective lacks an image.

1. Process the owner's backfill picks the same way as the first 124, and **add their rows to `image-manifest.json`**:
   - a single gets `num` set to `05` (etc.) and name `<slug>_hero.webp`, `_2`, …;
   - a connective gets `num` set to `W1-3` / `W2-5` / `W4-4` and name `<walk-slug>_stop<N>.webp`.

   Push the files to gh-pages in **one** batch and hash-verify them live.
2. Run `python3 drafts/philadelphia-batch1/tools/wire_philly.py --created <launch date>` from the repo root.
   - A `--dry-run <path>` run on 2026-10-06 (with stand-ins for the missing images) wrote 35 tours and passed `validate-tours-mirror.py` with **0 errors** and no Philadelphia warnings.
3. Then run the launch checklist in `archive/HANDOFF-261002-next-city.md` §4:
   - `validate-tours-mirror`;
   - `check-image-duplicates --maker PHL`;
   - `spine-lookup.py`;
   - `check-place-candidates` (expect **Eastern State Penitentiary**: the tour sits on the same point as 3 creator pins);
   - `join-places --max-move 100`.

   Update CLAUDE.md Key facts (re-derived; this is the 40th studio) and the tracker, and confirm Supabase with a count query after the merge.
4. Walks:
   - **W1** *The Fifth Square*: 6 stops, ~1.7 km, 522 s
   - **W2** *Broad and Market*: 9 stops, ~2.7 km, 755 s
   - **W3** *The Boulevard*: 6 stops, ~2.4 km, 786 s
   - **W4** *Brick*: 8 stops, ~2.3 km, 994 s
   - **W5** *The House That Isn't There*: 7 stops, ~0.6 km, 942 s

   Walking distances are computed (stop-to-stop × 1.25).
5. After launch, offer **architect tags** (atlas-upload Job 5). Candidates named in the scripts or well documented include William Strickland, Andrew Hamilton, John McArthur Jr., Paul Cret & Jacques Gréber, Helmut Jahn, Frederick Graff, Robert Smith and Venturi, Rauch & Scott Brown. Check each against its script before tagging.

# HANDOFF 2026-10-07: Auckland launches (Atlas Studio AKL, 20 singles)

**What shipped:** a new studio, **Atlas Studio AKL** 🇳🇿, the 40th. It has 20 single-stop audio tours of Auckland and no walks.
- **Maker:** platform `dozent`, handle `atlas.akl`. The id is uuid5 `atlas-maker:akl` = `774d495c-bf3f-5c9f-bb80-31787caaab7b`.
- **Ids:** tours use `atlas-tour:akl:<slug>`, and stops use `atlas-stop:akl:<slug>:1`.
- ⚠️ **Philadelphia's owner item still calls PHL "the 40th studio".** PHL is now the 41st.
- **Catalogue:** tours went 1824 → 1844 and makers 633 → 634. Cities and countries did not change, because creator pins already covered Auckland, New Zealand.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner) in the SovMod format. It has one folder per site, named `output <Name> <lat>, <lon>`. Each folder holds an MP3, `_clean.txt`, `_tts-safe.txt` and 1–6 webp photos at 1200×900.
- **Numbering:** the folders run 01–21, and **08 is missing**. The contributor was asked but did not answer.
- **Stray copy:** a duplicate Metita folder sits inside Mr Morris. It is byte-identical and was ignored.
- **Photos:** 83 in all. The contributor says they are royalty-free.
- **Audio:** 128k MP3s, 105–121 s each. Every file was transcript-matched to its own script with faster-whisper tiny.en, and all scored 0.86–0.92. Two pairs have identical file sizes but different hashes.
  - ⚠️ faster-whisper 1.2.1 cannot open files with av 19 (`metadata_errors`). Decode with ffmpeg to a numpy array and pass the array instead.
- **Staging:** scripts, `coordinates.tsv` and the assembler are in `drafts/auckland-batch1/`. Rules follow SovMod and Boston:
  - **Caption:** the first sentence of paragraph 2.
  - **Descriptions:** `longDescription` is the hook plus paragraph 3. `shortDescription` is cut at 145 characters.
  - **Geofence:** 40 m for venues and 60 m for Piha and Takutai Square.

**Coordinates.** `check-coordinates.py --drop` flagged 3 GROSS and 4 UNVERIFIABLE. Each was checked by hand with Nominatim reverse geocoding and searches.
- **Goblin and The Frog:** false positives. The geocoder matched other businesses, "Dice Goblin" in Royal Oak and "The Blue Frog" in Wynyard Quarter. Goblin is 33 m from 134 Ponsonby Rd, the old Golden Dawn address.
- **The Frog's street number is unverified.** It opened in November 2025, and OSM has no node for it. The point sits next to Daily Daily at 452 K Rd, which matches the script ("western end of K Road").
- **Piha was moved, with the contributor's OK.** The supplied point was 294 m south of Lion Rock, on Marine Parade South behind the surf club. It now sits on OSM's Lion Rock (-36.953931, 174.467021).
- **Five Britomart venues sit within 12 m of each other:** Cafe Hanoi, Ghost Street (in its basement, 2.7 m away), kingi, The Hotel Britomart and Mr Morris.
  - The contributor ruled them separate tours, and they are different businesses. Co-location is not identity, so there is no place question.
  - Their 40 m geofences overlap.
  - kingi's point is 41 m from OSM's kingi node on Tuawhiti Lane and was **kept as supplied**.
- **The bias line** read 8/12 north, median +11.1 m, p = 0.39. The sample is too small to call.
- **City outliers:** Piha is 28.5 km from Auckland's other entries. This is expected; Cape Point under Cape Town is the precedent.

**Architect tags (Job 5):**
- **Cheshire Architects:** The Hotel Britomart, Cafe Hanoi's new home and Mr Morris ("Nat Cheshire's redesign").
- **Stevens Lawson Architects:** HomeGround.
- **Not tagged:** the interior designers named in the scripts (Hannah Maurice at Bar Martin, Sam Boanas at Blue, CTRL Space at Metita), and the glass artist Luke Jacomb.

**gh-pages:** one commit, `0a88e73`, with 103 added files (20 audio, 83 images) and nothing modified or removed.
- It was built in a **blobless shallow clone** (`git fetch --depth=1 --filter=blob:none`), using `write-tree --missing-ok` and `GIT_NO_LAZY_FETCH=1`. This took seconds; a full fetch of gh-pages was still at 1.5 GB after 17 minutes.

**Checks:**
- `validate-tours-mirror` reported 0 errors.
- `check-place-candidates` found only the Britomart TIGHT pairs above.
- `join-places` found no Auckland joins.
- `spine-lookup` answered all 20.

# HANDOFF 2026-10-01: the five Miami walks are wired

Follows `HANDOFF-260930-miami-walks.md` (staging) and `HANDOFF-260929-miami-launch.md` (the 30 singles).

## What shipped
**5 `multiStop` tours, 32 stops, under Atlas Studio MIA.** Tours 1713 → 1718; multi-stop 74 → 79; tour stops 2090 → 2122.

| Walk | Title | City | Stops | Audio | Distance |
|---|---|---|---:|---:|---:|
| W1 | The Pitch — Downtown, River to Bay | Miami | 9 | 839 s | 3000 m |
| W2 | Ocean Drive — South Pointe to Lincoln Road | Miami Beach | 7 | 629 s | 3200 m |
| W3 | Calle Ocho — The Seam | Miami | 6 | 532 s | 3400 m |
| W4 | The Grove — Charles Avenue to Vizcaya | Miami | 5 | 446 s | 5600 m |
| W5 | The Water Line — Lincoln Road to Sunset Harbour | Miami Beach | 5 | 440 s | 1600 m |

- **Ids** follow the existing walk scheme: uuid5 `atlas-tour:mia:<tour slug>`, e.g. `atlas-tour:mia:miami-pitch-walk` (verified against Chicago's `atlas-tour:ord:chicago-riverwalk-walk`). Stop ids are `atlas-stop:mia:<tour slug>:<order>`.
- **Stops** come from `drafts/miami-walks/README.md`. Every stop that revisits a live single sits exactly on that single's coordinate (checked: none differed).
  - Intros are order 0 with no image; the radius is 40 m.
  - `caption` is the script's first sentence; `transcriptText` is the clean script without its header or `*[beat]*` lines.
- **Distances** are the author's route figures. W3 is measured, because its last leg runs straight down Eighth Street to Woodlawn.
- **Titles and descriptions were written this session from the intro scripts.** The owner may want to rename them.
- `relatedTourIds` is left empty; the `rebuild-related` job fills it on merge.

## Traps hit
- 🔴 **The pick-map named three single heroes that had since been replaced.** It said `dupont-building_hero`, `gesu-church_hero` and `tower-theater_hero`; the live singles now use `_hero-2`. The duPont `_hero` file is a **404**, and the other two are byte-identical to their single's `_3` gallery image. `check-image-duplicates.py --maker MIA` caught both. The fix was to point each reused stop at the single's CURRENT hero. **A staged pick-map ages: re-read image names from `Tours.json` at wire-in.**
- **Spine audit:** two walk titles name a street, so the gazetteer matched the street ("Ocean Drive") and an event ("Calle Ocho Festival") against each walk's intro point. These are recorded as `editorial-title` in `checks/spine-verdicts.json`, so the owner list is back to the 3 already on `main`.
- **The Grove intro** came as a re-exported WAV (48 kHz mono). It was encoded to 128 kbps / 44.1 kHz stereo MP3 with `lameenc` + `scipy` (no ffmpeg in the container). The transcript was checked against the script.

## Still open (not blocking)
- `audio/miami-water-line-walk_stop4.mp3` (Purdy, dropped) is orphaned on gh-pages.
- The non-blocking Miami items in `HANDOFF-260930-miami-walks.md` still apply: Commons licences, Overtown/Senator provenance, architect tags, the author's pre-record flags.
- After the publish job, confirm Supabase: the MIA `maker_id` row count should be **35**.

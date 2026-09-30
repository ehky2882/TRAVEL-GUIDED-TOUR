# Handoff 2026-09-30: Miami walks, staged and nearly ready (continue here)

**Read first:** `drafts/miami-walks/README.md` (the pick-map: all 33 stops with coordinates, audio names, images, owed items) and `archive/HANDOFF-260929-miami-launch.md` (the singles launch).

## State right now
- **Miami singles: LIVE in the app** (#1103). 30 tours under Atlas Studio MIA (`aed488af-23d3-514f-90f1-035ca2285d0d`). Verified in Supabase on 2026-09-29: `maker_id` count = 30.
- **Miami walks: staged, not wired.** Five walks, 33 stops:
  - W1 *The Pitch* (9)
  - W2 *Ocean Drive* (7)
  - W3 *Calle Ocho* (6)
  - W4 *The Grove* (5)
  - W5 *The Water Line* (6)
- **Scripts:** all 33 clean + `_TTS` in `drafts/miami-walks/scripts/` (#1105). Each clean script was matched against a transcript of its recording.
- **Audio:** 32 of 33 on gh-pages as `audio/<walk-slug>-walk_stopN.mp3` (`579feac8`). Walk slugs: `miami-pitch`, `miami-ocean-drive`, `miami-calle-ocho`, `miami-grove`, `miami-water-line`.
  - **MISSING: `miami-grove-walk_stop0.mp3`.** The drop's `miami_w4_00_intro.mp3` is byte-identical to `miami_w3_c_woodlawn.mp3`. The owner must re-export it from `miami_w4_00_intro_TTS.txt` ("This street exists because the town said no…").
- **Coordinates:** all 33 in `drafts/miami-walks/coordinates.tsv` (27 high, 6 medium). Stops that revisit a live single reuse its EXACT point, since several are places now.
- **Stop images:**
  - Reused stops take the live single's `heroImageURL`. **Read it from Tours.json**; the README's `<slug>_hero` column is stale for duPont, Gesu, Tower, Lyric and Little Haiti.
  - 7 new photos on gh-pages (`8b92d5a0`), credited in `drafts/CREDITS.md`: `miami-pitch_stop5`, `miami-calle-ocho_stop2`, `miami-calle-ocho_stop5`, `miami-grove_stop1`, `miami-grove_stop2`, `miami-grove_stop4`, `miami-water-line_stop2`.
  - **STILL OWED (2 photos):** W5-4 Purdy Avenue, W5-5 Sunset Harbour. Openverse had nothing usable, so these need owner photos. Intro stops (order 0) carry no image, per the Chicago walk convention.
- **Owner board:** `status/owner/miami-walks-owed.md` lists exactly these two items.

## To wire the walks (when the intro + 4 photos arrive)
1. Upload `miami-grove-walk_stop0.mp3`, then new photos as `<walk>_stopN.webp` (1200×900). Hash-verify live.
2. Build 5 `kind: "multiStop"` tours in `Tours.json`, modelled on an existing walk (e.g. Chicago *The Riverwalk*):
   - intro is stop order 0 at the start point;
   - `triggerRadiusMeters` 40 (the walks' convention);
   - `walkingDistanceMeters` from the route;
   - `totalDurationSeconds` = sum of the stops;
   - `centroidLatitude`/`centroidLongitude` = the mean of the stops;
   - `city` Miami (W1, W3, W4) or Miami Beach (W2, W5); `country` United States; `makerId` MIA.
   - **Ids:** check an existing multi-stop id scheme first. Singles use uuid5 `atlas-tour:mia:<slug>` / `atlas-stop:mia:<slug>:<n>`.
3. **Stop fields from the clean scripts:**
   - `transcriptText` = the body with the header and `*[beat]*` lines removed;
   - `caption` = the first sentence (they open on orientation by design).
   - Tour `longDescription`: write it from the intro script; the title is the walk name.
4. Run `validate-tours-mirror.py`, `check-image-duplicates.py --maker MIA`, `spine-lookup.py` and `spine-match.py` (read every DISAGREES line), `check-place-candidates.py`, `join-places.py --max-move 100`.
5. PR → CI green → squash-merge (content, auto-merge rule 4). Update the CLAUDE.md Key facts counts (multi-stop 74 → 79, stops) and the AUDIO-PENDING-SURVEY tracker row.
6. Afterwards, confirm Supabase: the MIA `maker_id` count should be 35.

## Other open Miami items (not blocking)
- **10 Commons photo licences unverified.** Commons returned 429 to this container for two days; see `drafts/CREDITS.md` § Miami.
- **Overtown aerial** (`overtown-interchange_hero.webp`): source unknown; reverse-image search it.
- **Architect tags** (Job 5 PR): Lapidus, Treister, Hohauser, Enrique Gutiérrez, Schultze & Weaver.
- **The author's pre-record flags 25–66** (in `miami_session_handoff.md` in the owner's drop): facts to verify or soften.

## Lessons from this session (also in docs/lessons.md)
- A Commons category listing has **no licence filter**. The Miami picks were reported as PD but 60 were CC BY/BY-SA. Record the licence per candidate.
- **A street geocodes to one segment, maybe the wrong one.** Española Way was 457 m off, and only the Spine audit caught it.
- **A pasted image may never become a file**, but it is in the session transcript (`~/.claude/projects/<proj>/<session>.jsonl`) as base64. Uploaded files land in `~/.claude/uploads/<session>/`.
- **Check audio for byte-duplicates**, and use speech-to-text (`faster-whisper tiny.en` via pip works here) to confirm each file is in the right slot.

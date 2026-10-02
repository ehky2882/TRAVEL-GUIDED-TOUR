# HANDOFF 2026-10-02: Boston staged (30 singles + 5 walks, scripts only)

## What arrived
- **Source:** the owner's OneDrive folder `260928_BOSTON`, shared "anyone with the link".
  - The first link the owner sent was organisation-only and returned 403. The re-shared link works.
  - Downloaded through SharePoint's REST API with the guest cookie: `/_api/web/GetFolderByServerRelativePath(decodedurl=…)?$expand=Folders,Files`, then `GetFileByServerRelativePath(…)/$value`. **Use curl, not urllib**: urllib was refused 403 on the same cookie. Retry on proxy drops. All 131 files were size-verified.
- **Contents:**
  - 30 singles (clean + `_TTS`).
  - 5 walk folders with 29 segments, each folder carrying its own copy of the author's master list and handoff.
  - 🔴 **The root folder's handoff is STALE (№10, pre-walks). The newest is in `boston w5` (№15).** Compare the headers; never read the root copy as current.
- **No audio.** The author's 15 T3 singles are GATED and were not written.

## What was staged (on `main`, like the Miami walks: this session can only push its own branch)
- `drafts/boston-batch1/` holds 60 scripts, `coordinates.tsv`, `coordinate-audit.txt` and `README.md` (the pick-map).
- `drafts/boston-walks/` holds 58 scripts in `scripts/`, `coordinates.tsv` and `README.md`.
- **Tracker:** Boston rows were added to `drafts/AUDIO-PENDING-SURVEY.md` (TOTAL PENDING 35), and the stale Miami-walks row was removed (Miami is live).
- **Owner item:** `status/owner/boston-audio-images.md`.
- **Maker id:** Atlas Studio BOS = uuid5 `atlas-maker:bos` = `cebccd48-7b4b-5719-bb5b-194734d5db8e`. The scheme was re-verified against MIA.

## Coordinates
- **Audit result:** GROSS none and no bias. Six points were UNVERIFIABLE, and each was read by hand.
- **Large distances explained** (all detail is in the batch README):
  - The checker matched a USS Constitution *information board* 467 m from the ship.
  - North End Parks is a node inside the Greenway polygon.
- **Overpass is blocked.** Intersections and polygon edges come from Nominatim `lookup … polygon_geojson=1` and the nearest vertex pair. Mount Vernon St is split into several OSM ways, and the first pick was 327 m off; search a tight viewbox to get the right segment.
- **Every walk intro is spoken from its stop 1**, so each intro shares stop 1's point. Existing walks do the same.

## For the owner and the author
- **W4-4:** the "Charlestown Bridge" is now the William Felton "Bill" Russell Bridge.
- **The author's pronunciation pass and flag 115** (Faneuil Hall renaming status) must be done before recording.
- **Place question after launch:** City Hall Plaza (17) vs the existing "Boston City Hall" pin, 92 m apart.

## Next
1. Images. The pipeline needs the Gemini key (owner-pasted) for its two gates, or the owner supplies photos.
2. Audio (59 MP3s).
3. Wire per the two READMEs.

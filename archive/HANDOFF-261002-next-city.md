# HANDOFF 2026-10-02: the next city. Playbook from Boston, for a fresh chat

The owner is starting a **fresh chat to stage the next city**. Boston finished in this one.
This file is the recipe that worked end to end for Boston and Miami, plus everything the
new session needs and cannot re-derive.

## 0. Before anything
- Run `bash scripts/session-start.sh`. Read `docs/lessons.md` and the two Boston handoffs:
  - `HANDOFF-261002-boston-staging.md` covers the download, staging and coordinates.
  - `HANDOFF-261002-boston-live.md` covers images, audio, launch and the owner's follow-up decisions.
- **Check that PR #1119 has merged.** It carries Boston's architect tags, the City Hall Plaza place, the
  Bill Russell Bridge rename and the image-picker tool. If it is still open, it was waiting on CI only:
  merge it once green (content, docs and Job-5 architect tags, so it auto-merges).
- The queue is empty: `drafts/AUDIO-PENDING-SURVEY.md` on `main` reads "Boston is live, the queue is
  EMPTY". The next city starts from zero.

## 1. Download the drop
- **OneDrive / SharePoint.** The link must be "anyone with the link"; an organisation-only link
  returns 403, so ask the owner to re-share. Fetch with **curl, not urllib** (urllib was refused on the
  same cookie). Get a guest cookie from the share link, then use the REST API:
  `/_api/web/GetFolderByServerRelativePath(decodedurl=…)?$expand=Folders,Files` and
  `GetFileByServerRelativePath(…)/$value`. Retry when the proxy drops.
- **Dropbox `/scl/fo/`.** Change `dl=0` to `dl=1` to get a zip. **Never commit a share link.**
- 🔴 **The author's folders carry several copies of their own handoff/master list, and the ROOT copy can
  be stale** (Boston: the root was №10, the newest was №15 inside `boston w5`). Compare the headers.

## 2. Stage (scripts arrive first; audio usually later)
- Make `drafts/<city>-batch1/`: scripts (clean + `_TTS`), `coordinates.tsv`
  (num, slug, lat, lon, radius, category, note) and `README.md` (the pick-map).
- Make `drafts/<city>-walks/` for walks: `scripts/`, `coordinates.tsv` and `README.md`. Stop ids are
  `W<n>-<order>`; mark reused stops "reuses single NN".
- **Coordinates:** Automation rule 8b, `check-coordinates.py --drop … --city …`. Fix every GROSS, read
  every UNVERIFIABLE by hand, check the BIAS line. Overpass is blocked; use Nominatim `lookup` with
  `polygon_geojson=1`, and **never put the owner's email in a User-Agent** (use the repo URL).
- Maker id `uuid5(NAMESPACE_URL, "atlas-maker:<code>")`. Tours `atlas-tour:<code>:<slug>`, single
  stops `atlas-stop:<code>:<slug>:1` with order 0, walk stops `atlas-stop:<code>:<walk-slug>:<order>`.
  Check the scheme against an existing studio (BOS = `cebccd48-…`).
- Land a tracker row in `drafts/AUDIO-PENDING-SURVEY.md` on `main` as soon as the batch is staged,
  plus a `status/owner/` item for the audio and images it is waiting on.

## 3. Images: the IMAGE PICKER (the owner's preferred way, confirmed 2026-10-02)
- **Keys:** the owner pastes Gemini, Unsplash and Pexels keys **fresh each session**. Keep them in the
  scratchpad only and never commit them. Ask for them when you reach this step.
- **Sources:** Unsplash, Pexels, then public-domain Commons. Thumbnails from Commons/Openverse 429 or 424
  under load; fetch through `https://i0.wp.com/upload.wikimedia.org/…?w=1000`.
- **Two separate Gemini gates** (CLAUDE.md § Image Pipeline step 2), then **look at contact sheets
  yourself**: Boston's manual pass still removed 54 of 258. Let Gate B accept interiors for churches.
- **Build the picker:** write ~1000–1600 px JPEGs plus `data.json`, then
  `python3 scripts/make-image-picker.py <dir> --city <City> --subtitle "…"` and publish the page with
  the Artifact tool, passing `files.json` as `files`. The owner taps hero + gallery and pastes
  back lines like `01 slug: 01-4 hero, 01-1, 01-7`.
- Walk stops that revisit a single reuse **the single's CURRENT hero**, never a stale pick-map name
  (Miami lesson).
- Owner photos arrive as chat attachments with captions ("paul revere house hero"). Hash the written
  file against the decode before committing.
- Upload to gh-pages (`/tmp/ghpages`). 🔴 **Batch the pushes:** pushes a few minutes apart cancel
  each other's Pages deploy, and in Boston no image was live for an hour. After the deploy, hash-check
  every live URL.

## 4. Audio, then wiring and launch
- The MP3s usually arrive later as a Dropbox link. Rename each to `audio/<slug>.mp3` (walks:
  `<walk-slug>_stop<N>.mp3`), push to gh-pages in **one** batch and hash-verify live.
- **The assembler:** `drafts/boston-batch1/tools/wire_city.py` is Boston's, kept as a reference. Adapt
  the code, the TITLE/TAGS maps and the paths. It sets:
  - `transcriptText`: the clean script minus the header and `*[beat]*`.
  - `shortDescription`: cut at 145 characters.
  - `caption`: the "You should be / You're / You are" standpoint sentence.
  - durations: read with mutagen.

  `tools/wire_walks_miami.py` is the walk assembler it grew from.
- **Checks before the PR:**
  - `validate-tours-mirror.py`: 0 errors.
  - `check-image-duplicates.py --maker <CODE>`.
  - `spine-lookup.py`.
  - `check-place-candidates.py`; put real groups to the owner. A walk sharing its stop-1 point with a
    single is by design.
  - `join-places.py --max-move 100`.
- **Merge conflicts on the launch PR** come from parallel sessions editing the CLAUDE.md Key-facts line
  and `spine/lookups.json.gz`. Take main's copy, re-run `scripts/spine-lookup.py`, and put the count
  update in its **own small PR** afterwards.
- After the merge, confirm Supabase with a count query: `/rest/v1/tours?select=id&maker_id=eq.<id>` with
  `Range: 0-0` and `Prefer: count=exact`. "Live on device?" means Supabase is serving it.

## 5. After launch, which the owner usually asks for
- **Architect tags** (atlas-upload skill Job 5): grep the scripts for named architects, add one line to
  each of the two Swift lists, tag the tours, and add *Designed by a Master*. Leave sculptors out.
- **Place pages:** offer them, but follow the owner's call per site. Boston rulings, which are durable:
  City Hall Plaza = the single + the walk, **without** the @ninosbuildings pin; Trinity Church and
  Copley Square **stay separate**.

## Context-length habit
The owner tracks context with a status bar (white below 75%, red above). A full city (stage, pick
images, wire audio, launch) filled one chat in Boston. When it nears the limit, write a handoff like
this one before compacting.

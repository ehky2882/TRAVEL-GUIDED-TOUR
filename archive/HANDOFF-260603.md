# Atlas — Handoff Notes (2026-06-03, session 18)

Web/PM session — content-batch consolidation followed by a
build-bump-and-archive. Eighteen new NYC tours had been landing
direct-to-main since session 17's TestFlight 1.0 (25) cut; this
session bundles them into TestFlight 1.0 (26).

**TestFlight 1.0 (26) build uploaded by owner via Organizer.**

---

## What happened this session

### 1. 18 new NYC tours — landed direct-to-main between sessions

All single-stop except tour 121, all under Atlas Studio NYC, all
geofenced. Catalog grew **113 → 131**, multi-stop count **1 → 2**.

Commits (oldest → newest):

- `7e3e9a9` — **5 NYC tours (114–118):** Four Freedoms Park,
  Green-Wood Cemetery, African Burial Ground National Monument,
  Cooper Union Foundation Building, Tompkins Square Park.
- `9df3983` — **2 NYC tours (119–120):** Museum of Modern Art
  (MoMA), Bryant Park.
- `88bf893` — **Fifth Avenue Walk (121)** — **second multi-stop
  tour ever** in the catalog (joining the AMNH Four Facades walk
  added 2026-05-26). Owner-asked for the catalog's next multi-stop
  experience after AMNH.
- `8261107` — **2 NYC tours (122–123):** Federal Hall, Columbus
  Park (Chinatown).
- `64a04e3` — **2 NYC tours (124–125):** Schomburg Center for
  Research in Black Culture, Coney Island.
- `79f6b49` — **2 NYC tours (126–127):** Eldridge Street Synagogue,
  Grand Army Plaza (Brooklyn).
- `fab0e53` — **2 NYC tours (128–129):** Grand Concourse,
  Strivers' Row.
- `ab7c1f8` — **2 NYC tours (130–131):** IAC Building (Frank Gehry,
  2007), The Strand Bookstore.

Two validator-caught typo fixes followed:

- `3235d33` — `triggerMode geofence → geofenced` across tours
  114–131 (the canonical enum case).
- `7c11003` — `TourKind multi → multiStop` on Fifth Avenue Walk
  (only `singleStop` / `multiStop` are valid).

Validator ran clean after each fix. No Swift / asset / project
changes in the run-up to this session.

### 2. PR-less build bump 25 → 26

Direct-to-main per the established build-bump pattern (precedent:
`aba765f` for 25, `401358f` for 24).

- **Commit `17dba88`** — single-line `CURRENT_PROJECT_VERSION`
  25 → 26 in `TRAVEL GUIDED TOUR.xcodeproj/project.pbxproj` for
  the two app-target build configs. Test-target lines stay at 1.
- **Archive** — `xcodebuild archive` clean at
  `/tmp/Atlas-20260603-1840.xcarchive` (~3 min wall clock).
  Followed `docs/testflight.md` § "Archive command":
  `-project … -scheme "TRAVEL GUIDED TOUR" -configuration Release
   -destination "generic/platform=iOS" -allowProvisioningUpdates`.
- **Owner uploaded via Organizer.** TestFlight 1.0 (26) live.

---

## State at session end

- **Catalog:** 131 tours, 3 makers (113 → 131 this session).
  Atlas Studio NYC at **91 NYC-area tours** (73 → 91).
- **Multi-stop tours:** 2 (AMNH Four Facades; Fifth Avenue Walk).
- **Build:** TestFlight 1.0 (26), uploaded 2026-06-03 evening.
- No code, asset, or project structure changes this session beyond
  the pbxproj bump.

---

## Parked / known follow-ups

- **PR #93 part 2** — stop-row timeline + thumbnails + animated
  `waveform` now-playing indicator + non-modal playback start.
- **9 more NYC tours** to reach the 100 NYC milestone (currently
  91 in the catalog).
- **More multi-stop walking experiences** — Fifth Avenue Walk is
  the proof-of-concept that the second-ever multi-stop tour works
  in production. Worth canvassing the catalog for natural walking
  routes between adjacent stops.
- **Porto / Lisbon / Cascais / Algarve / Alentejo / Azores hero
  polish** as time permits.
- **M-qa items 6+7** — AMNH Four Facades geofence walk on device.
- **Dynamic Type tradeoff on the `body` token** — `Font.system(size: 15)`
  is fixed-size; future pass should switch to
  `Font.system(size: 15, relativeTo: .body)`.

---

## How to resume

1. `git fetch && git status && git log origin/main..HEAD` — tree
   should be clean on `main`.
2. Read `CLAUDE.md` (Current State for build 26) and this handoff.
3. If the next session is more content, the natural pattern is:
   draft entries in `Resources/Tours.json`, run
   `swift scripts/validate-tours.swift`, upload audio + heroes to
   `gh-pages`, push direct to main (content-only auto-merge rule).
4. If cutting another TestFlight build: bump
   `CURRENT_PROJECT_VERSION` 26 → 27 in `project.pbxproj`,
   archive per `docs/testflight.md`, upload via Organizer.

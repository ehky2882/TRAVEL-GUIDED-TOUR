# Atlas — Handoff Notes (2026-05-22, local Mac session)

Local Mac session, 2026-05-21 evening → 2026-05-22. Picked up a
remote session's in-flight PR #54, got it merged, ran an extended
simulator review, added 9 tours, and shipped **TestFlight build
1.0 (5)**. Read this first at the start of the next session.

---

## What shipped this session

Everything below landed via **PR #54** (squash-merged to `main`
2026-05-22, commit `c008973`), then **build 1.0 (5)** was uploaded.

### 1. PR #54 CI fix — the real blocker

PR #54 arrived from a 2026-05-21 remote session with **failing CI**.
Earlier sessions chased a bogus `MapContentBuilder` error in the
image-carousel code. **Real cause:** CI built on `macos-latest`,
whose Xcode (16.x, iOS 18 SDK) miscompiles SwiftUI that is valid
under the iOS 26 SDK the project targets. Fix: `.github/workflows/ci.yml`
now runs build + test on the **`macos-26`** runner and selects the
newest Xcode. (An earlier attempt — overriding
`IPHONEOS_DEPLOYMENT_TARGET=18.0` — did not work; the runner Xcode
itself was the problem.)

### 2. Simulator-review UX polish batch

A long back-and-forth reviewing PR #54 in the simulator produced:
- **Mini-player is now always present** (not just when audio is
  loaded) — shows the active tour or a muted "Nothing playing" idle
  state. Restyled: smaller matched type, circular maker avatar,
  square-cornered rectangle.
- **Bottom island reshape** — tab bar top corners squared off; the
  mini-player rectangle stacks flush on top. Drawer top radius 36→30.
- **Tour-detail action bar** — aligned three controls to one size,
  top edge level with the home drawer's peek detent, island-colored
  background, "Start Tour" label.
- **Drawer cards** carousel multi-image tours; **hero images on the
  preview screen are pinch-to-zoom**.
- Library + Settings backgrounds matched to the island color.
- Home drawer detent **persists across tab switches** (state lifted
  to `ContentView`).
- Recenter animation slowed; location button color fixed.

### 3. Nine new tours — catalog now 20

Added (audio committed to `gh-pages` under `audio/`, entries in
`Resources/Tours.json`, each validated with
`swift scripts/validate-tours.swift`):
Casa da Música (Porto — first non-NYC tour), Whitney Museum,
American Museum of Natural History, Brooklyn Bridge Park, Chrysler
Building, Flatiron Building, Governors Island, Guggenheim Museum,
Intrepid Sea/Air/Space Museum. **All 20 tours are single-stop.**

### 4. TestFlight build 1.0 (5)

Build number bumped 4→5 (`6e12328`); owner archived + uploaded via
Xcode. Build 1.0 (5) carries everything above and is the current
TestFlight build.

---

## Start here next session

1. **M-qa on device against build 1.0 (5).** Owner installs via the
   TestFlight app and walks the M-qa checklist (`ROADMAP.md` § M-qa).
   New since the last on-device pass: the always-present mini-player,
   the reshaped island, the tour-detail action bar, pinch-zoom (only
   testable on device — the simulator can't pinch well), and the
   compass heading wedge on the user-location dot.
2. **Bug fixes from M-qa** — Claude can write fixes in any session,
   but they reach the device only on **build 6**, which needs a Mac
   session to archive + upload.
3. **A multi-stop tour is still missing.** All 20 tours are
   single-stop, so M-qa's multi-stop checks (geofenced stop
   advancement, next/prev, walking distance) can't run. Authoring one
   multi-stop walking tour would close that gap.
4. **More tours (optional).** `~/Desktop/ATLAS ASSETS/` has many more
   queued folders (Cooper Hewitt, Frick, Little Island, Morgan
   Library, New Museum, NYPL, Oculus, St Patrick's, Vessel, Washington
   Square Park, and more). Same workflow as this session.

---

## Tribal knowledge

- **CI must use Xcode 26.** The project targets iOS 26.2; older Xcode
  on `macos-latest` miscompiles it. `ci.yml` pins `macos-26`. If CI
  build fails with weird `MapContentBuilder` / availability errors,
  check the runner's Xcode version first — that's the tell.
- **Tour-authoring workflow.** Owner pastes audio + transcript +
  audio length; Claude prompts only for coordinates and category,
  then authors the full `Tours.json` entry, uploads the audio to
  `gh-pages`, validates, and commits one tour per commit. Defaults:
  `manual` trigger, 30m radius, placeholder hero image, Atlas Studio
  maker. See `docs/authoring-tours.md` — its "Authoring with Claude"
  section had stale category/trigger values (`onArrival`,
  `artAndMuseums`, etc.); **fixed this session**. The valid values:
  trigger `geofenced`/`manual`; the 10 `TourCategory` cases.
- **Asset folders.** In `~/Desktop/ATLAS ASSETS/`, tour folders move
  into `000-UPLOADED/` once handed to Claude; `000-NO AUDIO/` holds
  tours without audio yet. If a path the owner gives doesn't resolve,
  check `000-UPLOADED/`.
- **gh-pages uploads** (from a Mac): `git checkout gh-pages` → `cp`
  the mp3 into `audio/` → commit → push → `git checkout main`. Do it
  with a clean working tree (commit pending Tours.json edits first,
  or the branch switch aborts).
- `MapUserLocationButton` does not render reliably as a free-floating
  view — the home screen uses a custom location button.

---

## Repo state at session end

- `main` at `6e12328` (build-number bump) — or later if this handoff
  commit lands after. PR #54 fully merged.
- Branches: `gh-pages` (audio CDN, active) is the only non-main
  branch. The stale `fix/pr54-build` was deleted at session end —
  `origin` now carries just `main` + `gh-pages`.
- `Tours.json`: 20 tours, all single-stop, validator-clean.
- TestFlight: build 1.0 (5) uploaded 2026-05-22.

## How to resume

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"   # or the session's project path
git fetch
git checkout main
git pull --ff-only
git log --oneline -5
```

Read: `CLAUDE.md` § Current State → `ROADMAP.md` § "Where we are
right now" + § M-qa → this file. `docs/testflight.md` if uploading
another build; `docs/authoring-tours.md` if authoring tours.

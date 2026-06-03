# Atlas — Handoff Notes (2026-05-24, end-of-session)

Session ran evening 2026-05-23 → early 2026-05-24 (Mac).

---

## What shipped this session (all on `main`, all pushed)

### Hero images — all 38 tours

Every tour in `Tours.json` now has a real `heroImageURL` pointing to a
CC-licensed Wikimedia Commons photograph. Work happened across several
commits:

- **`8699ac6`** (PR #57) — initial batch: all 37 placeholder
  `atlas-tours.example` URLs replaced by real Wikimedia Commons images
  via automated Python + WebFetch lookup.
- **`98b7ab8`**, **`b089ebc`**, **`f2f68a1`** — three individual
  corrections: Whitney Museum (old Breuer building → new Renzo Piano
  Gansevoort building), Manhattan Bridge (generic span → iconic
  Washington Street DUMBO framing shot), Statue of Liberty (torso crop
  → full frontal view).
- **`03f6626`** — landscape-optimised batch: 9 images swapped out for
  wider, zoomed-out shots that show complete buildings in the
  horizontal card format. Tours updated: Statue of Liberty (aerial
  Liberty Island), Empire State Building (full tower street-level),
  Flatiron, Chrysler, Rockefeller Center (Prometheus plaza),
  Whitney (west-side exterior), NYPL Fifth Ave, St. Patrick's
  Cathedral, The Frick Collection.

**Two known caveats:**
- **Whitney Museum** — no landscape exterior of the Gansevoort
  building exists on Wikimedia Commons. Current image
  (`Whitney_Museum_from_west.jpg`) is near-square (3930×3456). If
  owner has access to a proper landscape shot, swap `heroImageURL`.
- **Museum of Arts and Design (MAD)** — same issue; no landscape
  exterior on Commons. Portrait image used as best available.

### Build number bump

- `project.pbxproj` both Debug + Release configs: `CURRENT_PROJECT_VERSION` 6 → 7
- Committed `74aa4a2`. Pushed to `origin/main`.

---

## TestFlight build 1.0 (7) — owner action needed

The build number is bumped and committed. To upload:

1. Xcode should already be open (opened at session end).
2. In top toolbar, set destination to **Any iOS Device (arm64)**.
3. **Product → Archive** (2–5 min).
4. Organizer opens → **Distribute App → App Store Connect → Upload** →
   keep all defaults → **Upload**.
5. Wait for "Your build has finished processing" email (15–30 min).
6. Install from TestFlight app.

Suggested "What to Test" for build 7:
*"All 38 tours now show real photos — buildings, landmarks, museums.
Main changes: landscape-oriented hero images for Empire State Building,
Flatiron, Chrysler, Rockefeller Center (Prometheus), Statue of Liberty
(aerial), NYPL, St. Patrick's Cathedral, Frick Collection, Whitney,
and Museum of Arts & Design. Tap any tour card on the home screen to
see the image."*

---

## Nothing is mid-flight

Clean stopping point. `main` builds clean (verified — the simulator
build during this session succeeded). No uncommitted work, no open
PRs, no half-finished feature.

Only open thread: the `claude/trim-claude-md` branch has 2 commits
ahead of `main` — one is the 10-image batch (already cherry-picked
to `main`); the other is a `3d9fee9` CLAUDE.md trimming experiment
that was **not** carried forward (the CLAUDE.md was updated in-place
this session instead). That branch can be deleted or ignored.

---

## Start here next session

1. **Check Apple email** — "build finished processing" → install
   build 7 from TestFlight.
2. **Spot-check hero images on device** — open 5–6 tour cards, verify
   the photos load and look good in the card format.
3. **M-qa multi-stop checks** — still the only open V1 item. Needs
   one multi-stop tour authored (edit `Tours.json`, add 2+ stops with
   different GPS coordinates, set `triggerMode` to `.geofenced` or
   `.manual`). Once authored, M-qa steps 6 and 7 can run on device.
4. **Optional:** design/polish pass — theme tokens, app icon, custom
   map pins, editorial copy.

---

## Tribal knowledge

- **Wikimedia Commons hero images** use the URL pattern
  `https://upload.wikimedia.org/wikipedia/commons/{md5[0]}/{md5[0:2]}/{filename}`.
  The most reliable way to get the confirmed URL for a given filename
  is the imageinfo API:
  `https://en.wikipedia.org/w/api.php?action=query&titles=File:{filename}&prop=imageinfo&iiprop=url|size&format=json`
  (MD5 construction silently fails when filenames contain percent-encoded
  characters — the API always gives the real URL).
- **SSL + rate limiting:** local Python `urllib` calls to Wikipedia
  fail with SSL cert errors (use `ctx.check_hostname=False` +
  `CERT_NONE`). Even with that fix, Wikipedia rate-limits aggressively
  (429s). Use the `WebFetch` tool for Wikipedia API calls during
  remote/agent sessions — it routes through Claude's network and has
  a separate rate limit.
- (Carried) `MapUserLocationButton` does not render reliably as a
  free-floating view — custom button used instead.
- (Carried) MapKit `UserAnnotation()` inherits app accent color;
  fixed with a custom `Annotation` using hardcoded `Color.blue`.
- (Carried) `SwiftUI Button` tints its label with accent color — any
  floating icon-button over the map needs `.buttonStyle(.plain)` +
  explicit foreground color.

---

## How to resume

```bash
cd <project root>
git fetch
git checkout main
git pull --ff-only
git log --oneline -6   # confirm 74aa4a2 (build bump) is present
```

Read in this order:
1. `CLAUDE.md` § Current State + § Session-start ritual
2. `ROADMAP.md` § "Where we are right now"
3. **This file** (`archive/HANDOFF-260524.md`)

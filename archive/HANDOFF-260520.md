# Atlas — Handoff Notes (2026-05-20, end-of-day consolidated)

End-of-day snapshot for **2026-05-20**. Two sessions ran today:

1. **Morning remote session** — Times Square images, P1/P2/P3 audit
   cleanup, download retry. All landed on `main` later that day.
2. **Evening Mac session** (this one) — home-screen UX batch, location
   button rework, PlayerView carousel, MakerView fixes, ESB GPS fix,
   and **TestFlight build 1.0 (4) upload**.

> This file **supersedes the earlier same-day draft** that described
> only the morning remote session (its "in-flight branch" is long
> since merged). Everything from both sessions is now on `main`.

Read this first at the start of the next session, then the pointers
in § "How to resume."

---

## ⚠️ Next session is REMOTE — read this first

Tomorrow (2026-05-21) the owner is working from a **remote session**
(web / cloud container, no Mac). That changes what's possible:

| Can do in a remote session | Cannot do in a remote session |
|---|---|
| Edit Swift code, push to `main` / open PRs | Open Xcode, build, or run the iOS Simulator |
| Author tour content (`Tours.json`) | Archive or upload a TestFlight build |
| Push audio/images to `gh-pages` | Verify UI changes visually (no simulator) |
| Update docs, plan, review code | Delete remote branches (container token gets HTTP 403) |
| Let CI validate via `xcodebuild` on PRs | Check Apple email (owner does that on their phone) |

**Implication for M-qa:** the owner still has their **iPhone** in a
remote session, so they can install build 4 via TestFlight and walk
the checklist themselves. If M-qa surfaces bugs, Claude can write the
Swift fixes and push — but **shipping those fixes to the device needs
a new TestFlight build (5), which needs a Mac.** So: remote session
fixes code + lands it on `main`; the build-5 upload waits for the
next Mac session. Don't promise the owner an on-device fix same-day.

---

## What shipped today (all on `main`, all pushed)

### Evening Mac session — this session

Committed straight to `main` (owner was at the Mac, reviewing in the
simulator as we went). HEAD is `c05172b` plus tonight's build-bump +
this doc commit.

- **`c76a96d`** — PlayerView gets the inset image + paged carousel
  (same `imageSection` pattern as `TourDetailView`).
- **`e94a3de`** — drawer peek height 110 → 130; header bottom padding
  8 → 16pt. More air between the tab bar and "x tours in view," and
  between that label and the first list card.
- **`3281f31`** — first attempt at the location button: native
  `MapUserLocationButton` wired via a shared `@Namespace`. **Reverted**
  next commit — it does not render reliably as a free-floating view.
- **`fa0d01c`** — location button redone as a custom button that
  cycles `none → follow → followWithHeading`, with
  `location` / `location.fill` / `location.north.line.fill` icons
  (Apple Maps convention). Panning the map resets it to `none`.
- **`c05172b`** — fixed the orange tint: `.buttonStyle(.plain)` +
  explicit white icon on the button; replaced `UserAnnotation()` (which
  inherited the terracotta app accent) with a custom blue-dot
  `Annotation` so the user's location renders Apple-Maps blue.

Earlier on `main` from the day's other commits (already merged before
this session): seed-tour removal, ESB GPS + caption + description fix,
detail-view image inset, the home-UX batch (unified opaque island,
expanded default drawer, map-pan retraction), MakerView uniform
thumbnails + Atlas Studio avatar, and the build-3 background-audio fix
(PR #53).

### TestFlight build 1.0 (4) — uploaded tonight

- Build number bumped 3 → 4 in Xcode; committed to `project.pbxproj`.
- Archived and uploaded to App Store Connect on 2026-05-20 evening.
- **Status at session end: processing at Apple.** Owner has not yet
  received the "build finished processing" email.
- Build 4 carries the entire day's work — every commit above.

---

## Start here next session (in order)

1. **Check the Apple email.** When "Your build has finished
   processing" arrives, build `1.0 (4)` is ready in App Store Connect
   → TestFlight. It should auto-appear in the Internal Testing group.
   Optionally paste "What to Test" notes (suggestion below).
2. **Install build 4** via the TestFlight app on the iPhone.
3. **Run the M-qa 10-step checklist** on device — the list is in
   `ROADMAP.md` § M-qa. New things worth extra attention this build:
   - Home location button — tap it, confirm it cycles and the user
     dot is **blue**, not orange.
   - PlayerView — open the Times Square tour, confirm the image
     carousel swipes and is inset.
   - Drawer spacing — confirm the peek detent looks right.
4. **Any bugs found →** Claude writes the fix and pushes to `main`
   (or a PR). Remember: the fix reaches the device only on build 5,
   which needs a Mac — so batch M-qa fixes and flag that a Mac
   session is needed to ship them.
5. **Optional, fully remote-friendly:** continue M-launch-content
   tour authoring. See `docs/authoring-tours.md` § "Authoring with
   Claude (interactive workflow)." 10 tours are in `Tours.json` now;
   owner may add more.

Suggested "What to Test" for build 4: *"New this build: redesigned
home location button (Apple-style, tap to follow / follow-with-
heading), photo carousel in the player and tour detail, blue user-
location dot, drawer spacing tweaks. Plus the corrected Empire State
Building map pin. Please tap through the home map, open a tour, and
play audio with the phone locked."*

---

## Nothing is mid-flight

Clean stopping point. No uncommitted work, no parked branch, no
half-finished feature. `main` builds (verified via `xcodebuild` this
session). The only open threads are the queue above — none of them
are blocked on something half-done.

Known noise in `git status` (safe to ignore, not worth committing):
`.DS_Store` and `TRAVEL GUIDED TOUR.xcodeproj/.../xcuserdata/` show as
untracked. They're per-user/macOS cruft. A future Mac session could
add them to `.gitignore` if the clutter bothers anyone — minor.

---

## Tribal knowledge

- **`MapUserLocationButton` does not work as a free-floating view.**
  Even with a shared `@Namespace` scope between `Map` and the button,
  it failed to render. The home screen uses a custom button instead
  (`HomeView.locationButton` + `LocationTrackingMode` enum). If a
  future session is tempted to "use the native one," this is why we
  don't.
- **MapKit annotations inherit the app accent color.** `UserAnnotation()`
  rendered terracotta (the Atlas accent), and `.tint(.blue)` on it did
  not override. Fix that stuck: a custom `Annotation` with a hardcoded
  `Color.blue` circle. Same gotcha applies to any future map-content
  styling — don't trust `.tint()` on `UserAnnotation`.
- **SwiftUI `Button` tints its label with the accent color.** The
  location button looked orange until `.buttonStyle(.plain)` was added.
  Any floating icon-button over the map needs `.plain` + an explicit
  foreground color.
- **`AsyncImage` does not constrain layout size from `scaledToFill()`.**
  `HeroImageView` wraps it in a `GeometryReader` and passes the exact
  offered width as an explicit `.frame(width:)`. Don't remove that
  wrapper — it's load-bearing.
- **SourceKit shows phantom "Cannot find type" errors** for the app's
  own types during editing in this environment. They are not real —
  `xcodebuild` is the source of truth, and it builds clean. Ignore the
  in-editor diagnostics; trust the build.
- (Carried from the morning session) gh-pages pushes work from the
  remote container *if you operate in the main checkout*
  (`git checkout gh-pages` → commit → push → switch back); worktrees
  fail. Outbound HTTP is allowlisted, so you can't curl-verify a
  gh-pages URL went live — check from a real browser.

---

## How to resume

From a remote session (the expected case tomorrow):

```bash
cd <project root>          # remote container path, not the Mac path
git fetch
git checkout main
git pull --ff-only
git log --oneline -8       # confirm tonight's build-bump + doc commits are present
```

Read in this order:

1. `CLAUDE.md` § Current State + § Session-start ritual
2. `ROADMAP.md` § "Where we are right now" + § M-qa (the 10-step
   checklist) + § Known follow-ups
3. **This file** (`archive/HANDOFF-260520.md`)
4. `docs/testflight.md` — only if a Mac session is doing another
   upload (build 5)
5. `docs/authoring-tours.md` — only if picking up tour authoring

You're picking up at: **M-qa on device against build 1.0 (4)** — the
owner installs and tests, Claude fixes any bugs found. See § "Start
here next session."

---

## Carried-over follow-ups (non-blocking)

- **Stale remote branch cleanup.** ~13 merged `claude/*` branches
  still on `origin`. Mac-side task (remote container can't delete
  branches — HTTP 403). Full list + re-derivation steps in
  `ROADMAP.md` § Known follow-ups.
- **M-launch-content** — optional additional tours; owner's call on
  whether 10 is enough for V1.
- **Deferred design / polish pass** — theme tokens, real app icon,
  custom map pins, editorial copy. See `ROADMAP.md` § Polish
  milestones.

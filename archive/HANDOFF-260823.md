# HANDOFF — 2026-08-23 (session 105, local Mac, launch screen)

**Owner: "Why is my splash at launch preceded by a blank black screen? Can't it
go straight to my splash?"** It can't literally — but it can now look as though
it does. Branch `claude/launch-screen-mark`. `test_sim` **418/418**. No Swift:
three lines of `Info.plist` and one image set.

## What the blank screen actually was

**iOS's own launch screen, not ours.** `Info.plist` declared `UILaunchScreen`
as an **empty dict**, which means "paint `systemBackground` and nothing else" —
black on a dark phone, white on a light one. It is shown from the tap until the
app's first frame, and no app can skip it.

**It lingers because our first frame is the whole app.** The splash is an
`.overlay` on `ContentView`, so SwiftUI has to build the map, the first
clustering pass over 1,466 tours, the drawer and the bars *before* it can put
anything on screen — splash included. Measured in the Simulator (Debug, so
slower than a device): the catalog load + decode in `DataService.init` is
**71 ms**, and `ContentView` first appears **~2.7 s** after that. That gap is
the launch work's own design — the heavy lifting happens behind the splash —
and the cost is that iOS's blank screen covers it instead of the brass mark.

**So the fix is to draw the mark into the launch screen**, which is now a
`UIImageName` pointing at `LaunchMark.imageset`.

## What to know before touching it

- **⚠️ `UIImageName` renders the image CENTRED AT ITS NATURAL SIZE — measured,
  not assumed.** A 44pt disc came back 44pt, dead centre (0.3pt off, within the
  sampling stride), with no safe-area offset. That is why the geometry can
  simply mirror `SplashView`: a 120×98pt image, symmetric about the disc, so
  centring the image centres the mark.
- **🔴 THE RENDERED LAUNCH SCREEN IS CACHED HARD, AND IT COST MOST OF THIS
  SESSION.** iOS kept serving a 44pt disc from the *first* version of the asset
  while the file on disk had the wordmark in it — through repeated rebuilds,
  through `simctl uninstall` + `install`, and through a **build-number bump**.
  A brand-new asset name rendered **blank** rather than falling back. Only
  **`xcrun simctl erase`** cleared it. Two consequences: **verify a launch
  screen only on an erased simulator or a freshly-installed device**, and warn
  the owner that a stale-looking launch screen on the next TestFlight build is
  fixed by deleting the app and reinstalling.
- **⚠️ THE LAUNCH SCREEN FOLLOWS THE SYSTEM APPEARANCE, NOT THE IN-APP
  PICKER**, and it cannot do otherwise — it is drawn before the app runs, so
  nothing knows about `colorSchemePreference`. Phone on Light with the app
  forced to Dark gives a white launch screen into a black splash. Accepted:
  matching the system is the best a static screen can do.
- **The light/dark split is two renditions**, tagged by luminosity in
  `Contents.json` — a launch screen cannot resolve a semantic colour. Verified
  by sampling the ground pixel: `(255,255,255)` light, `(0,0,0)` dark.
- **`scripts/render-launch-mark.swift` regenerates the asset** from the real
  New York face at the exact `SplashView` geometry. If the wordmark, the disc
  size or `LaunchZoom.originFraction` ever changes, re-run it — the two screens
  are shown back to back and any drift reads as a jump.

## Verified

On an **erased** simulator: launch screen renders disc + wordmark in light and
in dark; a crop of the launch screen beside the SwiftUI splash lines up on face,
tracking and position. The splash's disc looks marginally larger only because
its resting pulse (1.0 → 1.10) is mid-breath; it *starts* at 1.0, which is the
static image exactly.

## Owner question this raised, worth picking up next

**"I was in the subway with weak reception; the app loaded but the images
didn't. Does that mean we're not preloading? Should the splash wait until
everything is loaded?"**

We *are* preloading — `LaunchImageWarmup` fetches the first **8** hero images —
but with a **1.2 s deadline**, inside a **3.0 s** gate ceiling. On a weak
connection neither is enough for a single photo, so nothing warmed and the
hand-off happened as designed.

**Waiting for "everything" is the wrong fix and should not be built:** with no
signal it may never complete, and the splash would read as a frozen app. The
ceiling exists precisely to prevent that. Everything except photographs already
works offline — catalog, map, titles, distances, downloaded audio.

**The real gap is that photos are not kept for offline:**

1. **🔴 A DOWNLOADED TOUR DOES NOT BRING ITS PHOTOS.** `TourDownloader` fetches
   the audio and nothing else — so a tour deliberately saved for the Underground
   still shows empty boxes. This is the one to fix first.
2. Hero images *should* survive offline via `URLCache.shared` (50 MB memory /
   200 MB disk, set in `App.init`) — but that is **assumed, not proven**, and
   the owner's report is the first evidence against it. Verify before building
   anything on top of it.
3. Smaller: say "you're offline" rather than showing blank grey.

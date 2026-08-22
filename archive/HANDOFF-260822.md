# HANDOFF — 2026-08-22 (session 102, web/remote, code)

**Read this before touching the launch sequence.** Branch
`claude/launch-performance-animations-df4d7p`, **[PR #559](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/559) — OPEN, NOT MERGED.**
Four TestFlight builds cut from it: **1.1 (99), (100), (101), (102)**.

## Why you are picking this up

The owner asked for a local session **specifically so the launch animation can be
watched in the Simulator instead of costing a TestFlight build per iteration**.
Four builds went out; three were rejected on device. That is the process failure
to fix first — see § "Do this differently".

## What is actually shipped and good (build 99 — keep this)

The **launch performance work is done and the owner confirmed it**: *"definitely
much more snappy and the animation is smooth."* None of the animation churn since
has touched it, and it should not be reverted while fixing the transition.

- `Data/LaunchGate.swift` — the splash waits for **readiness** instead of a fixed
  2-second timer. Catalog loaded + location settled + photos warmed, bounded by a
  **1.2s floor** and a **3.0s ceiling**.
- `ContentView` mounts from the **first frame** with the splash overlaid, so
  `MKMapView` creation, the first clustering pass over 1,418 tours and the
  mini-player window's install all happen **behind** the splash.
- The launch camera resolves **without animation** — no more watching the map
  travel from the NYC fallback.
- The mini-player's window installs during the splash but **hidden** (it sits a
  level above every window in the scene, so it would paint over the splash).
- The location permission alert is withheld until after hand-off. `LaunchGate`
  treats `notDetermined` as *settled* so that delay can't stall the gate.
- `Data/LaunchImageWarmup.swift` — warms the first screenful of card heroes into
  `ImageCache` during the splash, choosing them via the app's own
  `HomeRailsViewModel.rails`. Bounded by its own **1.2s deadline**. Owner asked
  for this explicitly: *"I want ready including photos."*

## 🔴 The bug in build 102 — diagnosed, NOT fixed

Owner on 102: *"the build basically did none of what i asked for."* They are
right, and the cause is a layering mistake, not a timing one.

**`SplashView` paints `Color.black.opacity(groundOpacity)` OVER the app, and
fades it uniformly.** `ContentView` has the expanding circular mask applied to
*itself* — i.e. **underneath** the black. So:

- the opening expands **under an opaque sheet** and cannot be seen;
- the black fades out globally (0.122s → 0.281s);
- by the time the black has gone, the opening is ~94% finished (it runs
  0.000s → 0.298s).

**Net visible effect: a cross-fade.** Exactly the thing three rounds of work were
meant to replace.

### The fix

Invert it. **Punch the hole in the BLACK, not in the app.** A container transform
reveals the destination through a growing hole in the covering layer:

```swift
// in SplashView, replacing the plain Color.black
Rectangle().fill(.black)
    .mask {
        Rectangle()
            .overlay {                       // the hole
                Circle()
                    .frame(width: holeDiameter, height: holeDiameter)
                    .position(LaunchZoom.origin(in: geo.size))
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }
```

Then **remove `LaunchZoomReveal` from `ContentView` entirely**, or reduce it to
the scale + blur only (no mask) — the depth cue is worth keeping, the mask on the
app is not.

## ⚠️ Second bug, unverified but likely — check this in the Simulator

`Components/LaunchZoomReveal.swift` branches:

```swift
if progress >= 1 { content } else { content.scaleEffect(…).blur(…).mask(…) }
```

Two `@ViewBuilder` arms are **different view types**, so when progress reaches 1
SwiftUI may treat this as a structural change and **rebuild the entire
`ContentView` subtree — including `MKMapView`.** If so, the map is torn down and
recreated at the 0.42s mark, which would undo the whole point of building it
early, and could show as a flash or a camera reset at the end of the launch.

**Verify first** (it may be fine — SwiftUI sometimes preserves identity here).
If it is real, apply the effect unconditionally and neutralise it by value
(radius large enough to be a no-op) rather than branching.

## Owner decisions — settled, do not re-litigate

| Decision | Quote / date |
|---|---|
| The effect is a **zoom transition / container transform** (the iOS folder-open) | Owner sent a screenshot, 2026-08-22: *"I like the transition from the splash to the app.. snappy"* |
| **The mark opens** (mask reading), not the panel | *"def prefer mark opens (A)"* — confirmed at ⅙× speed |
| Chrome arrives **from the right** | 2026-08-22 |
| **Three edges settle on one frame** — module, search bar, drawer | *"I like that the things settle at exactly the same time"* |
| The **haptic fires on the settle**, not before | *"the haptic is at the wrong beat, it's not synced with the things settling into place"* |
| **Photos are part of "ready"** | *"I want ready including photos"* |
| The location dot stays **centred** | *"moving the location up so that it's not centred... I don't think it works"* |

## 🔴 Rejected approaches — do not rebuild these

1. **Pin bloom** (pins rippling outward from the user) — build 100. *"cant really
   read the pin bloom."* Deleted.
2. **Travelling mark** (brass circle flying to the location) — build 101.
   Underwhelming, and it forced the framing hack below.
3. **Off-centre launch framing** (`LaunchLayout`, user in the upper third) —
   existed *only* to give the travelling mark somewhere to land. Deleted. This was
   an animation dictating how the map frames the user; do not reintroduce it.
4. **Staged assembly as the whole transition** (builds 100–101) — *"slow and feels
   very lethargic."* 🔴 **The cause was not duration.** The destination did not
   exist yet when the transition ended, so the user watched furniture arrive.
   Shaving milliseconds would never have fixed it.
5. **Rail-card stagger** — removed with the assembly.

## Tribal knowledge earned here

- 🔴 **A `.transition` on a MapKit annotation replays forever.** MapKit rebuilds
  annotation views as the region changes, and the home map emits settle frames for
  *seconds* after any camera move. Anything animating on a map pin must be driven
  by a **value**, not an insertion animation. (This is why `atlasPinBloom` was
  built as a number — the approach was right even though the feature was cut.)
- 🔴 **A fraction-based timing assertion silently re-scales.** A test pinned the
  splash cut at `window <= 0.2` — a fraction. The hand-off went 0.9s → 0.42s, the
  fraction had to grow to describe the same real duration, and the test started
  failing while the cut was **shorter** than before. `LaunchBloom.duration` now
  lives beside the fractions so timing can be asserted in **seconds**.
- 🔴 **`ramp` must return exactly 1.** `(p - delay) / window` lands on
  0.9999999999999999 for ordinary inputs, and everything downstream treats 1 as
  "arrived". ⚠️ Snapping on `progress >= delay + window` does **not** work —
  `0.2 + 0.4` is `0.6000000000000001`. The tolerance has to sit on the result.
- ⚠️ **A `GeometryReader` must never wrap the app to read a size.** It fills the
  proposal and aligns its child top-leading, so it changes layout. Put it inside
  the `.mask { }` — a mask's content is already laid out against the masked
  view's bounds.
- ⚠️ **Two insertion-anchor slips cost two CI cycles.** Anchoring an edit on "the
  `var` line" stranded a `@ViewBuilder`; anchoring on "the file's last brace" put
  a helper inside the wrong struct. **Parse the enclosing declaration** — Swift
  declarations here routinely carry attributes and doc comments above them.
- The CI unit-test job takes **~10 minutes** (most of it simulator prep). The
  build job is ~3. Don't diagnose from a log tail — **grep the whole log for
  `error:`**; one failure hid in 1.16 MB.

## Do this differently

**Verify launch animations in the Simulator before cutting a build.** Every visual
claim in builds 100–102 was reasoned from code, never watched. The Simulator
cannot show the haptic, but it shows everything else — and the layering bug above
would have been obvious in one launch.

To exercise it: cold-launch (delete the app first for a true cold image cache),
and set a simulated location so the dot resolves. `LaunchBloom.duration` can be
temporarily raised to ~3s to inspect the sequence, then put back.

## State of the branch

- Last commit: `a8a776c`. CI green (build + validator + unit tests, 29 tests).
- **PR #559 is a code PR — needs owner OK + visual review before merge.**
- Nothing here is merged to `main`; `main` is untouched by this work.
- The mockups used to settle the design:
  https://claude.ai/code/artifact/72d5bf1d-6339-4b1c-8cd8-cfbf05211306

---

## Session 103 (local Mac) — the layering bug is FIXED and WATCHED

Commit `4a19ff5` on the same branch. `test_sim` **414/414**. Every claim below
was verified frame by frame in the Simulator with `LaunchBloom.duration`
temporarily at 3.0s — the process failure §"Do this differently" names.

- **The hole is punched in the whole splash now** (black + wordmark + mark),
  not in the app. `LaunchZoomReveal` keeps only the scale and blur and applies
  them **unconditionally**, neutralised by value — so the `progress >= 1` branch
  that could have torn down `ContentView` (and `MKMapView`) is gone. That second
  suspected bug is closed by removal rather than by testing it.
- **🔴 The mark has to be sized OFF the hole, and a scaleEffect cannot do it.**
  First attempt kept the 44pt mark with `scaleEffect(1 + 8 * zoomEase)`: the
  opening starts at exactly the mark's radius and grows toward a screen corner,
  so it outran the mark within a frame or two and the brass simply vanished —
  no "mark opens" at all. The mark is now a disc of `holeRadius + a band that
  thins`, so after masking what is left is a **brass rim leading the opening**.
  ⚠️ `holeRadius` must return **0 at rest**, or the resting brand screen is a
  44pt window onto the map.
- **🔴 The bottom module was landing in ONE JUMP, and there were two causes.**
  It lives in a separate `UIWindow`, which a `withAnimation` transaction does
  **not** reach — and it was being unhidden with the assembly already at 1, so
  there was nothing to animate from either. Fixed by rendering one frame at 0
  before `playHandOff()` (a 32ms sleep after `setHidden(false)`) *and* giving
  the module its own curve restating `LaunchBloom.assembly` in seconds.
  ⚠️ **Anything animated outside the main window needs both halves.**
- **The visible dimming outside the opening late in the sequence is deliberate**
  — `groundOpacity` now only clears in the last 14% — not a leak. Measured: the
  black is pure (corner luminance 0.0) for the whole first half.

**Superseded below** — builds 103, 104 and 105 followed, and the owner has now
reviewed all three on a device.


---

## Session 103, rounds 2–4 — TestFlight 1.1 (103) → (104) → (105)

**Owner on 105: "Much better."** Three device reviews, and the third round found
the thing that had been generating every timing bug since the work began.

### 🔴 THE ROOT CAUSE OF THE WHOLE TIMING MESS: `withAnimation` on a plain Double

The hand-off was `withAnimation(.linear(duration:)) { setHandOffProgress(1) }`.
**SwiftUI does not step a plain `Double` through the intermediate values.** It
re-renders each dependent view **once**, with progress already at 1, and then
animates each *rendered property* — an opacity here, a scale there — from its
old value to its new one across the whole duration.

So every `delay` and `window` in `LaunchBloom` was evaluated at `progress == 1`
and thrown away. The ramps existed, the tests passed, and none of it reached the
screen. What that looked like: the black clearing while the disc was half-grown,
the drawer rising before the brass had gone, everything sliding at once. **Three
separate "fixes" were built for those symptoms** (a stroked ring tied to the
disc's radius, a scale instead of a frame, a per-window animation curve) — each
moved the problem without solving it.

**`playHandOff` now TICKS the value** at ~display rate in a loop. Every view
sees the real intermediate numbers, so the ramps mean what they say — and since
no SwiftUI animation is involved, the bars in their separate window cannot fall
out of step with the main one either.

⚠️ **Do not add `.animation(...)` to anything reading `handOffProgress`.** It
would animate *toward* each ticked value and lag the whole sequence. The
explicit curve that previously papered over the cross-window problem is gone.

### 🔴 THE OTHER BIG ONE: whichever body reads the progress redraws 60×/s

`handOffProgress` ticks ~60 times a second. Any view whose **body** reads it is
re-evaluated that often — and `ContentView`'s body is the whole app while
`HomeView`'s is the map, its clustering and the rails. That is a large part of
what the owner reported as *"the performance/animation feels very lagg-y."*

Both now read **nothing**. The reads live in leaves that wrap content their
parent already built: **`Components/LaunchEntrance.swift`** (search bar, chips)
and `BottomSheet` itself (the drawer's two offsets). ⚠️ Do not "simplify" this
by reading `LaunchState` in the parent and passing a `Double` down — that puts
the read straight back into the expensive body.

Also removed for cost: the app-wide scale-and-blur (`LaunchZoomReveal`, deleted
— a full-screen offscreen pass, and invisible behind the disc anyway).

### The mark: three shapes tried, one kept

1. **Masked app + black faded over it** (build 102) — the opening expanded under
   an opaque sheet; read as a cross-fade.
2. **Hole punched in the black, mark sized off the hole** — leaves a brass RING
   with map inside it. Owner: *"i dont like that the brass circle becomes a ring
   and that there's blue behind it."*
3. **✅ A solid disc over a plain black rectangle.** It expands to cover the
   screen, then dissolves into the map. No mask, no hole, no seam — two shape
   fills a frame.

⚠️ **The black's opacity IS the disc's own value** (`groundOpacity { markOpacity }`).
Two ramps that are meant to coincide will not under load; one number cannot
disagree with itself.

⚠️ **`LaunchZoom.originFraction` is 0.5 and the splash's `GeometryReader` spans
the whole screen**, because the opening has to sit exactly where the map draws
the user's blue dot — the map fills the screen and the launch camera centres the
user. Reading inside the safe area put it ~30pt high.

### The drawer, and why it looked open before it was

Two causes, both worth knowing:

- 🔴 **`.offset` does not move a `.background`.** It is a rendering transform and
  leaves the layout frame where it was; `.background` sizes itself to that
  frame. Applied mid-chain, the panel and its rounded corners sat still at the
  detent while only the rails slid inside. Owner: *"the drawer portion is
  already showing at mid-detent, with the content itself sliding up."* The
  offset now sits **past** the background and clip shape.
- 🔴 **The panel is clipped to its RESTING box**, so the visible height is
  exactly `detent − offset` — a closed drawer that grows, with **no per-frame
  relayout of the rails**. The clip also stops rail cards showing through the
  gaps beside the floating bars.
- 🔴 **Travel distance is part of "arriving together".** The bars travel ~166pt;
  the drawer was parked 1200pt down. On one shared ramp the bars are visually
  home while the drawer is still a screen away, so they read as two arrivals.
  It is now parked just out of sight (closed strip + bars + margin).
- ⚠️ **There is a deliberate BEAT between the block landing and the opening
  starting** (0.64 → 0.74). Butted together, the drawer never appears closed at
  all; it simply keeps rising.

### Owner decisions this round

| Decision | Quote |
|---|---|
| The mark stays a **solid disc** the whole way | *"it should stay as a solid as it expands"* |
| It sits **exactly on the blue location dot** | *"as if the brass circle becomes the location marker"* |
| Module = tab bar + mini-player + **closed drawer**, one object, then it opens | *"comes in together into place… and then the drawer opens into mid-detent"* |
| **Search bar from the top**, capsules from the right | 2026-08-22 |
| Haptic must land **on** the settle | *"haptic feels early"* → bias 0.07s, then 0.15s |

### State

- Hand-off **0.55s**. Beats: zoom 0–0.36 · dissolve 0.36–0.48 · block 0.50–0.64
  · *pause* · drawer opens + chrome arrive 0.74–1.0 · haptic at 1.0 + 0.15s.
- `test_sim` **417/417**. PR #559 still **open** — code, needs the owner's merge.
- ⚠️ **`LaunchBloom.settleLatency` is the one number to turn** if the buzz still
  misses the beat.
- ⚠️ Verifying this in the Simulator means setting `LaunchBloom.duration` to ~4s
  temporarily. **Grep for `TEMP-SLOWMO` before committing** — it was used four
  times this session.

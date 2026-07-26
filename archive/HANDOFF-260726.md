# HANDOFF — 2026-07-26 (session 74, code/web)

Group Listen polish driven turn-by-turn off owner screenshots on real
TestFlight builds, plus **two real bugs the polish surfaced** — one of which had
nothing to do with Group Listen at all.

Merged: **[PR #441](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/441)**
(`57095f0`), **[PR #443](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/443)**
(`bf9f98e`), **[PR #442](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/442)**
(`2cb77f1`, docs). **[PR #444](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/444)**
was closed as superseded — its commits went onto #443's branch so one build
could carry everything. Builds cut: **1.1 (42) → (43) → (44) → (45) → (46)**,
all owner-reviewed on device.

## The green icon replaced the bottom banner (#441)

Owner, on the gold session strip above the mini-player: *"rather than that
banner … just make the group icon green when group play is active so when a
user clicks on it it takes them to the group play sheet."*

`GroupBanner.swift` deleted; the tour page's Group Listen button turns **green**
while `groupListen.isActive` and opens the sheet, whose active-session view
already carried Leave. Retires the deferred "banner overlaps page content" item.

- **`BottomModuleRoot`'s `onGeometryChange` height measurement STAYS.** It was
  added to fix the banner's untappable Leave button, but it is the general fix
  that makes anything above the mini-player tappable. Reverting it to a constant
  would re-arm that trap.
- **Accepted consequence:** the indicator now lives only on the tour page, so
  navigating away leaves no on-screen sign a session is running, and Leave means
  going back. If that bites, the cheap fix is a tint/dot on the mini-player, not
  bringing the strip back.
- Glyph also went 17 → 16pt (owner call, on-device).

## 🐛 The tab bar that looked dead — NOT group-specific (#443)

Owner: *"once I've joined a tour now the tab bar no longer works."* Two
follow-up details cracked it: **the icons highlight** and **the tour page is
still open**.

So the tab bar was never broken. The tap registered and flipped `selectedTab`
(hence the highlight); what failed was **dismissing the tour-detail layer**, so
the new tab's content loaded *behind* it. The original session-8 design note
predicted this exact symptom: *"icon updates, content doesn't."*

**Why the existing auto-dismiss missed:** it lives in `ContentView`'s
`.onChange(of: selectedTab)` — in the **main window**, which is entirely covered
by the UIKit detail modal at the moment of the tap, and **SwiftUI can stop
delivering updates to a hierarchy hidden behind a modal presentation**. The
write lands; the observer never runs.

**Fix:** `AtlasTabBar`'s binding dismisses `tourPresenter`/`makerPresenter` as
part of the tap, from the **secondary window**, which is never covered.
`ContentView`'s `.onChange` stays as a backstop for paths that change tabs
without a tap.

**Durable lesson: don't put a side effect that must run in a window that a modal
can cover.** Joining a group was just a reliable way to end up on a tour page —
this was reachable any time a detail layer was open.

## 🐛 Missing mini-player + tab bar — third attempt, different strategy (#443)

Reported again on 1.1 (43) *and* (44), specifically **launching from TestFlight's
"What to Test" screen**. The screenshot proved the layout was fine (drawer
reserved the space, map visible in the gap), so the secondary window simply
never installed.

**The design flaw:** the bars existed **only** in that window — `ContentView`
never rendered them — so any failed install meant no bars for the whole session
with nothing to fall back to. Every earlier fix was a bet on scene timing:

| trigger | how it's missed |
|---|---|
| `ContentView.onAppear` | fires once, ~2s in; defers if the scene isn't `.foregroundActive` then |
| `scenePhase` → `.active` | `.onChange` fires only on a *change*; a launch already active never fires it |
| `UIScene.didActivateNotification` | one-shot, useless if activation preceded registration |
| retry chain (added this session) | helped, but still assumed the window was the only way to get bars |

**Fix that finally holds:** `ContentView` renders `BottomModuleRoot` **inline in
the main window** whenever `bottomModuleWindow.isInstalled` is false (controller
is now `@Observable`). Ordinary SwiftUI, so it cannot fail for scene-lifecycle
reasons. The retry chain still promotes to the real window within seconds, at
which point the inline copy disappears. In fallback mode the only loss is
z-order above UIKit modals.

> ⚠️ **A mistake I made and had to undo.** I added
> `w.frame = scene.coordinateSpace.bounds` and described it to the owner as
> harmless insurance. It is wrong twice over: it pins a geometry snapshot so the
> window stops tracking the scene across rotation, and if the scene isn't
> configured yet it pins **zero** — creating exactly the invisible window it was
> meant to prevent. It may have been making 1.1 (44) worse. Reverted;
> `UIWindow(windowScene:)` tracks scene geometry itself. Readiness now lives in
> `foregroundActiveScene()`, which rejects a scene whose coordinate space is
> still empty.

Also: `setInteractiveBottomInset` now clamps to at least
`AtlasBottomModule.height()`. The measurement may legitimately be *larger* (that's
why it's measured) but must never arrive smaller — the module animates on
`nowPlayingTour` changes and `onGeometryChange` reports intermediate frames, so a
transient under-measurement could shrink the touch strip and leave painted bars
visible but dead.

## The Group Listen sheet, iterated on device (#443)

Five rounds of owner screenshots. Final state:

- **Type:** everything is `AtlasTypography.caption`, including the nav title
  (principal item, ALL CAPS, matching Settings). The **5-character join code and
  the code entry field deliberately stay large and monospaced** — read across a
  room and checked while typing, so legibility beats compactness.
- **`.presentationDetents([.medium, .large])`** — opens half height, drags to full.
- **Glyph 40 → 16pt**, matching the tour action row via one shared constant.
- **All three screens are two aligned columns:** chooser `LEAD A TOUR` /
  `JOIN A TOUR`; leader `SCAN TO JOIN` (QR) beside `OR ENTER CODE` (characters),
  captions on the **same line** so the options read as equals; join screen scan
  card beside the code field.
- Copy roughly halved. The download line survives only when the tour isn't
  downloaded, and still says **each phone streams its own audio** — the honesty
  fix that line exists for.

### Two layout causes worth separating

1. **Content overlapped the nav bar** ("YOU'RE LEADING" printed on the
   "LISTEN TOGETHER" title). Not padding: the content sat in a fixed
   `maxHeight: .infinity` frame, so anything taller than the detent overflowed
   **upwards** through the navigation bar. Now a `ScrollView`, so out-of-bounds
   rendering is impossible at any device size or Dynamic Type setting.
2. **Content cut off at the bottom** was separate: the mini-player + tab bar
   render in a *higher-level window* and paint over the sheet. The sheet now
   reserves `AtlasBottomModule.height()`.

### ⚠️ QR size floor: 110pt

`qrSize` went 170 → 132 → 140 → **110**. The payload is a ~58-character https
link (~33–37 modules), so 110pt is ~3pt per module. **Owner device-verified as
still scanning well ("works, not too small") — treat 110 as the floor.** If that
screen ever needs more room, open it at a taller detent; do **not** shrink the
code further, because an unscannable QR defeats the feature.

## Process lessons from a bad CI day

- **GitHub Actions was badly degraded for hours.** A step that normally takes
  2½ minutes ran 33+. **Cancel and re-run before theorising** — that cleared it
  every time. I waited ~40 minutes and built two wrong theories first.
- **Don't trust a single in-flight API reading.** I reported an upload as
  "running long" when it had already finished; the job-state responses lag.
- **I broke my own "never build before the simulator build is green" rule once,
  deliberately**, on a merge of two branches touching disjoint files that had each
  compiled green. It was fine (archive passed, CI confirmed after), but state the
  reasoning when doing it.
- **When a device-only symptom resists a fix, get one more fact before writing
  code.** Asking "do the icons highlight?" and "is the detail page still open?"
  solved the tab bar instantly after the join-path read found nothing.

## Owed / deferred

- **Two-phone Group Listen sync** — still never run end-to-end since the fixes.
  Owner has confirmed QR join, sheet layout, Leave, and the tab bar, but not
  actual synced playback across two devices.
- **Branch cleanup** — see the verified table in the section below. The git proxy
  blocks branch deletion from web sessions, so this needs the GitHub UI or a
  local session.
- **If the bars ever go missing again**, the inline fallback should make it
  impossible — if it still happens, that points somewhere new entirely, and the
  next step is a visible diagnostic rather than more hardening.
- Still open from before: real leader handoff, Hosted mode (Supabase Realtime),
  Pro Guide tier, anonymous followers, paid tours Phase 3 (StoreKit 2 buyer UI).

## Branch cleanup — verified list (2026-07-26)

**Read the gotcha first.** Every branch below was **squash-merged**, so its
commits are *not* ancestors of `main`. `git branch --merged main` will **not**
list them, and `git branch -d` will **refuse** them. That is expected and does
not mean work is unmerged — the content is in `main` under a single squash
commit. Confirm with `git log --oneline main -- <a file the branch touched>` or
by the PR link, then use `-D` / `push --delete`.

**Safe to delete — squash-merged, content is on `main`:**

| branch | landed as |
|---|---|
| `claude/shareplay-feature-bug-7chszc` | #423 `3e9a6d9`, #428 `18ba375` |
| `claude/docs-group-listen-banner-removal` | #442 `2cb77f1` |
| `claude/bottom-module-install-retry` | folded into #443 `bf9f98e` (its own PR #444 was closed, not merged — the commits went onto #443's branch) |
| `claude/group-listen-sheet-compact` | #443 `bf9f98e` |
| `claude/handoff-260726` | #445 — **only after that PR merges** |

```bash
# From a local Mac session, after confirming main has the content:
for b in claude/shareplay-feature-bug-7chszc \
         claude/docs-group-listen-banner-removal \
         claude/bottom-module-install-retry \
         claude/group-listen-sheet-compact; do
  git push origin --delete "$b"
done
```

**DO NOT DELETE — these hold unmerged work:**

| branch | why it exists |
|---|---|
| `claude/amsterdam-handoff-preserve-hlhyp8` | holds `drafts/AUDIO-PENDING-SURVEY.md` — the audio-pending queue tracker (Montreal 29 / Rome 30 / Berlin 36) |
| `claude/london-batch3-scripts-260616` | staged London batch 4 + 5 multi-stop walks, awaiting narration |
| `claude/dreamy-wozniak-tags-260612` | tag taxonomy proposal, never merged |
| `claude/paris-scripts-260622` | **status unclear** — Paris has since launched (50 tours), so this may be spent, but that was not verified here. Check before deleting. |

**Corrections to earlier notes:** previous handoffs listed
`claude/group-listen-icon-size` and `claude/group-listen-active-icon` as cleanup
owed. **Both are already gone from the remote** — deleted since. Any list that
still names them is stale; the table above was verified against
`list_branches` on 2026-07-26.


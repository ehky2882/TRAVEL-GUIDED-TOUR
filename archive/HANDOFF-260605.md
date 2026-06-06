# Atlas — Handoff Notes (2026-06-05, session 22)

Implementation session — **full-screen Player polish**, owner-driven
turn-by-turn at the simulator. Two code PRs shipped to `main`, both
`PlayerView`-focused. **No build bump** (stays at 32). No
`AudioPlayerService` API changes. 84/84 tests pass on each PR.

File touched: `Features/Player/PlayerView.swift` (both PRs) +
`ContentView.swift`, `Components/BottomModuleWindow.swift`,
`TRAVEL_GUIDED_TOURApp.swift` (PR #148 only).

---

## What shipped

### PR #148 — full-screen cover + caption typography + transport/carousel
- **Full-screen presentation.** `PlayerView` moved from a partial
  `.sheet` to covering the whole screen; the **bottom-module window is
  hidden** while it's up via new `BottomModuleWindowController.setHidden(_:)`,
  toggled from the App entry on `appShared.showingFullPlayer`. The
  mini-player + tab bar no longer show through the bottom of the player.
  (The bottom-module window sits one level above modals — see
  `BottomModuleWindow.install`'s `windowLevel = .normal + 1` — so a
  cover alone wouldn't hide it; hence the explicit `setHidden`.)
- **Carousel parity with the detail sheet** — square corners,
  pinch-to-zoom, no load crossfade.
- **Typography flattened to the CAPTION token** (13pt SF Mono); the
  redundant tour-title section was removed and the now-playing block
  moved up under the carousel. (Stop titles later moved to BODY
  all-caps — see PR #150.)
- First version added a chevron-down close + skip ±10s on single-stop
  tours. (Both superseded by PR #150's grab-handle + 5-button row.)

### PR #150 — drag-to-dismiss sheet, overflow menu, 5-button transport
- **Drag-to-dismiss.** Player is a `.fullScreenCover` (edge-to-edge to
  the very top — native sheets can't go full-bleed). A grab handle
  drives a **custom downward drag-to-dismiss** (`@State dragOffset` +
  `.offset` on the content, dismiss past ~150pt or a fling). A ZStack
  `AtlasColors.background` backing means the drag reveals the player's
  own surface color, not a black gap.
- **Overflow (•••) menu** on the top-right of the hero image, mirroring
  `TourDetailView.overflowMenu`: Download · Save · Share · Follow
  (disabled) · Go to creator · Report. Player is wrapped in its own
  `NavigationStack` (toolbar hidden) so "Go to creator" can push
  `MakerView`.
- **Transport → five equal columns** so play is always screen-centered:
  `speed (menu) · skip-back-10 · play · skip-forward-10 · next-track`.
  Skip ±10s always live; next-track jumps to the next stop, disabled on
  single-stop tours. Speed cycle gained 0.5×/0.75×. Play + scrubber are
  tinted `AtlasColors.mapPin` gold.
- **Scrubber** is a thin gold line (no thumb knob), still drag-to-seek.
- **System volume slider** (`MPVolumeView`, iOS/visionOS) below the
  transport row. NOTE: MPVolumeView renders **blank in the simulator**
  (no audio hardware) — it only draws on a real device / TestFlight.
  Owner chose system volume over an app-volume slider on purpose.

---

## Decisions made this session (owner)
- All Player text → CAPTION; stop **titles** specifically → BODY
  all-caps (current-stop + stops-list rows).
- Player must **cover** the bottom module (not show through).
- Play button **screen-centered**; speed far left, next-track far right.
- Volume = **system** (`MPVolumeView`), accepted that it's blank in sim.
- Overflow + speed menus stay **native** iOS menus (system font — can't
  apply caption to a `UIMenu`; owner OK'd keeping native).
- Player should feel like a **draggable sheet** that goes **full-screen
  to the top** → custom drag-to-dismiss on a full-screen cover.

## Worth a real-device / manual check
- **Drag-to-dismiss feel.** The automation HID can't generate touch-move
  events, so the drag was never exercised by tooling — only the owner's
  manual mouse-drag. Tune the dismiss threshold / spring if it feels too
  eager or too sticky.
- **Volume slider + AirPlay button** only appear on device.
- **"Go to creator"** pushes MakerView inside the player's own
  NavigationStack (the bottom module is hidden during this) — verify it
  feels right.

## Not done / deferred
- End-of-tour state still a plain replay (no "tour complete" / next-tour
  suggestion) — flagged in discovery, not in scope this session.
- No build bump; owner hasn't asked for a TestFlight cut of this work.

## How to resume
1. Session-start ritual (git/PR health + read this file).
2. Player work continues in `Features/Player/PlayerView.swift`.
3. See `~/.claude/.../memory/reference-atlas-sim-automation.md` for how
   to drive the Player in the sim (start audio → tap mini-player; the
   detail sheet's pill is reachable via `wait_for_ui label:"Start Tour"`).

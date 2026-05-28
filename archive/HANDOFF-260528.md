# Atlas — Handoff Notes (2026-05-28, session 11)

Shipped PR #91 — eliminates the chrome-shade seam at the top of
the mini-player when the tour detail sheet is up. Restructured
the bottom-module bars to grow edge-to-edge on Library / Me /
detail-up while keeping the floating-island look on Home (button
x positions identical across both forms, per the design rule).
TestFlight build 1.0 (16) archived and ready in Organizer.

---

## What shipped this session

### PR #91 — bottom-module chrome-shade seam fix

Root cause of the visible "bump" at the top of the *MINI PLAYER*
when the tour detail sheet is up: `Color(uiColor: .secondarySystemBackground)`
resolves to a different RGB at `.base` vs `.elevated`
`userInterfaceLevel` traits. Detail body lives in window 1
(`windowLevel = .normal`, effectively `.base`); bars live in
window 2 (`windowLevel = .normal + 1`, which UIKit treats as
elevated). The two RGB values diverge enough in dark mode to read
as a horizontal *CHROME* band at the boundary. The owner-spotted
geometric component was the painted `Rectangle` in `BottomModuleRoot`
that ran full-width while the bars were inset 8pt H — that
mismatch made the band particularly visible.

Two coordinated changes:

1. **Hardcoded RGB in `AtlasColors.secondaryBackground`.** Replaces
   `Color(uiColor: .secondarySystemBackground)` with a hardcoded
   `UIColor(dynamicProvider:)` block that keys only on
   `userInterfaceStyle` (light/dark) — no elevation variance.
   Both windows resolve to identical RGB:
     - Light: `#F2F2F7`
     - Dark:  `#1C1C1E` (Apple's `.base` shade — matches
       Settings/Music/Photos default)
   New companion `AtlasColors.secondaryBackgroundUIColor` for
   UIKit consumers (the detail's hosting view background in
   `BottomLayerPresentation`). Aliases `miniPlayerBackground` +
   `tabBarBackground` point at the same value so future
   per-surface tuning is easy.

2. **Bars grow edge-to-edge on Library / Me / detail-up; stay
   island only on Home-no-detail.** New `extendsToScreenEdges`
   parameter on `MiniPlayerBar` + `AtlasTabBar`. When `true`:
   painted background extends to the screen edges, square outer
   corners, painted 8pt strip below; buttons stay inset via
   *inner* horizontal padding so their x positions match the
   island form. When `false`: current Home form (inset 8pt H,
   rounded bottom corners, transparent 8pt outer strip).
   `BottomModuleRoot` decides the flag from
   `appShared.selectedTab` + `tourPresenter.presentedTour`;
   the separate edge-to-edge `Rectangle` it used to paint is
   gone. ContentView paints no extra fill.

### Diagnostic workflow used (worth remembering)

Spent most of the session debugging visually with **bright
contrasting diagnostic colors** instead of theorizing about
shade-trait propagation. Set magenta for the sheet body, cyan
for the mini-player, yellow for the tab bar, orange for the
behind-fill rectangle, screenshot the bottom region zoomed —
owner pointed at the boundary instantly ("the orange isn't fully
aligned with the top of the mini-player"). Saved as
`feedback-visual-debugging.md` for future sessions. Apply it
early when next debugging any multi-surface visual bug.

### Owner-noted polish (parked for follow-up)

While in the bottom module the owner asked me to remember three
small refinements they may want later:
- Mini-player title: lift to a stronger *TYPE STYLE*
  (`.subheadline` or `.footnote`) so the tour name reads as the
  primary line and the maker name as secondary. Both lines
  currently use `caption`, so there's no hierarchy.
- Match skip-forward (size 22 → mini-player uses 20) and
  play/pause (size 18) glyph sizes — currently asymmetric.
- Mini-player avatar (32pt) vs play ring (36pt) feel off-balance.
  Bumping the avatar to 36pt would equalize leading/trailing
  visual weight within the 54pt bar height.

Re-raise next time work touches the bottom module.

---

## Verification

- `test_sim`: 84/84 passing.
- `xcodebuild archive`: clean. Archive at
  `/tmp/Atlas-20260528-1617.xcarchive`. Organizer opened.
- Visual confirmation in iPhone 17 Pro (iOS 26.5) sim:
  - Home + no detail, light + dark: floating island preserved,
    map shows through 8pt side gaps + outer strip.
  - Library + no detail, light + dark: bars edge-to-edge, square
    corners, uniform fill.
  - Tour detail open (any tab), light + dark: **no seam at the
    top of the mini-player**. Detail body, mini-player, and tab
    bar all render the same RGB. Bars edge-to-edge, no orange
    band, no scroll-text peek-through.

---

## TestFlight

- Build **1.0 (16)** — `CURRENT_PROJECT_VERSION` bumped 15 → 16
  in commit `6cb60fb`. `xcodebuild archive` ran cleanly; owner
  uploaded via Organizer → Distribute App → Upload at session
  end (confirmed "that's all done").

---

## Files touched this session

- **Modified:** `TRAVEL GUIDED TOUR/Theme/AtlasColors.swift` —
  hardcoded RGB in `secondaryBackground` + new
  `secondaryBackgroundUIColor` UIKit companion +
  `miniPlayerBackground` / `tabBarBackground` aliases.
- **Modified:** `TRAVEL GUIDED TOUR/Components/BottomLayerPresentation.swift`
  — detail hosting view background now points at
  `AtlasColors.secondaryBackgroundUIColor` instead of
  `.secondarySystemBackground`.
- **Modified:** `TRAVEL GUIDED TOUR/Components/AtlasTabBar.swift`
  — `extendsToScreenEdges` parameter; conditional outer/inner
  padding + clip shape + painted-vs-clear bottom strip.
- **Modified:** `TRAVEL GUIDED TOUR/Features/Player/MiniPlayerBar.swift`
  — `extendsToScreenEdges` parameter; conditional outer/inner H
  padding; background still painted by the bar itself.
- **Modified:** `TRAVEL GUIDED TOUR/Components/BottomModuleRoot.swift`
  — drops the separate edge-to-edge `Rectangle` it used to
  paint; computes `extendsToScreenEdges` from `selectedTab` +
  `presentedTour` and threads it into both bars.
- **Modified:** `TRAVEL GUIDED TOUR.xcodeproj/project.pbxproj` —
  `CURRENT_PROJECT_VERSION` 15 → 16.

No `Tours.json` changes (catalog stays at 53 tours, 3 makers, 57
stops). No test changes.

---

## Known issue carried forward

**Detail body's scroll-content slightly visible in the safe-area
strip below the tab bar in detail-up state.** When the description
fills the scroll view past the 118pt bottom inset reservation,
the very last line can poke into the 8pt outer strip + home
indicator safe area before being clipped. With the bars now
edge-to-edge in detail-up state, they OCCLUDE this area visually
(the painted yellow/dark gray covers the entire bottom 118pt),
so it doesn't read as a bug. But the underlying reservation in
`TourDetailView` is technically 8pt short of the bar's painted
footprint. Owner is doing a larger detail-sheet retool in a
separate spawn; fold in there.

---

## How to resume

1. Run the session-start ritual (`git fetch`, `git status`, `gh pr
   list`, read this handoff). Tree should be clean on `main`
   after the docs commit at end-of-session.
2. Next likely work: the tour-detail-sheet retool (Phase 1 → 2
   per the brief in `HANDOFF-260527-3.md`'s "How to resume"
   section). Or the parked polish suggestions above. Or whatever
   owner brings up.
3. TestFlight 1.0 (16) processing — check email or App Store
   Connect → TestFlight tab to confirm Apple has finished
   processing before the owner installs and tests.

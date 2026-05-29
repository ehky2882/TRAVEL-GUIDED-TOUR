# HANDOFF — 2026-05-29 (bottom-module appearance fix)

Shipped **PR #95** (`5e803e2`): the inverted bottom-module appearance bug — light fill in dark mode, dark fill in light mode — is fixed. Single bug-fix session; small, focused diff (~40 lines across 2 files).

## What was broken

The mini-player + tab bar (in a secondary higher-level `UIWindow`, `PassThroughWindow`) rendered the wrong fill whenever the Settings → Appearance picker disagreed with the system appearance. Both directions confirmed: picker=Light + sim=Dark → bars dark (wrong); picker=Dark + sim=Light → bars light (wrong).

## Root cause

SwiftUI's `.preferredColorScheme(...)` only propagates into the window owned by a `WindowGroup`. It does **not** reach a manually-created `UIWindow` hosting a `UIHostingController`. The bottom-module's secondary window was installed in `BottomModuleWindowController.install(...)` and never had its `overrideUserInterfaceStyle` set — so its `UITraitCollection.userInterfaceStyle` always tracked SYSTEM, regardless of the picker. `AtlasColors.secondaryBackgroundUIColor` (PR #91's `UIColor(dynamicProvider:)`) resolved against the wrong style on that window. Branch logic in `AtlasColors` was correct; H2's "literal trait-override pin" hypothesis was refuted by the workflow.

Diagnosed via a 4-agent workflow (3 hypothesis investigators in parallel → 1 synthesizer). H1 and H3 converged on the window-trait isolation cause with high confidence.

## Fix

Two files, ~40 lines:

- **`Components/BottomModuleWindow.swift`** — new `BottomModuleWindowController.apply(preference:)` method maps `ColorSchemePreference` to `window.overrideUserInterfaceStyle` (`.system` → `.unspecified`, `.light` → `.light`, `.dark` → `.dark`). No-op if `window == nil`.
- **`TRAVEL_GUIDED_TOURApp.swift`** — call `apply(preference:)` from `.onAppear` after `install(...)` (initial value) AND from `.onChange(of: colorSchemePreference)` (every subsequent picker toggle). Removed the `.preferredColorScheme(colorSchemePreference.colorScheme)` modifier from inside the install closure — the closure is evaluated ONCE and was freezing the host VC's `overrideUserInterfaceStyle` at install time, which shadowed the new window-level override. The window-level override is now the single source of truth for the second window's trait collection.

**Preserves PR #91's chrome-seam guarantee:** both windows now resolve `secondaryBackgroundUIColor` against the same `userInterfaceStyle`, so the boundary between the detail body (window 1) and the bars (window 2) stays seamless. The dynamic-provider mapping and hardcoded RGBs are untouched.

**Preserves the single-form rule** (`feedback-atlas-module-design.md`): no button geometry, sizing, or layout changes.

## Verification

Three (picker, system) combinations verified visually in the iPhone 17 Pro sim:

- (Light, Light) — both windows light, bars light ✅
- (Light, Dark)  — bars STAY light (was inverted before fix) ✅
- (Dark, Light)  — bars STAY dark  (was inverted before fix) ✅

`test_sim` → **84/84 pass**, no warnings.

Screenshots saved to `/tmp/atlas-fix-*.jpg` during the session.

## State of `main`

- `5e803e2` — this fix (PR #95)
- `cba0755` — detail masthead + toolbar + overflow menu (PR #93) — landed during the same date from a different session (`claude/detail-masthead-toolbar-menu`, now deleted). This session deliberately did not touch that branch.
- `96de16a` — 5 Porto-area architecture tours (PR #94, content)
- `5d0f891` — session 11 handoff + CLAUDE.md update for PR #91

TestFlight build **1.0 (17)** was cut by session 12 (build-bump commit `f359f55`) after this PR merged, so build 17 carries the fix.

## Workflow notes worth carrying forward

- **`xcrun simctl spawn ... defaults write` does not reliably propagate to a running SwiftUI `@AppStorage` value.** Even after killing the app, the next launch sometimes reads the value the app itself flushed on terminate, clobbering the simctl write. Use the actual in-app Picker UI to change `@AppStorage`-backed enums, OR (if you must script it) write defaults, then kill + relaunch and accept that it may not stick. For this session I ended up driving the picker via taps.
- **`mcp__XcodeBuildMCP__snapshot_ui` only returns the topmost window's accessibility hierarchy.** With the bottom-module window installed at `windowLevel = .normal + 1`, the main window's Settings list and Picker are invisible to `snapshot_ui`. Use `axe describe-ui` directly (bundled at `~/.npm/_npx/.../xcodebuildmcp/bundled/axe`) — it returns the full app hierarchy including the main window's `PopUpButton` with exact `AXFrame` coordinates. Saved me from tap-coordinate guessing.
- **The diagnostic workflow harness was a big win here.** 3 parallel hypothesis investigators each read the same files independently and reached structured findings via a JSON Schema; the synthesizer compared their verdicts and picked the convergent root cause. Total wall time ~3.5 min, output high-confidence, with concrete proposed code edits. Reach for this pattern whenever a bug has several plausible mechanisms and the cost of guessing wrong (touching working code) is high.

## What's queued / not done this session

Still parked from session 11 (PR #91 handoff): mini-player title type style; control glyph size alignment; avatar/play-ring balance.

Still parked from session 12 (PR #93): owner feedback round 2+ on detail masthead/toolbar/menu, if any.

Owner-facing chrome-shade-mismatch polish is now fully complete: seam closed (PR #91) + appearance-tracking fixed (PR #95). No known bottom-module visual bugs remain.

Build 17 ships this fix (see middle of doc) — no further build-bump needed for it.

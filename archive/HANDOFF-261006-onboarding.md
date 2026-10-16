# Handoff — first-run onboarding + navigation guides (2026-10-06)

**For:** a LOCAL (Mac) Claude Code session, so the owner can iterate in the iOS Simulator
instead of waiting on a TestFlight build per round. Hand-written by the web session that built
it (claude.ai/code/session_01WBJyk1a9LSbKmPHH2S6ky9).

🔴 **Re-derive live state, never quote this file:** `bash scripts/session-start.sh`, then
`git fetch && git log --oneline origin/main..origin/claude/eloquent-knuth-uutk4y`.

---

## Start here (local session)

```bash
git fetch origin
git checkout claude/eloquent-knuth-uutk4y
git pull --ff-only origin claude/eloquent-knuth-uutk4y
```

Then XcodeBuildMCP: `session_show_defaults` → `build_run_sim`.

**To see onboarding again in the Simulator** it must be a first launch. Either erase the app
(long-press → Remove App, or `xcrun simctl uninstall booted com.ehky.TRAVEL-GUIDED-TOUR`), or
Settings → HELP → **Take the app tour** (skips the account screens) / **Show tips again**
(the five guides only). The state lives in `UserDefaults` key `onboarding.state`.
`-UITestSkipOnboarding` suppresses it (used by `ScreenshotUITests`).

## Where it stands

| | |
|---|---|
| PR | https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1093 — **open, NOT merged**, CI green, merges cleanly (main was ~48 commits ahead on 2026-10-06; merge `main` in before merging if it has moved) |
| Branch | `claude/eloquent-knuth-uutk4y` (head `a5b4c25` on 2026-10-06) |
| TestFlight | **182** (2026-10-06) is the latest — everything below is in it. 179/180/181 are earlier rounds |
| App Store | 1.1.3, no onboarding. `MARKETING_VERSION` is 1.1.4 on main and the branch |
| Owner instruction | 🔴 **Code PR → merge only on the owner's explicit "merge"**, after they've seen it on device/simulator. Don't trigger TestFlight unless they ask |

## What was built

**Onboarding — screens 2–18** (`TRAVEL GUIDED TOUR/Features/Onboarding/`)
- `OnboardingFlow.swift` — `OnboardingStep` (2 faceAppears … 18 questionMakerIntent);
  `progressBarSteps` = 3…18; `steps(replaying:)` drops 4/5/6 (account screens) on replay.
- `OnboardingStore.swift` — Codable `OnboardingState` in UserDefaults `onboarding.state`
  (completedVersion, firstName, lastName, homeCity, uses, formats, interests, listUses,
  makerIntent, seenCoachMarks). Plain class — **not** observable (see the 182 fix).
- `OnboardingCoordinator.swift` — `@Observable`. `willPresentWelcome` (resolved once in App
  init), `isCovering`, `holdsBottomModule`, **stored `state` mirror** re-synced by every
  `update`/`finish`/`resetCoachMarks`, `canGoBack`/`back()`, `onFinish` (synchronous hand-off
  to the guides).
- `OnboardingRootView.swift` — all cards; swipe-right + VoiceOver escape go back.
- `OnboardingChrome.swift` — `OnboardingScaffold` (progress bar, back chevron overlay, fixed
  42pt face, copy centred in a band, CTA pinned), `OnboardingProgressBar`, buttons, wordmark.
- `OnboardingControls.swift` — option rows, chips (29pt tall, 6pt gaps), `ChipFlowLayout`.
- `DozentFace.swift` — brass disc, expressions rest/beam/wink/wow; **mouth must never frown**.

**The five navigation guides** (`Features/Onboarding/CoachMarks/`): map · search bar · filters
· drawer · tab bar, over the LIVE Home, right after "Start exploring".
- Drawn in the **bottom-module window** (`Components/BottomModuleRoot.swift`), because that
  window sits above the main one. While running, `PassThroughWindow.claimsEntireScreen` takes
  every touch — **derived** from `CoachMarkCenter.isRunning` in
  `TRAVEL_GUIDED_TOURApp.syncBottomModuleVisibility()`, never latched.
- Anchors: `.coachMarkAnchor(_:)` on SearchBar / FilterChipRow (`HomeView`), the drawer
  (`ContentView`), and the bar module (`BottomModuleRoot`).
- Location permission is requested only after the guides end.

**Spec:** "No onboarding tutorial" was removed from Out of Scope in `CLAUDE.md` and
`atlas_claude_code_prompt.md` in this PR.

## Owner decisions to keep (from the canvas + device rounds)

- One type style: `AtlasTypography.caption` everywhere; hierarchy by spacing.
- Face same size/place from screen 3 on; titles/subtitles centred; copy centred between face and
  button; controls left-aligned inside themselves.
- Progress bar: Reels-style, **plain white (primaryText)**, one full segment per screen shown in
  this run (a replay's bar is shorter). No half segments, no brass.
- Screen 14 avatars: the maker's real photo via `MakerAvatarView` when it has one (an Atlas
  studio's emoji counts; a pinned creator's 🎵/📷 does not) — otherwise brass initials.
- Guides: dozent stands outside the bubble; no step counting; no "Skip all"; Next … Got it;
  tap anywhere advances; map stop has no cut-out.
- Back navigation (owner, build 181): chevron top-left + swipe right; never back onto screen 2.

## Bugs found on device, and why (don't reintroduce)

| Build | Symptom | Cause / fix |
|---|---|---|
| 179 | Stuck on first card; bars on top | Bars' UIWindow paints over everything → `holdsBottomModule` in the derived visibility rule |
| 180 | Frowning face | Arc dip sign → positive dip = smile |
| 180 | Half-filled progress segment | Per-run segment count, full segments only |
| 181 | **Rows/chips don't select** | Answers saved but never redrawn: coordinator read `state` *through* the non-observable store. Now a stored, observed mirror. Test: `testAnsweringAQuestionNotifiesTheScreenReadingIt` |
| 181 | Last chip hidden under Continue | Chips 31→29pt, gaps 7→6 |

## Open / next

1. **Owner is testing build 182** — collect notes, iterate in the Simulator.
2. Highest-risk item to watch: after "Got it", **every tap on Home must work** (the full-screen
   touch claim must release).
3. Not built yet (deliberately): account screens don't create an account (AuthService wiring);
   screen 14's six makers are a fixed list (ranking rule undecided); answers are stored but don't
   reorder Home yet (personalization phase 2); `caption` is a hard 13pt (Dynamic Type follow-up).
4. On merge: squash-merge #1093 only on the owner's "merge", then write the next handoff.

Design history (every canvas round and decision) is in the web session's plan; the canvas
artifact was the owner's review surface. Tests: `TRAVEL GUIDED TOURTests/OnboardingTests.swift`.

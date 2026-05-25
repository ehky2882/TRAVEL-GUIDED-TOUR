# archive/

Snapshots of working docs from earlier in the project. Naming
convention: `<original-name>-YYMMDD.md`, where the date is the day
the snapshot was archived (or the day it represents, for handoffs).

**Reading rule.** Most files here are historical — not read at
session start; anything still relevant to current work belongs in
`CLAUDE.md` or `ROADMAP.md`. **Exception: the most recent
`HANDOFF-YYMMDD.md` is part of the session-start ritual** (see
`CLAUDE.md` § "Session-start ritual"). It bridges the gap between
durable project rules and the specific mid-flight state from the
prior session — queued user feedback, what was about to be tackled,
tribal knowledge not yet promoted.

| File | Purpose | Date |
|---|---|---|
| `ACCOUNT-TRANSFER-260520.md` | **One-time orientation doc for the successor Claude on a different account.** Covers project overview, recommended reading order, state at transfer (code / content / TestFlight / Apple Developer), what's queued, working-style notes about the owner, and tribal knowledge worth carrying forward. Read once at the first session under the new account. | 2026-05-20 |
| `HANDOFF-260525.md` | **Active handoff.** Session 2026-05-25: shipped PR #66 (`2452f52`), extending PR #60's bottom-module geometry to the rest of the app. New `AtlasBottomModule.height(extendsToScreenEdges:)` helper + `\.atlasIsHomeTab` env value + `extendsToScreenEdges` flag on `MiniPlayerBar` / `AtlasTabBar`. Non-Home tabs (Library / Settings / Manage downloads / Tour Detail / Maker) now show the module flush to the screen edges; their scrollable content reserves bottom space via `.safeAreaInset(.bottom)`. TourDetailView's `actionBarHeight` + trailing spacer rebuilt around the helper — also fixes a pre-existing too-small 72pt spacer. Auto-merge policy changed this session (commit `b06284b`): all PRs auto-merge on CI green now, code included. 84/84 tests pass. | 2026-05-25 |
| `HANDOFF-260524-3.md` | Late-evening session 2026-05-24: shipped PR #60 (home polish bundle + player-state hardening, `e5b31da`). Visual-review pass against the running build surfaced three audio-state bugs the original polish scope didn't cover — added to the same PR: Open-player no longer disabled mid-load, `AudioPlayerService.seek(to:)` synthesizes `.ended` on scrub-to-end (AVPlayer doesn't fire `didPlayToEndTime` on manual seek), full-player `togglePlayPause` now replays on `.ended` via new `replayCurrent()`. 84/84 tests pass. TestFlight 1.0 (7) still queued for owner Archive/Upload. Superseded by the 260525 handoff above. | 2026-05-24 |
| `HANDOFF-260524-2.md` | Afternoon/evening Mac session 2026-05-24: shipped PR #61 (mini-player end-of-tour state fix — kills the post-tour "Loading…" flicker, adds in-place replay via new `AudioPlayerService.replayLast()`). Sibling session pushed `5db7aaa` to `claude/home-visual-polish-bundle` (drawer-stacking + sizing + tours-in-view iteration) — branch is on origin but not PR'd yet at session end. Superseded by the `-3` handoff above. | 2026-05-24 |
| `HANDOFF-260524.md` | Mac session 2026-05-23/24 morning: populated `heroImageURL` for all 38 tours via CC-licensed Wikimedia Commons photos (landscape-optimised batch), bumped build number to 7, opened Xcode for TestFlight upload. Superseded by the `-2` / `-3` handoffs above. | 2026-05-24 |
| `HANDOFF-260522.md` | Mac session 2026-05-21 evening → 2026-05-22: picked up remote PR #54, fixed CI, simulator UX-polish batch, 9 new tours (catalog 20), merged PR #54, uploaded **TestFlight build 1.0 (5)**. Historical. | 2026-05-22 |
| `HANDOFF-260521.md` | Short handoff from a parallel 2026-05-21 remote session, written just after PR #54 merged (build 5 bumped but not yet uploaded). Superseded by the 260522 handoff, which covers the same ground through the build 5 upload. Historical. | 2026-05-21 |
| `HANDOFF-260520.md` | Consolidated end-of-day snapshot for 2026-05-20, covering both that day's sessions: (1) morning remote session — Times Square images, P1/P2/P3 audit cleanup, download retry, Option A data layer (landed on `main` via PR #51); (2) evening Mac session — home-screen UX batch, location-button rework, PlayerView carousel, MakerView fixes, ESB GPS fix, and the **TestFlight build 1.0 (4) upload**. Historical — superseded by the 5/22 handoff. | 2026-05-20 |
| `HANDOFF-260519.md` | Consolidated end-of-day snapshot from 2026-05-19. Covers both that day's sessions: (1) morning remote session — TestFlight prep code work + 8 new real tours + ROADMAP expansions; (2) evening local Mac session — Xcode signing setup + first Archive + Upload to App Store Connect (build 1.0/1 uploaded at 9:38 PM, awaiting Apple processing). Its "Tomorrow's queue" — complete TestFlight setup → install on iPhone → run M-qa checklist — is still the live TestFlight plan; read alongside the 5/20 handoff. The morning-only version of this file is preserved in `git log -- archive/HANDOFF-260519.md`. | 2026-05-19 |
| `HANDOFF-260518.md` | End-of-day snapshot from the 2026-05-18 session. Historical — superseded by the 5/19 handoff. Kept for context on what shipped that day (AllTrails-style home, unit test target wiring, session-start ritual, P0 audit closure). | 2026-05-18 |
| `pre-qa-audit-260518.md` | Pre-QA code self-audit (22 findings, P0–P3). Produced under PR #21; most P0 + 2 P1 findings closed by PRs #22 / #23 / #24. Remaining findings tracked as live checklist in `ROADMAP.md` § M-qa. | 2026-05-18 |

When the next handoff is written, name it for the new date
(`HANDOFF-YYMMDD.md`) and update the entry above to point to the
latest one as the "Active handoff." Older handoffs stay as
historical entries, but only the latest is part of the session-start
ritual.

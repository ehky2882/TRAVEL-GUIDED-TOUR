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
| `HANDOFF-260522.md` | **Active handoff.** Local Mac session 2026-05-21 evening → 2026-05-22: picked up the remote session's PR #54, fixed its CI (switched to the `macos-26` runner), ran an extended simulator review producing a UX-polish batch, added 9 new tours (catalog now 20), merged PR #54, and uploaded **TestFlight build 1.0 (5)**. Its "Start here next session" queue — M-qa on device against build 5 — is the live plan. | 2026-05-22 |
| `HANDOFF-260520.md` | Consolidated end-of-day snapshot for 2026-05-20, covering both that day's sessions: (1) morning remote session — Times Square images, P1/P2/P3 audit cleanup, download retry, Option A data layer (landed on `main` via PR #51); (2) evening Mac session — home-screen UX batch, location-button rework, PlayerView carousel, MakerView fixes, ESB GPS fix, and the **TestFlight build 1.0 (4) upload**. Historical — superseded by the 5/22 handoff. | 2026-05-20 |
| `HANDOFF-260519.md` | Consolidated end-of-day snapshot from 2026-05-19. Covers both that day's sessions: (1) morning remote session — TestFlight prep code work + 8 new real tours + ROADMAP expansions; (2) evening local Mac session — Xcode signing setup + first Archive + Upload to App Store Connect (build 1.0/1 uploaded at 9:38 PM, awaiting Apple processing). Its "Tomorrow's queue" — complete TestFlight setup → install on iPhone → run M-qa checklist — is still the live TestFlight plan; read alongside the 5/20 handoff. The morning-only version of this file is preserved in `git log -- archive/HANDOFF-260519.md`. | 2026-05-19 |
| `HANDOFF-260518.md` | End-of-day snapshot from the 2026-05-18 session. Historical — superseded by the 5/19 handoff. Kept for context on what shipped that day (AllTrails-style home, unit test target wiring, session-start ritual, P0 audit closure). | 2026-05-18 |
| `pre-qa-audit-260518.md` | Pre-QA code self-audit (22 findings, P0–P3). Produced under PR #21; most P0 + 2 P1 findings closed by PRs #22 / #23 / #24. Remaining findings tracked as live checklist in `ROADMAP.md` § M-qa. | 2026-05-18 |

When the next handoff is written, name it for the new date
(`HANDOFF-YYMMDD.md`) and update the entry above to point to the
latest one as the "Active handoff." Older handoffs stay as
historical entries, but only the latest is part of the session-start
ritual.

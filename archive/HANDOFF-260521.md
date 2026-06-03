# Session Handoff — 2026-05-21 (Remote session, end-of-day)

## Status: PR #54 merged ✅ — ready for TestFlight build 5

Everything that was in flight is resolved. No outstanding blockers.

---

## What shipped today (PR #54, merged 2026-05-21)

- **Mini-player** (`MiniPlayerBar.swift`) — persistent bar above the tab bar
  while audio is loaded; inline pause/resume, tap to reopen full player
- **Drawer peek-height fix** — peek grows to clear the mini-player
- **Smooth recenter animation** + gentler button fade on map pan
- **Compass heading wedge** on the user-location dot
- **10 new tours** — catalog now has 20 total (target of 5–15 exceeded)
- **CI runner fix** — build + test jobs now use `macos-26` runner (Xcode 26,
  iOS 26 SDK), resolving the deployment-target mismatch that was breaking CI

## What still needs a Mac session

**Priority 1 — TestFlight build 5 upload (~10 min active)**

Build number is already bumped to 5 in `project.pbxproj` on `main`.
Archive and upload via Xcode Organizer. See `docs/testflight.md` for the runbook.
All the M-qa fixes from this session will reach testers' devices after this upload.

**Priority 2 — Multi-stop tour for M-qa**

The M-qa checklist still needs a multi-stop walking tour to verify
geofence triggering and audio queue behaviour between stops.
None of the 20 current tours have more than one stop.

**Priority 3 — Design / polish pass**

Deferred; no blocker. See `ROADMAP.md` § M-polish.

---

## Owner note

The owner does not use Terminal directly — Claude handles all shell/git work.
When starting a new Claude Code session, just say "continue from where we left
off" and Claude will read this file + `CLAUDE.md` + `ROADMAP.md` for context.

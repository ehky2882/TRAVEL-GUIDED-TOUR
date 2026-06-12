# HANDOFF — 2026-06-11 (session 33, web/PM)

## TL;DR

TestFlight **1.0 (40)** cut and shipped. Build bumped **39 → 40 direct-to-main**
(`0cf79b3`, app-target `CURRENT_PROJECT_VERSION` lines only; test target stays 1;
`MARKETING_VERSION` stays 1.0). `xcodebuild archive` clean at
`/tmp/Atlas-20260611-1900.xcarchive` (~3 min); embedded version verified
`1.0 (40)`; **no validation 90474** — `UIRequiresFullScreen=YES` from build 34
held. Owner uploaded via Organizer. **TestFlight 1.0 (40) is live.**

## What this build carries

Content + images only — **no Swift / asset / project-structure change** beyond the
pbxproj bump.

- **PR #192 — London batch 1:** 15 West End / Soho tours (theatre district,
  shopping, Soho landmarks), under Atlas Studio LDN.

**London 25 → 40** — West End / Soho now covered, on top of the City +
Westminster/Whitehall that shipped in build 39 (`ea197f0`). **Catalog 210 → 225
tours / 4 makers** (100 Atlas Studio NYC + 54 OPO + 40 LDN + 31 LIS).

## Process notes

- Primary worktree used (`/Users/EY/TRAVEL-GUIDED-TOUR`); no checkout conflict, so
  the `/tmp/build40` fallback was not needed.
- Archive command run per `docs/testflight.md` § "Archive command" (Release config,
  `generic/platform=iOS`, `-allowProvisioningUpdates`). DerivedData warm → ~3 min.
- Embedded version + `UIRequiresFullScreen` spot-checked on the built `.app` before
  opening Organizer.

## State at session end

- **Latest TestFlight build: 1.0 (40)** — live 2026-06-11.
- **Note:** an active content session may have open `claude/dreamy-wozniak-*`
  branches (more London in flight) — not touched this session. The next cut should
  bundle whatever lands on `main` after `0cf79b3`.

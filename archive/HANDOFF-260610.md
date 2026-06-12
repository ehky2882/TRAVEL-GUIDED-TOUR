# HANDOFF — 2026-06-10 (session 32, web/PM)

> Backfilled 2026-06-11 from git history (`ea197f0`) — this build shipped but the
> session-end docs were not written at the time.

## TL;DR

TestFlight **1.0 (39)** cut and shipped. Build bumped **38 → 39 direct-to-main**
(`ea197f0`, app-target `CURRENT_PROJECT_VERSION` lines only; test target stays 1;
`MARKETING_VERSION` stays 1.0). Owner uploaded via Organizer. **TestFlight 1.0 (39)
is live.**

## What this build carries

Content + images only — **no Swift / asset / project-structure change** beyond the
pbxproj bump.

- **PR #191 (`56f7a30`) — Lisbon expansion:** 26 Lisbon tours (Belém, Jerónimos,
  Castelo de São Jorge, Tram 28, and more), under Atlas Studio LIS.

**Lisbon 5 → 31** — Atlas Studio LIS's first large batch. **Catalog 184 → 210
tours / 4 makers** (100 Atlas Studio NYC + 54 OPO + 25 LDN + 31 LIS). London
unchanged at 25 this build.

## Caveat for the record

The build-39 bump commit message reads **"26 Lisbon + 19 London tours"**, but git
shows only the 26 Lisbon tours (`56f7a30`, PR #191) as new content between the
build-38 bump (`cf00495`) and the build-39 bump (`ea197f0`). The "19 London" tours
referenced (City batches + Westminster/Whitehall, sessions 29–30) had **already
shipped in build 38** — they were double-counted in the message. Build 39's actual
new content is the 26 Lisbon tours only. Catalog math confirms: 184 + 26 = 210, LDN
stays 25.

## State at session end

- **Latest TestFlight build: 1.0 (39)** — live 2026-06-10. (Superseded by 1.0 (40)
  on 2026-06-11 — see `HANDOFF-260611.md`.)

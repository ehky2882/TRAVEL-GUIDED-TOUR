# HANDOFF — session 42 (2026-06-23, web/PM — docs sync)

**Session-end snapshot.** Owner-requested documentation sync: the shared
`CLAUDE.md` / `ROADMAP.md` had drifted behind the catalog (they read ~307
tours / 4 makers in places), so this session refreshed the Current State
sections to reality. **Docs only — no app code, no `Tours.json`, no images,
no build bump.** Auto-merge class.

## Verified catalog state (live-checked against `Resources/Tours.json`)

- **362 tours · 5 makers · 381 stops · 4 multi-stop.**
- Per maker / city: **NYC 100 · London (LDN) 97 · Lisbon (LIS) 66 · Porto
  (OPO) 54 · Hong Kong (HKG) 45.** Five cities.
- **Hong Kong is the 5th maker and newest city** — built 0 → 45 over a few
  days (PRs #226–#234), an Asian flagship.
- **All 45 Hong Kong tours are bilingual** — `English | 中文` title format on
  both tour and stop titles (45/45 verified).
- **4 multi-stop tours:** American Museum of Natural History: Four Facades
  (5 stops, NYC), Fifth Avenue Walk (6, NYC), After the Fire: Wren's City
  (6, London), Albertopolis (6, London). The two London walks were wired +
  gallery-fixed during the recent growth (PRs #232/#233). **3 more London
  multi-stop walks are drafted** on `claude/london-batch3-scripts-260616`,
  awaiting wiring.
- Build: `CURRENT_PROJECT_VERSION = 46` (app target), `MARKETING_VERSION =
  1.0`. **TestFlight 1.0 (46) is current.**

## The number that mattered: prompt said 307/4, repo says 362/5

The drift was exactly what the task flagged — the docs' authoritative
"current numbers" line still read **307 tours / 5 makers / 316 stops**
(100 NYC + 80 LDN + 66 LIS + 54 OPO + 7 HKG) from session 41. The repo is
now **362 / 5 / 381** (100 / 97 / 66 / 54 / 45). London grew 80 → 97 and
Hong Kong 7 → 45 since that snapshot. No discrepancy between this prompt's
target numbers and the repo — both say 362/5; the repo confirms them.

## Remote-catalog era (the durable workflow fact, re-stated in both docs)

Since **build 46**, content ships with **no app build**:
- PR #209 — the app fetches `Tours.json` from gh-pages at launch (bundled
  copy = offline seed) via `RemoteCatalogLoader`.
- PR #212 — `.github/workflows/publish-catalog.yml` auto-publishes
  `Tours.json` → gh-pages on every content merge to `main`.
- **Net:** merge a content PR → live to build-46+ users with no rebuild and
  no App Store review. Realistic latency ≈ **~5 min after merge + an app
  relaunch** (~1–2 min publish + GitHub Pages CDN propagation; the app shows
  its cached catalog first, then refreshes in the background — sometimes a
  second relaunch). 1.0 (46) is the **last content-driven build**; build
  bumps are now only for actual app-code changes (still via the
  short-lived-PR pattern — the classifier blocks direct-to-main pbxproj
  pushes).

## In flight / on the horizon

- **Paris** drafted as the 6th city (`claude/paris-scripts-260622`).
- **V2 creator-platform** groundwork continues across design/code branches:
  `backend-foundation`, `accounts-design`, `moderation-design`,
  `maker-dashboard-design`, `maker-phase2-design`, `v2-roadmap`. See
  `archive/HANDOFF-260621.md` + `ROADMAP.md § V2 — execution plan` for the
  full design state (Supabase backend; nothing ships in the app yet).
- **Carried-over TODO (deferred by owner 2026-06-21):** 2 dead gallery
  images — The Oculus + The Charging Bull (Wikimedia 404s) — remove the
  entries or re-source via the image pipeline.

## What this session changed

- `CLAUDE.md` — new top Current State block (session 42); header date
  2026-06-21 → 2026-06-23; the authoritative "Key facts" numbers line
  307/5/316 → 362/5/381 with the new per-maker split, the 4 multi-stop
  tours, and the bilingual-HK note.
- `ROADMAP.md` — new top "Where we are right now" status block (session 42).
- `archive/HANDOFF-260623.md` (this file) + `archive/README.md` row.

Historical dated blocks in both docs were left intact (they're the project
log — the refresh is in-place at the top, not a restructure).

## Process notes

- Ran in a dedicated worktree `git worktree add /tmp/docsync origin/main`
  (detached) — the primary checkout was on `claude/maker-tour-sort` with
  another session's uncommitted Swift changes; left untouched.
- Re-verify `git branch --show-current` before each commit; `git pull
  --ff-only origin main` immediately before the final push.

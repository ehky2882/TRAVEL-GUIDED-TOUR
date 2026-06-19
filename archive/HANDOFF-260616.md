# HANDOFF — 2026-06-16 (session 39, local build cut — build 45, catalog crosses 300)

## TL;DR

**TestFlight 1.0 (45) cut, archived, and live.** Build cut to ship
everything on `main` since build 44 (`7f675a3`): **PR #205** (6 Lisbon
tours — Conserveira de Lisboa, Dolls Hospital, Oceanário de Lisboa,
Palace Fronteira, Ponte 25 de Abril, Vasco da Gama Bridge; LIS 60 → 66)
and **PR #206** (22 London tours wired into Tours.json; LDN 58 → 80).
Content + images only — **no app-code change since build 44** (the
compass fix #204 and placecard polish #201 already shipped in 44).
**🎉 Catalog crosses 300 tours: 300 / 4 makers** (100 NYC + 80 LDN +
66 LIS + 54 OPO). London is now firmly the #2 city.

## What happened

1. **Confirmed state** — `main` clean at `14bd8dc`; pbxproj at build 44
   (app-target lines; test target 1; `MARKETING_VERSION` 1.0).
2. **Worktree** — `git worktree add -b claude/build-45-bump /tmp/build45 main`.
   Plain `git worktree add /tmp/build45 main` **fails** (`'main' is
   already used by worktree at /Users/EY/TRAVEL-GUIDED-TOUR`) — the
   `-b <branch>` form creates the branch off `main` in the new worktree
   and sidesteps the collision. Edited the two app-target
   `CURRENT_PROJECT_VERSION` lines 44 → 45 via a `replace_all` on
   `CURRENT_PROJECT_VERSION = 44;` (the two `= 1;` test-target lines are
   left untouched). Clean diff: 2 insertions, 2 deletions.
3. **PR #207** — `chore(build): bump CURRENT_PROJECT_VERSION 44 → 45 for
   TestFlight`. CI fully green (Build · Validate Tours.json · Run unit
   tests — unit tests ~7m32s, the slow leg). Squash-merged `acc05b4`.
4. **Merge/cleanup snag (recurring — 3rd time, see sessions 36–38).**
   `gh pr merge 207 --squash --delete-branch` exited 1 with
   `failed to run git: fatal: 'main' is already used by worktree …` —
   but `gh pr view 207` confirmed `state: MERGED` (`acc05b4`), i.e. the
   squash **landed server-side**; only `gh`'s local post-merge checkout
   step failed. Recovery: `git push origin --delete claude/build-45-bump`
   (succeeded), then **archive from the primary checkout** (already on
   `main`): `git pull --ff-only origin main` → pbxproj now shows 45.
   The `/tmp/build45` worktree could **not** switch to `main` (it's held
   by the primary), so don't try to ff-pull inside the worktree — just
   archive from the primary and `git worktree remove /tmp/build45 --force`.
5. **Archive** — ran from `/Users/EY/TRAVEL-GUIDED-TOUR` (primary, on
   `main`): `xcodebuild archive -project "TRAVEL GUIDED TOUR.xcodeproj"
   -scheme "TRAVEL GUIDED TOUR" -configuration Release -destination
   "generic/platform=iOS" -archivePath /tmp/Atlas-20260616-2045-b45.xcarchive
   -allowProvisioningUpdates`. **ARCHIVE SUCCEEDED in ~23s** (warm
   DerivedData). Embedded `CFBundleShortVersionString=1.0`,
   `CFBundleVersion=45`, `UIRequiresFullScreen=true` (the build-34 90474
   guard held — no validation error). Opened in Organizer.
6. **Owner uploaded via Organizer → Distribute App → Upload.**
   **TestFlight 1.0 (45) is live.**
7. **Docs sync (this session 39 close-out)** — CLAUDE.md Current State +
   ROADMAP status + this handoff + archive/README pointer, via a
   `/tmp/docs45` worktree → docs-sync PR.

## Catalog

**272 → 300 tours / 4 makers** (100 Atlas Studio NYC + **80 LDN** +
**66 LIS** + 54 OPO). Build 45 expands both London (58 → 80, +22 via
#206) and Lisbon (60 → 66, +6 via #205). The 6 Lisbon adds include both
Tagus bridges (Ponte 25 de Abril + Vasco da Gama), the Oceanário,
Palácio Fronteira, Conserveira de Lisboa, and the Dolls Hospital.

## Tribal knowledge reconfirmed

- **Worktree off main, the right way:** `git worktree add -b <branch>
  /tmp/<dir> main`. The branch-less form collides with the primary's
  `main` checkout.
- **The `gh pr merge --delete-branch` worktree error is benign** — the
  squash lands server-side first; verify with `gh pr view <n> --json
  state,mergeCommit` before reacting. Recover with a manual remote-branch
  delete + ff-pull in the primary, then archive from the primary (not
  the soon-removed worktree).
- **Build-bump-via-PR is still required** — the auto-mode classifier
  blocks direct-to-main pbxproj bump pushes (precedents #199/#202/#207).
- **90474 stays quiet** — `UIRequiresFullScreen=YES` (build 34) keeps the
  iPad-orientation validation passing; no recurrence.

## State at session end

- `main` at `acc05b4` (build 45); pbxproj `1.0 (45)`, test target 1.
- TestFlight **1.0 (45) live** (2026-06-16).
- Worktrees: primary (`main`) + `/tmp/ghpages` (gh-pages). `/tmp/build45`
  removed. The docs-sync worktree (`/tmp/docs45`) is removed after its
  PR merges.
- **`claude/dreamy-wozniak-tags-260612` untouched** — unmerged
  tag-taxonomy proposal awaiting owner review.
- **Standing TODO unchanged:** upload automation (App Store Connect API
  key) — owner still does the Organizer upload manually.

## Next

- Nothing queued. Next content batch or the next build cut, whichever the
  owner asks for.

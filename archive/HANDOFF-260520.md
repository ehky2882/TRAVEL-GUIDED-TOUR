# Atlas — Handoff Notes (2026-05-20, resume-after-error session)

Single short remote session on 2026-05-20 from the web, picking up
after the prior session errored mid-task. No Mac involved this
session. Read in order at start of next session.

> **Why a short handoff:** the user came in with one in-flight task
> (uploading 3 Times Square images) and one housekeeping question
> (stale branches). Both got resolved; M-qa on real device is still
> waiting on the user being back at their Mac + iPhone. The 5/19
> handoff's "tomorrow's queue" still applies — this file layers on
> top of it.

---

## What shipped today

### 1. Times Square hero + 2 carousel images — partially shipped

The hero image carousel work that was "Option A, locked but
deferred" in `HANDOFF-260519.md`. Triggered by the user uploading
3 real photos for the Times Square tour. Shipped in two pushes:

- **`gh-pages` ← commit `0d8df6f`** — 3 JPEGs added under
  `images/`, first photographic content alongside `audio/`. Live at
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/times-square-from-tkts-{hero,2,3}.jpg`.
- **`claude/resume-after-error-WQGK6` ← commit `e0d098a`** —
  data half of Option A:
  - `Tour.swift` gains optional `additionalImageURLs: [String]?`
  - `scripts/validate-tours.swift` mirrors the field + per-URL
    validation
  - `Resources/Tours.json` Times Square entry now uses real
    `heroImageURL` (placeholder gone) + populated
    `additionalImageURLs`
  - `docs/Tours.template.json` + `docs/authoring-tours.md` document
    the new field for authors
  - `TestFixtures.swift` + `ToursDataDecodingTests.swift` cover the
    additive shape (missing → nil, present → array)
  - `ROADMAP.md` Known follow-ups gains the "remaining UI work" entry

**This is a code PR — not auto-mergeable under CLAUDE.md's rule.**
Needs owner sign-off before merging to `main`. The branch is
ready to open a PR from.

### 2. Stale remote branch cleanup — noted, not executed

13 merged `claude/*` feature branches still on `origin` from PRs
#36–#47 and #50, all squash-merged with no unmerged work. **Safe
to delete.** Container's GitHub token returns HTTP 403 on remote
branch deletes, so this is a Mac-side task. Captured in `ROADMAP.md`
§ Known follow-ups with re-derivation instructions.

(Also captured in `claude/resume-after-error-WQGK6` ← commit
`0ce95bd` — the first commit on the branch.)

---

## Tomorrow's queue (in order, when back at the Mac)

### 1. Carry over from 2026-05-19 — still the live plan

The 5/19 handoff's `## Tomorrow's queue` is the primary list:

1. Check Apple email — `1.0 (1)` should be done processing by now.
2. App Store Connect → TestFlight → paste "What to Test" notes
   (draft text is in `HANDOFF-260519.md` § Tomorrow's queue #2).
3. Install via TestFlight app on iPhone.
4. Run **M-qa 10-step checklist** on real device
   (`ROADMAP.md` § M-qa).
5. End of session: write `HANDOFF-260521.md`, update
   `archive/README.md`.

### 2. Review and merge the in-flight branch from today

Branch: `claude/resume-after-error-WQGK6`
Commits ahead of main: 3
- `0ce95bd` — ROADMAP note about stale branches
- `e0d098a` — Times Square images + Option A data layer
- (plus this handoff)

What to do:
- Open it in Xcode on the Mac, verify it builds and the Times Square
  tour's hero image renders from the real gh-pages URL (not the
  placeholder anymore).
- Pull and run `swift scripts/validate-tours.swift` — CI runs it on
  Linux per PR, but a local run on Mac catches any Linux/macOS Swift
  drift.
- Run unit tests via Cmd-U; the new
  `test_decodesAdditionalImageURLs_whenPresent` should pass alongside
  the existing decoding tests.
- Open a PR from the branch. Squash-merge once green.

### 3. Build the carousel UI (the remaining half of Option A)

ROADMAP § Known follow-ups has the full pointer. Quick recap:
- The 2 extra Times Square images are on `gh-pages` and referenced
  in `Tours.json`, but `TourDetailView` only renders `heroImageURL`.
  Until the carousel UI ships, those 2 photos are unreachable in the
  app.
- Approach: replace the single `HeroImageView` in
  `TourDetailView.swift` (line ~35) with a `TabView` using
  `.tabViewStyle(.page)` over `[heroImageURL] + (additionalImageURLs ?? [])`.
- ~30–40 min of SwiftUI; want to verify visually in the simulator
  with a multi-image tour (Times Square is the only one for now).
- Separate, focused PR. Don't bundle with anything else.

### 4. Clean up stale remote branches

Once at a Mac with `gh` or git auth, run the delete list from
`ROADMAP.md` § Known follow-ups. ~30s of work.

---

## Tribal knowledge from this session

- **Inline images in chat → base64 in session log**, not files on
  disk. To upload images the user pasted into chat in a
  remote-execution session, look in
  `/root/.claude/projects/<project>/<session-id>.jsonl` for `user`
  messages with `content[].type == "image"` whose `source.data` is
  the base64 JPEG. The Python decode pattern is in this session's
  transcript at line ~108.
- **gh-pages pushes work** from the remote-execution container
  *if you operate in the main checkout* — `git checkout gh-pages`
  → commit → push → switch back. **Worktrees don't work** because
  the harness's commit-signing service errors with "missing source"
  outside the assigned project path. Tried `git worktree add` first;
  had to fall back to switching branches in place.
- **Outbound HTTP is restricted in the container.** Curling the
  gh-pages URLs to verify they went live returns
  `403 Host not in allowlist` even for known-working production
  URLs. Not a deploy failure — just verify from a real browser.
- **Container's GitHub token can't delete remote branches.** HTTP
  403 on `git push origin --delete`. Branch deletion is a Mac-side
  or GitHub-web-UI task.

---

## Where we are right now

`main`: still at `e74949e` (PR #50, "docs/testflight: add Inviting
external testers section"). Nothing landed on `main` today.

In-flight branch: `claude/resume-after-error-WQGK6`, 3 commits
ahead of `main`. Ready to PR.

`gh-pages`: at `0d8df6f`, now has `images/` directory with 3 Times
Square photos plus the unchanged `audio/` directory.

TestFlight build `1.0 (1)` from 2026-05-19 — processing status
unknown (no email checking happened this session).

---

## How to resume from a fresh Mac session

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"
git fetch
git checkout main
git pull --ff-only
git checkout claude/resume-after-error-WQGK6   # review today's work
git log main..HEAD --oneline                   # should show 3 commits
```

Read in this order:

1. `CLAUDE.md` § Current State + § Session-start ritual
2. `ROADMAP.md` § "Where we are right now" + § M-qa + § Known follow-ups
3. **This file** (`archive/HANDOFF-260520.md`)
4. `archive/HANDOFF-260519.md` for the TestFlight queue still in flight
5. `docs/testflight.md` if doing another TestFlight upload

You're picking up at: review the in-flight PR + resume the
TestFlight / M-qa flow from 5/19.

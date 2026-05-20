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

### -2. P3-4 — Download retry with backoff

Commit `9fea6db`. `TourDownloader` now retries the current file on
transient network errors (timeout / connection lost / DNS / no
internet) with exponential backoff (1s → 2s → 4s, max 3 retries per
file). Terminal failures (bad URL, etc.) still fail immediately;
user cancel aborts any pending retry. Real-world payoff: a walking
tour download that hits a momentary signal blip recovers
transparently. `TourDownloaderRetryClassifierTests` covers the
classifier.

### -1. P3 audit cleanup — three small correctness fixes

Three remote-friendly P3 findings cleared on `claude/resume-after-error-WQGK6`
(commit `b1fe99a`).

- **P3-7** `ContentView.requestPermission` called on every
  `.onAppear` — now gated by a `didRequestLocationPermission`
  flag. iOS was already no-op-ing repeats but the redundancy was
  conceptually wrong.
- **P3-8** Search didn't match tags or descriptions even though
  `docs/authoring-tours.md` promised tags fed the index. Added
  tag + description buckets to `SearchView.filteredTours` with
  rank order title → category → maker → tags → description.
- **P3-10** `ManageDownloadsView` listed downloaded tours in
  Dictionary-iteration order (i.e. random between launches).
  Now sorted alphabetically by title via
  `localizedCaseInsensitiveCompare`.

P3 items intentionally **not** done this session (called out in
ROADMAP): P3-1 (theme tokens, design-deferred), P3-3 (lookup
performance, premature for 12 tours), P3-4 (download retry, larger),
P3-5 (tour-completed UX, needs simulator review), P3-6 (splash,
polish-pass deferred), P3-9 (delete swipe in Library, UI verify).

### 0a. P2 audit cleanup — accessibility + localization

Commit `2429fb1`. Closes the P2 tier:
- **P2-1** BottomSheet drag handle gains VoiceOver label,
  detent-aware value, hint, and `accessibilityAdjustableAction`
  that cycles detents on swipe up/down.
- **P2-2** marked obsolete in ROADMAP — the preview-card-with-X
  pattern referenced in the audit was removed in PR #19.
- **P2-3** download button now distinguishes "disabled because
  another download is in-flight" in its label + hint.
- **P2-4** SettingsView gains an "Open in Settings" button when
  location authorization is `.denied`/`.restricted`, deep-linking
  to `UIApplication.openSettingsURLString` (iOS / visionOS only).
- **P2-5** five copies of hand-rolled `formattedDuration` plus
  three hardcoded `m`/`km`/`min` distance literals all replaced
  with `Components/AtlasFormatters.swift` —
  `DateComponentsFormatter` for durations, `MeasurementFormatter`
  (`.naturalScale`) for distances. Imperial locales now see
  `"0.5 mi"` instead of `"1.3 km"`. Incidentally closes P3-2
  (formattedDuration duplication).

`AtlasFormattersTests` covers duration shape (sub-min, exact min,
hour+min, zero, negative) and distance shape with
locale-independent assertions.

### 0. P1 audit cleanup batch — closed out

All 5 remaining P1 findings from `archive/pre-qa-audit-260518.md`
shipped on `claude/resume-after-error-WQGK6` (commit `8bd5053`).
Intended as the "one cleanup PR before M-qa runs on device" called
out in `HANDOFF-260519.md` § V1 work outstanding. ROADMAP § M-qa
checklist and § Known follow-ups updated.

- **P1-1** sort key — `LibraryEntry` gains `lastListenedAt`;
  `LibraryStore.recentlyPlayed` and
  `HomeRailsViewModel.continueListeningRail` sort by it.
  Backwards-compatible (optional field, missing → nil).
- **P1-2** avatar URL — `MakerView.avatar` renders
  `maker.avatarURL` via `AsyncImage` with the grey-circle
  fallback.
- **P1-3** player-tour ID — `AudioPlayerService` gains
  `currentSourceId`; callers (`PlayerView`, `ProximityMonitor`)
  pass `tour.id.uuidString`; `TourDetailView` predicates match
  on source ID instead of title. Fixes the two-tours-with-the-
  same-title corner case.
- **P1-4** `HeroImageView` swapped from placeholder-only to
  `AsyncImage` with the placeholder as loading / failure / empty
  fallback. **First PR where real photography is visible in the
  simulator** — the Times Square images from earlier this session
  will now actually render.
- **P1-7** antimeridian bug — extracted to a single
  `MKCoordinateRegion.contains(_:)` extension in
  `Location/MKCoordinateRegion+Contains.swift`. Both
  duplicated implementations (`HomeView`, `HomeRailsViewModel`)
  collapsed to use it. Tests cover both wrap directions.

Test additions: `LibraryStoreTests` gains
`test_recentlyPlayed_sortedByMostRecentlyListened` +
`test_updateProgress_setsLastListenedAt`; new
`MKCoordinateRegionContainsTests` covers 6 cases including both
wrap directions. CI's xcodebuild jobs are the safety net — no
Swift toolchain in the remote container.

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
Commits ahead of main: 7+
- `0ce95bd` — ROADMAP note about stale branches
- `e0d098a` — Times Square images + Option A data layer
- `d506297` — Handoff doc for 2026-05-20 (initial draft)
- `8bd5053` — P1 audit cleanup batch (5 findings)
- `5b49bd2` — Handoff refresh (P1)
- `2429fb1` — P2 audit cleanup (5 findings + P3-2)
- `b1fe99a` — P3 audit cleanup (P3-7, P3-8, P3-10)
- (plus this handoff refresh)

See the "Where we are right now" section for a suggested PR split.

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

In-flight branch: `claude/resume-after-error-WQGK6`, 9+ commits
ahead of `main`:
- `0ce95bd` ROADMAP: stale branches noted
- `e0d098a` Times Square images + Option A data layer
- `d506297` Handoff doc (initial)
- `8bd5053` P1 audit cleanup batch (5 findings)
- `5b49bd2` Handoff refresh (P1)
- `2429fb1` P2 audit cleanup (accessibility + i18n; 5 findings + P3-2)
- `b1fe99a` P3 audit cleanup small fixes (P3-7, P3-8, P3-10)
- `d55d132` Handoff refresh (P2 + P3)
- `9fea6db` P3-4 — TourDownloader retry with backoff
- (plus this final handoff refresh)

**Splitting into multiple PRs is strongly recommended** given
the scope. Suggested split:
1. **Times Square + carousel data** (`e0d098a` + portions of the
   ROADMAP / handoff docs) — content + data-layer feature.
2. **P1 audit cleanup** (`8bd5053`) — 5 bug fixes + tests.
3. **P2 audit cleanup** (`2429fb1`) — accessibility + locale
   formatters.
4. **P3 small fixes** (`b1fe99a`) — three correctness
   improvements.
5. **Doc / housekeeping** (`0ce95bd`, `d506297`, `5b49bd2`, and
   this refresh) — could fold into whichever code PR ships first,
   or land separately.

Or merge as one big "pre-M-qa cleanup" PR if you'd rather. Each
commit on the branch already passes the "is this a self-contained
change?" test, so reviewers can read commit-by-commit either way.

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

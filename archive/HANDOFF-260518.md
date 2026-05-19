# Atlas — Handoff Notes (2026-05-18, end of day)

Snapshot of where the project is at the close of the 2026-05-18
session. Read this from any machine — GitHub web, fresh `git clone`,
new Claude session — to pick up the next work session with full
context. Companion to `CLAUDE.md` (durable rules) and `ROADMAP.md`
(milestone status).

> **Note on this file's history.** Earlier today's snapshot of the
> same name (covering 2026-05-16/17 work) lives in git history.
> `git log -- archive/HANDOFF-260518.md` to find it. This file is
> rewritten end-of-day rather than appended to.

---

## What's in `main` right now

Latest commit on `main` is `d70e2a4` ("CLAUDE.md: document when
Claude should run unit tests, PR #34").

**Tonight's session shipped:**

| PR | What |
|---|---|
| #31 | AllTrails-style home: custom tab bar + floating-island drawer + filter chips + vertical tour list + recenter button. Earlier rail-carousel home superseded. |
| #32 | Archived pre-QA audit doc to `archive/`; ROADMAP M-qa checklist is now the live record. |
| #33 | Wired Unit Testing Bundle target into Xcode project + `TourListCard` selection-state polish + CI test-job destination fix + test target deployment target lowered to 26.2. |
| #34 | `CLAUDE.md`: trigger-based test cadence rule. |

**Earlier today's session shipped** (for context):
- PR #20 — M-launch-content authoring scaffold + CONTRIBUTING.md
- PR #21 — Pre-QA self-audit doc (22 findings)
- PRs #22–24 — All P0 audit findings closed (theme tokens, navigation, audio + geofencing hardening)
- PRs #25–26 — CDN brief expansion + interim decision
- PRs #27, #30 — Two real tour audio recordings (Grand Central + Times Square TKTS)
- PR #28 — XCTest unit suite + CI workflow (test files only; wiring deferred to #33)
- PR #29 — Working rule: Claude auto-merges doc + content PRs without per-PR approval

---

## What's pending / queued

### Pending user feedback (most urgent for next session)

Tonight ended mid-iteration on AllTrails polish. After the
`TourListCard` selection-state fix landed (PR #33), the owner said:
> "good for now. lets switch gears slightly"

…then asked about test wiring and continuity. So **AllTrails polish
is paused but not done.** Owner said earlier: "alltrails style is
getting there, fine for now. many more specific comments to come."
Next session: prompt the owner for those specific comments before
making further AllTrails changes.

### V1 work still outstanding

- **M-launch-content** — 2 of 5–15 tours recorded. Owner records the
  rest. Authoring scaffold ready: `docs/authoring-tours.md`,
  `docs/Tours.template.json`, `scripts/validate-tours.swift`.
  Audio CDN is `gh-pages` branch (push `.mp3` files, update
  `Resources/Tours.json` URLs).
- **M-qa P1 cleanup batch** — five P1 audit findings open:
  - P1-1. "Continue listening" / "Recently played" sort by wrong field
  - P1-2. Maker avatar URL is ignored (lands with P1-4)
  - P1-3. Player-tour identification by title is fragile
  - P1-4. HeroImageView doesn't load remote images
  - P1-7. International-dateline bug in coordinate-in-region check
  Intended as one cleanup PR before M-qa runs.
- **M-qa real-device pass** — 10-step functional checklist in
  `ROADMAP.md` § M-qa. Needs a real iPhone + lock-screen + walking
  through a geofenced tour. Last unblocked item before V1 release
  (modulo polish / icon / pins).
- **Deferred polish pass** — theme tokens, app icon, custom map
  pins, final editorial copy.

### P2 / P3 audit items
Live in `ROADMAP.md` § M-qa. Not blocking V1. Address opportunistically.

---

## Tribal knowledge from today's sessions

(Durable form is in `docs/troubleshooting.md`. Quick recap for
context.)

- **Audio CDN MIME issue.** GitHub Releases serves binary assets as
  `Content-Type: application/octet-stream`, which AVPlayer rejects.
  Switched to GitHub Pages on the `gh-pages` orphan branch; Pages
  serves `audio/mp3` correctly. See `docs/cdn-decision.md`.
- **Phantom xcodeproj.** Xcode's workspace re-save dialog can create
  empty `.xcodeproj/` directories at nested paths if accepted with
  the default location. Always cancel and read the path first.
- **Xcode + git file-handle lock.** Xcode holding file handles can
  block `git rebase` / `git checkout` even with a clean tree.
  `git stash --include-untracked` releases the lock; otherwise quit
  Xcode (Cmd-Q) before non-trivial git ops.
- **gh CLI `.git/HEAD.lock`.** Background `gh pr merge` holds
  `HEAD.lock` while it switches the local checkout away from the
  deleted branch. Wait for gh to fully exit before `git pull`.
- **Test target was created with `IPHONEOS_DEPLOYMENT_TARGET = 26.5`**
  by Xcode (latest SDK), but the main app + CI runner only support
  26.2. Lowering to 26.2 fixed CI. If you add another target,
  check its deployment target matches the main app.
- **CI test destination must be name-based, not UDID.** The earlier
  workflow extracted a UDID from `xcrun simctl list devices`; the
  picked UDID didn't match any destination supported by the scheme
  on the CI runner. Name-based (`platform=iOS Simulator,name=iPhone 16,OS=latest`)
  is robust across Xcode / runtime version bumps.

---

## How to resume from a remote / fresh machine

```bash
# Fresh checkout (if needed)
git clone https://github.com/ehky2882/TRAVEL-GUIDED-TOUR.git
cd TRAVEL-GUIDED-TOUR

# Get latest
git fetch
git checkout main
git pull --ff-only

# Sanity
git status                              # should be clean
git log --oneline -5                    # confirm latest matches d70e2a4 or later
gh pr list --state open                 # should be empty unless something new
```

Then read in this order:
1. **`CLAUDE.md`** § Current State + § Session-start ritual
2. **`ROADMAP.md`** § Where we are right now + § M-qa checklist
3. **This file** (`archive/HANDOFF-260518.md`) for what's queued
4. **`docs/troubleshooting.md`** if anything weird happens with Xcode or git

To resume from the same Mac after a break:
```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"
claude --resume                  # picks the last session
# or just `claude` for fresh, and orient by reading the docs above
```

---

## What to tackle first next session (Claude's suggestion)

1. **Run the session-start ritual** (`CLAUDE.md` § "Session-start
   ritual") and confirm state matches this handoff.
2. **Prompt owner for the queued AllTrails comments** ("many more
   specific comments to come"). Don't make polish changes without
   them.
3. **If owner shifts gears** away from AllTrails: candidates in
   priority order are (a) the P1 cleanup batch, (b) more
   M-launch-content tours, (c) M-qa on a real device.
4. **End of session**: rewrite this handoff with the new state, or
   create `archive/HANDOFF-YYMMDD.md` for the new date.

---

## File map (where things live)

```
TRAVEL GUIDED TOUR/                    # repo root
├── CLAUDE.md                          # durable project guidance for Claude
├── ROADMAP.md                         # V1 plan + milestone status
├── CONTRIBUTING.md                    # onboarding for new contributors
├── atlas_claude_code_prompt.md        # canonical product spec
├── docs/                              # reference material (not session-start reading)
│   ├── authoring-tours.md
│   ├── Tours.template.json
│   ├── cdn-decision.md
│   └── troubleshooting.md             # ← Xcode + git landmines
├── archive/                           # dated snapshots of retired docs
│   ├── README.md
│   ├── HANDOFF-260518.md              # ← THIS FILE
│   └── pre-qa-audit-260518.md
├── scripts/
│   └── validate-tours.swift
├── .github/workflows/ci.yml
├── TRAVEL GUIDED TOURTests/           # XCTest suite + README for wiring
└── TRAVEL GUIDED TOUR/                # source root
    ├── Models/                        # Tour, Stop, Maker, etc.
    ├── Data/                          # DataService, LibraryStore, etc.
    ├── Audio/                         # AudioPlayerService, TourDownloader
    ├── Location/                      # LocationManager, ProximityMonitor
    ├── Features/
    │   ├── Home/                      # AllTrails-style: map + drawer + chips
    │   ├── Tour/, Player/, Search/, Maker/, Library/, Settings/
    ├── Components/                    # HeroImageView, TagChip, BottomSheet, AtlasTabBar
    ├── Theme/                         # AtlasColors/Typography/Spacing (placeholders)
    └── Resources/Tours.json           # ← seed + 2 real tours; edit for more content
```

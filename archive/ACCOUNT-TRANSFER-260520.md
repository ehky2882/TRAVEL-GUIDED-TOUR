# Atlas — Account Transfer Notes (2026-05-20)

> **For the successor Claude on a different account, on the owner's
> first session under that account.** This file is a one-time
> hand-off written specifically for that transition. Read it once,
> then operate from the regular `CLAUDE.md` + latest
> `archive/HANDOFF-*.md` going forward.

---

## What this project is, in one paragraph

**Atlas** is a SwiftUI iOS app — a creator platform for **GPS-anchored
audio tours.** Makers record short audio clips about places (a piece
on one location, or a multi-stop walking tour); consumers browse tours
near them, download for offline listening, and play them while walking
— with audio that auto-triggers at each geofenced stop. Shape: closer
to AllTrails or Atlas Obscura than to a guidebook. **V1 is consumer-
side only** — Atlas team makes the content, no backend, no auth, no
payments, no in-app maker upload. Multi-platform target (iOS / iPadOS
/ macOS / visionOS 26.2+) via SwiftUI + MapKit + AVFoundation +
CoreLocation. See `atlas_claude_code_prompt.md` at repo root for the
canonical product spec.

---

## How to come up to speed (first session under new account)

Run the session-start ritual from `CLAUDE.md` § "Session-start ritual":

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"      # or wherever the clone is
git fetch
git status                              # should be clean
git log --oneline -10                   # latest should be 7caf95e or newer
gh pr list --state open                 # should be empty unless something new
```

Then read in this order:

1. **`CLAUDE.md`** — project guidance for Claude. § Project Overview,
   § Current State, § Keep these docs in sync, § Session-start ritual,
   § Merging PRs, § Architecture, § Conventions are the load-bearing
   sections. The whole file is dense but every sentence earns its
   place.
2. **`ROADMAP.md`** — V1 execution plan + milestone status. § Where
   we are right now is the live snapshot; § V1 — Functionality
   milestones is the history.
3. **The most recent `archive/HANDOFF-*.md`** — `ls archive/HANDOFF-*.md | tail -1`.
   This file captures mid-flight state and tribal knowledge the
   durable docs don't cover yet.
4. **`docs/testflight.md`** — runbook for TestFlight uploads (~10 min
   per release after the gauntlet is set up).
5. **`docs/troubleshooting.md`** — Xcode + git landmines documented
   from real incidents.
6. **`docs/cdn-decision.md`** — Why audio is on GitHub Pages (`gh-pages`
   branch), not GitHub Releases. Includes the MIME-type gotcha.
7. **`docs/authoring-tours.md`** — content authoring guide
   (UI-agnostic, doubles as spec for future in-app maker upload).
8. **`atlas_claude_code_prompt.md`** — canonical product spec.

After reading those, you'll know everything the durable docs cover.
Specific to this account-transfer moment, see § "State at transfer
(2026-05-20)" below.

---

## State at transfer (2026-05-20)

### Code

- `main` is at commit `7caf95e` ("Pre-M-qa cleanup batch + Option A
  data layer (P1+P2+P3+download retry), PR #51"). All V1 audit
  findings closed (P0 / P1 / P2 / P3 done where actionable; a few P3
  items intentionally deferred — see ROADMAP).
- Unit test target wired (`TRAVEL GUIDED TOURTests`). Cmd-U runs the
  suite locally; CI runs it on every PR.
- `DEVELOPMENT_TEAM = CPC7M72JTP` is in `project.pbxproj` for both
  app + test targets. Signing works automatically on the owner's Mac;
  on a different Mac you'd need to either be signed into the same
  Apple Developer team or change the team ID.

### Content

- 12 tours total: 10 real NYC tours + 2 seed tours. Total audio
  ~26 minutes. Spans 4 categories (history, architecture,
  natureAndParks, culturalHeritage).
- Audio served from `gh-pages` branch at
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<file>.mp3`.
- First photographic content shipped: 3 Times Square photos at
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`.
  `Tours.json` references them via `heroImageURL` and the new
  `additionalImageURLs` field. **But `TourDetailView` only renders
  `heroImageURL` so far** — the carousel UI for additional images is
  Known Follow-up work (~30–40 min, see ROADMAP).

### TestFlight / App Store Connect

- Build **1.0 (1)** uploaded to App Store Connect on 2026-05-19 at
  9:38 PM, currently **"Ready to Submit"** as of 2026-05-20 morning
  (last we checked).
- Internal Testing group: **not yet created** (TestFlight tab → still
  pending). This is the next priority for the owner.
- External Testing group: **not yet created**.
- "What to Test" text: **not yet pasted** in App Store Connect. Draft
  text is in `archive/HANDOFF-260519.md` § Tomorrow's queue #2.
- TestFlight app: **already installed on owner's iPhone**. Ready to
  receive invites once the Internal Testing group is set up.
- Apple Developer team: owner ("EDWARD HO KIU YUNG") is the only
  member. iPhone UDID `00008150-001430EA1408401C` (iPhone 17 Pro,
  iOS 26.3.1) is registered to the team.

### Apple Developer / App Store Connect off-repo

| Where | What's there | Login |
|---|---|---|
| https://developer.apple.com/account | Apple Developer Program enrollment, App ID `com.ehky.TRAVEL-GUIDED-TOUR`, signing certs, provisioning profiles, registered devices | Owner's Apple ID |
| https://appstoreconnect.apple.com | App record "Atlas Audio Tours", App Privacy questionnaire (published), TestFlight, App Store version-1.0 metadata | Same Apple ID |
| https://ehky2882.github.io/TRAVEL-GUIDED-TOUR | Privacy policy + audio files + image files | n/a (served from `gh-pages` branch in this repo) |

The Apple Distribution **signing certificate** lives only in the
owner's Mac's Keychain — it's not in the repo. If the owner uses a
different Mac later, they either need to export + import the cert via
Keychain, or recreate via Xcode (Settings → Accounts → Manage
Certificates → + Apple Distribution).

---

## What's queued

In rough priority order. The deepest-buried items live in
`ROADMAP.md` § Known follow-ups; the immediate work lives here.

### Immediate (the V1 release path)

1. **TestFlight setup** — owner was mid-walkthrough when they
   transferred accounts. Specifically:
   - App Store Connect → TestFlight → Internal Testing → + → create
     group → add owner as tester → add build 1.0 (1) to the group
   - Optionally external testing group + Beta App Review (24–48h
     wait the first time)
   - Paste "What to Test" notes on the build (draft text in
     `HANDOFF-260519.md`)
   - On iPhone: install via TestFlight app → run M-qa 10-step
     checklist in `ROADMAP.md` § M-qa
2. **Stale remote branch cleanup** — 13 merged `claude/*` feature
   branches on origin/. Container's GitHub token couldn't delete
   them remotely; needs the owner's local Mac with their `gh` auth.
   Re-derivation instructions in `ROADMAP.md` § Known follow-ups
   (search for "Stale remote branches"). ~30s of work.

### Near-term

3. **Hero image carousel UI** — Option A data layer is shipped but
   `TourDetailView` still renders only `heroImageURL`. Until this
   ships, the 2 extra Times Square photos are unreachable in-app.
   ~30–40 min of SwiftUI: replace the single `HeroImageView` in
   `TourDetailView.swift` (~line 35) with a `TabView` using
   `.tabViewStyle(.page)` over `[heroImageURL] +
   (additionalImageURLs ?? [])`. Verify in simulator with Times
   Square (only multi-image tour for now). Separate, focused PR.
4. **More M-launch-content tours** — owner can add more or ship
   V1 with the current 10. See `docs/authoring-tours.md` for the
   workflow.
5. **P3 items intentionally deferred** (see ROADMAP):
   P3-1 (theme tokens, design-deferred),
   P3-3 (lookup performance, premature for 12 tours),
   P3-5 (tour-completed UX, needs simulator review),
   P3-6 (splash, polish-pass deferred),
   P3-9 (delete swipe in Library, UI verify needed).

### Future / post-V1

- **Design / polish pass** — theme tokens, real app icon (currently a
  placeholder green sphere), custom map pins, final editorial copy.
  Per `ROADMAP.md` § Owner direction #1, deferred deliberately.
- **`M-rethink-categories`** — drop closed `TourCategory` enum, derive
  home rails from `Tour.tags`. Pair with design pass.
- **`M-maker-platform`** — three-phase plan in ROADMAP for in-app maker
  upload (V1 has no maker upload).
- **`M-content-tooling`** — manifest-driven CSV uploads,
  auto-transcription, geocoding (pre-cursor to maker platform).

---

## Working-style notes (owner ↔ Claude)

Captured from many sessions across late May 2026. Honest observations
to save the new Claude from learning by trial. None of these are
preferences in a memory file — they're operating norms that emerged
naturally and are worth knowing up front.

### How owner likes to work

- **Non-technical, but technically literate.** Owner reads code-style
  docs fine with plain-English analogies (the parenthetical "analogy
  in parens" pattern in `CLAUDE.md` is owner-requested, not a Claude
  affectation). Don't dumb things down, but don't assume CS-degree
  vocabulary either.
- **Step-by-step prompts are welcomed.** When walking through Xcode
  UI or a multi-step flow, owner explicitly asked "can you walk me
  through it step by step prompt" — wants ONE step at a time, then a
  prompt for confirmation, then next step. Don't dump a 10-step list
  unless asked.
- **Recommended-option-first for decisions.** When using
  `AskUserQuestion`, put the recommended option first with
  "(Recommended)" in the label. Owner usually picks the first/
  recommended option unless they have a reason not to.
- **Owner appreciates "is this right?" validation moments.** They
  asked "is this right" + "is this normal?" frequently. Most often
  this means: I've made a change, do you confirm it's correct?
  Answer directly. If yes: confirm and move forward. If no: explain
  what's off.
- **Screenshots are the primary debugging artifact.** When owner
  hits a UI / state issue, asking for a screenshot is fastest — often
  faster than asking them to describe text. They've been generous
  with screenshots; lean on them.
- **Owner explains WHY they're stuck, not just WHAT.** Pay attention
  to the framing — "i really dont understand where to find this" or
  "is there another way?" are signals that the path I proposed is
  too complicated, not that they're confused. Offer simpler
  alternatives.
- **Owner sometimes dismisses `AskUserQuestion` without answering.**
  They may want to think before deciding. **Don't proceed** — wait
  for the next instruction. (Tested: yes, dismiss really means
  "pause, don't pick a default.")
- **Owner is honest about needing to stop.** "gotta go" / "i'm done
  for the night" / "i'll resume on the remote chat" are clear stop
  signals. Wrap up cleanly, push everything, write the handoff. Do
  not try to squeeze in "one more thing."
- **Owner trusts Claude with doc-only and content-only PRs.**
  Per `CLAUDE.md` § Merging PRs, Claude auto-merges those. Code PRs
  always wait for explicit owner OK — and "OK" means "I've validated
  visually in the simulator" by default. Big-batch code PRs the owner
  explicitly OKs in chat (like PR #51) can be merged without a sim
  validation cycle, but say so explicitly when doing it.

### Communication style

- **Concise wins.** Lead with the answer; explain after if needed.
  Owner reads tables and headings more reliably than walls of prose.
- **Tables are good for state recap** ("here's what we shipped" /
  "here's what's queued") — easier to scan than paragraphs.
- **Emoji used sparingly but effectively.** ✅ for confirmed
  state, ❌ for errors, ⚠️ for warnings. The 🚀 / 🎉 for genuinely
  big milestones (first TestFlight install, etc.) felt right. Don't
  spray them.
- **Owner appreciates a frank "I was wrong" when relevant.** I had
  to walk back the "Archive doesn't need devices registered" claim
  on 2026-05-19 — being honest about that landed better than trying
  to spin it. Acknowledge when you misled them.
- **Owner does NOT like padding or filler.** Don't preface answers
  with "Great question!" or summarize what they just said before
  answering. Just answer.

### Doc-hygiene patterns owner cares about

- **Session-start ritual** (`CLAUDE.md`) — built explicitly because
  owner got bit by parked-branch confusion on 2026-05-18. They value
  continuity and will reinforce this pattern.
- **HANDOFF-YYMMDD.md** at end of each session — written by Claude
  before sleep, rewritten next day. Owner explicitly asked for these
  ("i really want to make sure that if i were to pick up the work
  from a new session (remote) rather than this local one that there
  can be continuity"). The latest one is part of the session-start
  ritual; older ones go historical.
- **Doc-only PRs** — per the auto-merge rule, Claude PRs and
  self-merges these. Owner wants them visible as PRs (not direct-push
  to main) for the audit trail.
- **`archive/`** vs `docs/`** — `docs/` is reference material
  current and read-at-need (cdn-decision, testflight, troubleshooting,
  authoring-tours). `archive/` is historical snapshots — except the
  latest HANDOFF, which is read at every session start.

### Things that work less well

- **Long technical walls of text** — owner glazes over. Use
  headings / tables / bullets aggressively. If you can't, ask if
  they want a TL;DR.
- **Multiple parallel questions in one message** — owner will
  answer the first and forget the others. `AskUserQuestion` with up
  to 4 grouped questions is fine; 4 separate questions in prose
  isn't.
- **"Trust me, this should work" assertions** — if you have not
  actually verified something, say "I think this should work, let's
  try" rather than "this will work." Owner appreciates the honest
  hedge.

---

## Tribal knowledge worth carrying forward

Most of this is now documented elsewhere; quick pointers so the new
Claude finds them.

- **GitHub Pages MIME types vs Releases** — audio MUST be on
  `gh-pages`, not Releases. AVPlayer rejects Releases'
  `application/octet-stream` MIME. See `docs/cdn-decision.md`.
- **gh-pages workflow** — `git checkout gh-pages` → drop files in →
  commit → push → `git checkout main`. **Always check out back to
  main** before continuing other work. Don't try worktrees (the
  signing service errors out).
- **Apple's first-time signing gauntlet** — plug iPhone → Trust →
  Developer Mode in Settings → Restart → Confirm → Xcode auto-
  registers → click Register Device button → Archive works. See
  `docs/testflight.md` § "Adding a new physical device".
- **Disk-space matters** — Mac was at 99% capacity at one point
  causing `dyld_shared_cache_extract_dylibs` to fail. Cleaning
  `~/Library/Developer/Xcode/DerivedData/*` and
  `~/Library/Developer/Xcode/iOS DeviceSupport/*` freed 10 GB.
  See `docs/troubleshooting.md` § "dyld_shared_cache..."
- **`Tours.json` insertion pattern** — Python's `json.dumps(d, indent=2)`
  reformats inline arrays to multi-line, producing noisy diffs. Use
  string-level insertion (read file → find `"  ]\n}\n"` footer →
  splice in new tour block before it). Pattern was in a previous
  session's `/tmp/add_tour.py`.
- **CI iOS Simulator destination** — must explicitly create a
  simulator at job start (`xcrun simctl create`) because GitHub
  Actions runner-pool variance: some macos-latest runners have
  pre-baked iPhone simulators, others don't. See `docs/troubleshooting.md`
  § 7 + `.github/workflows/ci.yml`.
- **Build number must increment per upload** to App Store Connect.
  Marketing Version (`1.0`, `1.1`) can stay the same for multiple
  TestFlight uploads as long as Build Number (`1`, `2`, `3`) is unique.

---

## If you (new Claude) want to read this session's transcript

For deepest cold-start context, the conversation transcripts from the
sessions leading up to this transfer live at:

```
~/.claude/projects/-Users-EY/<session-id>.jsonl
```

…on the owner's Mac (the original session ran here). Each session has
its own JSONL file. The most relevant ones for project-level context
are the late-May 2026 ones (2026-05-18 through 2026-05-20). Each line
is a JSON event in the session — user messages, assistant messages,
tool calls, tool results. Use `jq` or Python to parse.

This is **optional / for the curious**. The docs in this repo capture
everything Claude needs to operate. The transcript is just the raw
log of how we got here.

---

## Final notes from the outgoing Claude

This project went from "I want to build an iOS app" to "an Atlas
TestFlight build is on the owner's iPhone awaiting M-qa" between
2026-05-18 and 2026-05-20. The doc-hygiene and continuity systems
(`CLAUDE.md` § Session-start ritual, the HANDOFF-YYMMDD.md pattern,
`docs/troubleshooting.md`, `docs/testflight.md`) were explicitly built
for the moment we're in now — and we just learned whether they hold
up under a hard account transfer.

If anything in the durable docs feels stale or wrong on first read,
please fix it in the next session. Don't accumulate stale-docs debt.

Good luck. The owner is in good hands; the project is in
good shape.

— Claude, on the previous account, 2026-05-20

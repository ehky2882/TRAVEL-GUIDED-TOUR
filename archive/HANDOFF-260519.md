# Atlas — Handoff Notes (2026-05-19, end of day)

Snapshot of where the project is at the close of the 2026-05-19
remote session. Read this from any machine — GitHub web, fresh
`git clone`, new Claude session on a different host — to pick up
the next work session with full context. Companion to `CLAUDE.md`
(durable rules) and `ROADMAP.md` (milestone status).

> **Note on file history.** The previous active handoff
> (`HANDOFF-260518.md`) has been demoted to historical; this file
> is now the active handoff per `archive/README.md`. The 5/18
> snapshot remains in `archive/` for reference but is no longer
> part of the session-start ritual.

> **Session context.** This whole session ran on **remote Claude
> Code on the web** while the owner was at a work computer (no
> Mac access). The next session is expected to run on the **local
> Claude Code on the Mac**. This handoff is written specifically
> to bridge that hop.

---

## What's in `main` right now

Latest commit on `main` is `f71913b` ("ROADMAP: expand Tier 1 #2
(maker platform) + add M-content-tooling, PR #46").

**Today's session shipped:**

| PR | What |
|---|---|
| #36 | **TestFlight prep.** App icon placeholder (1024×1024 PNG: black bg with shaded green sphere, splash-matching) wired into `Assets.xcassets/AppIcon.appiconset/`. `ITSAppUsesNonExemptEncryption = NO` set in both build configs (skips Xcode's per-archive dialog). `docs/design-tokens.md` published as a single-sheet reference for typography / colors / spacing / SF Symbols. |
| #37 | Tour: South Street Seaport, Pier 16 (2:32, history) |
| #38 | Tour: Empire State Building (2:30, architecture) |
| #39 | Tour: Statue of Liberty, Liberty Island (2:31, history) |
| #40 | Tour: Brooklyn Bridge, Manhattan Side (2:27, history) |
| #41 | Tour: Rockefeller Center, the Plaza (2:59, history) |
| #42 | Tour: Metropolitan Museum of Art, 5th Avenue Steps (2:54, architecture) |
| #43 | Tour: High Line, 10th Avenue Square (3:12, natureAndParks) |
| #44 | **ROADMAP.** Added `M-rethink-categories` polish milestone. Closed-enum `Tour.primaryCategory` is showing strain — at least four V1 tours had multiple defensible category fits. Direction (endorsed today, deferred): drop the enum, derive home rails + filter chips from `Tour.tags`. Pair with the design pass. |
| #45 | Tour: 9/11 Memorial, Between the Pools (2:13, culturalHeritage — first in catalog) |
| #46 | **ROADMAP.** Expanded Tier 1 #2 (maker platform) from a one-liner into a three-phase plan (single-piece capture / multi-stop curation / maker tooling depth). Phone-vs-web split spelled out. Hard dependencies on backend/auth/moderation noted. Two new open questions for the owner. Added `M-content-tooling` to Known follow-ups — near-term streamlining ideas (manifest-driven batch uploads, auto-transcription, geocoding from text, CLI tool) for whenever the chat-driven upload workflow starts hurting. |

Also pushed to **`gh-pages`** branch (not `main`):
- `audio/south-street-seaport-pier-16.mp3`
- `audio/empire-state-building.mp3`
- `audio/statue-of-liberty.mp3`
- `audio/brooklyn-bridge-manhattan-side.mp3`
- `audio/rockefeller-center-the-plaza.mp3`
- `audio/metropolitan-museum-fifth-ave-steps.mp3`
- `audio/high-line-10th-avenue-overlook.mp3`
- `audio/nine-eleven-memorial.mp3`
- `privacy/index.html` — privacy policy page

---

## Browser-side App Store Connect work (completed today, off-repo)

The owner did all of this from a work computer browser. **Don't
redo any of it on the Mac.**

- **Apple Developer.** App ID registered: `com.ehky.TRAVEL-GUIDED-TOUR` (explicit bundle ID, no capabilities enabled — none of V1's features need them).
- **App Store Connect.** App record created. Bundle ID locked to the above.
- **App Information filled:**
  - Subtitle: `Audio tours that follow you`
  - Promotional text: `Walk into a place, and the audio about it starts playing. Atlas is GPS-anchored audio tours for walkers. New York launch catalog, more cities coming.`
  - Keywords: `walking,self-guided,sightseeing,history,architecture,art,museum,city,guide,travel,NYC,explore,hike`
  - Description: (the multi-paragraph block from this session — in chat history if needed; re-derivable from the spec)
  - Privacy Policy URL: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/privacy/`
  - User Privacy Choices URL: blank (correct — Atlas has nothing to opt out of)
- **App Privacy questionnaire: Published.** Answered "No" to data collection at the top level (Atlas truly collects nothing off-device; location is used in-process only and never transmitted).
- **TestFlight → Test Information:**
  - Beta App Description: the multi-paragraph block from this session
  - Feedback Email: owner's personal email
  - Marketing URL: blank (skipped, optional)
  - Privacy Policy URL: same as above
  - License Agreement: blank (Apple's default beta agreement applies)
- **Privacy policy:** hosted at `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/privacy/` (served from `privacy/index.html` on the `gh-pages` branch).

The "What to Test" field is **drafted but not yet pasted** — that field only appears in App Store Connect after the first build is processed, so it's a Mac-session task. Text is in chat history; can also be re-derived from the M-qa 10-step checklist in `ROADMAP.md`.

---

## What's pending / queued for the next session

### Mac-side work (the whole point of the next session)

In order:

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"
git fetch
git checkout main
git pull --ff-only
git status            # should be clean
```

Then in Xcode:

1. **Settings → Accounts** → sign in with the Developer Program Apple ID. Confirm team appears.
2. Project navigator → **both targets** (`TRAVEL GUIDED TOUR` and `TRAVEL GUIDED TOURTests`) → **Signing & Capabilities** → set Team. Automatic signing should pick up the registered App ID.
3. Confirm `Assets.xcassets/AppIcon.appiconset/` shows the placeholder icon (it's already wired in `main`).
4. Destination → **Any iOS Device (arm64)**. Not a simulator — archive only works against device.
5. **Product → Archive**. Takes 2–5 min.
6. Organizer opens → **Distribute App → App Store Connect → Upload**.
7. Wait 15–30 min for App Store Connect to process the build (email when ready).
8. App Store Connect → TestFlight → click the build → paste the "What to Test" text.
9. TestFlight → Internal Testing → add yourself as Internal Tester.
10. Install TestFlight on iPhone → accept invite → install Atlas → run the M-qa 10-step checklist in `ROADMAP.md`.

### V1 work still outstanding

- **M-launch-content** — **10 of 5–15 tours done.** 8 real + 2 seed. Total ~26 min of audio across 4 categories (history 5, architecture 4, natureAndParks 1, culturalHeritage 1). Owner may decide to ship V1 with these, or add more. The seed tours (Cooper Hewitt, Hidden Brooklyn) use placeholder audio URLs (`soundhelix.com`) and could be removed if not wanted in launch content — kept for now to keep the catalog shape exercising multi-stop code paths.
- **M-qa P1 cleanup batch** — five P1 audit findings still open (P1-1, P1-2, P1-3, P1-4, P1-7). Needs simulator validation; intended as one cleanup PR before M-qa runs on device.
- **M-qa real-device pass** — 10-step functional checklist in `ROADMAP.md` § M-qa. The whole reason we're going to TestFlight.
- **Deferred polish** — theme tokens, app icon, custom map pins, final editorial copy.

### Hero image carousel (Option A, locked but not implemented)

Owner agreed on **Option A** (additive `additionalImageURLs: [String]` field alongside the existing `heroImageURL`). **Deferred** until images are ready to populate — no point lighting up the carousel UI while every tour has one placeholder image. ~1 hour of code when triggered: model + decoding tests + validator update + tour-detail view rewrite to a `TabView(.page)` showing `[heroImageURL] + additionalImageURLs`. Card surfaces unchanged (still use `heroImageURL` as cover).

### Decisions captured in ROADMAP (no immediate action)

- **`M-rethink-categories`** (post-V1 polish milestone) — drop `TourCategory` enum, derive home rails from `Tour.tags`. Pair with design pass.
- **`M-maker-platform`** (Tier 1 #2 deep dive) — three-phase plan for the in-app maker upload feature. Owner has identified this as a KEY post-V1 feature.
- **`M-content-tooling`** (V1 known follow-up) — manifest-driven CSV uploads, auto-transcription, geocoding, CLI tool. Pre-cursor work for the maker platform.

---

## Tribal knowledge from today's session

(Where reasonable, durable form is in the relevant doc; otherwise here.)

- **gh-pages mechanics.** Audio is pushed to the `gh-pages` orphan branch under `/audio/<filename>.mp3`, served at `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<filename>.mp3`. Workflow: `git checkout gh-pages`, copy file in, commit, push, `git checkout main`. Always check out back to `main` before continuing other work.
- **Audio filename convention** that emerged: `<location-slug>.mp3`, lowercase, dash-separated (e.g. `south-street-seaport-pier-16.mp3`, `metropolitan-museum-fifth-ave-steps.mp3`). The two earliest real tours (Grand Central, Times Square) use slightly different conventions because the convention wasn't yet settled. Don't worry about renaming retroactively.
- **Maker UUID.** All V1 tours use the in-house "Atlas Studio" maker: `00000000-0000-0000-0000-000000000001`. Reuse this `makerId` for new V1 tours.
- **JSON insertion approach.** `Tours.json` uses inline tag arrays (e.g. `"tags": ["a", "b", "c"]`). Python's `json.dumps(d, indent=2)` reformats these to multi-line, producing a noisy diff. Use **string-level insertion** instead: read the file, find the `"  ]\n}\n"` footer, splice in the new tour block before it. The pattern is in `/tmp/add_tour.py` from this session (not committed; regeneratable).
- **`What to Test` is a per-build field**, not app-level. Filled in via App Store Connect → TestFlight tab → click the build → Test Information. Won't appear until a build is processed.
- **Network policy.** This remote environment can't fetch `github.io` URLs (returns 403 `host_not_allowed`). Audio URLs work fine on phones and laptops; just couldn't verify from the container during the session. Don't be surprised by that.
- **`ITSAppUsesNonExemptEncryption = NO`** is now set in both Debug and Release. No more per-archive yes/no dialog from Xcode.
- **App icon caveat.** The placeholder is in the **universal iOS slot** only. Dark/tinted/macOS slots are intentionally empty in `Contents.json` — iOS falls back to universal for appearance variants, and the first build ships iOS-only. If you add platforms later, fill those slots.

---

## How to resume from a fresh / local Mac session

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"
git fetch
git checkout main
git pull --ff-only
git status                      # should be clean
git log --oneline -10           # latest should be f71913b or newer
git branch -a                   # any in-flight feature branches?
```

Then read in this order:

1. **`CLAUDE.md`** § Current State + § Session-start ritual
2. **`ROADMAP.md`** § "Where we are right now" + § M-qa checklist
3. **This file** (`archive/HANDOFF-260519.md`) for what's queued
4. **`docs/troubleshooting.md`** if anything weird happens with Xcode or git

You're picking up at the Mac-side work above. The browser-side App
Store Connect setup is already done — don't redo it.

---

## What to tackle first next session (Claude's suggestion)

1. **Run the session-start ritual** above and confirm state matches this handoff.
2. **Open Xcode → set Team for both targets → Archive → Upload.** That's the longest pole. ~30 minutes including processing wait.
3. **While App Store Connect processes the build:** paste the "What to Test" text once the build appears, then add yourself as Internal Tester.
4. **Install TestFlight on iPhone → install Atlas → walk the M-qa 10-step checklist.** This is the real validation gate.
5. **End of session:** rewrite this handoff for the new date as `archive/HANDOFF-260520.md` (or whenever) capturing the M-qa results. Update `archive/README.md` to point at it.

---

## File map (where things live)

```
TRAVEL GUIDED TOUR/                    # repo root
├── CLAUDE.md                          # durable project guidance
├── ROADMAP.md                         # V1 plan + milestone status
├── CONTRIBUTING.md                    # onboarding for new contributors
├── atlas_claude_code_prompt.md        # canonical product spec
├── docs/
│   ├── authoring-tours.md
│   ├── Tours.template.json
│   ├── cdn-decision.md
│   ├── design-tokens.md               # ← new this session (PR #36)
│   └── troubleshooting.md
├── archive/
│   ├── README.md                      # ← updated this session to point here
│   ├── HANDOFF-260519.md              # ← THIS FILE (active handoff)
│   ├── HANDOFF-260518.md              # ← previous handoff (historical)
│   └── pre-qa-audit-260518.md
├── scripts/
│   └── validate-tours.swift
├── .github/workflows/ci.yml
├── TRAVEL GUIDED TOURTests/
└── TRAVEL GUIDED TOUR/
    ├── Models/                        # Tour, Stop, Maker, etc.
    ├── Data/                          # DataService, LibraryStore, etc.
    ├── Audio/                         # AudioPlayerService, TourDownloader
    ├── Location/                      # LocationManager, ProximityMonitor
    ├── Features/                      # Home, Tour, Player, Search, Maker, Library, Settings
    ├── Components/                    # HeroImageView, TagChip, BottomSheet, AtlasTabBar
    ├── Theme/                         # AtlasColors/Typography/Spacing (placeholders)
    ├── Assets.xcassets/
    │   └── AppIcon.appiconset/
    │       └── atlas-icon-1024.png    # ← new placeholder this session
    └── Resources/Tours.json           # 12 entries: 2 seed + 10 real
```

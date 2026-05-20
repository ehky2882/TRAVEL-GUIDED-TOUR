# Atlas — Handoff Notes (2026-05-19, end of day, consolidated)

Snapshot of where the project is at the close of 2026-05-19. Read this
from any machine — GitHub web, fresh `git clone`, new Claude session
on a different host — to pick up tomorrow with full context. Companion
to `CLAUDE.md` (durable rules), `ROADMAP.md` (milestone status), and
`docs/testflight.md` (TestFlight upload runbook).

> **Note on file history.** This file consolidates two sessions on
> 2026-05-19:
> 1. **Morning remote session** (work computer, no Mac): TestFlight
>    prep code work + browser-side App Store Connect setup.
> 2. **Evening local Mac session**: Xcode signing setup + Archive +
>    Upload to App Store Connect.
>
> The morning version of this file (covering only the first session)
> is preserved in `git log -- archive/HANDOFF-260519.md`. This file
> is rewritten end-of-day rather than appended to.

---

## What shipped today (`main` is at `69444ec` or later)

### Morning remote session (PRs #36–#47)

| PR | What |
|---|---|
| #36 | TestFlight prep: app icon placeholder (1024×1024 PNG), `ITSAppUsesNonExemptEncryption = NO`, `docs/design-tokens.md` |
| #37–43, #45 | **8 new real tours** added. Total ~26 min of audio: South Street Seaport · Empire State Building · Statue of Liberty · Brooklyn Bridge · Rockefeller Center · Met 5th Ave Steps · High Line · 9/11 Memorial |
| #44 | ROADMAP: added `M-rethink-categories` polish milestone |
| #46 | ROADMAP: expanded Tier 1 #2 (maker platform) three-phase plan; added `M-content-tooling` |
| #47 | Morning handoff doc itself |

### Evening local Mac session (PR #48 + the TestFlight upload)

| PR / Action | What |
|---|---|
| #48 | `docs/testflight.md` upload runbook (TL;DR + vocabulary + versioning + adding-device + 6 troubleshooting incidents from tonight) + `DEVELOPMENT_TEAM = CPC7M72JTP;` persisted in `project.pbxproj` |
| (off-repo) | **iPhone 17 Pro registered with team** (UDID `00008150-001430EA1408401C`) |
| (off-repo) | **Developer Mode enabled on iPhone** |
| (off-repo) | **Apple Distribution certificate created** in Keychain (via Xcode → Settings → Accounts → Manage Certificates) |
| (off-repo) | **Archive built and uploaded** to App Store Connect, version 1.0 build 1, today at ~9:38 PM |

### Browser-side App Store Connect work (completed today)

(From the morning session — preserved here so tomorrow's session
doesn't redo it.)

- Apple Developer: App ID `com.ehky.TRAVEL-GUIDED-TOUR` registered
- App Store Connect: app record created
- App Information filled (subtitle, promotional text, keywords, multi-paragraph description, privacy policy URL)
- App Privacy questionnaire **published** ("No" to all data collection)
- TestFlight → Test Information: beta description + feedback email filled
- Privacy policy hosted at `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/privacy/`

The "What to Test" field is **drafted but not yet pasted** — that
field only appears in App Store Connect after the first build is
processed. **Pick this up tomorrow.** Text is re-derivable from the
M-qa 10-step checklist in `ROADMAP.md`.

---

## Where we are right now (waiting for Apple)

- ⏳ Build `1.0 (1)` was uploaded to App Store Connect at 9:38 PM 2026-05-19.
- ⏳ Apple's automated processing typically takes 15–30 minutes — may finish overnight or before tomorrow's session.
- ✉️ Apple will send an email titled "Your build has finished processing" when ready.
- After that, the build appears in App Store Connect → TestFlight tab and can be distributed to internal testers.

**The session ended before processing finished.** Status as of bedtime:
unknown / probably still processing. Check email first thing tomorrow.

---

## Tomorrow's queue (in order)

### 1. Check Apple's processing status

- Open email → look for "Your build has finished processing" (or rejection notice)
- If success: proceed to step 2
- If rejection: the email will have a specific reason (common: missing icon size, encryption declaration). See `docs/testflight.md` § Troubleshooting § "Build processing on Apple's side takes >60 min" for fixes.

### 2. Complete TestFlight setup in App Store Connect

In browser at https://appstoreconnect.apple.com → your app → TestFlight tab:

- Click on the processed build (1.0/1)
- **Paste "What to Test" notes.** Reasonable content for v1.0 build 1:
  > First TestFlight build of Atlas. Please walk through the 10-tour catalog (New York landmarks). Tap a tour pin or list card → start playback → confirm audio plays. Try locking the phone — audio should continue with lock-screen controls. If you walk near a multi-stop tour, confirm GPS triggers next stop's audio. Report anything that crashes, looks wrong, or feels confusing.
- **Internal Testing group** → add your Apple ID as an Internal Tester (if not already added during the morning setup)
- New build auto-distributes to internal testers within a few minutes

### 3. Install on iPhone via TestFlight

- On iPhone: install the **TestFlight app** from the App Store (if not already)
- Open TestFlight → there should be a notification for Atlas → tap **Accept** → tap **Install**
- App appears on home screen as "Atlas" with the placeholder green-sphere icon

### 4. Run the M-qa 10-step checklist on real device

From `ROADMAP.md` § M-qa:

1. App launches → map-dominant home with pins, search bar, drawer with tours
2. Pan the map → location-anchored rails recompute
3. Tap search bar → results screen works; opening a tour adds to "Because you searched X" rail
4. Tap a tour → tour detail → Start → audio plays
5. Lock phone → audio continues; lock-screen controls work
6. Multi-stop geofenced tour → simulated walking → next stop's audio triggers
7. Multi-stop manual tour → tap next stop in player → its audio plays
8. Download a tour → airplane mode → tour plays end-to-end
9. Save a tour → force-quit + relaunch → still saved
10. Maker page → tour list correct → tap tour → tour detail opens

**Goal of M-qa:** confirm V1 is shippable as-is, or surface specific
bugs that need fixing before public release.

### 5. End-of-day tomorrow

- Bugs found during M-qa → file individual PRs (or batch into a cleanup PR if many)
- If V1 is shippable: start thinking about App Store review submission (separate from TestFlight; requires App Store screenshots + final marketing)
- Rewrite this handoff for tomorrow's date (`HANDOFF-260520.md`) capturing M-qa results + any new state
- Update `archive/README.md` to point to the new active handoff

---

## V1 work outstanding beyond TestFlight + M-qa

- **M-launch-content** — currently 10 of 5–15 tours (8 real + 2 seed). Owner may decide to ship V1 with these, or add more. Seed tours could be dropped if not wanted in launch catalog.
- **M-qa P1 cleanup batch** — five P1 audit findings still open (P1-1 sort key, P1-2 avatar URL, P1-3 player-tour ID, P1-4 HeroImageView remote loading, P1-7 dateline bug). Intended as one cleanup PR before M-qa runs on device. Can also be addressed reactively if M-qa surfaces them as actual blockers.
- **Deferred polish pass** — theme tokens, app icon (replace placeholder green sphere), custom map pins, final editorial copy.

### Hero image carousel (Option A, locked but deferred)
Owner agreed on Option A (additive `additionalImageURLs: [String]` field alongside existing `heroImageURL`). Deferred until real images are ready. ~1 hour of code when triggered.

### Decisions captured in ROADMAP (post-V1)
- `M-rethink-categories` — drop `TourCategory` enum, derive home rails from `Tour.tags`. Pair with design pass.
- `M-maker-platform` — Tier 1 #2 deep dive, three-phase plan, owner-flagged as key post-V1 feature.
- `M-content-tooling` — manifest CSV uploads, auto-transcription, geocoding (pre-cursor to maker platform).

---

## Tribal knowledge from tonight's session

(Durable form is in `docs/testflight.md` § Troubleshooting; quick recap here.)

- **Apple's first-time signing gauntlet has many steps.** Plug in iPhone → Trust → Settings → Privacy & Security → Developer Mode → Restart → Confirm → Xcode auto-registers device → Try Again on signing → Archive works. See `docs/testflight.md` § "Adding a new physical device."
- **Disk space matters.** Mac was at 99% capacity (192 MB free) at start of session; this caused `dyld_shared_cache_extract_dylibs failed` when connecting the iPhone. Cleaning `~/Library/Developer/Xcode/DerivedData/*` and `~/Library/Developer/Xcode/iOS DeviceSupport/*` freed 10 GB. **Keep an eye on disk space — 99% on a 460 GB SSD is APFS hiding things in snapshots/caches.** Apple menu → About This Mac → Storage → Manage shows the breakdown.
- **`DEVELOPMENT_TEAM = CPC7M72JTP` is now in `project.pbxproj`.** Future fresh clones inherit signing config (assuming the same Apple Developer team is signed in to Xcode → Settings → Accounts on that machine).
- **Automatic Signing tries to generate both Development AND Distribution profiles** at build time. The Development one needs ≥1 registered device on the team, even if you only care about Archive. Plugging in any device once registers it and unblocks both.
- **Future TestFlight uploads will take ~10 minutes active time**, not 4 hours like tonight. See `docs/testflight.md` § TL;DR. No phone-plugging, no signing dance — just bump build number, Archive, Distribute, Upload.

---

## How to resume from a fresh / remote Mac session

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"
git fetch
git checkout main
git pull --ff-only
git status                      # should be clean
git log --oneline -10           # latest should be 69444ec or newer
git branch -a                   # any in-flight feature branches?
```

Read in this order:

1. **`CLAUDE.md`** § Current State + § Session-start ritual
2. **`ROADMAP.md`** § "Where we are right now" + § M-qa checklist
3. **This file** (`archive/HANDOFF-260519.md`) for tomorrow's queue
4. **`docs/testflight.md`** if you're doing another TestFlight upload
5. **`docs/troubleshooting.md`** if anything weird happens with Xcode or git

You're picking up at **Tomorrow's Queue step 1**: check email for Apple's processing notification.

If you're on a **different Mac** from the one used tonight (e.g. a different home machine), you'll need to:
- Sign in to your Apple Developer ID in Xcode → Settings → Accounts (one-time per Mac)
- Confirm Team is set correctly in Signing & Capabilities (DEVELOPMENT_TEAM is in pbxproj, so it should auto-populate)
- The Distribution certificate from tonight is in **the original Mac's Keychain only**. To Archive from a different Mac, you'd either need to export the cert from the original Mac's Keychain and import on the new one, or create a new Distribution cert via Xcode (Manage Certificates → +). For tomorrow's TestFlight tasks though, no new Archive is needed — only browser + TestFlight app work.

---

## What to tackle first next session (Claude's suggestion)

1. **Run the session-start ritual** (in `CLAUDE.md`) and confirm state matches this handoff.
2. **Check email for Apple's processing notification.**
3. **App Store Connect → TestFlight → click the build → paste "What to Test"** (text drafted above in "Tomorrow's queue" § 2).
4. **Install via TestFlight app on iPhone → run M-qa 10-step checklist.**
5. **End of session**: rewrite this handoff as `archive/HANDOFF-260520.md` (or whatever date), capturing M-qa results. Update `archive/README.md` to point at it.

If Apple's processing rejected the build for some reason, the failure
mode + fix is in `docs/testflight.md` § Troubleshooting. Most likely
candidates: missing icon size (we only have universal slot filled),
ITMS-XXXX validation error.

---

## File map (where things live)

```
TRAVEL GUIDED TOUR/                          # repo root
├── CLAUDE.md                                # durable project guidance
├── ROADMAP.md                               # V1 plan + milestone status
├── CONTRIBUTING.md
├── atlas_claude_code_prompt.md              # canonical product spec
├── docs/
│   ├── authoring-tours.md
│   ├── Tours.template.json
│   ├── cdn-decision.md
│   ├── design-tokens.md
│   ├── testflight.md                        # ← TestFlight upload runbook (new tonight)
│   └── troubleshooting.md
├── archive/
│   ├── README.md
│   ├── HANDOFF-260519.md                    # ← THIS FILE (active handoff)
│   ├── HANDOFF-260518.md                    # historical
│   └── pre-qa-audit-260518.md
├── scripts/validate-tours.swift
├── .github/workflows/ci.yml
├── TRAVEL GUIDED TOURTests/
└── TRAVEL GUIDED TOUR/
    ├── Models/, Data/, Audio/, Location/, Features/, Components/, Theme/
    ├── Assets.xcassets/
    │   └── AppIcon.appiconset/atlas-icon-1024.png   # placeholder (universal slot only)
    └── Resources/Tours.json                 # 12 entries: 2 seed + 10 real
```

Off-repo state (in Apple's database):
- App Store Connect: https://appstoreconnect.apple.com
- Apple Developer portal: https://developer.apple.com/account
- Privacy policy: https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/privacy/
- Apple system status (for outages): https://developer.apple.com/system-status/

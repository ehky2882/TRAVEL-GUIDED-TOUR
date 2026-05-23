# CLAUDE.md

## Project: Atlas

GPS-anchored audio tour platform. Makers record audio; consumers browse, download, and play while walking — audio auto-triggers at each stop. Closer to AllTrails than a guidebook.

**Spec:** `atlas_claude_code_prompt.md` — read before product decisions.
**Execution plan:** `ROADMAP.md` — read before implementation decisions.
**V1:** Consumer-side only. No backend, auth, payments, or maker upload.

Multi-platform SwiftUI. iOS 26.2 / macOS 26.2 / visionOS 26.2.

## Claude Automation Rules

These happen **automatically, without the owner asking**. The owner
should never need to say "run the tests," "validate tours," "merge
the PR," "update the docs," or "write a handoff."

| # | Trigger | What Claude does automatically |
|---|---------|-------------------------------|
| 1 | Every session start | Run full git/PR health check (§ Session-start ritual) + read latest HANDOFF file — before any other work |
| 2 | After any edit to `Resources/Tours.json` | Run `swift scripts/validate-tours.swift`; fix errors before continuing |
| 3 | Before pushing any code PR | Run the full unit test suite; fix failures before pushing |
| 4 | Doc-only PR is ready | Create branch → commit → open PR → wait for CI → squash-merge — all in one flow |
| 5 | Session ends (touched code or content) | Update `CLAUDE.md` + `ROADMAP.md` in same commit; write `archive/HANDOFF-YYMMDD.md`; update `archive/README.md` |
| 6 | Stale merged `claude/*` branches detected | Delete them via `git push origin --delete` — no prompting |

## Current State (as of 2026-05-20)

All V1 functionality milestones shipped on `main`. First TestFlight build uploaded (1.0/1, 2026-05-19).

**What's left:** M-qa pass on device via TestFlight → hero image carousel UI (~30–40 min SwiftUI) → design/polish pass → optional more launch-content tours (currently 10 of 5–15).

Key facts:
- 10 real NYC tours in `Resources/Tours.json` + 2 seeds; audio on `gh-pages` branch at `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<file>.mp3`
- Times Square has `heroImageURL` + `additionalImageURLs`; carousel UI not yet built
- Pre-M-qa audit closed (PR #51); see `ROADMAP.md` § M-qa for deferred P3 items
- AppIcon is placeholder (green sphere); AccentColor: terracotta `#B85042` (also placeholder)
- Theme tokens in `Theme/Atlas*.swift` are placeholder values pending design pass

See `ROADMAP.md` for full milestone history. Read latest `archive/HANDOFF-*.md` for mid-flight context from prior session.

## Session-start ritual (automatic — Claude runs this first, every session)

```bash
git fetch && git status && git branch --show-current && git log origin/main..HEAD && gh pr list --state open
ls archive/HANDOFF-*.md | tail -1   # then read that file
```

Run these commands as the first action, before responding to any substantive
request. Read the HANDOFF file output before doing anything else. Investigate
uncommitted changes before acting on them; never blindly add/commit leftovers.

## Merging PRs

**Doc-only / content-only (auto-merge, no owner approval needed):**
`*.md`, `docs/`, `archive/`, `scripts/`, `TRAVEL GUIDED TOURTests/`,
`.github/workflows/`, lint configs, `Resources/Tours.json`.
Claude creates the PR, waits for CI green, then squash-merges — all in one
uninterrupted flow. Owner pre-authorized this class of PR on 2026-05-18.

**Code PRs (wait for owner OK):**
`*.swift` source files, `*.xcodeproj`/`*.pbxproj`, `Assets.xcassets/`.
Open the PR, post a summary, then stop and wait for explicit owner approval.

## Keep Docs in Sync (automatic — no prompting needed)

Every session that ships a milestone, cuts scope, or changes "what's true today"
must update `CLAUDE.md` + `ROADMAP.md` in the same commit — never as a follow-up.
Claude also writes `archive/HANDOFF-YYMMDD.md` (today's date) + updates
`archive/README.md` at the end of any session that touched code or content.
These are non-negotiable; the owner should never have to ask.

## Repo Layout

| Path | Purpose |
|------|---------|
| `atlas_claude_code_prompt.md` | Canonical product spec |
| `ROADMAP.md` | Execution plan + milestone history |
| `docs/authoring-tours.md` | Tour content authoring guide |
| `docs/cdn-decision.md` | Audio hosting decision |
| `docs/design-tokens.md` | Typography/color/spacing reference |
| `docs/testflight.md` | Per-release upload runbook (~10 min) |
| `docs/troubleshooting.md` | Xcode + git landmines from real incidents |
| `scripts/validate-tours.swift` | Validates `Tours.json` — run with `swift scripts/validate-tours.swift` |
| `TRAVEL GUIDED TOURTests/` | 6 XCTest classes, data/logic layer |
| `archive/` | Dated session snapshots |

**validate-tours.swift mirrors `Tour/Stop/Maker/TourCategory.swift` types — update the script in the same commit if any model changes.**

## Build & Run

```bash
# macOS build
xcodebuild -scheme "TRAVEL GUIDED TOUR" -configuration Debug build

# iOS Simulator
xcodebuild -scheme "TRAVEL GUIDED TOUR" -destination "generic/platform=iOS Simulator" build

# Tests
xcodebuild test -scheme "TRAVEL GUIDED TOUR" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
  -configuration Debug
```

**Run tests automatically before pushing any code PR.** No exceptions for covered layers (`Models/`, `Data/`, `Audio/`, `Location/`). Skip for doc-only, CI-only, `Features/`/`Components/`/`Theme/`-only, or `Tours.json` content-only changes — CI covers those.

## Architecture

```
TRAVEL GUIDED TOUR/
├── TRAVEL_GUIDED_TOURApp.swift    App entry + SwiftUI Environment setup
├── ContentView.swift              AtlasTabBar — 3 tabs: Home / Library / Me
├── SplashView.swift
├── Models/                        Tour, Stop, Maker, TourCategory, RecentSearch, LibraryEntry
├── Data/                          DataService, LibraryStore, RecentSearchStore, RecentlyViewedStore, ToursData
├── Resources/Tours.json
├── Audio/                         AudioPlayerService (AVQueuePlayer + lock-screen), TourDownloader
├── Features/
│   ├── Home/                      HomeView, HomeMapSection, HomeRailsViewModel, RailCarousel
│   ├── Search/                    SearchBar, SearchView
│   ├── Tour/                      TourDetailView
│   ├── Player/                    PlayerView
│   ├── Maker/                     MakerView
│   ├── Library/                   LibraryView
│   └── Settings/                  SettingsView, ManageDownloadsView
├── Location/                      LocationManager, ProximityMonitor
├── Components/                    HeroImageView, TagChip, BottomSheet, PlatformHelpers
├── Theme/                         AtlasColors, AtlasTypography, AtlasSpacing
└── Assets.xcassets/
```

Environment services (instantiated once at app entry, injected via SwiftUI Environment — never instantiate inside views): `DataService`, `LibraryStore`, `RecentSearchStore`, `RecentlyViewedStore`, `LocationManager`, `AudioPlayerService`, `TourDownloader`.

## Conventions

- `@Observable` not `ObservableObject`. `NavigationStack` not `NavigationView`.
- Hero images: use `Components/HeroImageView.swift` — never raw `AsyncImage`.
- Audio: always through `AudioPlayerService`. Never create `AVPlayer` in a view.
- No third-party libraries in V1. Apple frameworks only: SwiftUI, MapKit, CoreLocation, AVFoundation, MediaPlayer, SwiftData/UserDefaults.
- Design tokens: use `AtlasColors.*`, `AtlasTypography.*`, `AtlasSpacing.*`. No hardcoded colors/fonts/padding.
- Support Dynamic Type and Dark Mode.

## Design System

Tokens in `Theme/` are single source of truth; current values are placeholders pending the deferred design pass. Accent `#B85042` is also placeholder. Build for function first — design pass comes after V1.

## Build Config

- Bundle ID: `com.ehky.TRAVEL-GUIDED-TOUR`
- Swift 5.0; deployment targets iOS 26.2 / macOS 26.2 / visionOS 26.2
- Device families: iPhone, iPad, Apple Vision; code signing automatic, team `CPC7M72JTP`
- Info.plist keys: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `UIBackgroundModes=audio`, `ITSAppUsesNonExemptEncryption=NO`

## Out of Scope for V1

No: backend/API, user accounts/auth, in-app maker upload, payments/IAP, moderation, comments/reviews/ratings, follow/sharing/social, push notifications (local geofence notifications OK), onboarding tutorial, in-app search, analytics SDK. Don't introduce any of these without a spec update.

# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

> **How to read this file (for the human owner):** every technical term has
> a plain-English analogy in parentheses right after it. The file is dense
> on purpose because Claude reads it at the start of every session — but you
> should be able to read along by leaning on the analogies. If a sentence
> still doesn't make sense after the analogy, that's a bug — ask Claude to
> rewrite it.

## Project Overview

The **product** is **Atlas** — a creator platform for **GPS-anchored
audio tours**. Makers record audio about a place (a single piece on
one location, or a multi-stop walking tour); consumers browse tours
near them, download for offline listening, and play them while
walking — with audio that automatically triggers at each stop. Shape
of the product is closer to AllTrails or Atlas Obscura than to a
guidebook. (See `atlas_claude_code_prompt.md` for the canonical
spec.)

> **Pivot history (May 2026):** Atlas was *originally* spec'd as an
> "editorial city guide" (Monocle-style). The product pivoted to
> the audio-tour creator platform described above. The reshape is
> complete on `main` — the old `SeedData.json` / `City` / `Place`
> code is gone; the audio-tour data model, audio engine, and
> feature views are in. The Xcode project folder name —
> `TRAVEL GUIDED TOUR` — is now more on-point than it was originally;
> in code, copy, and conversation the product is Atlas.

**V1 is consumer-side only.** Atlas team creates the launch content;
no backend, no auth, no payments, no in-app maker upload. See
`atlas_claude_code_prompt.md` § V1 scope.

The canonical product spec is `atlas_claude_code_prompt.md` at repo
root — read it before making product decisions. The execution plan
is `ROADMAP.md` at repo root — read it before making implementation
decisions.

Multi-platform SwiftUI app (SwiftUI = Apple's modern toolkit for building
app screens — think LEGO bricks for iPhone interfaces). Runs on iOS 26.2
(iPhone/iPad), macOS 26.2 (Mac), visionOS 26.2 (Apple Vision Pro headset)
— same app body, three different "TVs" it can play on.

## Current State (V1 functionality complete; M-qa UX fixes merged; TestFlight build 1.0 (5) uploaded)

Every V1 functionality milestone in `ROADMAP.md` is shipped on `main`.
The AllTrails-style home redesign landed via PR #31 on 2026-05-18 and
is now the production home. On 2026-05-19, the first TestFlight build
(1.0/1) was uploaded to App Store Connect. On 2026-05-20, the pre-M-qa
audit cleanup batch shipped via PR #51 — closing all remaining P1
findings, the actionable P2 findings (accessibility + locale-aware
formatters), three small P3 findings, and adding the Option A data
layer for the hero image carousel (`additionalImageURLs: [String]?`).
On 2026-05-20 M-qa on device uncovered a critical bug: `UIBackgroundModes: audio`
was silently dropped from the compiled Info.plist because Xcode ignores
`INFOPLIST_KEY_UIBackgroundModes` for array-type keys. Fixed by creating an
explicit `Info.plist` at repo root and switching both app target configs to
`GENERATE_INFOPLIST_FILE = NO` + `INFOPLIST_FILE = Info.plist`; shipped via
PR #53. M-qa background-audio step passed on build 1.0/3. On 2026-05-20
evening a Mac session shipped — directly to `main` — home-screen UX work
(unified opaque island, expanded default drawer, map-pan retraction, taller
peek), the PlayerView image carousel, the location-button rework (Apple-style
tracking-mode cycling + blue user dot), MakerView avatar/thumbnail fixes, and
the seed-tour / ESB-GPS / hero-image fixes, then uploaded TestFlight build
**1.0 (4)** carrying all of it.
On 2026-05-21 the first on-device M-qa pass ran against build 1.0 (4):
core flows (launch, search, playback, lock-screen, offline, save,
maker page) passed. The M-qa fixes, a large simulator-review polish
batch, a CI fix (build + test now run on the `macos-26` runner so CI
uses the Xcode 26 toolchain the project targets — Xcode 16 miscompiled
the iOS-26 SwiftUI), and 9 new tours all shipped via **PR #54**,
squash-merged to `main` on 2026-05-22. TestFlight build **1.0 (5)**
was uploaded 2026-05-22; an on-device M-qa pass against it the same
day cleared every applicable check with **no issues found** — V1
functionality is device-validated.
What's left for V1: a **multi-stop walking tour** (the only M-qa
steps still open are the multi-stop ones — geofenced stop advancement
and manual next-stop — blocked because all 20 tours are single-stop),
and the deferred **design / polish pass**.

What's true today (2026-05-22):

- `ContentView.swift` uses a custom `AtlasTabBar` (3 tabs: **Home /
  Library / Me**). A persistent **mini-player**
  (`Features/Player/MiniPlayerBar.swift`) sits directly above the tab
  bar **at all times** — showing the active tour (inline pause/resume,
  tap to open the full player) or a muted "Nothing playing" idle
  state. The mini-player is a square-cornered rectangle; the tab bar
  has square top corners + phone-radius bottom corners, so the two
  stack into one bottom "island." The home drawer's peek height grows
  to clear the mini-player.
- `Features/Home/` is the AllTrails-style layout: full-screen map +
  filter chip row + vertical tour list in a persistent bottom drawer
  + a floating location button (Apple-style: tapping cycles none →
  follow → follow-with-heading; falls back to a custom button because
  `MapUserLocationButton` does not render reliably as a free-floating
  view).
- `Resources/Tours.json` has **20 tours** (all single-stop): the
  original 10 NYC landmarks (Grand Central, Times Square, South Street
  Seaport, Empire State Building, Statue of Liberty, Brooklyn Bridge,
  Rockefeller Center, Met, High Line, 9/11 Memorial), Brooklyn Museum,
  and 9 added 2026-05-21/22 — Whitney, AMNH, Brooklyn Bridge Park,
  Chrysler Building, Flatiron Building, Governors Island, Guggenheim,
  Intrepid (NYC), and Casa da Música (Porto — the first non-NYC tour).
  Audio hosted on the `gh-pages` branch (served at
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<file>.mp3`);
  GitHub Releases tried first but serves the wrong MIME type — see
  `docs/cdn-decision.md`. **No multi-stop tour exists yet** — M-qa's
  multi-stop checks need one authored.
- **Photographic content + carousel shipped** (2026-05-20): 3 Times Square
  photos on `gh-pages` at `/images/`. Times Square tour uses a real
  `heroImageURL` and populates `additionalImageURLs: [String]?`. Both
  `TourDetailView` and `PlayerView` render all images as a paged
  `TabView(.page)` carousel (inset from screen edges with corner radius)
  when `additionalImageURLs` is non-empty, otherwise fall back to the
  single `HeroImageView`. `HeroImageView` fixed to properly constrain
  `scaledToFill()` layout so card sizing is stable in all contexts.
  The home drawer's `TourListCard` carousels multi-image tours too,
  and `TourDetailView`'s hero images are pinch-to-zoom.
- **Pre-M-qa audit closed** (PR #51, 2026-05-20). P0 findings closed
  earlier; P1 batch (5 findings: sort key, avatar, player-tour ID,
  remote image loading, antimeridian), P2 cleanup (BottomSheet
  VoiceOver, location-denied deep link, locale-aware
  `AtlasFormatters`), and P3 small fixes (permission gate, search
  tag/description matching, alphabetical ManageDownloads) all
  shipped. P3-4 download retry with exponential backoff also
  shipped. A few P3 items intentionally deferred — see
  `ROADMAP.md` § M-qa for the live checklist.
- **Audio playback** runs through `Audio/AudioPlayerService.swift`
  (AVQueuePlayer + lock-screen integration + audio session
  interruption + headphone-unplug handling).
  `UIBackgroundModes` → `audio` is enabled.
- **Offline playback** runs through `Audio/TourDownloader.swift`;
  managed from Settings → Manage Downloads.
- **Geofencing** ships with both
  `NSLocationWhenInUseUsageDescription` and
  `NSLocationAlwaysAndWhenInUseUsageDescription` set; foreground
  notifications display via a `UNUserNotificationCenterDelegate`.
- **Appearance toggle** in Settings (System / Light / Dark) backed
  by `@AppStorage("colorSchemePreference")`, applied app-wide via
  `.preferredColorScheme(...)` in `TRAVEL_GUIDED_TOURApp.swift`.
- **Unit test target** wired (PR #33) — `TRAVEL GUIDED TOURTests`
  XCTest bundle with 6 test classes; Cmd-U runs locally, same suite
  runs on CI per PR.
- **TestFlight signing wired** (2026-05-19):
  `DEVELOPMENT_TEAM = CPC7M72JTP` in `project.pbxproj`, Apple
  Distribution certificate in macOS Keychain, iPhone UDID registered
  with team, App Store Connect record + privacy policy + App Privacy
  questionnaire all complete. Per-release upload flow documented in
  `docs/testflight.md` (~10 min active per upload).
- `Assets.xcassets/AppIcon.appiconset/atlas-icon-1024.png` is a
  **placeholder** (green sphere on black). Universal iOS slot only —
  dark/tinted/macOS slots empty. M-polish-icon will replace.
- `Assets.xcassets/AccentColor.colorset` is terracotta `#B85042`
  (light) with a lighter dark-mode variant.
- Theme tokens in `Theme/Atlas{Colors,Typography,Spacing}.swift` are
  still **placeholder values** pending the deferred design pass.

See `ROADMAP.md` for milestone-by-milestone history and remaining
work, the latest `archive/HANDOFF-*.md` for the most recent session
handoff snapshot, `docs/troubleshooting.md` for Xcode + git landmines
documented from real incidents, and `docs/testflight.md` for the
TestFlight upload runbook (per-release ~10-min flow + first-time setup
historical reference). **First session under a new Claude account?**
Also read `archive/ACCOUNT-TRANSFER-260520.md` for cold-start
orientation + working-style notes.

## Keep these docs in sync

**Rule:** every session that ships a milestone, cuts scope, or
changes the "what's true today" state of the project updates
`CLAUDE.md` (this file) and `ROADMAP.md` *in the same commit* —
never as a follow-up.

Concretely, before ending a session that touched feature code,
check whether:
- the **Current State** section above still describes reality
- the **Architecture** folder map still matches the on-disk layout
- the relevant **ROADMAP** milestone is marked ✅ Done (PR #N) and
  any decisions / cuts / follow-ups are recorded

If yes, no doc change needed. If no, fix it in the same commit as
the code change. Stale docs poisoned a recent session (Claude
reported "all milestones done" without knowing about PR #19's home
redesign) — the rule prevents a repeat.

Temporary session-bridge notes don't live at repo root. If a
session needs one, fold the permanent content into `CLAUDE.md` /
`ROADMAP.md` before the session ends and move the snapshot to
`archive/` with a `YYMMDD` suffix (e.g. `archive/HANDOFF-260518.md`).

## Session-start ritual

Before doing anything substantive in a session — especially the
first action that opens Xcode or runs the app — verify the local
state. This prevents the "why doesn't my simulator show last
night's work?" confusion (see `docs/troubleshooting.md` § 1).

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"
git fetch                        # see what's on origin
git status                       # any uncommitted leftovers?
git branch --show-current        # are you on main, or a branch?
git log origin/main..HEAD        # any local commits not pushed?
gh pr list --state open          # any in-flight PRs?
```

Then read the **most recent `archive/HANDOFF-*.md`** —
`ls archive/HANDOFF-*.md | tail -1` to find it. It captures
mid-flight state the repo's permanent docs don't: queued feedback,
what was about to be tackled next, tribal knowledge from the prior
session. Older HANDOFFs in `archive/` are historical — only the
latest is part of this ritual.

If `git status` shows uncommitted changes from a prior session,
investigate before continuing — don't blindly add/commit. The
prior session may have left them deliberately (parked, WIP) or
accidentally (Xcode auto-save, abandoned experiment).

If on a feature branch with un-pushed commits, decide whether to
push, merge, or abandon them before starting new work — switching
branches with un-pushed work loses the work.

## Merging PRs (working rule with the owner)

**Owner pre-authorization (established 2026-05-18):** Claude may
merge **doc-only and content-only PRs** without asking for explicit
per-PR approval, using GitHub's squash-merge. Code PRs (anything
touching `.swift` files inside the `TRAVEL GUIDED TOUR/` source
folder) always wait for owner OK, since they affect the running
app and owner wants to validate visually in the simulator.

Concrete boundary, what counts as doc-only / content-only (auto-mergeable):
- `*.md` files (docs)
- `ROADMAP.md`, `CLAUDE.md`, `CONTRIBUTING.md`
- `docs/`, `archive/`
- `scripts/` (developer tooling, doesn't ship in the app)
- `TRAVEL GUIDED TOURTests/` (test code; doesn't affect the
  running app on phones, only the test target on CI)
- `.github/workflows/` (CI definitions; only run on GitHub's
  servers)
- Lint / tooling configs (`.swiftlint.yml`, etc.)
- `Resources/Tours.json` content additions or edits

What's **not** auto-mergeable — code touching the running app:
- Anything in `TRAVEL GUIDED TOUR/<source-folder>/*.swift`
  (Audio, Components, Data, Features, Location, Models, Theme,
  ContentView, SplashView, App entry)
- The Xcode project file (`*.xcodeproj`, `*.pbxproj`) —
  changes affect what builds
- Asset catalogs (`Assets.xcassets/`) — affect what users see

When in doubt, ask. Better to over-confirm than to merge something
that turns out to be visible to users without their review.

## Repo-root layout

Beyond this file and `ROADMAP.md`:

- `atlas_claude_code_prompt.md` — canonical product spec.
- `CONTRIBUTING.md` — onboarding doc for new contributors:
  toolchain setup, branching/PR workflow, code conventions
  pointer, communication norms.
- `docs/` — reference material that isn't read at session start:
  - `docs/authoring-tours.md` — UI-agnostic field-by-field guide
    for authoring tour content (used in M-launch-content; doubles
    as the spec for the future maker upload form).
  - `docs/Tours.template.json` — example tours showing every field.
  - `docs/cdn-decision.md` — owner-facing brief comparing
    Cloudflare R2 / S3+CloudFront / Apple ODR for V1 audio hosting.
    Owner picks; update the brief's Status line when they do.
  - `docs/design-tokens.md` — single-sheet reference for the
    typographic hierarchy, color palette, spacing scale, and icon
    vocabulary. Mirrors the values in `Theme/Atlas*.swift`; update
    in the same commit when tokens change.
- `scripts/` — developer-facing tooling:
  - `scripts/validate-tours.swift` — runs against
    `TRAVEL GUIDED TOUR/Resources/Tours.json` and catches typos /
    duplicate UUIDs / broken maker refs / kind ↔ stop count
    mismatches / coord-range errors before the app crashes at
    launch. Invoke: `swift scripts/validate-tours.swift`.
    **The script mirrors the Swift data model — if you change
    `Tour.swift` / `Stop.swift` / `Maker.swift` / `TourCategory.swift`,
    update the mirror types at the top of the script in the same
    commit.**
- `TRAVEL GUIDED TOURTests/` — XCTest unit suite for the data /
  logic layer. Wired to the Xcode project as the
  `TRAVEL GUIDED TOURTests` Unit Testing Bundle target (PR #33,
  2026-05-18). Six test classes + `TestFixtures.swift`. Runs on
  `Cmd-U` locally and on CI per PR.
- `.github/workflows/` — CI definitions. `ci.yml` runs three
  jobs on every PR: Tours.json validation (Linux), `xcodebuild build`
  (macOS), and `xcodebuild test` (macOS, conditional on the test
  scheme existing).
- `archive/` — dated snapshots of retired docs (see `archive/README.md`).

## Build & Run

(Build = compile the source files into a runnable app, like baking
ingredients into a cake.)

```bash
# macOS
xcodebuild -scheme "TRAVEL GUIDED TOUR" -configuration Debug build

# iOS Simulator (a fake iPhone running on the Mac for testing)
xcodebuild -scheme "TRAVEL GUIDED TOUR" -destination "generic/platform=iOS Simulator" build

# visionOS Simulator (a fake Vision Pro headset on the Mac)
xcodebuild -scheme "TRAVEL GUIDED TOUR" -destination "generic/platform=visionOS Simulator" build
```

Run the unit test suite:

```bash
xcodebuild test \
  -scheme "TRAVEL GUIDED TOUR" \
  -destination "platform=iOS Simulator,name=iPhone 17,OS=latest" \
  -configuration Debug
```

The `TRAVEL GUIDED TOURTests` Unit Testing Bundle target hosts six
XCTest classes against the data / logic layer (no UI / view tests).
Same suite runs on CI per PR via `.github/workflows/ci.yml`.

**When to run tests (Claude rule):** cadence is trigger-based, not
time-based.

- **Run them when** you've edited code in `Models/`, `Data/`,
  `Audio/`, or `Location/` (the layers tests actually cover), or
  before pushing any code PR, or after rebasing / merging `main`
  into a feature branch, or after resolving a merge conflict in
  code.
- **Skip them when** the change is doc-only, CI-only,
  Xcode-config-only, or only touches `Features/` / `Components/` /
  `Theme/` (no UI tests exist), or only adds `Resources/Tours.json`
  content (the validator script + decoding tests on CI cover this).
- **Don't run them "just to check"** at session start — if no
  covered code changed, nothing has changed.

Typical session: 1–2 runs total, right before pushing each code PR.
CI is the safety net regardless.

## Architecture

(Architecture = the floor plan of the codebase: which folder does what.)

```
TRAVEL GUIDED TOUR/
├── TRAVEL_GUIDED_TOURApp.swift    App entry; sets up environment shelves (services)
├── ContentView.swift              3-tab TabView (Home / Library / Me)
├── SplashView.swift               2-second launch splash
├── Models/
│   ├── Tour.swift                 A tour: title, maker, stops, category, …
│   ├── Stop.swift                 A stop within a tour: lat/lon, audio URL, trigger mode
│   ├── Maker.swift                A maker: display name, avatar, bio, tours
│   ├── TourCategory.swift         Closed enum of categories that drive home rails
│   ├── RecentSearch.swift         Local-only record of a search query
│   └── LibraryEntry.swift         Local "saved / downloaded / progress" record per tour
├── Data/
│   ├── DataService.swift          Loads Tours.json into [Tour] at launch
│   ├── LibraryStore.swift         Read/write store of [LibraryEntry]; persists across launches
│   ├── RecentSearchStore.swift    Local persistence for search history (cap 20)
│   ├── RecentlyViewedStore.swift  Backs the "Recently viewed" quick-resume banner on home
│   └── ToursData.swift            JSON ↔ Swift translator
├── Resources/
│   └── Tours.json                 Seed entries; replaced by real content in M-launch-content
├── Audio/
│   ├── AudioPlayerService.swift   AVQueuePlayer wrapper + lock-screen / Now Playing integration
│   └── TourDownloader.swift       Offline tour caching via URLSession background downloads
├── Features/
│   ├── Home/                      Map-dominant home: full-screen map + tour list in a bottom drawer
│   │   ├── HomeView.swift
│   │   ├── HomeMapSection.swift
│   │   ├── CategoryChipRow.swift
│   │   ├── TourListCard.swift
│   │   ├── HomeRailsViewModel.swift   (unused by the app since the PR #31 redesign; still unit-tested)
│   │   └── RailCarousel.swift         (unused by the app since the PR #31 redesign)
│   ├── Search/                    Search bar + results screen
│   │   ├── SearchBar.swift
│   │   └── SearchView.swift
│   ├── Tour/                      Tour detail screen
│   │   └── TourDetailView.swift
│   ├── Player/                    Full-screen audio player + persistent mini-player
│   │   ├── PlayerView.swift
│   │   └── MiniPlayerBar.swift
│   ├── Maker/                     Maker bio + their tour list
│   │   └── MakerView.swift
│   ├── Library/                   Saved / Downloaded / Recently played
│   │   └── LibraryView.swift
│   └── Settings/                  "Me" tab + Manage Downloads
│       ├── SettingsView.swift
│       └── ManageDownloadsView.swift
├── Location/
│   ├── LocationManager.swift      GPS reporter — drives "tours near you" sort + distance
│   └── ProximityMonitor.swift     Watches stop geofences; fires when user arrives at a stop
├── Components/                    HeroImageView, TagChip, BottomSheet, PlatformHelpers
├── Theme/                         AtlasColors, AtlasTypography, AtlasSpacing (placeholder values)
└── Assets.xcassets/               AccentColor terracotta #B85042; AppIcon still empty template
```

## Design System

> **Important — owner direction (May 2026):** design and theming decisions
> are **deferred**. Build for functionality first. The final color palette,
> typography, app icon, map-pin style, and editorial tone of all copy will
> be decided after V1 functionality lands. Until then, the rule below
> ensures that swap is cheap when it happens.

The three files in `Theme/` are the **single source of truth** for colors,
fonts, and spacing — like the brand-guidelines PDF on a designer's wall.
Their current *values* are placeholders, but the *structure* is locked in.

- **Always use the tokens, never hardcode values.** New code must reach
  for `AtlasColors.*`, `AtlasTypography.*`, `AtlasSpacing.*` instead of
  literal `Color(red:...)`, `.font(.system(size: 24))`, or `.padding(16)`.
  This is what makes the future design pass a 3-file change instead of a
  60-file change. (Hardcoding = baking a specific color into one screen
  instead of pulling it from the shared palette.)
- The Atlas accent in `Assets.xcassets/AccentColor.colorset` is set to
  terracotta `#B85042` per the original spec, but treat that value as a
  placeholder until the design pass.
- Interim design intent (pending the design pass): spare,
  audio-first, photography-forward where photos exist. Final palette,
  typography, and visual language all TBD. Some specifics from the
  earlier editorial-reader spec — e.g., "no star ratings, no review
  counts" — are *under review* in the audio-tour product, since a
  creator marketplace may eventually need quality signals. Don't
  treat the old principles as locked.

## Data Flow

(Data flow = how information moves from where it's stored to the screen
that displays it.)

`TRAVEL_GUIDED_TOURApp.swift` sets up "shared shelves" the moment the
app launches:

- **DataService** — read-only library of tours and makers, loaded
  from `Resources/Tours.json` at launch.
- **LibraryStore** — read/write storage for the user's saved /
  downloaded / recently-played tours, as `[LibraryEntry]`. Persists
  across launches.
- **RecentSearchStore** — local search history (cap 20), feeds the
  "Because you searched [X]" rail.
- **RecentlyViewedStore** — backs the "Recently viewed" home rail.
- **LocationManager** — the GPS reporter: "you're at lat X, lon Y."
- **AudioPlayerService** — wraps `AVQueuePlayer`, manages the audio
  session, drives lock-screen / Control Center / CarPlay integration.
  Every screen that wants to play audio talks to this.
- **TourDownloader** — manages offline audio caching via
  `URLSession` background downloads.

These shelves are placed in the SwiftUI `Environment` (a hallway shelf
every screen can reach into). Any screen that needs them just says "give
me the DataService off the hallway shelf" — instead of every screen making
its own copy. Don't instantiate these inside individual screens.

## Conventions

(Conventions = house rules. Follow them so the codebase stays consistent.)

- `@Observable` (a label that means "screens watching this object will
  auto-redraw when its data changes" — like a stock ticker), **not** the
  older `ObservableObject`.
- `NavigationStack` (the back/forward stack of screens — like a deck of
  cards you push a new screen onto and pop off to go back), **not** the
  older `NavigationView`.
- For every hero image (the big top photo on a screen), use
  `Components/HeroImageView.swift`. Don't reach for `AsyncImage` (the raw
  Apple "download a photo on the fly" tool) directly — `HeroImageView`
  already wraps it with a placeholder color.
- **No third-party libraries in V1.** Apple frameworks only:
  - SwiftUI — all UI
  - MapKit — Apple Maps as a drop-in building block
  - CoreLocation — GPS + geofencing
  - AVFoundation — audio playback (`AVQueuePlayer` wraps a queue of
    stop-audio clips for a tour)
  - MediaPlayer — `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`
    for lock-screen / Control Center / CarPlay integration
  - SwiftData *or* `Codable` + `UserDefaults` — local library +
    listening progress
- **Audio playback always goes through `AudioPlayerService`.** Don't
  spin up your own `AVPlayer` in a view. The service exists so audio
  session config, lock-screen integration, and queue management happen
  in one place.
- Support Dynamic Type (so users who set bigger text in iOS Settings get
  bigger text in Atlas) and Dark Mode (so the app looks right in both
  light and dark themes).
- Map pins currently use Apple's `Marker` with a SF Symbol — see
  `HomeMapSection.swift`. Custom-designed terracotta pins with
  category/maker glyphs are deferred to M-polish-pins.

## Build Configuration

- **Bundle ID:** `com.ehky.TRAVEL-GUIDED-TOUR` (the unique "phone number"
  Apple uses to identify this specific app).
- **Swift Language Mode:** Swift 5.0 (Swift = the programming language;
  5.0 = the version/edition).
- **Deployment Targets:** iOS 26.2, macOS 26.2, visionOS 26.2 (the *oldest*
  OS versions the app will run on — anything newer also works).
- **Device Families:** iPhone, iPad, Apple Vision.
- **App Sandbox:** Enabled, read-only file access. (Sandbox = a fence
  around the app so it can't reach other apps' files — like a kid's
  playpen. "Read-only" = it can look at files outside the fence but not
  change them.)
- **Code Signing:** Automatic. (Code signing = Apple's tamper-proof seal
  that says "this app really is from this developer." "Automatic" means
  Xcode handles it for us.)
- **Info.plist:** auto-generated from `INFOPLIST_KEY_*` build
  settings (Debug + Release):
  - `NSLocationWhenInUseUsageDescription` — audio-tour-aware copy.
  - `NSLocationAlwaysAndWhenInUseUsageDescription` — set so stop
    geofences can fire while the app is backgrounded / phone locked.
  - `UIBackgroundModes` = `audio` — audio continues playing with
    the phone locked. Without this, audio cuts on lock — fatal for
    a walking-tour app.
  - `ITSAppUsesNonExemptEncryption` = `NO` — Atlas uses only
    standard HTTPS, no custom crypto, so it qualifies for the
    standard export-compliance exemption. Set so Xcode doesn't
    prompt for the answer on every archive.

## Out of Scope for V1

Per `atlas_claude_code_prompt.md` §"What NOT to build in V1":

- **No backend / server / API.** All content ships via a static JSON
  manifest + audio files hosted on a CDN.
- **No user accounts / authentication.** "Sign in" is a placeholder UI
  entry in Settings; real auth is post-V1.
- **No in-app maker upload.** Atlas team edits `Tours.json` and uploads
  audio to the CDN by hand.
- **No payments / IAP / paid tours / maker payouts.** All V1 content is
  Atlas-made and free. The `Tour.priceUSD` field exists in the data
  model so tours can be priced later, but no buy buttons, no purchase
  flow, no payouts in V1.
- **No moderation tooling.** Atlas-made content only.
- **No comments, reviews, or ratings.**
- **No follow-a-maker, sharing, or other social features.**
- **No push notifications.** Local notifications for geofenced stop
  arrivals are allowed — they're how the geofence trigger surfaces
  when the app is backgrounded.
- **No onboarding tutorial.** The app should be self-evident.
- **No in-app search.** The V1 catalog is small enough to browse.
- **No analytics SDK** beyond Apple's built-in App Store Connect
  metrics.

Don't introduce any of these without a spec update.

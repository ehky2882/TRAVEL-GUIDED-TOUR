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

## Current State (V1 functionality complete; pre-polish, pre-launch-content)

Every V1 functionality milestone in `ROADMAP.md` is shipped on `main`
(M1–M3 through M-offline, plus a home-screen redesign in PR #19).
What's left for V1 release: **owner-side content work**
(M-launch-content — record audio + author real `Tours.json`),
**end-to-end QA on a real device** (M-qa), and the deferred
**design / polish pass**. There's also an in-flight
`claude/alltrails-alignment` branch with further home polish; see
`HANDOFF.md` for the current owner-facing snapshot.

What's true today:

- `ContentView.swift` is a 3-tab `TabView` — **Home / Library / Me**.
  (5 → 3 tab cut landed in PR #15: M-map was redundant against
  Home's embedded map, and Messages was absorbed as a row inside
  Settings.)
- `Resources/Tours.json` is the live data source — seed entries only;
  real content arrives in M-launch-content. The old
  `Resources/SeedData.json` is gone.
- **Audio playback** runs through `Audio/AudioPlayerService.swift`
  (AVQueuePlayer + lock-screen integration). `UIBackgroundModes` →
  `audio` is enabled, so audio continues with the phone locked.
- **Offline playback** runs through `Audio/TourDownloader.swift`;
  managed from Settings → Manage Downloads.
- **Geofencing** ships with both
  `NSLocationWhenInUseUsageDescription` and
  `NSLocationAlwaysAndWhenInUseUsageDescription` set, so stop
  geofences can fire while the app is backgrounded / phone locked.
- `Assets.xcassets/AccentColor.colorset` is set to terracotta
  `#B85042` (light) and a lighter variant for dark mode.
- `Assets.xcassets/AppIcon.appiconset` is still the empty Apple
  template. M-polish-icon addresses this.
- Theme tokens in `Theme/Atlas{Colors,Typography,Spacing}.swift` are
  still **placeholder values** pending the deferred design pass.

See `ROADMAP.md` for the milestone-by-milestone history and
`HANDOFF.md` for the current open-work snapshot.

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

No test targets are configured yet. (Tests = automated checks that re-run
after every change to confirm nothing broke. We don't have any yet.)

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
│   ├── RecentlyViewedStore.swift  Backs the "Recently viewed" home rail
│   └── ToursData.swift            JSON ↔ Swift translator
├── Resources/
│   └── Tours.json                 Seed entries; replaced by real content in M-launch-content
├── Audio/
│   ├── AudioPlayerService.swift   AVQueuePlayer wrapper + lock-screen / Now Playing integration
│   └── TourDownloader.swift       Offline tour caching via URLSession background downloads
├── Features/
│   ├── Home/                      Map-dominant home: full-screen map + curated rails in a bottom sheet
│   │   ├── HomeView.swift
│   │   ├── HomeMapSection.swift
│   │   ├── HomeRailsViewModel.swift
│   │   └── RailCarousel.swift
│   ├── Search/                    Search bar + results screen
│   │   ├── SearchBar.swift
│   │   └── SearchView.swift
│   ├── Tour/                      Tour detail screen
│   │   └── TourDetailView.swift
│   ├── Player/                    Full-screen audio player (modal sheet)
│   │   └── PlayerView.swift
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

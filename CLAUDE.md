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
> the audio-tour creator platform described above. Most of the
> existing code (`SeedData.json`, `CityDetailView`, `PlaceDetailView`,
> etc.) is being reshaped to fit. The Xcode project folder name —
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

## Current State (mid-pivot to audio tours)

The app's *structural shell* is built — 5-tab `TabView`, location
permission configured, environment-shelf dependency injection in
place, terracotta accent color in `Assets.xcassets`, theme tokens
ready (with placeholder values). The *content layer and most feature
views* are being rebuilt to fit the audio-tour spec. See `ROADMAP.md`
§ Where we are right now for the file-by-file migration map.

What's true today:

- `ContentView.swift` is a 5-tab `TabView` (Home / Explore / Favorites
  / Messages / Me). Tab *contents* will change as new feature views
  land; the skeleton stays.
- `Resources/SeedData.json` still holds the old 45-place editorial
  catalog. It gets replaced by `Resources/Tours.json` in
  M-data-model.
- **Location permission** is configured via the
  `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` build setting
  in `project.pbxproj` (Debug + Release). Copy will likely be
  tweaked during M-home to match the audio-tour framing.
- `Assets.xcassets/AccentColor.colorset` is set to terracotta
  `#B85042` (light) and a lighter variant for dark mode.
- `Assets.xcassets/AppIcon.appiconset` is the empty Apple template.
  A polish milestone addresses this.
- Theme tokens in `Theme/Atlas{Colors,Typography,Spacing}.swift` are
  **placeholder values** (currently all-white/all-black/Helvetica
  12pt) pending the deferred design pass.
- **Audio playback infrastructure does not yet exist.** It lands in
  M-audio-foundation, including the `UIBackgroundModes` → `audio`
  build setting.

See `ROADMAP.md` for the milestone-by-milestone plan.

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

> Legend for the folder map below:
> ✅ stays as-is across the pivot
> 🔄 reshaped or renamed during the audio-tour migration
> ❌ being deleted (old editorial-reader code)
> 🆕 doesn't exist yet; lands in a future milestone

```
TRAVEL GUIDED TOUR/
├── TRAVEL_GUIDED_TOURApp.swift    ✅ App entry; sets up environment shelves (services)
├── ContentView.swift              ✅ 5-tab TabView; tab contents swap as views land
├── SplashView.swift               ✅ 2-second launch splash
├── Models/
│   ├── City.swift                 ❌ delete in M-data-model
│   ├── Place.swift                ❌ delete in M-data-model
│   ├── PlaceCategory.swift        ❌ delete in M-data-model
│   ├── PlaceCollection.swift      ❌ delete in M-data-model
│   ├── Tour.swift                 🆕 added in M-data-model — a tour: title, maker, stops, …
│   ├── Stop.swift                 🆕 a stop within a tour: lat/lon, audio URL, trigger mode
│   ├── Maker.swift                🆕 a maker: display name, avatar, bio, tours
│   ├── TourCategory.swift         🆕 closed enum of tour categories that drive home rails
│   ├── RecentSearch.swift         🆕 local-only record of a search query (for "Because you searched [X]" rail)
│   └── LibraryEntry.swift         🆕 a local "saved/downloaded/progress" record per tour
├── Data/
│   ├── DataService.swift          🔄 reshaped in M-data-model to load Tours.json
│   ├── CollectionStore.swift      🔄 renamed → LibraryStore (data shape changes)
│   ├── RecentSearchStore.swift    🆕 M-search — local persistence for search history
│   └── SeedData.swift             🔄 renamed → ToursData (the JSON ↔ Swift translator)
├── Resources/
│   ├── SeedData.json              ❌ deleted in M-data-model
│   └── Tours.json                 🆕 added in M-data-model; populated in M-launch-content
├── Audio/                         🆕 brand new folder
│   ├── AudioPlayerService.swift   🆕 AVQueuePlayer wrapper + lock-screen integration (M-audio-foundation)
│   └── TourDownloader.swift       🆕 offline tour caching via URLSession (M-offline)
├── Features/
│   ├── Discover/                  ❌ replaced by Home/ in M-home
│   ├── City/                      ❌ deleted in M-data-model (no "city" entity in this product)
│   ├── Place/                     ❌ replaced by Tour/ in M-tour-detail
│   ├── Home/                      🆕 M-home — map-dominant home: map at top + curated rails below
│   ├── Search/                    🆕 M-search — search bar + results screen
│   ├── Tour/                      🆕 M-tour-detail — tour detail screen
│   ├── Player/                    🆕 M-player — full-screen audio player
│   ├── Maker/                     🆕 M-maker — maker bio + their tour list
│   ├── Library/                   🆕 M-library (replaces Collections/) — saved + downloaded + recent
│   ├── Map/                       🔄 in M-map — may be cut entirely if Home's embedded map is enough; owner decides
│   │   ├── MapView.swift
│   │   └── StopAnnotationView.swift   🔄 renamed from PlaceAnnotationView
│   └── Settings/                  ✅ stays; gets a "Manage downloads" link in M-offline
├── Location/
│   ├── LocationManager.swift      ✅ stays — drives "tours near you" sort + distance
│   └── ProximityMonitor.swift     🔄 reshaped in M-geofencing for stop geofences
├── Components/                    ✅ all stay (HeroImageView, TagChip, PriceIndicatorView, PlatformHelpers)
├── Theme/                         ✅ all stay (placeholder values until design pass)
└── Assets.xcassets/               ✅ AccentColor terracotta #B85042; AppIcon still template
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

- **DataService** — read-only library of tours and makers. (Currently
  still loading the old city/place data; reshaped in M-data-model.)
- **CollectionStore** — read/write storage for the user's saved
  lists. (Renamed to `LibraryStore` in M-library; data shape becomes
  `[LibraryEntry]`.)
- **LocationManager** — the GPS reporter: "you're at lat X, lon Y."
- **AudioPlayerService** — 🆕 added in M-audio-foundation. Wraps
  `AVQueuePlayer`, manages the audio session, drives lock-screen /
  Control Center / CarPlay integration. Every screen that wants to
  play audio talks to this.

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
- Map pins are custom SwiftUI views (`StopAnnotationView` — terracotta
  with category/maker icon), **not** Apple's default red pins.

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
- **Info.plist:** auto-generated from `INFOPLIST_KEY_*` build settings.
  `NSLocationWhenInUseUsageDescription` is set to the standard Atlas
  location-permission copy in both Debug and Release configs.
- **Audio background mode (planned, not yet added):** M-audio-foundation
  adds `UIBackgroundModes` → `audio` to the build settings so audio
  continues with the phone locked. Without this, audio cuts out on
  lock — fatal for a walking-tour app.
- **Always-location entitlement (TBD):** M-geofencing may need
  `NSLocationAlwaysAndWhenInUseUsageDescription` if we want geofenced
  stop triggers to fire while the app is backgrounded. Open question;
  the milestone covers the tradeoff.

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

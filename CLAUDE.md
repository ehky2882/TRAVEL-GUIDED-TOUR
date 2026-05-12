# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

> **How to read this file (for the human owner):** every technical term has
> a plain-English analogy in parentheses right after it. The file is dense
> on purpose because Claude reads it at the start of every session — but you
> should be able to read along by leaning on the analogies. If a sentence
> still doesn't make sense after the analogy, that's a bug — ask Claude to
> rewrite it.

## Project Overview

The **product** is **Atlas** — a curated, editorial discovery app for art,
culture, design, and architecture in cities. Think Monocle city guide as a
native app with location awareness. The Xcode project (the folder Apple's
tool uses to build the app) is named `TRAVEL GUIDED TOUR` for historical
reasons; in code, copy, and conversation the product is Atlas.

The canonical product spec is `atlas_claude_code_prompt.md` at repo root —
read it before making product decisions. The execution plan is `ROADMAP.md`
at repo root — read it before making implementation decisions.

Multi-platform SwiftUI app (SwiftUI = Apple's modern toolkit for building
app screens — think LEGO bricks for iPhone interfaces). Runs on iOS 26.2
(iPhone/iPad), macOS 26.2 (Mac), visionOS 26.2 (Apple Vision Pro headset)
— same app body, three different "TVs" it can play on.

## Current State (V1 in progress)

The architecture is mostly built; the integration is not. **Most feature
views (individual screens of the app) already exist as Swift files but are
not yet wired together** — like having every room of a house framed and
furnished but the hallways aren't connected yet.

- `ContentView.swift` is **a placeholder** — the file the app shows you
  first. Right now it's a search bar, hardcoded filter chips, eight grey
  rectangles, and a custom 5-tab bottom bar with one tab literally labeled
  `???`. It does **not** yet route to the real feature views (the proper
  rooms of the house). The first roadmap milestone replaces it with a
  proper 5-tab bar that opens into the real feature screens (tab content
  TBD by the owner at the start of M1). Do not "polish" the placeholder
  in isolation — it's getting torn down.
- `Resources/SeedData.json` is a stub. JSON is just a structured text file
  holding data — like a spreadsheet written out as a list. The real 45-place
  catalog (NYC, Porto, London) is not yet authored.
- `Info.plist` lacks location privacy strings. (`Info.plist` is the app's
  spec sheet that the iPhone reads before launch — like the nutrition label
  on the back of a cereal box. Apple requires a sentence explaining *why*
  the app wants your location, and that sentence is missing.)
- `Assets.xcassets/AccentColor.colorset` is the default system color, not
  Atlas terracotta `#B85042`. The app icon is the empty Apple template
  (the placeholder square on your home screen).

See `ROADMAP.md` for the milestone-by-milestone plan to close these gaps.

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
├── TRAVEL_GUIDED_TOURApp.swift    The front door — when you tap the icon, this runs first.
│                                  It also sets up the three "shared shelves" (data, collections,
│                                  location) that every screen can reach into.
├── ContentView.swift              ⚠ placeholder; M1 of ROADMAP replaces this with the real tab bar
├── SplashView.swift               2-second launch splash (the loading screen)
├── Models/                        The "shapes" of the data — what a City is, what a Place is, etc.
│   ├── City.swift                 A city: name, country, hero photo, intro, lat/lon, place count
│   ├── Place.swift                A place: name, category, photo, editorial copy, address, hours, …
│   ├── PlaceCategory.swift        The fixed list of place types (gallery, museum, café, …)
│   └── PlaceCollection.swift      A user's saved list ("Tokyo trip", "Favorites")
├── Data/                          The "filing cabinet" — how data gets loaded and saved
│   ├── DataService.swift          Loads SeedData.json on launch and lets screens search/filter
│   ├── CollectionStore.swift      Saves the user's collections to the device so they stick around
│   └── SeedData.swift             The translator that turns the JSON file into Swift objects
├── Resources/
│   └── SeedData.json              ⚠ stub; M2 fills it with 3 cities × ~15 places
├── Features/                      One folder per feature/screen group
│   ├── Discover/                  The home tab — feed of cities and featured places
│   │   ├── DiscoverView.swift
│   │   ├── CityCardView.swift
│   │   └── FeaturedPlaceRow.swift
│   ├── City/                      The "drill into one city" screen
│   │   ├── CityDetailView.swift
│   │   ├── CategoryFilterBar.swift
│   │   └── PlaceGridItem.swift
│   ├── Place/                     The "drill into one place" screen
│   │   ├── PlaceDetailView.swift
│   │   ├── NearbyPlacesSection.swift
│   │   └── OnSiteTipCard.swift   The little card that appears only when you're physically nearby
│   ├── Map/                       The map tab
│   │   ├── MapView.swift          Apple Maps with custom pins for each place
│   │   └── PlaceAnnotationView.swift  The terracotta pin design
│   ├── Collections/               The "Saved" tab
│   │   ├── CollectionsView.swift
│   │   ├── CollectionDetailView.swift
│   │   └── AddToCollectionSheet.swift  The pop-up that asks "save to which list?"
│   └── Settings/
│       └── SettingsView.swift
├── Location/                      The GPS / "where am I?" plumbing
│   ├── LocationManager.swift      Asks the iPhone for the user's location and shares it
│   └── ProximityMonitor.swift     Watches for the user crossing a virtual fence (within ~200m of a place)
├── Components/                    Reusable building blocks — small parts used by many screens
│   ├── HeroImageView.swift        The big top photo on a screen, with a placeholder while it loads
│   ├── TagChip.swift              The little pill-shaped category tag
│   ├── PriceIndicatorView.swift   The "$ / $$ / $$$ / free" indicator
│   └── PlatformHelpers.swift      Code that handles iPhone-vs-Mac-vs-Vision Pro differences
├── Theme/                         The design system — colors, fonts, spacing in one place
│   ├── AtlasColors.swift          THE source of truth for color
│   ├── AtlasTypography.swift      THE source of truth for fonts
│   └── AtlasSpacing.swift         THE source of truth for padding/margins/corner radius
└── Assets.xcassets/               Image catalog (app icon + accent color, both currently default)
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
- The lime-green menu circle and hardcoded paddings in `ContentView.swift`
  are placeholder code — they get deleted in M1, not promoted into the
  design language.
- The Atlas accent is currently terracotta `#B85042` per the original
  spec, but treat that value as a placeholder until the design pass.
- Spec design principles (also placeholders pending the design pass):
  editorial, photography-forward, near-white background, near-black text,
  one accent color, generous whitespace, no star ratings, no review
  counts, no ads.

## Data Flow

(Data flow = how information moves from where it's stored to the screen
that displays it.)

`TRAVEL_GUIDED_TOURApp.swift` sets up three "shared shelves" the moment the
app launches:

- **DataService** — the read-only library of cities and places.
- **CollectionStore** — read/write storage for the user's saved lists.
- **LocationManager** — the GPS reporter: "you're at lat X, lon Y."

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
- **No third-party libraries in V1.** Apple frameworks only: SwiftUI,
  MapKit (Apple Maps as a drop-in building block), CoreLocation (GPS),
  SwiftData (Apple's "save data on the device" toolkit) or `Codable` +
  `UserDefaults` (the simpler "write a note in a kitchen drawer" version).
- Support Dynamic Type (so users who set bigger text in iOS Settings get
  bigger text in Atlas) and Dark Mode (so the app looks right in both
  light and dark themes).
- Map pins are custom SwiftUI views (`PlaceAnnotationView` — terracotta
  with category icon), **not** Apple's default red pins.

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
- **Info.plist:** missing `NSLocationWhenInUseUsageDescription` (the
  one-sentence explanation iOS shows the user when the app first asks for
  location). M3 of the roadmap adds it.

## Out of Scope for V1

Per `atlas_claude_code_prompt.md` §"What NOT to Build in V1":

- No user accounts / login.
- No backend / server / API. (Backend = a computer somewhere on the
  internet that the app talks to. V1 has none — all data ships inside the
  app like a printed cookbook.)
- No push notifications. (Only *local* notifications, which the iPhone
  itself decides to show when you walk near a place — those are allowed.)
- No social features (sharing, following).
- No in-app search (the catalog is small enough to just browse).
- No onboarding tutorial (the app should be self-evident).
- No in-app purchases or subscriptions.
- No audio content (future layer).
- No creator/admin tools (future phase).

Don't introduce these without a spec update.

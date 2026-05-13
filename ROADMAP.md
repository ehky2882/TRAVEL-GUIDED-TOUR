# Atlas — V1 Roadmap

> **How to read this file:** every technical term has a plain-English
> analogy in parentheses so a non-coder owner can follow along. This is a
> **living document** — milestones, scope, and priorities will shift as
> we build. Edit freely.

> **May 2026 pivot note.** This roadmap was reset after the product
> pivoted from "editorial city guide" to "creator platform for audio
> tours." See `atlas_claude_code_prompt.md` for the spec. The earlier
> editorial-reader milestones (M4–M11 in the previous draft) are gone
> because the product shape that needed them is gone. The previous
> roadmap survives in git history if anyone needs to look back.

---

## Owner direction (May 2026)

Principles that override everything else in this file:

1. **Functionality first; design and tone deferred.** Don't burn
   cycles on color palettes, typography, app icons, custom map pins,
   or final editorial tone. Get the audio-tour experience working end
   to end, then polish.
2. **Build so the deferred design pass is cheap.** All new code uses
   `Theme/Atlas{Colors,Typography,Spacing}.swift` tokens even though
   their values are placeholders. The future design decision should be
   a 3-file change, not a 60-file rewrite.
3. **V1 is consumer-side only, backend-free.** Per the spec, payments,
   accounts, and in-app maker upload are post-V1. The V1 UI is built
   in the *shape* of the eventual creator platform so nothing the
   consumer sees needs to be redesigned later.
4. **Review workflow.** Owner reviews via iOS Simulator or TestFlight,
   not by reading code. Each milestone ends in a runnable, reviewable
   state.

---

## Where we are right now

**The product pivoted.** The previous editorial-city-guide V1 work is
mostly being reshaped, not thrown out. What survives:

| Survives the pivot | Status |
|---|---|
| 5-tab `TabView` scaffolding (M1) | ✅ Done — tab *contents* change but the skeleton stays |
| Location permission + `LocationManager` (M3) | ✅ Done — still needed for "near you" + geofencing |
| Environment-shelf pattern (DataService, CollectionStore, LocationManager) | ✅ Done — same pattern, new services slot in |
| `TRAVEL_GUIDED_TOURApp.swift`, splash, project.pbxproj basics | ✅ Done |
| `Components/HeroImageView.swift`, theme tokens, platform helpers | ✅ Done |

What gets replaced or rewritten:

| Replaced | Replaced by | In milestone |
|---|---|---|
| `Models/{City,Place,PlaceCategory,PlaceCollection}.swift` | `Models/{Tour,Stop,Maker,LibraryEntry}.swift` | M-data-model |
| `Resources/SeedData.json` (45 editorial places) | `Resources/Tours.json` (5–15 audio tours; content is owner work) | M-data-model + M-launch-content |
| `Data/DataService.swift` | Reshaped to load tours instead of cities + places | M-data-model |
| `Data/CollectionStore.swift` | Reshaped / renamed to `LibraryStore` | M-library |
| `Features/Discover/` | `Features/Home/` — "Tours near you" feed | M-home |
| `Features/City/` | Mostly cut (no "city as entity" in this product) | M-data-model |
| `Features/Place/PlaceDetailView.swift` | `Features/Tour/TourDetailView.swift` | M-tour-detail |
| `Features/Collections/` | `Features/Library/` (saved + downloaded + recent) | M-library |
| `Features/Map/PlaceAnnotationView.swift` | Repurposed as `StopAnnotationView` | M-map |
| Existing `Location/ProximityMonitor.swift` | Reshaped to monitor stop geofences | M-geofencing |

What's brand new:

- `Audio/AudioPlayerService.swift` — `AVQueuePlayer` wrapper + lock-screen integration
- `Audio/TourDownloader.swift` — offline audio caching
- `Features/Player/PlayerView.swift` — full-screen audio player
- `Features/Maker/MakerView.swift` — maker bio + their tour list
- `UIBackgroundModes: audio` entitlement in the project's Info.plist
  build settings

---

## V1 — Functionality milestones (in execution order)

### M1–M3. Build infrastructure — ✅ Done

These three milestones built the structural shell that survives the
audio-tour pivot. Brief status:

| | Status |
|---|---|
| **M1. Wire ContentView (5-tab TabView)** | ✅ Done in PR #2. Tab *contents* will change in later milestones; 5-tab skeleton stays. |
| **M2. Populate seed data file** | ✅ Done in commit `890b10c`. The 45-place editorial file gets replaced by `Tours.json` in M-data-model — but the infrastructure for loading JSON at launch survives. |
| **M3. Location privacy string** | ✅ Done (build setting). The copy will likely be tweaked for the audio-tour framing during M-home — small change. |

---

### M-data-model. New data model — Tour, Stop, Maker, LibraryEntry

**What:** Add the new Swift model types described in
`atlas_claude_code_prompt.md` § Data Model. Add a one- or two-tour
`Tours.json` for shape testing. Reshape `DataService` to load it.
Delete the old `City` / `Place` / `PlaceCategory` /
`PlaceCollection` models.

**Why:** Every later milestone depends on this shape. The previous
data model doesn't fit the audio-tour product at all.

**Files touched:**
- `Models/Tour.swift`, `Models/Stop.swift`, `Models/Maker.swift`,
  `Models/LibraryEntry.swift` (new)
- `Resources/Tours.json` (new — shape-test content only; real content
  arrives in M-launch-content)
- `Data/DataService.swift` (reshape)
- `Data/SeedData.swift` (rename → `Data/ToursData.swift` or rewrite
  in place)
- `Resources/SeedData.json` (delete once `Tours.json` works)
- `Models/{City,Place,PlaceCategory,PlaceCollection}.swift` (delete)

**Expected fallout:** Most existing views (`DiscoverView`,
`CityDetailView`, `PlaceDetailView`, `MapView`, `CollectionsView`)
break at compile time after the model swap. That's expected — the
next milestones rewrite them. To keep the app buildable mid-milestone,
the views can be stubbed to "Coming soon" placeholders until their
own milestone lands.

**How we know it worked:** App compiles; `DataService` exposes
`tours: [Tour]` on the environment; a debug print confirms tours
loaded.

---

### M-audio-foundation. Audio playback infrastructure

**What:** Wire up audio playback as a foundation every later milestone
will use.

- Add `Audio/AudioPlayerService.swift` (`@Observable`, on the
  environment shelf) wrapping `AVQueuePlayer`.
- Configure `AVAudioSession` with `.playback` category (audio
  continues with phone locked, ducks other audio appropriately).
- Add `UIBackgroundModes` → `audio` to Info.plist build settings.
- Wire `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` for play /
  pause / scrub / skip-forward / skip-backward from lock screen,
  headphones, AirPods, and CarPlay.

**Why:** Audio playback is the product's core feature; everything
downstream is wallpaper around it. Best to get the iOS plumbing right
once.

**Files touched:**
- `Audio/AudioPlayerService.swift` (new)
- `project.pbxproj` (add `UIBackgroundModes` build setting)
- `TRAVEL_GUIDED_TOURApp.swift` (instantiate service, place on
  environment)

**How we know it worked:** A throwaway test view plays a known remote
audio URL → audio plays → lock phone → audio continues → unlock →
lock-screen controls show the playing audio with title/artwork → tap
pause from lock screen → audio pauses.

---

### M-tour-detail. Tour detail screen

**What:** Build `TourDetailView`. Replaces `PlaceDetailView`. Shows
hero image, title, maker (tappable, links to `MakerView`), length,
walking distance, stops list, intro audio, Start / Download / Save
buttons.

**Files touched:**
- `Features/Tour/TourDetailView.swift` (new)
- `Features/Place/` (delete)

**How we know it worked:** A hardcoded navigation entry point opens
the detail for a specific tour ID. All fields render. Tapping Start
calls `AudioPlayerService` and starts playing the intro (or stop 1 if
no intro).

---

### M-player. Full-screen audio player

**What:** The screen consumers will spend the most time on. Shows
hero image, scrub bar, play/pause, speed control (1x / 1.25x / 1.5x /
2x), next-stop / previous-stop, stops list with the current stop
highlighted, and (for geofenced tours) distance-to-next-stop.

**Files touched:**
- `Features/Player/PlayerView.swift` (new)

**How we know it worked:** From `TourDetailView`, tap Start → player
pushes onto navigation stack → audio plays → scrub bar tracks position
→ tapping a different stop jumps playback → "next stop" button
advances correctly.

---

### M-home. "Tours near you" feed + location fallback

**What:** Replace `DiscoverView` with the new home tab. Sorts tours by
distance from the user; falls back to a global browse when the user is
not near any tours, denied location, or has location services off.
Also: tweak the location-permission copy in build settings to match
the audio-tour framing.

**Files touched:**
- `Features/Home/HomeView.swift` (new; or rename + rewrite
  `DiscoverView`)
- `Features/Discover/` (delete after move)
- `ContentView.swift` (point Home tab at the new view)
- `project.pbxproj` (update `NSLocationWhenInUseUsageDescription` copy)

**How we know it worked:** Set simulated location to NYC → home shows
nearby tours sorted by distance. Set simulated location to nowhere →
home shows "no tours nearby, browse all" fallback. Deny location →
same fallback, no crash.

---

### M-map. Map tab — tour stops

**What:** Reshape the existing `MapView` so pins represent **tour
stops** rather than editorial places. Tapping a pin shows a tour
preview card; tapping the card opens `TourDetailView`.

**Files touched:**
- `Features/Map/MapView.swift` (reshape)
- `Features/Map/PlaceAnnotationView.swift` → rename to
  `StopAnnotationView` (keep visual styling minimal for V1 — polished
  pins are a later milestone)

**How we know it worked:** Map tab shows a pin for every stop across
every tour. Tap a pin → preview card → tap card → tour detail opens.

---

### M-maker. Maker page

**What:** New `MakerView` shows avatar, bio, and the list of that
maker's tours. Linked from `TourDetailView`'s maker attribution.

**Files touched:**
- `Features/Maker/MakerView.swift` (new)

**How we know it worked:** From tour detail, tap the maker's name →
maker page renders → tap one of their tours → tour detail opens.

---

### M-library. Library tab — Saved / Downloaded / Recently played

**What:** Replace `CollectionsView` with `LibraryView`. Three sections:
**Saved** (bookmarked tours), **Downloaded** (audio cached on device),
**Recently played** (resume listening). Replace `CollectionStore`
with `LibraryStore` (data shape changes from `[PlaceCollection]` to
`[LibraryEntry]`).

**Files touched:**
- `Features/Library/LibraryView.swift` (new)
- `Features/Library/{Saved,Downloaded,RecentlyPlayed}Section.swift`
  (new)
- `Features/Collections/` (delete after move)
- `Data/CollectionStore.swift` → rename / rewrite as `LibraryStore`
- `ContentView.swift` (point Library tab at the new view)

**How we know it worked:** Save a tour from `TourDetailView` → it
appears in Library → Saved. Force-quit + relaunch → still there.
Recently-played history reflects what you actually played.

---

### M-geofencing. GPS-triggered stop playback

**What:** For multi-stop tours where the maker set stops to
`.geofenced` mode, automatically play the next stop's audio when the
user enters that stop's geofence (default 30m radius). Reuse the
existing `ProximityMonitor` shape with the new `Stop` model. Fire a
local notification when the geofence triggers in the background.

**Files touched:**
- `Location/ProximityMonitor.swift` (rework for stop geofences)
- `Audio/AudioPlayerService.swift` (handle geofence-triggered enqueue)
- `project.pbxproj` (likely needs
  `NSLocationAlwaysAndWhenInUseUsageDescription` for background
  geofencing — owner-facing decision: do we ask for "always" location,
  or accept that geofencing only works while the app is foregrounded?)

**Open question for owner at start of this milestone:** "Always"
location is more powerful (geofences work with the phone locked) but
a heavier permission ask. "When-in-use" works while the player is on
screen but stops when the app backgrounds. Recommended: ask for
when-in-use first; prompt for always-allow only once the user starts
a multi-stop geofenced tour, with copy that explains the tradeoff.

**How we know it worked:** Simulator with simulated location moving
along a tour's stops → audio for stop N plays as the user arrives at
stop N. Phone locked → same behavior + a local notification.

---

### M-offline. Tour download for offline playback

**What:** "Download for offline" on tour detail downloads all of the
tour's audio files (and intro) to the app sandbox. Player prefers the
local file when available. Downloaded tours appear in Library →
Downloaded with an offline indicator. Settings includes a "Manage
downloads" view for deleting cached tours and seeing storage usage.

**Files touched:**
- `Audio/TourDownloader.swift` (new — `URLSession` background
  downloads)
- `Features/Tour/TourDetailView.swift` (Download button + progress
  ring)
- `Features/Library/DownloadedToursSection.swift`
- `Features/Settings/SettingsView.swift` (Manage downloads link)

**How we know it worked:** Download a tour → put phone in airplane
mode → start the tour → audio plays end to end without buffering.

---

### M-launch-content. Record 5–15 audio tours / pieces

**Owner milestone — not Claude work.** The Atlas team:

- Picks 5–15 locations / themes (mix of single-piece + multi-stop)
- Writes scripts
- Records audio
- Edits and masters
- Captures stop coordinates and trigger preferences
- Uploads audio to the chosen CDN
- Writes maker bios + tour descriptions
- Authors the final `Tours.json` entries

**Hand-off shape:** Once `Tours.json` is updated with real content and
audio URLs resolve, the rest of the app should "just work" — no code
changes required if the prior milestones held to the data contract.

**Open decision for owner:** Which CDN hosts the audio? Reasonable
defaults: Cloudflare R2, AWS S3 + CloudFront, or Apple's On-Demand
Resources. Pick once and stay there for V1.

---

### M-qa. V1 functionality sanity pass

**What:** End-to-end walkthrough of the running app with real content
loaded. Functional checklist:

1. App launches → home feed shows tours sorted by distance (or
   graceful fallback).
2. Tap a tour → tour detail → tap Start → audio plays.
3. Lock the phone → audio continues; lock-screen controls work.
4. Multi-stop geofenced tour → simulated walking along stops → next
   stop's audio triggers on arrival.
5. Multi-stop manual tour → tap next stop in player → its audio plays.
6. Download a tour → airplane mode → tour plays end to end.
7. Save a tour → force-quit + relaunch → still saved.
8. Maker page → tour list correct → tap tour → tour detail opens.
9. Map tab → pins show → tap → tour detail opens.

**Files touched:** none expected. Bugs become small targeted fixes.

**Outcome:** V1 ready for owner review via TestFlight, or for the
polish phase below.

---

## V1 — Polish milestones (after functionality lands)

| Milestone | Scope |
|---|---|
| **M-polish-theme.** Theme pass | Decide and apply final colors, typography, spacing. If the rest of V1 followed "use tokens, never hardcode," this is a 3-file change. |
| **M-polish-pins.** Custom map pins | Replace Apple's default pins with the final designed `StopAnnotationView`. |
| **M-polish-player.** Player UI polish | The player is the most-watched surface; deserves its own design pass after the rest of the design system is decided. |
| **M-polish-icon.** App icon | Replace the empty Apple template with a real Atlas icon. |
| **M-polish-copy.** Tour descriptions + maker bios review | Editorial-tone pass over launch content. Owner / content team, not Claude. |
| **M-polish-final.** Final V1 success-criteria pass + vibe check | Walk the 9 success criteria in `atlas_claude_code_prompt.md` with the polished app. Last gate before any V1 release. |

---

## Post-V1 — Future direction (owner takes my lead, reserves right to change)

The big arc after V1 is **opening the platform to outside makers.**
That requires several large pieces of infrastructure, roughly:

### Tier 1 — Unblock the maker side

| | Why first |
|---|---|
| **1. Backend.** Server-stored tours, audio uploads, full CRUD. Stack TBD: managed BaaS (Firebase / Supabase / AWS Amplify) vs. custom DB + REST API. | The static-JSON model doesn't scale past ~50 hand-maintained tours. Every other post-V1 feature depends on this. |
| **2. Maker authentication + maker dashboard.** Sign-up, audio upload, tour metadata editor, per-tour analytics. Likely web-first — editing tours is a desktop task. | No outside makers can ship anything without this. |
| **3. Moderation pipeline.** Report-this-tour, takedown tooling, internal review queue, content policy. | Required before opening uploads to the public — Apple App Store review will ask. |

### Tier 2 — Monetization

| | |
|---|---|
| **4. Paid tours via Apple IAP.** `Tour.priceUSD` flips from 0 to real values; Buy button in consumer app; per-account ownership tracking. Apple takes 30% / 15%; Atlas takes a cut of the remainder; maker gets the rest. | The revenue-share model that the spec calls for. |
| **5. Maker payouts.** Pay makers what they're owed. Stripe Connect is the obvious default for marketplaces of this shape. | Required as soon as paid tours exist. |

### Tier 3 — Consumer-side richness

| | |
|---|---|
| **6. Real sign-in (replaces the V1 placeholder).** Optional sign-in; enables cross-device sync, follow-a-maker, purchase history. Anonymous use still works. | |
| **7. Follow-a-maker + new-tour notifications.** Push when a followed maker publishes a new tour. | |
| **8. In-app search.** Once catalog grows past browsable. | |
| **9. Social — share a tour.** Deep links into a specific tour from a shared URL. | |

### Tier 4 — Platform expansion

| | |
|---|---|
| **10. Reviews / ratings.** Worth weighing — the spec historically excluded them for vibe reasons, but a creator marketplace usually needs quality signals. | |
| **11. Maker collaboration.** Multi-maker tours; joint payouts. | |
| **12. Native experiences on iPad / Mac / Vision Pro.** If consumer demand materializes there. | |

### Open questions for the owner (answer before each tier starts)

- **Tier 1 #1** — backend stack? Firebase / Supabase / custom?
- **Tier 1 #2** — maker dashboard as standalone web app or in-iPad-app?
- **Tier 2 #4** — paid tours per-purchase, subscription, both?
- **Tier 2 #5** — Stripe Connect or another marketplace processor?
- **Tier 3 #6** — Sign in with Apple only, or also email / Google?
- **Tier 4 #10** — do reviews and ratings ship at all, or never?

---

## Working agreement

- This file is **living**. Edit it whenever the plan changes.
- Functionality first; design / tone / icon / polish after.
- New code uses theme tokens even with placeholder values.
- Each milestone ends in a runnable, simulator-reviewable state.
- Owner reviews via simulator or TestFlight, not by reading code.
- If a session uncovers a new gap that isn't in this list, add a new
  milestone rather than expanding an existing one.
- The product spec (`atlas_claude_code_prompt.md`) stays canonical for
  *what* we build. This roadmap is *when* and *how*.

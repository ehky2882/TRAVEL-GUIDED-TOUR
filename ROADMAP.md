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

**Status (2026-05-23):** every V1 functionality milestone is shipped
on `main` (M1–M3, M-data-model, M-audio-foundation, M-tour-detail,
M-player, M-home, M-search, M-maker, M-library, M-geofencing,
M-offline; M-map was cut). AllTrails-style home (PR #31) is the
production home. **Pre-M-qa audit complete** — P0 findings closed
(PRs #22 / #23 / #24, 2026-05-18); P1 + P2 + P3 cleanup batch shipped
2026-05-20 (PR #51). Unit test target wired (PR #33) and runs on CI
per PR; CI runs on the `macos-26` runner so it uses the Xcode 26
toolchain the project targets. **TestFlight: build 1.0 (6) being
uploaded 2026-05-23** carrying the mini-player UX upgrade (welcome
text in idle, marquee-scroll on overflowing titles, always-present
skip-10 button, progress ring around play/pause) and 11 additional
tours (catalog 20 → 31). Build 1.0 (5) uploaded 2026-05-22 carried
PR #54: on-device M-qa fixes, a simulator-review UX-polish batch
(always-present mini-player, square-topped island, tour-detail action
bar, drawer-card carousels, pinch-zoom), and 9 new tours; cleared
the full M-qa device pass with no issues 2026-05-22. Earlier builds:
1.0 (1) first upload (2026-05-19); 1.0 (3) verified the
background-audio fix; 1.0 (4) carried the first home-UX batch and was
the build the 2026-05-21 M-qa pass ran against. Quick simulator-only
verification of build 6's mini-player changes; an on-device pass
against build 6 is the next step.

**Content (M-launch-content).** 31 tours in `Resources/Tours.json`,
all single-stop. The original 10 NYC landmarks (Grand Central, Times
Square, South Street Seaport, Empire State Building, Statue of Liberty,
Brooklyn Bridge, Rockefeller Center, Met, High Line, 9/11 Memorial),
Brooklyn Museum, 9 added 2026-05-21/22 — Whitney, AMNH, Brooklyn
Bridge Park, Chrysler Building, Flatiron Building, Governors Island,
Guggenheim, Intrepid, and Casa da Música (Porto — the first non-NYC
tour) — and 11 added 2026-05-22/23: Little Island, Manhattan Bridge
(from DUMBO), Museum of the City of New York, NYPL Fifth Avenue, The
Oculus, St. Patrick's Cathedral, Vessel (Hudson Yards), Wall Street,
Washington Square Park, Cooper Hewitt, and El Museo del Barrio. Audio
hosted on the `gh-pages` branch (served at
`https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<file>.mp3`);
GitHub Releases tried first but serves the wrong `Content-Type` for
AVPlayer — see `docs/cdn-decision.md` § "Why we switched from Releases
to Pages." No multi-stop tour exists yet.

**TestFlight signing wired (2026-05-19).**
`DEVELOPMENT_TEAM = CPC7M72JTP` in `project.pbxproj`, Apple
Distribution certificate in macOS Keychain (original Mac only), iPhone
UDID registered with team, App Store Connect record + privacy policy
(hosted on `gh-pages` at `/privacy/`) + App Privacy questionnaire all
complete. Per-release upload flow documented in `docs/testflight.md`
(~10 min active). See `archive/HANDOFF-260519.md` for the
session-by-session log.

What's left for V1:
- **A multi-stop walking tour.** M-qa on build 1.0 (5) passed every
  applicable check on device (2026-05-22, no issues found). The only
  M-qa steps still open are the multi-stop ones — geofenced stop
  advancement and manual next-stop — blocked until a multi-stop tour
  is authored. All 31 tours are single-stop, so the app's defining
  feature is uncovered by content.
- **M-launch-content (optional more)** — owner may decide 31 tours
  are enough for V1 launch, or add more. See `docs/authoring-tours.md`.
- **Deferred design / polish pass** — theme tokens, real app icon
  (replace placeholder green sphere), custom map pins, final
  editorial copy.

**Account transfer note (2026-05-20):** project is being handed off
from one Claude account to another. See
`archive/ACCOUNT-TRANSFER-260520.md` for the cold-start orientation +
working-style notes written specifically for the new account's first
session.

**Branches.** `gh-pages` (audio CDN + privacy policy) is the only
non-main branch — orphan, no shared history with main. No parked or
stale branches otherwise.

**Pivot history.** The previous editorial-city-guide V1 work was
mostly reshaped, not thrown out. The migration tables below are kept
for historical reference; everything in them shipped.

What survives:

| Survives the pivot | Status |
|---|---|
| `TabView` scaffolding (M1) | ✅ Done — originally 5 tabs, trimmed to 3 (Home / Library / Me) in PR #15 when M-map was cut |
| Location permission + `LocationManager` (M3) | ✅ Done — still needed for "near you" + geofencing |
| Environment-shelf pattern (DataService, LibraryStore, LocationManager, AudioPlayerService, …) | ✅ Done — same pattern; new services slot in |
| `TRAVEL_GUIDED_TOURApp.swift`, splash, project.pbxproj basics | ✅ Done |
| `Components/HeroImageView.swift`, theme tokens, platform helpers | ✅ Done |

What got replaced or rewritten (all ✅ shipped):

| Replaced | Replaced by | In milestone |
|---|---|---|
| `Models/{City,Place,PlaceCategory,PlaceCollection}.swift` | `Models/{Tour,Stop,Maker,LibraryEntry,TourCategory,RecentSearch}.swift` | M-data-model |
| `Resources/SeedData.json` (45 editorial places) | `Resources/Tours.json` (seed entries; real content pending M-launch-content) | M-data-model + M-launch-content |
| `Data/DataService.swift` | Reshaped to load tours instead of cities + places | M-data-model |
| `Data/CollectionStore.swift` | Renamed to `LibraryStore` (shape: `[LibraryEntry]`) | M-library |
| `Data/SeedData.swift` | Renamed to `ToursData.swift` | M-data-model |
| `Features/Discover/` | `Features/Home/` — map-dominant home with curated rails | M-home |
| `Features/City/` | Cut (no "city as entity" in this product) | M-data-model |
| `Features/Place/PlaceDetailView.swift` | `Features/Tour/TourDetailView.swift` | M-tour-detail |
| `Features/Collections/` | `Features/Library/` (saved + downloaded + recently played) | M-library |
| `Features/Map/` | **Cut entirely** — Home's embedded map is sufficient | M-map (cut) |
| Existing `Location/ProximityMonitor.swift` | Reshaped to monitor stop geofences | M-geofencing |

What got added net-new (all ✅ shipped):

- `Audio/AudioPlayerService.swift` — `AVQueuePlayer` wrapper + lock-screen integration
- `Audio/TourDownloader.swift` — offline audio caching via `URLSession`
- `Features/Player/PlayerView.swift` — full-screen audio player
- `Features/Maker/MakerView.swift` — maker bio + their tour list
- `Features/Search/{SearchView,SearchBar}.swift` + `Data/RecentSearchStore.swift`
- `Data/RecentlyViewedStore.swift` — drives the "Recently viewed" home rail
- `Features/Settings/ManageDownloadsView.swift` — storage management for downloaded tours
- `Components/BottomSheet.swift` — persistent bottom sheet used by the home redesign
- `UIBackgroundModes: audio` build setting (audio continues with phone locked)
- `NSLocationAlwaysAndWhenInUseUsageDescription` build setting (geofence triggers in background)

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

### M-data-model. New data model — Tour, Stop, Maker, LibraryEntry, TourCategory, RecentSearch — ✅ Done (PR #6)

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
- `Models/TourCategory.swift` (new — closed enum of categories that
  drive the home screen's interest-based rails; spec § TourCategory)
- `Models/RecentSearch.swift` (new — local-only record of a search
  query, used by the "Because you searched [X]" rail; spec §
  RecentSearch)
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

### M-audio-foundation. Audio playback infrastructure — ✅ Done (PR #7)

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

### M-tour-detail. Tour detail screen — ✅ Done (PR #8)

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

### M-player. Full-screen audio player — ✅ Done (PR #9)

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

### M-home. Map-dominant home screen with curated rails — ✅ Done (PR #10; redesigned in PR #19)

> PR #19's full-screen-map redesign replaced the stacked rails with
> a single distance-sorted tour list in a bottom drawer. The shipping
> home has no rails — `HomeRailsViewModel` and `RailCarousel` are
> unused by the app (still exercised by the unit suite). The old
> "Because you searched [X]" rail is retired along with the layout.

**What:** Build the new home screen, modeled on the Airbnb landing
page pattern. See `atlas_claude_code_prompt.md` § Key screens #1 for
the design contract. Major pieces:

1. **Search bar pinned to the top** above the map (taps to open the
   M-search results screen).
2. **Map** filling the upper portion of the screen, with tour-stop
   pins. Centered on the user's location, or a sensible default if
   denied / unavailable. Panning the map updates the location-anchored
   rails below.
3. **Curated horizontal-scroll rails** filling the lower portion.
   Three rail families:
   - **Location-anchored:** "Near you" (uses `LocationManager`),
     and "In [city/area in view]" that recomputes when the map pans.
   - **Personalized:** "Continue listening" (`LibraryEntry.listenedSeconds > 0
     && completedAt == nil`), "Recently viewed" (small local cache),
     "Because you searched [X]" (from `RecentSearch`).
   - **Interest-based:** one rail per `TourCategory` — "History,"
     "Architecture," "Art," etc. Hide rails with zero matching tours.

Also: tweak the location-permission copy in build settings to match
the audio-tour framing.

**Files touched:**
- `Features/Home/HomeView.swift` (new)
- `Features/Home/HomeMapSection.swift` (new — map at top, with pan
  detection that updates rail state)
- `Features/Home/RailCarousel.swift` (new — reusable horizontal-
  scroll rail component used by every rail family)
- `Features/Home/HomeRailsViewModel.swift` (new — computes which
  rails to surface, sorts tours within each rail)
- `Features/Discover/` (delete after move)
- `ContentView.swift` (point Home tab at the new view)
- `project.pbxproj` (update `NSLocationWhenInUseUsageDescription` copy)

**How we know it worked:** Set simulated location to NYC → map opens
on NYC with pins → "Near you" rail shows NYC tours → category rails
show interest-organized tours. Pan map to Lisbon → location-anchored
rails recompute. Deny location → map opens on a sensible default
view, location-anchored rails fall back to "Browse all" or hide.

---

### M-search. Search bar + results screen — ✅ Done (PR #11)

**What:** Minimal V1 search that powers the home screen's search bar
and the "Because you searched [X]" rail.

- Search bar in the home header opens a full-screen search results
  view.
- Matches on `Tour.title`, `Maker.displayName`, and
  `Tour.primaryCategory` (display name of the category).
- No filters, facets, fuzzy matching, sorting options, or saved
  searches — explicitly deferred per the spec's out-of-scope list.
- Successful queries (i.e., the user opens a tour from the results)
  are appended to local `RecentSearch` history. Cap stored at 20;
  oldest fall off.

**Files touched:**
- `Features/Search/SearchView.swift` (new — results screen)
- `Features/Search/SearchBar.swift` (new — the pinned bar component
  used in `HomeView`)
- `Data/RecentSearchStore.swift` (new — local persistence for
  `RecentSearch` records)

**How we know it worked:** Tap search bar → results screen opens.
Type "history" → tours with `primaryCategory == .history` appear.
Type a maker name → that maker's tours appear. Tap a result → tour
detail opens → return to home → "Because you searched [X]" rail
now shows the query.

---

### M-map. Standalone map screen — ❌ Cut (PR #15)

Cut by owner decision. Home's embedded map (and then the full-screen
map in the PR #19 redesign) covers the spatial-discovery need; a
separate Map tab was redundant. The former Messages tab also got
absorbed into Settings as a row in the same cut, dropping the shell
from 5 tabs to 3 (Home / Library / Me). `Features/Map/` was deleted.

---

### M-maker. Maker page — ✅ Done (PR #12)

**What:** New `MakerView` shows avatar, bio, and the list of that
maker's tours. Linked from `TourDetailView`'s maker attribution.

**Files touched:**
- `Features/Maker/MakerView.swift` (new)

**How we know it worked:** From tour detail, tap the maker's name →
maker page renders → tap one of their tours → tour detail opens.

---

### M-library. Library tab — Saved / Downloaded / Recently played — ✅ Done (PR #13)

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

### M-geofencing. GPS-triggered stop playback — ✅ Done (PR #17)

> Always-location decision: shipped with both
> `NSLocationWhenInUseUsageDescription` and
> `NSLocationAlwaysAndWhenInUseUsageDescription` set, so geofences
> can fire while the app is backgrounded / phone locked.

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

### M-offline. Tour download for offline playback — ✅ Done (PR #18)

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

**Authoring scaffold (ready):**
- `docs/authoring-tours.md` — UI-agnostic field-by-field guide
  (every `Tour` / `Stop` / `Maker` field, decision tips, validation
  checklist, quick workflow). Doubles as the spec for the future
  in-app maker upload form.
- `docs/Tours.template.json` — two filled-in example tours
  (single-piece + multi-stop) showing every field. Copy from this
  when authoring real entries.
- `scripts/validate-tours.swift` — pre-commit safety net. Catches
  typos, duplicate UUIDs, broken maker refs, kind ↔ stop count
  mismatches, coord-range errors, audio-duration math problems
  before they crash the app at launch. Run manually with
  `swift scripts/validate-tours.swift` or wire into a git
  pre-commit hook (one-liner in `docs/authoring-tours.md`).

**Hand-off shape:** Once `Tours.json` is updated with real content and
audio URLs resolve, the rest of the app should "just work" — no code
changes required if the prior milestones held to the data contract.

**Audio hosting (decided 2026-05-18):** GitHub Releases for the
design / prototype phase; switch to Cloudflare R2 before public
release. Full reasoning and switch-triggers in `docs/cdn-decision.md`
§ Status. Owner manages Releases uploads; URLs slot into
`Tours.json` like any other HTTPS URL — no code changes required
to use either path.

---

### M-qa. V1 functionality sanity pass

**What:** End-to-end walkthrough of the running app with real content
loaded. Functional checklist:

1. App launches → map-dominant home with pins, search bar, filter
   chips, and the tour list in the bottom drawer (or graceful
   fallback if no location). The list sorts nearest-first when
   location is granted, with distance labels on each card.
2. Pan the map → the drawer header's "N tours in view" count
   recomputes for the new area.
3. Tap the search bar → results screen works (title / maker /
   category match). Open a tour from search → tour detail opens.
4. Tap a tour (pin, drawer card, or search) → tour detail → tap
   Start → audio plays.
5. Lock the phone → audio continues; lock-screen controls work.
6. Multi-stop geofenced tour → simulated walking along stops → next
   stop's audio triggers on arrival.
7. Multi-stop manual tour → tap next stop in player → its audio plays.
8. Download a tour → airplane mode → tour plays end to end.
9. Save a tour → force-quit + relaunch → still saved.
10. Maker page → tour list correct → tap tour → tour detail opens.

**M-qa device pass — build 1.0 (4) (2026-05-21).** First on-device
walkthrough. Checklist 1, 3, 4, 5, 8, 9, 10 passed. Items 6/7
(multi-stop geofenced + manual) deferred — no multi-stop tour is in
the current catalog. Five UX issues surfaced and were fixed the same
session (remote — code on the feature branch, ships to device on the
next TestFlight build):

- **Mini-player added.** A persistent now-playing bar sits between
  the home drawer and the tab bar whenever audio is loaded —
  pause/resume inline, tap to reopen the full player. New
  `Features/Player/MiniPlayerBar.swift`; hosted by `ContentView`;
  the home drawer's peek height grows to clear it.
- **Hero-image bleed-through at the peek detent fixed** — the
  drawer's scroll list now fades out at peek instead of leaking a
  sliver of the first card above the tab bar.
- **Recenter animation** — the camera now glides to the user
  (0.45 s ease) instead of snapping; the recenter button's
  fade-in/out on map pan is gentler.
- **User-location dot rebuilt** — explicit Apple-Maps blue, plus a
  directional heading wedge driven by the device compass
  (`LocationManager.heading`, iOS only).

**M-qa device pass — build 1.0 (5) (2026-05-22).** Full walkthrough
on device. Checklist items 1–5 and 8–10 all passed, plus every
build-5 UX change verified — the always-present mini-player (idle +
active states), the square-topped island, the tour-detail action
bar, drawer-card carousels, pinch-to-zoom hero images, the compass
heading wedge, the Library/Settings island backgrounds, and
drawer-detent persistence across tab switches. Items 6/7 (multi-stop
geofenced + manual) still deferred — no multi-stop tour exists.
**No issues found.** V1 functionality is device-validated; only the
multi-stop checks remain, blocked on content.

**Files touched:** none expected. Bugs become small targeted fixes.

**Outcome:** V1 ready for owner review via TestFlight, or for the
polish phase below.

**Pre-QA self-audit (2026-05-18).** Before M-qa actually runs on
device, a code self-audit (landed via PR #21; doc archived to
`archive/pre-qa-audit-260518.md` once most P0s closed) surfaced
22 findings — bugs, fragile edges, accessibility gaps, polish —
categorized P0 (launch blockers) → P3 (polish/debt). Running
status; check items off as fixes land:

**P0 — Launch blockers**
- [x] P0-1. Home → Tour Detail navigation silently broken (PR #23)
- [x] P0-2. Dark Mode catastrophically broken (PR #22)
- [x] P0-3. Typography hierarchy collapsed (PR #22)
- [x] P0-4. SettingsView 23 hardcoded `.foregroundStyle(.black)` (PR #22)
- [x] P0-5. Geofenced playback fails offline for downloaded tours (PR #24)
- [x] P0-6. Geofence notifications invisible in foreground (PR #24)
- [/] P0-7. Developer-facing copy in user UI — HomeView + LibraryView fixed in PR #23. SettingsView debug-counts row deferred to a follow-up after PR #22.

**P1 — Bugs**
- [x] P1-1. "Continue listening" / "Recently played" sort by wrong field (lastListenedAt added)
- [x] P1-2. Maker avatar URL is ignored (AsyncImage with circle fallback)
- [x] P1-3. Player-tour identification by title is fragile (currentSourceId on AudioPlayerService)
- [x] P1-4. HeroImageView doesn't load remote images (AsyncImage with placeholder fallback)
- [x] P1-5. Audio session interruption (phone call) not handled (PR #24)
- [x] P1-6. Headphone unplug doesn't pause audio (PR #24)
- [x] P1-7. International-dateline bug in coordinate-in-region check (MKCoordinateRegion.contains extension)

**P2 — Accessibility**
- [x] P2-1. BottomSheet has no VoiceOver affordance (label + accessibilityAdjustableAction)
- [/] P2-2. Map preview close button sub-44pt touch target — obsolete; the preview-card-with-X pattern was removed in the PR #19 home redesign
- [x] P2-3. Download button disabled state not announced (label + hint when isOtherActive)
- [x] P2-4. No "Open Settings" deep link when location denied (button in SettingsView, iOS/visionOS)
- [x] P2-5. Localization gap — duration / distance formatters hardcoded English/metric (new AtlasFormatters)

**P3 — Polish & tech debt** (ten items; see audit doc; none block V1)
- [ ] P3-1. Hardcoded values bypass theme-tokens — deferred with the design pass
- [x] P3-2. `formattedDuration` duplicated — closed incidentally by P2-5's `AtlasFormatters`
- [ ] P3-3. O(n) lookups everywhere — premature; V1 has 12 tours
- [x] P3-4. TourDownloader no retry on transient failures (3 retries, exponential backoff 1s/2s/4s, transient errors only — terminal failures still fail immediately)
- [ ] P3-5. No tour-completed UX
- [ ] P3-6. Splash screen bare-bones — deferred with the polish pass
- [x] P3-7. ContentView calls `requestPermission` on every appearance (guarded by `didRequestLocationPermission` flag)
- [x] P3-8. Search doesn't index tags or descriptions (added tag + description buckets with rank ordering)
- [ ] P3-9. No delete swipe in Library
- [x] P3-10. ManageDownloadsView ordering undefined (sorted alphabetically by title)

**Lifecycle.** The audit doc itself was archived on 2026-05-18
after the P0 wave landed (PRs #22 / #23 / #24). The closed PRs
are the authoritative record of fixes; this checklist is the
live "what's left." Remaining P1s will batch into a cleanup PR
before M-qa runs.

---

## V1 — Development infrastructure

| Milestone | Scope |
|---|---|
| **M-tests.** XCTest unit suite + CI | ✅ Done. Test files shipped via PR #28 (`claude/m-tests-260518`); workflow added the same day. Xcode test target wiring + CI fix shipped via PR #33 on 2026-05-18: `TRAVEL GUIDED TOURTests` Unit Testing Bundle hosts 6 XCTest classes (`LibraryStore`, `HomeRailsViewModel`, `RecentSearchStore`, `RecentlyViewedStore`, `TourCategory`, `ToursData` decoding) plus `TestFixtures`. Runs locally via Cmd-U and on CI per PR. Cadence rule: see `CLAUDE.md` § "When to run tests." |

---

## V1 — Polish milestones (after functionality lands)

| Milestone | Scope |
|---|---|
| **M-polish-theme.** Theme pass | Decide and apply final colors, typography, spacing. If the rest of V1 followed "use tokens, never hardcode," this is a 3-file change. |
| **M-polish-pins.** Custom map pins | Replace Apple's default pins with the final designed `StopAnnotationView`. |
| **M-polish-player.** Player UI polish | The player is the most-watched surface; deserves its own design pass after the rest of the design system is decided. |
| **M-polish-icon.** App icon | Replace the empty Apple template with a real Atlas icon. |
| **M-polish-copy.** Tour descriptions + maker bios review | Editorial-tone pass over launch content. Owner / content team, not Claude. |
| **M-rethink-categories.** Categories vs. tags | Closed-enum `Tour.primaryCategory` is showing strain in V1 content authoring — many tours have 2–3 defensible category fits, and forcing a single primary felt reductive on at least four tours during M-launch-content (Rockefeller Center, Brooklyn Bridge, High Line, Times Square). Likely direction: drop `TourCategory` enum, derive home rails + filter chips from tags (`Tour.tags`), either popularity-driven or from a curated tag set. Touches `Tour.swift`, `TourCategory.swift` (delete), `HomeRailsViewModel.swift`, `CategoryChipRow.swift`, `scripts/validate-tours.swift`, tests, and the product spec. Pair with the design pass since chip-row visuals change. Owner endorsed direction on 2026-05-19; deferred so V1 content can ship first. |
| **M-polish-final.** Final V1 success-criteria pass + vibe check | Walk the 9 success criteria in `atlas_claude_code_prompt.md` with the polished app. Last gate before any V1 release. |

---

## Known follow-ups (V1, non-blocking)

Small known gaps that aren't blocking V1 release but should get
picked up during M-qa or the polish phase. (Lifted from
`archive/HANDOFF-260518.md` so they live in a doc that future
sessions actually read.)

- **Rails layout retired.** The AllTrails redesign (PR #19/#31)
  dropped the stacked-rails home for a map + single distance-sorted
  drawer list. `HomeRailsViewModel` and `RailCarousel` are no longer
  referenced by the app (the unit suite still covers
  `HomeRailsViewModel`). Deleting them would mean dropping that test
  too, so they're left in place for now. The old "Because you
  searched [X]" rail is retired with the layout.
- **`AudioPlayerService` progress aggregation.** `listenedSeconds`
  on `LibraryEntry` currently reflects position within the current
  audio item only — it doesn't aggregate across stops in a
  multi-stop tour. Fine for V1 ("resume listening" works at item
  granularity), worth a real pass before any analytics or
  completion-tracking feature.
- **Custom `AtlasTabBar` tradeoff.** The AllTrails alignment branch
  replaces the system `TabView`'s tab bar with a custom one. That
  gives up system-level features (badge dots, focus animations,
  accessibility heuristics Apple ships). Easy to revisit post-V1
  if any of those bite.
- **Stale remote branch cleanup** (noted 2026-05-20). 13 merged
  `claude/*` feature branches still on `origin` from PRs #36–#47
  and #50 — all squash-merged, content verified to be on `main`, no
  unmerged work. Safe to delete; the remote-session container's
  GitHub token can't delete branches (HTTP 403), so this needs to
  run from the owner's local machine or the GitHub web UI. Branch
  list + ready-to-paste delete commands are in the chat transcript
  for the 2026-05-20 resume session; if that's lost, re-derive via
  `git ls-remote origin 'refs/heads/claude/*'` and cross-check each
  against its PR's merged status before deleting. Not touched:
  `main`, `gh-pages`, and whatever `claude/resume-*` branch the
  current session is on.
- **Hero image carousel UI** ✅ Shipped 2026-05-20. `TourDetailView`
  and `PlayerView` both render a paged `TabView(.page(indexDisplayMode:
  .always))` when `additionalImageURLs` is non-empty, falling back to a
  single `HeroImageView` for tours with one photo. Images are inset
  from the screen edges with a corner radius. All 3 Times Square images
  are reachable in-app. `HeroImageView` also fixed to constrain
  `scaledToFill()` layout so card sizing is stable.
- **Content authoring tooling at scale (M-content-tooling).** The
  current tour-upload workflow — owner drags audio + transcript
  into a Claude chat, answers 3 questions, Claude pushes audio +
  writes JSON + opens a PR — works fine for ~10 tours. It doesn't
  scale to 100, breaks at 1,000. None of this blocks V1; pre-cursor
  work for Tier 1 #2 (maker platform), since these tools are also
  ~50% of what outside makers will need. Streamlining wins worth
  doing whenever batch uploads start hurting:
  - **Single-PR batches** — one PR for N tours instead of one per.
  - **Manifest-driven uploads** — CSV / JSON with filename, title,
    coords, trigger, category per tour; the pipeline reads the
    manifest and runs the upload.
  - **Geocoding from text** — manifest can say "41st & Fifth, NYC"
    and a geocoder produces coords.
  - **Auto-transcription** — send just the MP3; Whisper or Apple
    Speech generates the transcript automatically.
  - **Description + tag drafting from transcript** — structured
    LLM prompt produces short desc + long desc + caption + tags +
    suggested category, owner spot-checks a batch.
  - **A `scripts/add-tour.swift` CLI** — given audio + manifest
    line, generates JSON entry, validates, commits, opens PR.
    Owner can batch-upload without invoking Claude.

---

## Post-V1 — Future direction (owner takes my lead, reserves right to change)

The big arc after V1 is **opening the platform to outside makers.**
That requires several large pieces of infrastructure, roughly:

### Tier 1 — Unblock the maker side

| | Why first |
|---|---|
| **1. Backend.** Server-stored tours, audio uploads, full CRUD. Stack TBD: managed BaaS (Firebase / Supabase / AWS Amplify) vs. custom DB + REST API. | The static-JSON model doesn't scale past ~50 hand-maintained tours. Every other post-V1 feature depends on this. |
| **2. Maker authentication + maker dashboard.** Sign-up, audio upload, tour metadata editor, per-tour analytics. Phone for capture, web for composition; both are needed (see "Maker platform — detailed design" below). | No outside makers can ship anything without this. The keystone of Atlas-as-platform. |
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

### Maker platform — detailed design (Tier 1 #2 deep dive)

The maker dashboard is the keystone of Atlas-as-platform. Right
now all content is curated by the Atlas team and hand-edited into
`Tours.json`. That works for ~10–50 tours; it falls apart at
hundreds and is unsupportable at thousands. The maker platform is
what flips Atlas from a curated audio app into a creator
marketplace.

Three phases, escalating in scope. Each ends in a shippable
surface.

#### Phase 1 — Single-piece tour creation (phone-first)

The minimum a maker needs to publish one short audio tour about
one location. Targets the simplest tour shape so the platform can
ship the basics before tackling multi-stop curation.

- **Onboarding.** Sign in with Apple (no passwords). Maker
  profile: display name, bio, optional avatar + website.
- **Audio.** In-app recording (`AVAudioRecorder`) so makers can
  record from the place itself, or import from Files / Voice
  Memos / Dropbox.
- **Transcription.** On-device via Apple's `SFSpeechRecognizer`
  — free to the platform, privacy-friendly, works offline. Maker
  reviews + edits the transcript before publishing.
- **Location.** MapKit with two modes:
  - "Use current location" — auto-pin where the maker is
    standing. Right answer when recording in the field.
  - "Drop pin" — long-press to place, drag to refine. Address
    surfaced for confirmation.
  - Trigger radius as a draggable circle around the pin.
- **Images.** PHPicker for camera roll. Carousel of up to 5
  (per the Option A model locked in 2026-05-19 — see
  `M-rethink-categories` neighbor). In-app landscape crop.
  First image is the card cover everywhere.
- **Metadata.** Title, short description, long description, tags
  (with autocomplete from existing taxonomy). Trigger mode with
  smart defaults — geofenced for outdoor, manual for indoor.
- **Review screen.** "Listen" button — maker walks their own
  tour end-to-end before publishing.
- **Submit → moderation queue** (Tier 1 #3).

#### Phase 2 — Multi-stop tour creation (phone + web)

Where it gets genuinely harder. Most makers will start with
single-piece tours; the platform's distinctive product is the
multi-stop walking tour.

- **Stop creation.** Same per-stop capture UX as Phase 1, but
  cheap to repeat. Collapsible cards in a list.
- **Ordering.** Drag-to-reorder. Makers don't always create
  stops in walking order — might record stop 4 first because
  they walked by it.
- **Route preview.** Once stops are placed, draw the connecting
  walking path via `MKDirections`. Surface total walking distance
  + ETA. Flag stops that are unreachably far apart (>500m gap
  without a transit hint).
- **Intro audio.** Optional clip before stop 1 — the "welcome,
  here's why I picked these five blocks" opener.
- **Per-stop trigger override.** Tour-level default, but a
  single stop inside (e.g.) a quiet church can flip to manual.
- **Validation.** Stops in walking order, no orphans, no
  oversized gaps without justification, no duplicates within
  radius.

#### Phase 3 — Maker tooling depth

The stuff that makes a maker stay on the platform after their
first tour. Less foundational than Phases 1–2; more
retention-driving.

- **Maker analytics.** Per-tour: starts, completions, average
  drop-off point, device split, top cities, peak days. One
  dashboard per tour.
- **Version history + revert.** Tours are living things; makers
  re-record stops, swap photos, fix typos. Track edits with
  rollback. Post-MVP, but design earlier phases with it in mind.
- **Drafts + autosave.** Tour authoring is *long*. Losing 20
  minutes of work to a phone call is unforgivable. Autosave
  every 30s; drafts list accessible from any signed-in device.
- **Re-edit after publishing.** Day one. Without version history
  at first — that's Phase 3.
- **Moderation hookup, two-way.** Makers respond to takedown
  notices, request re-review after edits, see flag reasons.
  Connects to Tier 1 #3.

#### Cross-cutting: phone vs web

Phone is right for **capture** — recording, pinning, photos.
Phone is wrong for **composition** — long descriptions,
transcript polish, metadata tuning, route review.

- **In the field, phone:** record audio at each stop, drop pin,
  take photos, save as draft.
- **At home, web:** open Atlas Studio on a laptop, polish
  transcripts, write descriptions, tune tags, preview the route,
  publish.

The earlier ROADMAP note ("Likely web-first — editing tours is a
desktop task") is half-right. The full answer is **both surfaces,
each optimised for the half of the workflow it does best**, with
drafts syncing between them.

#### Hard dependencies

Nothing here ships without these in place first:

1. **Tier 1 #1 — Backend.** Tours move from static JSON to
   server-stored. Audio uploads to a managed bucket the maker
   doesn't have to think about.
2. **Tier 3 #6 — Real sign-in.** Maker identity. Sign in with
   Apple is the right primitive.
3. **Tier 1 #3 — Moderation.** Required before opening uploads
   publicly. Apple App Store review will ask.

Sequence: backend (the platform) → auth + moderation (the
controls) → maker UI (the surface).

---

### Open questions for the owner (answer before each tier starts)

- **Tier 1 #1** — backend stack? Firebase / Supabase / custom?
- **Tier 1 #2** — phone-only MVP, web-only MVP, or both from day one?
- **Tier 1 #2** — auto-transcription via Apple's on-device API (free, lower quality) or Whisper API (paid, higher quality)?
- **Tier 2 #4** — paid tours per-purchase, subscription, both?
- **Tier 2 #5** — Stripe Connect or another marketplace processor?
- **Tier 3 #6** — Sign in with Apple only, or also email / Google?
- **Tier 4 #10** — do reviews and ratings ship at all, or never?

---

## Working agreement

- This file is **living**. Edit it whenever the plan changes.
- **Doc hygiene.** Every session that ships a milestone, cuts scope,
  or changes the "what's true today" state of the project updates
  `ROADMAP.md` and `CLAUDE.md` *in the same commit* — never as a
  follow-up. Stale docs poisoned a recent session (Claude reported
  "all milestones done" without knowing about PR #19's redesign);
  the rule prevents a repeat.
- Functionality first; design / tone / icon / polish after.
- New code uses theme tokens even with placeholder values.
- Each milestone ends in a runnable, simulator-reviewable state.
- Owner reviews via simulator or TestFlight, not by reading code.
- If a session uncovers a new gap that isn't in this list, add a new
  milestone rather than expanding an existing one.
- The product spec (`atlas_claude_code_prompt.md`) stays canonical for
  *what* we build. This roadmap is *when* and *how*.
- Temporary "session bridge" notes (like the original `HANDOFF.md`)
  don't live at repo root — fold their permanent content into
  `ROADMAP.md` / `CLAUDE.md` and move the snapshot to `archive/`
  with a `YYMMDD` suffix.

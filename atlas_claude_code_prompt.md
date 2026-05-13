# Atlas — A creator platform for audio tours

> **Pivot note (May 2026).** This spec replaces an earlier framing of
> Atlas as a curated *editorial city guide* (think Monocle / Kinfolk).
> That framing has been retired. The product is now a creator platform
> for **GPS-anchored audio tours**, closer in shape to AllTrails or
> Atlas Obscura than to a guidebook. The previous editorial-reader
> build (`SeedData.json` with 45 city places, `CityDetailView`,
> `PlaceDetailView`, etc.) is being reshaped to fit. See
> `ROADMAP.md` for the migration plan.

---

## What we're building

Atlas is an iOS / iPad / Mac / visionOS audio-tour app with two sides:

- **Makers** record GPS-anchored audio tours about places they care
  about. A tour is either a **single piece** (one location, one audio
  clip) or a **multi-stop guided walk** (multiple locations, one clip
  per stop, optionally GPS-triggered as the listener arrives).
- **Consumers** browse tours near them (or anywhere they're planning
  to be), download for offline listening, and play them while walking
  — phone in pocket, headphones in, audio narrating the place around
  them.

Atlas earns by taking a percentage of paid-tour revenue when paid
tours and maker payouts ship in a future phase.

**V1 is consumer-side only.** The Atlas team creates the initial
content. There is no in-app upload, no payments, no auth backend yet
— the consumer interface is built in the *shape* of the eventual
creator platform so that nothing has to be redesigned when those
pieces land. See "What NOT to build in V1" below.

**Compared to:**
- AllTrails — location-anchored user-generated content
- Atlas Obscura — curated discovery, but text-first
- Audible / podcast apps — audio playback, but not location-tied

Atlas's distinctive bet: **the audio plays *because of where you are*,
not because you pressed play in a feed.** That's the product.

---

## V1 scope at a glance

| Element | V1 |
|---|---|
| Content | 5–15 audio tours / single-location pieces, all created by the Atlas team |
| Distribution | Static JSON manifest of tours (in app bundle or fetched at launch from a CDN) |
| Audio hosting | CDN; consumer app downloads audio on demand and caches locally |
| Pricing | All content free at launch |
| Accounts | None (sign-in is a placeholder UI entry; real auth is post-V1) |
| Maker upload | None in-app (Atlas team edits the JSON and uploads audio to the CDN by hand) |
| Backend | None (no server-stored data, no API) |
| Platforms | iOS 26.2+, iPadOS 26.2+, macOS 26.2+, visionOS 26.2+ |

---

## Core user flows (V1)

### Flow 1: Discover

- Open app → **Home tab = "Tours near you."** Location-aware feed
  sorted by distance. Falls back to a global browse when the user is
  not near any tours or has denied location permission.
- **Explore tab = Map.** Pins represent tour stops. Tapping a pin
  shows a tour preview card; tapping the card opens tour detail.
- Tap any tour → tour detail screen.

### Flow 2: Listen

- Tour detail shows: maker, length, walking distance, stops list,
  optional intro audio, "Start" button, "Download for offline" button.
- Tap Start → full-screen audio player.
- Audio plays through phone speaker / headphones / AirPods / CarPlay.
- Lock-screen and Control Center controls work (play / pause /
  scrub / skip).
- Background audio supported — lock the phone and keep walking.
- **Single-piece tours:** one continuous audio clip tied to one
  location.
- **Multi-stop tours:** discrete audio clip per stop. Each stop's
  clip plays when the maker's chosen trigger fires:
  - **Geofenced trigger** (maker default for outdoor walking tours):
    when the user enters the stop's geofence (~30m radius, maker
    configurable), the clip plays automatically.
  - **Manual trigger** (maker default for indoor / quiet contexts):
    the player UI surfaces a "tap to play stop 2" affordance.

### Flow 3: Library

- **Library tab** holds:
  - **Saved tours** — bookmarked for later.
  - **Downloaded tours** — full audio cached on device for offline
    listening (essential for walking-tour use cases with spotty
    signal).
  - **Recently played** — listening progress persisted locally.
- No cross-device sync in V1 (no accounts). Sign-in adds sync
  post-V1.

---

## Data model

### Tour

- `id`: UUID
- `title`: String
- `shortDescription`: String (one sentence — feed/card copy)
- `longDescription`: String (multi-paragraph — tour detail page)
- `makerId`: UUID (→ Maker)
- `heroImageURL`: String
- `kind`: Enum — `.single` (one location) or `.multiStop` (≥2)
- `stops`: [Stop] (length 1 for `.single`, ≥2 for `.multiStop`)
- `introAudioURL`: String? (plays before stop 1 if present)
- `totalDurationSeconds`: Int (sum of stop durations + intro)
- `walkingDistanceMeters`: Int? (only meaningful for multi-stop)
- `centroidLatitude` / `centroidLongitude`: Double (for "near me" sort)
- `city`: String? (informational only, free-text; tours aren't
  required to belong to a city)
- `tags`: [String]
- `priceUSD`: Decimal (V1: always 0; reserved for paid tours later)

### Stop

- `id`: UUID
- `order`: Int (0-indexed within the tour)
- `title`: String (e.g., "The Bronze Doors")
- `caption`: String? (one-line description in the player UI)
- `latitude` / `longitude`: Double
- `audioURL`: String
- `audioDurationSeconds`: Int
- `triggerMode`: Enum — `.geofenced` or `.manual` (maker-set)
- `triggerRadiusMeters`: Int (default 30; ignored if `.manual`)
- `imageURL`: String?
- `transcriptText`: String? (accessibility)

### Maker

- `id`: UUID
- `displayName`: String
- `avatarURL`: String?
- `bio`: String (1–3 sentences)
- `websiteURL`: String?

### LibraryEntry (local, on-device for V1)

- `tourId`: UUID
- `savedAt`: Date?
- `downloadedAt`: Date?
- `listenedSeconds`: Int (progress through the tour)
- `completedAt`: Date?

---

## Seed content (V1)

For V1 launch, the Atlas team creates **5–15 audio tours / pieces.**
A reasonable mix:

- 2–3 single-location pieces (a piece of public art, a building
  facade, a specific exhibit) — short, 2–5 minutes each.
- 2–3 multi-stop walking tours (a neighborhood, an architecture trail,
  a small museum) — 15–30 minutes each, 3–8 stops.
- The rest at whatever ratio the team prefers.

Recording, editing, mastering, and writing the descriptions is owner
work, not Claude work. See `ROADMAP.md` M-launch-content for the
hand-off shape.

---

## UI / Design direction

> **Design and theming decisions remain deferred** per owner direction
> May 2026. The placeholder values in `Theme/Atlas*.swift` stay until
> the design pass after functionality lands. The structural intent
> below is *what each screen contains*, not *what it looks like*.

### Key screens

1. **Home** — "Tours near you" feed (or global browse fallback).
2. **Explore** (Map) — pins for tour stops; tap a pin → tour preview
   → tour detail.
3. **Library** — Saved / Downloaded / Recently played sections.
4. **Tour detail** — hero image, title, maker (linked to maker page),
   length + walking distance, intro audio, stops list, Start button,
   Download button, Save button.
5. **Maker page** — avatar, bio, list of this maker's tours.
6. **Player** — full-screen audio player. Now-playing stop, scrub bar,
   speed control, "next stop" / "previous stop", stop list with the
   current stop highlighted, distance to next stop (for geofenced
   tours), download progress indicator.
7. **Settings** ("Me" tab) — about, location permission, "Sign in"
   placeholder, downloaded-tour storage management, clear cache.

### Tab bar (5 tabs)

The 5-tab skeleton from M1 survives the pivot. Contents:

| Tab | Content |
|---|---|
| Home | Tours near you |
| Explore | Map of tour stops |
| Library | Saved / Downloaded / Recently played |
| [TBD] | Placeholder — owner decision |
| Me | Settings |

---

## Technical architecture

### Stack

- **iOS 26.2+ / iPadOS / macOS / visionOS** (per `CLAUDE.md` build
  config)
- **SwiftUI only.** `@Observable`, `NavigationStack`.
- **No third-party dependencies in V1.** Apple frameworks only:
  - **SwiftUI** — all UI
  - **MapKit** — the map tab
  - **CoreLocation** — "tours near you" sorting, geofenced playback
  - **AVFoundation** — audio playback (`AVQueuePlayer` for multi-stop
    pre-queueing)
  - **MediaPlayer** — `MPNowPlayingInfoCenter` and
    `MPRemoteCommandCenter` for lock-screen / Control Center / CarPlay
    integration
  - **SwiftData** *or* `Codable` + `UserDefaults` — local library +
    listening progress

### Data layer (V1 — static JSON + CDN audio)

- `Tours.json` ships with the app bundle (or is fetched once at launch
  from a CDN — owner decision; either works under this architecture).
- Audio files referenced by URL in `Tours.json`. Hosted on a CDN
  (provider TBD — owner decision; reasonable defaults: Cloudflare R2,
  AWS S3 + CloudFront, or Apple-hosted On-Demand Resources).
- Downloaded audio cached in the app sandbox, indexed by tour ID.
- Library state (saved / downloaded / progress) stored locally via
  SwiftData or Codable + UserDefaults.
- **Structure the code so a real backend can be swapped in later
  without rewriting views.** The view layer talks to a `TourService`
  protocol; V1's implementation reads the static JSON; the future
  backend implementation makes network calls.

### Audio playback

- `AVQueuePlayer` wrapped in an `@Observable` `AudioPlayerService` on
  the Environment shelf.
- Audio session category `.playback` so audio continues with the phone
  locked and ducks other audio appropriately.
- `UIBackgroundModes` → `audio` in `Info.plist` build settings
  (M-audio-foundation adds this).
- `MPNowPlayingInfoCenter` updated whenever the playing stop changes.
- `MPRemoteCommandCenter` wired for play / pause / skip-forward /
  skip-backward / scrub from lock screen, headphones, AirPods, and
  CarPlay.

### Location features

- `LocationManager` (already in place from M3) drives "tours near you"
  sorting and distance display on tour detail.
- `CLCircularRegion` monitoring via the existing `ProximityMonitor`
  shape drives **GPS-triggered stop playback** for multi-stop tours
  where the maker selected `.geofenced` mode. Region radius per stop's
  `triggerRadiusMeters`.
- **App degrades gracefully without location:** "tours near you"
  falls back to a global browse, and geofenced tours surface a "tap to
  play stop N" affordance instead.

### Project structure

The current folder shape (see `CLAUDE.md` § Architecture) survives.
Several files are repurposed or renamed during the migration; the
roadmap milestones spell out which.

---

## What NOT to build in V1

- **No backend** — no server, no API, no database. All content ships
  via a static JSON manifest and CDN-hosted audio.
- **No user accounts or authentication.** "Sign in" is a placeholder
  UI entry in Settings; real auth ships post-V1.
- **No in-app maker upload.** The Atlas team uploads tours by editing
  the JSON manifest and posting audio to the CDN by hand.
- **No payments / IAP / paid tours / maker payouts.** All V1 content
  is Atlas-made and free. The `Tour.priceUSD` field exists in the
  data model so existing tours can be priced later, but no buy
  buttons, no purchase flow, no payout infrastructure.
- **No moderation tooling.** Atlas-made content only, so not needed
  yet.
- **No comments, reviews, or ratings.**
- **No follow-a-maker, sharing, or other social features.**
- **No push notifications.** Local notifications for geofenced stop
  arrivals are allowed (they're how the geofence trigger surfaces when
  the app is backgrounded).
- **No onboarding tutorial.** The app should be self-evident.
- **No in-app search.** The V1 catalog is small enough to browse.
- **No analytics SDK** beyond Apple's built-in App Store Connect
  metrics.

Do not introduce any of the above without a spec update.

---

## Success criteria for V1

1. App launches → "Tours near you" feed (or a graceful fallback when
   no tours are nearby or location is denied).
2. User can tap a tour → tour detail with maker, length, stops, intro
   audio, Start button.
3. Tap Start → audio plays. Lock-screen and Control Center controls
   work. Background play works (phone locked, audio continues).
4. For a multi-stop geofenced tour: arriving at a stop's geofence
   triggers the next clip while the app is foregrounded or
   backgrounded.
5. For a multi-stop manual tour: tapping the next stop in the player
   plays its clip.
6. User can download a tour for offline playback. Airplane mode →
   downloaded tour still plays end to end.
7. User can save tours; saves persist across relaunches.
8. 5–15 actual recorded audio tours / pieces are loaded into the app.
9. App works without location permission (just no "near me" sorting
   and no geofenced playback).

---

## Tone (interim)

The consumer-facing UI should feel **spare, confident, audio-first.**
Less "design magazine on a phone," more "a beautiful audio app that
respects your time and your ears." Final tone direction TBD by owner
in the polish phase.

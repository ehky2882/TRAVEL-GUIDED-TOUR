# Pre-QA code self-audit — 2026-05-18

A careful read of every Swift file in `TRAVEL GUIDED TOUR/` to surface
bugs, fragile edges, accessibility gaps, and dead code **before**
M-qa runs on a real device. Output of one Claude session, working
solo against `main` (post-PR-#19, pre-PR-#20).

## How to triage this doc

- **P0 — Launch blockers.** Must be fixed before V1 ships. Examples:
  primary navigation flows that silently do nothing; the app
  unusable in dark mode; user-visible developer copy.
- **P1 — Bugs.** Real defects that should be fixed but don't strictly
  block a launch (workarounds exist, or affect a smaller user slice).
- **P2 — Accessibility.** Apple Review will sometimes ask about
  these; they affect a real subset of users either way.
- **P3 — Polish & technical debt.** Cleanups, performance for the
  post-V1 scale, branding, missing UX niceties.

Each finding has file:line refs so a fix can start from the call site.

Lifecycle of this doc: triage findings into ROADMAP.md's M-qa
section (or close them out as fixed), then archive this doc with the
date suffix per the doc-hygiene rule. Don't let it linger as a
"floating todo list."

## Summary

- **7 P0 launch blockers**
- **7 P1 bugs**
- **5 P2 accessibility gaps**
- **10 P3 polish / technical-debt items**

The biggest finding by far: **Home → Tour Detail navigation is
silently broken** (P0-1) — both map-pin preview cards and home
rail cards use `NavigationLink` but no `NavigationStack` wraps
the Home tab. That's the kind of bug that survives unit tests
and only gets caught with hands-on QA, which is exactly why this
audit exists.

The second-biggest: **Dark Mode is catastrophically broken** (P0-2)
because `AtlasColors` defines every text color as `Color.black`
and backgrounds as `Color.white`. The theme is intentionally
placeholder per the deferred-design discipline, but placeholder
values should still adapt to dark mode — use SwiftUI's system
colors (`.primary`, `.secondary`, etc.) as placeholders.

---

## P0 — Launch blockers

### P0-1. Home → Tour Detail navigation is silently broken

**Symptom:** Tapping a map pin's preview card or a tour card on
any home rail does nothing — no transition, no destination.

**Cause:** `HomeView` is rendered directly inside `ContentView`'s
`TabView` with no enclosing `NavigationStack`. Both
`HomeMapSection.tourPreviewCard` and `RailCarousel` use
`NavigationLink { TourDetailView(tour:) }`, which requires a
`NavigationStack` ancestor to resolve. Without one, the link is a
no-op.

`HomeMapSection.swift:60` even has a comment that *expects* a
`NavigationStack` to wrap HomeView — but nothing wires it up.
`LibraryView` and `SettingsView` have their own
`NavigationStack`s; `HomeView` doesn't.

**Fix:** Wrap `HomeView`'s body in `NavigationStack { … }` (and
keep the `.toolbar(.hidden, for: .navigationBar)` modifier so the
home doesn't grow a visible nav bar).

**Refs:** `ContentView.swift:17-32`, `HomeView.swift:32-57`,
`HomeMapSection.swift:59-61`, `RailCarousel.swift:21-26`.

---

### P0-2. Dark Mode catastrophically broken

**Symptom:** On a device set to Dark Mode, large parts of the app
become unreadable — black text on a dark background. Likely also
white-on-white in inverted regions.

**Cause:** `Theme/AtlasColors.swift` defines literal values:

```swift
static let primaryText = Color.black
static let secondaryText = Color.black
static let tertiaryText = Color.black
static let background = Color.white
// …
```

These are fixed colors, not Dark-Mode-aware. CLAUDE.md describes
them as "placeholder values pending the deferred design pass" —
that's fine in principle, but placeholders should still work in
both color schemes. There's also a hierarchy collapse: primary /
secondary / tertiary are all identical.

**Fix:** Replace placeholder values with SwiftUI system colors
that adapt to color scheme automatically:

```swift
static let primaryText = Color.primary
static let secondaryText = Color.secondary
static let tertiaryText = Color.secondary.opacity(0.6)
static let background = Color(.systemBackground)
static let secondaryBackground = Color(.secondarySystemBackground)
// etc.
```

The deferred design pass can still replace these later — the token
shape stays the same.

**Refs:** `Theme/AtlasColors.swift` (entire file).

---

### P0-3. Typography hierarchy collapsed

**Symptom:** Every screen looks like an undifferentiated wall of
12pt Helvetica. Titles, headlines, body text, captions are all
identical — no visual hierarchy.

**Cause:** `Theme/AtlasTypography.swift` aliases every style to
`Font.custom("HelveticaNeue", size: 12)`:

```swift
static let standard = Font.custom("HelveticaNeue", size: 12)
static let largeTitle = standard
static let title = standard
static let headline = standard
static let body = standard
static let caption = standard
// …
```

Same deferred-design rationale as P0-2, but again the placeholder
collapses functional usability. Type hierarchy is core to
readability.

**Fix:** Use SwiftUI system fonts for placeholders so the
hierarchy is visible until the real type pass:

```swift
static let largeTitle = Font.largeTitle
static let title = Font.title2
static let headline = Font.headline
static let body = Font.body
static let caption = Font.caption
```

These auto-scale with Dynamic Type for accessibility — a side
benefit the current setup loses.

**Refs:** `Theme/AtlasTypography.swift`.

---

### P0-4. SettingsView hardcodes `.black` foregroundStyle in 23 places

**Symptom:** Even after fixing AtlasColors (P0-2), SettingsView
remains broken in Dark Mode because it bypasses the tokens and
sets `.foregroundStyle(.black)` directly on every label.

**Cause:** Every text view in SettingsView has
`.foregroundStyle(.black)` literal. Probably added because the
author saw the placeholder AtlasColors values were already black
and wrote the same thing manually.

**Fix:** Replace every `.foregroundStyle(.black)` in
SettingsView.swift with the appropriate `AtlasColors.*` token (or
delete the modifier entirely and rely on SwiftUI's default
foreground style, which adapts to color scheme).

**Refs:** `Features/Settings/SettingsView.swift:15-127` (search
the file for `.black`).

---

### P0-5. Geofenced playback fails offline even for downloaded tours

**Symptom:** A user downloads a multi-stop tour, walks it offline
(airplane mode, or just no signal), the geofence fires when they
arrive at stop 2, audio fails to load.

**Cause:** `ProximityMonitor.handleEntry` builds the audio URL
directly from `stop.audioURL` (the remote URL):

```swift
if let url = URL(string: stop.audioURL) {
    audioPlayer?.play(url: url, …)
}
```

It never asks `TourDownloader` whether a local copy exists.
`PlayerView.playStop` does the right thing
(`tourDownloader.localURL(forStop:in:) ?? remoteURL`) — but
ProximityMonitor bypasses PlayerView entirely.

**Fix:** Either inject `TourDownloader` into
`ProximityMonitor.startMonitoring` alongside `audioPlayer`, or
have ProximityMonitor publish "stop entered" events and let
PlayerView own the URL resolution (cleaner separation —
ProximityMonitor doesn't need to know about downloading).

**Refs:** `Location/ProximityMonitor.swift:116-131`,
`Features/Player/PlayerView.swift:400-416` (reference impl).

---

### P0-6. Geofence notifications invisible while app is foregrounded

**Symptom:** Tour is playing; user has the Player open and looks
away; they walk into stop 3's geofence; audio for stop 3 starts
but there's no visual confirmation (no banner, no badge, no
sound effect) — the user wonders what just happened.

**Cause:** `ProximityMonitor.sendNotification` posts a
`UNNotificationRequest` with `trigger: nil` (immediate delivery),
but iOS by default suppresses notifications when the app is
foregrounded. To show them in-foreground, the app needs a
`UNUserNotificationCenterDelegate` that handles `willPresent` and
returns `[.banner, .sound]`. Nothing implements this delegate.

The doc comment on `ProximityMonitor` actually says "iOS
suppresses these in the foreground by default" — flagged as
expected, but for a walking-tour app this is wrong behavior.

**Fix:** Implement a `UNUserNotificationCenterDelegate` (in
`TRAVEL_GUIDED_TOURApp.swift` or a dedicated helper) that returns
`[.banner, .sound]` in `willPresent`. Set it as
`UNUserNotificationCenter.current().delegate` at app launch.

**Refs:** `Location/ProximityMonitor.swift:133-147`,
`TRAVEL_GUIDED_TOURApp.swift` (where to wire the delegate).

---

### P0-7. Developer-facing copy visible to users

**Symptom:** Three places in the UI mention internal jargon a
user shouldn't see:

1. `HomeView` empty state: "Tours will appear here once
   Tours.json is populated." — mentions a JSON filename.
2. `LibraryView` Downloaded empty state: "Downloading tours for
   offline listening lands in M-offline." — references a
   roadmap milestone (and is stale — M-offline shipped).
3. `SettingsView` About section: shows raw "Tours: 4" /
   "Makers: 1" counts — useful for debugging, not for users.

**Cause:** Copy written during development and never revised.

**Fix:** Rewrite in user voice. Examples:

- HomeView empty state: "No tours yet. Atlas is launching with
  a small slate of NYC audio tours soon."
- LibraryView Downloaded empty state: "No downloaded tours yet.
  Tap the download icon on any tour to listen offline."
- SettingsView About: remove the count rows or rephrase as
  marketing-friendly copy ("4 tours, 1 maker — and growing").
  Or drop entirely.

**Refs:** `Features/Home/HomeView.swift:147`,
`Features/Library/LibraryView.swift:208`,
`Features/Settings/SettingsView.swift:101-122`.

---

## P1 — Bugs

### P1-1. "Recently played" and "Continue listening" sort by wrong field

**Symptom:** Tours appear in the wrong order in both surfaces —
not what the user listened to most recently, but tours they've
spent the most cumulative time on (LibraryView) or saved
longest ago (HomeRailsViewModel).

**Cause:** No `lastListenedAt` field on `LibraryEntry`.
`LibraryStore.recentlyPlayed` sorts by `listenedSeconds` (line
32). `HomeRailsViewModel.continueListeningRail` sorts by
`savedAt` (line 75), which is the bookmark date.

**Fix:** Add `var lastListenedAt: Date?` to `LibraryEntry`.
Update `LibraryStore.updateProgress` to set it on every call.
Change both sorts to use this field.

**Refs:** `Models/LibraryEntry.swift`, `Data/LibraryStore.swift:32`
and `:53-60`, `Features/Home/HomeRailsViewModel.swift:69-88`.

---

### P1-2. Maker avatar URL is ignored

**Symptom:** Every maker page shows a solid grey circle for the
avatar, even when `maker.avatarURL` is set in `Tours.json`.

**Cause:** `MakerView.avatar` always renders a placeholder
`Circle().fill(Color(white: 0.78))`. The `maker.avatarURL` is
never read.

**Fix:** Render the URL via `HeroImageView` (with a circular
clip shape) or an inline `AsyncImage` with the grey placeholder
as fallback. Same pattern as hero images for tours — once
HeroImageView gets its `AsyncImage` swap-in (P1-4), apply the
same treatment to avatars.

**Refs:** `Features/Maker/MakerView.swift:60-64`,
`Models/Maker.swift:6` (avatarURL field).

---

### P1-3. Player-tour identification by title is fragile

**Symptom:** If two tours have the same title, the player UI
treats them as the same one. Could lead to weird "Open player"
button states on tour B while tour A is actually playing.

**Cause:** `TourDetailView.isThisTourActive` and PlayerView's
`startPlaybackIfNeeded()` use
`audioPlayer.currentTitle == tour.title` to identify the source.
The audio player doesn't expose a tour ID.

**Fix:** Add an internal "source identifier" to `AudioPlayerService`
— either a `currentSourceURL: URL?` (URL-equality check) or a
generic `currentSourceId: String?` set by callers. PlayerView and
TourDetailView would then match on that instead of title.

**Refs:** `Features/Tour/TourDetailView.swift:355-372`,
`Features/Player/PlayerView.swift:369`,
`Audio/AudioPlayerService.swift:24`.

---

### P1-4. HeroImageView doesn't load remote images

**Symptom:** Every hero image, every tour thumbnail, every map
preview is a flat grey rectangle. No actual photo ever displays.

**Cause:** `Components/HeroImageView.swift` renders only the
placeholder fill. The comment in the file notes the strategy: "Swap
to AsyncImage(url:) once CDN photos are available."

**Fix:** When M-launch-content gets real CDN URLs (post-CDN
decision), swap the body to:

```swift
AsyncImage(url: URL(string: imageName)) { phase in
    switch phase {
    case .success(let image): image.resizable().scaledToFill()
    default: Rectangle().fill(placeholderFill)
    }
}
.frame(height: height)
.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
```

This is a blocker for launch — every screen in the app is
visually unfinished without it.

**Refs:** `Components/HeroImageView.swift`.

---

### P1-5. Audio session interruption (phone call) not handled

**Symptom:** A phone call comes in mid-tour. iOS pauses audio
(system handles this). Call ends. Audio doesn't resume.

**Cause:** `AudioPlayerService` doesn't observe
`AVAudioSession.interruptionNotification`. Apple's standard audio
app pattern is to listen for this and call `play()` on the
`.ended` interruption with `.shouldResume` option.

**Fix:** Add an observer in `AudioPlayerService.init` for
`AVAudioSession.interruptionNotification`. On `.began`, ensure
state goes to `.paused`. On `.ended` with `.shouldResume` flag,
call `play()`.

**Refs:** `Audio/AudioPlayerService.swift` (init, around line 58).

---

### P1-6. Headphone unplug doesn't pause audio

**Symptom:** User listens through AirPods, AirPods disconnect or
get unpaired, audio continues through the iPhone speaker —
broadcasting their walking tour to everyone around them.

**Cause:** `AudioPlayerService` doesn't observe
`AVAudioSession.routeChangeNotification`. Apple's HIG explicitly
requires audio apps to pause on the
`.oldDeviceUnavailable` route change reason.

**Fix:** Add an observer in `AudioPlayerService.init`. On route
change with reason `.oldDeviceUnavailable`, call `pause()`.

**Refs:** `Audio/AudioPlayerService.swift` (init, around line 58).

---

### P1-7. International dateline bug in coordinate-in-region check

**Symptom:** A tour at longitude -179 wouldn't appear "in view"
for a user viewing a region centered at +179, even though the
two points are geographically close (the map wraps around).

**Cause:** Naive bounding-box math in
`HomeView.isCoordinate(_:inside:)` (lines 125-137) and
`HomeRailsViewModel.isInside(_:region:)` (lines 148-160).
Identical implementations, both broken at the antimeridian.

**Fix:** When `region.center.longitude + delta/2 > 180` or
`< -180`, split the check into two ranges. Or use MapKit's
own region containment helpers if any exist.

Lower urgency since V1 launch content is NYC-only — the bug fires
only for tours in Fiji / New Zealand / Hawaii relative to each
other, which isn't V1's catalog. But the duplicated implementation
is its own DRY problem.

**Refs:** `Features/Home/HomeView.swift:125-137`,
`Features/Home/HomeRailsViewModel.swift:148-160`.

---

## P2 — Accessibility gaps

### P2-1. BottomSheet has no VoiceOver affordance

**Symptom:** A VoiceOver user can't expand or collapse the home
sheet — the drag handle has no label and no rotor action.

**Cause:** `Components/BottomSheet.swift`'s `dragHandle` is a
plain `Capsule` with `.contentShape(Rectangle())`. No
`.accessibilityLabel`, no `.accessibilityAction`.

**Fix:** Add `.accessibilityLabel("Tour list")` and
`.accessibilityAdjustableAction { direction in … }` that responds
to swipe-up/swipe-down by changing detent.

**Refs:** `Components/BottomSheet.swift:80-88`.

---

### P2-2. Map preview close button has sub-44pt touch target

**Symptom:** The "x" button on the map's tour-preview card is
hard to tap on smaller devices; fails Apple's 44×44pt minimum.

**Cause:** `HomeMapSection.swift:97-104` — the button's label is
just `Image(systemName: "xmark.circle.fill")` with no explicit
frame. SF Symbols at `AtlasTypography.body` size are ~22pt.

**Fix:** Wrap the image in `.frame(width: 44, height: 44)` and
adjust visual padding to keep the icon small while the touch
target stays large.

**Refs:** `Features/Home/HomeMapSection.swift:97-104`.

---

### P2-3. Download button doesn't communicate disabled state to VoiceOver

**Symptom:** When tour B is downloading and the user opens tour
A's detail page, the download button is disabled. VoiceOver
users still hear "Download tour" and tapping does nothing.

**Cause:** `TourDetailView.downloadButton` has
`.disabled(isOtherActive)` but the `.accessibilityLabel` is fixed
per-state and never reflects "currently disabled."

**Fix:** Override the label when `isOtherActive` is true:
"Download unavailable — another tour is downloading." Or add
`.accessibilityHint("Wait for the current download to finish.")`.

**Refs:** `Features/Tour/TourDetailView.swift:262-263`.

---

### P2-4. No "Open Settings" deep link when location is denied

**Symptom:** User denies location at first prompt. Atlas's
location-dependent features (Near You rail, geofencing) degrade
silently. To re-enable, user has to navigate to iOS Settings →
Privacy → Location → Atlas manually.

**Cause:** `SettingsView` shows a static "Denied" status but
offers no in-app remediation. Standard iOS pattern is a button
that opens
`UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString))`.

**Fix:** When `locationManager.authorizationStatus` is `.denied`
or `.restricted`, add an "Open in Settings" row that deep-links
to the system settings page.

**Refs:** `Features/Settings/SettingsView.swift:53-77`.

---

### P2-5. Localization gap — every formatter is hardcoded English/metric

**Symptom:** Users with non-English / non-metric locales see
"15 min", "850 m", "0.8 km away" — even when their device is
set to Imperial units or a language other than English.

**Cause:** Hand-rolled formatters in `TourDetailView`,
`LibraryView`, `MakerView`, `RailCarousel`, and `LocationManager`.
All hardcode "m", "km", "min", "s".

**Fix:** Replace with `DateComponentsFormatter` for durations
and `MeasurementFormatter` for distances. Both respect the
device locale and unit-system preference automatically. This
also internationalizes V1 for free.

**Refs:** `Features/Tour/TourDetailView.swift:376-395`,
`Features/Library/LibraryView.swift:184-188`,
`Features/Maker/MakerView.swift:181-185`,
`Features/Home/RailCarousel.swift:80-84`,
`Location/LocationManager.swift:72-82`.

---

## P3 — Polish & technical debt

### P3-1. Hardcoded values bypass the theme-tokens discipline

CLAUDE.md is firm: "Always use the tokens, never hardcode values."
But several files violate this:

- `Components/BottomSheet.swift`: magic numbers 24/40/5/8/4,
  `Color.secondary.opacity(0.4)`
- `Features/Maker/MakerView.swift:62`: `Color(white: 0.78)`
- `Features/Home/HomeView.swift:64`: `peekHeight: CGFloat = 100`
- `SplashView.swift:13`: hardcoded neon green
- `Features/Player/PlayerView.swift:38,257-273`: rate values,
  font sizes

**Fix:** Promote each to a theme token or use existing ones.

---

### P3-2. `formattedDuration` is duplicated four times

Implemented (with slight variations) in `TourDetailView`,
`LibraryView`, `MakerView`, `RailCarousel`. Same logic, slight
inconsistencies — e.g., LibraryView shows "30s" for sub-minute
content, TourDetailView shows "0 min 30s".

**Fix:** Replace with `DateComponentsFormatter` (P2-5 covers this).
One implementation, locale-aware, no duplication.

---

### P3-3. O(n) lookups everywhere

`DataService.tour(by:)`, `maker(by:)`, `tours(by:)`,
`HomeRailsViewModel`'s rail builders all do linear scans. Fine
for V1's 5–15 tours. Pre-cache as `[UUID: Tour]` /
`[UUID: Maker]` if the catalog ever scales past ~100.

**Refs:** `Data/DataService.swift`, multiple files.

---

### P3-4. TourDownloader has no retry on transient failures

Network blips during download fail immediately. User has to
re-tap. Could be solved with `URLSession.shared.dataTask`
retries with backoff, or by leaving the download in a "retrying"
state for N seconds before failing.

**Refs:** `Audio/TourDownloader.swift:314-326`.

---

### P3-5. No tour-completed UX

`LibraryEntry.completedAt` is in the model. Nothing ever sets it
— PlayerView always writes `completed: false`. No completion
celebration view, no auto-suggestion to bookmark/share, no
filtering "show completed only."

**Fix:** When `handlePlaybackEnded` fires on the last stop, set
`completed: true` via `libraryStore.updateProgress`. Optionally
present a small "Tour complete" overlay.

**Refs:** `Features/Player/PlayerView.swift:133-144`,
`Features/Player/PlayerView.swift:457-474`,
`Models/LibraryEntry.swift`.

---

### P3-6. Splash screen is bare-bones

A 12pt "atlas" wordmark on black with a single neon-green dot.
No logo, no real branding. Adequate as a placeholder during
development; not adequate as a first impression at launch.

**Refs:** `SplashView.swift`.

---

### P3-7. ContentView calls `requestPermission` on every appearance

```swift
.onAppear {
    locationManager.requestPermission()
}
```

iOS suppresses the dialog after the first call, so functionally
safe — but conceptually wrong, and could be reframed to ask in
context (the first time the user expands the home drawer, or
opens a multi-stop tour).

**Refs:** `ContentView.swift:34-37`.

---

### P3-8. Search doesn't index tags or descriptions

`SearchView.filteredTours` matches against title, maker name, and
category display name only. Users searching for "Brooklyn" or
"1920s" won't find tours unless the keyword is in the title.

**Fix:** Extend the substring match to include
`tour.shortDescription`, `tour.longDescription`, and
`tour.tags`. Order: title hits → category → maker → tags →
description (small ranking heuristic).

**Refs:** `Features/Search/SearchView.swift:266-289`,
`docs/authoring-tours.md` (which already says tags feed the
search index).

---

### P3-9. No delete swipe in Library

Saved and Downloaded sections present tour rows that can't be
removed via the standard iOS swipe-to-delete gesture. Users have
to open each tour and unsave / unsave-download individually.

**Fix:** Add `.swipeActions` to the `LibraryView.tourRow`
NavigationLink rows.

**Refs:** `Features/Library/LibraryView.swift:80-102`.

---

### P3-10. ManageDownloadsView ordering is undefined

`downloadedTours` iterates `tourDownloader.states` (a
Dictionary) which has no defined order — list order varies
between launches. Should sort by title or download date.

**Refs:**
`Features/Settings/ManageDownloadsView.swift:78-83`.

---

## What looks good (worth noting)

So a future reviewer doesn't worry about these:

- **`AudioPlayerService` state machine** is careful and well-commented.
  The `isAwaitingFirstPlayTransition` flag, the watchdog timeout,
  the way `.waitingToPlayAtSpecifiedRate` doesn't override
  `.failed` — these solve real iOS audio gotchas that a junior
  implementation would miss.
- **`TourDownloader` progress overshoot** is caught and resolved
  with a clear comment explaining why bytes counters reset
  before the recompute (line 291-295). Good defensive code.
- **Accessibility labels on transport buttons** in PlayerView
  are present (lines 261, 268, 276, 289).
- **Cross-platform shims** in `PlatformHelpers.swift` are
  clean — small surface area, well-scoped.
- **Failure UX in PlayerView** (banner + retry icon on play
  button) is more thoughtful than most apps at this stage.
- **TourDetailView's download button state machine** is
  thorough (4 faces × accessibility per face).
- **Decoupling of `TourDownloader` from `LibraryStore`** via
  the `onChange` sync in TourDetailView is a clean architectural
  choice.

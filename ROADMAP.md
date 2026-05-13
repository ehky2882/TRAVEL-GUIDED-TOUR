# Atlas — V1 Roadmap

> **How to read this file:** every technical term has a plain-English
> analogy in parentheses so a non-coder owner can follow along. This is a
> **living document** — milestones, scope, and priorities will shift as
> we build. Edit freely.

## Owner direction (May 2026)

Two principles override everything else in this file:

1. **Functionality first; design and tone deferred.** Don't burn cycles
   on color palettes, typography choices, app icons, custom map pins, or
   editorial voice. Get the features working, get the data flowing, get
   the app reviewable in the iOS Simulator. The design / theming /
   editorial pass happens after V1 functionality lands.
2. **Build so the deferred design pass is cheap.** New code uses the
   `Theme/Atlas{Colors,Typography,Spacing}.swift` tokens even though
   their values are placeholders. That way the future design decision is
   a 3-file change, not a 60-file rewrite. Same idea for editorial copy
   in `SeedData.json` — use factual placeholder descriptions now, plan
   for a tone rewrite later.
3. **Review workflow.** Owner reviews changes by running the app in the
   iOS Simulator or via TestFlight, not by reading code. Each milestone
   ends with the app in a runnable, reviewable state.

---

## Where we are right now

**V1 functionality is largely already in place.** The first roadmap was
written based on a too-quick initial scan of the repo and incorrectly
flagged the seed data and the location privacy string as "gaps." Both
were already committed before this roadmap was authored. Net effect:

| Milestone | Status |
|---|---|
| M1 — Wire ContentView (5-tab structure) | ✅ Done |
| M2 — Populate SeedData.json (45 places) | ✅ Already done in commit `890b10c` |
| M3 — Info.plist location privacy string | ✅ Already done (build setting) |
| M4 — PlaceDetail + Collections end-to-end QA | ⏳ Needs run-in-simulator check |
| M5 — Map view functional QA | ⏳ Needs run-in-simulator check |
| M6 — V1 functionality sanity pass | ⏳ Needs run-in-simulator check |
| M7–M11 — Polish phase | ⏳ Pending |

The remaining V1 functionality work is mostly **QA** (M4 / M5 / M6) —
running the app, walking the flows, and fixing anything broken. It
should produce few or no code changes if the existing scaffolding is
sound. After that comes the polish phase (theme, custom pins, app icon,
editorial copy review, final vibe check).

---

## V1 — Functionality milestones (in execution order)

Each milestone is sized to fit in one focused work session.

### M1. Wire ContentView to the real screens (the unblocker) — ✅ Done

**Status:** Shipped in PR #2 (commit `24df8b7`). 5-tab `TabView` routes
to `DiscoverView` / `MapView` / `CollectionsView` / a "Coming soon"
Messages placeholder / `SettingsView`. The "Messages" tab's content is
deferred to post-V1 per owner.

**Historical brief (kept for reference):**

Replace the placeholder `ContentView.swift` (the front door)
with a real 5-tab bar that routes each tab into the actual feature
screens we already built. The current placeholder has 5 tabs labeled
Home / Explore / Favorites / ??? / Me — keep the 5-tab structure per
owner direction.

**Decision needed at the start of M1:** what does each of the 5 tabs
open into? Likely starting point (owner can override):

| Tab | Opens into | File |
|---|---|---|
| Home | Discover feed (cities + featured places) | `DiscoverView` |
| Explore | Map of all places | `MapView` |
| Favorites | User's saved collections | `CollectionsView` |
| ??? | TBD — needs owner decision | placeholder for now |
| Me | Settings / profile | `SettingsView` |

The "???" tab gets a temporary "Coming soon" placeholder until you tell
us what it should be.

**Why:** Until this is done, none of the existing work is reachable when
you run the app. This is the single change that turns the project from
"a pile of finished rooms" into "a navigable house."

**Files touched:**
- `TRAVEL GUIDED TOUR/ContentView.swift` (rewrite)

**Files referenced (already exist, no changes):**
- `Features/Discover/DiscoverView.swift`
- `Features/Map/MapView.swift`
- `Features/Collections/CollectionsView.swift`
- `Features/Settings/SettingsView.swift`

**How we know it worked:** Run the app. Instead of grey rectangles
labeled "Content 1..8," you see a real screen on the Home tab. Tapping
each of the 5 tabs switches to a different real screen.

---

### M2. Populate `SeedData.json` with the 45-place catalog — ✅ Already done

**Status:** Done in commit `890b10c` ("V1"), before this roadmap was
written. The file contains all 45 places (NYC, Porto, London × 15 each)
with all required fields. Editorial copy is already in the Atlas voice
— better than the "factual placeholder" the milestone originally
specified. The two-pass plan (factual placeholder now → editorial
rewrite later) is collapsed into a single existing pass. If you want
to edit specific copy later, treat that as a small targeted change.

**Historical brief (kept for reference):**

Fill in the data file that the app reads on launch — 3 cities
(NYC, Porto, London) × ~15 places each. Each place gets a name,
category, address, lat/lon (GPS coordinates), basic factual description,
and the rest of the structured fields the data model expects.

**Why:** Right now the app has *zero* real content. The Discover feed
will be empty until this file is filled in.

**Files touched:**
- `TRAVEL GUIDED TOUR/Resources/SeedData.json` (fill in the stub)

**Notes:**
- Hero photos can be solid color blocks or SF Symbols (Apple's built-in
  icon library) for V1. Real photography is a later layer.
- Same for the "on-site tip" field — leave it `null` for most places;
  add a placeholder tip on 3–5 places just so we can test the on-site
  display path.

**How we know it worked:** Launch the app → Home tab shows three city
cards (NYC, Porto, London). Tap a card → City detail shows ~15 places
filterable by category.

---

### M3. Location privacy strings + GPS flow QA — ✅ Already done

**Status:** The `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription`
build setting is already configured in `project.pbxproj` (both Debug
and Release) with the copy: *"Atlas uses your location to show nearby
curated places and calculate distances when you're exploring a city."*
Modern Xcode generates the Info.plist from this build setting rather
than maintaining a separate file. The "QA the flow" half of this
milestone rolls into M6 (functional sanity pass) — run the app, accept
the prompt, confirm `LocationManager` reports a position.

**Historical brief (kept for reference):**

Add the one-sentence explanation iOS requires before the app
can use GPS. Without it, Apple silently refuses to grant location
permission.

**Why:** Atlas's "you're physically in the city" magic depends on GPS.
Without this fix, the location features look broken for no obvious
reason.

**Files touched:**
- `TRAVEL GUIDED TOUR.xcodeproj` Info.plist (add the privacy strings —
  `NSLocationWhenInUseUsageDescription`, and `…AlwaysAndWhenInUseUsage…`
  if we enable proximity geofencing in V1).

**The sentence to write:** something like *"Atlas uses your location to
show nearby places and surface on-site tips when you're at a place."*
Short, honest, makes the trade clear. Final wording is a tone decision —
placeholder copy for now.

**How we know it worked:** Fresh install on the simulator → first launch
prompts for location with that sentence. Granting permission →
`LocationManager` reports a real lat/lon. Denying → app still works
without distance/proximity features.

---

### M4. PlaceDetail + Collections end-to-end

**What:** Make the full save-a-place flow work from start to finish:

1. Tap a place card → `PlaceDetailView` opens with photo, description,
   address, hours, etc.
2. Tap "Save to Collection" → bottom sheet slides up.
3. Pick an existing collection or create a new one.
4. The place appears in the Favorites tab inside that collection.
5. Force-quit the app, relaunch — saved places are still there.

**Why:** Saving places is the primary user activity. If this flow has
rough edges (data loss on relaunch, sheet not dismissing, places not
appearing), the app isn't usable.

**Files touched:** mostly QA + small bug fixes across:
- `Features/Place/PlaceDetailView.swift`
- `Features/Collections/AddToCollectionSheet.swift`
- `Features/Collections/CollectionsView.swift`
- `Data/CollectionStore.swift` (verify saves persist across launches)

**How we know it worked:** The 5-step round-trip above works without
friction.

---

### M5. Map view — core functionality only

**What:** Make sure the map tab actually works as a functional feature:
- Map opens centered on a sensible default city (e.g., user's nearest
  if location granted, NYC otherwise).
- Every place from `SeedData.json` shows up as a pin on the map.
- Tapping a pin opens that place's `PlaceDetailView`.
- User's blue "you are here" dot appears when location is granted.

**Per owner direction: custom terracotta pins, compact preview cards,
and other visual polish are deferred.** Use Apple's default pins for
V1. The map works; the look is a later pass.

**Files touched:**
- `Features/Map/MapView.swift` (functional QA + bug fixes)
- `Features/Map/PlaceAnnotationView.swift` (leave styling minimal for now)

**How we know it worked:** Simulator with location set to Manhattan →
Map tab opens to NYC with pins everywhere. Tap one → place detail
opens.

---

### M6. V1 functionality sanity pass

**What:** Walk through the running app and confirm the full functional
loop works end to end without crashes or dead-ends.

**The functional checklist:**
1. App launches → splash → home feed of 3 cities.
2. Tap a city → city detail with filterable places.
3. Tap a place → place detail with all fields visible.
4. Save a place → choose/create collection → appears in Favorites tab.
5. Map tab shows pins → tap pin → opens place detail.
6. Location prompt appears on first launch; granting/denying both
   work cleanly.
7. Force-quit + relaunch → collections persist.

**Why:** Last functional gate before V1 polish begins. Anything broken
here gets a bug ticket before any design work starts.

**Files touched:** none expected — this is QA, not code. Bugs found
here turn into small targeted fixes.

**How we know it worked:** All 7 checklist items pass on the iOS
Simulator. App ready for owner review via TestFlight if desired.

---

## V1 — Polish milestones (after functionality lands)

These were originally V1 milestones but moved to a later phase per
owner direction. They can be reordered or split based on priorities
once we get here.

### M7. Theme pass
Decide and apply: final color palette, typography choices, spacing
rhythm. Update only the three `Theme/` files — if M1–M6 followed the
"use tokens, never hardcode" rule, this is purely a 3-file change.
Sync `Assets.xcassets/AccentColor.colorset` to match.

### M8. Custom map pins + place preview cards
Replace Apple's default pins with terracotta `PlaceAnnotationView` with
category icon. Add compact card that slides up on pin tap.

### M9. App icon
Replace empty Apple template with a real Atlas icon.

### M10. Editorial tone pass on `SeedData.json`
Rewrite all ~45 place descriptions in the chosen "Atlas voice"
(decision made just before this milestone). This is content work, not
code work — done as a single editorial sprint.

### M11. Final V1 success-criteria pass + vibe check
Walk through the 7 success criteria in
`atlas_claude_code_prompt.md` §"Success Criteria for V1" with the
running, polished app. Last gate before any V1 release.

---

## Post-V1 — Future direction (owner takes my lead, reserves right to change)

Below is my recommended priority order with reasoning. None of this is
locked in — flag anything you want reordered, dropped, or expanded.

### Tier 1 — Highest leverage, do first

**1. Backend.** Replace the bundled `SeedData.json` with a real
server-hosted database (likely Firebase or a simple REST API). *Why
first:* without this, every single content update — every new city,
every fixed typo, every added place — requires shipping a new app
version through Apple's review process (1–7 days). With a backend,
content updates are instant. This unlocks the entire editorial
workflow.

**2. Local proximity notifications.** When a saved place is within
~200m, the iPhone fires a gentle notification ("The Noguchi Museum is
a 3-minute walk from you"). *Why second:* this is the **single feature
that makes Atlas different from a static guidebook app**. The whole
product thesis is "editorial discovery + location awareness" — without
the location-triggered notifications, we have half the thesis. Built
with Apple's `CLCircularRegion` (virtual fences); no server needed.

**3. Custom map-pin photography + photo polish.**
Replace solid-color hero images and SF Symbol thumbnails with real
photography for each place. *Why here:* once the backend is in place
(Tier 1 #1), photo URLs are easy to swap and update. Doing this before
the backend would mean every photo update requires an app release.

### Tier 2 — Grow the catalog, expand the audience

**4. Search.** Re-enable the search bar with proper filtering by city,
category, neighborhood, tags. *Why now:* the V1 catalog is 45 places —
small enough to browse. Once we add new cities (Mexico City, Tokyo,
Berlin, etc.) and the catalog hits ~100+, browsing alone gets clumsy.

**5. More cities.** Expand from 3 cities to ~10. *Why after backend:*
adding cities is cheap when content is server-hosted. Each new city is
roughly the same content lift as one city of V1.

**6. Authentication + sync.** User accounts so a user's saved
collections sync across iPhone, iPad, Mac, Vision Pro. *Why here:*
necessary prerequisite for social (Tier 3) and a quality-of-life win
for users with multiple devices.

### Tier 3 — Social and richer experiences

**7. Social — sharing collections.** Users can share a collection
("My Lisbon weekend") via a link. The recipient sees a read-only view
of the collection. *Why here:* simplest social feature; high
shareability (Instagram-friendly); doesn't require following or feeds.

**8. Audio layer.** Curated audio per place — short narrations,
ambient field recordings. *Why later:* high content-production effort
(every place needs a recording). Best done once the catalog is stable
and the brand voice is locked in.

**9. Following / curators.** Users follow specific editors or curators
and see their picks featured. *Why later:* requires user-generated or
curator-generated content infrastructure, which is a big build.

### Tier 4 — Internal tooling

**10. Creator / admin tools.** Web-based dashboard for editorial staff
to add cities and places without a developer. *Why last:* internally
we can manage content via direct database edits during the early
growth phase; the admin dashboard becomes worth building once we're
adding content faster than 1–2 people can hand-edit.

### Open questions for the owner

These should be answered before each tier begins (not now):

- Tier 1 #1 — Firebase vs. custom REST API vs. a managed CMS like
  Contentful? Each has trade-offs around cost, control, and editorial
  workflow.
- Tier 1 #2 — Notifications opt-in or opt-out? On by default for saved
  places only, or also for "places nearby that match your taste"?
- Tier 2 #5 — Which cities next? Decision drives the editorial workload.
- Tier 3 #7 — Should shared collections require an account to view, or
  be open via link? Open is better for virality but harder to monetize
  later.

---

## Working agreement

- This file is **living**. Edit it whenever the plan changes.
- Functionality first, design / tone / icon / polish after.
- New code uses theme tokens even with placeholder values, so the
  design pass stays cheap.
- Each milestone ends in a runnable, simulator-reviewable state.
- Owner reviews via simulator or TestFlight, not by reading code.
- If a session uncovers a new gap that isn't in this list, add a new
  milestone rather than expanding an existing one.
- The product spec (`atlas_claude_code_prompt.md`) stays canonical for
  *what* we build. This roadmap is *when* and *how*.

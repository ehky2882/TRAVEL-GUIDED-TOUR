# Atlas — V1 Roadmap

> **How to read this file:** every technical term has a plain-English
> analogy in parentheses so a non-coder owner can follow along. This is a
> **living document** — milestones, scope, and priorities will shift as
> we build. Edit freely.

## Where we are right now

Think of the app as a house under construction:

- The **rooms** are framed and furnished — every individual screen
  (Discover, City detail, Place detail, Map, Saved) exists as a Swift file
  with working code inside it.
- The **hallways are not connected** — the front door (`ContentView.swift`)
  opens onto a placeholder room with grey rectangles instead of routing
  you to the real rooms.
- The **furniture catalogue is empty** — the file that holds the actual
  cities and places (`SeedData.json`) is a stub. We have the shelves but
  no books on them yet.
- The **front-door welcome card is missing** — the iPhone won't let the
  app use GPS until we write a one-sentence note explaining why.
- The **paint isn't on the walls yet** — the accent color is still
  Apple's default blue instead of Atlas terracotta.

Closing those gaps = shipping V1.

---

## Milestones (in execution order)

Each milestone is sized to fit in one focused work session. Each lists:
**what we're doing**, **why it matters**, **which files change**, and
**how we know it worked**.

### M1. Wire ContentView to the real screens (the unblocker)

**What:** Replace the placeholder `ContentView.swift` (the front door)
with a `TabView` (a tab bar at the bottom of the app — like channel
buttons on an old TV remote) that has 3 tabs: **Discover**, **Map**,
**Saved**. Each tab opens the real screen we already built.

**Why:** Until this is done, none of the existing work is reachable when
you run the app. This is the single change that turns the project from
"a pile of finished rooms" into "a navigable house."

**Files touched:**
- `TRAVEL GUIDED TOUR/ContentView.swift` (rewrite)

**Files referenced (no changes needed — they already exist):**
- `Features/Discover/DiscoverView.swift`
- `Features/Map/MapView.swift`
- `Features/Collections/CollectionsView.swift`

**Tweak from spec to flag:** the spec says 3 tabs; the current placeholder
has 5 (Home / Explore / Favorites / ??? / Me). M1 follows the spec — if
you want to keep 5, tell us before we start.

**How we know it worked:** Run the app. Instead of grey rectangles
labeled "Content 1..8," you see the Discover feed. Tapping the bottom
tab bar switches between Discover, Map, and Saved screens.

---

### M2. Populate `SeedData.json` with the 45-place catalog

**What:** Write the actual data file that the app reads on launch — 3
cities (NYC, Porto, London) × ~15 places each. Each place gets a name,
category (gallery / museum / café / etc.), address, lat/lon (the GPS
coordinates), editorial copy (3–5 sentences in the Atlas voice — confident,
spare, opinionated), and an optional "on-site tip" (a sentence that only
shows when you're physically near the place, like an insider whisper).

**Why:** Right now the app has *zero* real content. The Discover feed
will be empty until this file is filled in. This is also where the Atlas
"voice" gets defined — every editorial line we write is a vote for the
brand's tone.

**Files touched:**
- `TRAVEL GUIDED TOUR/Resources/SeedData.json` (fill in the stub)

**Notes:**
- Hero photos can be solid color blocks or SF Symbols (Apple's built-in
  icon library — the little glyphs you see all over iOS) for V1. Real
  photography is a later layer.
- Editorial tone reference: see `atlas_claude_code_prompt.md` §"Seed
  Content" — the Noguchi Museum example sets the voice.

**How we know it worked:** Launch the app → Discover tab shows three
city cards (NYC, Porto, London) with hero images and intros. Tap a card
→ City detail shows ~15 places filterable by category.

---

### M3. Add location privacy strings to Info.plist + QA the GPS flow

**What:** Add the one-sentence explanation iOS requires before the app
can use GPS. Without it, Apple silently refuses to grant location
permission.

**Why:** Atlas's whole "you're physically in the city" magic depends on
GPS. Without this fix, the location features look broken for no obvious
reason.

**Files touched:**
- `TRAVEL GUIDED TOUR.xcodeproj` Info.plist (add the privacy string —
  Claude knows where).

**The sentence to write:** something like *"Atlas uses your location to
show nearby galleries, museums, and architectural landmarks, and to
surface on-site tips when you're at a place."* — short, honest, makes
the trade clear.

**How we know it worked:** Fresh install on the simulator → first launch
prompts for location with that sentence. Granting permission → the app's
Location indicator (in `LocationManager`) reports a real lat/lon.
Denying → the app still works, just without distance/proximity features.

---

### M4. Theme cleanup — make the design language consistent

**What:**
- Audit every screen for hardcoded colors and numeric padding (e.g., the
  lime-green menu circle, `Color(red: 0.22, green: 1.0, blue: 0.08)`).
  Replace them with the shared tokens in `Theme/AtlasColors.swift`,
  `AtlasTypography.swift`, `AtlasSpacing.swift`.
- Update `Assets.xcassets/AccentColor.colorset` to terracotta `#B85042`
  so anywhere iOS uses the system accent (e.g., the default tint of a
  back button), it matches Atlas.

**Why:** Right now the design system is defined but not enforced —
individual screens override it with one-off colors. That makes the app
feel inconsistent and makes it impossible to rebrand later by changing
one file. (Hardcoded color = baking the color into one screen vs.
pulling from the shared brand palette.)

**Files touched:**
- `TRAVEL GUIDED TOUR/ContentView.swift` (already getting rewritten in M1)
- Any screen that uses literal colors or numeric paddings (Claude will
  find them with a search)
- `Assets.xcassets/AccentColor.colorset/Contents.json`

**How we know it worked:** Visual pass. Near-white background, near-black
text, terracotta is the only color note. No screen has a stray bright
color. Switching iOS to Dark Mode still looks right.

---

### M5. PlaceDetail + Collections end-to-end

**What:** Make sure the full save-a-place flow works from start to finish:
1. Tap a place card on the Discover or City screen → `PlaceDetailView`
   opens, showing hero image, editorial copy, on-site tip (if the user
   is nearby), practical info (hours, price, address, website link), and
   a small map snippet.
2. Tap "Save to Collection" → `AddToCollectionSheet` slides up from the
   bottom (a sheet = a partial-screen pop-up panel — like the share menu
   in iOS).
3. Pick an existing collection or create a new one ("Tokyo trip").
4. The place appears in the Saved tab inside that collection.
5. Force-quit the app, relaunch — saved places are still there.

**Why:** Saving places to lists is the primary way users plan trips. If
this flow has any rough edges (lost data on relaunch, sheet not
dismissing, places not appearing), the app isn't usable.

**Files touched:** mostly QA + small bug fixes across:
- `Features/Place/PlaceDetailView.swift`
- `Features/Collections/AddToCollectionSheet.swift`
- `Features/Collections/CollectionsView.swift`
- `Data/CollectionStore.swift` (verify saves persist across launches)

**How we know it worked:** The 5-step round-trip above works without any
"this should work but doesn't" friction.

---

### M6. Map view polish

**What:** Make the map look like Atlas, not Apple's default.
- Custom terracotta annotation pins (the marker dots on the map) with the
  category icon (gallery, museum, etc.) instead of Apple's red teardrops.
- Tap a pin → a compact card slides up showing the place's photo, name,
  and category.
- Tap the card → opens `PlaceDetailView`.
- User's blue dot (the iPhone's "you are here" indicator) shows when the
  user is in one of the 3 cities.

**Why:** The map is one of the three core tabs. Default Apple pins look
generic; the spec specifically calls for custom terracotta pins as a
brand moment.

**Files touched:**
- `Features/Map/MapView.swift`
- `Features/Map/PlaceAnnotationView.swift`

**How we know it worked:** In the simulator, set custom location to
Manhattan → Map tab opens to NYC, terracotta pins visible at every Atlas
place. Tap one → compact card. Tap the card → place detail.

---

### M7. App icon + accent finalization

**What:** Replace the empty Apple template app icon with a real Atlas
icon. For V1, a simple typographic mark — for example a serif "A" in
terracotta on a cream background — is enough. Confirm the accent color
in the asset catalogue matches the terracotta set in M4.

**Why:** The app icon is the first piece of design anyone sees. Shipping
with the empty Apple template signals "unfinished."

**Files touched:**
- `Assets.xcassets/AppIcon.appiconset/` (add icon images at the required
  sizes)
- `Assets.xcassets/AccentColor.colorset/Contents.json` (verify M4)

**How we know it worked:** Install on simulator → home screen shows the
real icon, not the grey square.

---

### M8. V1 success-criteria pass

**What:** Walk through the 7 success criteria in
`atlas_claude_code_prompt.md` §"Success Criteria for V1" with the running
app in hand. Anything that doesn't pass becomes a bug ticket.

**The 7 criteria, paraphrased:**
1. App launches and shows a beautiful, editorial home feed with 3 cities.
2. User can browse into a city, filter by category, see places on a map.
3. User can tap a place and read a compelling editorial description.
4. User can save places to collections and create new collections.
5. With location permission, in one of the 3 cities → user sees distance
   to places and a "You're in [City]" experience.
6. The app *feels* like a design object — someone who cares about design
   would screenshot it and share it. (This is the subjective vibe check.)
7. The code is clean and structured so a backend can be plugged in later
   without rewriting the screens.

**How we know V1 is done:** All 7 pass on a real device or simulator,
not just in theory.

---

## Post-V1 (deferred — captured so we don't lose track)

Rough priority order. Don't plan in detail until V1 ships.

- **Backend.** Swap the bundled JSON for a real server-hosted database
  (REST or Firebase — both are flavors of "a computer on the internet
  the app talks to"). The architecture is already structured to allow
  this swap without rewriting the screens; preserve that property.
- **Local proximity notifications.** When a saved place is within ~200m,
  the iPhone itself fires a gentle notification ("The Noguchi Museum is
  a 3-minute walk from you"). Uses `CLCircularRegion` (a virtual fence
  around a coordinate — when you cross it, the iPhone taps the app on
  the shoulder).
- **Audio layer.** Editorial voice-overs or ambient audio per place,
  played on-site.
- **Search.** Re-enable the search bar once the catalog grows past
  ~50 places — at that point browsing alone gets clumsy.
- **Social.** Sharing collections with friends; following curators.
- **Creator / admin tools.** A workflow for editorial staff to add
  cities and places without a developer.
- **Auth + sync.** User accounts so collections sync across iPhone, iPad,
  Mac, Vision Pro.

---

## Working agreement

- This file is **living**. Edit it whenever the plan changes — don't
  treat the milestone list as fixed.
- Keep each milestone small enough to ship in a single session (≤ ~5
  files touched).
- If a session uncovers a new gap that isn't in this list, add a new
  milestone instead of expanding an existing one.
- The product spec (`atlas_claude_code_prompt.md`) stays canonical for
  *what* we build. This roadmap is *when* and *how*.

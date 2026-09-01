# HANDOFF — 2026-09-01 (session 131) — four place cards, and the Empire State Building moved onto its own address

**Owner: *"Make place pages for Empire State Building, St. John divine, Rockefeller center, Morgan
library"*** — the four EXACT groups `check-place-candidates.py` has reported since the @hereinnyc
batch merged in #682. All four built, then the Empire State place re-anchored onto the building on owner
instruction. **Places 76 → 80. `makers` is BYTE-IDENTICAL and exactly ONE Atlas tour changed.**
Content only — no Swift, no SQL, no gh-pages push, no build.

---

## What was actually there

The checker's EXACT groups showed only the coincident **pin pairs**. Reading the catalogue around
each subject found considerably more, and it changed the shape of all four places:

| Site | Atlas tour | Its gallery | Other pins |
|---|---|---|---|
| Empire State Building | yes, 92 m away | 3 | 2 (both coincident) |
| Cathedral of St. John the Divine | yes, 30 m | 2 | 3 (2 coincident + the lamppost at 42 m) |
| Rockefeller Center | yes, 124 m | 2 | 4 (2 coincident + Rink + Lost Theatre) |
| The Morgan Library & Museum | yes, 6.5 m | 5 | 2 (both coincident) |

Two consequences:

- **Every one has an Atlas tour with a gallery**, so all four heroes are **third photographs**
  promoted from the tour's own gallery — already uploaded, already verified, **nothing sourced**.
  This is the tier-1 shape, not the tier-2 borrowed-hero case, so the borrowed-hero warning count
  does not move.
- **Every entry involved is `manual`.** No geofence is disturbed by any move, and no
  `triggerRadiusMeters` changes. Asserted, not assumed.

## The anchor rule applied — and the one place it was overridden

Three of the four places are anchored on **their Atlas tour's coordinate**, so the pins move and the
tour does not. The Empire State Building is the exception, on owner instruction — see below.

`makers` is byte-identical to `origin/main` and **exactly one Atlas tour changed** (the Empire State
one). **9 link pins** changed, in exactly **four fields each** (`stops[0].latitude/longitude` plus
the mirrored centroid).

Distances moved: **ESB tour 91.7 m onto the building** (its two pins were already there and are
unchanged from `main`) · St John 29.6 m ×2 and 21.8 m · Rockefeller 123.9 m ×2, 96.1 m, 14.9 m ·
Morgan 6.5 m ×2.

## 🔴 THE EMPIRE STATE ANCHOR — put to the owner, and they moved it onto the building

Reverse-geocoded at zoom 18, the two candidate anchors are **not** equivalent:

- the **pin** coordinate → `350 5th Avenue, 10118` — the Empire State Building's own address, and its
  dedicated ZIP code;
- the **tour** coordinate → `Chase, 349 5th Avenue` — a bank branch on the opposite pavement.

The tour's coordinate was not an error. Its narration opens *"From 34th and Fifth, the Empire State
Building rises into the frame like the postcard it became"*, so it is a **deliberate vantage** — the
**Grand Central** case at the same scale (88 m there, 92 m here), and that one anchored on the tour
with the `address` naming the building. **It was built that way first, flagged, and put to the
owner**, who chose to move the tour.

**Final state: the place sits on the building at `40.748442, -73.985659`, and the Atlas tour moved
92 m onto it.** The two pins were already there, so they **return to the coordinate `main` has and
are byte-identical to it** — the Atlas Empire State Building tour is the **only tour in the whole
catalogue this branch changes**. ⚠️ **This diverges from Grand Central deliberately. Do not "restore
consistency" by moving it back.**

### 🔴 Moving it meant re-deriving the radius, not inheriting it

The IAC / Barcelona Pavilion rule: **a coordinate and a radius are one decision.** The stop carried
the 30 m city default, which from the building would **not** have reached the vantage the script
sends the listener to. Re-derived from what the narration actually asks of them:

| covered | distance from the new anchor |
|---|---|
| the building itself | 0 m |
| the 34th-and-Fifth vantage the script describes | 92 m |
| margin at 120 m | 28 m |

**Radius is now 120 m**, which is precedented (120 m ×1, 100 m ×2, 90 m ×2, 80 m ×11 across the
catalogue). **0 geofenced markers sit within 500 m** of the anchor, so nothing else can fire there —
checked against every stop in the catalogue, not assumed.

### ✅ Then set to `geofenced` on owner instruction — and the finding that came out of it

The stop is now `triggerMode: geofenced`, joining **1,146 of the 1,480 single-stop tours** already
marked that way (New York 28 → 29 of 90), with **0 overlapping geofenced regions**.

**🔴 IT STILL CHANGES NO BEHAVIOUR, AND THE REASON GENERALISES TO 1,146 TOURS: `triggerMode:
geofenced` ON A SINGLE-STOP TOUR IS INERT IN THE CURRENT APP.** Traced through the code rather than
assumed from the field:

1. **There is no catalogue-wide background monitoring.** `ProximityMonitor.startMonitoring` is called
   from exactly one site — `PlayerView.onAppear` — and its own doc says *"One active tour at a
   time."* It registers regions for **that tour's** geofenced stops only. So no geofence can fire
   until the user has already opened the tour.
2. **The same `onAppear` plays the stop first.** It runs `startPlaybackIfNeeded()` before
   `startGeofenceMonitoringIfNeeded()`; for a single-stop tour with no intro that calls
   `playStop(at: 0)`, which sets `appShared.currentPlayingStopId`.
3. **That id is then seeded as already-played.** `startGeofenceMonitoringIfNeeded` passes it as
   `startedStopId`, and `startMonitoring` does `playedStopIds.insert(startedStopId)` — while
   `handleEntry` guards `!playedStopIds.contains(stopId)` and the already-inside path subtracts
   `playedStopIds` from its candidates.

**So the only stop a single-stop tour has is marked played before its region is even registered.**
The field is a content convention there, not a working trigger. It does real work only on
**multi-stop walks**, where stops 1..N fire as the listener walks between them during an
already-started tour.

⚠️ **Walking up to a landmark and having its tour start by itself is a capability the app does not
have.** It would need ambient monitoring of nearby tours — a code change, not a catalogue one, and
one bounded by Apple's 20-region cap, which a 1,552-tour catalogue comfortably exceeds.

The other three anchors are unambiguous: St John and the Morgan both reverse-geocode to their own
building from *either* candidate (`Cathedral of Saint John the Divine, 1047 Amsterdam Avenue`;
`The Morgan Library & Museum, 225 Madison Avenue`), and Rockefeller's tour sits on the Plaza, the
heart of the complex.

## ⚠️ Membership went past the coincident pairs, twice, and both are one line to reverse

- **The Penn Station lamppost joins the cathedral.** Its own caption reads *"A piece of the original
  Penn Station **inside** the Cathedral of St. John the Divine"*, and its hero shows the three-lantern
  post standing indoors. That is the **Arab Hall / Elizabeth Oak / Tudor Kitchens** shape — an object
  on the site — not the **Beauchamp Tower** exclusion (a separate building) or the **Great Ball
  Court** one (a separate destination). 4 members.
- **The Rink and the Lost Theatre join Rockefeller Center.** The tour itself describes *"fourteen Art
  Deco buildings"* across three blocks, and both pins say "at Rockefeller Center" — the Lost Theatre's
  caption places it *"in Rockefeller Center"*. Max spread is **124 m**, well inside the **Windsor
  Castle** precedent (6 members across 376 m). 5 members.

**⚠️ The place is named `Rockefeller Center`, not the tour's `Rockefeller Center, the Plaza`** — the
place covers the complex, the tour covers the plaza. A deliberate divergence from the
take-the-tour's-title convention.

## Heroes — all four opened and read, not chosen by filename

Every candidate was rendered and looked at against its members' heroes, so no place prints one
picture twice:

- **Empire State Building** → `empire-state-building_2.webp`, the tower daylit between two buildings.
  Chosen over the night skyline (too close to the tour's own hero) and an upward close-up.
- **Cathedral of St. John the Divine** → `cathedral-st-john-the-divine_3.webp`, the nave. The
  alternative is a facade detail; establishing beats close-up (the session-95 criterion).
- **Rockefeller Center** → `rockefeller-center-the-plaza_2.webp`, the tree, the rink and Prometheus
  together. ⚠️ **Seasonal** — exactly the **Grand Central** trade-off (its place hero carries a
  Christmas wreath), resolved the same way, because the only alternative is a Prometheus close-up.
- **The Morgan Library & Museum** → `morgan-library_2.webp`, the corner of Madison showing the low
  villa beside the taller block — which is what the tour's own opening sentence describes.

All four live URLs return **200**.

## ⚠️ Flagged, not resolved

**`Dante at the Morgan Library` carries `#morganpartner`** — a paid partnership, the same class as
the German Doner Kebab and Coca-Cola pins. It is a real post about a real thing in the building, and
the Coca-Cola precedent (#677) says the owner may well keep it; it ships as a member.

## Descriptions

Each describes the **site**, grounded in the member tour's own text, and asserts nothing a member
merely claims. No architect is named who is not named by the source — the Empire State description
does **not** name Shreve, Lamb and Harmon, because the tour never does (the Jules Dalou rule);
the Morgan names McKim and Piano because its tour names both. Addresses are editorial, corroborated
by reverse geocoding rather than taken from it.

## Verification

- **Place ids** are `uuid5(NAMESPACE_URL, "atlas-place:<city-slug>:<name-slug>")`, the slug
  lowercasing and replacing every non-`[a-z0-9]` run with a hyphen. **Reverse-verified against 74 of
  the 76 existing places**; the two misses are the documented legacy uppercase ids (Green-Wood
  Cemetery, Oedo Antique Market). All four new names are pure ASCII.
- **Validator mirror** — vocabulary parsed from **both** `Models/Tag.swift` and the Swift validator,
  refusing to run if they disagree or either parse is empty (**385 tags across 5 facets**) —
  **self-tested against 40 injected fault classes, 40/40 caught**, then **0 errors, 2 warnings**
  across 1,552 tours + 533 pins + 80 places, **both pre-existing** (VIA 57 West's transcript gap,
  Bedrock Caverns' deliberate null `walkingDistanceMeters`).
- **Three further place-layer faults injected against the NEW places specifically** — a member
  claimed by two places, an empty place name, and one of the new members nudged 55 m off its anchor
  — **3/3 caught**, with the unmodified control clean. The mirror's own suite already covers a
  one-tour place, a duplicate place id, an unknown tour id, a member off the coordinate and a hero
  repeated in the gallery.
- `Tours.json` **byte-stable under a Python re-dump before editing** (the build asserts it and
  refuses otherwise); diff **111 insertions / 44 deletions**.
- **`makers` byte-identical** to `origin/main`, and **exactly one Atlas tour changed** — the Empire
  State Building, in its four coordinate fields plus `triggerRadiusMeters`. **9 link pins changed**,
  in exactly the four coordinate fields; the two Empire State pins are byte-identical to `main`.
  Trigger modes are all still `manual` and no other radius changed.
- **0 members off their place's coordinate**, 0 duplicate place ids, 0 tours claimed twice.
- `check-place-candidates.py`: **EXACT 4 → 0, and the script exits 0** — restoring the clean-exit
  state, which had been broken since #682. **NEAR 24 → 22**, falling by exactly the two Empire State
  pairs the places resolved; **no new coincident group was manufactured.**
- `seed_from_toursjson.py` regenerates cleanly at **208 makers / 2,085 tours / 2,457 stops / 80
  places**, exercising its own `validate_places`.
- ⚠️ **Nothing compiled locally** — no Swift toolchain in a Linux web session, so **CI on the PR is
  the authoritative validator**.

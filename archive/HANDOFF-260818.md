# HANDOFF — 2026-08-18 (session 95)

**Branch:** `claude/place-layer-step2` · **PR:** [#523](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/523) (open)
**Catalog:** 1350 tours / 30 makers / 1696 stops / **24 places** — unchanged in count by this session.

## What shipped

The **place layer**, in three passes, plus a polish pass the owner asked for at the end.

1. **Step 1 — the data layer** (merged, squash `82c3b33`): `Place`, `places` in `Tours.json`,
   `DataService` lookups, `backend/places.sql`, validator + seed-script support, 24 places derived
   from exact coordinate matches.
2. **Step 2 — the map and the page** (`2de3696`): `MapMarkers` (one pin per tour, place tours
   collapse), `PlacePin`, `PlacePlacecardView`, `PlaceView`, `PlacePresenter`, the third UIKit
   slide-up layer.
3. **Step 3 — polish, save, share** (`1688ea5`): this session's work, below.

## The polish pass

Owner: *"Let's polish the place page. I want it to be consistent with my other pages such as the
tour details page. Starting with the image/carousel layout (inset rather than full span)… etc etc.
Show me visually."*

Answered with an **HTML mockup of three phones side by side** at true 390 pt proportion — tour
detail (the standard), the place page today, the place page proposed — with numbered pins tying
each divergence to a table. Same pattern as session 93's option mockup, and again one artifact
settled what prose had not.

**Nine divergences found by reading `PlaceView.swift` against `TourDetailView.swift`.** Six were
plainly wrong and were fixed without asking; three were decisions and the owner took all three.

| # | Was | Now |
|---|---|---|
| 1 | `AtlasColors.background` (pure white/black) | `secondaryBackground`, like every other detail page |
| 2 | A bare 44 pt **circle** on the photo, 17 pt glyph, no backdrop | Tour detail's `chromeRow`: **capsules**, 20 pt glyph, material bar, `.safeAreaInset(edge: .top)` |
| 3 | Full-bleed hero, no top padding | Inset `lg`, `.padding(.top, .md)` |
| 4 | No switcher | `AtlasTabStrip` GALLERY / MAP (owner: yes) |
| 5 | `HeroImageView` direct, one image | `TourMediaCarousel` — the shared component (owner: yes) |
| 6 | `secondaryText`, never truncated | `primaryText`, 4-line preview + Read more |
| 7 | Brass `N TOURS AVAILABLE` | **Kept** (owner: yes) — the one deliberate divergence |
| 8 | `spacing: 0` stack, every child padding itself | Outer `lg` / inner `md`, one horizontal `lg` |
| 9 | Hand-rolled 0.5 pt rule | `Divider()` |

## Save and share

**Save** — new `Data/SavedPlacesStore.swift`, its own `UserDefaults` key.

Deliberately **not** folded into `LibraryStore`: every member of that store is tour-keyed, and its
`onChange` hook has one meaning — *push the tour library to Supabase*. A place write would have
fired it for data that must not be pushed, and `applyMerged` (which replaces the whole entry list
on a sign-in merge) would have been a hazard for data it knows nothing about.

A place bookmark is a **plain toggle**, unlike a tour's add-only one. The tour rule exists because a
tour can be filed into named lists and one tap must never destroy that filing; a place has no lists.
**If places ever gain lists, revisit this.**

Saved places appear in Library's **Lists** tab under a `PLACES` header, between the lists and
Following.

**⚠️ Known gap, deliberate: saved places do not sync across devices.** Saved tours, recently-viewed
and playback progress all do. Wiring it is additive — a `user_saved_places` table plus one push path
in `SyncService` — and needs no migration of what is stored now.

**Share** — `DeepLink.place`, path marker `p`, `AtlasShareLink.placeURL`, resolved by the app into
the place layer. `ReportSheet` gained a `.place` target. A `p/index.html` landing page went to
**gh-pages** (`ee5c1fb`, verified as exactly one addition and zero deletions before pushing) so a
shared link degrades to a real page rather than a 404; it replicates `Place.ranked` in JS so the web
order matches the app's.

## Owner action

**One Supabase paste, optional today:** `backend/places_photos.sql` — adds `additional_image_urls`
to `places` and teaches `catalog_places()` to send it. **The app is correct without it**; the column
is empty everywhere until step 4 writes place photography. Safe to run twice.

## Traps worth carrying

- **🔴 Adding a key to `Tours.json` does not put it in front of users.** The app reads Supabase
  first and only falls back to the bundled catalog offline. This session told the owner "nothing for
  you to run yet", shipped build 68, and the owner correctly reported it still showed the old
  behaviour — `places.sql` had never been applied, so the RPC served no `places` key.
- **🔴 A Python mirror of a Swift validator proves the LOGIC, never the TYPES.** `Place.tourIds` was
  written `[String]` while the validator keys tours by `UUID`; the mirror keyed by string and passed.
  Re-reading the Swift found a second error in the same block.
- **🔴 `key_path` must be called before `scripts/revoke-dev-certs.py` in the fastlane lanes.** The
  script authenticates by reading the `.p8` from `~/private_keys`, and `key_path` is what writes it
  there — it is lazy, and had been first reached three steps *after* the revoke since the July
  rewrite. Build 67 died at the certificate cap with the revoke step reporting a warning nobody read.
  Fixed in both `beta` and `release`.
- **A Swift argument-order error can be invisible in the CI log** — xcodebuild's verbose echo buries
  the `error:` lines beyond log-tail reach. Parse the call site and the declaration and diff the
  orders instead of reading.
- **`p`, `t`, `m` are single-letter path markers.** A new share marker must not collide; the parser
  checks them in order.

## Next

- Confirm the flow on device, then merge #523.
- **Step 4 — editorial content:** place names, one-line descriptions, addresses, place heroes (and,
  now, place galleries).
- **Step 5 — deferred:** geofence behaviour when two tours overlap ("ask on arrival" vs auto-play the
  top-ranked one with a switch-guide affordance) · search/browse grouping by place · an "other tours
  at this place" block on tour detail · saved-places sync.

# CLAUDE.md

## Project: Atlas

GPS-anchored audio tour platform. Makers record audio; consumers browse, download, and play while walking — audio auto-triggers at each stop. Closer to AllTrails than a guidebook.

**Spec:** `atlas_claude_code_prompt.md` — read before product decisions.
**Execution plan:** `ROADMAP.md` — read before implementation decisions.
**V1:** Consumer-side only. No backend, auth, payments, or maker upload.

Multi-platform SwiftUI. iOS 26.2 / macOS 26.2 / visionOS 26.2.

## Session workflow

- **Web sessions** (like this one) are for project management, content uploads, and planning. Code changes happen here only when they're small and self-contained.
- **Implementation work** (new features, refactors, UI changes) → owner spawns a new session and creates a new branch. This keeps the main project-management session context clean.
- Owner does not use Terminal. Claude handles all shell/git work.

## Claude Automation Rules

These happen **automatically, without the owner asking**.

| # | Trigger | What Claude does automatically |
|---|---------|-------------------------------|
| 1 | Every session start | Run full git/PR health check (§ Session-start ritual) + read latest HANDOFF file — before any other work |
| 2 | After any edit to `Resources/Tours.json` | Run `swift scripts/validate-tours.swift`; fix errors before continuing |
| 3 | Before pushing any code PR | Call `test_sim` (XcodeBuildMCP); fix failures before pushing |
| 4 | Doc-only / content-only / asset PR is ready (CI green) | Squash-merge to `main` automatically — no owner approval gate. Resolve merge conflicts in-line. Delete the merged branch. **Code PRs (anything in `*.swift`, `*.xcodeproj`/`*.pbxproj`, `Assets.xcassets/`) wait for explicit owner OK + visual simulator confirmation — see § Merging PRs for the exact boundary.** |
| 5 | Session ends (touched code or content) | Update `CLAUDE.md` + `ROADMAP.md` in same commit; write `archive/HANDOFF-YYMMDD.md`; update `archive/README.md` |
| 6 | Stale merged `claude/*` branches detected | Delete them via `git push origin --delete` — no prompting |
| 7 | Owner asks for a TestFlight build | Bump `CURRENT_PROJECT_VERSION` in `project.pbxproj`, commit + push, then run `xcodebuild archive` (see `docs/testflight.md` § "Archive command"). Owner then does Organizer → Distribute App → Upload (2–3 min). |
| 8 | New tour added (to `Tours.json`) that lacks images | Run the image pipeline (§ Image Pipeline) automatically — no prompting — and **reply with a numbered, labeled contact sheet of ~12 verified CC0 candidates per tour so the owner can pick hero + gallery by number** (e.g. `"3 hero, 1, 7, 9"`). This is the standard "upload tours without images" flow. **Exception: owner-supplied images (Portugal/Porto/Lisbon tours) — do not run pipeline, use the provided assets.** |

## Image Pipeline

Standard process for sourcing hero + gallery images for tours that don't have owner-supplied assets. Run this automatically whenever a new tour is added without images, or when the owner asks to improve existing images.

**Tools:** Unsplash API + Openverse API (sources) → Gemini vision (verification gate) → Pillow (resize/crop) → gh-pages (hosting) → Tours.json patch.

**Sources & API keys** (owner pastes secret-bearing keys fresh each session — do not store):
- **Unsplash:** `Client-ID <key>` header on `https://api.unsplash.com/search/photos`. Generic/atmospheric travel shots; weakest at exact-subject match.
- **Openverse:** `GET https://api.openverse.org/v1/images/` — aggregates 800M+ CC/public-domain works across 45+ sources (Wikimedia Commons, Flickr, Europeana, …) in one call. Search the place by name. No key needed for low volume, but **anonymous is throttled hard (~5 req/hr, 100/day)** — too low for a full pipeline run. To get the Standard tier (much higher limits): register once via `POST https://api.openverse.org/v1/auth_tokens/register/` (JSON: `name`, `description`, `email`) → returns `client_id` + `client_secret`; exchange them for a Bearer token via OAuth2 `client_credentials` at `POST /v1/auth_tokens/token/`, then send `Authorization: Bearer <token>`. Useful query params: `q`, `license`/`license_type`, `source`, `category`, `aspect_ratio=wide`, `size`, `page`, `page_size`. **License policy (owner decision 2026-06-08): prefer public-domain only — `license=cc0,pdm`.** The app has NO attribution UI (no credit field on `Tour`), and CC BY / BY-SA legally require crediting creator + license. PD images (`cc0`, `pdm`) carry no such obligation, so they're safe to ship as-is. Only fall back to BY/BY-SA if PD coverage is too thin *and* the owner OKs it for that tour. Wikimedia downloads: send a descriptive `User-Agent` and space requests ~1.5s apart — `upload.wikimedia.org` returns **HTTP 429** on rapid bursts. **Caveat: Openverse depth varies wildly by subject** — strong for some landmarks, near-empty for others (e.g. Seagram Building = one Wikimedia "Park Av" series + false matches). For a thin subject, query **Wikimedia Commons directly** (MediaWiki API, no key — e.g. the building's `Category:` page) for a deeper, cleaner pool, or add Unsplash.
- **Gemini:** `?key=<key>` on `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent`
- Gemini key format: starts with `AQ.` (NOT `AIzaSy` — do not prepend anything)

**Pipeline steps:**
1. **Search** — 5–6 targeted queries per tour, ~3 results each, covering different vantage points (exterior, interior, aerial, detail, night, golden hour, etc.). **Sourcing order under the CC0-only policy:** (a) **Openverse** `license=cc0,pdm` (search the landmark by name); (b) if too thin, **Wikimedia Commons directly** filtered to PD (the building's `Category:` page, no key); (c) **Unsplash** (`orientation=landscape&content_filter=high`) for atmospheric coverage — Unsplash needs no per-image credit so it's policy-safe. Filter to images that can crop to 1200×900 without upscaling (`min(w,h)≥900` and the long side ≥1200). Dedupe by image URL before the verify step.
2. **Verify** — Send each candidate to `gemini-2.5-flash-lite` with a subject-specific YES/NO prompt. Reject non-subject images silently. **Mandatory for Openverse — its result titles are unreliable** (generic strings like "Park Av Nov 2025 01" that may be a neighboring building, a streetscape, or a different landmark entirely); never trust Openverse metadata for subject match, always verify the pixels.
3. **Label** — Present the verified candidates (~10–12; fewer if the subject is thin) as **individual full-size images, sent inline** (each ~1000px long side, with a large number badge + source/license tag burned into the corner), batched a handful per `SendUserFile` call with a group caption. **Do NOT use a small contact-sheet grid** — owner feedback (2026-06-08): grid tiles are too small to judge. The number burned onto each image is how the owner refers back to it. Use a distinct number namespace per source when mixing (e.g. `1–35` CC0 vs `U01–U32` Unsplash) so picks are unambiguous.
4. **Owner picks** — Owner replies e.g. `"U07 hero, U01, U22, U20"`. First = hero; the rest = gallery order. Default target is **1 hero + up to ~5 gallery** (owner can pick fewer/more, mix sources, or say "none, leave as-is" / "keep current hero" / "find more on unsplash").
5. **Process** — Crop selections to final 1200×900 WebP (no label). Name: `{audio-slug}_hero.webp`, `{audio-slug}_2.webp`, etc.
6. **Upload** — Commit to `gh-pages` branch under `images/`. Pull + rebase if non-fast-forward.
7. **Patch Tours.json** — Replace `heroImageURL` + set/update `additionalImageURLs`. Commit + push to session branch.

**Special cases:**
- Owner says "keep current hero" → leave `heroImageURL` as-is; only add `additionalImageURLs`.
- Owner says "keep current hero in gallery" → put original URL as last entry in `additionalImageURLs`.
- Too few verified images → tell owner, offer to fetch more with different queries, or skip.
- Unsplash rate limit (50 req/hr free tier) → pause, note time to reset, continue other work.
- Openverse rate limit → anonymous is ~5 req/hr (100/day); if hit, authenticate (register → Bearer token, see Sources above) for the Standard tier, or fall back to Unsplash-only for that run.
- Openverse subject too thin (few/no PD matches) → say so, then try Wikimedia Commons directly (the building's `Category:` page) and/or Unsplash, rather than settling for off-subject or BY-SA shots.

**Audio slug** = the filename stem of the tour's `audioURL` (e.g. `audio/empire-state-building.mp3` → `empire-state-building`). Use this as the image filename prefix. Some older slugs use dots or mixed case — match exactly.

**Image URL base:** `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

**gh-pages worktree:** `/tmp/ghpages` (already set up; `git pull origin gh-pages --rebase` before push if rejected).

## Current State (2026-06-07)

### TestFlight 1.0 (36) (session 27 — web/PM)

Build cut to ship the maker-page polish + save-maker feature plus recent chrome/search fixes and new galleries. Build bumped 35 → 36 direct-to-main (`ca671c8`, app-target lines only; test target stays 1). `xcodebuild archive` clean at `/tmp/Atlas-20260607-2112.xcarchive` (fast — DerivedData warm from build 35; embedded version verified `1.0 (36)`). No validation 90474 — `UIRequiresFullScreen` from build 34 held. Owner uploaded via Organizer. **TestFlight 1.0 (36) is live.**

Carries: **PR #163** (full-edge module + no drawer leak on pushed details), **#164** (place results limited to cities/landmarks, businesses dropped), **#166** (Maker + Search page background pinned to the module shade), **#167** (maker editorial typography + square thumbnails), **#168** (new galleries: The Shed, Citi Field, LOVE Sculpture), **#170** (save-maker bookmark + nav chrome + Library section). No project changes this session beyond the pbxproj bump. **Catalog: 149 tours / 3 makers.**

**Latest TestFlight build: 1.0 (36)** — uploaded 2026-06-07.

### TestFlight 1.0 (35) (session 26 — web/PM)

Build cut to ship sessions 24–25's player + search work plus the latest content. Build bumped 34 → 35 direct-to-main (`ce32d88`, app-target lines only; test target stays 1). `xcodebuild archive` clean at `/tmp/Atlas-20260607-0649.xcarchive` (~4 min, no validation 90474 — `UIRequiresFullScreen` from build 34 held). Owner uploaded via Organizer. **TestFlight 1.0 (35) is live.**

Carries: **PR #159** (Player presented from top window — gapless transition + floating island on retract), **PR #160** (place-search perf via `MKLocalSearchCompleter` + tap spinner), and **7 tours' new photo galleries** (Intrepid, Little Island, Manhattan Bridge, Chelsea Hotel, Four Freedoms Park, Unisphere, Cooper Union). No Swift/asset/project changes this session beyond the pbxproj bump. **Catalog: 149 tours / 3 makers.**

**Latest TestFlight build: 1.0 (35)** — uploaded 2026-06-07.

### Search polish + place-search performance (session 25)

Owner-directed Search pass, turn-by-turn at the simulator. Two PRs to `main`. **No build bump (34). No data-shape changes. 88/88 tests pass.**

- **[PR #154](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/154) — Search polish.** Typography flattened to the `caption` token across the search field, recent searches, and no-results copy; result-row + maker-row **titles stay `body` ALL CAPS** (the one exception — mirrors the Player's "stop titles → BODY all-caps"). Result rows: single-line all-caps title with tail truncation, **maker-name-only** subtitle (category + "•" bullet dropped), **square-corner** thumbnails — removes the prior two-line category•maker wrap. New **Makers** result section above Tours: maker rows (circular emoji avatar, all-caps name, tour-count subtitle) deep-link to `MakerView` via the host nav stack. `SearchView.swift` only; the shared `SearchBar` (Home) untouched.
- **[PR #160](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/160) — place-search performance.** Replaced the per-keystroke `MKLocalSearch` (a full network round-trip on every character — the typing lag) with **`MKLocalSearchCompleter`**: lightweight title/subtitle suggestions stream as you type; the heavy `MKLocalSearch` geocode runs **once, on tap**, to resolve the coordinate the map flies to. `PlaceSearchService` rewritten around the completer (delegate-based; intentionally **not** `@MainActor` so the conformance doesn't cross an actor boundary — callbacks already arrive on main). The tapped place row shows a **spinner** while it resolves; extra taps ignored mid-resolve. `Features/Search/` only.
- **[PR #164](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/164) — place results limited to cities/landmarks.** Added an `MKPointOfInterestFilter` to the completer that includes only landmark-type POI categories (museums, parks, monuments, theaters, stadiums, zoos, beaches, universities, etc.) and excludes businesses (food/retail/services). Address completions (cities, towns, neighborhoods, regions) are unaffected — so "London" → London/England, Londonderry, etc. (no "London Fetish"); "Central Park" still resolves. The allowlist is deliberately tighter than the map's `HomeMapSection.tourPOI` (no transit / hotels / parking / EV — useful to *see* on the map, but not search destinations). `PlaceSearchService.swift` only.

### Full-screen Player polish, round 2 (session 24)

Continued the Player polish from session 22, owner-driven at the simulator. One `PlayerView`-focused PR. **No build bump (stays 33). No `AudioPlayerService` API changes. 88/88 tests pass.**

- **Player now presented from the top window.** `PlayerView` is a `.fullScreenCover` on `BottomModuleRoot` (the secondary window that hosts the mini-player + tab bar) instead of `ContentView`. The cover slides up over the module **in the same window**, so the module no longer has to be hidden/shown around the player — this removes the transition gap (module briefly missing) that no timing tweak could fix. Removed `BottomModuleWindowController.setHidden` + the App-level show/hide. `PassThroughWindow.hitTest` now claims all touches while that window is presenting a modal, so the player is fully interactive.
- **Floating island on retract.** Opening the player dismisses any detail sheet underneath (`ContentView` `onChange(showingFullPlayer)` → `tourPresenter.dismiss()`), so retracting returns to the tab root — Home shows its floating island instead of edge-to-edge bars. `BottomModuleRoot` reads `showingFullPlayer` so geometry recomputes on toggle.
- **Now-playing block:** title is a single line — centered when it fits, `MarqueeText` scroll when too long; caption always reserves 3 lines (`reservesSpace: true`).
- **Volume:** system `MPVolumeView` bracketed by `speaker.fill` / `speaker.wave.3.fill` icons; 12pt thumb. Device-only (blank in sim) by design.

Real-device check still pending: volume/AirPlay (device-only) and the drag-to-dismiss / present-retract animations (sim HID can't drag). See `archive/HANDOFF-260606-2.md`.

### Place search (session 23)

Implementation session — **place/location search added to Search**. Owner approved lifting the prior "Home map camera is settled — don't touch" constraint for this additive change. **No build bump (stays 33). 88/88 tests pass (4 new).**

- **What it does.** Typing a place name (e.g. "London", "Brooklyn") surfaces a **Places** section above the Makers/Tours catalog results. Tapping a place dismisses Search and glides the Home map camera to that region. If there are no Atlas tours there, a transient **"No Atlas tours here yet — Atlas tours are in New York and Portugal."** hint shows on the map.
- **`PlaceSearchService`** (`Features/Search/`) — originally an `@MainActor @Observable` wrapper around Apple's **`MKLocalSearch`** (no new deps, no backend), debounced 300ms, 4-result cap, per-feature zoom from the placemark's `CLCircularRegion` radius (clamped 1–50km). *Rewritten in PR #160 (session 25) around `MKLocalSearchCompleter` for instant type-ahead — see that block above; the per-feature zoom logic is retained on the on-tap resolve.*
- **`SearchView`** — new Places section (gold `mappin.and.ellipse`, BODY all-caps name, locality subtitle, `arrow.up.right` affordance) above Makers/Tours. Section headers now show whenever Places *or* Makers are present; tours-only stays headerless (unchanged). Tapping a place sets `HomeSharedState.pendingMapMove` + `dismiss()`. Places are **not** recorded in `RecentSearch`.
- **`HomeSharedState.pendingMapMove`** — one-shot, UUID-keyed `PendingMapMove` (Equatable for `.onChange`; re-taps to the same place re-fire). The channel from Search → map without lifting `cameraPosition` out of `HomeView`.
- **`HomeView`** — observes `pendingMapMove`, flies the camera (additive; recenter / pin-tap / startup paths untouched), retracts the drawer, and shows the no-tours hint via `.overlay` (attaching it as a ZStack sibling of the UIKit `Map` did **not** composite — use `.overlay`). Hint auto-dismisses after 6s or on a map tap.
- **`MapRegionGeometry.anyStop(of:inside:)`** (`Features/Home/`) — pure, unit-tested; reuses the existing antimeridian-aware `MKCoordinateRegion.contains`.
- **Known / follow-ups.** In the **simulator** the no-tours hint can paint a few seconds late on the first fly to a far, uncached region (MKMapView tile streaming starves SwiftUI overlay compositing) — verify prompt on device/TestFlight. One cosmetic `MKMapItem.placemark` iOS-26 deprecation warning left in `PlaceSearchService` (kept for the per-feature zoom; new address API shape uncertain). Folds in the same day's Search-polish commit (caption typography, single-line result rows, maker result section). See `archive/HANDOFF-260606.md`.

### Full-screen Player polish (session 22)

Implementation session — owner-driven, turn-by-turn at the simulator. Two `PlayerView`-focused code PRs to `main`. **No build bump (stays 32). No `AudioPlayerService` API changes. 84/84 tests pass.**

- **[PR #148](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/148) — full-screen cover + caption typography + carousel.** `PlayerView` now covers the whole screen; the bottom-module window is hidden while it's up via new `BottomModuleWindowController.setHidden(_:)`, toggled from the App entry on `appShared.showingFullPlayer` (the module window sits at `windowLevel = .normal + 1`, above modals, so a cover alone wouldn't hide it). Hero carousel matched to `TourDetailView` (square corners, pinch-to-zoom, no load crossfade). Redundant tour-title section removed; now-playing block moved up under the carousel. Text flattened to the `caption` token.
- **[PR #150](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/150) — drag-to-dismiss sheet, overflow menu, 5-button transport.** Player is a `.fullScreenCover` (edge-to-edge to the top) with a grab handle driving a **custom drag-to-dismiss** (`@State dragOffset` + `.offset`, dismiss past ~150pt / a fling). **••• overflow menu** on the hero's top-right mirroring the detail sheet (Download · Save · Share · Follow [disabled] · Go to creator · Report) — player wrapped in its own `NavigationStack` so "Go to creator" pushes `MakerView`. Transport reworked to **five equal columns** (`speed · skip-back-10 · play · skip-forward-10 · next-track`) so play is screen-centered; skip ±10s always live, next-track disabled on single-stop; speed menu gained 0.5×/0.75×. Scrubber is a thin **gold** line (no thumb knob); play + scrubber tinted `AtlasColors.mapPin`. Stop titles → BODY all-caps; current-stop caption truncates to 3 lines with inline Read more. **System volume slider** (`MPVolumeView`) below the transport row — draws on device only, **blank in the simulator by design**.

Owner-confirmed constraints honored: mini-player design untouched (only its window's visibility toggles); native iOS menus kept (system font — `UIMenu` typography isn't customizable). **Drag-to-dismiss feel + volume slider + AirPlay button need a real-device check** (sim can't drag; MPVolumeView is device-only). See `archive/HANDOFF-260605.md`.

### Image pipeline pass — 14 NYC tours backfilled (session 20)

Web/PM session. No new tours, no Swift changes, no build bump. Catalog stays at **138 tours / 147 stops / 3 makers**. Branch `claude/session-012bd7xvvgfz8cpkucw3bqy8-0MeY7` open, not yet merged to main.

Image pipeline codified as **Rule #8** (+ full § Image Pipeline section added this session). Ran the pipeline on 14 NYC tours — Unsplash fetch → Gemini verify → owner picks labeled previews → crop to 1200×900 WebP q82 → gh-pages → Tours.json patch:

- **Empire State Building** — new hero (obs deck) + 3 gallery
- **Chrysler Building** — new hero (gargoyle) + 3 gallery
- **Brooklyn Bridge** — new hero + 4 gallery
- **Met Museum** — new hero + 2 gallery
- **Bethesda Terrace** — new hero (fountain) + 3 gallery
- **Grand Central** — kept Wikimedia hero, 2 exterior gallery shots added
- **High Line** — kept Wikimedia hero, 1 overlook gallery shot added
- **Rockefeller Center** — new gh-pages hero, ice rink + original Wikimedia in gallery
- **One WTC** — new hero + 2 gallery
- **Guggenheim** — new hero (FLW facade) + 4 gallery
- **Times Square** — skipped (owner: "None, leave as-is")
- **Statue of Liberty** — new hero (aerial) + 4 gallery
- **Washington Square Park** — kept Wikimedia hero, 5 gallery shots added
- **Flatiron Building** — new hero (symmetry) + 3 gallery
- **Lincoln Center** — new gh-pages hero (plaza-wide) + night gallery + original Wikimedia in gallery

~25 NYC tours still need gallery images. 9/11 Memorial is queued next (background fetch script running at session end). See `archive/HANDOFF-260604.md` for in-flight details and the full remaining queue.

**Latest TestFlight build: 1.0 (28)** — uploaded 2026-06-03 evening (session 19).

### Six home polish PRs + TestFlight 1.0 (28) (session 19)

Six small focused home-screen tweaks layered on top of session 18's content, plus the build bumps that cut 27 (left unshipped by session 18) then 28 (defensive re-bump before owner upload). **TestFlight 1.0 (28) is live.** Catalog now **138 tours / 147 stops / 3 makers** — **96 Atlas Studio NYC** (105 stops) + 37 Atlas Studio Porto + 5 Atlas Studio Lisbon — from session 18's 131 + PR #127's 7 central Porto classics (Cathedral, São Bento, Clérigos, Ribeira, São Francisco, Bolsa, Dom Luís I) + 4 more NYC tours added during the session-18 web/PM run (Grand Concourse, Strivers' Row, IAC Building, The Strand Bookstore).

- **[PR #128](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/128) — muted standard map style.** `MapStyle.standard` now uses `.standard(emphasis: .muted)` so the canvas reads as desaturated and the pins / placecard / chrome stop competing with the map's own colour. Hybrid + Imagery unchanged.
- **[PR #129](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/129) — pin sizes + cluster count typography.** `StopPin` diameter **14 → 16 pt** (unselected) and **18 → 20 pt** (selected). Cluster count text dropped semibold-SF-Pro for **SF Mono regular** at 12 pt — matches the new editorial voice on the home caption surfaces.
- **[PR #130](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/130) — curated POI categories.** New `HomeMapSection.tourPOI` static allowlist passes `pointsOfInterest: .including(...)` to the standard map style. Cultural / civic / nature / transit kept; ATMs, gas stations, banks, retail, nightlife, restrooms, and the entire activity-venue group hidden. Single list to iterate on.
- **[PR #131](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/131) — drawer list scoped to map view.** `displayedTours` now filters to tours whose stops fall inside `sharedState.visibleRegion` and sorts by tour-centroid distance from the map *center*. Header count collapses to `displayedTours.count` so "N TOURS IN VIEW" always matches the cards below. Strip-clipping helpers + `currentScreenHeight()` shim + unused `UIKit` import dropped. Doc comment flags the rails direction — when the drawer pivots to a rail layout (`HomeRailsViewModel`), this becomes the "In map view" rail and a sibling rail sorting by `Tour.distance(from: userLocation)` becomes "Near you" — no model change required.
- **[PR #132](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/132) — keyboard overlay on bottom module + drawer.** `BottomModuleRoot` and `BottomSheet` switched from `.ignoresSafeArea(.container, edges: .bottom)` to `.ignoresSafeArea(.all, edges: .bottom)`. Focusing a `TextField` (e.g. inside `SearchView`) no longer pushes the bottom module + drawer up by the keyboard's height — the keyboard slides up *over* them, anchored at the screen bottom.
- **[PR #133](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/133) — recenter on pin tap.** `onPinTapped` animates `cameraPosition` to centre the tapped pin's coordinate at the current visible span (read off `sharedState.visibleRegion?.span`, fall back to `recenterSpan`). Pin sits at screen geometric centre; placecard rises above it. Reads as a pan, not a zoom.

`xcodebuild archive` clean at `/tmp/Atlas-20260603-2123-b28.xcarchive`; owner uploaded via Organizer. Build 27 was bumped direct-to-main in session 18 (`89dd5df`) but never archived; first archive of this session cut at 27, owner then asked to defensively bump to 28 — landed via [PR #134](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/134).

**Latest TestFlight build: 1.0 (28)** — uploaded 2026-06-03 evening.

### 18 new NYC tours + TestFlight 1.0 (26) (session 18 — web/PM)

Web/PM session. Eighteen new NYC tours had been landing direct-to-main between sessions; this session bundled them into a TestFlight cut. Catalog **113 → 131 tours**, 3 makers; NYC-area **73 → 91**. Multi-stop count **1 → 2**.

- **5 NYC tours (114–118, `7e3e9a9`):** Four Freedoms Park, Green-Wood Cemetery, African Burial Ground National Monument, Cooper Union Foundation Building, Tompkins Square Park.
- **2 NYC tours (119–120, `9df3983`):** Museum of Modern Art (MoMA), Bryant Park.
- **Fifth Avenue Walk multi-stop tour (121, `88bf893`)** — **second multi-stop tour ever** in the catalog (joining AMNH Four Facades from 2026-05-26).
- **2 NYC tours (122–123, `8261107`):** Federal Hall, Columbus Park (Chinatown).
- **2 NYC tours (124–125, `64a04e3`):** Schomburg Center for Research in Black Culture, Coney Island.
- **2 NYC tours (126–127, `79f6b49`):** Eldridge Street Synagogue, Grand Army Plaza (Brooklyn).
- **2 NYC tours (128–129, `fab0e53`):** Grand Concourse, Strivers' Row.
- **2 NYC tours (130–131, `ab7c1f8`):** IAC Building (Frank Gehry, 2007), The Strand Bookstore.
- **Two validator-caught typo fixes** before the build: `triggerMode geofence → geofenced` across tours 114–131 (`3235d33`), and `TourKind multi → multiStop` on Fifth Avenue Walk (`7c11003`).
- **Build bumped 25 → 26 in `17dba88`** — direct-to-main per established pattern (`aba765f` for 25, `401358f` for 24). Single-line pbxproj edit. `xcodebuild archive` clean at `/tmp/Atlas-20260603-1840.xcarchive` (~3 min). Owner uploaded via Organizer.

No Swift / asset / project structure changes this session beyond the pbxproj bump.

**Latest TestFlight build: 1.0 (26)** — uploaded 2026-06-03 evening.

### Home polish batch + cluster smoothness + TestFlight 1.0 (25) (session 17)

Long iterative implementation session — owner sat at the sim and asked for one or two changes at a time, I implemented + rebuilt + relaunched, they reviewed and either kept iterating or moved on. Most changes are 1-2 lines but they add up to a meaningful refresh of the home chrome. Cluster smoothness (item #6 from the original 11-item brief) also landed.

- **[PR #113](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/113) — home polish batch.** Search bar + chip row tightened (`AtlasSpacing.searchBarHeight` 46 → 44 to match the 44pt map control button diameter; horizontal padding `lg` (24) → `md` (16)). Recenter button zoom widened `0.005°` → `0.02°` (~2km neighborhood view; initial-launch span `0.1°` from PR #103 unchanged). New `Maker.avatarEmoji: String?` field — Atlas Studio NYC maker shows **🍎** in mini-player + maker page; resolution order is emoji → URL → bundled fallback. Typography tokens overhauled: `caption` is now **13pt SF Mono regular** (was `Font.caption` 12pt SF Pro); `body` is now **15pt SF Pro regular** (was `Font.body` 17pt; pinned fixed-size so Dynamic Type stops scaling that token — flagged in code comment as a follow-up). `captionSerif` doc clarified that it intentionally diverges from caption now and stays at SwiftUI's semantic placeholder. "N tours in view" header dropped headline → body → finally **caption**, with all variant strings **ALL CAPS** (`LET'S EXPLORE TOGETHER!`, `NO TOURS IN VIEW`, etc.); the animated dot cycle for mid-pan is unchanged. Map control glyphs 16 → 20pt. Tab bar icons 22 → 20pt; tab labels uppercased at display site (enum value stays proper-cased so VoiceOver pronounces "Home" as a word). Mini-player: title `caption` → `body`; title strings uppercased; play/pause glyph 18 → 20pt (matches skip-forward); leading inner inset `lg` → `md` (avatar's left edge 16pt from bar left edge); new `trailingInnerInset: CGFloat = 12` (ring's outer right edge 16pt from bar right edge); bodyContent HStack spacing `sm` → `md` (avatar→text gap 8 → 16pt); outer body HStack spacing `sm` → 0 (skip-glyph right edge → ring left edge lands at exactly 16pt visually, derived from `44 − 10 − 18` with controls edge-to-edge but glyphs centered). Drawer `BottomSheet.topCornerRadius` 30 → **28pt** (bottom radius / phone-radius 56 unchanged).
- **Cluster smoothness — item #6 closed.** Original brief said clusters morphed on pure pan. Code already used an absolute (lat=0, lon=0) grid origin so it *should* have been stable; on-device review proved otherwise. Cause: cell pitch derives from `region.span / cellsAcross`, and MapKit reports sub-percent drift on `region.span` when a pan gesture settles even without zoom — any drift re-buckets markers near cell boundaries. Fix: new `HomeMapSection.snappedSpan(_:)` static helper rounds the span to two significant figures before cell pitch is computed. Sub-percent drift collapses to a single value; real pinch-zoom (always several percent per step) still crosses snap boundaries cleanly. Pin diameters were already constants; no change there.
- **[PR #114](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/114) — build bump 24 → 25.** Admin-merged. `xcodebuild archive` clean at `/tmp/Atlas-20260602-2310.xcarchive`; owner uploaded via Organizer. **TestFlight 1.0 (25) is live.**

`xcodebuild test` succeeds locally on iPhone 17 Pro / 26.5 throughout the session.

**Latest TestFlight build: 1.0 (25)** — uploaded 2026-06-02 evening.

### TestFlight 1.0 (24) + 11 Portugal tours (session 16 — web/PM)

Web/PM session — single 11-tour Portugal batch under PR [#110](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/110), then build bump 23 → 24 via PR [#111](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/111) (admin-merged, single-line metadata). `xcodebuild archive` clean at `/tmp/Atlas-20260602-2146.xcarchive`; owner uploaded via Organizer. **TestFlight 1.0 (24) is live.**

- **11 new Portugal tours** (catalog 102 → 113, 105 → 117 stops):
  - **Atlas Studio Porto (8):**
    - Batalha Centro de Cinema (Porto, culturalHeritage, 167s) — 1947 Art Deco cinema, Estado Novo censors destroyed the hammer-and-sickle facade; restored in 2022 stainless steel; Atelier 15 renovation
    - Building in Senhora da Luz (Porto, architecture, 139s) — Souto de Moura, 2016; Foz do Douro 3-family apartment block with exposed-concrete grid on east/west elevations
    - Mosteiro Santo Agostinho da Serra do Pilar (Vila Nova de Gaia, sacredSites, 151s) — 1538–1670 UNESCO monastery, Portugal's only circular cloister; Wellington spotted the wine barges from here in 1809
    - Teatro Rivoli (Porto, musicAndPerformance, 167s) — Júlio Brito Art Deco redesign, 1923; Praça Dom João I, opposite Porto City Hall; Fantasporto host
    - Trindade Metro Station (Porto, architecture, 146s) — Souto de Moura, six-line interchange, white-tile pavilions + 736-tile 2025 azulejo mural for the Carnation Revolution's fiftieth
    - Vodafone Headquarters (Porto, architecture, 158s) — Barbosa & Guimarães, 2009; faceted concrete shell on Boavista, structure-as-skin (no internal frame)
    - Municipal Library of Viana do Castelo (Viana do Castelo, literature, 158s) — **first Viana do Castelo tour** — Álvaro Siza, 2008; 45m white-concrete square with 20m void cut through the upper volume, in Távora's waterfront master plan
    - Biblioteca Pública e Arquivo Regional Luís da Silva Ribeiro (Angra do Heroísmo, literature, 167s) — **first Azores tour in catalog** — Inês Lobo; Mies van der Rohe Award nominee 2017; UNESCO Angra
  - **Atlas Studio Lisbon (3):**
    - Adega Mayor (Campo Maior, architecture, 135s) — **first Campo Maior + first Alentejo tour** — Álvaro Siza, 2006 winery for the Nabeiro coffee family; 120m white facade on the Spanish border plain
    - Óbidos (Óbidos, culturalHeritage, 155s) — **first Óbidos tour** — Vila das Rainhas; 1,565m of medieval walls; the keep is a layered Moorish / 1148-reconquest / 1755-earthquake palimpsest
    - Capela do Monte (Lagos, sacredSites, 173s) — **first Lagos + first Algarve tour** — Álvaro Siza, 2016; his only Algarve building; 10×6m non-denominational hilltop chapel above Monte da Charneca, no electricity / heating / running water
- Audio (11 MP3s, slug-based) uploaded across 3 chunked commits — `f4e849d`, `259309d`, `7a67dc9` — after persistent HTTPS 408s on the combined push.
- Images (42 webp + 3 jpg-for-Adega) at commit `24c6e36`. Naming follows the established `<Base>_hero.<ext>` / `<Base>_N.<ext>` pattern.
- All 22 live-URL spot-checks (11 audio + 11 heroes) returned 200 against `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/`.
- Validator: 3 makers / 113 tours / 117 stops, no issues. CI green (validator + iOS Simulator build + unit tests).
- **Atlas Studio Porto** grows 22 → 30 tours; **Atlas Studio Lisbon** grows 2 → 5.
- **New cities in catalog (5):** Viana do Castelo, Angra do Heroísmo, Campo Maior, Óbidos, Lagos. Mainland Portugal coverage now spans north (Viana / Porto / Braga / Marco de Canaveses / Gondomar / Matosinhos / Vila Nova de Gaia), centre (Óbidos), Lisbon belt (Lisbon / Cascais), Alentejo (Campo Maior), Algarve (Lagos) — plus Terceira (Azores).

**Latest TestFlight build: 1.0 (24)** — uploaded 2026-06-02 via Organizer.

### Home-screen polish pass + TestFlight 1.0 (23) (session 15)

Eleven-item home-screen polish brief from the owner. Seven items implemented and shipped across two PRs; three deferred as informational; one (clustering) parked for a future visual verify.

- **[PR #103](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/103) — items #1 + #4 (map cleanup).** Default location at launch is now location-based: on first appear the camera recenters on `locationManager.userLocation` at a wider span (`initialUserSpan = 0.1°` ≈ 11 km N-S, ~Manhattan length). Guarded by `didCenterOnUser` so subsequent location updates don't snatch the camera back from user pans. When permission is denied / no reading arrives, the existing NYC fallback region is retained (permission was already requested at `ContentView.onAppear`). Recenter button keeps the tighter 0.005° span. Look Around button + probe + `LookAroundView.swift` removed entirely; map-mode picker and recenter are the only two map controls now.
- **[PR #104](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/104) — items #5, #7, #9, #10, #11 (drawer + cards).** Drawer's `.large` detent now caps below the search bar + chip row via a new `BottomSheet.topReservedHeight` parameter (search/chips stay anchored above when fully expanded). New `AtlasSpacing.searchAndChipsBlockHeight` token (`sm + searchBarHeight + sm + searchBarHeight = 108 pt`) is the single source of truth for the search/chips block. `PlacecardView` background swapped from `.regularMaterial` to `AtlasColors.secondaryBackground` (matches drawer / bars / search / chips). `TourListCard` hero corner: category badge replaced by a bookmark Button wired to `LibraryStore.toggleSaved` / `isSaved`; category dropped from the card. `isMapMoving` lifted from `HomeView.@State` into `HomeSharedState`; drawer header shows a `TimelineView`-driven `. / .. / ...` dot cycle (0.4 s period) while the map is mid-pan, instead of letting the count flicker through "0 tours in view."
- **Drawer-gap bug fixed mid-review.** Initial `BottomSheet.heightForDetent(.large)` formula was `topGap = topInset + topReservedHeight` — but the GeometryReader's bounds already start below the device top safe area while `geo.safeAreaInsets.top` still **reports** the device's actual inset value (it describes the device, not what remains to consume). The `+ topInset` was double-counting the offset by ~59 pt. Discovered via bright-magenta diagnostic per `feedback-visual-debugging.md`; removed in BottomSheet and in both `drawerVisibleHeight` mirrors (HomeView, HomeDrawerContent). Gap is now mathematically and visually `AtlasSpacing.sm` (8 pt), matching the search-bar-to-chips gap.
- **[PR #105](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/105) — build bump 21 → 22 for TestFlight.** Merged with `--admin` (metadata-only). `xcodebuild archive` clean at `/tmp/Atlas-20260601-2233.xcarchive`; owner uploaded via Organizer.
- **[PR #107](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/107) — drag clamp.** Owner reviewed 1.0 (22) on device and reported that the drawer could be dragged past `.large` (covering the search bar / chip row) before snapping back on release. Cause: drag-time visual ceiling in `BottomSheet.body` was `geo.size.height - horizontalInset` (nearly full screen). Fix: clamp the ceiling to `heightForDetent(.large, ...)` so the drawer can never grow past the resolved `.large` height during a gesture. `.large` already respects `topReservedHeight` so the drag visually bounds where the snap will land.
- **[PR #108](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/108) — build bump 22 → 23.** Admin-merged. `xcodebuild archive` clean at `/tmp/Atlas-20260601-2302.xcarchive`; owner uploaded via Organizer. **TestFlight 1.0 (23) is live.**

**Deferred / informational only (no code change this session):**

- **#2 search bar + chip height vs map button diameter.** Measured map buttons at 44 pt; search bar + chips at 46 pt (2 pt difference). Owner declined the match for now.
- **#3 typography audit.** Home uses 3 text styles (body / caption / headline) plus 3 SF-Symbol sizes (12 / 16 / 40 pt). Already at the floor; further reduction would crush hierarchy.
- **#8 horizontal alignment.** Today the bottom module sits at 8 pt, map buttons at 16 pt, search/chips at 24 pt. Three gutters; owner has the numbers.
- **#6 clustering smoothness.** Code already uses an absolute (lat=0, lon=0) grid origin so panning without zoom should not re-cluster, and pin diameters are constant across zoom. Skipped a code change pending a visual verify together — not done this session.

84/84 tests pass after both PRs and after the diagnostic-driven gap fix.

**Latest TestFlight build: 1.0 (23)** — uploaded 2026-06-01.

### TestFlight 1.0 (21) + 6 Porto-area tours (session 14 — web/PM)

Session 14 was a web-only PM session — six new tours under Atlas Studio Porto, then TestFlight build 21 cut to ship them. Tours landed via [PR #100](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/100); build bump via [PR #101](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/101) (auto-merge classifier flagged the historical direct-to-main bump pattern, so this one went via short-lived PR).

- **6 new Porto-area tours** (catalog 91 → 97):
  - Porto Tram Museum (Porto, culturalHeritage, 172s) — Massarelos thermoelectric station, 1915
  - Church of Santa Maria (Marco de Canaveses, sacredSites, 188s) — Álvaro Siza, 1996; **first Marco de Canaveses tour**
  - Fundação Livraria Lello (Matosinhos, culturalHeritage, 148s) — foundation HQ in the 14th-c Mosteiro de Leça do Bailio on the Portuguese Camino
  - Livraria Lello (Porto, culturalHeritage, 176s) — Art Nouveau bookstore, 1906 — Esteves' first reinforced-concrete staircase in Portugal
  - Parque de São Roque (Porto, natureAndParks, 161s) — former Calém Port-wine Quinta da Lameira; garden by Jacinto de Matos 1900–1911
  - Pavilhão Multiusos de Gondomar (Gondomar, architecture, 164s) — Álvaro Siza, 2007; **first Gondomar tour**
- Audio (6 MP3s, slug-based) + 28 webps uploaded to `gh-pages` (commits `332367f` audio, `2f3dc04` images).
- **The two Lellos ship as distinct tours, owner-confirmed.** Foundation entry's longDescription leads with the Knights Hospitaller monastery on the Camino and Siza's foot-washing fountain (the foundation is a closing note); bookstore entry's longDescription leads with Decus in Labore, the 1906 Esteves staircase, Viúva Lamego skylight, and the Rowling-denied Harry Potter mythology.
- **Catalog: 97 tours, 3 makers**. New cities in catalog: **Marco de Canaveses**, **Matosinhos**, **Gondomar** (Matosinhos hosts the Leça do Bailio monastery; Leça da Palmeira was already present from prior Porto batches).
- Build bumped 20 → 21; archive at `/tmp/Atlas-20260601-2057.xcarchive`; owner uploaded via Organizer. **TestFlight 1.0 (21) is live.**

**Latest TestFlight build: 1.0 (21)** — uploaded 2026-06-01 via Organizer.

### 10 new NYC tours + coordinate/hero fixes (session 13 — web/PM)

Session 13 was a web-only PM session — no Swift changes. All commits direct to `main`.

- **10 new NYC tours added** (catalog 81 → 91): Domino Park (Brooklyn), Wave Hill (Bronx), Queens Museum, Museum of the Moving Image, Snug Harbor Cultural Center (Staten Island), Yankee Stadium (Bronx), Citi Field, Madison Square Garden, Riverside Church, One World Trade Center. All Atlas Studio NYC, single-stop, geofenced. Audio on `gh-pages`; all hero images verified live.
- **Hero image audit** — all 10 new tours had guessed/broken Wikimedia URLs on first commit; all fixed with verified hash paths.
- **Coordinate fixes** — The Cloisters (`40.865220, -73.931122`, was wrongly in NJ) + Beacon Theatre (`40.780491, -73.981257`).
- **Flatiron Building hero** replaced: wide landscape → nearly-square portrait (3024×3903) from the prow angle, CC BY-SA 4.0. Better fit for square card frames.
- **Catalog: 91 tours, 3 makers, 73 NYC-area.** Build still 1.0 (19).

**TestFlight at session-13 end: 1.0 (19)** — uploaded from local session 2026-05-31. (Superseded by 1.0 (21) in session 14.)

### TestFlight 1.0 (17) + tour-detail retool + light-mode fix + 6 new tours (session 12)

Session 12 batched four parallel-session landings, then cut TestFlight build 1.0 (17). Build bump `f359f55` direct to main; archive at `/tmp/Atlas-20260529-1626.xcarchive`; owner uploaded via Organizer.

- **PR #93 — tour-detail masthead + toolbar + overflow menu.** Toolbar is X close (left) · Save (right) · ellipsis overflow menu (right) with no title text (the body's title carries page identity). Overflow menu: Download · Save · Share · *Follow creator (disabled)* · Go to creator · *Report a concern (destructive)*. Masthead: square-cornered hero · title · maker row · subtitle line (`3 min · 1 stop · 455 ft away`; multi-stop swaps in `… · 1.2 mi walk`) · inline button row above the description · description peek with soft fade-mask. Inline button row repeated at the bottom of the scroll body. Carousel gets a `N photos` overlay pill when >5 images. Stops section header unified to `Stops` for single + multi. **PR #93 is part 1 of 2** — part 2 (not yet shipped) reshapes stops into a numbered timeline with thumbnails + animated `waveform` now-playing indicator, and rewires Start Tour to non-modal playback start.
- **PR #95 — light-mode tab bar fix.** Bottom-module bars were showing inverted appearance (light fill in dark mode, dark fill in light mode) when the Settings appearance picker disagreed with the system. Root cause: SwiftUI's `.preferredColorScheme(...)` only propagates into a `WindowGroup`-owned window, NOT into the manually-created secondary `UIWindow` (`PassThroughWindow`) that hosts the bars. New `BottomModuleWindowController.apply(preference:)` sets `window.overrideUserInterfaceStyle` from the current `ColorSchemePreference`; called once in `.onAppear` and again on every `colorSchemePreference` change so the secondary window's trait collection mirrors the picker. The earlier `.preferredColorScheme` modifier inside the install closure (frozen at install time) was removed. PR #91's `secondaryBackgroundUIColor` dynamic-provider RGBs are untouched — chrome-seam guarantee preserved.
- **Content additions: 6 new tours.** PR #92 added Casa das Histórias Paula Rego (Eduardo Souto de Moura, 2009) in Cascais — **first Cascais tour** + 2nd under Atlas Studio Lisbon. PR #94 added 5 Porto-area architecture tours under Atlas Studio Porto: Edifício Burgo (Souto de Moura, 2007), House at Rua do Crasto 213 (Souto de Moura, 2001), Leixões Cruise Terminal (Luís Pedro Silva, 2015), Majestic Café (João Queiroz, 1921), Piscina das Marés (Álvaro Siza, 1966). **New city: Leixões.** Catalog 53 → 59 tours.

**Latest TestFlight build: 1.0 (17)** — uploaded 2026-05-29 via Organizer.

### Bottom-module chrome-shade seam fix + bars-to-edges (session 11)

PR #91 closes the "subtle chrome shade mismatch" known issue carried forward through sessions 8–10. The bump owner saw at the top of the *MINI PLAYER* when the tour detail sheet was up had two compounding causes:

1. **Trait variance.** `Color(uiColor: .secondarySystemBackground)` resolves to a different RGB at `.base` vs `.elevated` `userInterfaceLevel`. The detail body lives in window 1 (.base); the bars in window 2 (`windowLevel = .normal + 1`, treated as elevated). Same semantic color → two different RGBs → visible chrome band at the boundary in dark mode.
2. **Geometry.** The painted `Rectangle` in `BottomModuleRoot` ran edge-to-edge full-width, but the bars themselves were inset 8pt H — so the Rectangle peeked above the bars' top edge at the side corners, making the band particularly visible.

Two coordinated changes in PR #91:

- **`AtlasColors.secondaryBackground` → hardcoded RGB** via a `UIColor(dynamicProvider:)` block that keys only on `userInterfaceStyle`. No elevation variance. Light `#F2F2F7` / Dark `#1C1C1E` (Apple's `.base` shade — same as Settings/Music/Photos). New companion `AtlasColors.secondaryBackgroundUIColor` for UIKit consumers (`BottomLayerPresentation` sets the detail hosting view to this directly).
- **Bars grow edge-to-edge on Library / Me / detail-up; island only on Home-no-detail.** New `extendsToScreenEdges` parameter on `MiniPlayerBar` + `AtlasTabBar`. When true: painted background extends to screen edges, square outer corners, painted 8pt strip below. When false: current Home form (inset 8pt H, rounded bottom corners, transparent strip). Buttons keep identical x positions via *inner* horizontal padding, so the design rule of "buttons identical everywhere" (PR #70, `feedback-atlas-module-design.md`) still holds. The separate window-2 `Rectangle` is gone — bars now own their fill in both modes.

`BottomModuleRoot` is a clean VStack of two bars now; no extra fill behind them in either mode. `ContentView` paints no extra fill. The bottom module is one component now, not three layers across two windows.

**TestFlight build 1.0 (16)** cut at session end — owner uploaded via Organizer.

**Diagnostic workflow worth remembering** — bright contrasting test colors per painted surface (magenta sheet, cyan mini-player, yellow tab bar, orange behind-fill) turned a fuzzy "subtle hairline" complaint into a precise geometric finding within one screenshot. Saved as `feedback-visual-debugging.md`. Reach for it early when next debugging any multi-surface visual bug.

**Parked for next bottom-module pass:** lift mini-player title to a stronger *TYPE STYLE* (both lines are `caption` today — no hierarchy); align skip-forward (size 20) + play/pause (size 18) glyph sizes; bump avatar 32pt → 36pt to match the play-ring diameter.

### Content batch: gallery images + 3 new Portugal tours + Lisbon maker (session 9)

Content-only PR train (#84–#90, all squash-merged). Two threads:

**Task A — backfilled gallery images for 6 existing Porto/Braga tours.** PR #81's broken hero links resolved by uploading the actual webps to `gh-pages` and populating `additionalImageURLs` on each catalog entry. Tours updated: Bouça Housing Complex (+6 gallery), Chapel of Souls (+1 — `_tiles`), Capela do Senhor da Pedra (+1), Cantareira / Rua do Passeio Alegre 212 (+2), Casa de Chá da Boa Nova (+7), Braga Municipal Stadium (+3). Naming convention: `<slug>_hero.webp` for Main1/canonical shot + `<slug>_2.webp` … `<slug>_N.webp` for the gallery — except where the catalog had a pre-existing descriptive name (Chapel's `_tiles`).

**Task B — 3 new single-stop tours.** Expo'98 Portuguese National Pavilion (Lisbon, 38.7660, -9.0950, 146s, +8 gallery images), Piscina da Quinta da Conceição (Matosinhos, 41.1978, -8.6849, 144s, +6), Porto School of Architecture / FAUP (Porto, 41.1499, -8.6364, 143s, +17). All architecture-category, geofenced. **New maker added:** "Atlas Studio Lisbon" (`B1A9EAF0-7B07-46A4-BDAE-F28D430A55FA`) — the Expo'98 tour points at it; Piscina + FAUP stay on Atlas Studio Porto.

**Catalog totals:** 53 tours, 3 makers, 57 stops (was 50/2/54 at session start). No `*.swift` changes this session.

### UIKit-backed slide-up presentation + unified chrome (session 8)

Replaces the SwiftUI `.offset` slide layer with a UIKit `UIPresentationController`-driven modal so the tour-detail view slides up *from behind* the persistent mini-player + tab bar — the Apple Music pattern. New machinery in `Components/`:

- **`BottomModuleWindow.swift`** — installs a secondary higher-level `UIWindow` (`PassThroughWindow`, `windowLevel = .normal + 1`) that hosts the mini-player + tab bar. The window's `hitTest` returns hits only inside the bottom-inset strip; touches above pass through to the main window.
- **`BottomModuleRoot.swift`** — SwiftUI root for window 2. Paints an edge-to-edge `secondaryBackground` Rectangle on every surface *except* Home (so Home keeps its floating-island look with map showing through the 8pt sides + 8pt outer strip).
- **`BottomLayerPresentation.swift`** — `UIPresentationController` + slide-up/down animators. The presented view's frame is full-screen so it slides up *behind* window 2's mini-player + tab bar rather than stopping short. `BottomLayerContainerView` passes touches in the bottom strip through to window 2. `BottomLayerController` is the SwiftUI-facing public entry; `ContentView`'s `.onChange(of: tourPresenter.presentedTour?.id)` calls `present`/`dismiss`.
- **`AppSharedState`** (`@Observable`) — `selectedTab` + `showingFullPlayer` shared across the two windows. `TourPresenter` was promoted from `ContentView` state to App-level state for the same reason.

Other bottom-module geometry changes:

- `MiniPlayerBar.topGap = 0` — the painted bar's top edge IS the top of the mini-player view; no transparent strip mid-bottom-region that reads as a hairline at the window-compositing boundary.
- Tapping a tab while the detail is up auto-dismisses the detail (otherwise the new tab content swaps in *behind* the modal and the user appears stuck — icon updates, content doesn't).
- `PassThroughWindow.hitTest` decides pass-through purely geometrically off the point. The earlier `hit === rootViewController?.view` check rejected legitimate SwiftUI Button taps (SwiftUI often returns the hosting view as the hit target), which is why Library / Me tabs initially weren't switching.

Detail view rework:

- Sticky action bar removed. Start Tour / bookmark / download buttons moved inline into the `ScrollView` body (after the stops list). Layout pass for the buttons comes later.
- `.toolbarBackground(.hidden, for: .navigationBar)` so the nav bar's X + title sit on the body's `secondaryBackground` rather than the translucent material SwiftUI applies by default.
- Top padding (`AtlasSpacing.md`) added between the nav bar and the hero image.
- Hosting controller's view paints `UIColor.secondarySystemBackground` directly + `traitOverrides.userInterfaceLevel = .elevated` so the detail body resolves the *same shade* of `secondarySystemBackground` that window 2 resolves at its higher window level. (In dark mode UIKit's elevated-trait variant of `secondarySystemBackground` is slightly lighter than the base variant.)

**Known issue: subtle chrome shade mismatch.** In dark mode the detail body still reads as a *very subtly* different shade than the mini-player + tab bar even with the `.elevated` trait override. Owner has noted this for a future polish pass — not a blocker for the build.

### Tour-detail enter-slide mirror (session 7 — PR #78)

Follow-up to PR #77's structural fix. Owner said exit is now perfect but enter still isn't the exact opposite. The remaining asymmetry was `AsyncImage`'s default transaction — a ~250ms crossfade from `.empty` placeholder to `.success` loaded image. On exit, the hero image is already loaded so no crossfade fires; on enter, the crossfade runs concurrent with the slide, reading as a fade-in stacked on the slide motion. Fix: new `disableLoadAnimation: Bool` parameter on `HeroImageView`, set to `true` only on the hero(s) in `TourDetailView`. Cached images (the common case — drawer's `TourListCard` and map's `PlacecardView` both load the same URL into URLCache before the user taps to open detail) now render frame-zero of the first body eval; uncached images snap in cleanly when they land. Other `HeroImageView` usages keep the default crossfade — those surfaces appear in place, not via a slide, so the crossfade is polish there.

### Tour-detail slide animation fix (session 6 — PR #77)

Resolves the open issue flagged at the end of session 5 (fade-from-drawer / fade-from-placecard). Two competing transitions were masking the layer's `.offset` slide:

1. **Inner content was inserted one tick late.** `displayedTour` lived on `ContentView` as `@State` and mirrored `tourPresenter.presentedTour` via `.onChange` — which fires AFTER the offset animation starts. The `if let displayedTour` conditional inserted the `NavigationStack` mid-slide, and SwiftUI filled the gap with its default opacity-fade transition. **Fix:** `displayedTour` moved onto `TourPresenter`, updated synchronously inside `present(_:)` (same SwiftUI tick as the offset). `dismiss()` keeps the lag (cleared 0.45s later) so content stays rendered through the slide-down. `.transition(.identity)` on the inner content as belt-and-suspenders.
2. **Drawer opacity-fade caused the entry-point asymmetry.** The drawer (z-stacked ABOVE the detail layer in PR #76) was fading 1→0 on present and 0→1 on dismiss on the same 0.4s clock. From the drawer entry (drawer `.large`) the fade-out dominated the perceived motion; from the placecard entry (drawer `.peek`) only the bottom 80pt faded so the slide stayed visible. **Fix:** drawer no longer animates opacity. Its `.zIndex` swaps: **z-4 when no detail is up** (above mini-player + tab bar — PR #76's "last card visible at scroll-end" fix preserved); **z-1 when detail active** (below the detail layer). The detail's slide-up COVERS the drawer naturally; the slide-down REVEALS it. Mini-player + tab bar stay at z-3 so their buttons remain tappable through the detail layer.

Verified in simulator from both entry points; all 84 unit tests pass.

### Detail-as-sheet refactor (PR #76)

Five connected changes that landed the slide-up layer.

1. **Home drawer hoisted out of `HomeView` into `ContentView`.** New `HomeSharedState` (`@Observable`) carries the map ↔ drawer state (`selectedCategory`, `placecardTour`, `placecardCoordinate`, `visibleRegion`, `sheetDragOffset`). `HomeDrawerContent.swift` extracts the drawer body. The drawer now z-stacks above the mini-player + tab bar (when no detail is up — see PR #77 for the dynamic-zIndex twist), fixing the long-running "last card peeks behind the tab bar / can't reach scroll-end" complaint.
2. **Tour detail always presented as a slide-up layer.** New `TourPresenter` (`@Observable`) drives a `ContentView`-level layer; every entry point (`TourListCard`, `RailCarousel`, `LibraryView`, `MakerView`, `SearchView`'s result rows, the placecard, the quick-resume banners) calls `tourPresenter.present(tour)` instead of pushing via `NavigationLink`. `TourListCard` is now pure presentational — no NavigationLink. `MakerView`'s in-stack push stays as a `NavigationLink` since it pushes onto the layer's own `NavigationStack`.
3. **`TourDetailView` X close.** Default back chevron hidden; X in the top-leading toolbar slot calls `tourPresenter.dismiss()`. `.toolbarBackground(AtlasColors.secondaryBackground, for: .navigationBar)` so the nav bar matches the rest of the detail surface.
4. **Mini-player + tab bar stay visible underneath the detail layer.** `moduleGeometry` now reads `tourPresenter.presentedTour != nil` directly (in addition to `navState.isShowingDetail`) so the module switches to `.fullEdge` on the SAME SwiftUI tick the layer comes up. Mini-player + tab bar's z-index keeps them above the detail layer so their buttons remain tappable.
5. **SearchBar + chips background.** Both swapped from `.regularMaterial` + stroke to `AtlasColors.secondaryBackground` with no border — one unified chrome color across drawer / mini-player / tab bar / search bar / chips.

### Earlier this day

PR #70 (buttons identical across surfaces — `643cbd7`) shipped 2026-05-25 pm-3: final shape of the bottom-module rework. Bar contents render the EXACT same form on every surface (Home, Library, Me, every pushed detail): 8pt horizontal inset, phone-screen-radius rounded bottom corners, transparent 8pt strip below. The only thing that differs between Home (floating island) and the rest (full-edge look) is whether `ContentView` paints an edge-to-edge `secondaryBackground` rectangle BEHIND the inset bar — on Home it doesn't (gaps show the map); elsewhere the same-colored fill makes the gaps blend into a continuous full-width strip. `AtlasTabBar` + `MiniPlayerBar` lost their `extendsToScreenEdges` flags entirely (single form now). Verified via `snapshot_ui`: tab buttons at x=8 / 136.67 / 265.33 with width 128.67 on every surface, identical to OLD Home position. The "fill or not" decision is now a single conditional in `ContentView`, driven by `selectedTab == .home && !navState.isShowingDetail`.

PR #69 (restore Home floating island + anchor at OLD Home position — `8d928b3`) shipped 2026-05-25 pm-2: fixes two regressions PR #68 introduced on Home. (1) `AtlasTabBar.bottomExtensionHeight` was adding the home-indicator safe-area inset to the view's *height* on non-Home, which physically pushed the buttons (and the mini-player above them) up by ~34pt — opposite of the intent. Fixed by making the view a constant 64pt in both modes (56pt painted button row + 8pt outer strip); only what's painted in the 8pt strip changes (transparent on Home, opaque elsewhere). The safe-area zone underneath is already covered by the painted button row because the parent ZStack `.ignoresSafeArea(.bottom)` extends it down. (2) The PreferenceKey-driven `moduleGeometry` was getting stuck at `.fullEdge` after popping back from a detail screen, so Home rendered in full-edge geometry. Replaced with `@Observable AtlasNavigationState` that tracks `pushedDepth` via `push()` / `pop()` from each pushed view's `onAppear` / `onDisappear` — deterministic, no stuck values. ContentView derives geometry from `selectedTab` + `navState.isShowingDetail`. NEW Home button positions match OLD Home exactly (verified via `snapshot_ui`: Home/Library/Me buttons at y=807 in every tab). `AtlasBottomModule.height` is now a constant 126pt across modes. `\.atlasIsHomeTab` env + `AtlasModuleGeometryKey` PreferenceKey both removed.

PR #68 (consistent bottom module across tabs + detail screens — `fe11d99`) shipped 2026-05-25 pm: three connected fixes surfaced by the PR #66 visual review. (1) `SearchBar` no longer presents `SearchView` as `.sheet(...)` — switched to `NavigationLink` push so the mini-player + tab bar stay visible while the user searches (and the further `TourDetailView` push extends the same stack). (2) `AtlasTabBar` refactored so its button row sits at the same screen-y in both geometries — the home-indicator safe-area inset moved OUT of the painted button row into a separate background rectangle below it. Identical button layout in both modes; only what's painted below changes (transparent on Home → map shows; opaque on every other surface → continuous `secondaryBackground` through the home-indicator strip). (3) Detail screens (`TourDetailView` / `MakerView` / `SearchView` / `ManageDownloadsView`) always render with the full-edge module now, even when reached from the Home tab — fixes the floating-island leak where scrolled content peeked through the 8pt outer gap on Home-entry detail screens. Mechanism: replaced `\.atlasIsHomeTab` env value (deleted) with typed `AtlasModuleGeometry` preference — each surface declares its preference at its root; the deepest declaration wins; `ContentView` reads via `onPreferenceChange` and threads geometry into `MiniPlayerBar` + `AtlasTabBar`. `AtlasBottomModule.height` math updated: non-Home now reads `layoutHeight (62) + tabBarBackgroundHeight (56) + 8 + safeAreaBottomInset` (the extra 8pt is the new outer gap above the safe-area fill).

PR #66 (module geometry on non-Home tabs — `2452f52`) shipped 2026-05-25: extends PR #60's bottom-module work past the home screen. On Home the mini-player + tab bar still floats as a rounded island; on Library / Settings / Manage downloads / Tour Detail / Maker the module extends flush to the screen edges and the tab bar background runs through the home-indicator safe area. Every non-Home scrollable surface now applies `.safeAreaInset(.bottom)` sized to the shared `AtlasBottomModule.height(extendsToScreenEdges:)` helper so content never hides behind the module. TourDetailView's `actionBarHeight` now tracks that helper too — also fixes the long-standing too-small 72pt trailing spacer that let the last description lines hide behind the action bar. (PR #68 above superseded its `\.atlasIsHomeTab` env-value plumbing with a typed preference; the helper itself stays.)

PR #61 (mini-player end-of-tour state — `c054a67`) shipped 2026-05-24 pm: kills the post-tour "Loading…"/hourglass flicker and adds in-place replay via new `AudioPlayerService.replayLast()`. PR #60 (home polish bundle + player-state hardening — `e5b31da`) shipped 2026-05-24 late-pm: bigger bottom-module radius (48→56), drawer now stacks on top of mini-player + tab bar via new `bottomReservedHeight`, chip + search-bar share `searchBarHeight = 46`, "tours in view" count + `Let's explore together!` empty state, recenter button tracks drawer detent. Same PR also fixed three player-state bugs surfaced during visual review: Open-player button no longer disabled mid-load, `seek(to:)` synthesizes `.ended` on scrub-to-end (AVPlayer doesn't fire `didPlayToEndTime` on manual seek), full-player tap-to-replay on `.ended` via new `replayCurrent()`.

**What's left:** owner-noted chrome shade-mismatch polish → M-qa multi-stop check (AMNH Four Facades on device) → broader design/polish pass.

Key facts:
- **138 tours, 3 makers** in `Resources/Tours.json` (96 Atlas Studio NYC + 37 Atlas Studio Porto + 5 Atlas Studio Lisbon); audio on `gh-pages` at `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<file>.mp3`
- **136 single-stop + 2 multi-stop**: "American Museum of Natural History: Four Facades" (5 stops, ~8m 44s, exterior walk, added 2026-05-26) and "Fifth Avenue Walk" (6 stops, added 2026-06-03) — both geofenced. AMNH unblocks M-qa items 6 + 7.
- **All tours have `heroImageURL`.** NYC tours use CC-licensed Wikimedia Commons 1280px thumbs; Porto/Lisbon/Braga tours use owner-supplied webps on `gh-pages` at 1200×900. Tours that received a gallery this session have an `additionalImageURLs` array of webps under the same slug — see catalog for the full list.
- `MiniPlayerBar` above tab bar at all times: marquee titles, skip-forward-10s, progress ring, idle welcome message
- `MarqueeText.swift` in `Components/` — scrolls overflow text continuously
- AppIcon is placeholder (green sphere); AccentColor: terracotta `#B85042` (placeholder)
- Theme tokens in `Theme/Atlas*.swift` are placeholder values pending design pass
- `UIBackgroundModes=audio` now in explicit `Info.plist` (not INFOPLIST_KEY — Xcode ignores that for arrays)

See `ROADMAP.md` for full milestone history. Read latest `archive/HANDOFF-*.md` for mid-flight context.

## Session-start ritual (automatic — Claude runs this first, every session)

```bash
git fetch && git status && git branch --show-current && git log origin/main..HEAD && gh pr list --state open
ls archive/HANDOFF-*.md | tail -1   # then read that file
```

Run before any substantive work. Investigate uncommitted changes before acting on them.

## Merging PRs

**Auto-merge (squash, no owner approval) — content/docs/assets/CI/test code:**
- `*.md`, `docs/`, `archive/`, `ROADMAP.md`, `CLAUDE.md`, `CONTRIBUTING.md`
- `Resources/Tours.json` (content additions and edits)
- `scripts/` (developer tooling, doesn't ship in the app)
- `TRAVEL GUIDED TOURTests/` (test target; doesn't affect the running app)
- `.github/workflows/` (CI definitions)
- Lint / tooling configs (`.swiftlint.yml`, etc.)
- Audio + image uploads to `gh-pages` branch

Flow for auto-merge PRs: open PR → wait for CI green → `gh pr merge --squash --delete-branch`.

**Wait for owner OK (visual simulator review required) — code:**
- Anything in `TRAVEL GUIDED TOUR/<source-folder>/*.swift` (`Audio/`, `Components/`, `Data/`, `Features/`, `Location/`, `Models/`, `Theme/`, `ContentView.swift`, `SplashView.swift`, the App entry)
- Xcode project file (`*.xcodeproj`/`*.pbxproj`)
- Asset catalogs (`Assets.xcassets/`)
- `Info.plist`

Owner reviews via iOS Simulator or TestFlight before merge — not by reading code. **Reason:** the previous auto-merge-everything policy (briefly in effect 2026-05-25/27) produced visible regressions on `main` that required follow-up fix PRs (#68→#69→#70 chain after #66; #77→#78 chain after #76). Pre-merge visual review catches these in the simulator and avoids the fix-forward thrash.

**Merge conflicts: resolve them automatically** when they're structural (file renames, neighboring edits, import reorderings, doc reformats, version-number bumps). Stop and ask only if the conflict reflects a real business-logic disagreement between two PRs.

**When in doubt, ask** — better to over-confirm than merge something the owner hadn't seen yet.

## Keep Docs in Sync (automatic — no prompting needed)

Every session that ships a milestone, cuts scope, or changes "what's true today" must update `CLAUDE.md` + `ROADMAP.md` in the same commit. Write `archive/HANDOFF-YYMMDD.md` + update `archive/README.md` at session end if code or content was touched. Non-negotiable.

## Repo Layout

| Path | Purpose |
|------|---------|
| `atlas_claude_code_prompt.md` | Canonical product spec |
| `ROADMAP.md` | Execution plan + milestone history |
| `docs/authoring-tours.md` | Tour content authoring guide |
| `docs/cdn-decision.md` | Audio hosting decision |
| `docs/design-tokens.md` | Typography/color/spacing reference |
| `docs/testflight.md` | Per-release upload runbook (~10 min) |
| `docs/troubleshooting.md` | Xcode + git landmines from real incidents |
| `scripts/validate-tours.swift` | Validates `Tours.json`; run: `swift scripts/validate-tours.swift` |
| `TRAVEL GUIDED TOURTests/` | 6 XCTest classes, data/logic layer |
| `archive/` | Dated session snapshots |

**`validate-tours.swift` mirrors `Tour/Stop/Maker/TourCategory.swift` — update the script in the same commit if any model changes.**

## Build & Run

Use **XcodeBuildMCP tools** — prefer over raw `xcodebuild` shell commands.

| Task | XcodeBuildMCP tool |
|------|--------------------|
| Verify session defaults | `session_show_defaults` — **call first every session before any build/test** |
| Build for iOS Simulator | `build_sim` |
| Build + launch in Simulator | `build_run_sim` |
| Run unit tests | `test_sim` |
| Take simulator screenshot | `screenshot` |

**Run `test_sim` automatically before pushing any code PR.** Skip for doc-only, CI-only, `Features/`/`Components/`/`Theme/`-only, or `Tours.json` content-only changes.

Fallback raw commands (CI + macOS builds):
```bash
xcodebuild -scheme "TRAVEL GUIDED TOUR" -configuration Debug build
xcodebuild test -scheme "TRAVEL GUIDED TOUR" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" -configuration Debug
```

## Architecture

```
TRAVEL GUIDED TOUR/
├── TRAVEL_GUIDED_TOURApp.swift    App entry + SwiftUI Environment setup
├── ContentView.swift              AtlasTabBar — 3 tabs: Home / Library / Me
├── SplashView.swift
├── Models/                        Tour, Stop, Maker, TourCategory, RecentSearch, LibraryEntry
├── Data/                          DataService, LibraryStore, RecentSearchStore, RecentlyViewedStore, ToursData
├── Resources/Tours.json
├── Audio/                         AudioPlayerService (AVQueuePlayer + lock-screen), TourDownloader
├── Features/
│   ├── Home/                      HomeView, HomeMapSection, CategoryChipRow, TourListCard, HomeRailsViewModel, RailCarousel
│   ├── Search/                    SearchBar, SearchView
│   ├── Tour/                      TourDetailView
│   ├── Player/                    PlayerView, MiniPlayerBar
│   ├── Maker/                     MakerView
│   ├── Library/                   LibraryView
│   └── Settings/                  SettingsView, ManageDownloadsView
├── Location/                      LocationManager, ProximityMonitor
├── Components/                    HeroImageView, MarqueeText, TagChip, BottomSheet, PlatformHelpers
├── Theme/                         AtlasColors, AtlasTypography, AtlasSpacing
└── Assets.xcassets/
```

Environment services (instantiated once at app entry, injected via SwiftUI Environment — never in views): `DataService`, `LibraryStore`, `RecentSearchStore`, `RecentlyViewedStore`, `LocationManager`, `AudioPlayerService`, `TourDownloader`.

## Conventions

- `@Observable` not `ObservableObject`. `NavigationStack` not `NavigationView`.
- Hero images: use `Components/HeroImageView.swift` — never raw `AsyncImage`.
- Audio: always through `AudioPlayerService`. Never create `AVPlayer` in a view.
- No third-party libraries in V1. Apple frameworks only: SwiftUI, MapKit, CoreLocation, AVFoundation, MediaPlayer, SwiftData/UserDefaults.
- Design tokens: use `AtlasColors.*`, `AtlasTypography.*`, `AtlasSpacing.*`. No hardcoded colors/fonts/padding.
- Support Dynamic Type and Dark Mode.

## Design System

Tokens in `Theme/` are single source of truth; values are placeholders pending deferred design pass. Accent `#B85042` is also placeholder. Build for function first.

## Build Config

- Bundle ID: `com.ehky.TRAVEL-GUIDED-TOUR`
- Swift 5.0; deployment targets iOS 26.2 / macOS 26.2 / visionOS 26.2
- Device families: iPhone, iPad, Apple Vision; code signing automatic, team `CPC7M72JTP`
- `Info.plist` at repo root (explicit file — `GENERATE_INFOPLIST_FILE = NO`)
- Keys: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `UIBackgroundModes=audio`, `ITSAppUsesNonExemptEncryption=NO`

## Out of Scope for V1

No: backend/API, user accounts/auth, in-app maker upload, payments/IAP, moderation, comments/reviews/ratings, follow/sharing/social, push notifications (local geofence notifications OK), onboarding tutorial, in-app search, analytics SDK. Don't introduce any without a spec update.

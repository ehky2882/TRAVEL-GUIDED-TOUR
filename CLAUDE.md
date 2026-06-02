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

## Current State (2026-06-01)

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
- **97 tours, 3 makers** in `Resources/Tours.json` (73 NYC-area + 17 Porto-area + 3 elsewhere-in-Portugal/Iberia + others); audio on `gh-pages` at `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<file>.mp3`
- **58 single-stop + 1 multi-stop**: "American Museum of Natural History: Four Facades" (5 stops, ~8m 44s, geofenced exterior walk) — added 2026-05-26, unblocks M-qa items 6 + 7
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

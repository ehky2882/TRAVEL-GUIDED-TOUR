# CLAUDE.md

## Project: Atlas

GPS-anchored audio tour platform. Makers record audio; consumers browse, download, and play while walking — audio auto-triggers at each stop. Closer to AllTrails than a guidebook.

**Spec:** `atlas_claude_code_prompt.md` — read before product decisions.
**Execution plan:** `ROADMAP.md` — read before implementation decisions.
**V1:** Consumer-side only. No backend, auth, payments, or maker upload.

Multi-platform SwiftUI. iOS 26.2 / macOS 26.2 / visionOS 26.2.

## Claude Automation Rules

These happen **automatically, without the owner asking**.

| # | Trigger | What Claude does automatically |
|---|---------|-------------------------------|
| 1 | Every session start | Run full git/PR health check (§ Session-start ritual) + read latest HANDOFF file — before any other work |
| 2 | After any edit to `Resources/Tours.json` | Run `swift scripts/validate-tours.swift`; fix errors before continuing |
| 3 | Before pushing any code PR | Call `test_sim` (XcodeBuildMCP); fix failures before pushing |
| 4 | Any PR is ready (CI green) | Squash-merge to `main` automatically — no owner approval gate. Resolve merge conflicts in-line without prompting (unless they require a business-logic decision — see § Merging PRs). Delete the merged branch. Owner reviews via TestFlight downstream. |
| 5 | Session ends (touched code or content) | Update `CLAUDE.md` + `ROADMAP.md` in same commit; write `archive/HANDOFF-YYMMDD.md`; update `archive/README.md` |
| 6 | Stale merged `claude/*` branches detected | Delete them via `git push origin --delete` — no prompting |
| 7 | Owner asks for a TestFlight build | Bump `CURRENT_PROJECT_VERSION` in `project.pbxproj`, commit + push, then run `xcodebuild archive` (see `docs/testflight.md` § "Archive command"). Owner then does Organizer → Distribute App → Upload (2–3 min). |

## Current State (2026-05-25)

### Detail-as-sheet refactor (session 5, this commit)

Five connected changes, plus one **OPEN ISSUE** the owner has flagged.

1. **Home drawer hoisted out of `HomeView` into `ContentView`.** New `HomeSharedState` (`@Observable`) carries the map ↔ drawer state (`selectedCategory`, `placecardTour`, `placecardCoordinate`, `visibleRegion`, `sheetDragOffset`). `HomeDrawerContent.swift` extracts the drawer body. The drawer now z-stacks above the mini-player + tab bar, fixing the long-running "last card peeks behind the tab bar / can't reach scroll-end" complaint.
2. **Tour detail always presented as a slide-up layer.** New `TourPresenter` (`@Observable`) drives a `ContentView`-level layer; every entry point (`TourListCard`, `RailCarousel`, `LibraryView`, `MakerView`, `SearchView`'s result rows, the placecard, the quick-resume banners) calls `tourPresenter.present(tour)` instead of pushing via `NavigationLink`. `TourListCard` is now pure presentational — no NavigationLink. `MakerView`'s in-stack push stays as a `NavigationLink` since it pushes onto the layer's own `NavigationStack`.
3. **`TourDetailView` X close.** Default back chevron hidden; X in the top-leading toolbar slot calls `tourPresenter.dismiss()`. `.toolbarBackground(AtlasColors.secondaryBackground, for: .navigationBar)` so the nav bar matches the rest of the detail surface.
4. **Mini-player + tab bar stay visible underneath the detail layer.** `moduleGeometry` now reads `tourPresenter.presentedTour != nil` directly (in addition to `navState.isShowingDetail`) so the module switches to `.fullEdge` on the SAME SwiftUI tick the layer comes up. Bottom-module ZStack order in `ContentView` puts the bottom module AFTER the detail layer so it overlays on top.
5. **SearchBar + chips background.** Both swapped from `.regularMaterial` + stroke to `AtlasColors.secondaryBackground` with no border — one unified chrome color across drawer / mini-player / tab bar / search bar / chips.

### ⚠️ Open issue — tour-detail slide animation

**Status: NOT working as expected. Owner-flagged, multiple fix attempts unsuccessful, tracked in PR #77.** The layer slides up but the dismiss animation reads as a fade rather than a clean slide-down. From the home drawer the present also reads as a fade. Multiple approaches were tried in this session — `.transition(.move(edge: .bottom))` with various wrapper modifiers (clipShape, shadow, compositingGroup), then a switch to explicit `.offset` + `.animation(_, value:)` with a lagging `displayedTour` for content lifecycle, then offset value tuned to actual screen height, then synchronized opacity animation on the drawer. None landed cleanly with the owner. The current code uses the offset-based approach; do NOT iterate on this further in the bulk PR — the fix is owned by the follow-up PR.

Best leads for the follow-up:
- Confirm the slide is actually animating (UIView layer inspection / video capture) — the user's report differentiates present vs. dismiss visually, which suggests the offset IS animating but other view-tree changes mask it.
- Try replacing the lagging `displayedTour` with a separate `@State` that's set inside `present()` / `dismiss()` directly on the presenter (move state ownership out of `ContentView`).
- Consider whether the home drawer's `opacity` animation is what the user perceives as "fade" — when opened FROM the drawer, the drawer fades out as the detail slides up; if the drawer is the dominant visible element pre-tap, its fade may overshadow the detail's slide.
- A `UIViewControllerRepresentable`-bridged custom presentation (mimicking the system sheet but with a configurable bottom inset to keep the mini-player visible) is the nuclear option.

### Earlier this day

PR #70 (buttons identical across surfaces — `643cbd7`) shipped 2026-05-25 pm-3: final shape of the bottom-module rework. Bar contents render the EXACT same form on every surface (Home, Library, Me, every pushed detail): 8pt horizontal inset, phone-screen-radius rounded bottom corners, transparent 8pt strip below. The only thing that differs between Home (floating island) and the rest (full-edge look) is whether `ContentView` paints an edge-to-edge `secondaryBackground` rectangle BEHIND the inset bar — on Home it doesn't (gaps show the map); elsewhere the same-colored fill makes the gaps blend into a continuous full-width strip. `AtlasTabBar` + `MiniPlayerBar` lost their `extendsToScreenEdges` flags entirely (single form now). Verified via `snapshot_ui`: tab buttons at x=8 / 136.67 / 265.33 with width 128.67 on every surface, identical to OLD Home position. The "fill or not" decision is now a single conditional in `ContentView`, driven by `selectedTab == .home && !navState.isShowingDetail`.

PR #69 (restore Home floating island + anchor at OLD Home position — `8d928b3`) shipped 2026-05-25 pm-2: fixes two regressions PR #68 introduced on Home. (1) `AtlasTabBar.bottomExtensionHeight` was adding the home-indicator safe-area inset to the view's *height* on non-Home, which physically pushed the buttons (and the mini-player above them) up by ~34pt — opposite of the intent. Fixed by making the view a constant 64pt in both modes (56pt painted button row + 8pt outer strip); only what's painted in the 8pt strip changes (transparent on Home, opaque elsewhere). The safe-area zone underneath is already covered by the painted button row because the parent ZStack `.ignoresSafeArea(.bottom)` extends it down. (2) The PreferenceKey-driven `moduleGeometry` was getting stuck at `.fullEdge` after popping back from a detail screen, so Home rendered in full-edge geometry. Replaced with `@Observable AtlasNavigationState` that tracks `pushedDepth` via `push()` / `pop()` from each pushed view's `onAppear` / `onDisappear` — deterministic, no stuck values. ContentView derives geometry from `selectedTab` + `navState.isShowingDetail`. NEW Home button positions match OLD Home exactly (verified via `snapshot_ui`: Home/Library/Me buttons at y=807 in every tab). `AtlasBottomModule.height` is now a constant 126pt across modes. `\.atlasIsHomeTab` env + `AtlasModuleGeometryKey` PreferenceKey both removed.

PR #68 (consistent bottom module across tabs + detail screens — `fe11d99`) shipped 2026-05-25 pm: three connected fixes surfaced by the PR #66 visual review. (1) `SearchBar` no longer presents `SearchView` as `.sheet(...)` — switched to `NavigationLink` push so the mini-player + tab bar stay visible while the user searches (and the further `TourDetailView` push extends the same stack). (2) `AtlasTabBar` refactored so its button row sits at the same screen-y in both geometries — the home-indicator safe-area inset moved OUT of the painted button row into a separate background rectangle below it. Identical button layout in both modes; only what's painted below changes (transparent on Home → map shows; opaque on every other surface → continuous `secondaryBackground` through the home-indicator strip). (3) Detail screens (`TourDetailView` / `MakerView` / `SearchView` / `ManageDownloadsView`) always render with the full-edge module now, even when reached from the Home tab — fixes the floating-island leak where scrolled content peeked through the 8pt outer gap on Home-entry detail screens. Mechanism: replaced `\.atlasIsHomeTab` env value (deleted) with typed `AtlasModuleGeometry` preference — each surface declares its preference at its root; the deepest declaration wins; `ContentView` reads via `onPreferenceChange` and threads geometry into `MiniPlayerBar` + `AtlasTabBar`. `AtlasBottomModule.height` math updated: non-Home now reads `layoutHeight (62) + tabBarBackgroundHeight (56) + 8 + safeAreaBottomInset` (the extra 8pt is the new outer gap above the safe-area fill).

PR #66 (module geometry on non-Home tabs — `2452f52`) shipped 2026-05-25: extends PR #60's bottom-module work past the home screen. On Home the mini-player + tab bar still floats as a rounded island; on Library / Settings / Manage downloads / Tour Detail / Maker the module extends flush to the screen edges and the tab bar background runs through the home-indicator safe area. Every non-Home scrollable surface now applies `.safeAreaInset(.bottom)` sized to the shared `AtlasBottomModule.height(extendsToScreenEdges:)` helper so content never hides behind the module. TourDetailView's `actionBarHeight` now tracks that helper too — also fixes the long-standing too-small 72pt trailing spacer that let the last description lines hide behind the action bar. (PR #68 above superseded its `\.atlasIsHomeTab` env-value plumbing with a typed preference; the helper itself stays.)

PR #61 (mini-player end-of-tour state — `c054a67`) shipped 2026-05-24 pm: kills the post-tour "Loading…"/hourglass flicker and adds in-place replay via new `AudioPlayerService.replayLast()`. PR #60 (home polish bundle + player-state hardening — `e5b31da`) shipped 2026-05-24 late-pm: bigger bottom-module radius (48→56), drawer now stacks on top of mini-player + tab bar via new `bottomReservedHeight`, chip + search-bar share `searchBarHeight = 46`, "tours in view" count + `Let's explore together!` empty state, recenter button tracks drawer detent. Same PR also fixed three player-state bugs surfaced during visual review: Open-player button no longer disabled mid-load, `seek(to:)` synthesizes `.ended` on scrub-to-end (AVPlayer doesn't fire `didPlayToEndTime` on manual seek), full-player tap-to-replay on `.ended` via new `replayCurrent()`.

**What's left:** author one multi-stop walking tour (unblocks the last M-qa checks) → broader design/polish pass.

Key facts:
- **38 single-stop tours** in `Resources/Tours.json`; audio on `gh-pages` at `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<file>.mp3`
- **All 38 tours have `heroImageURL`** — CC-licensed Wikimedia Commons landscape photos (committed 2026-05-23/24). Whitney and MAD have no landscape exterior on Commons; best available used.
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

**Auto-merge all PRs that pass CI (squash, no owner approval).** This includes code PRs (`*.swift`, `*.xcodeproj`/`*.pbxproj`, `Assets.xcassets/`) — owner reviews via TestFlight after the fact, not before merge. Flow: open PR → wait for CI green → `gh pr merge --squash --delete-branch`.

**Merge conflicts: resolve them automatically.** When merging or rebasing produces a conflict, Claude resolves it without prompting. Pure structural conflicts (file renames, neighboring edits, import reorderings, doc reformats, version-number bumps) are always auto-resolved. Only stop and ask if the conflict reflects a real business-logic disagreement two PRs are taking different positions on (e.g. two PRs implementing the same feature differently) — surface the choice before resolving.

**Exceptions — still wait for owner OK:**
- Anything that adds an `Info.plist` capability key the owner hasn't asked for (`UIBackgroundModes` additions, `NSAppTransportSecurity`, etc.)
- Anything that bumps the deployment target
- Anything that introduces a third-party dependency
- Anything that changes signing identity / team / bundle ID

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

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

**Status (2026-06-30, session 48):** web/PM content session — **Tokyo launched as the 7th city** ([PR #280](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/280), `4ab886a`, squash, auto-merged on CI green). New maker **Atlas Studio TYO** (`be5797bb-…`, 🇯🇵) + **63 single-stop, geofenced tours** (30 m), bilingual `English | 日本語`, owner-supplied audio + images. **Catalog 406 → 469 tours / 6 → 7 makers / 521 stops; Tokyo = 63.** Validator PASS. Assets-first to gh-pages (63 mp3 + 215 webp, lowercase-hyphen slugs; Sumida Hokusai `.jpg.webp` cleaned), then an idempotent assembler appended the entries off `origin/main`. **Confirmed live** on both sources — Supabase `get_catalog` RPC (~1 min) + gh-pages mirror (~6 min CDN lag) each serve 7/469/63, asset URLs 200. 3 source-data fixes geocoded + flagged (Hōrin-ji folder coord was in Kyoto → Waseda; Edo-Tokyo Open Air Museum + Nanago-Dori toilets had no coord). Supplied/cleaned Japanese for 9 folders. *Note: the 6th city was San Francisco (Atlas Studio SFO, 35 tours), already on `main`.* No app/build change; docs-only sync this entry. See `archive/HANDOFF-260630.md`. Earlier status follows.

**Status (2026-06-26, session 44):** code session — **the gh-pages catalog refresh was hardened ([PR #245](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/245)) and shipped in TestFlight 1.0 (49).** Resolves the long-flagged build-46 bug where two testers stayed stuck on a stale cached catalog for hours: the remote `refresh()` gave up after one 15s timeout, silently, only at cold launch. Four fixes in `RemoteCatalogLoader`/`DataService`/the App entry — **retry with ~1s/2s backoff** (3 attempts, transient-only: network/timeout/5xx/408/429, not a clean 4xx), **30s/60s timeouts** (was 15s), **refresh-on-foreground** (`scenePhase → .active`, 60s debounce + in-flight guard, so reopening picks up new content with **no force-quit**), and a **`CFBundleVersion`-stamped cache** discarded across app-version changes (the 47→48 case). +8 unit tests (103/103). Proven live in the sim (★-on-gh-pages → background+reopen → ★ appeared → reverted byte-exact). The `CatalogFetching` seam is preserved. Build bumped **48 → 49** via [PR #249](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/249); build 49 also carries #244 (detail Nearby Tours), #246 (maker sort/view persistence), #247 (home polish batch), #248 (search polish). Content unchanged (~370 tours / 5 makers, ships live via the remote catalog). See `archive/HANDOFF-260626.md`. Earlier status follows.

**Status (2026-06-23, session 42):** docs-sync session (web/PM) — **Current State refreshed to 362 tours / 5 cities / the remote-catalog era**; no app/content/build change (`CLAUDE.md` + `ROADMAP.md` + a HANDOFF only, auto-merge class). The catalog has grown well past the last doc snapshot (307/4): **362 tours / 5 makers / 381 stops / 4 multi-stop**, live-verified against `Resources/Tours.json` — **NYC 100 · London 97 · Lisbon 66 · Porto 54 · Hong Kong 45**. **Hong Kong is the 5th maker and newest city**, built 0 → 45 over a few days (PRs #226–#234) and **fully bilingual** (`English | 中文` tour + stop titles). The 4 multi-stop walks are AMNH Four Facades (NYC), Fifth Avenue Walk (NYC), After the Fire: Wren's City (London) and Albertopolis (London) — the two London walks wired + gallery-fixed during the recent growth (PRs #232/#233); 3 more London multi-stop walks are drafted on `claude/london-batch3-scripts-260616`, awaiting wiring. **Content now ships with no app build:** since TestFlight 1.0 (46) the app fetches `Tours.json` from gh-pages (PR #209) and merges auto-publish it (PR #212), so a content PR goes live to build-46+ users ~5 min after merge + an app relaunch — no rebuild, no App Store review. 1.0 (46) remains current and is the last content-driven build; build bumps are now only for actual app-code changes. **In flight:** Paris drafted as the 6th city (`claude/paris-scripts-260622`); V2 creator-platform groundwork continues across design/code branches (see § V2 — execution plan below). Earlier status follows.

**Status (2026-06-18, session 41):** infra session — **catalog publishing is now automated; the manual gh-pages re-upload step is gone.** New [`.github/workflows/publish-catalog.yml`](.github/workflows/publish-catalog.yml) ([PR #212](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/212), squash-merged, CI green) closes the drift gap PR #209 left: it triggers on every push to `main` that touches `TRAVEL GUIDED TOUR/Resources/Tours.json` (path-filtered) plus manual `workflow_dispatch`, validates the file (JSON parse + non-empty `tours`/`makers`), and copies **only** `Tours.json` to the gh-pages root — committing only on a real diff (`[skip ci]` message) and pushing via the built-in `GITHUB_TOKEN`. Audio/images/privacy on gh-pages are never touched; it pushes only to gh-pages so it can't retrigger itself. **What this means for the owner:** merge a `Tours.json` change to `main` → it auto-publishes to gh-pages within ~1 min → the live app picks it up on next launch. No manual upload, no app rebuild; the 272-vs-300 drift can't recur. gh-pages `Tours.json` is now workflow-owned — never hand-edited. Real-run verified via `workflow_dispatch` (SUCCESS; correctly no-op'd since already in sync). Earlier status follows.

**Status (2026-06-18, session 40):** verify-task-turned-ship — **the catalog detached from the app bundle ([PR #209](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/209)) and TestFlight 1.0 (46) cut and shipped.** PR #209 makes the app fetch `Tours.json` from gh-pages at launch — it loads the local copy first (last-good network cache → bundled seed) for an instant, offline-capable first frame, then refreshes from the URL in the background and republishes live; any network/decode failure keeps the local copy intact. **So content can now ship by pushing one file to gh-pages — no app rebuild, no App Store review** (the first backend seam). New `Data/RemoteCatalogLoader.swift` (fetch behind a `CatalogFetching` protocol) + injectable loader/`autoRefresh` on `DataService`; bundled `Tours.json` kept as the offline seed; **95/95 tests** (7 new `RemoteCatalogLoaderTests` cover cache/bundle/nil load + fetch-error + undecodable fallbacks). While verifying, found the **published gh-pages file was stale at 272 while `main` was 300** (sessions 39's #205/#206 tours were never re-published) — a fresh launch would have regressed 300 → 272. Fixed: **republished gh-pages `Tours.json` to 300** (verified live), proved the live update end-to-end (added a ★ to one title on gh-pages → relaunch showed it with no rebuild → reverted clean), and **caught the PR branch up to 300** before merging so the offline seed ships 300 too. Merged `de8ff6a`; build bumped **45 → 46** via short-lived [PR #210](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/210) (`6418fba`, admin-merged, app-target lines only), archive clean at `/tmp/Atlas-20260618-2257-b46.xcarchive` (embedded `1.0 (46)`; no validation 90474). Upload hit Apple's *"PLA Update available"* + downstream *"No iOS Distribution certificate"* — owner accepted the updated Program License Agreement at developer.apple.com/account, retried, **TestFlight 1.0 (46) is live.** **Follow-up flagged (owner request):** auto-publish `Tours.json` → gh-pages on merge-to-main so the published file can never drift from the bundled seed again. See `archive/HANDOFF-260618.md`. Earlier status follows.

**Status (2026-06-16, session 39):** local build-cut session — **TestFlight 1.0 (45) cut and shipped; catalog crosses 300 tours.** Build cut to ship everything on `main` since build 44 (`7f675a3`): [PR #205](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/205) (6 Lisbon tours — Conserveira de Lisboa, Dolls Hospital, Oceanário de Lisboa, Palace Fronteira, Ponte 25 de Abril, Vasco da Gama Bridge; **LIS 60 → 66**) + [PR #206](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/206) (22 London tours wired into Tours.json; **LDN 58 → 80**). Content + images only — no app-code change since build 44. **Catalog crosses 300: 300 tours / 4 makers** (100 NYC + 80 LDN + 66 LIS + 54 OPO). Build bumped **44 → 45** via short-lived [PR #207](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/207) (`acc05b4`, app-target lines only; test target stays 1; `MARKETING_VERSION` stays 1.0), archived clean at `/tmp/Atlas-20260616-2045-b45.xcarchive` (embedded `1.0 (45)`; no validation 90474), owner uploaded via Organizer. **TestFlight 1.0 (45) is live.** Bump + merge ran in a `/tmp/build45` worktree; the session-38 `gh pr merge --delete-branch` worktree snag recurred (squash landed server-side; recovered by deleting the remote branch + ff-pull in the primary, then archiving there). See `archive/HANDOFF-260616.md`. Earlier status follows.

**Status (2026-06-15, session 38):** web/PM session — **14 more Lisbon tours + TestFlight 1.0 (44) cut and shipped.** [PR #200](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/200) added **14 single-stop tours under Atlas Studio LIS** (owner-supplied audio + images, no sourcing pipeline): Avenida da Liberdade, Basilica of Estrela, Casa dos Bicos, Eduardo VII Park, Jardim da Estrela, Jazigo dos Duques de Palmela, the four Alfama/Bairro Alto miradouros (da Graça, das Portas do Sol, de Santa Catarina, de Santa Luzia), Monument to the Discoveries, National Coach Museum, Ribeira das Naus, Village Underground Lisboa — **Lisbon 46 → 60; catalog 258 → 272 tours / 4 makers / 281 stops** (100 NYC + 58 LDN + 54 OPO + 60 LIS). gh-pages audio `d4bd503` + images `b56899a` (38 webp); all live URLs 200; validator clean; squash-merged `cccbd9b`. The build also carries [PR #201](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/201) (`0ea562b`, merged by a parallel session) — home placecard polish: ALL-CAPS title with `lineLimit(2)`, distance line tertiary → secondary, card width standardized at 2/3 of the active scene width via new `HomeView.placecardWidth`. Build bumped **43 → 44** via short-lived [PR #202](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/202) (`7f675a3`, app-target lines only; test target stays 1; `MARKETING_VERSION` stays 1.0), archived clean at `/tmp/Atlas-20260615-2246-b44.xcarchive` (embedded `1.0 (44)`; no validation 90474), owner uploaded via Organizer. **TestFlight 1.0 (44) is live.** All mutating work ran in isolated worktrees — no branch-flip incidents. See `archive/HANDOFF-260615.md`. Earlier status follows.

**Status (2026-06-12, session 36):** implementation session — **the home drawer pivoted from the flat in-view tour list to category rails** ([PR #194](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/194), owner-driven at the simulator), then **TestFlight 1.0 (42) cut and shipped** (bump [PR #196](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/196), archive `/tmp/Atlas-20260612-1117-b42.xcarchive`, owner uploaded via Organizer). The drawer now renders `HomeRailsViewModel.rails()`: compact Continue-listening row (sources the player's loaded tour, falls back to last-listened) → NEAR YOU → IN VIEW (≥500m pan) → one whole-catalog shelf per category, distance-sorted from the viewer; chips jump-scroll to shelves instead of filtering. Rail cards: 260pt / 4:3 uncropped heroes, one-line all-caps titles, maker subtitle, bookmark. Also landed: the **detent-persistence fix** (drawer stays mounted under the tour-detail layer — no more flash on exit), **compass relocated** beside the recenter button, **44pt pin hit areas**. `BottomSheet.swift` untouched; `TourListCard.swift` now unused. 88/88 tests. Deferred: drawer scroll-reset on reopen, distance shown on NEAR YOU cards, per-rail "see all". See `archive/HANDOFF-260612-3.md`. Earlier status follows.

**Status (2026-06-12, session 35):** local build-cut session — **TestFlight 1.0 (41) cut and shipped.** Build bumped **40 → 41 direct-to-main** (`7cf3590`, app-target lines only; test target stays 1; `MARKETING_VERSION` stays 1.0), archived clean at `/tmp/Atlas-20260612-0832.xcarchive` (embedded version verified `1.0 (41)`; no validation 90474), owner uploaded via Organizer. Carries **PR #193 (London batch 2 — 18 Bloomsbury/South Bank tours)** + #195 docs. **London 40 → 58 — now the #2 city ahead of Porto; catalog 225 → 243 tours / 4 makers.** Bump + archive ran in a `/tmp/build41` worktree because the primary checkout was mid-flight on `claude/home-drawer-rails` (**PR #194 intentionally NOT included** — owner reviewing separately). No Swift/asset/content changes beyond the pbxproj bump. See `archive/HANDOFF-260612-2.md`. Earlier status follows.

**Status (2026-06-12, session 34):** web/PM session (multi-day) — **33 more London tours via the audio-pending staging workflow**, its first at-scale run: tours text-drafted + image-staged on per-batch branches days before audio existed (`drafts/pending-tours.json` + gh-pages images), then assembled into `Tours.json` and shipped the day the MP3s arrived. **PR #192 (batch 1: 15 West End/Soho — Buckingham Palace → Carnaby Street)** and **PR #193 (batch 2: 18 Bloomsbury/South Bank — British Museum → Old Operating Theatre)** both squash-merged to `main`, CI green. **Catalog: 4 makers / 243 tours / 252 stops; London 25 → 58** (100 NYC + 54 OPO + 31 LIS + 58 LDN). Batch 1 shipped in TestFlight 1.0 (40); **batch 2 awaits the next cut**. Lessons: a conflicted PR never triggers CI (resolve, don't wait); parallel-session Tours.json conflicts → take main's file + re-run the idempotent assembler; the remote-env git proxy blocks branch deletion (delete `claude/dreamy-wozniak-nM6a4` + `-batch2` via GitHub UI). No Swift/asset/project changes. See `archive/HANDOFF-260612.md`. Earlier status follows.

**Status (2026-06-09, session 30):** web/PM session — **London expansion, Westminster/Whitehall cluster**. Added **10 more London tours** under Atlas Studio LDN (Westminster Abbey, Houses of Parliament & Big Ben, Westminster Hall, Trafalgar Square, The National Gallery, St Martin-in-the-Fields, Banqueting House, The Cenotaph, Churchill War Rooms, Parliament Square), taking London to **25** and the catalog to **4 makers / 174 tours / 183 stops**. All single-stop, geofenced, owner-narrated; merged to `main` via PR #188 (one consolidated PR, CI green). Unsplash deep for famous landmarks; restricted-interior subjects (Westminster Hall roof, Banqueting House Rubens ceiling, Churchill War Rooms Map Room) used owner-pasted images (pulled from the session-transcript `.jsonl`). No Swift/asset/project changes; no build bump (TestFlight stays 1.0 (37); these ship in the next cut). Earlier status follows.

**Status (2026-06-09, session 29):** web/PM session — **London expansion**. Added **9 more London tours** under Atlas Studio LDN (Lloyd's of London, Bank Junction, St Stephen Walbrook, St Bartholomew the Great, Smithfield Market, Postman's Park, The Barbican, Guildhall, Temple Church), taking London 6 → **15** and the catalog to **4 makers / 164 tours / 173 stops**. All single-stop, geofenced, owner-narrated. Merged to `main` via PR #185 (Lloyd's) + PR #186 (the other 8, consolidated). Image-sourcing lesson codified: interior-famous City churches/sites have ~no usable CC0 modern photo (Unsplash returns other churches; Wikimedia modern photos are CC BY-SA), so the owner supplied images by pasting them in chat — Claude pulls owner-pasted images out of the session-transcript `.jsonl` (base64 image blocks) and processes them. No Swift/asset/project changes; no build bump (TestFlight stays 1.0 (37) — these 9 ship in the next cut, 37 → 38). Earlier status follows.

**Status (2026-06-08, session 28):** web/PM session — **London launch**. Added **Openverse** as a CC0-only image source to the pipeline (owner policy: public-domain `cc0,pdm` only, since the app has no attribution UI), and formalized the "upload tours without images" protocol with inline full-size candidate presentation. Created a **fourth maker, Atlas Studio LDN** (🇬🇧), and added the catalog's **first 6 London tours** — St Paul's Cathedral (`sacredSites`), The Monument (`history`), The Tower of London (`history`), Tower Bridge (`architecture`), Leadenhall Market (`culturalHeritage`), The Gherkin (`architecture`) — all single-stop, geofenced, owner-narrated, Unsplash imagery (owner chose modern photos over CC0 historical art). New reusable rule: **tall subjects (columns/spires) need a top-biased hero crop** since the 1200×900 hero is landscape (The Monument's gilded urn). Catalog **149 → 155 tours / 3 → 4 makers / 164 stops**. No Swift/asset/project changes. All merged to `main` via PR #181 (first 5) + #182 (The Gherkin); build bumped 36 → 37 (`49a81ac`) and **TestFlight 1.0 (37) is live** with the 6 London tours. Earlier status follows.

**Status (2026-06-06, session 25):** every V1 functionality milestone is shipped on `main`. Implementation session — **Search polish + place-search performance**, owner-directed at the simulator. [PR #154](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/154): Search typography flattened to the `caption` token (result/maker titles stay `body` ALL CAPS); result rows single-line all-caps with **maker-only** subtitle + square thumbnails (kills the old two-line category•maker wrap); new **Makers** section deep-links to `MakerView`. `SearchView.swift` only — shared `SearchBar` (Home) untouched. [PR #160](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/160): the place-search typing lag is fixed by swapping the per-keystroke `MKLocalSearch` for **`MKLocalSearchCompleter`** (instant type-ahead; the heavy geocode deferred to a single on-tap resolve, with a spinner on the resolving row) — supersedes session 23's 300ms-debounced `PlaceSearchService` internals. [PR #164](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/164): place results limited to cities/towns/regions + landmark POIs (museums, parks, monuments, …) via an `MKPointOfInterestFilter` — businesses (restaurants/shops/services) excluded; addresses unaffected. **No build bump (34). 88/88 tests pass.** Earlier status follows.

**Status (2026-06-06, session 24):** every V1 functionality milestone is shipped on `main`. Implementation session — **full-screen Player polish, round 2**, owner-driven at the simulator (continues session 22). The structural change: `PlayerView` is now presented as a `.fullScreenCover` from `BottomModuleRoot` (the top window that hosts the mini-player + tab bar) rather than from `ContentView`, so the cover slides over the module *in the same window* — eliminating the transition gap that the old hide/show-the-module-window approach left behind (removed `setHidden` entirely; `PassThroughWindow.hitTest` claims all touches while presenting a modal). Opening the player also dismisses the underlying detail sheet, so retracting returns to the tab root and Home shows its floating island (not edge-to-edge). Plus: single-line/marquee stop title, caption that always reserves 3 lines, and the system volume slider bracketed by speaker icons with a smaller thumb. **No build bump (33). No `AudioPlayerService` API change. 88/88 tests pass.** Drag-to-dismiss + volume/AirPlay still need a real-device check. Earlier status follows.

**Status (2026-06-05, session 22):** every V1 functionality milestone is shipped on `main`. Implementation session — **full-screen Player polish**, owner-driven at the simulator, across two `PlayerView`-focused PRs. [PR #148](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/148): full-screen cover (bottom-module window hidden via new `BottomModuleWindowController.setHidden`), caption typography, carousel matched to the detail sheet. [PR #150](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/150): drag-to-dismiss grab-handle sheet, ••• overflow menu mirroring the detail sheet (player wrapped in a `NavigationStack` for "Go to creator"), five-equal-column transport with play screen-centered (`speed · −10 · play · +10 · next-track`), thin gold knob-less scrubber, 0.5×/0.75× speeds, and a system `MPVolumeView` slider (device-only — blank in sim). **No build bump (32). No `AudioPlayerService` API change. 84/84 tests pass.** Drag-to-dismiss + volume + AirPlay need a real-device check. TestFlight unchanged. Earlier status follows.

**Status (2026-06-06, session 23):** implementation session — **place search added to Search**. Typing a place name (e.g. "London", "Brooklyn") now surfaces a **Places** section above the Makers/Tours catalog results; tapping a place dismisses Search and glides the Home map camera to that region. Backed by Apple's `MKLocalSearch` (no new dependencies, no backend — same MapKit/CoreLocation already in the app). New `PlaceSearchService` (debounced 300ms, cancels stale lookups, derives per-feature zoom from the placemark radius); `SearchView` gains the Places section + a one-shot `HomeSharedState.pendingMapMove` channel to the map; `HomeView` flies the camera (additive — recenter / pin-tap / startup paths untouched) and shows a transient "No Atlas tours here yet" hint when the destination has no tour pins (decision: go-anywhere + overlay). New `MapRegionGeometry.anyStop(of:inside:)` reuses the existing antimeridian-aware `MKCoordinateRegion.contains`. **88/88 tests pass (4 new).** This explicitly lifted the prior "Home map camera is settled — don't touch" constraint, per owner approval, for this additive change. Also folds in the same day's Search-polish commit (caption typography, single-line result rows, maker result section). Known: the no-tours hint can paint a few seconds late **in the simulator** (MKMapView tile-streaming starves SwiftUI overlay compositing) — verify prompt on device; one cosmetic `placemark` iOS-26 deprecation warning left as a follow-up. No build bump (stays 33). TestFlight unchanged.

**Status (2026-06-04, session 20):** every V1 functionality milestone is shipped on `main`. **TestFlight 1.0 (28) is live** (unchanged from session 19). Session 20 (web/PM, 2026-06-04) was a pure image-pipeline pass — no new tours, no Swift/code changes. The pipeline was codified as CLAUDE.md Rule #8. Fourteen NYC tours received new hero/gallery images sourced from Unsplash, verified by Gemini, cropped to 1200×900 WebP q82, and uploaded to gh-pages: Empire State Building, Chrysler Building, Brooklyn Bridge, Met Museum, Bethesda Terrace, Grand Central (gallery only), High Line (gallery only), Rockefeller Center, One WTC, Guggenheim, Statue of Liberty, Washington Square Park (gallery only), Flatiron Building, Lincoln Center. Times Square was skipped at owner request. ~25 NYC tours still need gallery images; 9/11 Memorial is queued next. All changes are on branch `claude/session-012bd7xvvgfz8cpkucw3bqy8-0MeY7`, pending merge to main. Catalog: **138 tours / 147 stops / 3 makers** (96 Atlas Studio NYC + 37 Atlas Studio Porto + 5 Atlas Studio Lisbon; 136 single-stop + 2 multi-stop).

**Status (2026-06-03, session 19):** every V1 functionality milestone is shipped on `main`. **TestFlight 1.0 (28) is live** (uploaded 2026-06-03 evening) — carries six small home-screen polish PRs ([#128](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/128) muted standard map style; [#129](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/129) `StopPin` 14/18 → 16/20pt and cluster count 12pt SF Mono regular; [#130](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/130) curated POI `.including(...)` allowlist via the new `HomeMapSection.tourPOI` static — cultural / civic / nature / transit kept, ATMs / gas stations / retail / nightlife / activity venues hidden; [#131](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/131) drawer list scoped to `visibleRegion` and sorted by map-center distance, with the header count collapsed to `displayedTours.count` so list and header always agree; [#132](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/132) `BottomModuleRoot` + `BottomSheet` switched to `.ignoresSafeArea(.all, edges: .bottom)` so the keyboard slides up *over* the bottom module + drawer instead of pushing them up; [#133](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/133) `onPinTapped` animates the camera to centre the tapped pin at the current span). Plus PR [#127](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/127) (7 central Porto classics — Cathedral, São Bento, Clérigos, Ribeira, São Francisco, Bolsa, Dom Luís I — from session 18) and the build bumps that cut 27 (left unshipped) then 28 ([PR #134](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/134), defensive). Catalog now **138 tours / 147 stops / 3 makers** (**96 Atlas Studio NYC** + 37 Atlas Studio Porto + 5 Atlas Studio Lisbon; 136 single-stop + 2 multi-stop). The prior session (18, 2026-06-03, web/PM) shipped 18 new NYC tours that landed direct-to-main between sessions 17 and 18 (catalog **113 → 131 tours**, NYC-area **73 → 91**, multi-stop **1 → 2**); 4 additional NYC tours (Grand Concourse, Strivers' Row, IAC Building, The Strand Bookstore) were added in the same web/PM run bringing the NYC total to **96**. Notable adds: Museum of Modern Art (MoMA), Bryant Park, Federal Hall, Coney Island, Schomburg Center for Research in Black Culture, Eldridge Street Synagogue, Grand Concourse, Strivers' Row, IAC Building (Frank Gehry, 2007), The Strand Bookstore, Four Freedoms Park, Green-Wood Cemetery, African Burial Ground National Monument, Cooper Union Foundation Building, Tompkins Square Park, Columbus Park (Chinatown), Grand Army Plaza (Brooklyn), and — **the second multi-stop tour ever** in the catalog — Fifth Avenue Walk (joining the AMNH Four Facades walk from 2026-05-26). Two validator-caught typo fixes preceded the build: `triggerMode geofence → geofenced` across tours 114–131 (`3235d33`) and `TourKind multi → multiStop` on Fifth Avenue Walk (`7c11003`). Build bumped 25 → 26 in `17dba88` (direct-to-main per the established pattern `aba765f` for 25, `401358f` for 24 — single-line pbxproj edit). `xcodebuild archive` clean at `/tmp/Atlas-20260603-1840.xcarchive`; owner uploaded via Organizer. No Swift / asset / project structure changes this session beyond the pbxproj bump. The prior session (17, 2026-06-02) shipped a long iterative home-polish batch via [PR #113](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/113) + build bump 24 → 25 via [PR #114](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/114).

**Status (2026-06-02, session 17):** every V1 functionality milestone is shipped on `main`. **TestFlight 1.0 (25) was live** (uploaded 2026-06-02 evening) — carries a long iterative home-polish batch via [PR #113](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/113) on top of session 16's 11-tour Portugal content. PR #113 highlights: typography overhaul (`AtlasTypography.caption` is now 13pt SF Mono regular; `body` is now 15pt SF Pro regular); home-chrome dimensions tightened (search/chips 24→16pt horizontal inset and 46→44pt height; map control glyphs 16→20pt; tab bar icons 22→20pt; drawer top corner 30→28pt; mini-player avatar→bar and ring→bar both 16pt, avatar→text 16pt, skip-glyph→ring outer 16pt visual); ALL CAPS pass across the home header, mini-player title line, and tab bar labels; new `Maker.avatarEmoji` field with Atlas Studio NYC's avatar set to 🍎; and cluster smoothness — item #6 of the original 11-item brief closed via a new `HomeMapSection.snappedSpan(_:)` helper that rounds the visible region's span to two significant figures before deriving cluster cell pitch, so MapKit's sub-percent settle drift on pure pans no longer re-buckets markers near cell boundaries. Build bumped 24 → 25 via [PR #114](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/114). Earlier the same day, session 16 (web/PM) added 11 Portugal tours via [PR #110](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/110) on top of the prior session's home-screen polish work. Eight new Atlas Studio Porto tours (Batalha Centro de Cinema, Building in Senhora da Luz, Mosteiro Santo Agostinho da Serra do Pilar, Teatro Rivoli, Trindade Metro Station, Vodafone Headquarters, Municipal Library of Viana do Castelo, and Biblioteca Pública e Arquivo Regional Luís da Silva Ribeiro in Angra do Heroísmo — **the catalog's first Azores tour**) and three new Atlas Studio Lisbon tours (Adega Mayor in Campo Maior — **first Alentejo tour**; Óbidos; Capela do Monte above Monte da Charneca in Lagos — **first Algarve tour**). Catalog **113 tours, 3 makers** (102 → 113; 105 → 117 stops). Atlas Studio Porto 22 → 30; Atlas Studio Lisbon 2 → 5. New cities in catalog: Viana do Castelo, Angra do Heroísmo, Campo Maior, Óbidos, Lagos. Audio + images chunked across four gh-pages commits (`f4e849d`, `259309d`, `7a67dc9`, `24c6e36`) after the combined push hit HTTP 408 — no SSH key on machine, fell back to HTTPS chunks. Build bumped 23 → 24 via [PR #111](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/111) (admin-merged metadata change). `xcodebuild archive` clean at `/tmp/Atlas-20260602-2146.xcarchive`; owner uploaded via Organizer. Mainland Portugal coverage now spans north → centre → Lisbon belt → Alentejo → Algarve, plus Terceira. The prior session (15, 2026-06-01) shipped the eleven-item home-screen polish pass via [PR #103](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/103) + [PR #104](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/104) + drag-clamp follow-up [PR #107](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/107), with builds 22 ([PR #105](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/105)) and 23 ([PR #108](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/108)). Earlier status follows.

**Status (2026-05-29):** every V1 functionality milestone is shipped on
`main`. Major UX work shipped 2026-05-24/25 — bottom module consistency
(PRs #66–70), home polish + player-state hardening (PRs #60–61), placecard
pop-up on pin tap (PR #75), tour detail as slide-up layer with drawer hoist
(PR #76), slide animation fix (PR #77), AsyncImage crossfade fix (PR #78).
**Session 8 (2026-05-27)** replaced the SwiftUI `.offset` slide layer with
a UIKit `UIPresentationController`-driven modal so detail slides up *from
behind* the persistent mini-player + tab bar (now hosted in a secondary
higher-level `UIWindow` — Apple Music pattern). **Session 11 (2026-05-28)**
closed the chrome-shade seam (PR #91) — hardcoded RGB in `secondaryBackground` +
bars edge-to-edge in non-Home/detail-up. **Session 12 (2026-05-29)** landed
PR #93 (tour-detail masthead + toolbar + overflow menu, part 1 of 2),
PR #95 (light-mode bottom-module bug — secondary-window trait-collection
plumbing), PR #92 (Casa das Histórias Paula Rego — first Cascais tour),
and PR #94 (5 Porto-area architecture tours). TestFlight build **1.0 (17)
is live** (uploaded 2026-05-29).

**Content (M-launch-content ✅).** **97 tours** in `Resources/Tours.json` (73 NYC + 17 Porto-area + 2 Marco de Canaveses/Lisbon/Cascais/Matosinhos under Atlas Studio Lisbon and Atlas Studio Porto).
First **multi-stop tour** added 2026-05-26: "American Museum of Natural
History: Four Facades" — 5 stops (~8m 44s), exterior architecture walk,
geofenced. This unblocks M-qa checklist items 6 + 7. The original 10 NYC landmarks (Grand Central, Times
Square, South Street Seaport, Empire State Building, Statue of Liberty,
**Home polish + player-state hardening (PR #60, 2026-05-24 late-pm).**
Bigger bottom-module radius (48→56), drawer now overlays the mini-player +
tab bar (squared bottom corners via new `bottomReservedHeight` /
`bottomCornerRadius: 0`), chip row + search bar share `searchBarHeight =
46`, `caption` font throughout, "tours in view" count math fixed (uses
individual stops + screen-coord math; swaps to "Let's explore together!"
at the `.large` detent), recenter button tracks the drawer's top edge in
every detent. Same PR fixed three audio-state bugs surfaced during the
visual review: (1) `TourDetailView` no longer disables "Open player"
mid-load — the sheet is the user's escape hatch; (2)
`AudioPlayerService.seek(to:)` synthesizes `.ended` when the user scrubs
to/past `duration` (AVPlayer doesn't fire `didPlayToEndTime` on manual
seek, so without this we'd park in `.waitingToPlayAtSpecifiedRate` →
flip to `.loading`); (3) `PlayerView.togglePlayPause` on `.ended` now
calls a new `replayCurrent()` that restarts via `playIntro`/`playStop`
(was `audioPlayer.play()`, a no-op on the drained AVQueuePlayer queue).
Commit `e5b31da`. 84/84 tests pass; CI green.

**Module geometry on non-Home tabs (PR #66, 2026-05-25).** Extends PR
#60's bottom-module work past the home screen. On Home the mini-player +
tab bar still float as a rounded island; on Library / Settings / Manage
downloads / Tour Detail / Maker the module now extends flush to the
screen edges (no horizontal inset, no rounded outer corners) and its
background runs through the home-indicator safe area, with the button
column padded up so taps still clear the indicator. Every scrollable
non-Home surface now applies `.safeAreaInset(.bottom)` sized to the
module so the last list item / settings row / tour-detail description is
always reachable above the module. Mechanism: new
`AtlasBottomModule.height(extendsToScreenEdges:)` helper centralizes the
math (replaces HomeView's inlined `floatingIslandHeight = 64 +
layoutHeight`); `MiniPlayerBar` and `AtlasTabBar` each gain an
`extendsToScreenEdges` flag. TourDetailView's `actionBarHeight` now
tracks the helper (was hardcoded `130 + layoutHeight + 8`) and its
trailing ScrollView spacer matches `actionBarHeight` exactly — fixes the
pre-existing too-small 72pt spacer that let the last description lines
hide behind the action bar. Commit `2452f52`. 84/84 tests pass; CI green.

**Restore Home floating island + anchor at OLD Home position (PR #69,
2026-05-25 pm-2).** PR #68 introduced two compounding regressions on
Home that the owner caught immediately. (1) `AtlasTabBar` added the
home-indicator safe-area inset to the view's *height* in full-edge
mode — physically shoved the buttons + mini-player up by ~34pt. (2)
The PreferenceKey-driven `moduleGeometry` got stuck at `.fullEdge`
after popping back from a detail screen, leaving Home in the wrong
geometry. Net effect: Home no longer floated AND everything sat too
high. Fix: `AtlasTabBar.body` is now a fixed-height VStack (56pt
painted button row + 8pt outer strip) in both modes; only what's
painted in the 8pt strip changes (transparent on Home, opaque
elsewhere). The safe-area zone underneath is already covered by the
painted button row because of the parent `.ignoresSafeArea(.bottom)`.
`AtlasBottomModule.height` is a constant 126pt across modes.
Replaced PreferenceKey with `@Observable AtlasNavigationState`
tracking `pushedDepth` via push/pop from each pushed view's
onAppear/onDisappear — deterministic, no sticky values. Verified via
`snapshot_ui`: tab buttons at y=807 in every tab (Home, Library, Me),
matching the OLD Home position exactly. Commit `8d928b3`. 84/84
tests pass; CI green.

**Buttons identical across surfaces; only background fill differs (PR
#70, 2026-05-25 pm — final shape).** Bar contents render the exact same
form on every surface — Home, Library, Me, every pushed detail. 8pt
horizontal inset, phone-screen-radius rounded bottom corners,
transparent 8pt strip below. The only difference between Home
(floating island) and the rest (full-edge): `ContentView` paints an
edge-to-edge `secondaryBackground` rectangle BEHIND the inset bar on
non-Home surfaces, making the side + bottom gaps blend into a
continuous strip the same color as the bar. On Home that fill isn't
painted, so the gaps show the map. `AtlasTabBar` + `MiniPlayerBar`
lost their `extendsToScreenEdges` flags entirely (single form now).
Final snapshot_ui anchor: tab buttons at x=8 / 136.67 / 265.33 width
128.67 on every surface, identical to OLD Home. Commit `643cbd7`.
84/84 tests pass; CI green.

**Restore Home floating island after PR #68 regression (PR #69,
2026-05-25 pm).** PR #68 made non-Home's tab bar 34pt taller (by
adding the safe-area inset to its painted height), which physically
shoved buttons up — opposite of the "anchor at OLD Home position"
goal. Its PreferenceKey-driven `moduleGeometry` also got stuck at
`.fullEdge` after popping back from a detail, so Home rendered in
the wrong (full-edge) shape with the buttons in the wrong (higher)
position. PR #69 fixed both: `AtlasTabBar` view height pinned at a
fixed 64pt in every geometry (56pt painted button row + 8pt outer
strip — only the strip's fill differs between modes); replaced the
preference with an `@Observable AtlasNavigationState` tracking
`pushedDepth` via push/pop from each pushed view's
appear/disappear; `AtlasBottomModule.height` locked to a constant
126pt. Commit `8d928b3`. 84/84 tests pass; CI green. Superseded
mechanism-wise by PR #70 (which collapsed even the remaining
conditional bottom-strip fill into a single fill-rectangle
decision in `ContentView`).

**Consistent bottom module across tabs + detail (PR #68, 2026-05-25 pm).**
Visual review of PRs #65 + #66 on `main` caught three follow-ups that
PR #66 left on the floor. (1) `SearchBar` was presenting `SearchView` as
`.sheet(...)`, which covered `ContentView`'s ZStack — the mini-player +
tab bar disappeared when the user opened search, and the further
`TourDetailView` push inherited the sheet's own nav stack. Switched to a
`NavigationLink` push into the host tab's stack so the module stays
visible underneath; `SearchView` dropped its inner `NavigationStack` +
"Close" toolbar and now applies a `safeAreaInset(.bottom)` so result
rows clear the module. (2) `AtlasTabBar` was adding the home-indicator
safe-area inset *inside* the painted button row in full-edge mode,
shoving the buttons ~26pt higher than they sat on Home — the bar
appeared to jump up when switching tabs. Refactored so the safe-area
fill is a separate background rectangle below an identically-laid-out
button row; only what's painted below changes between modes. (3) Detail
screens (`TourDetailView` / `MakerView` / `ManageDownloadsView` /
`SearchView`) used to inherit the Home tab's floating-island look when
pushed from Home, which let scrolled content peek through the 8pt outer
transparent gap below the rounded tab bar. Now every detail screen
declares the full-edge geometry directly and overrides its host tab's
preference while it's on top. Mechanism: replaced `\.atlasIsHomeTab` env
value (deleted) with a typed `AtlasModuleGeometry` preference; each
surface declares its preference at its root; the deepest declaration
wins; `ContentView` reads via `onPreferenceChange` and threads geometry
into `MiniPlayerBar` + `AtlasTabBar`. `AtlasBottomModule.height` math
updated to add the new 8pt outer gap above the safe-area fill on
non-Home. Commit `fe11d99`. 84/84 tests pass; CI green.

Brooklyn Bridge, Rockefeller Center, Met, High Line, 9/11 Memorial),
Brooklyn Museum, 9 added 2026-05-21/22 — Whitney, AMNH, Brooklyn
Bridge Park, Chrysler Building, Flatiron Building, Governors Island,
Guggenheim, Intrepid, and Casa da Música (Porto — the first non-NYC
tour); 11 added 2026-05-22/23: Little Island, Manhattan Bridge
(from DUMBO), Museum of the City of New York, NYPL Fifth Avenue, The
Oculus, St. Patrick's Cathedral, Vessel (Hudson Yards), Wall Street,
Washington Square Park, Cooper Hewitt, and El Museo del Barrio; and
**7 added 2026-05-23 afternoon** — The Frick Collection, Neue Galerie,
Museum of Arts and Design, New Museum, The Morgan Library & Museum,
The Shed, and **MoMA PS1** (the first Queens tour). **All 38 tours
now have `heroImageURL` populated** — CC-licensed Wikimedia Commons
photos added 2026-05-23/24 (commit `8699ac6` + subsequent individual
corrections). Images are landscape-optimised where possible; Whitney
and MAD have no landscape exterior on Commons and use the best
available option. Audio hosted on the `gh-pages` branch (served at
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
  is authored. All 38 tours are single-stop, so the app's defining
  feature is uncovered by content.
- **M-launch-content (optional more)** — owner may decide 38 tours
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
- **Place search (2026-06-06, session 23).** A **Places** section above
  the catalog results geocodes the query via Apple's `MKLocalSearch`
  (cities / neighborhoods / landmarks); tapping one flies the Home map
  to that region instead of opening a tour. If the destination has no
  Atlas tours, a transient "No Atlas tours here yet" hint appears on the
  map. Place results are *not* recorded in `RecentSearch` (catalog-only).
  See `PlaceSearchService`, `HomeSharedState.pendingMapMove`,
  `MapRegionGeometry`.

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

## V2 — execution plan (in progress)

**V2 = open the platform to outside makers + give consumers accounts.** It executes
Tier 1 below (backend → auth + moderation → maker UI) and pulls Tier 3's sign-in
forward. Each step is shippable on its own; the *design* steps are docs+SQL produced in
web sessions, the *app* steps need a Mac (`test_sim` + simulator review before merge).

Backend decided: **Supabase (Postgres)** — see `docs/backend-design.md`.

| Step | What | Status |
|---|---|---|
| **1. Detach catalog** | App reads the catalog from a URL (`RemoteCatalogLoader`); bundled copy = offline seed | ✅ Shipped — build 46 (PR #209) |
| **2. Backend foundation** | `makers`/`tours`/`stops` schema, public-read RLS, `get_catalog()` RPC, seed from `Tours.json` | ✅ **DONE (2026-06-27)** — Supabase project "Dozent" live + seeded (5/370/396); **app cutover shipped (PR #255)** — `RemoteCatalogLoader` reads `get_catalog` first, gh-pages fallback. Live in **TestFlight 1.0 (50)** |
| **3. Accounts & auth** | `profiles`, self-serve makers, per-tour moderation, `reports`, consumer-sync tables; Apple+email+Google | ✅ **DONE — shipped through TestFlight 1.0 (57).** Email (#262) + Apple (#274) + Google (#277) sign-in; cross-device sync of library/makers/progress/recently-viewed (#279/#287) with logout-clear (#283); "Report a concern" → `reports` (#290). `AuthService` + `SyncService`. (Report-email notifications = pending owner Resend setup.) |
| **4. Maker dashboard** | Phase 1 single-piece creation (record/import audio, pin+radius, photos, transcript, metadata, submit→review), then Phase 2 multi-stop | ✅ **Phase 1 authoring loop COMPLETE — LIVE in TestFlight 1.0 (63)** (owner-confirmed 2026-07-03). Architecture: the **Me tab is a Profile = a maker page** (one `MakerView`, modes). Shipped: profile tab (#300), standalone creator screen via `MakerPresenter` (#302), create/edit profile → `makers` (#304), create-a-tour draft form + My-Tours feed with status badges (#307), and the **full tour editor (#310)** — record (`AVAudioRecorder`) / import audio → `tour-audio`, photos (PHPicker → crop 1200×900 → `tour-images` → hero+gallery), transcript, and **Submit for review** (status→`in_review`). `MakerProfileService` + `MakerTourService`; storage buckets + RLS from PR #222. **Remaining (both small):** the submit-email webhook (owner: `tours` UPDATE → `notify-moderation`) + an admin **Publish** path (`publish_tour`). **Phase 2 (multi-stop authoring)** needs no backend change — future. |
| **5. Moderation (email-me)** | Owner chose **email notify**, not a queue UI: emailed on submit/report, act via `publish_tour`/`takedown_tour` | ✅ **Report emails LIVE (2026-07-01).** SQL helpers (PR #224) + `notify-moderation` Edge Function deployed + Resend secrets + `reports` INSERT webhook — owner-confirmed end-to-end. Optional `tours` UPDATE→in_review webhook deferred to maker authoring. |
| **6. Paid tours** | Apple IAP; `Tour.priceUSD` goes live; ownership tracking (Tier 2 #4) | ⬜ Not started |
| **7. Maker payouts** | Stripe Connect (Tier 2 #5) | ⬜ Not started |
| **8. Consumer richness** | Follow-a-maker push, in-app search, share links (sign-in/sync already in Step 3) | ⬜ Partially pulled forward |

**Catalog rollout (de-risked, two phases)** once the DB is live: (1) keep the app on
gh-pages while a job exports `get_catalog()` → `Tours.json` → gh-pages (proves the DB,
zero app change); (2) point the app's `RemoteCatalogLoader` at the Supabase RPC, gh-pages
stays a fallback mirror. Details in `docs/backend-design.md`.

Design references: `docs/backend-design.md`, `docs/accounts-design.md`, `backend/`.

### V2 — remaining to-dos (checklist)

As of 2026-06-27. **Critical path to "outside makers can publish a tour": B (Supabase
config) → A (Mac app work).** Everything else (payments, consumer extras, media
hosting) can follow.

**A. App-side — needs a Mac / Xcode session (each gated by `test_sim` + simulator review)**
- [x] Add `supabase-swift` (first third-party dependency) — **done, PR #262 (2026-06-27)**: SPM 2.48.0, app-target only; used by `AuthService` (the catalog read still uses its own `URLSession` fetcher)
- [x] Point `RemoteCatalogLoader` at the `get_catalog` RPC (+ `apikey`/anon header) — **done, PR #255 (2026-06-27)**: Supabase-first with gh-pages fallback; `SupabaseCatalogFetcher` + `SupabaseConfig` (client-safe anon key). Live-verified 370 tours from Supabase in-sim
- [x] Sign-in UI (Apple / email / Google) in the "Me" tab — **all three done** (email #262 · Apple #274 · Google #277), shipped in builds 51/52/53. `AuthService` + `SignInView` (Apple + Google buttons + email sign-in/create/confirm), Me-tab account row + sign-out.
- [x] Sync a signed-in user's library / saved makers / recents → the `user_*` tables — **done (#279 library+makers, #287 recently-viewed; #283 logout-clear), builds 54–56.** `Data/SyncService.swift`: pull→merge→push on sign-in + debounced write-through; `user_library` / `user_saved_makers` / `user_recently_viewed`. Cross-device round-trip device-verified by owner.
- [~] Maker authoring UI (`Features/Maker/` + `Features/Profile/`) — Phase 1 single-stop, then Phase 2 multi-stop. **In progress (session 51):** Me-tab profile = maker page (#300); standalone public creator screen via `MakerPresenter` (#302); create/edit creator profile → `makers` row (#304, in review). **Next:** create-a-tour form → `draft`, then audio/photos/transcript/submit.
- [x] Wire the "Report a concern" overflow action → `reports` table — **done, PR #290 (build 57)**: `ReportSheet` + `ReportsService` insert (`returning: .minimal`); email removed from the client. Email notifications pending owner Resend/Edge-Function setup.

**B. Supabase config — owner (dashboard; Apple/Google need their dev consoles)**
- [ ] Enable auth providers — email (toggle), Apple (Services ID), Google (OAuth client)
- [x] Deploy `notify-moderation` Edge Function + set Resend secrets + add `reports` INSERT DB webhook — **done 2026-07-01**, owner-confirmed email delivery. (Optional `tours` UPDATE→in_review webhook deferred until maker authoring ships.)
- [ ] Make yourself admin: `update profiles set is_admin = true where id = '<your auth uid>';` (once you have a signed-in account)

**C. Needs owner decisions, then design**
- [ ] Paid tours (Step 6): per-tour purchase / subscription / both → then design Apple IAP
- [ ] Maker payouts (Step 7): confirm Stripe Connect → then design

**D. Deferred / later**
- [ ] Media hosting decision — gh-pages vs Supabase Storage vs a CDN (owner leans "one place"); see `docs/cdn-decision.md`
- [ ] Consumer richness (Step 8): follow-a-maker + notifications, in-app search, share links
- [ ] Moderation web admin tool — only if volume outgrows the email approach

**E. Housekeeping**
- [ ] Fix 2 dead gallery images (The Oculus, The Charging Bull — Wikimedia 404)
- [ ] Delete merged `claude/*` branches (GitHub UI — proxy blocks deletion from sessions)

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

- **Tier 1 #1** — backend stack? **DECIDED 2026-06-21: Supabase (Postgres).**
- **Tier 1 #1 / maker onboarding** — application gate vs self-serve? **DECIDED 2026-06-21: self-serve + per-tour moderation** (anyone signed in can create one maker profile; publishing is admin-gated).
- **Tier 1 #2** — phone-only MVP, web-only MVP, or both from day one? *(open)*
- **Tier 1 #2** — auto-transcription via Apple's on-device API (free, lower quality) or Whisper API (paid, higher quality)? *(open)*
- **Tier 2 #4** — paid tours per-purchase, subscription, both? *(open)*
- **Tier 2 #5** — Stripe Connect or another marketplace processor? *(open)*
- **Tier 3 #6** — Sign in with Apple only, or also email / Google? **DECIDED 2026-06-21: Apple + email + Google.**
- **Tier 3 #6 / accounts scope** — consumer accounts now or later? **DECIDED 2026-06-21: now** (optional sign-in + cross-device library/saved sync; anonymous use still works).
- **Tier 4 #10** — do reviews and ratings ship at all, or never? *(open)*

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

# HANDOFF 2026-07-05 (session 56) — directed polish pass → TestFlight 1.0 (71)

Code session. Owner pivoted from features to polish after an honest app assessment. Shipped a polish batch + a merged home-perf fix in **build 71**.

## The assessment (context for why we pivoted)
Owner asked for a candid read. Summary given: execution is strong (real app on TestFlight, clean architecture, 140 tests, solid backend, genuine 509-tour content library) — but **features have run ahead of users** (the whole social layer is network plumbing for a base that doesn't exist yet), the **V1→V2 creator-platform pivot** made this a much harder two-sided product, the **core GPS-triggers-audio-while-walking experience is the least-verified thing** (only field-testable), and there's **no visual identity yet** (placeholder icon/color). Highest-value non-polish move: get real people walking real tours. Owner agreed and chose to spend this session polishing.

## What shipped in build 71

### Identity: brand accent = dark gold (brass) `#8B7535` ([PR #344](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/344), squash `63e9ab4`)
- Owner-confirmed the gold the app already wore is THE brand color. (A mis-paste briefly set terracotta `#B85042`; reverted immediately — see memory `project-brand-color-brass-gold`, which also records: **never re-propose terracotta, never add a dark-mode accent variant**.)
- `AccentColor.colorset` → `0x8B7535` universal, **no dark-mode variant** (owner: "the one that stays consistent").
- `AtlasColors.mapPin = accent` — one source of truth (the ~58 `mapPin` call sites now resolve through the asset).
- `TourStatus.takenDown` badge → red (an accent badge would now be identical to In-review's gold).
- Terracotta removed everywhere: app tokens/comments, `docs/design-tokens.md`, CLAUDE.md, and the gh-pages share (`/t/`, `/m/`) + privacy pages (already pushed live).
- Visually near-identical — every gold surface is pixel-for-pixel the same. Sim-verified.

### Haptics (same PR) — `Components/AtlasHaptics.swift`
Centralized helper; no-op in the Simulator (**device-only to feel**). Fired at: save/bookmark toggle (both stores' user-action methods), follow/unfollow (on tap, pre-network), approve(success)/decline, download complete(success)/fail(error) (MainActor hop — URLSession completion is nonisolated), and the **geofence stop auto-fire** in `ProximityMonitor.handleEntry` (medium "you've arrived" bump — the app's signature moment, felt pocketed).

### Error toasts (same PR) — `Components/AtlasToast.swift`
`ToastCenter` (app-wide, injected into both windows) + `ToastHost` rendered as a top overlay in the **bottom-module window** — which sits above every UIKit modal, so a toast shows over tour/maker layers + sheets. Auto-dismiss ~3.2s; error/success/info styles. Wired to the two **genuinely-silent** failures: **follow/unfollow** and **approve/decline a request** (before, a bad network just did nothing — button didn't change, row silently stayed). Left as-is: Report (already an inline error), download (already a `.failed` button state), background catalog refresh (intentionally silent). Render sim-verified via a temp trigger (removed; grep-clean).

### Home stays alive across tab switches ([PR #347](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/347), squash `b3441c6`)
The owner's on-device "return-to-Home lag" fix, from a **parallel session** — I verified + merged it into this build. `ContentView.tabContent` now keeps `HomeView` permanently mounted (ZStack, opacity + `allowsHitTesting` toggled, not `switch`-swapped) so its `MKMapView` (~509 clustered annotations) isn't torn down + rebuilt on every return to Home; `HomeView(isActive:)` short-circuits camera side-effects while hidden. **Sim-verified:** Library/Me render opaque (no Home bleed-through), and returning to Home is instant with camera position + drawer detent preserved (no rebuild flash, no reset to default region).

### Cleanup
Deleted the long-dead `Features/Home/TourListCard.swift` (unused since the rails pivot; only leftover reference was a doc-comment).

## Build 1.0 (71)
- Bump **70 → 71** via short-lived [PR #351](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/351) (admin-merged; app-target only, test target stays 1).
- Validator PASS (9 makers / 509 tours / 561 stops); `test_sim` **140/140** on the combined `main`.
- Archived clean with `-allowProvisioningUpdates` → `/tmp/Atlas-20260705-b71.xcarchive`. Binary-verified: `1.0 (71)`, `UIRequiresFullScreen=true`, mic key, `applesignin`+`associated-domains`, Supabase host (1), gh-pages fallback (2), **no `TEMP_LOCAL_DEMO`**. (Gold hex won't appear in a `strings` grep — colors compile into `Assets.car`, not the Mach-O.) Owner uploading via Organizer.

## Also on main (no build needed)
A stack of **tag spot-check / de-clutter** content PRs (#335–#346) from parallel sessions edited `Tours.json` tags. The catalog is **remote-loaded**, so those reach users automatically — build 71 exists purely for the code above. A `docs/tag-phase2-plan.md` also landed.

## NEXT — the polish list (owner-directed; pick any)
Remaining Tier-2/3 items: **upload-progress** in the tour editor (audio/photo uploads hang the button with no feedback); **empty-states sweep** (consistent copy/voice across follow lists, requests, search-no-results); the **app icon** (still the placeholder green sphere — the next identity step, should be gold-led). Known debts: **Dynamic Type** pinned off on the `body` token (session-17 follow-up); **VoiceOver** pass on the newer authoring/social screens; **multi-stop on-device QA** (AMNH). Bigger picture: field-test the GPS trigger with real walkers.

## Housekeeping
Local clone has ~20 stale `claude/*` branches (old build bumps / content batches, squash-merged so git can't auto-detect them as merged) + a couple genuinely-unfinished content holds (Paris scripts, some London multi-stop, LA image-staging) parked for audio. Remote is clean (no stale merged branches, no open PRs after this session).

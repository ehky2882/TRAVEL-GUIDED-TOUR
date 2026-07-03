# HANDOFF — 2026-07-02 (session 51, code)

## Headline

**V2 Step 4 (maker authoring) is underway.** The owner's key idea reframed the architecture: **the "Me" tab is now a Profile page, and a profile IS a maker page** — one component (`MakerView` with modes), because "each maker should be thought of like a user too." Shipped to `main` as three individually-reviewed increments; a fourth (#304) is in review. Backend needed **no new setup**.

## What shipped (in order)

1. **Increment 1 — Me tab → Profile ([PR #300](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/300), merged `343e605`).**
   - `MakerView` gained `MakerViewMode` — `.publicMaker` (default, unchanged) / `.ownProfile`.
   - `.ownProfile`: **gear** (Settings moved inside the profile), **"+" add-a-tour** (row in list / tile in grid), no `navState.push()` (tab root).
   - New `Features/Profile/ProfileView.swift` (signed-in → own profile; signed-out → sign-in prompt + gear) and `CreateTourPlaceholderView.swift`. `ContentView` Me tab → `ProfileView` (was `SettingsView`).
   - `@Environment(AuthService.self)` made **optional** (public page reachable via the UIKit tour layer, which doesn't inject it — the ReportSheet-crash class of bug).
   - Rebased cleanly onto #297 before merge (non-overlapping hunks in `ContentView`/`MakerView`).

2. **Increment 1.5 — public creator page = its own standalone screen ([PR #302](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/302), merged `5607e70`).**
   - The structural fix: makers were only ever *pushed* onto whatever stack you were in. Now they present via the **same UIKit bottom-layer slide-up as tours**, driven by `MakerPresenter` (the twin of `TourPresenter`), with an **X** close — new mode `.publicStandalone`.
   - First-class entries route through it: **deep link, Search results, Library saved-makers** (were in-stack `NavigationLink` pushes → now `makerPresenter.present`).
   - `ContentView`: new `makerLayer` `BottomLayerController` + an `onChange(of: makerPresenter.presentedMaker)` mirroring the tour block; **removed #297's temporary `.sheet` placeholder**; tab-switch / full-player-open also dismiss a presented maker.
   - **"Go to creator" from a tour/player deliberately stays an in-stack push** (back returns to the tour; avoids stacking a maker layer over a tour layer). This resolves memory `project-maker-standalone-presenter-coordination`.
   - Sim-verified via `dozent://maker?id=…` (host is `maker`, not `m` — that's the https path form): standalone slide-up + X + bookmark/••• + grid (no "+"); tapping a tour inside slides a tour detail over it (present-over-present).

3. **Increment 2a — create/edit your creator profile ([PR #304](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/304), OPEN — owner review).**
   - **The app's first client→Supabase content write.** New `Data/MakerProfileService.swift`: `loadMyMaker()` reads your own `makers` row by `user_id`; `saveProfile()` upserts it (reuses the row id when present so the unique-per-user constraint holds + future tours stay linked; generates one on first create). `MakerRow` DTO maps snake_case.
   - New `Features/Profile/ProfileEditorView.swift` (name/bio/website). An **"Edit Profile"** pill on the own-profile header opens it. `ProfileView` shows `makerProfileService.myMaker` once loaded (else the synthesized placeholder), loaded via `.task(id: userId)`. `MakerProfileService` built in `App.init` (shares `AuthService`), injected into `ContentView`.
   - Backend already applied (`makers_owner_insert/update` RLS + `authenticated` grants) — **no owner Supabase setup**. Sim: pill + prefilled editor render; no-session Save fails gracefully ("You need to be signed in…"). **Live authenticated write is owner-device-verified** (sim can't hold a real session).

- **`test_sim` 140/140** throughout (121 app + 19 deep-link).
- **Also merged from parallel sessions:** **#297** (Universal Link deep-linking for tours + creators + web preview — the share feature; its `DeepLink`/`AtlasShareLink` plumbing is what 1.5 builds on) and **#301** (report emails include the tour title).

## Owner decisions

- **One login = one profile** (start empty; fills as you create tours). The 7 seed studios stay separate public maker pages (their login just isn't attached). Backfilling the owner as their owner was explicitly declined.
- Maker/creator entry point lives on the **Me tab** (no new bottom tab).
- Transcript approach for later increments: **manual text field first**, auto (Apple SFSpeechRecognizer) as a follow-up (raised, not yet built).

## Build / TestFlight

- **`main` is at build 61** (`project.pbxproj`, both app configs; the bump rode in with the share work #297, no separate `chore: bump` commit). **TestFlight latest = 1.0 (61)** per owner.
- **The Step-4 increments (#300/#302, and #304 when merged) may NOT be in the currently-live 61 binary** (archive-vs-merge timing uncertain). To get maker authoring on device, **cut a fresh build after #304 merges** (bump 61 → 62) — short-lived-PR bump pattern + `-allowProvisioningUpdates`, archive from a clean checkout on `main`.

## NEXT

- **Owner:** review PR #304 on device (Me → Edit Profile → save name/bio → persists across devices). Then merge.
- **Increment 2b:** the real create-a-tour form (title/description/category/tags + MapKit pin + draggable radius → a `draft` `tours` row under your maker), replacing `CreateTourPlaceholderView`. Then audio → photos (crop 1200×900) → transcript → submit (`status=in_review`). See `docs/maker-dashboard-design.md` write contract + `backend/storage.sql` (buckets `tour-audio`/`tour-images`, path `{maker_id}/{tour_id}/file`).

## Tribal knowledge (memory)

- `reference-two-repo-clones-build-target` — two repo clones on the Mac (`~/TRAVEL-GUIDED-TOUR` = git/edit; `~/Desktop/TRAVEL GUIDED TOUR` = XcodeBuildMCP default). Point the builder at the clone you're editing (`session_set_defaults projectPath=…`), and use **iPhone 17 Pro / iOS 26.5** (the persisted `iPhone 16 Pro` default no longer exists).
- `project-maker-standalone-presenter-coordination` — RESOLVED by #302 (kept for history).
- Standalone maker deep link for testing: `dozent://maker?id=<uuid>` (custom-scheme host = `maker`; NYC seed maker id = `00000000-0000-0000-0000-000000000001`).

## Cleanup still owed (owner, unchanged)

- Delete throwaway `auth.users` test rows (`claude.authprobe.…`, `dozent.simtest.…`) + the one test `reports` row (`delete from public.reports where details ilike '%test%';`).

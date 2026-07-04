# HANDOFF — 2026-07-04 (session 53, code — device-testing polish + moderation email)

The owner ran the full authoring loop on TestFlight **1.0 (66)** and fed back a stream of comments. **Eight app fixes** shipped in **[PR #326](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/326)** (`23c3e40`) → **TestFlight 1.0 (67)**, plus a **server-side moderation-email rewrite** (`36fbb19`, deployed live via the Supabase dashboard — not in the app build).

## The eight app fixes (build 67)
1. **Public maker page reflects a profile edit immediately.** Own profile = live `makers` row; public page = cached catalog (`get_catalog`, refreshes on relaunch/foreground) → lag. `DataService.applyLocalMaker(_:)` upserts a maker into the in-memory catalog; `ProfileView` mirrors `myMaker` in via `.onChange`. New makers also appear at once (append path).
2. **Review your recording.** `AudioRecordSheet` gains a **Play recording** button (`RecordingReviewPlayer`, an `AVAudioPlayer` wrapper separate from the tour player); stops on re-record/keep/close.
3. **No avatar flash in Library.** `MakerAvatarView` now uses the shared `ImageCache` like `HeroImageView` — `init` pre-populates → a cached photo renders frame-zero; `.task` loads on first miss.
4. **Tighter profile editor + countdowns.** Name cap 24, bio 100 (bounded 3 lines), live "N left" per field (red near the limit), tight label+field grouping.
5. **Tighter New Tour form + countdowns.** Title 60 / short 100 / desc 600, same countdown/grouping.
6. **Settings theme Dark→Light→Dark fix.** A `.sheet` doesn't reliably pick up *changes* to the presenter's `.preferredColorScheme` (first toggle applies, toggle-back sticks). Declared it on `SettingsView` itself, keyed on the same `@AppStorage`. Sim-verified D→L→D returns to dark.
7. **Signed-out page redesign.** Person icon 72→**20pt** (the empty-state/control glyph size — the app's control **diameter is 44pt**: map controls, tour-detail action buttons, search bar all use 44 = HIG min). Sign-in button pinned to 44. "YOUR PROFILE"→**"JOIN DOZENT"** in mono `caption` with sign-up copy.
8. **Shared `JoinDozentPrompt`** (`Features/Auth/JoinDozentPrompt.swift`) — self-hiding when signed in; used on the Me-tab signed-out profile (icon shown) and appended below **all three Library empty states** (icon hidden) to encourage sign-up.

Earlier in the session: builds 64 (polish A+B), 65 (polish C: links + custom avatar), 66 (the **audio-write `order`-column fix** — memory `reference-postgrest-order-column-collision` — + editor/New-Tour polish + avatar crop + discard prompt).

## Moderation email (server-side, LIVE)
`notify-moderation` rewritten (`backend/functions/notify-moderation/index.ts`): a submitted tour now emails a **readable** summary — title, resolved **maker name**, city/category/duration, description, the **transcript**, a **▶ Listen** link, the **photos inline** — with one-click **✓ Approve & publish / Take down** buttons. The GET branch verifies `MODERATION_TOKEN` and PATCHes the tour via the service role (not `publish_tour`, whose `is_admin()` gate returns false under the service role since `auth.uid()` is null). **Owner setup done (hand-held, non-technical):** pasted the code + Deploy, turned **Verify JWT OFF** (a browser click carries no JWT; the token guards the action), added the secret `MODERATION_TOKEN`. Moderation loop now: maker submits → owner emailed → **one click publishes**.

## Verification
`test_sim` **140/140** throughout. Every visual fix sim-verified with the temp `if true` (ProfileView) / `.me`/`.library` default-tab (BottomModuleWindow) hacks — **reverted + grep-clean before every commit/archive**. Writes (profile save, avatar/recording upload, approve-publish) are owner-device-verified (sim holds no session).

## Build 67
Bump #327 (admin-merged, metadata-only). Archived from clean `main` → `/tmp/Atlas-20260704-b67.xcarchive`, `-allowProvisioningUpdates`; binary-verified (`1.0 (67)`, `UIRequiresFullScreen`, mic key, `applesignin`+`associated-domains`, Supabase host, no `TEMP_LOCAL_DEMO`). Owner uploading.

## Git hygiene note
When moving the Edge-Function change to `main` (it deploys separately, not in the app build), I briefly committed an app fix to local `main` by mistake — recovered via `git cherry-pick` onto the branch + `git reset --hard origin/main`. `origin/main` was never wrong. Watch which branch you're on after a `stash/checkout main/stash pop` dance.

## NEXT — batch D (design-first)
The social layer: follow/followers with counts, public vs private accounts, friend requests (auto vs manual accept). Needs a new `follows` table + RLS + owner decisions. Bring a short design before coding.

## Deferred / owed (unchanged)
- Multi-stop authoring (Phase 2; no backend change). Owner cleanup: throwaway `auth.users` test rows; test tour `11111111-…`.

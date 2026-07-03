# HANDOFF — 2026-07-03 (session 51 cont'd, code)

## Headline

**V2 Step 4 — maker authoring — the Phase-1 loop is COMPLETE and LIVE in TestFlight 1.0 (63).** A signed-in user can now do the whole thing, all persisted to Supabase: **set up a creator profile → create a draft tour (metadata + map pin/radius) → open an editor → record or import audio → add photos → write a transcript → Submit for review**. Two small pieces remain to fully close it (submit-email webhook + admin publish).

## What shipped today (continuing session 51 from HANDOFF-260702)

1. **Increment 2b — create-a-tour draft ([PR #307](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/307), `9f398fe`).** The "+" opens a real form (title/desc/category/tags + a MapKit pan-to-place pin + a geofence radius `MapCircle` + slider) writing a `draft` `tours`+`stops` row via new **`Data/MakerTourService.swift`** (`createDraftTour`). Own-profile feed now shows the user's **own tours across all statuses** (`myTours`, direct table select → snake-case `TourRow` DTO) with **DRAFT / IN REVIEW** badges — was the published catalog. `MakerProfileService.ensureMaker()` lazily creates the maker row on first authoring action. New **`Models/TourStatus.swift`**.

2. **Increment 2c — the full tour editor ([PR #310](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/310), `d3af442`).** Tapping an owned tour opens **`Features/Profile/TourAuthoringView.swift`**:
   - **Audio** — record in-app (**`Features/Profile/AudioRecordSheet.swift`**: `AVAudioRecorder` AAC m4a + a main-actor async tick timer; `NSMicrophoneUsageDescription` added to `Info.plist` via PlistBuddy) **or** import a file (`.fileImporter`); uploads to the **`tour-audio`** bucket (`{maker_id}/{tour_id}/file`), patches stop `audio_url`/`audio_duration_seconds` + tour `total_duration_seconds`.
   - **Photos** — `PhotosPicker` (≤5) → aspect-fill **crop to 1200×900 JPEG** (`UIGraphicsImageRenderer`) → **`tour-images`** bucket → patch `hero_image_url` (first = cover) + `additional_image_urls`; thumbnail strip + COVER badge.
   - **Transcript** — field patching `stops.transcript_text`.
   - **Submit for review** — flips `tours.status` draft→`in_review` (enabled only with audio + a cover; saves transcript first).
   - `MakerTourService` methods: `attachAudio` / `attachPhotos` / `stopTranscript` / `setTranscript` / `submitForReview`.
   - Built incrementally as 4 commits on one branch (import → record → photos → transcript+submit); `test_sim` **140/140** throughout. Each step sim-verified with a temp seeded draft (recording drove the real mic-permission prompt with the custom message + a live timer; the PhotosPicker opened with the 5-image limit; Submit enabled only with audio+cover).

3. **Builds: 62 then 63.** **1.0 (62)** (bump #308) shipped the profile + create-a-tour stack; **1.0 (63)** (bump #314) adds the full editor (#310). Both archived from a clean `main` checkout with `-allowProvisioningUpdates`, binary-verified (version, `UIRequiresFullScreen`, mic key, Apple + associated-domains entitlements, Supabase host, no poison string). Both owner-confirmed live.

## The write-verification reality (unchanged, important)

Every Supabase **write** (profile save, draft create, audio/photo upload, transcript, submit) is **owner-device-verified only** — the simulator can't hold a real signed-in session (Google/Apple are device features; email-confirm is on). So the sim work verifies UI + graceful failure; the live round-trips are confirmed on the owner's device. This mirrors all of Step 3 (auth/sync).

## Remaining to fully close Step 4 (both small, next session)

1. **Submit EMAIL** — owner Supabase Database Webhook on **`public.tours` UPDATE** → the existing `notify-moderation` Edge Function (the **twin of the reports webhook** already done in session 50; the function already handles the `in_review` branch). Hand-hold click-by-click (owner is non-technical on Supabase). Submit works without it; the email just won't fire.
2. **Admin Publish** — after review, `publish_tour(<tour_id>)` (or `status`→`published`, `published_at=now()`) in the SQL Editor pushes a submitted tour into the public catalog. Wire a simpler app/admin path later.
3. **Phase 2 — multi-stop authoring** — needs no backend change (`stops.order`/`kind`/`intro_audio_url` already exist). Future.

## Tribal knowledge / notes

- **`reference-two-repo-clones-build-target` (memory)** bit again — XcodeBuildMCP defaults reset to the Desktop clone + `iPhone 16 Pro`; re-point `projectPath` to `~/TRAVEL-GUIDED-TOUR` + `iPhone 17 Pro` at session start.
- Direct-table selects return **snake_case** (need a `CodingKeys` DTO); the `get_catalog` RPC returns **camelCase** (decodes straight into `Tour`). Don't reuse `Tour`'s decoder for a table select.
- Recording works in the **sim** via the host mic — handy for verifying the recorder UI; upload still needs a device session.
- Accidentally committed one increment to local `main` (forgot to branch) → recovered via `git branch <name> <sha>` + `git reset --hard origin/main` + rebase. Watch the branch before committing.
- **Catalog grew in parallel:** Toronto (#306, YYZ) + Kyoto (#309, KYO) — now ~509 tours / 9 makers.

## Cleanup still owed (owner, unchanged)

- Throwaway `auth.users` test rows (`claude.authprobe.…`, `dozent.simtest.…`) + the one test `reports` row.

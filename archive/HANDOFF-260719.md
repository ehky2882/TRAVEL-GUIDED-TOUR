# HANDOFF — 2026-07-19 (session 59)

**Active handoff.** Web session. Two things shipped: (1) an on-demand signed-TestFlight
CI pipeline that lets a web/Linux session build device-testable builds with no Mac, and
(2) **Journeys** — the first feature built + shipped end-to-end that way.

## 1. TestFlight CI pipeline (infra)
- New **`.github/workflows/testflight.yml`** (PR #393): on demand (PR label `build` or
  Actions → Run workflow), a `macos-26` runner archives + signs (cloud signing via an App
  Store Connect API key) + uploads to TestFlight. Runbook: `docs/testflight-ci.md`.
- **Owner one-time setup (done):** 3 GitHub Actions **Secrets** — `APP_STORE_CONNECT_KEY_ID`,
  `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY` (the `.p8` contents) — + a `build`
  label.
- **Gotchas codified:** cloud signing needs the API key at **Admin** role (App Manager →
  *"No profiles for '…' were found"* on export); secrets go in the **Secrets** tab (not
  Variables), named exactly. Build numbers switched to **`github.run_number`**, `MARKETING_VERSION`
  bumped to **1.1** (PR #394) → builds read `1.1 (N)`. **Repo is PUBLIC → Actions is free.**

## 2. Journeys — Phase 1 (code, PR #395 → `main`, squash `9fe6149`)
User-curated, ordered collections of **whole** tours (multi-stop tours never split). Cloud-backed.
- **New files:** `Models/Journey.swift` (`Journey` + `JourneyItem`); `Data/JourneyService.swift`
  (`@MainActor @Observable` Supabase CRUD, mirrors `MakerTourService`); `Features/Journeys/`
  (`JourneysListView` + `JourneyEditorSheet`, `JourneyDetailView`, `AddToJourneySheet`).
- **Wiring:** `JourneyService` built at App init (shares `AuthService`), injected app-wide + into
  **both UIKit slide-up layers** in `ContentView` (they don't inherit the SwiftUI env). Entry
  points: "Journeys" row on `MakerView .ownProfile`; "Add to a Journey" in `TourDetailView`'s
  overflow menu (both optional-env-gated so no non-layer path crashes).
- **Backend:** `backend/journeys.sql` (already in repo) applied to the live Supabase project by the
  owner (hand-held). Tables `journeys` / `journey_items` / `saved_journeys` + RLS + `get_journey`
  RPC. **The app build is independent of the SQL** — first create surfaced *"Could not find the
  table 'public.journeys'"* until the owner ran it, then worked (PostgREST cache auto-reloads).
- **Verified:** TestFlight **1.1 (7)** built + uploaded clean via CI; owner device-tested the full
  loop (create → add → view ordered → play → edit/remove → delete). PR #395 CI green (validator +
  sim build + unit tests); squash-merged.

## 3. Group Listen — Phase 1 (code, PR #396 → `main`, squash `2ba2f58`, TestFlight 1.1 (8))
**Second feature built + shipped from this web session.** Synced group listening — one leader,
followers mirror. Phase 1 = free **"Listen Together"** over **MultipeerConnectivity** (offline).
- **New files (`Features/GroupListen/`):** `GroupPlaybackState.swift` (sync protocol), `GroupTransport.swift`
  (seam), `MultipeerTransport.swift` (offline pipe, join-by-code), `GroupListenCoordinator.swift`
  (`@MainActor @Observable` engine — leader broadcasts, follower reconciles w/ 1.25s drift threshold;
  follower geofence OFF), `GroupListenSheet.swift`, `GroupBanner.swift`.
- **Wiring:** "Listen together" in `TourDetailView` ⋯ menu; coordinator built dependency-free at App
  init, deps wired via `attach(...)` in `.task`, injected app-wide + both UIKit layers + bottom-module
  window. `Info.plist`: `NSLocalNetworkUsageDescription` + `NSBonjourServices` (`_atlas-tour`).
- **Additive** — solo playback/geofence unchanged. **⚠️ Device-only — on-device sync (2+ phones,
  different accounts) is owner-owned, NOT yet verified**; merged anyway (additive, menu-gated).
- **Deferred:** leader-handoff/takeover (v1 shows "Leader left" + Leave), QR join, Hosted mode
  (Supabase Realtime, `backend/group_sessions.sql`), Pro Guide paid tier.

## ⚡ Capability note for ALL sessions — web sessions can now build + ship features
The old "implementation work needs a local Mac session" rule is **retired** (CLAUDE.md § Session
workflow updated). Any web/remote session can write app code, push a branch, trigger
`.github/workflows/testflight.yml` (Actions → Run workflow, or a PR `build` label) for a signed
device build, and merge on owner OK + green `ci.yml`. Proven twice today (Journeys #395, Group
Listen #396). Don't tell the owner a feature must wait for a local session.

## Journeys polish backlog (deferred — `docs/journeys-design.md` §14)
edit-journey-details (v1 is create-only) · drag-reorder · a field to *enter* the per-tour note
(schema stores `note`, detail shows it, no input yet) · cover images · share (`.journey` deep link +
web landing) · discover/save others' public journeys (`saved_journeys` unused) · walking-path map ·
batch offline download. Each ships the same web-session → CI → device → merge way.

## NEXT (owner's call)
Any polish item above, or a different feature. **Group Listen** (`docs/group-listen-design.md`,
`backend/group_sessions.sql`) is the other designed-but-unbuilt feature.

## Housekeeping
- Designated branch `claude/zealous-galileo-86z05a` was restarted from `main` for the Journeys work
  (its old already-merged history was force-replaced with lease). Post-merge it can be left as-is
  (restart from `main` again for the next feature).

# Journeys — design & production handoff

Status: **Phase 1 SHIPPED** (2026-07-19, PR #395 → `main`; TestFlight 1.1 (7), owner
device-verified). Working name **"Journey"** kept. Backend SQL applied to Supabase:
[`../backend/journeys.sql`](../backend/journeys.sql). The rest of this doc is the original
design (2026-07-08); §14 below records exactly what shipped and the polish backlog.

> This is the consumer-curation counterpart to the maker platform; it barely invents new
> infrastructure — it mostly *arranges* pieces already built.

---

## 14. Shipped v1 (Phase 1) + polish backlog (2026-07-19)

**Shipped this session** — built in a *web* session through the new on-demand TestFlight CI
pipeline (first feature to ship that way), owner-tested on device, merged via PR #395:
- **`Models/Journey.swift`** — `Journey` + `JourneyItem` value types.
- **`Data/JourneyService.swift`** — `@MainActor @Observable` Supabase CRUD (load my journeys
  with item counts, list items, membership lookup, create, add/remove tour, delete), mirroring
  `MakerTourService`.
- **`Features/Journeys/`** — `JourneysListView` (list + `JourneyEditorSheet` create form),
  `JourneyDetailView` (ordered tours, tap-to-play, edit-to-remove, delete), `AddToJourneySheet`
  (toggle a tour's membership across journeys, create-and-add).
- **Entry points** — a "Journeys" row on the own-profile (`MakerView .ownProfile`) and an
  "Add to a Journey" item in `TourDetailView`'s overflow menu. `JourneyService` built at App
  init (shares `AuthService`), injected app-wide + into both UIKit slide-up layers.
- **Backend** — `journeys` / `journey_items` / `saved_journeys` tables + RLS + `get_journey`
  RPC applied to the live Supabase project.

**Polish batch SHIPPED 2026-07-20** (PR #410 → `main`, squash `07e6d52`; TestFlight 1.1 (28)) — four items done:
1. ✅ **Edit a Journey's details** after creation (title / description / public) — `JourneyEditorSheet`
   generalized to an `editing:` mode; `JourneyService.updateJourney`.
2. ✅ **Reorder** tours — up/down controls per row in Edit mode; `JourneyService.reorder` writes
   `position`. (Up/down rather than drag; a drag `onMove` is a later nicety.)
3. ✅ **Per-tour curator note** — `JourneyNoteEditorSheet` + `JourneyService.setNote`; "Add/Edit note"
   under each tour in Edit mode.
4. ✅ **Cover image** — auto from the first tour's hero (or `coverImageURL` if set): detail-screen
   banner + list-row thumbnails. `loadMyJourneys` embeds `journey_items(tour_id, position)` →
   `Journey.firstTourId`. (Custom cover *upload* still deferred — auto only.)

**Still deferred** (each a clean follow-up, none blocking):
5. **Share a Journey** — add a `.journey(id)` case to `Data/DeepLink.swift` + a web landing page,
   then a Share action (§7). Dropped from v1 to avoid a dead link.
6. **Discover / save others' Journeys** — public Journeys on the profile; `saved_journeys` +
   a `SavedJourneysStore`; surface in Library (§4, §7). Table exists, unused.
7. **Walking-path map** on the detail screen (§8) — reuse `TourDetailView`'s `MKDirections`.
8. **Batch offline download** of a Journey's tours (§6) — loop `TourDownloader`.
9. **Custom cover upload** + **drag-to-reorder** — nice-to-haves on top of the shipped auto-cover / up-down reorder.

The sections below are the full original design; items above map to §§3–8, 11–12.

---

## 1. What we're building
Let anyone build and share a **Journey**: an ordered, editable collection of *tours* — for
planning a trip and for following it on the ground. Think Spotify playlist, but the
"songs" are tours. You collect tours you like, arrange them (with a walking path when they're
near each other), annotate them, download them for offline, and share.

## 2. The unifying idea it rests on: "Anyone can be a Dozent"
The owner's key reframe (2026-07-08): **there is no "consumer" vs "maker" account** — there's
just an account, and any account can both *listen* and *create*. The maker/consumer split
today is an artifact of the seed phase (the owner is the only uploader right now). This was
already the app's direction (session 51: "the Me tab is a profile, and a profile IS a maker
page; one login = one profile"). Journeys make it concrete: an account now creates **two
kinds of things**, both living on its profile:
- **Tours** — original authored audio experiences (the *building block*; needs review).
- **Journeys** — curated arrangements of tours (the *composition*; publishes instantly).

## 3. Decisions locked with the owner (2026-07-08)
- **Unit = whole tours, always atomic.** A Journey item is a *tour* (single- or multi-stop).
  **A multi-stop tour is never picked apart** — respect the author's intended package. So a
  Journey is simply an ordered list of tour IDs; never stop-level. (Product value *and* clean
  data model agreeing.)
- **Any account can create Journeys** (no consumer/maker distinction).
- **Per-tour curator note** — each item can carry a short note ("do this at golden hour,"
  "grab coffee across the street first"). This is what turns a *list* into *someone's guide*.
- **Living object** — add / remove / reorder anytime, at home *or* mid-walk. No separate
  "edit mode."
- **Offline = batch download** of the member tours (nothing new — just loop the existing
  downloader over the tours; see §6).
- **Publishes instantly + is reportable** (not pre-reviewed like tours — see §7).
- **Name: punted.** Keep "Journey" as the working name.

## 4. Where it lives (information architecture)
Three surfaces — build / reside / saved — plus a detail screen:
- **Build → "Add to a Journey" on every tour.** The Spotify "＋" pattern: you collect as you
  explore. This action lives on the **tour detail, search results, and the map placecard**.
  First add → "Create new Journey." *This is the primary way Journeys get built.*
- **Reside (yours) → your Profile (Me tab).** Alongside your Tours, because your profile *is*
  your creator page. Two shelves: "Tours" and "Journeys." Your **public** Journeys are what
  visitors see on your profile.
- **Saved (others') → Library.** Saving someone else's Journey files it in your Library next
  to saved tours/makers/downloads. (Profile = what you *made*; Library = what you *collected*.
  Owner's lean; revisit if one-stop management in Library is wanted.)
- **Open → a Journey detail screen:** ordered tours with their notes, a map with the walking
  path (§8), and **Play · Download · Share · Save** actions.

## 5. Data model (`backend/journeys.sql`)
Tiny, and it reuses `tours` + `auth.users`.
- **`journeys`** — `id`, `owner_user_id`, `title`, `description`, `cover_image_url` (nullable;
  can default to the first tour's hero), `is_public`, `created_at`, `updated_at`.
- **`journey_items`** — `journey_id`, `tour_id`, `position` (order), `note` (the per-tour
  curator note), `added_at`. PK `(journey_id, tour_id)` — a tour appears once per Journey.
- **`saved_journeys`** — `(user_id, journey_id, saved_at)` — saving someone else's (mirrors
  the existing `user_saved_makers` pattern).
- RLS: a Journey is readable by its owner always, by anyone if `is_public`; writable only by
  its owner; admins can moderate. `get_journey(uuid)` RPC returns the Journey + ordered items
  (tour_ids + notes) in one call for the detail screen / deep link.

**Tour data is NOT duplicated.** A Journey stores only tour *IDs*; the app resolves them
against the already-loaded catalog (`DataService`) — no refetch of tour content.

## 6. Offline — batch download (confirmed: it's just the member tours)
Reuse `Audio/TourDownloader.swift` as-is:
- `download(tour:)` per tour in the Journey (the downloader runs one file at a time — queue
  them); aggregate progress from its `states` / `progress(tourId:)`; total size from
  `diskUsage(tourId:)`.
- `isDownloaded(tourId:)` to show per-tour + overall state; adding a tour later offers to grab
  just that one. `deleteDownload(tourId:)` to free space.
- No new storage concept — a "downloaded Journey" is just "all its tours downloaded."

## 7. Sharing, discovery, saving, moderation
- **Share** reuses the Universal-Link deep-linking from **#297** (`Data/DeepLink.swift`): add a
  `.journey(id)` case + a share action on the detail screen → the same web-preview + open-in-app
  flow tours/creators already have.
- **Discovery**: public Journeys appear on the owner's **Profile**; shared links open them
  directly. (A "Journeys" browse rail on Home is a *later* possibility, not v1.)
- **Save**: `saved_journeys` + a `SavedJourneysStore` mirroring `Data/SavedMakersStore.swift`;
  surfaces in Library.
- **Moderation — an elegant asymmetry, by content type, not account type:** a **Tour** is
  original audio → pre-reviewed (as today). A **Journey** only references *already-vetted*
  tours + the owner's text → **publishes instantly**, and is **reportable** (extend the existing
  `reports` flow to accept a `journey_id`) if a title/description/note is abusive. The risky
  content (audio) was already cleared.

## 8. The walking path (draw it when it makes sense)
- When a Journey's tours are geographically close, draw the connecting **walking route** on the
  detail-screen map — reuse the `MKDirections` approach already in `TourDetailView` — and show
  total distance/time. When they're far apart (a multi-city trip), just **list** them, no path.
- **One flexible object** that adapts (path when near, list when not) — don't split into two
  concepts.

## 9. Integration points (verified against current code)
Almost entirely additive:
- **`Models/Tour.swift`** — the item unit; Journeys store `Tour.id`s, resolve via `DataService`.
- **`Audio/TourDownloader.swift`** — batch offline (§6), used as-is.
- **`Data/DeepLink.swift`** (#297) — add `.journey(id)`; reuse share + web preview.
- **`Data/SavedMakersStore.swift`** — template for a new `SavedJourneysStore`; and
  `LibraryStore`/`LibraryView` for where saved Journeys surface.
- **`Features/Maker/MakerView.swift` + `Features/Profile/ProfileView.swift`** — add a "Journeys"
  shelf next to "Tours"; the profile "+" becomes "＋ Create → Tour or Journey."
- **`Features/Tour/TourDetailView.swift`** — the "＋ Add to a Journey" action (+ it already holds
  the `MKDirections` route-drawing to reuse) ; same action on search rows + map placecard.
- **`Data/AuthService.swift`** — creating/saving requires sign-in (public Journeys are readable
  by anyone, matching public tours).
- **New `Data/JourneyService.swift`** (`@Observable`) — CRUD against the `journeys`/
  `journey_items` tables via PostgREST (the app's first *consumer* content writes beyond the
  maker profile), built at App init like the other services.
- **New `Features/Journeys/`** — `JourneyDetailView`, `JourneyEditor` (reorder/add/remove/note),
  `AddToJourneySheet`, a `JourneyRow`/card.

## 10. Why it's strategically strong
- **Discovery flywheel for makers:** a shared Journey drives plays + exposure to *every* tour's
  maker. Curators (Dozents) feed authors (Dozents). Marketplace loop.
- **Reframes the product** from "browse tours" → "**plan and take trips**" — a stickier,
  repeated, emotional behavior.
- **Compounds** with everything: **Group Listen** a Journey together; **social** (follow →
  see their Journeys); shareable Journeys are a **growth** vector.

## 11. Phased plan (for the local session)
Each phase ends testable.
- **Phase 1 — create, curate, use (solo).** `journeys.sql` applied (owner, hand-held);
  `JourneyService`; "＋ Add to a Journey" on tour detail; profile "Journeys" shelf; the
  `JourneyDetailView` (ordered list + notes + Play-through); reorder/add/remove; per-tour note.
  Acceptance: build a Journey from a few tours, reorder, add notes, play through it.
- **Phase 2 — offline + map path.** Batch download (§6); walking-path map (§8).
- **Phase 3 — share, discover, save.** `.journey` deep link + share; public toggle + profile
  discovery; `saved_journeys` + Library. Extend `reports` to journeys.
- **Phase 4 (later) — makers publish curated Journeys** (same feature; "official" collections),
  Home browse rail, group-listen-a-Journey.

## 12. Open / deferred (decide during build)
- **Name** (punted — keep "Journey" as working name).
- **Library one-stop management** of *your own* Journeys, or Profile-only (owner leans
  Profile-only; Library = saved).
- **Cover image** — auto (first tour's hero) vs custom upload. Auto for v1.
- **Fork/remix** someone's Journey into your own editable copy — nice later, not v1.

## 13. Verification (when built)
- Create a Journey from tours across makers/cities; confirm a multi-stop tour is added whole,
  never split. Reorder / add / remove / note — persists to Supabase, reflects on profile.
- Download the Journey offline (airplane mode) → all member tours play.
- Nearby tours → walking path + distance draws; far-apart tours → clean list, no path.
- Make it public → appears on your profile; share link opens it (in-app + web preview); another
  account saves it → shows in their Library; report a Journey → lands in `reports`.
- Regression: solo tour browse/play/download unchanged.

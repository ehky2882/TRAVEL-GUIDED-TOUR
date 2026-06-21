# Maker dashboard — Phase 1 design (V2 Step 4)

Status: **design + storage SQL** (2026-06-21). Builds on the catalog foundation
([`backend-design.md`](backend-design.md), #218) and the accounts/auth layer
([`accounts-design.md`](accounts-design.md), #220). The storage SQL is
[`../backend/storage.sql`](../backend/storage.sql) (runs after `accounts.sql`). The
SwiftUI authoring UI is later Mac work; this doc nails the **flow, the write contract,
and media storage** so that UI has a fixed target.

## Why
Steps 2–3 made content server-backed and gave makers identity + ownership. Step 4 is the
first surface where an outside maker actually **creates and submits a tour** — the
keystone that flips Atlas from curated app to creator marketplace. Per the spec, Phase 1
is the minimum: **one short audio tour about one location** (single-stop). Multi-stop is
Phase 2.

## Scope
- **In:** the single-piece (single-stop) authoring flow, its data/write contract, media
  storage (audio + up to 5 images), on-device transcription, client + server validation,
  submit-to-moderation.
- **Out (later):** Phase 2 multi-stop (ordering, route preview, intro audio, per-stop
  trigger override), Phase 3 (analytics, version history, drafts/autosave depth, web
  Studio), and the moderation *reviewer* UI (Step 5 — schema already in #220).

## Authoring flow (spec Phase 1)
1. **Sign in** (Apple/email/Google — Step 3) and, first time, **create a maker profile**
   (display name, bio, optional avatar + website → a `makers` row with `user_id = you`).
2. **Audio** — record in-app (`AVAudioRecorder`) or import from Files/Voice Memos.
3. **Transcribe** — on-device `SFSpeechRecognizer` (free, offline, private); maker edits
   the transcript. *(Apple vs Whisper is still an owner open question — default Apple.)*
4. **Location** — MapKit: "use current location" or drop/drag a pin; draggable trigger
   radius circle. Address surfaced to confirm.
5. **Images** — PHPicker, up to 5; in-app landscape crop to **1200×900** (the catalog
   convention); first image is the hero/cover.
6. **Metadata** — title, short + long description, tags (autocomplete from existing
   taxonomy), category, trigger mode (smart default: geofenced outdoor / manual indoor).
7. **Review** — "Listen" plays the tour as a consumer would.
8. **Submit** — tour goes to the moderation queue (`status='in_review'`).

## Media storage (the new piece)
Supabase Storage, two **public** buckets — `tour-audio`, `tour-images`
(`backend/storage.sql`). Path convention **`{maker_id}/{tour_id}/{filename}`**; RLS
authorizes writes by `owns_maker(segment[1])`, so a maker can only write under their own
prefix while anyone can read (served via CDN at
`…/storage/v1/object/public/<bucket>/<path>`). Tour/stop rows store the resulting public
URL — same shape as today's gh-pages URLs, so `HeroImageView` / `AudioPlayerService`
need no change. **The existing Atlas catalog stays on gh-pages** (URLs untouched); only
new maker uploads use these buckets.

Client-side processing before upload (keeps the catalog uniform, no server compute):
- **Audio:** read duration → `stops.audio_duration_seconds` + `tours.total_duration_seconds`.
  Keep a sane codec (m4a/AAC or mp3).
- **Images:** crop/encode to 1200×900 (hero + gallery), ≤5; first = `hero_image_url`,
  rest = `additional_image_urls`.

## Write contract (ordered client → backend ops)
A single-stop submit, each step gated by the Step-3 RLS:
1. `insert makers` (first-time only; `user_id = auth.uid()`).
2. `insert tours` with `status='draft'` (`maker_id` = your maker; `kind='single'`).
   *RLS allows insert only in draft/in_review.*
3. Upload audio → `tour-audio/{maker_id}/{tour_id}/stop1.m4a`; upload images →
   `tour-images/{maker_id}/{tour_id}/hero.webp`, `_2.webp`, … Capture public URLs.
4. `insert stops` (one row; `order=0`, the audio/image URLs, coords, trigger, transcript).
5. Patch `tours` with hero/additional image URLs, durations, centroid (= the stop coord).
6. **Submit:** `update tours set status='in_review'`. Editing later resubmits the same way.
Publishing (`status='published'`) is **admin-only** (Step 5). A maker editing a published
tour resubmits with `status='in_review'` — RLS forbids them setting `published`.

## Validation
- **Client (pre-submit):** title + descriptions non-empty; category + trigger set; a pin
  with coords; audio present (duration > 0); ≥1 image (hero). Block submit otherwise.
- **Server (guaranteed by schema/RLS from #218/#220):** `NOT NULL` on required columns;
  enum-valid category/kind/trigger; maker can't write another maker's tour; maker can't
  self-publish. Mirrors `scripts/validate-tours.swift` invariants.

## App-side work (later, on a Mac — not in this step)
- **supabase-swift** Storage + PostgREST client (the dep introduced in Step 3).
- New `Features/Maker/` authoring screens (audio record/import, map pin + radius,
  PHPicker + crop, transcript editor, metadata form, review/listen, submit) + a
  "My tours" list with status badges (draft / in review / published / taken down).
- `AVAudioRecorder` capture; `SFSpeechRecognizer` transcription; client-side image crop.
- Gated: `test_sim` + simulator review before merge (new `Features/` + `Data/` code).

## Dependencies & sequence
Needs #218 (catalog schema) + #220 (accounts/ownership/RLS). Precedes Step 5 (moderation
reviewer UI) and Phase 2 (multi-stop). The maker-side upload tooling also overlaps ~50%
with the streamlining wins listed under "Pre-cursor tooling" in ROADMAP.

## Verification
- **Storage SQL** applies clean after `accounts.sql` (owner-side on Supabase): buckets
  exist; a signed-in maker can upload under their `{maker_id}/…` prefix but not another
  maker's; objects are publicly readable by URL.
- **End-to-end (Mac):** author a single-stop tour → submit → it appears in
  `moderation_queue` as `in_review`, not in `get_catalog()`; an admin publishes →
  it appears in `get_catalog()` and in the consumer app on next catalog refresh; its
  audio/images load from the Storage URLs.

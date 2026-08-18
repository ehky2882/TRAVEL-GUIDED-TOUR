# HANDOFF — 2026-08-18 (session 94: the tour upload flow got its missing half)

## What happened

**Owner: "i would like to polish my tour upload feature to the point where it's
comparable to what instagram has in terms for features and ease of use."**

Shaped by an HTML mockup reviewed on device (the session-77b pattern), built in
three increments, shipped in **TestFlight 1.1 (62)**, merged as
[PR #515](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/515) — 9 files, all
Swift, authoring only.

The session did **not** start there and spent most of its length elsewhere: the
owner asked where to find the paid tour, which unspooled into verifying paid
tours Phase 3 end to end, pricing 66 walks, a pre-merge code review that found a
paywall bypass, merging #469, and a documentation resync. All of that is written
up under its own Current State entries. **Worth noting because it recurred:** the
owner twice had to ask why the thing they originally requested had not been
built. When a session diverges that far, say so unprompted.

## 🐛 The find that mattered: `MakerTour` carries NO stops

`TourRow.asMakerTour` builds its `Tour` with `stops: []` — the profile feed only
needs title, status and images. So a details editor reading `tour.stops.first`
gets nil and falls back to a 30 m default.

**Saving that would have quietly reset the geofence radius of every tour anyone
edited the title of.** No error, no warning, no dead link — the tour would simply
stop firing where it used to, which is the same failure class as the Cape Town
coordinate that was 423 m off.

Fixed with `stopLocation(tourId:)`, and the change-detection baseline moves with
the loaded values so the form does not open claiming an edit nobody made.

**The same gap explains why playback was impossible**: the editor knew a tour
*had* audio (from its duration) without knowing where it was. Hence
`stopAudioURL(tourId:)`.

**Durable: anything reading `tour.stops` off a `MakerTour` is reading an empty
array.** It is not a bug in `MakerTour` — the feed does not need stops — but any
new authoring surface must fetch what it needs.

## Why audio bypasses the Supabase SDK

`supabase-swift` 2.48's `storage.upload` returns only on completion and
**exposes no progress callback**. Fine for a 200 KB photo; wrong for narration,
the largest thing this app sends — an indeterminate spinner cannot distinguish
"nearly there" from "stalled".

`StorageUploader` hits the same REST endpoint over a plain `URLSession` so
`URLSessionTaskDelegate.didSendBodyData` can report real byte counts. Photos stay
on the SDK: they are small, and "3 of 5" is the honest unit for a batch.

**It is NOT a background session.** Uploads survive moving around inside the app,
not the app being killed. Stated in the type's own doc comment so nobody assumes
otherwise.

## Deliberate architecture calls, recorded so they are not "tidied"

- **`AuthoringAudioPreview` is not `AudioPlayerService`.** That is the app's
  single tour player and owns the mini-player, lock screen, now-playing info and
  the geofence hand-off. Auditioning a half-finished draft must not put it on the
  lock screen. It is also **not `AVAudioPlayer`**, which cannot stream a remote
  URL — attached audio is an https URL on Storage.
- **`setPhotos` replaces, it does not append.** Reordering and removal both need
  to express "this exact list, in this exact order", which an append-only API
  cannot say. Dropped files are deleted from Storage; `storagePath(from:bucket:)`
  **returns nil rather than guessing**, because a plausible wrong path could
  delete the wrong object.
- **Position one IS the cover**, rather than a separate "set as cover" action.
- **`AuthoringErrorText` does not guess.** An unrecognised failure is reported as
  unrecognised. Inventing a plausible cause is worse than admitting ignorance,
  because the maker will act on it.

## Owner decisions (2026-08-17)

| Question | Decision |
|---|---|
| Editing a published tour | **Allowed, and it re-enters review.** Drafts/in-review keep status. The sheet says so *before* Save. |
| Photo cap | **8** |
| Crop step | **Always shown, with a Skip** |

## Process notes

- **`get_status` on a PR is useless in this repo** — legacy commit statuses only,
  so it returns `pending` / `total_count: 0` forever regardless of Actions. Use
  `get_check_runs`. **But 0 check runs can also mean the PR is conflicted**, so
  check `mergeable_state` (`dirty` = conflict, `unstable` = checks in flight)
  before concluding CI simply has not run. That ambiguity cost a wrong read.
- **Direct `api.github.com` calls are proxy-blocked** (403 "GitHub access is not
  enabled for this session"). Use the MCP tools; do not build bash pollers.
- `git diff --stat A B | tail` sorts `web/` last alphabetically — reading only
  the tail once hid every Swift file and suggested a PR was all website.
- Three CI runs, one per increment, plus a fourth on the PR against a base that
  had moved. Worth the wait: `main` took a screenshots PR mid-build.

## Owed / next

1. **Device-verify the radius fix** — edit only a tour's title, confirm the
   trigger radius survived. The bug was silent; so is a bad fix.
2. **Drag-to-reorder feel** — it compiles; whether the drop targets land where a
   thumb expects is unverified.
3. **True background upload** (survives the app being killed) and **draft
   autosave on the create form** — both deliberately scoped out, not forgotten.
4. Still open from the paid-tours work: **`PurchaseOutcome.alreadyOwned` is
   unwired**, and **Group Listen is withheld on all 66 paid walks** — a product
   call the owner has not made.

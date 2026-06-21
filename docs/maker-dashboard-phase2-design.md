# Maker dashboard — Phase 2 design: multi-stop authoring (V2 Step 4 cont.)

Status: **design** (2026-06-21). Continues
[`maker-dashboard-design.md`](maker-dashboard-design.md) (Phase 1, single-stop). Phase 2
is the platform's distinctive product: a **walking route with several stops**, each with
its own audio that auto-triggers as the consumer reaches it. Today only 2 of 307 catalog
tours are multi-stop (AMNH Four Facades, Fifth Avenue Walk).

**No backend change.** The foundation already supports this — `stops` is its own table
with an `order` column + `unique (tour_id, "order")`, `tours.kind='multiStop'`,
`tours.intro_audio_url`, and `tours.walking_distance_meters` all exist (#218). Media
storage (#222) and ownership/RLS (#220) are unchanged. Phase 2 is therefore **almost
entirely app-authoring UX** — this doc fixes that flow. (A nice validation that the
foundation schema was designed right.)

## Scope
- **In:** the multi-stop authoring experience and how it maps onto the existing
  write contract — repeatable stop capture, reordering, route preview, intro audio,
  per-stop trigger override, route validation.
- **Out:** Phase 3 (analytics, version history, autosave depth, web Studio), the
  moderation reviewer UI (Step 5).

## What it adds over Phase 1
Phase 1 captures one stop. Phase 2 is "do that cheaply, N times, then arrange + connect
them." The new authoring pieces (spec "Phase 2 — multi-stop"):

1. **Repeatable stop capture.** The same per-stop record/import → transcribe → pin +
   radius → photos → metadata flow as Phase 1, presented as a list of **collapsible stop
   cards** you add to. Each card = one `stops` row.
2. **Drag-to-reorder.** Makers don't record in walking order (you might capture stop 4
   first because you passed it). Reordering sets each card's position → the `"order"`
   column. The unique `(tour_id, "order")` constraint means reorder writes must be applied
   as a set (renumber 0..n) — see write contract.
3. **Route preview.** Once stops are placed, draw the connecting walking path with
   `MKDirections` (walking mode). Surface **total walking distance + ETA**. Flag any leg
   **>500m** with no transit hint as a likely error. Distance → `walking_distance_meters`.
4. **Intro audio (optional).** A "welcome, here's why I picked these five blocks" clip
   before stop 1 → uploaded like any stop audio → `tours.intro_audio_url`.
5. **Per-stop trigger override.** The tour sets a default (geofenced outdoor / manual
   indoor); a single stop (e.g. a quiet church) can flip to manual → that stop's
   `trigger_mode`.
6. **Route validation** (pre-submit, client): stops in walking order; no orphan stops
   (every stop has coords + audio); no oversized gaps (>500m) without justification; no
   two stops within each other's trigger radius (would double-fire); ≥2 stops (else it's
   a single-stop tour, `kind='single'`).

## Write contract (delta from Phase 1)
Same ordered create→upload→submit as Phase 1, with these differences:
- `tours.kind = 'multiStop'`.
- **Stops are a set, not one row.** Insert one `stops` row per card. On reorder, renumber
  and update all affected rows' `"order"` in a single transaction (or write to a temporary
  high offset then back down) to respect `unique (tour_id, "order")`.
- Compute `tours.total_duration_seconds` = Σ stop durations (+ intro if present);
  `tours.walking_distance_meters` from the `MKDirections` route; `centroid_*` from the
  stop coordinates (e.g. their mean) rather than a single pin.
- Optional intro audio uploaded to `tour-audio/{maker_id}/{tour_id}/intro.m4a` →
  `intro_audio_url`.
- Submit + moderation + publish are identical to Phase 1 (publish stays admin-only).

## App-side work (later, on a Mac — not in this step)
Extends `Features/Maker/` from Phase 1:
- A **stop-list editor** (collapsible cards, add-stop, drag-to-reorder).
- **Map route preview** — `MKDirections` walking polyline overlay + distance/ETA readout
  + the >500m gap warning.
- **Intro-audio** capture slot; **per-stop trigger** control on each card.
- The route **validation** pass before enabling Submit.
- Reuses every Phase-1 capture component (audio, pin+radius, PHPicker+crop, transcript,
  metadata) per stop.
- Gated: `test_sim` + simulator review before merge.

This is also where the consumer-side multi-stop *playback* (already shipped — the
`ProximityMonitor` geofence engine + AMNH/Fifth-Ave tours) gets its first
maker-authored content to drive it end-to-end.

## Dependencies & sequence
Needs Phase 1 (the per-stop capture components) + #218/#220/#222. No new backend. Precedes
nothing hard — Phase 3 tooling and Step 5 moderation UI are independent follow-ons.

## Verification
- **No SQL to apply** — confirm `kind='multiStop'`, `stops.order`, `intro_audio_url`,
  `walking_distance_meters` already exist (they do, from #218).
- **End-to-end (Mac):** author a ≥2-stop tour → reorder stops → route preview shows a
  sane distance/ETA and flags an injected far stop → submit → admin publishes → the tour
  plays in the consumer app with each stop's audio auto-triggering in order via the
  existing `ProximityMonitor`.

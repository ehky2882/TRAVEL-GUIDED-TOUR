# Tag migration — implementation & rollout plan

**Status:** proposed / awaiting owner go-ahead (2026-07-01). Companion to
`docs/tag-taxonomy-v2.md`. **This is a plan. Nothing here ships until the owner
approves it.** It touches live, Supabase-backed content, so it is scoped to roll
out incrementally.

---

## 1 · The tour → tags mapping plan (how 469 tours get retagged)

**First pass is automated.** `scripts/seed_tags.py` (refreshed for 469 tours /
7 makers) assigns a faceted tag set to every tour from: title → old
`primaryCategory` → curated existing `tags` → short/long descriptions. Output:
`docs/tag-migration-review.md` (per-tour proposal + coverage). Average **6.4
tags/tour**; every tour gets ≥1 Place type and ≥1 Theme (the required minimum).

**Reliability of the auto-pass (what to trust, what to fix):**

| Facet | Auto-pass quality | Human effort |
|---|---|---|
| Place type | Good from title + description; **85 tours still resolve to `Notable Building` only** (was 162 before the description scan) | **Medium** — the main review cost; the 85 are flagged ⚠️ and sorted to the top of each city section |
| Theme | Lead theme reliable; secondary themes over-fire on keywords | Medium — prune false positives |
| Style & era | Reliable when the era is named | Low |
| Architect | Reliable names, but a *mention* ≠ the subject | Medium — confirm the tour is actually *about* that architect |
| Experience | `Iconic Landmark` / `Free to Visit` / `After Dark` are **editorial, seed = 0** | Medium — hand-author the 3 editorial tags |

**Review workflow (owner chose spot-check-by-city, D10):** seed → owner skims
`docs/tag-migration-review.md` **one city at a time** (the review is now grouped
per maker: NYC 100 · LDN 99 · LIS 66 · OPO 54 · HKG 52 · SFO 35 · TYO 63, each
with its ⚠️ flag count and the flagged tours sorted to the top) → fix the
obvious misses → apply approved tags to `Tours.json` → validate → ship.
**Effort estimate:** only **85 tours** carry a place-type ⚠️ flag and the 3
editorial Experience tags (`Iconic Landmark` / `Free to Visit` / `After Dark`)
are hand-authored; a spot-check pass is realistically **~3–5 focused hours**
(a full eyeball-every-tour pass would be ~8–14h). Best done city by city — each
maker is internally consistent — or assisted by a second LLM pass over full
transcripts.

---

## 2 · Engineering change list

### 2a · Data model (app — `TRAVEL GUIDED TOUR/`)
- **`Models/Tour.swift`** — `primaryCategory: TourCategory` → **removed** (or
  deprecated during transition, see rollout). `tags: [String]` becomes the
  source of truth. Decide the on-wire shape (**D4**):
  - **Flat** `tags: [String]` — every tag is a bare string; facet inferred from a
    lookup table. Zero schema change (column already `text[]`). Simplest.
  - **Faceted** `tags: [Tag]` where `Tag = {value, facet}`, or a
    `TagSet {placeTypes, themes, styles, experiences, architect}` struct — richer,
    but changes the JSON contract and the Supabase shape.
  - *Recommendation:* **flat `[String]` on the wire + a `Tag` value type with a
    `facet` computed from a bundled vocabulary map in the app.** Keeps the
    `text[]` column and `get_catalog` output untouched; the app derives facets.
- **`Models/TourCategory.swift`** — **delete** the enum at the flip (or keep a
  thin `deriveCategory(from: tags)` helper if the map/rails still want one
  primary — see **D5**).
- **New `Models/Tag.swift`** — the closed vocabulary as a Swift value type: the
  `VOCAB` map (facet → tags), `facet(for:)`, validation, display order. Single
  source of truth mirrored by the validators.

### 2b · Category consumers to migrate (~15 files)
Every `primaryCategory` / `TourCategory` reference (grep-verified):

| File | Today | After |
|---|---|---|
| `Features/Home/HomeRailsViewModel.swift` | one rail per `TourCategory.allCases`, `tour.primaryCategory == category` | rails built from a **curated tag list** (or popularity) — `tour.tags.contains(tag)` |
| `Features/Home/CategoryChipRow.swift` | single-select `TourCategory?` chips | **multi-select tag chips** (faceted sections or a flat curated set) — visuals change, **pair with design** |
| `Features/Home/HomeView.swift` | `availableCategories: TourCategory.allCases`, `selectedCategory` filter | selected **tag set**; filter is `tour.tags ⊇ selection` (AND/OR — **D6**) |
| `Features/Home/HomeSharedState.swift`, `HomeDrawerContent.swift`, `RailCarousel.swift`, `PlacecardView.swift`, `TourListCard.swift` | read `primaryCategory` for display/icon | read a derived primary tag or a themed chip |
| `Features/Search/SearchView.swift` (2 sites) | `tour.primaryCategory` as facet/keyword | search over `tags`; tags become search tokens |
| `Features/Maker/MakerView.swift` (2 sites) | sort/group by `primaryCategory` | sort/group by a chosen facet (Theme) or tag |
| `Features/Tour/TourDetailView.swift`, `Player/PlayerView.swift`, `Components/HeroImageView.swift`, `Features/Settings/ManageDownloadsView.swift`, `Features/Library/LibraryView.swift` | category label/icon | tag chips / derived label |
| `Data/DataService.swift` | decodes/holds category | holds tags; expose tag-index helpers |

### 2c · Backend (Supabase — project "Dozent")
The **`tours.tags text[]` column already exists** (`backend/schema.sql:79`) — this
is the key de-risker. The `primary_category` enum + `not null` are the only hard
constraints to unwind.
- **`schema.sql`** — at the flip: drop the `not null` on `primary_category`
  (Phase 2) then drop the column + `tour_category` enum + `idx_tours_category`
  (Phase 3). Optionally add a GIN index on `tags` for filter queries.
- **`get_catalog()` RPC** — emits `primaryCategory` + `tags` today
  (`schema.sql:184–185`). Keep both during transition; drop `primaryCategory`
  from the JSON at the flip. **This is the one change every app version sees**,
  so it gates on old builds no longer requiring the field.
- **`seed_from_toursjson.py`** — validates `primaryCategory ∈ CATEGORIES` and
  upserts both columns. Update to validate `tags ⊆ VOCAB` (≥1 Place type + ≥1
  Theme) and stop requiring `primaryCategory`.
- **RLS** — unaffected (public-read stays; no policy references category).
- All SQL delivered as **copy-paste-ready blocks for the SQL Editor** (owner is
  non-technical on infra — per CLAUDE.md § Session workflow).

### 2d · Validation & tests
- **`scripts/validate-tours.swift`** — replace the embedded `TourCategory` enum
  + `primaryCategory` field check with: every tag ∈ vocabulary; ≥1 Place type
  and ≥1 Theme per tour; `Designed by a Master` ⇔ Architect present. Mirror the
  Python validator in the seed workflow.
- **Tests** — anything asserting `primaryCategory` or per-category rails
  (`HomeRailsViewModel` tests especially) moves to tag-based assertions. Run
  `test_sim` on **iOS 26.5** (26.3 crashes the @Observable store tests — memory
  `reference-ios263-sim-test-crash`).

### 2e · UX (pair with a design pass)
- **Rails.** Today = one rail per category. After = rails from a **curated tag
  set** (the taxonomy leaned curated over popularity — editorial control, stable
  ordering). e.g. themed rails ("Sacred spaces", "Designed by a master",
  "Hidden gems") mapping to specific tags. **D7:** curated vs popularity-driven.
- **Filter chips.** Single-select → **multi-select**. **D8:** flat curated chip
  row (simplest, closest to today's visuals) vs a faceted filter sheet (sections
  per facet — richer, bigger design lift). Chip-row visuals change either way —
  **this is the design-review surface** (per the AllTrails chip styling in
  `CategoryChipRow`).
- **Multi-select semantics.** **D6:** within a facet OR, across facets AND
  (standard faceted-search behavior), or global OR. Affects result counts.

---

## 2.5 · Owner decisions (locked 2026-07-02)

| # | Decision | Choice |
|---|---|---|
| D1 | `Shop & Flagship` place type | **Fold** into `Notable Building` + `Fashion & Retail` theme |
| D2 | Thin style tags (`Metabolist`, `Mission / Spanish Revival`) | **Drop** |
| D3 | Split `Temple & Shrine` | **No** — keep one `Religious Building` for now |
| D4 | Tag storage shape | **Flat `[String]` + app-side facet map** (no schema change) |
| D5 | Keep a lightweight primary? | **Yes — derive one primary tag** (map pin + one-label spots stay untouched) |
| D6 | Multi-select semantics | **OR-within-facet, AND-across-facet** (standard) |
| D7 | Rails: curated vs popularity | **Deferred** — decide during Phase 2 UI (not needed until then) |
| D8 | Filter UI | **Simple multi-select chip row** (upgrade to a faceted sheet later if wanted) |
| D9 | Rollout | **Incremental 3-phase** |
| D10 | Retag review depth | **Spot-check by city** (auto-seed first pass, owner skims per city) |
| D11 | Free-form tags | **Discard**; optionally salvage neighbourhood names as a separate location layer later |

Only **D7 (home rails: curated vs popularity)** is still open, and it isn't
needed until the Phase 2 UI build. The § 4 menu below is retained for context.

---

## 3 · Rollout — incremental, to de-risk live content

Content is live and Supabase-backed, so **big-bang is avoidable**. Proposed
three-phase flip (**D9**: incremental vs big-bang):

- **Phase 1 — tags alongside categories (additive, no user-visible change).**
  Land the normalized `tags` on all 469 tours (column already exists), keep
  `primaryCategory`. App still reads categories. Auto-seed + validator learn the
  vocabulary. *Fully reversible; nothing user-facing.* **Tooling is built and
  dry-run-verified** — `scripts/apply_tags.py` (safe by default; `--write` to
  apply) turns 2,006 free-form tags into the 85-tag controlled set. Step-by-step
  runbook + copy-paste kickoff prompt in `docs/tag-phase1-kickoff.md`.
- **Phase 2 — flip the UI to tags (app build).** Rails + chips derive from tags;
  `primaryCategory` still emitted by the RPC for older builds but unused by the
  new build. Ship as a normal TestFlight build. *Old builds keep working off the
  still-present category field.*
- **Phase 3 — drop the category (cleanup).** Once the tag-based build is the
  floor, remove `primaryCategory` from `Tour`, the enum, the RPC JSON, the DB
  column + index, and the validators.

This maps onto the existing content-ships-without-a-build pipeline (Phase 1 is a
`Tours.json` content change → auto-seed → live) and the short-lived-PR build
pattern (Phase 2/3).

**Rough effort:** Phase 1 content/tooling ≈ the 8–14h retag + ~1 day tooling;
Phase 2 app+design ≈ **3–5 days** (model + ~15 files + multi-select filter +
design pass + tests); Phase 3 cleanup ≈ ~1 day. Backend SQL is small at each
phase.

---

## 4 · Open decisions for the owner

The important part — these drive whether/how we build it.

- **D1 · `Shop & Flagship` place type?** Add it, or fold flagships into
  `Notable Building` + the `Fashion & Retail` theme? *(Recommend: fold unless
  Tokyo/Ginza retail becomes a named rail.)*
- **D2 · Thin new style tags.** Keep `Metabolist` (maybe 0 in catalog) and
  `Mission / Spanish Revival` (1) for completeness, or drop/merge?
- **D3 · Split `Religious Building` → `Temple & Shrine`?** For the 41 East-Asian
  temples/shrines.
- **D4 · Tag storage shape.** Flat `[String]` + app-side facet map *(recommended,
  zero schema change)* vs faceted struct on the wire.
- **D5 · Keep a lightweight primary "category"?** Pure-tags, or derive one
  primary tag for the map pin / a compact label / a fallback rail? *(A derived
  primary avoids touching the map layer.)*
- **D6 · Multi-select semantics.** OR-within-facet / AND-across-facet
  (recommended) vs global OR.
- **D7 · Rails: curated vs popularity-driven.** *(Taxonomy leaned curated.)*
- **D8 · Filter UI: flat curated chip row vs faceted filter sheet.** How many
  facets to expose as filters vs keep as metadata (e.g. Architect + Style as
  metadata only)?
- **D9 · Rollout: incremental 3-phase (recommended) vs big-bang.**
- **D10 · Manual re-tag review depth.** Full 469-tour human review, spot-check
  by city, or trust the seed for Place/Style/Architect and only hand-author
  Theme + the editorial Experience tags?
- **D11 · Free-form tags.** Discard the 2,006 unnormalized tags entirely, or
  salvage a curated few (e.g. neighbourhood tags like `alfama`, `shibuya`) as a
  separate, non-facet "location" layer?

---

## 5 · What does NOT change
- Stops, audio, images, pricing, maker ownership, RLS, auth/sync, the
  content-ships-without-a-build pipeline, and the offline bundled-seed fallback.
- The prior branch `claude/dreamy-wozniak-tags-260612` is preserved (not merged,
  not deleted) — this plan builds on its thinking.

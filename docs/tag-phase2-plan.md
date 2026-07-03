# Tag migration — Phase 2 plan (the visible switch)

**Status:** proposed / awaiting owner go-ahead (2026-07-03). Phase 1 is **live**
(all 509 tours carry the controlled 85-tag vocabulary; nothing user-facing
changed — verified on the Supabase RPC). Phase 2 is where users finally *see*
the benefit. It's an **app-code change → needs a TestFlight build + a
turn-by-turn simulator review** (unlike Phase 1, which shipped over-the-air).

Read first: `docs/tag-taxonomy-v2.md` (the vocabulary), `docs/tag-migration-plan.md`
(the full plan + locked decisions), `docs/tag-phase1-kickoff.md` (what already
shipped). This is an implementation plan for a **fresh session** (per the
web-vs-implementation split in CLAUDE.md).

---

## 1 · What Phase 2 delivers (plain)

Two visible changes on the Home screen, plus one invisible safety piece:

1. **Curated browsing shelves.** Today the drawer shows one shelf per old
   category, in enum order. After: a **hand-picked, ordered set of tag shelves**
   (owner decision D7 — editorial, not popularity-driven), e.g. "Hidden gems",
   "Designed by a master", "Sacred spaces". The personalized + location shelves
   (Continue listening · Recently viewed · Near you · In view) stay on top,
   unchanged.
2. **Multi-select filter chips.** Today the chip row **jump-scrolls** to a shelf
   and is single-select. After: chips **filter** and you can pick **several**
   (owner decision D8 — a simple multi-select chip row, not a faceted sheet).
   Tap "Food" + "Hidden Gem" → the list narrows to tours that are both.
3. **A derived "primary" label (invisible).** Owner decision D5: keep one primary
   tag per tour, computed automatically from its tags, so the **map pins and any
   one-label spots keep working untouched** — no map-layer rewrite.

---

## 2 · Owner decisions (locked)

| # | Decision | Choice |
|---|---|---|
| D5 | Keep a lightweight primary | **Yes — derive one primary tag** per tour |
| D6 | Multi-select filter logic | **OR within a facet, AND across facets** (standard) |
| D7 | Browsing shelves | **Hand-picked / editorial** (curated list below) |
| D8 | Filter UI | **Simple multi-select chip row** (upgrade to a faceted sheet later if ever wanted) |
| — | Maker "create a tour" form | **Deferred to a fast-follow** — do the consumer/browsing side first (that form is still mid-construction) |

---

## 3 · Proposed curated shelf set (editorial — owner tweaks freely)

A starting list of hand-picked shelves, in order, each mapping to one tag. The
owner reorders / adds / drops; this is the editorial control D7 buys. Empty
shelves auto-hide (e.g. a city with no tours of that tag).

| Shelf title | Tag it draws from |
|---|---|
| Iconic landmarks | `Iconic Landmark` *(editorial tag)* |
| Hidden gems | `Hidden Gem` |
| Designed by a master | `Designed by a Master` |
| Sacred spaces | `Faith & Spirituality` |
| Art & museums | `Art` |
| Food & drink | `Food & Drink` |
| Green escapes | `Green Escape` |
| Viewpoints | `Viewpoint & Panorama` |
| Architecture & design | `Architecture & Design` |
| A sense of history | `History` |
| By the water | `Maritime` |
| Fashion & retail | `Fashion & Retail` |

The chip row shows the **same curated tags** (so tapping a chip filters to that
shelf's tag, and multiple chips combine per D6). Whether the chip row exposes a
few more filters than there are shelves is a small design-pass call.

---

## 4 · Engineering change list (grounded in the app as of 2026-07-03)

### 4a · New model
- **`Models/Tag.swift`** (new) — the controlled vocabulary as a Swift value type:
  the facet→tags map, `facet(for:)`, display order, and the **`derivePrimary(from:
  [String]) -> primary tag`** rule for D5. Single source of truth; mirrors
  `scripts/seed_tags.py`'s `VOCAB` and the validators.
- **`Models/Tour.swift`** — `tags: [String]` already holds the controlled set
  (Phase 1). Add a computed `primaryTag` (via `Tag.derivePrimary`). **Keep
  `primaryCategory` for now** (older TestFlight builds still read it; drop it in
  Phase 3).

### 4b · Consumer surfaces to migrate (Home + browse + detail)
| File | Today | After |
|---|---|---|
| `Features/Home/HomeRailsViewModel.swift` | one shelf per `TourCategory.allCases` | shelves from the **curated tag list** (`tours.filter { $0.tags.contains(tag) }`) |
| `Features/Home/CategoryChipRow.swift` | single-select, jump-scroll | **multi-select filter chips** (curated tags) |
| `Features/Home/HomeDrawerContent.swift` | `jumpToCategory` scroll on `selectedCategory` | filter the shelf list by the selected tag set (D6) |
| `Features/Home/HomeView.swift` | `availableCategories`, `selectedCategory` filter | selected **tag set**; `displayedTours` filters `tags ⊇ selection` |
| `Features/Home/HomeSharedState.swift` | `selectedCategory: TourCategory?` | `selectedTags: Set<String>` |
| `Features/Home/TourListCard.swift`, `RailCarousel.swift`, `PlacecardView.swift` | read `primaryCategory` for a label/icon | read `primaryTag` (derived) |
| `Features/Search/SearchView.swift` | search index includes `primaryCategory.displayName` | index includes the tags + derived primary (tags already normalized) |
| `Features/Tour/TourDetailView.swift`, `Player/PlayerView.swift` | category label | tag chips / derived label |
| `Features/Library/LibraryView.swift`, `Settings/ManageDownloadsView.swift`, `Components/HeroImageView.swift`, `Features/Maker/MakerView.swift` | category label/icon/sort | derived primary / tag-based |
| `Data/DataService.swift` | holds category | expose a tag index helper for fast filtering |

### 4c · Explicitly DEFERRED (maker side — fast-follow, not Phase 2)
Per the owner's scope choice, leave these on the old category picker for now:
`Features/Profile/CreateTourView.swift` (category picker + free-text tags),
`Features/Profile/TourAuthoringView.swift`, `Data/MakerTourService.swift`. A
follow-up swaps the maker form to pick controlled tags (Place type + Theme
required) once that authoring flow settles.

### 4d · Validation & tests
- **`scripts/validate-tours.swift`** — add: every tag ∈ vocabulary; ≥1 Place type
  + ≥1 Theme per tour; `Designed by a Master` ⇔ an Architect tag. (Still passes
  today; this makes it enforce the vocabulary going forward.)
- **Tests** — `HomeRailsViewModel` tests move from per-category to per-curated-tag
  assertions; add `Tag.derivePrimary` unit tests; filter-logic (D6) tests. Run
  `test_sim` on **iOS 26.5** (26.3 crashes the store tests — memory
  `reference-ios263-sim-test-crash`).

### 4e · Backend
- **No schema change needed for Phase 2.** The RPC already emits `tags`; the app
  reads them. `primaryCategory` stays in the RPC output for old builds. (Dropping
  the column/enum is Phase 3.)

---

## 5 · Rollout & how the sim review goes

- Build against an isolated clone (memory `reference-two-repo-clones-build-target`).
- **This is a turn-by-turn simulator session with the owner** — the shelves +
  chip visuals are the review surface. Expect a few rounds (shelf order, chip
  look, filter feel), same as past Home-polish sessions.
- Ship as a normal TestFlight build (bump via the short-lived-PR pattern +
  `-allowProvisioningUpdates`). Old builds keep working off `primaryCategory`
  (still present).
- **Before the build:** the city-by-city tag **spot-check** (D10) is worth doing
  first, since the tags now become visible — see `docs/tag-migration-review.md`
  (flagged tours sorted to the top per city; ~3–5 hrs).

**Rough effort:** spot-check ~3–5 hrs · app build (Tag model + ~12 consumer files
+ multi-select filter + curated shelves + derived primary + tests) ≈ **3–4 days**
incl. the sim-review iterations · design pass on chip visuals folded in.

---

## 6 · What does NOT change in Phase 2
Map pins (fed by the derived primary), stops, audio, images, pricing, the maker
create-a-tour form (deferred), auth/sync, the offline seed, and `primaryCategory`
(kept until Phase 3 cleanup).

---

## 7 · Copy-paste kickoff prompt for the fresh implementation session

> Implement Phase 2 of the tag migration (M-rethink-categories). Phase 1 is live
> (all 509 tours carry the controlled tags). Plan: `docs/tag-phase2-plan.md`
> (decisions locked); vocabulary: `docs/tag-taxonomy-v2.md`. Build: a `Models/Tag.swift`
> vocabulary + `derivePrimary`; convert Home shelves to the curated tag list
> (§3), the chip row to multi-select filters (OR-within/AND-across, D6), and all
> category-reading consumers (§4b) to the derived primary; keep `primaryCategory`
> for old builds; leave the maker create-a-tour form on the old picker (deferred).
> Update `validate-tours.swift` + tests; `test_sim` on iOS 26.5. This is a
> turn-by-turn simulator review with the owner — start by showing the new Home
> shelves + filter chips, then iterate on shelf order and chip visuals. Do the
> city-by-city spot-check of `docs/tag-migration-review.md` first if the owner
> wants the visible tags cleaned before the build.

## 8 · Open item for the owner
- **Confirm / edit the curated shelf list (§3)** — order and which tags become
  shelves. This is the editorial control you chose; the list above is just a
  sensible starting point.

# Atlas tag taxonomy

**Status:** proposed (2026-06-12). Replaces the single `primaryCategory` enum with a
controlled, multi-select tag vocabulary. Owner decisions baked in: **tags-only**
(drop `primaryCategory`), **Architect is its own facet**.

## Why

Every tour currently carries exactly one of 10 categories, but the catalog is
lopsided (`architecture` 70 / `history` 47 / `culturalHeritage` 46 of 243 — and
`culturalHeritage` has become a meaningless catch-all) and the tours genuinely
span dimensions (Borough Market = *food + 1,000-year history + Victorian iron
architecture*). The existing free-form `tags` field is not organization: 1,717
uses across **1,171 unique tags**, 965 used exactly once, unnormalized
(`azulejo`/`azulejos`). This taxonomy replaces both with a **closed, faceted
vocabulary** — a tour gets several tags, and any tag is a filter.

## The five facets

A tour is described by tags drawn from five facets. **Place type** and **Theme**
are required (≥1 each); the rest are applied where they fit.

### 1 · Place type — *what it physically is* (pick 1–2, required)
| Tag | Definition |
|---|---|
| `Religious Building` | Church, cathedral, chapel, synagogue, monastery, temple. |
| `Museum & Gallery` | Museum, art gallery, or house-museum. |
| `Park & Garden` | Park, garden square, botanical garden, garden cemetery. |
| `Public Square` | Piazza, plaza, civic square, circus. |
| `Tower & Skyscraper` | Tall tower or high-rise; observation buildings. |
| `Bridge` | A road or foot bridge. |
| `Monument & Memorial` | Statue, column, obelisk, war memorial, national monument. |
| `Market & Arcade` | Food market, covered market, shopping arcade. |
| `Theatre & Venue` | Theatre, concert hall, performance/cultural venue, stadium. |
| `Library` | Public or national library. |
| `Street & District` | A named street, lane, yard, neighbourhood, or quarter. |
| `Civic & Government` | Town/city hall, court, bank, exchange, parliament, guild. |
| `Waterfront` | Pier, beach, harbour, quay, dock, riverside/seafront walk. |
| `Notable Building` | Architecturally notable building not covered above (station, cinema, residence, factory, pavilion…). |

### 2 · Theme — *what the story is about* (pick 1–3, required)
This is the meaning layer that replaces the old category.

| Tag | Definition |
|---|---|
| `Architecture & Design` | The building/design itself is the subject. |
| `History` | General historical narrative, eras, origins. |
| `Art` | Visual art — collections, sculpture, murals, public art. |
| `Literature` | Writers, books, literary associations. |
| `Music & Performance` | Music, theatre, jazz, recording, the stage. |
| `Food & Drink` | Markets, cuisine, wine, coffee, the table. |
| `Faith & Spirituality` | Religion, worship, the sacred. |
| `Power & Politics` | Monarchy, government, the machinery of state. |
| `Money & Trade` | Finance, commerce, markets, the diamond/Gilded-Age wealth story. |
| `Immigration & Community` | Migrant communities, who settled and why. |
| `Crime & Scandal` | Heists, slums, the red-light, the disreputable. |
| `Death & Remembrance` | Cemeteries, memorials, the outcast dead, mourning. |
| `Engineering & Innovation` | Structural feats, domes, spans, technical firsts. |
| `War & Conflict` | War, the Blitz, fortresses, wartime history. |
| `Maritime` | Docks, harbours, ships, the sea and the port. |

### 3 · Style & era — *for built things* (pick 0–2)
`Medieval / Gothic` · `Baroque` · `Georgian / Neoclassical` *(incl. Pombaline,
Federal)* · `Beaux-Arts` · `Victorian` · `Art Deco` · `Modernist` · `Brutalist` ·
`Contemporary` *(21st-century)* · `Gilded Age` *(NYC c.1870–1910)*

### 4 · Experience — *how you'll find it* (pick 0–2)
| Tag | Definition |
|---|---|
| `Iconic Landmark` | A must-see, world-famous. *(editorial — not auto-assigned)* |
| `Hidden Gem` | Off the beaten path, easily missed, a local secret. |
| `Viewpoint & Panorama` | A view, skyline, miradouro, observation deck. |
| `Green Escape` | A quiet, green place to slow down. |
| `Free to Visit` | No ticket required. |
| `After Dark` | Comes alive at night; nightlife. |
| `Designed by a Master` | Work of a celebrated architect (auto-set when an Architect tag applies). |

### 5 · Architect — *named designer* (pick 0–1, where notable)
A controlled list of architects with real presence in the catalog (counts =
tours):

`Álvaro Siza` (15) · `Eduardo Souto de Moura` (11) · `McKim, Mead & White` (7) ·
`Renzo Piano` (4) · `Norman Foster` (3) · `Fernando Távora` (3) ·
`Herzog & de Meuron` (3) · `Christopher Wren` (3) · `Inigo Jones` (2) ·
`Frank Gehry` · `Charles Holden` · `Denys Lasdun` · `Giles Gilbert Scott` ·
`Frank Lloyd Wright` · `Cass Gilbert` · `Inês Lobo` · `Luís Pedro Silva`

New architects are added to this list as the catalog grows (closed set, append-only).

## Rules

- **Closed vocabulary.** Only tags in this document are valid. The validator
  rejects anything else. New tags are added here first, deliberately.
- **Required:** ≥1 `Place type` and ≥1 `Theme`. Others optional.
- **Typical tour:** ~5–7 tags. (Catalog average from the seeder: 5.5.)
- **`Designed by a Master`** is implied by any `Architect` tag — keep them in sync.

## Data / model change (the code PR, separate)

1. `primaryCategory` is **removed** from `Tour`; the old `TourCategory` enum is
   replaced by a `Tag` type (string-backed, closed set, with a `facet`).
2. `Tour.tags` becomes the controlled `[Tag]`.
3. `validate-tours.swift` (and the Python mirror) enforce: every tag ∈ vocabulary;
   ≥1 Place type and ≥1 Theme per tour.
4. Home's `CategoryChipRow` → a **faceted multi-select filter** (facets as
   sections, tags as chips). This is the user-facing change that needs simulator
   review.

## Migration

`scripts/seed_tags.py` auto-assigns a first-pass tag set to all 243 tours from
title + old category + curated existing tags + descriptions, and writes
`docs/tag-migration-review.md` (per-tour proposal + coverage). Reliability:
**Place type / Style / Architect** are fairly accurate; **Theme** nuance,
`Iconic Landmark`, and the `Notable Building` fallthroughs need human correction.
Workflow: review → correct the seed → apply to `Tours.json` → ship the model/UI
PR.

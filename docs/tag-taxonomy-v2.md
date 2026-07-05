# Atlas tag taxonomy — v2 (refreshed for the 509-tour catalog)

**Status:** proposed / awaiting owner approval (2026-07-01). Supersedes the
2026-06-12 draft (`docs/tag-taxonomy.md` on branch
`claude/dreamy-wozniak-tags-260612`, never PR'd). This is a **plan**, not an
implementation — no app code, `Tours.json`, or backend changes ship from this
doc. See `docs/tag-migration-plan.md` for the engineering change list and the
open decisions.

Replaces the single `primaryCategory` enum with a **closed, curated, faceted
multi-select tag vocabulary**. Owner direction (endorsed 2026-05-19, carried
forward): **tags-only** (drop `primaryCategory`), **Architect is its own facet**.

## What changed since the June draft

| | June draft | Now |
|---|---|---|
| Catalog | 243 tours, ~4 cities | **509 tours, 9 makers** (NYC 100 · LDN 99 · LIS 66 · OPO 54 · HKG 52 · SFO 35 · TYO 63 · KYO 30 · YYZ 10) |
| New cities not in the analysis | — | **Tokyo, Kyoto, Hong Kong, San Francisco, Toronto** — temples/shrines, design/flagship landmarks, the Tokyo Toilet project, colonial-era HK, SF Victorians/Mission, Kyoto machiya/zen gardens |
| Backend | gh-pages `Tours.json` only | **Supabase-backed** — `get_catalog` RPC + gh-pages mirror + CI auto-seed; `tours.tags text[]` column already exists |

### The catch-all got worse
The old enum is now more lopsided than when the problem was first flagged.
Current `primaryCategory` distribution over 509 tours:

| category | count | | category | count |
|---|---|---|---|---|
| **culturalHeritage** | **122** | | visualArt | 38 |
| architecture | 121 | | foodAndDrink | 32 |
| history | 68 | | musicAndPerformance | 13 |
| sacredSites | 49 | | hiddenGems | 12 |
| natureAndParks | 46 | | literature | 8 |

`culturalHeritage` is now the **single largest bucket** — a meaningless
catch-all absorbing 25% of the catalog. The free-form `tags` field has degraded
too: **~3,300 uses across 2,183 unique tags, most used exactly once**,
unnormalized (`azulejo`/`azulejos`, `siza vieira`/`siza`). Neither field is
doing organizing work. This taxonomy replaces both.

## The five facets

A tour is described by tags drawn from five facets. **Place type** and **Theme**
are required (≥1 each); the rest are applied where they fit. New v2 tags are
**bold**. Counts in parentheses are from the refreshed auto-seed over the 509
tours (`scripts/seed_tags.py` → `docs/tag-migration-review.md`) — a first-pass
signal, not a final count.

### 1 · Place type — *what it physically is* (pick 1–2, required)
| Tag | Definition |
|---|---|
| `Religious Building` (48) | Church, cathedral, chapel, synagogue, monastery — **and Buddhist temple / Shinto shrine / Taoist temple** (Tokyo, HK). |
| `Museum` (60) | Museum, art gallery, or house-museum. |
| `Park` (55) | Park, garden square, botanical/Japanese garden, garden cemetery. |
| `Public Square` (16) | Piazza, plaza, civic square, circus — **incl. Shibuya-style crossings**. |
| `Tower` (18) | Tall tower / high-rise / observation building (Skytree, Mori, Peak Tower). |
| `Bridge` (9) | A road or foot bridge. |
| `Monument` (11) | Statue, column, obelisk, war/peace memorial, national monument. |
| `Market` (21) | Food market, covered market, shopping arcade, **yokocho alley**. |
| `Venue` (24) | Theatre, concert hall, performance/cultural venue, stadium, **kabuki theatre**. |
| `Library` (6) | Public or national library. |
| `District` (49) | A named street, lane, yard, neighbourhood, quarter (Ginza, Alfama, Chinatown, Mission). |
| `Civic` (16) | Town/city hall, court, bank, exchange, parliament, guild, **Diet**. |
| `Waterfront` (16) | Pier, beach, harbour, quay, dock, bay, riverside/seafront walk (Victoria Harbour, the Bund, Embarcadero). |
| `Notable Building` (86) | Architecturally notable building not covered above (station, cinema, residence, factory, pavilion, **public toilet**…). **Catch-all — see note.** |

> **`Notable Building` is the new catch-all risk.** After the seeder learned to
> read the short description (not just the title), the fall-through dropped from
> 174 → **86** tours, of which **85** resolve *only* to Notable Building and are
> the ones that need a human look. Those 85 are sorted to the top of each city's
> table in `docs/tag-migration-review.md`. Review effort, not a taxonomy flaw.

### 2 · Theme — *what the story is about* (pick 1–3, required)
The meaning layer that replaces the old category.

| Tag | Definition |
|---|---|
| `Architecture` (287) | The building/design itself is the subject. |
| `History` (257) | General historical narrative, eras, origins. |
| `Art` (145) | Visual art — collections, sculpture, murals, public art, teamLab. |
| `Literature` (54) | Writers, books, literary associations. |
| `Performance` (104) | Music, theatre, jazz, recording, the stage, kabuki. |
| `Food` (96) | Markets, cuisine, wine, coffee — **ramen, izakaya, sushi, dim sum**. |
| `Faith` (129) | Religion, worship, the sacred — **Buddhism, Shinto, Zen**. |
| `Power` (130) | Monarchy, government, the machinery of state — **imperial Japan, colonial administration**. |
| `Commerce` (103) | Finance, commerce, markets, the Gilded-Age / tycoon wealth story. |
| `Immigration` (58) | Migrant communities — Chinatown, Harlem, **Japantown**, who settled and why. |
| `Crime` (25) | Heists, slums, the red-light, the disreputable. |
| `Remembrance` (55) | Cemeteries, memorials, mourning — **atomic/war remembrance**. |
| `Engineering` (125) | Structural feats, domes, spans, **seismic engineering**, technical firsts. |
| `War` (71) | War, the Blitz, fortresses, wartime history. |
| `Maritime` (72) | Docks, harbours, ships, the sea and the port — junk boats, the Bund. |
| **`Fashion`** (46) | **Fashion, luxury retail, department-store culture, the flagship-as-architecture story (Ginza, Omotesando, Fifth Avenue).** |
| **`LGBTQ+`** (4) | **LGBTQ+ history and culture — Stonewall, Harvey Milk & the Castro, Soho's Old Compton Street. Hand-applied (owner-added 2026-07-04), backed by precise seeder keywords.** |

### 3 · Style & era — *for built things* (pick 0–2)
`Gothic` (49) · `Baroque` (20) · `Neoclassical` (23)
*(incl. Pombaline, Federal)* · `Beaux-Arts` (15) · `Victorian` (31) ·
`Art Deco` (15) · `Modernist` (28) · `Brutalist` (6) ·
`Contemporary` (34) *(21st-century)* · `Gilded Age` (5) *(NYC c.1870–1910)* ·
**`Colonial`** (23) *(HK/treaty-port, Portuguese, early-American)*

### 4 · Experience — *how you'll find it* (pick 0–2)
| Tag | Definition |
|---|---|
| `Iconic Landmark` (0†) | A must-see, world-famous. *(editorial — not auto-assigned)* |
| `Hidden Gem` (33) | Off the beaten path, easily missed, a local secret. |
| `Viewpoint` (77) | A view, skyline, miradouro, observation deck, the Peak. |
| `Green Escape` (117) | A quiet, green place to slow down. |
| `Free to Visit` (0†) | No ticket required. *(editorial)* |
| `After Dark` (0†) | Comes alive at night; neon, nightlife. *(editorial)* |
| **`Public Art`** (33) | **Outdoor installation / mural / sculpture / the Tokyo Toilet project — free, in situ.** |
| `Designed by a Master` (116) | Work of a celebrated architect (auto-set when an Architect tag applies). |

> † `Iconic Landmark`, `Free to Visit`, and `After Dark` are **editorial** — a
> keyword seed can't judge them, so they read 0 in the auto-pass and are
> hand-authored during review. Budget for this.

### 5 · Architect — *named designer* (pick 0–1, where notable)
Closed, **append-only** list of architects with real presence in the current
catalog. Counts = tours mentioning them (a *mention* may be comparative — the
seed flags candidates, the human confirms the subject architect).

**Carried from v1:** `Álvaro Siza` (15) · `Eduardo Souto de Moura` (11) ·
`McKim, Mead & White` (7) · `Renzo Piano` (7) · `Herzog & de Meuron` (7) ·
`Norman Foster` (6) · `Christopher Wren` (5) · `Giles Gilbert Scott` (4) ·
`George Gilbert Scott` (2) *(the grandfather — Albert Memorial, St Pancras; not Giles, his grandson)* ·
`Fernando Távora` (3) · `Inigo Jones` (3) · `Frank Gehry` · `Charles Holden` ·
`Denys Lasdun` · `Frank Lloyd Wright` · `Cass Gilbert` · `Inês Lobo` ·
`Luís Pedro Silva`.

**New for Tokyo:** `Kengo Kuma` (8) · `Kenzō Tange` (4) · `Fumihiko Maki` (3) ·
`Shigeru Ban` (3) · `Tadao Ando` (2) · `SANAA` (2) *(Sejima + Nishizawa)* ·
`Kisho Kurokawa` (2) · `Toyo Ito` · `Sou Fujimoto`.

**New for HK / SF / NYC / global** (surfaced across the new catalog):
`I. M. Pei` (3) · `Mies van der Rohe` (3) · `Le Corbusier` (3) ·
`Philip Johnson` (3) · `Thomas Heatherwick` (3) · `Bernard Maybeck` (SF) ·
`Daniel Burnham` (SF) · `William Van Alen` (Chrysler) · `Santiago Calatrava`
(Oculus) · `Zaha Hadid` · `Jean Nouvel`.

New architects are appended here first, deliberately, as the catalog grows.

## Rules

- **Closed vocabulary.** Only tags in this document are valid. The validator
  rejects anything else. New tags are added here first.
- **Required:** ≥1 `Place type` and ≥1 `Theme`. Others optional.
- **Typical tour:** ~5–7 tags (auto-seed average **6.4**, range 2–14).
- **`Designed by a Master`** is implied by any `Architect` tag — keep in sync.

## Open questions the catalog raised (detailed in the migration plan)

- **D1 — `Shop & Flagship` place type vs `Notable Building` + `Fashion`
  theme.** Only ~3 tours read as flagship *by title*, but 46 hit the retail
  theme. Is the flagship-store landmark distinct enough to be its own place
  type, or is `Notable Building` + `Fashion` enough?
- **D2 — thin new tags.** `Metabolist` (Nakagin was demolished 2022 — may be 0)
  and `Mission / Spanish Revival` (1) are marginal. Keep for curatorial
  completeness, fold into `Modernist` / `Colonial`, or drop?
- **D3 — split `Religious Building`?** Tokyo/HK add 32 temples + 9 shrines. Keep
  one broad `Religious Building`, or split `Temple & Shrine` for the East-Asian
  catalog?

See `docs/tag-migration-plan.md` § Open decisions for the full list.

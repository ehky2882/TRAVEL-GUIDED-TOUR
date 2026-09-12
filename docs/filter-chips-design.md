# Filter chips — the facet row

**Status:** design agreed, not yet built. Canvas:
<https://claude.ai/code/artifact/b5da2e3e-cd23-4484-807b-c8e74cb70d59>

Replaces the flat multi-select row shipped in Tag Phase 2 (`Features/Home/TagFilterChipRow.swift`,
owner decision D8). The combine rule is unchanged — **OR within a facet, AND across** (D6,
`Tag.matches`). What changes is the row: eighteen toggles become **one door plus eight facets**,
each opening its own sheet.

## The row

```
≡ All · Format ⌄ · Dozent ⌄ · Experience ⌄ · Type ⌄ · Theme ⌄ · Era ⌄ · Nearby ⌄ · Architect ⌄
```

Left to right: what the thing is → whose it is → how it feels → what it is → what it is about →
when → how far → by whom.

| Chip | Values | Notes |
|---|---|---|
| **≡ All** | every facet below, one scroll | Never fills brass — it is a door, not a filter. Badge counts the values switched on behind it. |
| **Format** | Audio stop 1,480 · Audio walk 72 ‖ TikTok 1,106 · Instagram 592 · YouTube 19 | Grouped **Audio tours** / **Pinned posts**. The catalogue's real fault line and the row says nothing about it today. |
| **Price** | Free 3,283 · Paid 66 | Two values, not bands — see below. |
| **Dozent** | 377 · 34 studios · 343 pinned | Search. Groups: Studio Dozents / Pinned Dozents. |
| **Experience** | 8 · Designed by a Master 857 → After Dark 93 | The only facet phrased from the visitor's side, hence high in the row. |
| **Type** | 14 · Notable Building 742 → Bridge 44 | Icons earn their place here — one line glyph per type. |
| **Theme** | 17 · History 1,361 → LGBTQ+ 16 | Longest grid: 8 chips then More. |
| **Era** | 11 · Contemporary 401 → Gilded Age 36 | |
| **Nearby** | Walking distance · 5 km · 25 km | Single-select, no counts (they depend on where the viewer is). |
| **Architect** | 429 · largest is 23 | Search. |

**Counts below are from `Resources/Tours.json` in this checkout; the live catalogue is already
ahead of it (1,796 link pins against this file's 1,717). Re-derive before building.** Counts are
over all 3,269 pins — 1,552 tours and 1,717 link pins — because the chips filter the
map and the map carries both.** That denominator overturns the Phase 2 call that kept Art Deco,
Brutalist and Bridge out of the row for being thin: against 3,269 they are 50, 51 and 44.
Re-derive before building; they move with every content merge.

### Not chips, and why

| | |
|---|---|
| City | the map answers "where" by panning; 116 cities is a search, not a chip |
| Duration | median audio stop is 2 min 14 s — Format already separates the stop from the 11-minute walk |
| Rating | we collect none |
| Purchased | entitlement state, like Saved and Downloaded — belongs in the All sheet |
| Saved / Downloaded | personal, not editorial — lives in the All sheet |
| Video tour | one tour (`via-57-west`). The value stays in the model; the option appears when it clears ~20 |

### 🔴 Price comes from the database, never from `Tours.json`

`seed_from_toursjson.py` **omits `price_tier` deliberately** — price lives in the DB and is
maker-set, so a content re-seed cannot reset it. The consequence is that `Tours.json` reads
`priceTier: null` for every tour **and always will**, however many paid tours exist. Reading the
file and concluding "everything is free" is a false pass; this design nearly shipped with Price
excluded on exactly that reasoning.

Ask the live DB instead — 47 bytes, no catalogue fetch:

```bash
curl -s --compressed -D - -o /dev/null \
  -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
  -H "Range: 0-0" -H "Prefer: count=exact" \
  "$PROJECT/rest/v1/tours?select=id&price_tier=not.is.null"   # content-range: 0-0/66
```

**As of 2026-09-12: 66 paid tours, every one a multi-stop walk, every one at $0.99** — 66 of the
~72 walks in the catalogue. Fourteen tiers exist in App Store Connect; one is in use.

Two consequences for the chip:

- **Two values, not bands.** `Under $5 / $5–10 / Over $10` would be three options with two empty.
  Bands earn their place when the spread widens.
- **Price is nearly a restatement of Format today** — `Paid` returns very close to what
  `Audio walk` returns. Not a reason to drop it, but it is why it slices little for now.

⚠️ `Free` here means the *tour* costs nothing. Experience carries **`Free to Visit`** (323), which
means the *place* costs nothing to enter. If the two read ambiguously side by side once built, the
price values become `Free to listen` / `Paid`.

## Rules

1. **Over ~30 values a grid becomes a search.** Dozent (377) and Architect (429) are lists with a
   search field; everything else is a chip grid. Search changes the presentation, never how the
   facet combines — both stay multi-select.
2. **A set chip becomes its own answer**: `Museum`, or `Museum +2`. Empty, it shows the facet name
   and a chevron.
3. **Counts sit on the option inside the sheet, and on the commit pill — never on a row chip.**
   Ours run from 1,480 to 19, so "YouTube 19" is the whole reason not to tap it. (The reference app
   shows no counts anywhere; its values are all common, ours are not.)
4. **One facet, one sheet**, sized to its own content. The All sheet is the only one that stacks
   them.
5. **A brass pill floats over every sheet** carrying the live count — `SHOW 118 PINS` — and commits.
6. **Sort leaves the row** for the drawer header, opposite the result count.
7. Chips filter **the map and the drawer together**, from one predicate.

## Anatomy

The 44 pt capsule the search bar already uses (`AtlasSpacing.searchBarHeight`), 13 pt SF Mono
(`AtlasTypography.caption`), `secondaryBackground` at rest, `mapPin` brass when on with
`background` as the label colour, 8 pt gaps, 16 pt gutters. No new token. The only new drawing is
one line glyph per place type.

## Implementation notes

Every signal is already on the device — **no Supabase migration, no `get_catalog` change, no
catalogue edit**:

| Chip | Reads |
|---|---|
| Format | `tour.kind` (`single` · `multiStop` · `link`) + `tour.linkSource` (derived from `sourceURL`) |
| Dozent | `tour.makerId` + `DataService.makers` (`toursByMakerId` already indexes it) |
| Experience · Type · Theme · Era · Architect | `tour.tags` via `Tag.matches` |
| Nearby | `LocationManager.userLocation` + the tour's coordinate |

Touch points: `HomeSharedState` (two filter fields become a small predicate set),
`TagFilterChipRow` (toggles → facet chips), two new sheets, and the two filter sites that must stay
in step — `HomeView.filteredTours` and `HomeRailsViewModel`.

## Open

**Whether `Audio` and `Posts` should be one-tap chips** instead of living inside Format. Faster for
the common case, but the pair would have to **OR** where every other pair of chips **ANDs**, which
is a special case in an otherwise uniform rule. Recommendation: keep them inside Format.

## Where this came from

An AllTrails screen recording the owner supplied (2026-09-11). Taken from it: the per-facet mini
sheet, the floating count pill, sort outside the row, icons on sheet chips. Deliberately not taken:
sliders (our only range is duration, median 2 minutes) and the rounded-rectangle chip — ours is a
capsule in SF Mono, which is the app's own voice.

# Filter chips — a door and four chips

**Status:** design agreed, not yet built. Canvas:
<https://claude.ai/code/artifact/b5da2e3e-cd23-4484-807b-c8e74cb70d59>

Replaces the flat multi-select row shipped in Tag Phase 2 (`Features/Home/TagFilterChipRow.swift`,
owner decision D8). The combine rule is **unchanged** — OR within a facet, AND across (D6,
`Tag.matches`). What changes is the row: eighteen toggles become **four chips**, each opening a
sheet.

```
≡ All  ·  Format ⌄  ·  Price ⌄  ·  Dozents ⌄  ·  Tags ⌄
```

The row splits along a real seam. Three **structural fields** — `kind`, `price_tier`, `makerId` —
get a chip each, because each asks a different kind of question. The **entire controlled
vocabulary** gets one chip, because it is all the same kind of question.

| Chip | Values | Notes |
|---|---|---|
| **≡ All** | every facet below, in one scroll | A door, not a filter — never fills brass; its badge counts what is on behind it. |
| **Format** | Audio stop 1,481 · Audio walk 72 · Instagram posts 9 · Instagram Reels 625 · TikTok 1,235 · YouTube Shorts 3 · YouTube videos 16 | One flat list, alphabetical. One field, so its values OR. |
| **Price** | Free 3,375 · Paid 66 | Two values, not bands. **Read from the DB** — see below. |
| **Dozents** | 377, largest first — @urbanistariel 292 → 252 with a single pin | Search. One flat list. **Plural**, as Settings and the empty state already say. |
| **Tags** | PLACE 14 · SUBJECT 17 · WHY GO 8 · ERA 11 · ARCHITECT 429 | One chip, five groups. Any within a group, all across groups. |

**Clear** sits in every panel's header — one word everywhere, the All panel included — not in the
row. **Sort** sits on the drawer header, opposite the result count.

### The All panel

Every facet in one scroll, one heading level deep: `FORMAT`, `PRICE`, `DOZENT`, then Tags' own
groups — `PLACE`, `SUBJECT`, `WHY GO`, `ERA`, `ARCHITECT` — flattened to the same level, each with
its `More`. It writes into exactly the same selection as the individual chips, so the two routes
cannot disagree.

**Kept because some people would rather scan one list than open four panels** (owner,
2026-09-12) — which is how the reference app leads its row. It was briefly cut on the reasoning
that it duplicates the chips; duplication is the point. It is a second route, not a second
mechanism.

**Counts are over every row the map carries — tours AND link pins — because the chips filter the
map and the map shows both.** That denominator overturns the Phase 2 call that kept Art Deco,
Brutalist and Bridge out of the row for being thin: against ~3,400 they are 50, 51 and 44.

**Live, 2026-09-12 (reconciled, `kind` and `source_url` from the DB):**

| | |
|---|---|
| All rows | **3,441** |
| Audio stop (`single`) · Audio walk (`multiStop`) | 1,481 · 72 — **1,553 tours** |
| Link pins | **1,888** — TikTok 1,235 · Instagram Reels 625 · Instagram posts 9 · YouTube videos 16 · YouTube Shorts 3, nothing unclassified |
| Paid · Free | 66 · 3,375 |

⚠️ 🔴 **Re-derive every number before building, and mean it.** The tag-level counts in this document
come from `Resources/Tours.json` in one checkout, against 3,269 rows. **The live catalogue moved
from 1,796 to 1,888 link pins during the single session that wrote this file** — 92 pins in about
forty minutes, from other sessions merging content. Nothing here is wrong so much as perishable;
treat every figure as an order of magnitude, not a value. The one-line count query below is the
pattern for all of them, and price can never come from the file at all.

## Why one Tags chip rather than a chip per facet

Because **the number of chips is presentational, not semantic.** `Tag.matches` takes one flat
`Set<String>` of tags and derives each tag's facet itself via `Tag.facetByTag`, then ORs within a
facet and ANDs across. The shipped app already passes it a single `selectedTags` set. So one chip
filters identically to five: `Place` AND `Subject` still asks "a market, about empire" — you just
pick both from one sheet, under two headings.

What the merge buys: the row stops asking anyone to know what "Theme" means. What it costs: the
Tags sheet is the longest screen in the app, and a collapsed chip reading `Museum +2` says less
than three chips each showing their own value. **Mitigation:** a `More` per group, and show the
single value when exactly one is picked, otherwise `Tags · 4`.

### The groups inside Tags, renamed to the question each answers

| Was | Is | Asks |
|---|---|---|
| Type | **Place** | what it *is* — a noun you could point at |
| Theme | **Subject** | what the narration is *about* |
| Experience | **Why go** | what you get out of being there |

Borough Market is the clean case: a **Market**, about **food · history · commerce**, promising
nothing in particular. Notre-Dame de Paris is a **Religious Building**, about **faith · history**,
and an **Iconic Landmark**.

**Four values are demoted** into their group's `More` — still selectable, just not promoted:

| Value | Why |
|---|---|
| `Faith` | 88% of `Religious Building` is also `Faith`, and 77% the other way — one fact, two chips |
| `Architecture` | 82% of `Designed by a Master` carries it, and it matches 37% of the catalogue |
| `History` | matches 42% of the catalogue, so it narrows almost nothing |
| `Green Escape` | 72% of it is also `Park` |

Two rules fall out, worth applying to any future value: **a value matching more than ~a third of
the catalogue does not narrow anything**, and **where two groups' values overlap ~70% both ways,
promote one.** Both changes are display-only; the tags stay on the tours.

The split still earns its keep where the vocabulary is clean — `Tower` / `Viewpoint` overlap only
19% / 9% (most towers are shut at the top), `Venue` / `Performance` 15% (most venues are bars).

### 🔴 Price comes from the database, never from `Tours.json`

`seed_from_toursjson.py` **omits `price_tier` deliberately** — price lives in the DB and is
maker-set, so a content re-seed cannot reset it. `Tours.json` therefore reads `priceTier: null` for
every tour **and always will**, however many paid tours exist. Reading the file and concluding
"everything is free" is a false pass; this design nearly shipped without a Price chip on exactly
that reasoning.

Ask the live DB — 47 bytes, no catalogue fetch:

```bash
curl -s --compressed -D - -o /dev/null \
  -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
  -H "Range: 0-0" -H "Prefer: count=exact" \
  "$PROJECT/rest/v1/tours?select=id&price_tier=not.is.null"   # content-range: 0-0/66
```

**As of 2026-09-12: 66 paid tours, every one a multi-stop walk, every one at $0.99** — 66 of the
~72 walks in the catalogue. Fourteen tiers exist in App Store Connect; one is in use. Hence two
values rather than bands (`Under $5 / $5–10 / Over $10` would be three options with two empty), and
hence `Paid` returns nearly what `Audio walk` returns for now.

⚠️ `Free` here means the *tour* costs nothing. `Why go` carries **`Free to Visit`** (323), which
means the *place* costs nothing to enter. If the two read ambiguously once built, the price values
become `Free to listen` / `Paid`.

### Two lists that are deliberately NOT grouped (owner, 2026-09-12)

**Dozent is one flat list.** An earlier draft split it into *Studio Dozents* (34) and *Pinned
Dozents* (343), with brass avatars for the studios and grey for everyone else. Both are gone: a
Dozent is a Dozent, whether they record for us or we pin their post, and the panel must not sort
them into first and second class. Rows carry the maker's own `avatarURL` — all 377 have one — and
are ordered by how much of the map is theirs.

**Format is one flat list too.** *Audio tours* / *Pinned posts* headings earned nothing: the option
labels already say which is which.

### Format splits by platform AND by short-form — each in the platform's own words

**Owner decision, 2026-09-12: the short-form formats are separately selectable.** Seven options,
using each platform's own branding — **Reels** and **Shorts** are product names and take a capital;
**videos** and **posts** are generic and do not. TikTok brands nothing separately, so it is one
option.

| Option | Live count | How it is detected |
|---|---|---|
| Audio stop | 1,481 | `kind == .single` |
| Audio walk | 72 | `kind == .multiStop` |
| Instagram posts | 9 | `/p/` or `/tv/` path — **needs a new one-liner** |
| Instagram Reels | 625 | `/reel` or `/reels` path — **needs a new one-liner** |
| TikTok | 1,235 | host |
| YouTube Shorts | 3 | **`LinkSource.isYouTubeShort(_:)`, already shipping** |
| YouTube videos | 16 | YouTube host, not a Short |

`isYouTubeShort` matches `shorts` as a whole path component, so a video merely *titled* "shorts"
cannot fool it, and the app already uses it to give a Short a 9:16 player instead of letterboxing
it into 16:9. Instagram needs the equivalent: the 9 non-reel pins are eight `/p/` posts and one
`/tv/` (IGTV, retired), so `/p/` and `/tv/` are posts and `/reel`/`/reels` are Reels.

⚠️ **Two options are tiny — Shorts 3 and Instagram posts 9 — and that was weighed.** It cuts
against the rule that an option finding a handful reads as broken (the rule that still holds
`Video tour`, at 1, out of the list). It wins anyway because leaving them unlisted would make those
pins **unreachable from this chip**: picking `Instagram Reels` excludes the 9 posts, and nothing
else would select them.

⚠️ Worth knowing what the numbers say about Instagram regardless: of 634,
**625 are Reels**, so Instagram is a reels channel with a rounding error attached. The app still
gives all Instagram a 9:16 player, which is right for 625 of 634.

## Not chips, and why

| | |
|---|---|
| **Nearby** | the map *is* a distance filter and a continuous one; it dies without location permission; and it means nothing when planning a trip from home. Served instead by sort-by-nearest and the existing recenter button |
| City | same reason — panning answers "where"; 116 cities is a search |
| Duration | median audio stop is 2 min 14 s — Format already separates the stop from the 11-minute walk |
| Rating | we collect none |
| Saved · Downloaded · Purchased | personal state, rare mid-walk — belongs in the **Library tab** |
| Video tour | one tour (`via-57-west`). The value stays in the model; the option appears when it clears ~20 |

## Rules

1. **Over ~30 values a grid becomes a search.** Dozent (377) and Architect (429) are lists with a
   search field; everything else is a grid. Search changes the presentation, never how the facet
   combines — both stay multi-select.
2. **A set chip becomes its own answer**: `Museum`, or `Museum +2`. Empty, it shows the chip name
   and a chevron.
3. **Counts sit on the option inside the sheet, and on the commit pill — never on a row chip.**
   Ours run from 1,480 to 19, so "YouTube 19" is the whole reason not to tap it. (The reference app
   shows no counts anywhere; its values are all common, ours are not.)
4. **A sheet holds only what its chip opened**, sized to its own content. Three shapes cover every
   chip: short grid, grouped grid, searchable list.
5. **Every panel reserves the pill's height plus clearance at the end of its content** — 96 pt of
   run-out. The pill floats, so without it the last option of any scrolling panel sits underneath
   and is untappable. A panel with a fixed height must also be at least its content plus that 96:
   `Format` was 440 pt from when it held five options, and splitting `Reels` and `Shorts` out took
   it to seven stacked rows — 375 pt of content, so 470 pt of panel.
6. **A brass pill floats over every panel** carrying the live count — `SHOW 118 RESULTS`, or
   `SHOW 1 RESULT` — and commits. **The noun is "results"** (owner, 2026-09-12): "pins" is our
   word for map markers and should never reach a user, and "tours" is wrong for the 1,796 pinned
   posts. It also matches copy the app already ships — `HomeDrawerContent` says `1 RESULT` /
   `N RESULTS` while filtering. The unfiltered drawer header becomes `N RESULTS IN VIEW`.
7. **Sort lives on the drawer header**, not in the row.
8. Chips filter **the map and the drawer together**, from one predicate.

## Anatomy — two heights, and why

Every chip is a capsule (`radius = height / 2`) in **13 pt SF Mono** (`AtlasTypography.caption`),
`secondaryBackground` at rest, `mapPin` brass when on with `background` as the label colour, 16 pt
gutters. Two sizes, for two different jobs:

| | Height | Padding | Gaps | Effective tap target |
|---|---|---|---|---|
| **Row** (over the map) | **44** — `AtlasSpacing.searchBarHeight` | 0 16 | 8 | 52 pt |
| **Panel options** | **32** | 0 13 | **row 16 · column 10** | **48 pt** |

**Why 32 in the panels.** At 44 pt the Tags panel runs to ~940 px — nearly two screens. 32 brings
it to ~780 px, about a fifth of a screen of scrolling.

**Why the gaps are 16 and 10.** What a thumb cares about is the **vertical pitch** — the chip plus
the gap it can absorb — not the drawn height. A 32 pt chip with a 16 pt row gap is a **48 pt
target**, comfortably past the 44 pt HIG minimum rather than exactly on it.
`.contentShape(Rectangle())` over the padded frame is what makes the absorbed gap real. Columns
matter less (a 60–180 pt wide chip was never the problem), so 10 is for air, not for aim.

⚠️ **22 pt was tried and rejected.** It reaches ~410 px — far tighter than needed — but its pitch
is **28 pt**, 16 short, and this is an app used one-handed while walking. A mis-tap is not
harmless: with contextual counts, one wrong chip can take the result to zero, leaving you to work
out which of forty you hit. 22 pt also cannot grow with Dynamic Type.

**The Tags panel fits one screen, at a price.** The panel starts at 64 pt (just under the status
bar) and the promoted set is trimmed to **Place 4 · Subject 4 · Why go 3 · Era 3** — 637 pt over 9
rows, fitting with ~30 pt spare. Sliding alone could not do it: at 7·5·4·4 promoted the content was
829 pt, which is 96 pt short even with the panel at the very top of the screen, so the lever had to
be the promoted set rather than the spacing.

⚠️ **It fits on a big phone only.** A 667 pt screen (SE) leaves ~430 pt of panel, so it scrolls
there whatever we do — "no scrolling" is a property of large phones, not of this design, so the
scroll behaviour and the pinned group heading still have to be right.

⚠️ **`More` now carries 10 of the 14 place types and 13 of the 17 subjects.** That is a heavier bet
on the promotion judgement than before; if a value people expect is behind `More`, swap it forward
rather than widening the panel.

⚠️ **Superseded note, kept for the reasoning:** ~780 px against a ~650 px
budget (panel top at 96, ~96 reserved for the pill) — `Architect` and the tail of `Era` sit below
the fold. It briefly did fit, at 12/7 spacing, and that was my argument for 32 pt over 44 pt; the
argument survives on its own numbers (44 pt would be ~940 px). **Consequence: the pinned group
heading is load-bearing, not a nicety** — you will scroll past `PLACE` into `SUBJECT`, and a chip
reading `Contemporary` means nothing without `ERA` above it. If the scrolling grates, promote fewer
values per group rather than tightening the spacing back.

**Kept larger on purpose:** the `Architect` search field (40 pt — a text input, not a chip) and the
over-filtered screen's two buttons (44 pt — pressed once, in frustration).

### Panel header and layout (owner review, 2026-09-12)

**The title is the caption font** — 13 pt SF Mono, uppercase, 0.06 em tracking. Not a sans
semibold sheet title: `HomeDrawerContent`'s count header is already `AtlasTypography.caption` with
tracking and uppercase copy, so panel chrome is mono in this app. Hierarchy comes from size and
colour, not typeface — title 13 pt in `primaryText`, group labels 11 pt in `secondaryText`.

**The title is centred; nothing else is** (owner, 2026-09-12). `Clear` is positioned absolutely at
the right rather than as a flex sibling, so the title centres on the panel and not on the space
left beside it. `Format`'s stacked column is centred too. **Group labels stay left-aligned** — an
earlier pass centred them and the owner pulled it back. A chip's own label is already centred
inside its capsule with its count beside it, so centring that pair independently would make the
numbers wander; and the `Dozents` rows are full-width list rows with an avatar, so centring the
name would unmoor the column.

### Ordering: counts promote, the alphabet displays

**Within every group, values are in alphabetical order** — `District · Monument · Museum · Park ·
Religious Building · Venue · Waterfront`. An earlier pass sorted each group by pin count, biggest
first, on the reasoning that the likeliest picks come first. Rejected for two reasons, and both
generalise: the order was **invisible** (nothing on screen says these are in size order, so it
reads as arbitrary) and **unstable** (every content merge reshuffles it, so nobody can learn where
anything is).

**The counts still decide WHICH values are promoted** and which fall into `More` — that has to stay
volume-based, or `More` would swallow things people actually want. Only the display order changed.

⚠️ **One deliberate exception: the `Dozents` list stays in size order, most first.** It is a search
list of 377 where "most of the map is theirs" is a real relevance ranking; alphabetically it would
open on whichever Instagram handle happens to begin with an A.

`Format` took the alphabet happily, as it happens: `Audio stop · Audio walk · Instagram · TikTok ·
YouTube` puts the two audio kinds together, which size order split apart.

**Spacing:** 24 pt between the header and the first option, 28 pt above each group label, 16 pt
between option rows and 10 pt across. The 16 pt row gap is load-bearing (it is what makes the 48 pt
target) — widen it freely, never shrink it.

**`Format` stacks; every other panel wraps.** One option per row, left-aligned, in `Format` only.
It has five options with a real pecking order — 1,480 audio stops down to 19 YouTube posts — so a
column reads like a list you work down. `Tags` has thirty-odd values across five groups where
nothing outranks anything: stacked it runs to two screens for no gain, wrapped it fits one.

No new colour or type token. Two new named control heights would be worth adding beside
`searchBarHeight`, rather than reusing `AtlasSpacing.xl` (32) and an untokenised 12, since these
are control metrics rather than spacing. The only new drawing is one line glyph per `Place` value.

## Implementation notes

Every signal is already on the device — **no Supabase migration, no `get_catalog` change, no
catalogue edit**:

| Chip | Reads |
|---|---|
| Format | `tour.kind` + `tour.linkSource`, plus `isYouTubeShort` (ships) and a matching Instagram reel check (**new, one-liner**) |
| Price | `tour.priceTier` (already a `get_catalog` key) |
| Dozents | `tour.makerId` + `DataService.makers` (`toursByMakerId` already indexes it) |
| Tags | `tour.tags` via `Tag.matches`, unchanged |

Touch points: `HomeSharedState` (two filter fields become a small predicate set),
`TagFilterChipRow` (toggles → four chips), the three sheet shapes, and the two filter sites that
must stay in step — `HomeView.filteredTours` and `HomeRailsViewModel`.

## Multi-select, and the one thing it rules out

**Every chip is multi-select.** Picking several values inside a chip means *any of them*:
`Instagram` + `TikTok` gets both platforms, `@hereinnyc` + `@urbanistariel` gets both feeds. Across
chips it is *all of them*: `Museum` (Tags) + `Paid` (Price) gets museums that are paid. That is D6,
unchanged — OR within a facet, AND across.

`Tags` is the only chip where both halves of the rule are visible at once, and the group headings
are what signal it: `Museum` + `Market` (both **Place**) gets either, while `Museum` + `Food`
(**Place** + **Subject**) gets museums about food.

**Settled 2026-09-12: `Audio` and `Posts` stay inside `Format` — they are not promoted to two
chips.** The one-tap version was tempting for the commonest request, but two sibling chips would
land on the AND side of the rule, where `Audio` AND `Posts` matches nothing — so that pair alone
would have to OR, getting *wider* as you tap in a row where everything else gets narrower. Inside
one chip they already OR, which is the behaviour wanted. No special case, no new rule.

If the three taps ever grate, the cheap fix is to make the sheet's group headings selectable, so
tapping **Audio tours** picks the whole group at once — no new chip and no new rule.

## Where this came from

An AllTrails screen recording the owner supplied (2026-09-11). Taken from it: a sheet holds only
what its chip opened, the floating count pill, sort outside the row, icons on sheet chips.
Deliberately not taken: sliders (our only range is duration, median 2 minutes) and the
rounded-rectangle chip — ours is a capsule in SF Mono, which is the app's own voice.

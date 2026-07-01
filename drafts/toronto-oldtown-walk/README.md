# Toronto — "Old Town" multi-stop walk (audio pending) 🇨🇦

Image-staged 2026-06-30. **Toronto's first multi-stop walk** — 5 stops through the
founding core east of downtown, tied by the through-line "how a muddy colonial town
talked itself into becoming a city." Maker **Atlas Studio YYZ** (create at first
Toronto wire-in).

## Tour shape (`kind: multiStop`)
- `introAudioURL: null` — the intro IS stop 0 (manual trigger); stops 1-5 are geofenced (radius 40).
- `totalDurationSeconds` = sum of all stop durations (read from MP3s at wire-in).
- centroid = average of the 5 stop coords; `walkingDistanceMeters` ≈ **2300** (Union → Distillery, ~1hr easy walk; last leg Market→Distillery is the long ~1.1km SE leg).
- `heroImageURL` = the walk cover; `additionalImageURLs` = the per-stop images below.
- Suggested category: `history`.

## Stops (order + coords + image)
| # | Stop | slug (existing images) | coord (lat, lon) | trigger |
|---|------|------------------------|------------------|---------|
| 0 | Intro — Old Town | — (no image; narration only) | 43.6453, -79.3806 (at Union Station) | manual |
| 1 | Union Station | `union-station` | 43.6453, -79.3806 | geofenced |
| 2 | Gooderham Flatiron + Berczy Park | `gooderham-building` (+ `berczy-park`) | 43.6479, -79.3745 | geofenced |
| 3 | St. James Cathedral | `st-james-cathedral` (**new — owner-supplied**) | 43.6503, -79.3739 | geofenced |
| 4 | St. Lawrence Market | `st-lawrence-market` | 43.6488, -79.3715 | geofenced |
| 5 | Distillery District | `distillery-district` | 43.6503, -79.3599 | geofenced |

## Images (owner defaults 2026-06-30 — swap on request)
- **Walk hero:** `union-station_hero.webp` (the colonnade — matches the intro's "we start at the grandest front door it ever built"). Alternatives: Gooderham Flatiron (most iconic Old Town image) or Distillery lanes.
- **Per-stop `additionalImageURLs`** reuse the existing single-stop heroes already live on gh-pages — **no re-upload needed** except St. James:
  - stop 1 → `union-station_hero.webp`
  - stop 2 → `gooderham-building_hero.webp` (Berczy Park's dog fountain also available at `berczy-park_hero.webp`)
  - stop 3 → `st-james-cathedral_hero.webp` (**NEW this session** — owner-supplied shot: full spire + King/Church intersection; ship-safe)
  - stop 4 → `st-lawrence-market_hero.webp`
  - stop 5 → `distillery-district_hero.webp`
- **Efficiency note:** because 4 of 5 stops are already single-stop tours in the catalog, this walk mostly *reuses* their imagery. Only St. James Cathedral was newly added (owner-supplied). All reused images are ship-safe/owner; St. James is owner-supplied. **No new credits required for this walk.**

## Narrative callbacks
The walk is self-referential by design: the Gooderham Flatiron (stop 2) is set up as
the distilling family's head office, and stop 5 (the Distillery) pays it off ("this is
where their money came from"). Garrison Creek links stop 2's context to Trinity
Bellwoods + Fort York (other Toronto tours). St. Lawrence Market's "market that governed
a town" and St. James's "centre of everything" reinforce the founding-core theme.

## Wire-in checklist (at audio arrival)
1. Create **Atlas Studio YYZ** maker (first Toronto wire-in — applies to all staged Toronto singles too).
2. Add one `multiStop` tour entry to `Tours.json`: 5 stops in order, each geofenced/radius 40, intro as stop 0 manual, `introAudioURL: null`.
3. `totalDurationSeconds` = Σ stop durations (read via mutagen); centroid = avg stop coords; `walkingDistanceMeters` ≈ 2300 (refine if desired).
4. `additionalImageURLs` = the 5 stop hero URLs above; `heroImageURL` = union-station hero (or owner's swap).
5. Run `swift scripts/validate-tours.swift` (multiStop kind + geofenced triggers).

**Blocked on:** (1) narration MP3s (intro + 5 stops = 6 files); (2) the Atlas Studio YYZ maker.

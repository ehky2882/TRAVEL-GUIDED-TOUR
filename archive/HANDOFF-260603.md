# Atlas — Handoff Notes (2026-06-03, session 18)

Web/PM session — 18 new NYC audio tours added (catalog 113 → 131, NYC 73 → 96),
plus two CI-breaking validator bugs discovered and fixed. No Swift or asset changes.
TestFlight build unchanged at **1.0 (25)**.

---

## What happened this session

### NYC content batch — 18 tours across 10 commits

All tours are Atlas Studio NYC (`00000000-0000-0000-0000-000000000001`), single-stop
unless noted, `triggerMode: "geofenced"`. Audio to `gh-pages`, JSON via clean
`content/tours-XXX-YYY` branches squash-merged to main.

| Tours | Title(s) | Category | Duration |
|-------|----------|----------|----------|
| 114–115 | Four Freedoms Park · Green-Wood Cemetery | architecture · history | 132s · 149s |
| 116–117 | African Burial Ground National Monument · Cooper Union Foundation Building | history · architecture | 138s · 139s |
| 118 | Tompkins Square Park | history | 132s |
| 119–120 | Museum of Modern Art (MoMA) · Bryant Park | visualArt · history | 118s · 122s |
| 121 | Fifth Avenue Walk (multi-stop, 6 stops + intro) | architecture | ~9m total |
| 122–123 | Federal Hall · Columbus Park, Chinatown | history · culturalHeritage | 120s · 121s |
| 124–125 | Schomburg Center for Research in Black Culture · Coney Island | culturalHeritage · history | 136s · 130s |
| 126–127 | Eldridge Street Synagogue · Grand Army Plaza, Brooklyn | sacredSites · architecture | 121s · 119s |
| 128–129 | Grand Concourse · Strivers' Row | architecture · culturalHeritage | 137s · 135s |
| 130–131 | IAC Building · The Strand Bookstore | architecture · literature | 121s · 125s |

Fifth Avenue Walk (tour 121) is the catalog's second multi-stop tour: 6 stops on 5th Ave
from 82nd to 59th Street, intro audio + one stop per block of content (The Met, Guggenheim,
Neue Galerie, Cooper Hewitt, Apple Fifth Avenue, Grand Army Plaza). `introAudioURL` set;
`kind: "multiStop"`.

### Two validator bugs found and fixed

CI failed on every content PR from tour 114 onward. Two separate typos in the JSON enums:

1. **`triggerMode: "geofence"` → `"geofenced"`** — 23 stops across tours 114–131.
   Swift `StopTriggerMode` enum uses `case geofenced`; the trailing `d` was missing.
   Fixed in [PR #125](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/125),
   commit `3235d33`.

2. **`kind: "multi"` → `"multiStop"`** — Fifth Avenue Walk (tour 121).
   Swift `TourKind` enum uses `case multiStop`; used `"multi"` instead.
   Fixed in [PR #126](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/126),
   commit `7c11003`.

Full enum audit run at session end — all 131 tours pass. Valid enum raw values:
- `triggerMode`: `"manual"` | `"geofenced"`
- `kind`: `"single"` | `"multiStop"`
- `primaryCategory`: `"history"` | `"architecture"` | `"visualArt"` | `"musicAndPerformance"` | `"literature"` | `"foodAndDrink"` | `"natureAndParks"` | `"hiddenGems"` | `"culturalHeritage"` | `"sacredSites"`

---

## State at session end

- **Catalog:** 131 tours, 3 makers (96 NYC + 30 Atlas Studio Porto + 5 Atlas Studio Lisbon)
- **NYC goal:** 96 / 100 — **4 more tours needed**
- **CI:** latest main `7c11003` was in-progress at session end; should be green (both enum bugs fixed, full audit clean)
- **TestFlight:** 1.0 (25), unchanged — no build bump this session
- **gh-pages audio:** all 18 new MP3s pushed; last gh-pages commit `eb7cfec`

---

## Parked / what's next

### 4 NYC tours to 100

Owner declined large-area suggestions (parks, neighborhoods). Presented 8 single-vantage
candidates; owner to pick 4 to record:

| # | Tour | Story angle |
|---|------|-------------|
| 1 | United Nations | Le Corbusier + Niemeyer + Harrison; postwar world-peace dream in glass and marble |
| 2 | Jefferson Market Library | 1877 Victorian Gothic courthouse saved from demolition, converted to library |
| 3 | Haughwout Building | 1857 cast iron, first passenger safety elevator (Otis) |
| 4 | New York Stock Exchange | 1903 Corinthian temple; Wall Street as a literal Dutch wall |
| 5 | Tweed Courthouse | $250k budget, $13m actual cost; now a landmark interior |
| 6 | Municipal Building | McKim Mead & White 1914, straddling Chambers St; Stalin copied it |
| 7 | Delmonico's | America's first proper restaurant; invented the business lunch + Eggs Benedict |
| 8 | The Puck Building | 1885 Romanesque Revival; last survivor of the prewar publishing district |

Owner's implicit preference: United Nations, Jefferson Market Library, Tweed Courthouse,
Delmonico's — but they hadn't confirmed picks at session end.

### Other parked items (from earlier sessions)

- **PR #93 part 2** — stop-row timeline + thumbnails + animated `waveform` now-playing + non-modal playback start
- **M-qa items 6+7** — AMNH Four Facades geofence walk on device
- **Dynamic Type** — `AtlasTypography.body` is fixed-size `Font.system(size: 15)`, noted in code comment

---

## How to resume

1. `git fetch && git status && git log origin/main..HEAD` — tree should be clean on main.
2. Check CI on `7c11003` is green (Actions tab on GitHub).
3. If recording 4 more NYC tours: upload MP3 + script pairs, follow the content-batch
   workflow in CLAUDE.md. Use `"triggerMode": "geofenced"` and `"kind": "single"`.
4. After reaching 100 NYC tours: consider a TestFlight build bump to ship the catalog milestone.

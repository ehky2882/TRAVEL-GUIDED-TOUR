# Authoring Atlas tours

How to write the metadata for a tour — every field explained, the
small decisions called out, the gotchas surfaced. Paired with
`docs/Tours.template.json`, which shows the same fields filled in
with realistic placeholder content.

> **Two audiences, one guide.** Today the only person editing tour
> content is the Atlas team (i.e. you, by hand-editing
> `TRAVEL GUIDED TOUR/Resources/Tours.json`). Post-V1, outside
> makers will fill in the same fields through an in-app or web
> form. This guide is deliberately phrased UI-agnostically — every
> "every tour needs X" sentence below maps to a future form input
> with that same label and help text.

---

## The shape of a tour

Three levels nest inside each other:

```
Maker ─┐
       └── Tour ─┐
                 └── Stop (one for a single-piece, several for a walking tour)
```

- A **Maker** is the person or studio behind a tour (display name + bio).
- A **Tour** is one experience — either a single short audio piece at one location, or a multi-stop walking tour. Every tour is owned by one maker.
- A **Stop** is one geo-located audio clip inside a tour. A single-piece tour has exactly one stop; a multi-stop tour has 2–8 (no hard cap, but past 8 stops listeners drift).

The live data file is `TRAVEL GUIDED TOUR/Resources/Tours.json` —
one JSON object with two arrays: `makers` and `tours`. Stops are
nested inside each tour.

---

## Maker — fields

| Field | Required? | What it is |
|---|---|---|
| `id` | Yes | A UUID. Generate once per maker, never change it. See "Generating UUIDs" below. |
| `displayName` | Yes | The name shown on the maker page and as the byline on every tour. 1–40 characters. Real name or studio name; "Atlas Studio" for in-house content. |
| `avatarURL` | No (`null` ok) | Headshot or logo. Square. Hosted on the CDN (see "Audio + image URLs" below). |
| `bio` | Yes | 1–3 sentences in the maker's own voice. Who they are, what they make, why their tours are worth 20 minutes of someone's ears. Avoid CV bullets. |
| `websiteURL` | No (`null` ok) | Personal site or studio site. Currently not surfaced in the UI but stored for post-V1 maker page polish. |

---

## Tour — fields

| Field | Required? | What it is |
|---|---|---|
| `id` | Yes | A UUID. Generate once per tour, never change it. |
| `title` | Yes | 30–60 characters. Action-flavored or evocative. No trailing punctuation. Examples: "The Cooper Hewitt Facade", "Walking the High Line". Avoid "A Tour Of…" boilerplate. |
| `shortDescription` | Yes | One sentence, ~80–140 characters. Appears in feeds and rail cards. State the duration or stop count up front — "Three stops along an elevated park…" |
| `longDescription` | Yes | 2–4 paragraphs. Appears on the tour detail screen above the stop list. Cover: what the tour is, where it happens, who would enjoy it, any practical notes (good shoes, indoor/outdoor, time of day). |
| `makerId` | Yes | The `id` of the maker (from the `makers` array) who made this tour. Foreign key. |
| `heroImageURL` | Yes | The big image at the top of the tour detail screen. Landscape orientation, ≥ 1600px wide. Hosted on the CDN. |
| `additionalImageURLs` | No (omit or `null` ok) | Optional array of extra landscape images for a carousel below the hero on the tour detail screen. Same size guidance as `heroImageURL`. Order matters — index 0 shows first after the hero. Leave the field out entirely if the tour has only a hero. |
| `kind` | Yes | Either `"single"` (one location, one audio clip) or `"multiStop"` (a walking tour). Drives UI affordances — e.g., walking distance only shows for multi-stop. |
| `stops` | Yes | Array of stops (see Stop fields below). `single` tours have exactly 1; `multiStop` tours have 2 or more. |
| `introAudioURL` | No (`null` ok) | Optional 30–90s clip that plays before stop 1. Use for orientation: "We're going to be walking from X to Y, here's why I picked these three buildings…" |
| `totalDurationSeconds` | Yes | Sum of every `audioDurationSeconds` across stops plus the intro. Compute once, paste in. |
| `walkingDistanceMeters` | `null` for single; required for multiStop | Total walking distance between stops, in meters. Roughly: open Google Maps Directions in walking mode, sum the leg distances. |
| `centroidLatitude` / `centroidLongitude` | Yes | The "center point" of the tour. For single-piece, equals the one stop's coords. For multi-stop, the average of the stop coords is fine — it's used for sorting tours by distance, not for navigation. |
| `city` | No (`null` ok) | Free text — "New York", "Lisbon", "Edinburgh". Currently used for display; post-V1 may anchor a "Tours in [city]" rail. |
| `primaryCategory` | Yes | One of the values in the Categories table below. Drives the interest-based home rails. |
| `tags` | Yes (can be empty `[]`) | Free-text secondary themes. Lowercase, 1–4 words each. Examples: `"walking tour"`, `"gilded age"`, `"hidden gems"`. Not surfaced as filters in V1 but feeds the search index. |
| `priceUSD` | Yes (`0` for V1) | Always `0` in V1 — all launch content is free. Field exists so paid tours can ship post-V1 without a data migration. |

---

## Stop — fields

| Field | Required? | What it is |
|---|---|---|
| `id` | Yes | A UUID. Generate once per stop, never change it. |
| `order` | Yes | 0-indexed position in the tour. First stop is `0`, second is `1`, etc. Don't skip numbers. The player uses this to advance "next stop." |
| `title` | Yes | What this stop is called. 1–60 characters. Often the name of the place ("The Bronze Doors") or the moment ("Where Whitman Stood"). |
| `caption` | No (`null` ok) | One-line orientation: where to stand, what to look at. Shows in the player UI underneath the stop title. Examples: "Stand on the east sidewalk facing west", "Inside the rotunda, look up." |
| `latitude` / `longitude` | Yes | Decimal degrees, six decimal places of precision is plenty. Negative for west longitude / south latitude. See "Finding coordinates" below. |
| `audioURL` | Yes | The audio file for this stop. See "Audio + image URLs" below. |
| `audioDurationSeconds` | Yes | The duration of the audio clip in seconds. Compute from the actual recording. The player uses this for the scrub bar before audio loads. |
| `triggerMode` | Yes | Either `"geofenced"` or `"manual"`. See "Choosing trigger mode" below. |
| `triggerRadiusMeters` | Yes | Integer. 30 is a sensible default. See "Choosing trigger radius" below. |
| `imageURL` | No (`null` ok) | Optional image shown for this specific stop. Useful when listeners might not know what they're looking at (a small detail, an obscured plaque). |
| `transcriptText` | No (`null` ok) | Full text of the audio. Supports VoiceOver users; also makes content searchable. Post-V1, may anchor a "read instead of listen" mode. |

---

## Field reference — practical guidance

### Generating UUIDs

A UUID is a 36-character string like `550e8400-e29b-41d4-a716-446655440000`. Each one must be unique across all makers, tours, and stops.

Easy ways to generate one:

- **macOS Terminal:** `uuidgen` (returns one UUID per command).
- **Online:** [uuidgenerator.net](https://www.uuidgenerator.net/) — refresh for a new one.
- **iPhone Shortcuts:** add the "Generate UUID" action.

The seed file uses padded `00000000-0000-0000-0000-…` UUIDs for legibility. For real content, generate fresh real ones — don't reuse template IDs.

### Finding coordinates

The most painless flow:

1. Open **Google Maps** on desktop.
2. Right-click the exact spot where the listener should be standing.
3. The first item in the right-click menu is the coordinates (e.g. `40.7843, -73.9572`) — click to copy.
4. The first number is `latitude`, the second is `longitude`.

For indoor stops (museum exhibit, building interior), drop the pin on the entrance and use `triggerMode: "manual"` — see below.

### Choosing trigger mode

- **`"geofenced"`** — the app starts the audio automatically when the user crosses into the stop's radius. Use for outdoor walking tours where GPS is reliable.
- **`"manual"`** — the user taps "Play stop X" themselves. Use when GPS is unreliable (indoor, dense urban canyon, underground), when stops are very close together (< 50m apart), or when the listener should choose the moment (church, gallery, quiet room).

When in doubt, pick `"manual"` — surprise auto-play in a quiet space is worse than a tap.

### Choosing trigger radius

`triggerRadiusMeters` defines a circle around the stop's coordinate. Once the user steps inside, the audio fires.

- **30m** is the default and right for most outdoor stops — gives the listener time to find the spot before the audio reaches the "stand here and look at…" line.
- **15–20m** for stops < 50m apart (avoid one geofence overlapping the next).
- **40–50m** for large buildings where the listener might approach from any side.

### Audio + image URLs

Every `audioURL`, `heroImageURL`, `imageURL`, `avatarURL` is an HTTPS URL pointing to a file on the CDN. The CDN host is a separate decision — see `ROADMAP.md` post-V1 / M-launch-content notes.

**Until the CDN is chosen**, the placeholder convention is `https://atlas-tours.example/...` — these URLs deliberately don't resolve, so the app falls back to the placeholder UI. That lets you preview the catalog shape in the simulator before any real audio is hosted.

**File format:** MP3, 128 kbps mono is plenty for spoken audio (~1MB per minute). Higher bitrates waste bandwidth on download-for-offline.

**Audio length guidance:**
- Single-piece tour: 2–5 minutes per audio clip.
- Multi-stop tour: 3–8 minutes per stop.
- Intro audio: 30–90 seconds.

Reading pace is ~150 words per minute, so a 3-minute clip ≈ 450 words of script.

### Categories

`primaryCategory` is one of:

| Value (use as-is in JSON) | Displays as |
|---|---|
| `history` | History |
| `architecture` | Architecture |
| `visualArt` | Art |
| `musicAndPerformance` | Music & Performance |
| `literature` | Literature |
| `foodAndDrink` | Food & Drink |
| `natureAndParks` | Nature & Parks |
| `hiddenGems` | Hidden Gems |
| `culturalHeritage` | Cultural Heritage |
| `sacredSites` | Sacred Sites |

Pick the single best fit. The home screen builds an interest-based rail per category; rails with zero matching tours are hidden, so don't worry about leaving some empty.

If you find yourself stretching to fit (e.g., a food + architecture walking tour), pick the one the listener is most likely to filter on. Secondary themes go in `tags`.

---

## Validating the JSON before committing

Before you commit an edited `Tours.json`, run the validator:

```bash
swift scripts/validate-tours.swift
```

(Run from the repo root. To validate a different file, pass its path
as the only argument.)

The validator decodes `Tours.json` against the live Swift data model
and runs every check below. Exit code 0 means clean; 1 means
errors; 2 means the file couldn't be parsed at all.

What it catches:

- **JSON syntax errors** (missing brackets, trailing commas).
- **Missing or mistyped fields** — every required field on every
  Maker / Tour / Stop, with a path like
  `[tours > 1 > stops > 0 > latitude]` for fast lookup.
- **Bad enum values** — `primaryCategory: "fakecategory"`,
  `kind: "single-stop"`, `triggerMode: "auto"`, etc.
- **Duplicate UUIDs** — across makers, across tours, and across
  stops globally.
- **Broken maker references** — a tour's `makerId` that doesn't
  match any maker in the `makers` array.
- **`kind` ↔ stop count mismatch** — `single` with ≠ 1 stop;
  `multiStop` with < 2 stops.
- **Stop `order` packing** — must be 0..<count, no gaps, no
  duplicates within a tour.
- **Coordinate ranges** — latitude in [-90, 90], longitude in
  [-180, 180].
- **Centroid sanity** — warns if the tour centroid is outside the
  bounding box of its stops (likely a copy-paste mistake).
- **Audio math** — `totalDurationSeconds` must cover the sum of
  stop durations; warns if they don't match exactly on a tour
  with no intro audio.
- **Sanity bounds** — `audioDurationSeconds > 0`,
  `triggerRadiusMeters > 0`, warns if radius is outside 5–500m.
- **URL validity** — every `heroImageURL`, `additionalImageURLs[]`,
  `audioURL`, `introAudioURL`, `imageURL`, `avatarURL`, `websiteURL`
  is a well-formed URL with a scheme + host. (Does NOT check that
  the URL resolves — placeholder `atlas-tours.example/...` URLs pass.)
- **Empty required text** — `title`, `bio`, `displayName`, etc.

What it doesn't (yet) catch:

- The validator is not wired into the Xcode build. Run it manually
  before committing, or add a git pre-commit hook:
  ```bash
  echo 'exec swift scripts/validate-tours.swift' > .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  ```
- It doesn't check that audio URLs actually resolve to playable
  files. That's a manual QA step before launch.

If you change the Swift data model (`Tour.swift`, `Stop.swift`,
`Maker.swift`, `TourCategory.swift`), update the matching mirror
types at the top of `scripts/validate-tours.swift` in the same
commit. The script has a comment near the top reminding you.

---

## Quick workflow — authoring a new tour by hand

1. Generate a UUID for the tour (`uuidgen` in Terminal).
2. Decide `kind` — single or multi-stop. Pick coords; if multi-stop, walk the route in Google Maps Directions and note the total distance.
3. Open `docs/Tours.template.json`, copy the closest example tour (single or multi-stop), paste into `TRAVEL GUIDED TOUR/Resources/Tours.json` inside the `tours` array.
4. Replace every field with real content. Strip the `_about` / `_comment` fields — they exist only in the template.
5. For each stop, generate a UUID and fill in fields. Use placeholder audio URLs (`https://atlas-tours.example/…`) until the CDN is chosen and audio is uploaded.
6. Write the script for each audio clip in a separate doc — record only after the script reads well.
7. Once recorded and uploaded, swap the placeholder URLs for real CDN URLs.
8. Validate (`python3 -m json.tool` or jsonlint), build, test in simulator.
9. Commit `Tours.json`.

---

## For the future in-app maker form

When a maker upload screen gets built (post-V1, Tier 1 in ROADMAP.md), every field above becomes a form input:

- "Required?" column → which inputs are mandatory vs optional.
- Field descriptions → input help text / placeholder text.
- Length guidance ("30–60 characters") → input validators.
- Decision sections (trigger mode, radius, audio length) → in-form hints, perhaps a "?" tooltip next to the input.
- Categories table → the dropdown choices.
- The validation checklist → server-side validation rules.

Treat this doc as the source of truth for the data contract; the UI is just a polished surface over it.

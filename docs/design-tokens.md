# Atlas — Design tokens summary

A single-sheet reference for the typographic hierarchy, color palette,
spacing scale, and icon vocabulary used across Atlas. Lives here as
the editable source of truth; the **values** themselves live in
`TRAVEL GUIDED TOUR/Theme/Atlas{Typography,Colors,Spacing}.swift`.

> **Status:** All values below are **placeholders pending the
> deferred design pass** (owner direction, May 2026). The *shape* of
> the system is locked; the *values* swap in a 3-file change.
> Discipline rule: views reach for tokens, never hardcoded literals
> (`AtlasColors.primaryText`, not `Color.black`).

---

## Typography hierarchy

Source: `Theme/AtlasTypography.swift`

Every slot maps to a SwiftUI system font today, so Dynamic Type works
and the visual hierarchy reads correctly. The custom brand face swaps
in at the design pass; call sites don't change.

| Token            | Current value                                                      | Size          | Typical use                                |
| ---------------- | ------------------------------------------------------------------ | ------------- | ------------------------------------------ |
| `largeTitle`     | `Font.largeTitle`                                                  | ~34pt         | Splash, top-of-screen hero titles          |
| `title`          | `Font.title`                                                       | ~28pt         | Section heroes, tour detail title          |
| `title2`         | `Font.title2`                                                      | ~22pt         | Sub-section heads                          |
| `title3`         | `Font.title3`                                                      | ~20pt         | Card titles, rail headers                  |
| `headline`       | `Font.headline`                                                    | ~17pt semibold | Emphasized list rows, buttons            |
| `body`           | `Font.system(size: 15, weight: .regular, design: .default)`        | **15pt SF Pro regular** | Default paragraph copy. **Fixed-size — Dynamic Type does not scale this token** (accepted tradeoff; future pass can switch to `Font.system(size:relativeTo:)`) |
| `callout`        | `Font.callout`                                                     | ~16pt         | Secondary inline copy, chips               |
| `caption`        | `Font.system(size: 13, weight: .regular, design: .monospaced)`     | **13pt SF Mono regular** | Small metadata copy — chip text, mini-player subtitle, tab bar labels, stop durations, search-bar placeholder, detail subtitle line. Monospaced face gives small-metadata copy a distinct editorial voice. |
| `captionSerif`   | `Font.caption` (slot reserved)                                     | ~12pt SF Pro  | Editorial captions on tour detail; intentionally NOT the same value as `caption` — placeholder pending a paired serif at the design pass |

**History note.** The pre-PR-#22 version aliased every slot to
`Helvetica 12pt`, collapsing all hierarchy (audit P0-3). PR #22
promoted each slot to its SwiftUI system equivalent; PR #113 (session
17) differentiated `body` (15pt SF Pro, fixed-size) and `caption`
(13pt SF Mono regular) from the generic SwiftUI semantics.

---

## Color palette

Source: `Theme/AtlasColors.swift`

Every token is adaptive — resolves to a SwiftUI semantic color or
platform-system color so light and dark mode both render correctly.
(Audit P0-2 caught the prior version, which used literal
`Color.black` / `Color.white` and was unreadable in dark mode.)

### Brand

| Token         | Value                               | Notes                                                                                                                          |
| ------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `accent`      | `Color.accentColor`                 | Mirrors `Assets.xcassets/AccentColor.colorset` — **terracotta `#B85042`** light mode, lighter variant dark mode. Placeholder. |
| `accentLight` | `Color.accentColor.opacity(0.6)`    | Secondary accent — e.g. disabled accent states.                                                                                |
| `mapPin`      | `Color(red: 139/255, green: 117/255, blue: 53/255)` | **Dark gold `#8B7535`** — map pin fill. Separate from `accent` so pin styling can diverge from interactive-element tinting without a global accent change. |

### Text — three-step hierarchy

| Token           | Value                            | Adapts via                                              |
| --------------- | -------------------------------- | ------------------------------------------------------- |
| `primaryText`   | `Color.primary`                  | iOS semantic — black in light, white in dark.           |
| `secondaryText` | `Color.secondary`                | iOS semantic — muted gray, both modes.                  |
| `tertiaryText`  | `Color.secondary.opacity(0.6)`   | Further-muted layer for metadata.                       |

### Surfaces (platform-conditional)

| Token                    | iOS / iPadOS / visionOS         | macOS                          |
| ------------------------ | ------------------------------- | ------------------------------ |
| `background`             | `.systemBackground`             | `windowBackgroundColor`        |
| `secondaryBackground`    | **Hardcoded RGB** — light `#F2F2F7` / dark `#1C1C1E`. NOT `.secondarySystemBackground`. The system semantic resolves differently at `.base` vs `.elevated` UIKit window levels, which caused a visible chrome seam between the detail body (window 1) and bars (window 2) in dark mode. Hardcoded pair removes the elevation variance. | `underPageBackgroundColor`     |
| `miniPlayerBackground`   | Alias of `secondaryBackground` | —                              |
| `tabBarBackground`       | Alias of `secondaryBackground` | —                              |
| `cardBackground`         | `.systemBackground`             | `windowBackgroundColor`        |
| `placeholderWarm`        | `.tertiarySystemFill`           | `tertiaryLabelColor @ 0.3`     |
| `placeholderCool`        | `.tertiarySystemFill`           | `tertiaryLabelColor @ 0.3`     |
| `divider`                | `.separator`                    | `separatorColor`               |
| `cardShadow`             | `Color.black.opacity(0.12)`     | Same — nearly imperceptible in dark mode (correct). |

---

## Spacing & shape

Source: `Theme/AtlasSpacing.swift`

| Token                      | Value  | Use                                                                                      |
| -------------------------- | ------ | ---------------------------------------------------------------------------------------- |
| `xs`                       | 4pt    | Tight stacks, chip padding                                                               |
| `sm`                       | 8pt    | Inline gaps                                                                              |
| `md`                       | 16pt   | Default content padding                                                                  |
| `lg`                       | 24pt   | Section padding                                                                          |
| `xl`                       | 32pt   | Major spacing                                                                            |
| `xxl`                      | 48pt   | Hero spacing                                                                             |
| `heroHeight`               | 320pt  | Tour detail hero image height                                                            |
| `cardCornerRadius`         | 12pt   | Tour cards                                                                               |
| `chipCornerRadius`         | 20pt   | Filter chips (Home)                                                                      |
| `phoneScreenRadius`        | **56pt** | Floating-island drawer bottom + tab bar bottom corners. Slightly larger than device bezel radius so the island reads as generously rounded. |
| `searchBarHeight`          | **44pt** | Home search bar height and category chip row height. Matches Apple's 44pt HIG tappable-target minimum and the floating map control button diameter — all interactive home-map elements share one 44pt vertical footprint. |
| `searchAndChipsBlockHeight`| **108pt** | Combined height of the home screen's search-bar + chip-row block (`sm + searchBarHeight + sm + searchBarHeight`). Drawer `.large` detent reserves this at the top so search/chips remain visible when fully expanded. |

**Shape (BottomSheet defaults, not in `AtlasSpacing` but documented here):**

| Token                      | Value | Use                                                                       |
| -------------------------- | ----- | ------------------------------------------------------------------------- |
| `BottomSheet.topCornerRadius`    | **28pt** | Drawer's top corner radius. Softer than square but well short of the phone-radius bottom. |
| `BottomSheet.bottomCornerRadius` | `phoneScreenRadius` (56pt) | Matches the phone screen's bottom curve so drawer + tab bar read as one continuous pill. |

---

## Icons — SF Symbols only

No custom glyphs in V1; everything is an Apple SF Symbol.

### Tab bar — `Components/AtlasTabBar.swift`

| Tab     | Unselected            | Selected                   |
| ------- | --------------------- | -------------------------- |
| Home    | `house`               | `house.fill`               |
| Library | `bookmark`            | `bookmark.fill`            |
| Me      | `person.crop.circle`  | `person.crop.circle.fill`  |

### Tour categories — `Models/TourCategory.swift`

Drives the home filter chip row and the category badge on each tour
list card. Closed enum so the home rails are reliable.

| Case                   | Icon                | Display name          |
| ---------------------- | ------------------- | --------------------- |
| `.history`             | `building.columns`  | History               |
| `.architecture`        | `building.2`        | Architecture          |
| `.visualArt`           | `paintpalette`      | Art                   |
| `.musicAndPerformance` | `music.note`        | Music & Performance   |
| `.literature`          | `book`              | Literature            |
| `.foodAndDrink`        | `fork.knife`        | Food & Drink          |
| `.natureAndParks`      | `leaf`              | Nature & Parks        |
| `.hiddenGems`          | `sparkles`          | Hidden Gems           |
| `.culturalHeritage`    | `globe`             | Cultural Heritage     |
| `.sacredSites`         | `moon.stars`        | Sacred Sites          |

### Functional icons (in-context)

| Surface       | Icon                                                                                          | Meaning                          |
| ------------- | --------------------------------------------------------------------------------------------- | -------------------------------- |
| Player        | `backward.fill` / `forward.fill`                                                              | Skip stop                        |
| Player        | `play.fill` / `pause.fill`                                                                    | Transport                        |
| Player        | `speaker.fill` / `speaker.wave.2.fill`                                                        | Mini-player state                |
| Player        | `exclamationmark.triangle.fill`                                                               | Playback failure banner          |
| Tour detail   | `bookmark` / `bookmark.fill`                                                                  | Save toggle                      |
| Tour detail   | `arrow.down.circle` / `stop.circle` / `checkmark.circle.fill` / `exclamationmark.circle`     | Download state machine           |
| Tour detail   | `person.crop.circle` + `chevron.right`                                                        | Maker attribution row            |
| Home          | `magnifyingglass`                                                                             | Search affordance                |
| Home          | `location.fill`                                                                               | Recenter map button              |
| Home / Library| `clock` / `clock.arrow.circlepath`                                                            | Duration, recent searches        |
| Library       | `arrow.down.circle.fill`                                                                      | Downloaded badge                 |
| Search        | `xmark.circle.fill`                                                                           | Clear field                      |
| Maker         | `link`, `arrow.up.right`                                                                      | Website / external link          |
| Lists         | `chevron.right`                                                                               | Row affordance                   |

### Map pins

Custom SwiftUI views — `StopPin` and `ClusterPin` — in `Features/Home/HomeMapSection.swift`. Color is `AtlasColors.mapPin` (dark gold `#8B7535`) throughout. **Custom terracotta pins with category / maker glyphs are deferred to `M-polish-pins`.**

| Element      | State / count | Size                          | Notes                                                      |
| ------------ | ------------- | ----------------------------- | ---------------------------------------------------------- |
| `StopPin`    | unselected    | 16pt diameter                 | White stroke 1.5pt                                         |
| `StopPin`    | selected      | 20pt diameter                 | White stroke 3pt; pops above neighbors without shifting density |
| `ClusterPin` | 1–9 stops     | 26pt inner / 36pt outer circle | Count label: SF Mono regular 12pt white (`Font.system(size:12, weight:.regular, design:.monospaced)`) |
| `ClusterPin` | 10–99 stops   | 30pt inner / 40pt outer circle | Same label style                                           |
| `ClusterPin` | 100+ stops    | 34pt inner / 44pt outer circle | Same label style                                           |

### App icon

Still the empty Apple template in
`Assets.xcassets/AppIcon.appiconset`. Replaced in `M-polish-icon`.

---

## Where the deferred design pass plugs in

When the brand pass happens, the swap is three files:

1. **`AtlasTypography.swift`** — replace each `Font.xxx` with
   `Font.custom("BrandFace-Weight", size: ...)`. Stick close to the
   current point sizes so Dynamic Type scaling stays well-behaved.
   Optionally pick the paired serif for `captionSerif`.
2. **`AtlasColors.swift`** — replace `Color.primary` / `.secondary`
   and the platform-system surfaces with brand colorsets defined in
   `Assets.xcassets` (so both light and dark variants come from the
   asset catalog).
3. **`Assets.xcassets/AccentColor.colorset`** — drop the new accent
   in. `AtlasColors.accent = Color.accentColor` picks it up
   automatically.

The polish milestones that consume this doc:

- `M-polish-theme` — the three-file swap above.
- `M-polish-pins` — custom map pin design + glyph.
- `M-polish-icon` — real Atlas app icon.
- `M-polish-player` — Player UI gets its own design pass after the
  rest of the system is decided.

---

## Editing rules

- This doc is the **editable surface**. Treat it as the source of
  truth for what the design system *contains*. When the design pass
  picks real values, update both this doc and the matching
  `Theme/Atlas*.swift` file in the same commit.
- If a new token gets added in `Theme/`, add a row here too. If a
  token is renamed or removed, update both places.
- The Swift files are also the source of truth for **call sites** —
  views import the tokens from there, not from this doc.

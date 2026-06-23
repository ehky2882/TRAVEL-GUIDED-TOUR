# HANDOFF — bridge note for the next tour-detail-sheet session

**Written 2026-06-22.** The work described below shipped **2026-06-03** in a
session that then went dormant for ~3 weeks. Owner is now spawning a fresh
session to iterate on the tour detail sheet again. This is a topical bridge
note, not a session-end snapshot — for the broader project state, read
`archive/HANDOFF-260621.md` and `CLAUDE.md § Current State` first.

## What's already shipped on the tour detail sheet (PR #135 + #136)

| Surface | State |
|---|---|
| **Stops list** | Whole row is a `Button` calling `playStop(_:)`. Leading column: stop number, or animated `waveform` SF Symbol in `AtlasColors.mapPin` when this stop is the audible source. No trailing play/pause affordance (removed mid-iteration). |
| **Primary "Start Tour" button** | NOT a system `.borderedProminent`. Custom `Capsule(fill: AtlasColors.mapPin)`, exactly 44pt tall. Content is a 3-zone transport bar: `[pause/play icon, 20pt semibold white] · [scrubbable linear progress bar, white fill on white-25% track] · [time-remaining text, caption monospaced]`. Icon and time text are tappable (play/pause); bar handles `DragGesture(minimumDistance: 0)` for scrub and commits via `audioPlayer.seek(to:)`. |
| **Save + Download buttons** | 44×44 Capsules with `AtlasColors.mapPin.opacity(0.15)` fill and 20pt regular `mapPin` SF Symbols. |
| **Top chrome row** | System toolbar **hidden** via `.toolbar(.hidden, for: .navigationBar)`. Custom in-body row via `.safeAreaInset(.top)`: three discrete 44pt Capsules (X close, Save, overflow `…`), 20pt regular `primaryText` SF Symbols, neutral `AtlasColors.tertiaryText.opacity(0.18)` Capsule fill. Backdrop = `.regularMaterial` + `AtlasColors.secondaryBackground.opacity(0.8)` tint (translucent body-color match). |
| **Masthead** | Title: `body` font, **uppercased**. Maker row: caption font, name only (no "by ", no avatar SF Symbol), `secondaryText` color. Stops section header: `secondaryText` (was tertiary). VStack spacing 0; the visible 4pt gap above/below the maker row comes from `makerRow`'s own `.padding(.vertical, AtlasSpacing.xs)` (kept inside the NavigationLink tap zone). |
| **Description** | Truncates to 4 lines with inline "Read more" / "Show less" toggle. Toggle only renders when `longDescription.count > 240`. |
| **Button row spacing** | 24pt visible above and below the action row (`.padding(.vertical, AtlasSpacing.sm)` on top of VStack's `md`). |
| **`AtlasFormatters.duration(seconds:)`** | Sub-hour durations now include seconds: 119s → "1m 59s". `hourMinuteFormatter` keeps the one-hour-plus path as `"1 hr 25 min"`. |

## Other shipped tweaks (PR #136, same day)

- **Portugal flag emoji** on Atlas Studio Porto + Atlas Studio Lisbon makers (`Tours.json`, picks up automatically via MiniPlayerBar's avatar resolution).
- **Splash refresh**: `AtlasColors.mapPin` 44pt circle (was placeholder green 24pt); `"Atlas"` SF Mono → **`"Dozent"`** in iOS New York serif at **15pt** regular, 2pt tracking.
- **Drawer images square-corner**: removed outer `.clipShape(RoundedRectangle…)` on `TourListCard`; `cornerRadius: 0` on `HomeDrawerContent` quick-resume banner thumbnails and `RailCarousel` hero (rails currently unused).
- **Search bar tap retracts the drawer** to `.peek` from `.medium`/`.large` via `.simultaneousGesture(TapGesture())` on the SearchBar call site in `HomeView`.

## Parked for a future iteration (with context)

| Item | Where it stands |
|---|---|
| **Gradient fade on the chrome row's bottom edge** | Owner wanted the hard chrome/body boundary softened. Tried fading the chrome's bottom downward into the body — owner said "fade should work up, not down". Tried the inverse: solid chrome bottom + body content faded upward (mask on `scrollBody`) so content disappears before reaching the chrome. Owner: "forget the fade for now, will come back to it." Currently the chrome has a hard bottom edge with the layered material + tint backdrop. |
| **`TourListCard.formattedDuration`** ([Features/Home/TourListCard.swift:151](TRAVEL%20GUIDED%20TOUR/Features/Home/TourListCard.swift)) | Local helper bypasses `AtlasFormatters.duration` and integer-divides by 60. Home drawer card reads `1 min` for a 1m 59s tour while the detail sheet reads `1m 59s`. One-line fix to route through `AtlasFormatters.duration`. **Left as-is** because home is in the CLAUDE.md "settled / don't change" list and owner didn't OK touching it on June 3. |
| **TestFlight upload automation** | Memory file at `~/.claude/projects/-Users-EY/memory/todo-testflight-upload-automation.md`. Owner asked for full archive-and-upload automation but it requires a one-time 5-min App Store Connect API key setup. Today's flow is still: Claude archives, owner uploads via Organizer. |

## Important caveat for the next session

This bridge note describes the **June 3 shipped state**. Between then and 2026-06-22, the repo gained:
- **Atlas Studio HKG** + 38 Hong Kong tours (catalog: 138 → 307 tours, 3 → 5 makers).
- The full **V2 backend design pass** — Supabase schema, accounts/auth, maker dashboard, moderation. Docs + non-shipping SQL only; nothing in the app yet.
- An open London batch 4 wire-up PR (#231).

`Features/Tour/TourDetailView.swift` **may have been touched** since by other sessions. **Re-read the file cold** at session start — don't assume the June-3 mental model is still current.

## Convention reminders (memory)

- Owner's working style: one decision at a time, tables over prose, "(Recommended)" option listed first in `AskUserQuestion`, never proceed if the dialog is dismissed without an answer.
- UI terminology: when owner uses plain-language UI descriptions, reflect back with the *INDUSTRY TERMS* asterisked.
- Visual debugging for chrome / overlay / seam bugs: paint each surface a distinct bright color first; owner points at the bad boundary.
- Design rule: buttons identical everywhere across surfaces; same shape, same hit zone, only fill differs.

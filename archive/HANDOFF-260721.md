# HANDOFF — 2026-07-21 (session 66, code, web)

**Maker tour list + grid now distinguish multi-stop walks from single stops — brass WALK pill + stop count. Shipped in TestFlight 1.1 (29) (list) and 1.1 (30) (list + grid).**

## What & why

Owner, with a screenshot: *"When in the Maker page, the tour list doesn't distinguish between single stops and multi stops. What's a good way to distinguish these? Because the icons are so small."* Real — two same-named **The Jordaan** tours (a 2m 43s single stop and a 12m 39s multi-stop walk) were indistinguishable in the maker tour list; only the duration hinted at the difference.

Flow: suggested options → built an **HTML mock** (sent as a file, not published — owner rejected the Artifact publish, so `SendUserFile` with `display: render`) of "Option 1 + 2" (a brass WALK pill + a stop count in the subtitle) → owner approved → implemented list → owner asked for the grid too → implemented grid. Words over tiny glyphs was the guiding call.

## Changes — one file, `Features/Maker/MakerView.swift`

**List view — [PR #413](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/413) (`ac6e421`), TestFlight 1.1 (29):**
- New `walkPill` — a `Text("WALK")` capsule that **mirrors `statusBadge`'s exact shape** (font `.system(size: 9, weight: .semibold)`, `foregroundStyle(AtlasColors.background)`, `.padding(.horizontal, 6).padding(.vertical, 2)`, `Capsule()`) but in `AtlasColors.accent` (`#8B7535`). `.fixedSize()` + `.accessibilityLabel("Multi-stop walk")`. Because the pill text is `AtlasColors.background`, it flips white/black with the theme just like the status badge.
- `tourRow`'s subtitle became an `HStack(spacing: AtlasSpacing.xs)` — `walkPill` (only when `tour.kind == .multiStop`) then the subtitle `Text` (now `.truncationMode(.tail)`). Fixed-size pill → the `Text` truncates first, so the distance drops off the end before the pill/count on long titles.
- `subtitleText(_:)` rewritten to build `[String]` parts: prepend `"N stop(s)"` **only for `.multiStop`**, then duration, then distance-away when a location fix exists. Single-stop output is byte-for-byte unchanged (`2m 43s · 1.2 mi away`); multi-stop reads `6 stops · 12m 39s · 1.2 mi away`.

**Grid view — [PR #414](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/414) (`ed4daa9`), TestFlight 1.1 (30):**
- The Instagram-style tiles in `toursGrid` are image-only, so walks were invisible there. Added a second `.overlay(alignment: .topLeading)` rendering `walkPill` when `tour.kind == .multiStop`, with `.shadow(color: .black.opacity(0.25), radius: 2, y: 1)` to lift it off busy photos and `.padding(AtlasSpacing.xs)`. **Top**-leading keeps it clear of the existing **bottom**-leading Draft/In-review `statusBadge` overlay. Single-stop tiles carry no pill.

No data-model / API / backend change — reads `tour.kind` + `tour.stops.count`, already in the catalog. Grid tiles otherwise untouched; single-stop rows/tiles untouched.

## Verification

- Both PRs green on `ci.yml` (Validate Tours.json + Build (iOS Simulator) + Run unit tests — the `test_sim` stand-in; no Mac in a web session).
- `testflight.yml` `workflow_dispatch` on the branch built + signed + uploaded **1.1 (29)** (run #29793587684, list only) and **1.1 (30)** (run #29826515139, list + grid) — **both archived clean, no Apple-Development cert-cap snag** this session.
- Owner authorized both merges (squash). Merged via GitHub MCP after confirming all four checks green each time.
- **Device-eyeball owed:** grid-pill legibility over real hero photos in light + dark, and that it never collides with the status badge on the owner's own drafts. (Placeholder thumbnails in the mock, so real-photo contrast is the one judgment call left.)

## Git / process notes

- Designated branch `claude/tour-list-stop-distinction-kyk2xr`.
- After #413 merged, **restarted the branch fresh off `origin/main`** (`git checkout -B … origin/main`, then reapplied the grid edit and **force-with-lease** pushed) for the #414 follow-up — per the merged-branch rule, never stacked new commits on already-merged squash history.
- **Branch-delete owed:** the git proxy blocks branch deletion from web sessions → delete `claude/tour-list-stop-distinction-kyk2xr` in the GitHub UI (else it's swept as a stale merged `claude/*` branch).
- Parallel session landed **#415** on `main` while this ran (Amsterdam multi-stop walk fixes — gallery dedup + scrambled transcripts); untouched here. Note: the catalog now includes **Amsterdam** tours/maker, but this session left the docs' **Key facts** catalog counts alone — content sessions own recounting; my scope was the code.

## Next

Owner's call. This closes the maker-list/grid walk-distinction ask fully. Natural nearby follow-ups if wanted: the same WALK cue on other tour-list surfaces (Search results, Library, Home rails) for consistency; or a `N STOPS`-only pill variant if the owner later prefers the count on the pill itself.

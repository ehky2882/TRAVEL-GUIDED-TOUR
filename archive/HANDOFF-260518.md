# Atlas — Handoff Notes

Snapshot of where the project is right now, plus things you can work
on from a non-local machine (no Xcode required). Read this from the
GitHub web UI to pick up at work tomorrow.

---

## Current state (as of last session)

### What's in `main`
Every V1 functionality milestone is shipped + a clean home-screen
redesign:

| Milestone | Notes |
|---|---|
| M1–M3 | App shell, location permission, theme tokens |
| M-data-model | Tour / Stop / Maker / LibraryEntry / etc. |
| M-audio-foundation | `AudioPlayerService` (AVQueuePlayer + lock screen) |
| M-tour-detail | `TourDetailView` (hero, maker, stops, action bar) |
| M-player | `PlayerView` modal sheet (scrub, transport, speed, auto-advance) |
| M-home | Map-dominant home + curated rails |
| M-search | `SearchView` + `RecentSearchStore` |
| M-maker | `MakerView` (avatar + bio + tour list) |
| M-library | Saved / Downloaded / Recently played |
| M-map | **CUT** (Home's embedded map covers it) |
| M-geofencing | GPS-triggered stop audio |
| M-offline | `TourDownloader` + Manage Downloads |
| Home redesign (PR #19) | Full-screen map, glass search bar, persistent bottom sheet |

### What's open / WIP
- **`claude/alltrails-alignment`** branch (not yet a PR) — has the
  AllTrails-style iteration: custom `AtlasTabBar`, integrated
  floating-island drawer + tab bar, filter chip row, vertical tour
  list, recenter button, etc. Branch is pushed; **needs a `git rebase
  main`** next local session to drop the now-redundant home-redesign
  commits (PR #19's content) before opening PR #20.

### What's left for V1
- **M-launch-content** — your content work. Record 5–15 tours,
  populate `Tours.json` with real audio URLs hosted on a CDN.
- **M-qa** — end-to-end sanity sweep on a real device. Verify
  lock-screen Now Playing widget + background geofence triggers.
- **AllTrails alignment polish** — finish iteration on
  `claude/alltrails-alignment`, open PR #20, merge.

### Known follow-ups (not blocking V1)
- Custom tab bar gives up system features (badges, focus animations).
  Easy to revisit post-V1.
- "Because you searched [X]" home rail not yet integrated into
  `HomeRailsViewModel` (data is captured, just not surfaced).
- `AudioPlayerService` doesn't aggregate progress across stops —
  `listenedSeconds` reflects position within current item only.
- Polish milestones from `ROADMAP.md` (theme, pins, player, icon,
  copy, final).

---

## Things you can work on remotely (no Xcode needed)

These are all editable from any browser via GitHub, or in any text
editor on a work computer. None require running the app.

### A. Content planning for M-launch-content

The biggest unblocked piece. Spec calls for 5–15 tours. Decisions you
can make sitting at a desk:

1. **Pick locations.** Spec suggests:
   - 2–3 single-location pieces (a piece of public art, a building
     facade, a specific exhibit) — short, 2–5 min each.
   - 2–3 multi-stop walking tours (neighborhood, architecture trail,
     small museum) — 15–30 min, 3–8 stops each.
   - Rest at whatever ratio you want.
2. **Map each tour to a `TourCategory`** (`Models/TourCategory.swift`).
   Closed set: `.history`, `.architecture`, `.visualArt`,
   `.musicAndPerformance`, `.literature`, `.foodAndDrink`,
   `.natureAndParks`, `.hiddenGems`, `.culturalHeritage`,
   `.sacredSites`. Revise this enum if it doesn't fit.
3. **Write tour metadata** for each:
   - `title` (1 line, gets you in the mood)
   - `shortDescription` (one sentence, feed copy)
   - `longDescription` (multi-paragraph, tour detail page)
   - `walkingDistanceMeters` (multi-stop only)
   - `tags` (free-text secondary themes)
4. **Plan stops** per tour:
   - `title` (e.g. "The Bronze Doors")
   - `caption` (one-line description in player UI)
   - lat/lon (Google Maps → right-click → copy coordinates)
   - `triggerMode`: `.geofenced` (outdoor walking) or `.manual`
     (indoor / quiet contexts)
   - `triggerRadiusMeters` (default 30; tune for the location)
5. **Write maker bios.** Currently the single seed maker is "Atlas
   Studio." If you have other makers for V1, write 1–3 sentence bios
   each.
6. **Draft scripts** for the audio. Spec doesn't constrain length but
   the seed tours are 2–5 min single-piece, 4–8 min per stop in
   multi-stop. Reading speed ~150 wpm → aim for 300–750 words per
   2–5 min clip.

Anything you write here will plug into `Tours.json` when the audio's
recorded. You can also write it directly into `Tours.json` as
placeholder content (with `atlas-tours.example` audio URLs that
won't resolve, like the existing seed) — that lets you preview how
it looks in the app next time you're at your Mac.

### B. CDN decision

Spec calls out three reasonable defaults: Cloudflare R2, AWS S3 +
CloudFront, or Apple's On-Demand Resources. Pick one for V1 audio
hosting and write a short note in `ROADMAP.md` recording the
decision + reasoning. Free to revisit later, but locking it in now
unblocks M-launch-content.

### C. Documentation tightening

- **`ROADMAP.md`** — mark all the merged milestones as ✅ (it still
  shows them as "to do"). The text in the "Where we are right now"
  section is stale.
- **`CLAUDE.md`** — the "Current State (mid-pivot to audio tours)"
  section is stale (most of the things it says "are being rebuilt"
  are now built). Worth a refresh so the next Claude session has
  accurate context.
- **`atlas_claude_code_prompt.md`** — the canonical product spec.
  Reasonable to leave alone, but any product-direction shifts you
  want to lock in (e.g. ratings/reviews decision, paid tours
  thinking) belong here.

### D. Post-V1 thinking (no urgency)

`ROADMAP.md` § "Post-V1 — Future direction" has six open owner
questions:
- Backend stack — Firebase / Supabase / custom?
- Maker dashboard — standalone web app or in-iPad?
- Paid tours — per-purchase, subscription, both?
- Payouts — Stripe Connect or other?
- Sign-in — Sign in with Apple only, or email / Google too?
- Reviews & ratings — ship at all, or never?

None block V1 but worth noodling on. Could write a quick stance on
each into ROADMAP.md.

### E. Code review

Once **PR #20** (AllTrails alignment) is open, you can review the
diff on GitHub. Inline comments + approve/request-changes work in
the browser. You don't need to check out the branch locally to
review — only to test.

---

## How to resume locally (tomorrow night or whenever)

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"
claude --resume                  # picks the last session
# or just `claude` for a fresh one and tell me what you want to do
```

What I'd suggest tackling first when you're back at the Mac:

1. **Rebase `claude/alltrails-alignment` onto main** (clean up the
   now-redundant PR #19 commits in it).
2. **Tweak remaining home polish** based on testing the rebased
   branch in the simulator.
3. **Open PR #20** for the AllTrails work.
4. **Plug in any content** you wrote during the day (B/C above).

---

## File map (where things live)

```
TRAVEL GUIDED TOUR/
├── CLAUDE.md                   # project guidance for Claude
├── ROADMAP.md                  # V1 plan; mark milestones ✅ here
├── atlas_claude_code_prompt.md # canonical product spec
├── HANDOFF.md                  # ← this file
├── TRAVEL GUIDED TOUR/         # source root
│   ├── Models/                 # Tour, Stop, Maker, etc.
│   ├── Data/                   # DataService, LibraryStore, etc.
│   ├── Audio/                  # AudioPlayerService, TourDownloader
│   ├── Location/               # LocationManager, ProximityMonitor
│   ├── Features/
│   │   ├── Home/               # map + drawer + chips
│   │   ├── Tour/               # tour detail
│   │   ├── Player/             # full-screen player
│   │   ├── Search/             # search bar + results
│   │   ├── Maker/              # maker page
│   │   ├── Library/            # saved/downloaded/recently played
│   │   └── Settings/           # "Me" tab + Manage Downloads
│   ├── Components/             # HeroImageView, TagChip, BottomSheet, AtlasTabBar
│   ├── Theme/                  # AtlasColors, AtlasTypography, AtlasSpacing
│   └── Resources/Tours.json    # ← seed content; this is what you edit for content
└── TRAVEL GUIDED TOUR.xcodeproj
```

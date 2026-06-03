# Atlas — Handoff Notes (2026-05-26, remote session)

## What shipped today

### PR #78 — merged ✅
Hero image crossfade fix during tour-detail slide-up. `HeroImageView` gains
`disableLoadAnimation: Bool = false`; `TourDetailView` opts in so cached images
appear frame-zero of the first body eval (no ~250ms crossfade competing with
the slide). Other surfaces unaffected.

### AMNH Four Facades — multi-stop tour added ✅
First multi-stop tour in the catalog. Unblocks M-qa checklist items 6 + 7.

- **39 tours** total (38 single-stop + 1 multi-stop)
- 5 stops: intro (manual) + 4 geofenced stops walking counterclockwise around
  the AMNH block (CPW → 77th St → Columbus Ave → 81st St)
- ~8m 44s total, 700m walking distance, category: architecture
- Audio files live on `gh-pages`; JSON on `main`
- Bug fixed in same session: `kind` field was `"multi"`, should be `"multiStop"`
  (Swift enum raw value) — caught by CI validator, fixed before merge

### Stale branch
`claude/fix-enter-slide-mirror` was deleted after PR #78 merged (auto-merge).
`claude/placecard-pin-tap` still exists on origin — needs deletion from Mac
(`git push origin --delete claude/placecard-pin-tap`) or GitHub web UI;
remote session gets 403 on branch deletes.

---

## What's next (in order)

**1. TestFlight build 12 — Mac session (~10 min)**
Build number is at 11. Bump to 12, archive, upload. Carries:
- PR #78 (enter-slide mirror fix)
- AMNH Four Facades multi-stop tour

**2. M-qa multi-stop check — simulator or device**
Items 6 + 7 on the M-qa checklist are now unblocked:
- Item 6: multi-stop geofenced tour → simulate walk along stops → next stop's
  audio triggers on arrival (use Xcode simulator location simulation)
- Item 7: manual next-stop → tap next stop in player → its audio plays
Use the "American Museum of Natural History: Four Facades" tour.

**3. Design / polish pass — deferred**
No blocker. See `ROADMAP.md` § M-polish.

---

## Owner note
The owner does not use Terminal directly — Claude handles all shell/git work.

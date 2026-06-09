# Atlas — Handoff Notes (2026-06-08, session 28)

Web/PM session. **London launch** — **6** London tours under a new
fourth maker, plus **Openverse** added to the image pipeline. No Swift /
asset / project changes. Catalog **149 → 155 tours / 3 → 4 makers**.
**All 6 merged to `main`** (PR #181 = first 5; PR #182 = The Gherkin).

---

## What happened

### Pipeline: Openverse added (CC0-only)
- New image source documented in `CLAUDE.md` (Rule #8 + § Image Pipeline):
  `GET https://api.openverse.org/v1/images/`, aggregates 800M+ CC/PD works
  across 45+ sources (Wikimedia, Flickr, Europeana…) in one call.
- **License policy (owner decision): public-domain only — `license=cc0,pdm`.**
  The app has no attribution UI and no `credit` field on `Tour`, so CC
  BY/BY-SA (which legally require crediting) are off-limits; PD carries no
  obligation. Owner explicitly declined adding an attribution UI ("others
  too complicated for now").
- Lessons captured: (a) Openverse result **titles are unreliable** (generic
  "Park Av…" strings, foreign lookalikes) → the Gemini/vision verify gate
  is **mandatory**; (b) `upload.wikimedia.org` returns **HTTP 429** on
  bursts → descriptive User-Agent + ~1.5s spacing; (c) Openverse depth
  varies wildly by subject — Seagram Building was near-empty (one Wikimedia
  "Park Av" series + false matches), St Paul's was deep but PD skews to
  **historical engravings/paintings** because modern photos are rarely PD.
- **Presentation lesson:** owner found the contact-sheet grid tiles too
  small. Protocol now: send candidates as **individual full-size inline
  images** (~1000px, number burned in), distinct number namespace per
  source (`1–35` CC0 / `U01–U35` Unsplash).

### London launch
- **New maker: Atlas Studio LDN** (`9c40396a-74ed-49d2-9796-a41edb9e4105`,
  🇬🇧, displayName "Atlas Studio LDN"). Created per owner OK.
- **5 London tours** (all single-stop, geofenced, Atlas Studio LDN,
  owner-narrated text + TTS + MP3 supplied):
  | Tour | Category | Dur | Coords | Notes |
  |------|----------|-----|--------|-------|
  | St Paul's Cathedral | sacredSites | 135s | 51.5138,-0.0984 | Wren dome |
  | The Monument | history | 117s | 51.5102,-0.0859 | hero **top-biased crop** to keep the gilded urn |
  | The Tower of London | history | 138s | 51.5081,-0.0759 | White Tower + fortress |
  | Tower Bridge | architecture | 125s | 51.5055,-0.0754 | hero = bascules raised |
  | Leadenhall Market | culturalHeritage | 130s | 51.5128,-0.0836 | Horace Jones cast-iron arcade |
  | The Gherkin | architecture | 129s | 51.5144,-0.0803 | Foster 30 St Mary Axe; landscape hero (full curve); 1 vertical gallery pick top-biased |
- **All images Unsplash, owner-picked.** Owner asked for modern photos
  over CC0 historical art ("find more on unsplash"). Unsplash key pasted
  fresh this session; download endpoints triggered per Unsplash API terms.
  Each hero + 4–5 gallery cropped to 1200×900 WebP q82.
- **Slug/coords/category** chosen by Claude (hyphenated slugs:
  `st-pauls-cathedral`, `the-monument`, `tower-of-london`, `tower-bridge`,
  `leadenhall-market`). Durations read from the MP3s via `mutagen`.
- Audio + images on `gh-pages`; **all live-URL spot-checks 200**. Validator
  (Python mirror — `swift` not in the web container) clean on every add.

## Tall-subject crop rule (important, reusable)
The 1200×900 **landscape** hero format fights tall/narrow subjects
(columns, spires, towers). A naive center crop **decapitates** them — The
Monument's golden urn was lost at center; fixed with a **top-biased crop**
(`yb≈0.18`). Apply the same to any future column/spire/obelisk (Nelson's
Column, Cleopatra's Needle, etc.). Wide subjects (Tower of London, Tower
Bridge, Leadenhall interior) center-crop fine.

## State at session end
- **Catalog: 4 makers / 155 tours / 164 stops** (96 NYC + 37 OPO + 5 LIS +
  6 LDN). **All on `main`** — London batch merged via PR #181 (first 5)
  and PR #182 (The Gherkin), both CI-green (validate + iOS build + tests).
- gh-pages has all 6 tours' audio + 29 images.
- **TestFlight 1.0 (37) is live** (build `49a81ac`, bumped 36 → 37 and
  uploaded from the owner's local session) — ships the 6 London tours.
- Git identity set to `Claude <noreply@anthropic.com>` mid-session (stop
  hook flagged GitHub's squash-merge committer email on already-merged
  `main` history — left untouched, since rewriting published history would
  require force-pushing main; only the identity for new commits was fixed).

## How to resume / open items
1. Session-start ritual + read this file.
2. ~~Cut TestFlight 37~~ **DONE** — `49a81ac` bumped 36 → 37, archived +
   uploaded from the owner's local session; **1.0 (37) is live** with the
   6 London tours.
3. If more London tours come, same flow: text+TTS+MP3 → add under Atlas
   Studio LDN → Unsplash-led images (owner prefers modern) → inline
   full-size picks → finalize → PR + merge. Tall subjects (columns/spires/
   towers) get the top-biased crop.
4. Carried code follow-ups (unchanged from session 27): on-device M-qa
   incl. multi-stop; design/polish pass (Theme tokens placeholder);
   `MKMapItem.placemark` deprecation warning; Player drag/volume device
   pass.

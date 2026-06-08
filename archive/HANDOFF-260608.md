# Atlas — Handoff Notes (2026-06-08, session 28)

Web/PM session. **London launch** — first 5 London tours under a new
fourth maker, plus **Openverse** added to the image pipeline. No Swift /
asset / project changes. Catalog **149 → 154 tours / 3 → 4 makers**.

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
- **Catalog: 4 makers / 154 tours / 163 stops** (96 NYC + 37 OPO + 5 LIS +
  5 LDN).
- **Branch `claude/dreamy-wozniak-nM6a4`** carries 8 commits: Openverse
  docs (×3), + 5 London tour content commits. **Not merged to main.**
- gh-pages has all 5 tours' audio + 24 images (pushed across 5 commits;
  one rebase needed when an unrelated gh-pages commit landed mid-session).
- **No build bump.** Latest TestFlight still **1.0 (36)**.

## How to resume / open items
1. Session-start ritual + read this file.
2. **Open question for owner:** merge the London batch (`Tours.json` +
   docs) to `main` via PR? Content is auto-merge-eligible, but it's parked
   on the branch pending owner's word (offered at session end).
3. If more London tours come (`london_06`…), same flow: text+TTS+MP3 →
   add under Atlas Studio LDN → Unsplash-led images (owner prefers modern)
   → inline full-size picks → finalize. Tall subjects get the top-biased
   crop.
4. Carried code follow-ups (unchanged from session 27): on-device M-qa
   incl. multi-stop; design/polish pass (Theme tokens placeholder);
   `MKMapItem.placemark` deprecation warning; Player drag/volume device
   pass. Next TestFlight cut would bump 36 → 37 (would ship these 5 new
   tours).

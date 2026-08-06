# HANDOFF — 2026-08-06 (session 83, web/remote, content)

**Berlin launched: 36 tours + the 24th maker, Atlas Studio BER.** Catalog
**1128 → 1164 tours / 23 → 24 makers / 1414 → 1471 stops.** Branch
`claude/berlin-tours-upload-or9i4j`. Content only — no app code, no build needed.

---

## What shipped

**Atlas Studio BER** 🇩🇪 — `a0717b10-a295-5ab5-a875-d5a9587d0274` (uuid5 `atlas-maker:ber`).

- **31 single-stop tours**, geofenced 30 m, `stop0.imageURL` = the tour hero.
- **5 walks**, manual intro (stop 0, `imageURL: null`) + geofenced stops at 40 m:
  | slug | title | shape | km | category |
  |---|---|---|---|---|
  | `berlin-imperialspine-walk` | The Imperial Spine | intro+5 | 1.5 | history |
  | `berlin-ghostline-walk` | The Ghost Line | intro+5 | 2.0 | history |
  | `berlin-coldwarcentre-walk` | Cold War Centre | intro+4 | 2.0 | history |
  | `berlin-scheunenviertel-walk` | The Scheunenviertel | intro+4 | 0.8 | culturalHeritage |
  | `berlin-riverborder-walk` | The River Border | intro+3 | 2.0 | culturalHeritage |
- **57 MP3s, 7,489 s (~2h05m)** — the largest single narration drop to date
  (Rome's 6,866 s was the previous high). All 44.1 kHz / 128 kbps, all byte-distinct.
- **127 images**, all staged back on 2026-07-21. Zero image work this session.

**This is the first drain from the audio-pending queue since Montreal.** Rio,
São Paulo and Dubai all arrived complete and jumped it. **Queue is now Chicago
alone: 30 tours / 53 MP3s.**

---

## Transport: a Dropbox `/scl/fo/` link, first try

The owner pasted a **shared-folder** link (`dropbox.com/scl/fo/…`); with `dl=1` it
returned a 116 MB zip immediately. This keeps working — it is only the **Transfer**
shape (`/t/…`) and work-tenant SharePoint links that cannot be fetched headlessly.
**Check the URL shape before declaring a link undownloadable.**

---

## Three README deviations — two predicted, one new and invisible to the validator

1. **Singles set `stop0.imageURL` to the tour hero.** `drafts/berlin-batch1/README.md`
   says `null`; 100% of Dubai/Montreal/Rome/Madrid/Rio/São Paulo singles set it.
2. **Walk galleries omit whichever stop image is also the walk hero.** The walk
   READMEs list every stop image in order, which trips the validator's
   `heroImageURL also appears in additionalImageURLs` check.

   **(1) and (2) are the exact two errors the Dubai section of the tracker
   predicted would recur. They did. The READMEs are still unfixed for Chicago.**

3. 🐛 **`ghostline_hero.webp` and `ghostline_stop4.webp` are BYTE-IDENTICAL** —
   same sha256 on the *live URLs*, not merely the same git blob. The Ghost Line
   walk would have shown that photograph as its cover and again as gallery slide 4.
   **`validate-tours.swift` cannot catch this:** the two URLs are different and
   both return 200, so every check it runs passes. Fixed by dropping
   `ghostline_stop4` from the gallery (4 entries for 5 stops); stop 4 keeps it as
   its own stop image, which is the documented reuse slot, and
   `check-image-duplicates.py` now classifies the pair **INFO** instead of ERROR.

   **Durable rule: a walk whose hero is drawn from its own stop images needs a
   byte check, not just a URL check.**

---

## 🐛 A wrong image, caught by opening it

**Imperial Spine stop 4 (Lustgarten)** was staged with `museum-island_hero.webp`.
That file is **the Bode Museum photographed from the water** — 600 m north at the
island's tip — while the stop script tells the listener they are looking at "a
colonnade of eighteen columns: the Altes Museum… the Berliner Dom… the palace
facade." Nothing but opening the file would have caught it; the slug
(`museum-island`) matches the stop title (`Lustgarten`) perfectly.

Now uses **`museum-island_3.webp`**, the Altes Museum colonnade head-on across the
lawn — already staged, already ship-safe, no new credit.

This was independently found by **[PR #475](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/475)**,
which audited all 94 reused walk images across six cities and was **still open and
unmerged** at wire-in. **Verified here by opening both files rather than taking the
report on trust.** Then **all 21 Berlin walk-stop images were opened and checked
against their stop scripts** — the other 20 are correct, including the
sensitivity-critical ones (Große Hamburger Strasse is Lammert's memorial sculpture;
Topography of Terror is the documentation pavilion, not a swastika close-up).

⚠️ **The single-stop `museum-island` hero is still that same Bode photograph, and
was deliberately left alone.** A hero is a tour cover, and the Bode from the water
is a legitimate iconic Museum Island image; a walk *stop* image has to show what is
actually in front of you, which is why only the walk was wrong. But that hero is
also `stop0.imageURL`, and the single's script opens in the Lustgarten too.
`museum-island_3` is already in its gallery, so promoting it is a one-line swap —
**owner's call, flagged not taken.**

---

## Verification

- **0 errors, 0 warnings across all 1164 tours**, via a **Python mirror of
  `validate-tours.swift`** (no Swift toolchain in a Linux web session). This
  revision parses the tag vocabulary from **both** `Models/Tag.swift` **and** the
  Swift validator and **raises if the two disagree or if either parse comes back
  empty** — the Dubai failure mode, where a mirror silently passed everything.
  **Self-tested against 30 injected fault classes first — 30/30 caught.**
- **uuid5 scheme reverse-verified** against 16 live makers plus a São Paulo single
  and all 7 stops of its walk before minting BER. **0 duplicate tour / stop / maker
  ids** across 1164 / 1471 / 24.
- **127 images uploaded = 127 referenced, 0 orphaned.** (The São Paulo lesson:
  compare the maker's uploaded image count against what the dup-checker prints —
  a shortfall means images nothing points at, and nothing fails on it.)
- `check-image-duplicates.py --maker BER` — clean over 127 images, one expected
  walk-reuse group.
- **All 184 Berlin asset URLs live-checked 200.**
- **`transcriptText`** = each display script minus its 42 `[beat]` markers.
  **No headers to strip at all** — every one of the 57 scripts opens on prose, the
  cleanest script set any city has delivered. Captions extend across sentences
  until they clear 60 chars; **shortest shipped is 63**.

### Assets-first, via pure plumbing

Blobless fetch → `read-tree` into a temp `GIT_INDEX_FILE` → `hash-object -w` →
`update-index --cacheinfo` → **`write-tree --missing-ok`** → `commit-tree` → push
the sha to `refs/heads/gh-pages`. Verified before committing that **none of the 57
target paths already existed** and that the tree diff was **exactly 57 additions,
0 deletions, nothing outside `audio/`**.

The Pages deploy lagged and served 404 for every MP3. Checked against the Actions
API and found **`in_progress`, not `cancelled`** — the distinction CLAUDE.md warns
about — then confirmed by **hashing the downloaded bytes against the uploaded blob
SHAs**, not by the push succeeding.

### Key-order discipline

Matching the dominant convention (explicit `introAudioURL: null` /
`walkingDistanceMeters: null`, full-precision centroid mirroring the single stop)
made the diff **1,941 insertions / 1 deletion** — the single deletion being the
file's closing brace.

---

## Flagged, not actioned

- **⚠️ Karl Friedrich Schinkel is not in the tag vocabulary**, and he is behind the
  Neue Wache, the Altes Museum and the Konzerthaus, recurring through the Berlin
  scripts as the man who "taught Prussia what calm looks like." Hans Scharoun,
  August Endell and Hermann Henselmann are likewise absent. `Norman Foster`,
  `Renzo Piano`, `Mies van der Rohe` and `Santiago Calatrava` **are** in the
  vocabulary and are used by name. Adding the rest means editing
  `Models/Tag.swift` — a **code** change needing owner OK + sim review — so it was
  kept out of a content PR. **With São Paulo's Bo Bardi / Mendes da Rocha /
  Niemeyer gap, the case for one combined vocabulary PR is now strong.**
- **⚠️ `east-side-gallery_hero` is Vrubel's Brezhnev–Honecker mural**, still in
  copyright, carried on **German freedom of panorama** (§59 UrhG), which does cover
  permanently-sited public artworks. Different legal footing from the Chicago
  Pilsen murals, where the US has no such provision — don't conflate the two.
- **⚠️ 2 tours ship hero-only** (Mauerpark, Nollendorfplatz); 4 more have hero + 1
  (Bernauer Strasse, Karl-Marx-Allee, Kollwitzplatz, Treptower Park). Backfillable
  without touching audio.
- ✅ **The `crop43` portrait-decapitation scare was checked and cleared.** Chicago
  staging named Berlin's Water Tower as a likely casualty; `kollwitzplatz_2` is
  intact from base to chimney.
- **PR #475 is still open** and touches `drafts/` docs including this tracker. Per
  the tracker's own collision rule, the **content wire-in lands first** and #475
  rebases onto it. Its Berlin fix is already reflected in `Tours.json` here.

---

## Next

- **Chicago is the whole remaining queue** — 30 tours (25 single + 5 walks),
  53 MP3s, image-complete, `Atlas Studio ORD`
  (`f34cd76e-1e41-5c38-865d-d8eccd775cd3`). Its pick-map was written as staging
  went. **Fix the two staging-README errors before wiring it**, or they will recur
  a third time.
- Chicago's script numbering is **deliberately non-contiguous** (01–17, 20, 21, 23,
  24, 25, 28, 29, 30 — 18/19/22/26/27 were never delivered). Recorded in advance so
  nobody reads a gap as a lost file.

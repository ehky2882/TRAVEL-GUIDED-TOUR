# HANDOFF — 2026-08-11 (session 88, web) — Melbourne launched: 35 tours + 28th maker Atlas Studio MEL; the first Australian city

**One-line summary:** Melbourne goes live — 34 single-stop tours + the Federation Square
walk under new maker **Atlas Studio MEL** 🇦🇺, wired the same day the owner's Dropbox drop
arrived. Catalog **1256 → 1291 tours / 27 → 28 makers / 1596 → 1637 stops**. Seventh
complete drop in a row; the queue was empty before it and is empty after it.

Branch: `claude/upload-scripts-audio-images-8vvpw7`, [PR #489](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/489).

## What shipped

- **New maker:** Atlas Studio MEL (`117eebb3-5e5d-51e9-83cf-8ae0f3747bf0` = uuid5
  `atlas-maker:mel`, 🇦🇺), the 28th — **the catalog's first Australian city.**
- **34 single-stop tours**, geofenced 30 m: Above Board · Byrdi · Caretaker's Cottage ·
  Carlton Gardens · Carnation Canteen · Chin Chin · CIBI · Four Pillars · France-Soir ·
  Gimlet at Cavendish House · Heide MoMA · HER · Lune Croissanterie · Matilda 159 ·
  Melbourne Museum · Minamishima · MPavilion · Napier Quarter · NGV · Pellegrini's ·
  Piccolina · Pidapipó Laboratorio · Reine & La Rue · Royal Botanic Gardens · Royal
  Exhibition Building · Shot Tower Museum · Shrine of Remembrance · Siglo · State Library
  Victoria · TarraWarra · The Block Arcade · Tipo 00 · Victor Churchill · Yakimono.
- **1 walk:** `melbourne-fedsquare-walk` "Federation Square" (intro+6, 550 m,
  culturalHeritage) — Flinders Street Station (Under the Clocks) → Nearamnew → ACMI →
  The Atrium & Deakin Edge → Ian Potter Centre: NGV Australia → Koorie Heritage Trust →
  Federation Wharf.
- **Category mix:** 22 foodAndDrink · 3 visualArt · 3 architecture · 2 natureAndParks ·
  2 history · 1 culturalHeritage (+1 walk) · 1 literature. The heaviest food/drink share
  of any city yet — Melbourne's canon *is* its bars and restaurants.
- **41 MP3s, 4,987 s ≈ 1h23m** to gh-pages (commit `a6cc859`, pure plumbing, exactly 186
  additions); Tours.json diff **1,689 insertions / 0 deletions**.

## The delivery — the cleanest yet

- Dropbox `/scl/fo/` link, 100 MB zip, downloaded first try. **Seventh complete drop**
  (after Rio, São Paulo, Marrakech, Buenos Aires + the queue cities): 41 MP3s **already
  44.1 kHz/128 kbps** — no transcode, the first drop since Rio needing zero audio work —
  and 146 images **already 1200×900**, all byte-distinct, `01` = hero.
- **The walk arrived with 7 content stops and NO intro track** (folders `output 01..07`,
  each stop numbered "Stop NN of 07" in its script header). Resolved by the Chicago
  Riverwalk precedent: its stop 0 ("The Lake Street stairway") is also a real
  location-specific opener wired `manual`. So Flinders Station = stop 0 (manual, the walk's
  natural start — "I'll meet you under the clocks"), stops 02–07 = geofenced stops 1–6.
- One naming quirk: Pellegrini's MP3 arrived named `01 Pellegrini's Espresso Bar Hero
  Image.mp3` (copied the image pattern). Content was a valid MP3; handled by extension.
- **Script shape:** singles carry a one-line `<Name> — Audio Tour Script` header; walk
  stops a two-line header (title + `Federation Square Multi-Stop Tour — Stop NN of 07`).
  Both stripped for `transcriptText`, plus 41 `[beat]` markers (exactly one per script).
  The tts-safe twins proved the closing recommendation lines ARE narrated (kept) and
  `[beat]` is not. Captions extend across sentences to clear 60 chars; shortest shipped 65.

## 🐛 One wrong image caught by the open-every-image audit — pre-upload this time

All 57 files (34 single heroes + all 23 walk images) were opened and checked against
their scripts. **`melbourne-fedsquare-walk_stop0_4.webp` showed the Gog and Magog clock —
which lives in the ROYAL ARCADE on Bourke Street, three blocks from Flinders Street
Station.** The clock face itself reads "T. Gaunt & Co, Royal Arcade, Melbourne" and the
in-frame plaque names the giants. The Thyssen class again (plausible location, wrong
building) — but caught **before** upload, so the file was simply never staged to gh-pages:
145 of 146 images shipped, 0 orphans. Everything else verified correct, including the
script-specific details (Above Board's hidden bottles, Four Pillars' porthole still,
Lune's glass cube, the Ando pavilion's reflecting pool, Deakin Edge's timber bowl).

## Wire-in decisions worth carrying

- **uuid5 reverse-verified 8/8 before minting** (BUE/RAK/ORD makers, a BUE single
  tour+stop pair, the BUE walk + two of its stops, and the ORD walk-stop id pattern).
  Walk stop ids: `atlas-stop:mel:melbourne-fedsquare-walk-stop{N}`.
- **Walk conventions followed BUE** (the closest structural precedent — same pre-structured
  drop shape): stop 0 carries its own `imageURL` (it's a real place with photos, unlike
  Chicago's abstract intros which take null); walk hero = stop 0's cover; walk gallery =
  all other walk images in stop order (21 entries); every stop's `imageURL` = its own
  `_stop{N}_hero`.
- **Two Yarra Valley tours ship `city: "Healesville"`** (Four Pillars ~50 km NE, TarraWarra
  ~45 km NE — the Aït Benhaddou/Campinas convention). **Heide (Bulleen) and Victor
  Churchill (Armadale) stay `city: "Melbourne"`** — both are metro Melbourne, same
  continuum as Fitzroy/Richmond/South Yarra tours.
- **NGV Australia (walk stop 4) vs National Gallery of Victoria (single 19) are different
  buildings by design** — Fed Square vs St Kilda Road, the MAC USP two-entries precedent.
  Don't "fix" it.
- **Tadao Ando and Kisho Kurokawa are IN the tag vocabulary and used by name** (MPavilion;
  the Shot Tower's Melbourne Central cone) — the named tag implies Designed-by-a-Master
  per the Calatrava precedent. **The rest of the Melbourne canon is absent:** Roy Grounds
  (NGV), Joseph Reed (Royal Exhibition Building + Carlton Gardens layout), William Pitt
  (Reine & La Rue's Stock Exchange), Norman Peebles (State Library dome), David Askew
  (Block Arcade), David McGlashan (Heide II), Allan Powell + Kerstin Thompson (TarraWarra),
  Hudson & Wardrop (Shrine) — all `Designed by a Master`. The combined Tag.swift PR case
  grows a Melbourne wing.
- **Sensitivity:** the Koorie Heritage Trust stop leads with the 1985 court case and
  self-determination framing exactly as scripted; Bunjilaka and the Ian Potter First
  Nations collection follow the scripts' respectful register; no mortality figures
  anywhere; the Shrine is reverent and non-graphic. Nothing in the CREDITS ledger — all
  images owner-supplied.
- Reine & La Rue's hero shows the **Melbourne Safe Deposit facade — that IS the
  restaurant's Queen Street entrance** into the Stock Exchange complex (same William Pitt
  Gothic precinct), verified before accepting.
- Siglo's script says "Bourke Street" for a venue whose door is by The European on Spring
  Street; the audio says what it says, so the transcript keeps it and the tour description
  simply avoids naming the street.

## Verification (all green before merge)

- Python mirror of `validate-tours.swift`: vocab parsed from **both** `Tag.swift` and the
  Swift validator (raises on disagreement/empty), **self-tested 45/45 injected fault
  classes**, then **0 errors / 0 warnings across all 1291 tours**; 0 duplicate ids across
  1291/1637/28.
- gh-pages: 0 of 186 target paths pre-existed (checked against all 6,104 existing); tree
  diff **exactly 186 additions, 0 deletions, nothing outside `audio/` + `images/`**; Pages
  deploy checked via the Actions API (in_progress → completed/success); **all 186 live
  URLs hash-verified against the uploaded git blob SHAs**.
- Tours.json byte-stable under `json.dumps(indent=2, ensure_ascii=False) + '\n'` before
  editing; key order mirrors the BUE entries exactly; caption floor 65 chars.

## Flagged, not actioned

- **The dropped Royal Arcade image** suggests the owner may have a Royal Arcade tour in a
  future batch (the photo had to come from somewhere) — mention if a second Melbourne
  batch appears.
- **Missing-architect-tag list, Melbourne wing:** Grounds, Reed, Pitt, Peebles, Askew,
  McGlashan, Powell, Kerstin Thompson, Hudson & Wardrop — same combined `Models/Tag.swift`
  PR as Schinkel/Niemeyer/Bo Bardi/Studio KO/Testa/Khan.
- **Nothing is staged anywhere.** The queue is still empty; the next city needs a fresh
  drop. Complete drops with pre-sized images are now 7-for-7 the winning shape.

## Next

- Standing non-content work unchanged: Paid tours Phase 3 (PR #469 awaiting owner review),
  launch-runbook Step 1 (prove one fastlane TestFlight build), the combined Tag.swift
  architect PR, PR #475 (close or merge its drafts-audit value).

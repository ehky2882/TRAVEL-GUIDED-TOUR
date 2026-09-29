# Handoff 2026-09-29 — Glasgow launch (Atlas Studio GLA)

**What shipped:** a new bureau, **Atlas Studio GLA** 🇬🇧 (maker id `f65dc893-2f4d-598a-8f00-21416db82c7a`
= uuid5 `atlas-maker:gla`, `NAMESPACE_URL`), the 37th studio, with **50 tours: 49 singles + 1
multi-stop walk** (*University of Glasgow*: Cloisters → Hunterian Museum → The Mackintosh House,
~300 m, stops geofenced at 20 m). 52 MP3s (1.6–2.7 min, 128 kbps mono 44.1 kHz, 6,629 s total)
and 174 photographs on `gh-pages` in one commit `e9af36a` (226 files, all `A`). Catalogue
1633 → 1683 tours, 547 → 548 makers. Tour/stop ids: uuid5 `atlas-tour:gla:<slug>` /
`atlas-stop:gla:<slug>`, slug = the script's filename stem (leading `NN-` stripped).

**Source:** a Dropbox `/scl/fo/` drop from a content contributor (not the owner), same shape as
Istanbul: one folder per site named `<site> <lat>, <lon>`, `<slug>_clean.txt` (transcript;
title + `===` underline and `[beat]` lines stripped), an unused `_tts-safe.txt` twin, one MP3,
1200×900 webps (three JPGs converted to webp). `unzip` mangles the curly apostrophe in two
folder names (`#U2019`); titles come from the scripts, so nothing reached the catalogue.
The assembler lives only in the session scratchpad; titles, captions (first sentence of
paragraph 2), longDescription (paragraphs 2–3) are verbatim from the scripts, shortDescription
hand-written from them.

**Triage found, and the contributor fixed in the drop before minting:**
- Three wrong-building photos: the Cloisters hero was Glasgow Cathedral; the Hunterian Museum
  hero was the Hunterian *Art Gallery* entrance; Pollok Country Park 02/03 were the Burrell.
- Two coordinates: Forth and Clyde Canal (was at Queen's Cross, ~450 m from the Claypits
  reserve) and Starter Culture (~100 m off, on Minard Road).
- Left out as hotel advertising: the bedroom/room photos of Kimpton (05), Native (03) and
  the Social Hub (05).

**Out-of-town tours carry their real town**, as Healesville / Nacka did: Loup of Fintry →
`Fintry`, Rouken Glen → `Giffnock`, The Hill House → `Helensburgh`.

**Checks:** `check-coordinates.py --drop` needed a second run (57/136 calls failed the first
time); then **no significant bias** (27/40 north, median +7.5 m), one GROSS (Shawarma King —
the geocoder found the Paisley Road branch; the King Street arch point is 12 m from OSM's 113
King Street). Validator mirror: 0 errors; one warning (Loup of Fintry has no Theme tag).
`spine-lookup`: 50 asked, 0 failed. `check-city-outliers`: no Glasgow entry.
`check-place-candidates`: Steps Bar (13 m) and The Hill House (155 m) against existing pins;
by name search also The Mackintosh House stop vs the "Mackintosh at The Hunterian" pin (27 m).
`join-places --max-move 100`: none.

**Left for Edward (status board):**
- `mackintosh-tag` — no "Charles Rennie Mackintosh" architect tag (a Swift change); six
  tours/stops carry *Designed by a Master* meanwhile. Contributor asked for it.
- `place-glasgow-260929` — the three same-site pairs; Burrell-inside-Pollok (part vs whole);
  The Social Hub Glasgow minted at the contributor's request despite reading as an advert;
  photo sources/licences not recorded.

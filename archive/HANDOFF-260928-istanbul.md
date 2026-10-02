# Handoff 2026-09-28 — Istanbul batch 1 (Atlas Studio IST)

**What shipped:** a new bureau, **Atlas Studio IST** 🇹🇷 (maker id = uuid5 `atlas-maker:ist`,
`NAMESPACE_URL`), with **51 tours: 50 singles + 1 multi-stop walk** (*Galataport: From Customs
Hall to Modern Art*, 4 stops, ~700 m). 54 MP3s (98–138 s each) and 187 photographs on
`gh-pages` in one commit (241 files, all `A`). Catalogue 1582 → 1633 tours, 537 → 538 makers.

**Source:** a Dropbox `/scl/fo/` drop supplied by a content contributor (not the owner). One
folder per site, named `<site> <lat>, <lon>`, each with `<n>_<slug>_clean.txt` (used as
`transcriptText`, `[beat]` lines stripped), a `_tts-safe.txt` twin (unused), one MP3 and
1200×900 webps. ⚠️ The zip stores names in UTF-8 without the flag — `unzip` mangles them;
extract with Python and decode cp437 → utf-8.

**Triage, then the contributor's rulings:**
- Four commercial entries — Misela Pera (handbags), Yastık (cushions), Anatolian Craft
  (appointment-only showroom), Zorlu Center (mall) — were flagged as advertising-adjacent;
  the contributor said **mint all four**.
- **Dilim Pastanesi**'s first MP3 was 49 s for a 298-word script (truncated). The contributor
  re-exported it: 107 s.
- **The Bank Hotel** folder had no coordinate; the re-sent folder carries 41.0237889,
  28.9744304 — 23 m from OSM's "Vault Karaköy" (its former name) at Bankalar Cd. 5.

**Checks:** `check-coordinates.py --drop` — **no northward bias** (26/40, median +11.7 m,
p = 0.081); 3 GROSS (Petra, Aşşk Kahve, TURK) were all the geocoder matching another branch
or a namesake, each confirmed against the street its script names. Validator 0 errors.
`check-place-candidates`: NAME none, EXACT none; TIGHT pairs Aheste/Misela Pera (same
building, different businesses — co-location is not identity) and Camondo Stairs/SALT
Galata (24 m, different things). `join-places --max-move 100`: 0. `spine-lookup`: 51 asked,
0 failed. `check-city-outliers` flags Sancaklar Mosque at 32 km — correct, it is in
Büyükçekmece.

**Left for Edward (status board):**
- `istanbul-architect-tags` — Sinan, the Balyans, Vallaury, Tabanlıoğlu, Emre Arolat are not
  in the tag vocabulary (a Swift change). Those tours carry *Designed by a Master* meanwhile.
- `istanbul-photo-licences` — the contributor says the photos are "from Creative Commons";
  per-image licence and author were not supplied. Also noted in `drafts/CREDITS.md`.
- Not raised as place questions: AKM and Gezi Park sit on/next to Taksim Square
  (part-vs-whole is undecided in `docs/places.md`); no check flagged them.

**Worth a later walk:** the Kuzguncuk scripts already chain (Dilim → Bostanı → Simitçi Tahir →
Glow → İsmet Baba → Vapur Kafe), as do Walter's → Fahri Konsolos in Moda.

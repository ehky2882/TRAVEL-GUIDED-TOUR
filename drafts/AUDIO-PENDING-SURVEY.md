# Audio-Pending Tour Tracker — the single source of truth for staged content

**Purpose.** Tours are staged (scripts + images) on various branches long before their
narration MP3s exist. This file is the **authoritative, continually-updated record** of
what is staged, what is live, and what still needs audio — so no session has to re-survey
the branches to answer "what's left?".

**⚠️ UPDATE RULE (do this automatically — no prompting):**
- When a batch of tours is **staged** (scripts + images) → add it to the PENDING table below.
- When audio arrives and tours are **wired live** (merged to `main`) → move them from PENDING
  to the LIVE section and update the counts.
- Always update this file in the same commit/session as the staging or wire-in.
- The counts here must match reality; if in doubt, re-verify against `origin/main`'s
  `TRAVEL GUIDED TOUR/Resources/Tours.json` (a tour is LIVE iff it's in that file) and against
  `git ls-tree -r --name-only origin/gh-pages | grep audio/` (audio staged iff the slug's
  `.mp3` is there).

**Last verified:** 2026-07-15 (🇮🇹 Rome staged — 25 singles + 5 walks, image-complete on gh-pages).

---

## PENDING — staged, awaiting narration audio

Every pending tour below is **image-complete** (heroes + galleries live on gh-pages). The
**only** missing ingredient is narration MP3s. No draft audio is staged for any of these yet.

| City | Pending tours | Breakdown | MP3s needed | Staging branch | Maker at wire-in |
|------|--------------:|-----------|------------:|----------------|------------------|
| 🇺🇸 Los Angeles | 39 | 36 single + 3 walks (5/7/5 stops) | 56 | `claude/dreamy-wozniak-nM6a4` | **new** (LA) |
| 🇪🇸 Madrid | 35 | 31 single + 4 walks (5/6/5/5 stops) | 56 | `claude/dreamy-wozniak-nM6a4` | **new** (MAD) |
| 🇳🇱 Amsterdam | 38 | 33 single + 5 walks (5/6/5/5/5 stops) | 64 | `claude/amsterdam-handoff-preserve-hlhyp8` | **new** Atlas Studio AMS |
| 🇨🇦 Montreal | 29 | 25 single + 4 walks (intro+5 / intro+4 / intro+4 / intro+4) | 46 | `claude/amsterdam-handoff-preserve-hlhyp8` | **new** Atlas Studio YUL |
| 🇮🇹 Rome | 30 | 25 single + 5 walks (intro+5 / intro+5 / intro+5 / intro+4 / intro+4) | 53 | `claude/amsterdam-handoff-preserve-hlhyp8` | **new** Atlas Studio ROM |
| **TOTAL PENDING** | **171** | | **275** | | |

_(🇬🇧 London — "The Measure of the World" (Greenwich, 7-track walk) **went LIVE 2026-07-08, PR #378** — removed from pending. It was the last staged London tour.)_
_(✅ Paris = DONE: **45 single-stop tours LIVE** (PR #374) + **all 5 walks LIVE** — Le Marais (#379), Montmartre (#380), The Triumphal Way (#381), Paris Islands (#382), The Left Bank (#383). Nothing Paris pending.)_
_(✅ 🇨🇦 Toronto = DONE (2026-07-10): **all 42 tours LIVE** — 38 single-stop (10 batch A + 28 PR #384) + **all 4 walks** (Old Town #385, Museum Mile #386, Downtown Spine #387, Immigrant West/Kensington #388). Nothing Toronto pending.)_

### Per-city detail

**🇺🇸 Los Angeles** — `drafts/la-batch1..8` (36 single-stop) + 3 walks:
- `la-beachfront-walk` — intro + 5 (Santa Monica Pier, Muscle Beach, Venice Boardwalk, Venice Canals, Abbot Kinney)
- `la-downtown-walk` — intro + 7 (Disney Hall, The Broad, MOCA, Angels Flight, Grand Central Market, Bradbury, El Pueblo/Olvera)
- `la-museumrow-walk` — intro + 5 (La Brea Tar Pits, LACMA/Geffen, Academy Museum, Petersen, Farmers Market)
- Credits: LA CC images logged in `drafts/CREDITS.md` (Los Angeles row, ~17). New city → new maker.

**🇪🇸 Madrid** — `drafts/madrid-batch1..7` (31 single-stop) + 4 walks:
- `madrid-austrias` — intro + 5 · `madrid-paseo-del-arte` — intro + 6 (Cibeles, Neptuno, Prado, Thyssen, CaixaForum, Reina Sofía) · `madrid-retiro` — intro + 5 · `madrid-royal` — intro + 5
- Credits: Madrid CC images logged in `drafts/CREDITS.md` + `drafts/madrid-batch3/IMAGE-CREDITS-madrid-batch3.txt`. New city → new maker.

**🇳🇱 Amsterdam** — `drafts/amsterdam-batch1` (33 single-stop) + 5 walks:
- `amsterdam-canalring-walk` (intro+5) · `amsterdam-oldside-walk` (intro+6) · `amsterdam-museumquarter-walk` (intro+5) · `amsterdam-jordaan-walk` (intro+5) · `amsterdam-jewishquarter-walk` (intro+5)
- All walks reuse live single-stop heroes (zero new image work). Full spec in each folder's README + `drafts/amsterdam-batch1/README.md` (master pick-map). Credits: `drafts/CREDITS.md` (Amsterdam, 22). New maker **Atlas Studio AMS** 🇳🇱.

**🇨🇦 Toronto — ✅ COMPLETE (2026-07-10)** — all **42 tours LIVE** under Atlas Studio YYZ: 38 single-stop (10 batch A + 28 PR #384) + all 4 walks (Old Town #385, Museum Mile #386, Downtown Spine #387, Immigrant West/Kensington #388). Nothing pending.

**🇫🇷 Paris — 5 multi-stop walks** (on `dreamy-wozniak-nM6a4`; wire under the existing **Atlas Studio PAR** maker):
- ~~`paris-marais` — "Le Marais"~~ — **LIVE 2026-07-08 (PR #379)**, 6 tracks
- ~~`paris-montmartre` — "Montmartre"~~ — **LIVE 2026-07-08 (PR #380)**, 6 tracks
- ~~`paris-triumphalway` — "The Triumphal Way"~~ — **LIVE 2026-07-08 (PR #381)**, 7 tracks
- ~~`paris-islands` — "Paris Islands"~~ — **LIVE 2026-07-09 (PR #382)**, 6 tracks
- ~~`paris-leftbank` — "The Left Bank"~~ — **LIVE 2026-07-09 (PR #383)**, 7 tracks — **all 5 Paris walks now live**
- Reuse the 45 live single-stop Paris heroes where stops overlap; a few fresh walk images already staged (Îles hero, Marais Musée Picasso — CC credits in `IMAGE-CREDITS-paris-batch1.txt`). READMEs say "create the PAR maker" — **stale**: PAR now exists, so walks wire straight in.

**🇨🇦 Montreal** — **29 tours (25 single-stop + 4 walks)**, new maker **Atlas Studio YUL** 🇨🇦. Complete 2026-07-13 (image-staged; awaiting narration):
- **Batch 1 (Old Montreal, 5):** Notre-Dame/Place d'Armes, Place Jacques-Cartier/City Hall, Old Port, Pointe-à-Callière, Bonsecours Market+chapel. (`drafts/montreal-batch1/README.md`)
- **Batch 2 (4):** Château Ramezay, Habitat 67, McGill/Golden Square Mile, Christ Church Cathedral. (`drafts/montreal-batch1/README.md`)
- **Batch 3 (16):** Mary Queen of the World, Place Ville Marie/RÉSO, Dorchester/Sun Life, Quartier des Spectacles, Chinatown, Mount Royal/Kondiaronk, St Joseph's Oratory, Plateau staircases, Square Saint-Louis, The Main, Mile End, Jean-Talon Market, The Village, Botanical/Biodome, Lachine Canal, Atwater Market. (`drafts/montreal-batch3/README.md`)
- **4 walks:** `montreal-oldmontreal-walk` (intro+5) · `montreal-mountroyal-walk` (intro+4) · `montreal-plateaumileend-walk` (intro+4) · `montreal-downtown-walk` (intro+4). Each has its own README wire-in spec; all reuse single-stop heroes except Mount Royal (3 new images: entrance, climb, Cross).
- **MP3s needed: 46** = 25 singles + 21 walk tracks. Credits: `drafts/CREDITS.md` (Montreal — 15 batch 1-2 + 4 batch 3/walk = 19 CC-credited; almost all batch-3 is owner/ship-safe).

**🇮🇹 Rome** — **30 tours (25 single-stop + 5 walks)**, new maker **Atlas Studio ROM** 🇮🇹. Complete 2026-07-15 (image-staged; awaiting narration):
- **Batch 1 (25 single-stop):** Colosseum, Roman Forum, Pantheon, Trevi, Spanish Steps, Piazza Navona, St Peter's Square, Castel Sant'Angelo, Piazza del Popolo, Campo de' Fiori, Campidoglio, Vittoriano, Largo Argentina, Jewish Ghetto, Tiber Island, Santa Maria in Trastevere, Gianicolo, Bocca della Verità, Circus Maximus, Aventine, Baths of Caracalla, Ara Pacis + Mausoleum, Pincio, Piazza Barberini, Arch of Constantine. Master pick-map (slug/coord/category/hero+gallery/credit): `drafts/rome-batch1/README.md`.
- **5 walks:** `rome-ancientrome-walk` (intro+5) · `rome-baroqueheart-walk` (intro+5) · `rome-ghettotrastevere-walk` (intro+5) · `rome-vaticanborgo-walk` (intro+4) · `rome-aventinetestaccio-walk` (intro+4). Each folder has its own README wire-in spec (per-stop image slug + coord + centroid + walking distance).
- **Walk images:** almost all stops reuse live single-stop heroes. **5 walk-only new images** staged (Trajan's Column, Ponte Sant'Angelo, Via della Conciliazione, Testaccio/Monte Testaccio, Aventine Keyhole).
- **Sensitivity:** the Jewish Ghetto (single #14 + Ghetto & Trastevere walk stop 2) uses dignified Portico d'Ottavia / Great Synagogue exteriors only — no graphic imagery.
- **MP3s needed: 53** = 25 singles + 28 walk tracks. Credits: `drafts/CREDITS.md` (Rome — **6 CC-credited**: Ara Pacis ×3, Piazza Barberini ×2, Testaccio ×1; everything else ship-safe/owner-pasted).
- **Pending galleries (hero-complete without them):** #10 Mary interior, #11 Place Ville Marie, #22 Square Saint-Louis, #23 The Main.

_(🇬🇧 London — Greenwich walk "The Measure of the World" **went LIVE 2026-07-08, PR #378**. It was the last staged London tour; London is now fully wired.)_

---

## LIVE — done, for reference (do not re-stage)

As of 2026-07-08, `origin/main` = **11 makers / 616 tours / 726 stops**. Live cities:

| City | Live tours | Maker | Notes |
|------|-----------:|-------|-------|
| London | 99 | LDN | + **5 walks** (After the Fire, Albertopolis, Spine of Power, South Bank Mile, **The Measure of the World / Greenwich** — added 2026-07-08). London fully wired. |
| New York | ~96 | NYC | + AMNH Four Facades, Fifth Avenue Walk |
| Tokyo | 63 | TYO | bilingual EN/JP |
| Lisbon / Porto region | ~60 / ~50 | LIS / OPO | |
| Hong Kong | 52 | HKG | bilingual EN/中文 |
| Kyoto region | 52 | KYO | bilingual EN/JP |
| **Paris** | 45 | **PAR** | **launched 2026-07-08 (PR #374)** — 45 single-stop + **all 5 walks** (Le Marais #379, Montmartre #380, Triumphal Way #381, Paris Islands #382, Left Bank #383). **Paris fully wired.** (above). |
| San Francisco | 35 | SFO | + 4 multi-stop walks |
| Naoshima | 15 | NAO | + 2 multi-stop walks |
| Toronto | 42 | YYZ | ✅ COMPLETE 2026-07-10 — 38 single-stop + 4 walks (PRs #384–#388) |

---

## Wire-in process (when audio arrives) — reference

1. Owner drops MP3s into chat → they land in `/root/.claude/uploads/<session>/`.
2. Read durations (`mutagen`), copy each to gh-pages `audio/<slug>.mp3`, push to `gh-pages`.
3. Build/extend the city's assembler: maker id = `uuid5(NAMESPACE_URL, "atlas-maker:<code>")`,
   tour id = `uuid5(…, "atlas-tour:<code>:<slug>")`, stop id = `atlas-stop:<code>:<slug>`.
   Each tour: transcript verbatim from the display `.txt`, geocoded coord, geofenced 30 m,
   staged image URLs, category + controlled-vocabulary tags (≥1 Place type + ≥1 Theme),
   authored short/long descriptions. Walks: `kind:multiStop`, stop 0 = intro (manual),
   stops 1..N geofenced, centroid = avg of stops, `walkingDistanceMeters` set.
4. **Re-serialize `Tours.json` with `json.dumps(d, ensure_ascii=False, indent=2)` (no trailing
   newline)** so the diff is additions-only (matches the file's existing formatting exactly).
5. Validate (`swift scripts/validate-tours.swift`, or the Python mirror when Swift is absent);
   fix errors. Merge to `main` → auto-publishes to gh-pages + Supabase (live, no app build).
6. **Update this file** (move the city from PENDING to LIVE).

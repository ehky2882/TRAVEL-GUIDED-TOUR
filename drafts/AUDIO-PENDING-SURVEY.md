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

**Last verified:** 2026-07-28 (🇨🇦 Montreal COMPLETE — all 29 tours live under Atlas Studio YUL. Pending queue: **Berlin + Dubai**).

> ⚠️ **This file went stale within a day and told a session the wrong thing.** On 2026-07-28 it said the queue was "Montreal + Berlin only"; **Dubai had been script- and image-staged on 2026-07-27** by a parallel session that added its drafts to `claude/amsterdam-handoff-preserve-hlhyp8` and pushed ~32 images to `gh-pages` **without updating this file**. A session then reported "queue is down to Berlin only" to the owner, who corrected it. **The UPDATE RULE above is not optional, and it binds the *staging* session as much as the wire-in session.** When in doubt, re-derive rather than trust the table: `git ls-tree -r --name-only origin/claude/amsterdam-handoff-preserve-hlhyp8 -- drafts/` and compare against the makers in `origin/main`'s `Tours.json`.

---

## PENDING — staged, awaiting narration audio

Every pending tour below is **image-complete** (heroes + galleries live on gh-pages). The
**only** missing ingredient is narration MP3s. No draft audio is staged for any of these yet.

| City | Pending tours | Breakdown | MP3s needed | Staging branch | Maker at wire-in |
|------|--------------:|-----------|------------:|----------------|------------------|
| 🇩🇪 Berlin | 36 | 31 single + 5 walks (intro+5 / intro+5 / intro+4 / intro+4 / intro+3) | 57 | `claude/amsterdam-handoff-preserve-hlhyp8` | **new** Atlas Studio BER |
| 🇦🇪 Dubai | 26 | 22 single + 4 walks (intro+4 / intro+4 / intro+3 / intro+3) | 40 | `claude/amsterdam-handoff-preserve-hlhyp8` | **new** Atlas Studio DXB |
| **TOTAL PENDING** | **62** | | **97** | | |

_(✅ 🇪🇸 Madrid = DONE (2026-07-25, PR #435): **34 tours LIVE** — 30 single-stop + **4 walks** (Madrid de los Austrias, Paseo del Arte, El Retiro, Royal Madrid) under new maker **Atlas Studio MAD**. 55 MP3s. Note: the staged set was **30 singles / 55 MP3s**, not the 31/56 recorded here — the old figure was one over. Owner audio arrived complete, matching the staged drafts 1:1.)_
_(✅ 🇮🇹 Rome = DONE (2026-07-27): **30 tours LIVE** — 25 single-stop + **5 walks** (Ancient Rome, The Baroque Heart, The Ghetto and Trastevere, The Vatican and the Borgo, The Aventine and Testaccio) under new maker **Atlas Studio ROM**. 53 MP3s, 6,866 s narration. The delivery also contained **7 extra singles (25–31)** narrated after the image-staging session — Piazza del Quirinale, Monti, Santa Maria Maggiore, San Giovanni in Laterano, Trajan's Column, Porta San Sebastiano, Testaccio. They have **no scripts and no staged images** (Trajan's Column + Testaccio have a walk-only hero and nothing else), so they were NOT wired. Their audio is banked on gh-pages under its eventual slug (`piazza-quirinale.mp3`, `monti.mp3`, `santa-maria-maggiore.mp3`, `san-giovanni-laterano.mp3`, `trajans-column.mp3`, `porta-san-sebastiano.mp3`, `testaccio.mp3`) — see the new PENDING row below.)_
_(✅ 🇳🇱 Amsterdam = DONE (2026-07-16, PR #401): **38 tours LIVE** — 33 single-stop + **5 walks** (Canal Ring, Old Side, Museum Quarter, Jordaan, Jewish Quarter) under new maker **Atlas Studio AMS**. 64 MP3s. Sensitivity honored on the Jewish Quarter + De Wallen.)_
_(✅ 🇺🇸 Los Angeles = DONE (2026-07-15, PR #390): **42 tours LIVE** — 38 single-stop + **4 walks** (Beachfront, Downtown LA, Museum Row, **Hollywood Boulevard**) under new maker **Atlas Studio LAX**. 64 MP3s. Note: LA turned out to be 38 singles + 4 walks (the old "36 + 3" count was low, and a Hollywood walk was added at wire-in). Memorial Coliseum + The Huntington shipped with `transcriptText: null` — scripts never provided as text; trivial backfill when they arrive.)_
_(🇬🇧 London — "The Measure of the World" (Greenwich, 7-track walk) **went LIVE 2026-07-08, PR #378** — removed from pending. It was the last staged London tour.)_
_(✅ Paris = DONE: **45 single-stop tours LIVE** (PR #374) + **all 5 walks LIVE** — Le Marais (#379), Montmartre (#380), The Triumphal Way (#381), Paris Islands (#382), The Left Bank (#383). Nothing Paris pending.)_
_(✅ 🇨🇦 Toronto = DONE (2026-07-10): **all 42 tours LIVE** — 38 single-stop (10 batch A + 28 PR #384) + **all 4 walks** (Old Town #385, Museum Mile #386, Downtown Spine #387, Immigrant West/Kensington #388). Nothing Toronto pending.)_

### Per-city detail

**🇺🇸 Los Angeles — ✅ LIVE (2026-07-15, PR #390)** — all **42 tours** under **Atlas Studio LAX**: 38 single-stop + 4 walks (Beachfront, Downtown LA, Museum Row, Hollywood Boulevard). Nothing pending. (Coliseum + Huntington `transcriptText: null` — backfill when scripts arrive; LA CC image credits in `drafts/CREDITS.md`, Los Angeles row.)

**🇪🇸 Madrid — ✅ LIVE (2026-07-25, PR #435)** — all **34 tours** under **Atlas Studio MAD** (`980300bd-fc2c-56cc-8960-bcf90414c206`): 30 single-stop (`drafts/madrid-batch1..7`) + 4 walks — `madrid-austrias` (intro+5, 1.1 km) · `madrid-paseo-del-arte` (intro+6, 1.3 km) · `madrid-retiro` (intro+5, 1.8 km) · `madrid-royal` (intro+5, 1.4 km). 55 MP3s, 6,459 s of narration. Nothing pending. Singles ship geofenced at **30 m** (the catalog-wide city-launch default) rather than the "~40 m" the batch READMEs suggested; walk stops 40 m with a manual intro. Credits: `drafts/CREDITS.md` + `drafts/madrid-batch3/IMAGE-CREDITS-madrid-batch3.txt`.

**🇳🇱 Amsterdam — ✅ LIVE (2026-07-16, PR #401)** — all **38 tours** under **Atlas Studio AMS**: 33 single-stop + 5 walks (Canal Ring, Old Side, Museum Quarter, Jordaan, Jewish Quarter). Nothing pending. Amsterdam CC image credits in `drafts/CREDITS.md`.

<details><summary>(staging detail — for reference)</summary>

**🇳🇱 Amsterdam** — `drafts/amsterdam-batch1` (33 single-stop) + 5 walks:
- `amsterdam-canalring-walk` (intro+5) · `amsterdam-oldside-walk` (intro+6) · `amsterdam-museumquarter-walk` (intro+5) · `amsterdam-jordaan-walk` (intro+5) · `amsterdam-jewishquarter-walk` (intro+5)
- All walks reuse live single-stop heroes (zero new image work). Full spec in each folder's README + `drafts/amsterdam-batch1/README.md` (master pick-map). Credits: `drafts/CREDITS.md` (Amsterdam, 22). New maker **Atlas Studio AMS** 🇳🇱.
</details>

**🇨🇦 Toronto — ✅ COMPLETE (2026-07-10)** — all **42 tours LIVE** under Atlas Studio YYZ: 38 single-stop (10 batch A + 28 PR #384) + all 4 walks (Old Town #385, Museum Mile #386, Downtown Spine #387, Immigrant West/Kensington #388). Nothing pending.

**🇫🇷 Paris — 5 multi-stop walks** (on `dreamy-wozniak-nM6a4`; wire under the existing **Atlas Studio PAR** maker):
- ~~`paris-marais` — "Le Marais"~~ — **LIVE 2026-07-08 (PR #379)**, 6 tracks
- ~~`paris-montmartre` — "Montmartre"~~ — **LIVE 2026-07-08 (PR #380)**, 6 tracks
- ~~`paris-triumphalway` — "The Triumphal Way"~~ — **LIVE 2026-07-08 (PR #381)**, 7 tracks
- ~~`paris-islands` — "Paris Islands"~~ — **LIVE 2026-07-09 (PR #382)**, 6 tracks
- ~~`paris-leftbank` — "The Left Bank"~~ — **LIVE 2026-07-09 (PR #383)**, 7 tracks — **all 5 Paris walks now live**
- Reuse the 45 live single-stop Paris heroes where stops overlap; a few fresh walk images already staged (Îles hero, Marais Musée Picasso — CC credits in `IMAGE-CREDITS-paris-batch1.txt`). READMEs say "create the PAR maker" — **stale**: PAR now exists, so walks wire straight in.

**🇨🇦 Montreal — ✅ LIVE (2026-07-28)** — all **29 tours** under **Atlas Studio YUL** (`4f7241f0-9392-54a4-8807-24fd959e61fe`): 25 single-stop (geofenced 30 m) + 4 walks — `montreal-oldmontreal-walk` (intro+5, 1.5 km, history) · `montreal-mountroyal-walk` (intro+4, 1.8 km, natureAndParks) · `montreal-plateaumileend-walk` (intro+4, 3.0 km, culturalHeritage) · `montreal-downtown-walk` (intro+4, 1.5 km, culturalHeritage). **46 MP3s, 90m13s narration** (57m10 singles + 33m03 walks). Owner audio arrived complete and matched the staged drafts 1:1 — the numbering gaps (13, 18, 19, 20, 28, 29) in the delivery are exactly the scripts that were never written. Nothing Montreal pending. Credits: `drafts/CREDITS.md` (Montreal — 19 CC-credited).

⚠️ **Mount Royal's walk hero was an open question the staging README flagged owner-to-confirm** — the Kondiaronk Belvedere (the payoff view) vs the Cross (the narrative climax, since the walk is bookended by Maisonneuve's 1643 vow). Wired with the **belvedere**, the README's own stated default. One-line swap if the owner prefers the Cross.

⚠️ **5 singles ship hero-only** — Mary Queen, Place Ville Marie, Square Saint-Louis, The Main, Plateau staircases. Four were logged "gallery pending" at staging; Plateau was designed that way. Backfillable without touching audio.

<details><summary>(staging detail — for reference)</summary>

**🇨🇦 Montreal** — **29 tours (25 single-stop + 4 walks)**, new maker **Atlas Studio YUL** 🇨🇦. Image-staged 2026-07-13:
- **Batch 1 (Old Montreal, 5):** Notre-Dame/Place d'Armes, Place Jacques-Cartier/City Hall, Old Port, Pointe-à-Callière, Bonsecours Market+chapel. (`drafts/montreal-batch1/README.md`)
- **Batch 2 (4):** Château Ramezay, Habitat 67, McGill/Golden Square Mile, Christ Church Cathedral. (`drafts/montreal-batch1/README.md`)
- **Batch 3 (16):** Mary Queen of the World, Place Ville Marie/RÉSO, Dorchester/Sun Life, Quartier des Spectacles, Chinatown, Mount Royal/Kondiaronk, St Joseph's Oratory, Plateau staircases, Square Saint-Louis, The Main, Mile End, Jean-Talon Market, The Village, Botanical/Biodome, Lachine Canal, Atwater Market. (`drafts/montreal-batch3/README.md`)
- **4 walks:** `montreal-oldmontreal-walk` (intro+5) · `montreal-mountroyal-walk` (intro+4) · `montreal-plateaumileend-walk` (intro+4) · `montreal-downtown-walk` (intro+4). Each has its own README wire-in spec; all reuse single-stop heroes except Mount Royal (3 new images: entrance, climb, Cross).
- **MP3s needed: 46** = 25 singles + 21 walk tracks. Credits: `drafts/CREDITS.md` (Montreal — 15 batch 1-2 + 4 batch 3/walk = 19 CC-credited; almost all batch-3 is owner/ship-safe).
</details>

**🇮🇹 Rome — ✅ LIVE (2026-07-27)** — all **30 staged tours** under **Atlas Studio ROM** (`d5939cce-c156-5316-984a-6259aadd8be2`): 25 single-stop (geofenced 30 m) + 5 walks — `rome-ancientrome-walk` (intro+5, 1.5 km) · `rome-baroqueheart-walk` (intro+5, 2.0 km) · `rome-ghettotrastevere-walk` (intro+5, 2.5 km) · `rome-vaticanborgo-walk` (intro+4, 1.25 km) · `rome-aventinetestaccio-walk` (intro+4, 2.5 km). 53 MP3s, 6,866 s narration. Credits: `drafts/CREDITS.md` (Rome — 6 CC-credited: Ara Pacis ×3, Piazza Barberini ×2, Testaccio ×1).

**🇮🇹 Rome — ✅ the 7 extras are LIVE too (2026-07-27, PR #452).** Piazza del Quirinale · Monti · Santa Maria Maggiore · San Giovanni in Laterano · Trajan's Column · Porta San Sebastiano · Testaccio — all single-stop, geofenced 30 m, 1,041 s of narration. **Rome total: 37 tours (32 single + 5 walks). Nothing Rome pending.**

**How the gap happened (worth knowing — it can recur):** the scripts existed all along. Rome script-sessions 3 and 4 (14–15 July) produced stops 25–31, and the session-4 handoff states "Singles: ALL 33 non-gated complete." But the **image-staging session was only ever handed 01–24 plus the late-added #46** — its README says so directly ("gaps 25–45 were never uploaded as singles") — so images were chosen only for what it received. **The break was in the handoff between the scriptwriting chats and the staging chat, not in the writing.** When a city's scripts and its image staging happen in different sessions, reconcile the master list against what staging actually received *before* staging closes.

**Images:** 3 heroes owner-supplied (Monti, Trajan's Column, Porta San Sebastiano); the rest sourced. ⚠️ `trajans-column_hero.webp` and `testaccio_hero.webp` were **overwritten** — they were walk-only images, so the Ancient Rome and Aventine/Testaccio walk stop images changed too (deliberate; both improvements).


**🇦🇪 Dubai** — **26 tours (22 single-stop + 4 walks)**, new maker **Atlas Studio DXB** 🇦🇪. Staged 2026-07-27 (scripts + images; awaiting narration). **MP3s needed: 40** = 22 singles + 18 walk tracks.
- **Batch 1 (22 single-stop)**, `drafts/dubai-batch1/`, in the owner's script order: Al Fahidi · Abra Crossing · Gold Souk · Spice Souk · Al Seef · Burj Khalifa · Dubai Fountain · Museum of the Future · Jumeirah Mosque · Etihad Museum · Textile Souk · Al Shindagha · Al Fahidi Fort · Dhow Wharfage · Dubai Frame · DIFC Gate · Alserkal Avenue · Kite Beach · Madinat Jumeirah · Marina Walk · JBR The Beach · Palm West Beach.
- **4 walks:** `dubai-creekcrossing-walk` (intro+4: textile souk, abra crossing, spice souk, gold souk) · `dubai-oldquarter-walk` (intro+4: Al Shindagha, Al Fahidi Fort, Al Fahidi lanes, Al Seef) · `dubai-downtown-walk` (intro+3: Burj Park, Dubai Fountain, Souk Al Bahar bridge) · `dubai-marinajbr-walk` (intro+3: Marina Walk, the seam, JBR The Beach).
- **Images:** ~32 pushed to `gh-pages` on 2026-07-27 across 9 commits (`35dc58e`, `47ef5ad`, `df2aff4`, `8a2bc43`, `e1c0451`, `788e719`, `d0cea4e`, `0d69d76`, `0a94484`), plus `dubai-fountain_*` staged earlier. Two walk-only stop images exist (`downtown_stop3` = Souk Al Bahar, `marinajbr_stop2` = the seam).
- **⚠️ Dubai has NO master pick-map README**, unlike every other staged city (Montreal, Berlin, Madrid, Rome all have one per batch folder). **So slug↔coord↔category↔hero/gallery assignments are not written down anywhere.** A wire-in session will have to reconstruct them from the scripts and the gh-pages filenames, or the staging session needs to write the README first. **Verify per-tour image coverage before promising a launch** — it has not been audited here.

**🇩🇪 Berlin** — **36 tours (31 single-stop + 5 walks)**, new maker **Atlas Studio BER** 🇩🇪. Complete 2026-07-21 (image-staged; awaiting narration):
- **Batch 1 (31 single-stop):** Brandenburg Gate, Reichstag, Holocaust Memorial, Bebelplatz, Museum Island, Humboldt Forum, Alexanderplatz, Gendarmenmarkt, Checkpoint Charlie, Bernauer Strasse, East Side Gallery, Potsdamer Platz, Oberbaumbrücke, Topography of Terror, Gedächtniskirche, Tiergarten/Siegessäule, Hackesche Höfe, Neue Synagoge, Nikolaiviertel, Tränenpalast, Neue Wache, Karl-Marx-Allee, Kollwitzplatz/Wasserturm, Mauerpark, Tempelhofer Feld, Charlottenburg, Kulturforum, Band des Bundes, Treptower Park, Landwehrkanal/Maybachufer, Nollendorfplatz. Master pick-map (slug/coord/category/hero+gallery/credit): `drafts/berlin-batch1/README.md`.
- **5 walks:** `berlin-imperialspine-walk` (intro+5, Unter den Linden) · `berlin-ghostline-walk` (intro+5, Bernauer Strasse Wall line) · `berlin-coldwarcentre-walk` (intro+4) · `berlin-scheunenviertel-walk` (intro+4) · `berlin-riverborder-walk` (intro+3). Each folder has its own README wire-in spec (per-stop image + coord + centroid + walking distance).
- **Walk images:** Imperial Spine + Cold War Centre reuse only live single-stop heroes; **7 walk-only new images** staged (Ghost Line: Nordbahnhof, steel-rod border strip, Chapel of Reconciliation, preserved Wall/hero; Scheunenviertel: Haus Schwarzenberg, Große Hamburger deportation memorial; River Border: East Side Park).
- **Sensitivity honored (dignified only, no graphic imagery):** Holocaust Memorial, Bebelplatz book-burning memorial, Topography of Terror (documentary, no swastika close-ups), Neue Synagoge (exteriors/dome), Große Hamburger deportation memorial, Neue Wache (Kollwitz Pietà), Treptower Park Soviet memorial (soldier/child + banners, no swastika close-ups), Nollendorfplatz pink-triangle history, Bernauer Strasse (owner-pasted).
- **MP3s needed: 57** = 31 singles + 26 walk tracks. Credits: `drafts/CREDITS.md` (Berlin — **~26 CC-credited** across Topography ×5, Neue Wache ×3, Hackesche ×3, Neue Synagoge ×2, Tränenpalast ×3, Bebelplatz ×2, + Karl-Marx-Allee, Kollwitz, Nollendorfplatz heroes, and the 7 walk-only images; everything else ship-safe/owner-pasted).

_(🇬🇧 London — Greenwich walk "The Measure of the World" **went LIVE 2026-07-08, PR #378**. It was the last staged London tour; London is now fully wired.)_

---

## LIVE — done, for reference (do not re-stage)

As of 2026-07-16, `origin/main` = **15 makers / 828 tours** (Supabase upsert-accumulates more makers — assert on tour counts). Live cities:

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
| Seoul | 43 | SEL | launched 2026-07-15 (PR #389) — 40 single + 3 walks |
| **Los Angeles** | **42** | **LAX** | ✅ **launched 2026-07-15 (PR #390)** — 38 single-stop + **4 walks** (Beachfront, Downtown LA, Museum Row, Hollywood Boulevard) |
| **Amsterdam** | **38** | **AMS** | ✅ **launched 2026-07-16 (PR #401)** — 33 single-stop + **5 walks** (Canal Ring, Old Side, Museum Quarter, Jordaan, Jewish Quarter) |

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

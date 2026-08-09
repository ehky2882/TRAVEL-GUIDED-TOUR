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
- **🔴 THIS FILE LIVES ON `main`. Read it — and write it — from `origin/main`, never from a
  staging branch.** Staged drafts (`drafts/<city>-batch*`, `drafts/<city>-*-walk`) stay on their
  branch and **never reach `main`**, so this tracker is the *only* cross-session signal that a
  staged city exists at all. A staging branch can sit 100+ commits behind `main` for weeks, and
  its copy of this file will be stale and will contradict reality (this happened 2026-07-28: a
  branch copy still listed Rome as pending two days after Rome went live).
  - **Read at session start:** `git show origin/main:drafts/AUDIO-PENDING-SURVEY.md`
  - **Write as soon as a batch is staged** — a docs-only PR straight off `origin/main`
    (auto-merge class, ~2 min). Do **not** wait until the whole city is finished, and never let
    the row exist only on the staging branch.
  - **Check `gh pr list --state open` immediately before editing this file, not just at session
    start.** Frequent small edits collide: on 2026-07-28 two sessions opened PRs 8 minutes apart
    (#463 Montreal wire-in, #464 Dubai staging row) that both touched this file *and* `CLAUDE.md`,
    neither aware of the other. If another PR is already touching it, let the **content wire-in
    land first**, then rebase the docs PR onto it — a wire-in carries `Tours.json` and is by far
    the more expensive thing to re-resolve.
- The counts here must match reality; if in doubt, re-verify against `origin/main`'s
  `TRAVEL GUIDED TOUR/Resources/Tours.json` (a tour is LIVE iff it's in that file) and against
  `git ls-tree -r --name-only origin/gh-pages | grep audio/` (audio staged iff the slug's
  `.mp3` is there).

**Last verified:** 2026-08-09 (🇺🇸 **Chicago COMPLETE** — 30 tours live under Atlas Studio ORD, the 27th maker; catalog 1256 tours / 1596 stops. **The final queue drain: the PENDING table is now EMPTY for the first time since it was created.** Chicago's narration arrived as **53 WAVs** (48 kHz mono — the first non-MP3 delivery; transcoded to the catalog's 44.1 kHz/128 kbps MP3), matching the staged scripts 1:1 including the documented numbering gaps. Detail in the per-city section below.)

**Previously verified:** 2026-08-08 (🇦🇷 **Buenos Aires COMPLETE** — 36 tours live under Atlas Studio BUE, the 26th maker and the first Argentine city; catalog 1226 tours / 1543 stops. **Never in this table** — it arrived complete (audio + scripts + images in one Dropbox `/scl/fo/` drop) and was wired the same day, like Rio/São Paulo/Marrakech.)

**Previously verified:** 2026-08-07 (🇲🇦 **Marrakech COMPLETE** — 26 tours live under Atlas Studio RAK, the 25th maker and the first African city; catalog 1190 tours / 1497 stops. **Never in this table** — it arrived complete (audio + scripts + images in one Dropbox `/scl/fo/` drop) and was wired the same day, like Rio/São Paulo. **Pending queue is unchanged: Chicago alone, 30 tours / 53 MP3s.**)

> ⚠️ **This file went stale within a day and told a session the wrong thing.** On 2026-07-28 it said the queue was "Montreal + Berlin only"; **Dubai had been script- and image-staged on 2026-07-27** by a parallel session that added its drafts to `claude/amsterdam-handoff-preserve-hlhyp8` and pushed ~32 images to `gh-pages` **without updating this file**. A session then reported "queue is down to Berlin only" to the owner, who corrected it. **The UPDATE RULE above is not optional, and it binds the *staging* session as much as the wire-in session.** When in doubt, re-derive rather than trust the table: `git ls-tree -r --name-only origin/claude/amsterdam-handoff-preserve-hlhyp8 -- drafts/` and compare against the makers in `origin/main`'s `Tours.json`.

---

## PENDING — staged, awaiting narration audio

**🎉 NOTHING IS PENDING. The queue is empty (first time ever, 2026-08-09) — Chicago was the
last staged city and it is live.** Five singles the Chicago master list marks as drafted
(18 Wrigley Field, 19 Lincoln Park, 22 Gold Coast/Astor, 26 Wicker Park, 27 The 606) were
never delivered as scripts, images or audio — **if they ever arrive they are a second batch**
and get a fresh row here, per the staging rule below.

| City | Pending tours | Breakdown | MP3s needed | Staging branch | Maker at wire-in |
|------|--------------:|-----------|------------:|----------------|------------------|
| **TOTAL PENDING** | **0** | | **0** | | |

_(✅ 🇺🇸 **Chicago = DONE (2026-08-09): 30 tours LIVE** — 25 single-stop (geofenced 30 m) + **5 walks** (`chicago-riverwalk-walk` "The Riverwalk", intro+5, 2.0 km; `chicago-loopskyscraper-walk` "The Loop — Where the Skyscraper Was Born", intro+5, 0.55 km; `chicago-lakefront-walk` "The Lakefront — Millennium Park to Museum Campus", intro+5, 2.4 km; `chicago-magmile-walk` "The Magnificent Mile — DuSable Bridge to the Water Tower", intro+4, 0.8 km; `chicago-pilsen-walk` "Pilsen — Eighteenth Street, East to West", intro+4, 1.8 km) under new maker **Atlas Studio ORD** (`f34cd76e-1e41-5c38-865d-d8eccd775cd3`) — the **27th maker**. 53 tracks, 6,238 s (~1h44m). **The first non-MP3 delivery: 53 WAVs at 48 kHz mono**, transcoded to 44.1 kHz/128 kbps MP3 at wire-in. Delivery matched the staging exactly, including the five documented numbering gaps. ⚠️ At wire-in the visual audit found **tour 02's staged hero showed the WRONG BRIDGE** (a LaSalle-area bascule, not the DuSable) — its gallery `_2` was the real DuSable and was promoted; and **riverwalk walk stop 1's staged image looked the wrong direction** (east at the St. Regis, not northwest at Wolf Point/the Mart) — swapped to `merchandise-mart_hero`, shot from the listener's exact spot. Two byte-identical cross-tour pairs deduped. 🔴 Pilsen walk stops 1+3 ship with the documented UNRESOLVED mural rights (owner-directed; `drafts/CREDITS.md`).)_

_(✅ 🇦🇷 **Buenos Aires = DONE (2026-08-08): 36 tours LIVE** — 34 single-stop (geofenced 30 m) + **2 walks** (`bue-uba-walk` "Universidad de Buenos Aires", intro+3, 1.0 km; `bue-tresdefebrero-walk` "Parque Tres de Febrero", intro+7, 4.8 km) under new maker **Atlas Studio BUE** (`64f37bdd-7cb4-5727-b525-6a801162ff9a`) — the **26th maker and the first Argentine city**. 46 MP3s, 6,156 s (~1h43m). **Never in this table** — arrived complete (audio + scripts + 120 already-1200×900 images in one Dropbox `/scl/fo/` drop) and wired the same day; **the first drop with pre-structured walk folders**. ⚠️ Estación de La Plata, Museo de Arte de Tigre and Alo's Bistro ship with their own `city` (La Plata / Tigre / San Isidro). ⚠️ Slug collision dodged: Rio owns `catedral-metropolitana`, so BUE's cathedral is `catedral-metropolitana-bue`.)_

_(✅ 🇲🇦 **Marrakech = DONE (2026-08-07): 26 tours LIVE** — 26 single-stop (geofenced 30 m), no walks, under new maker **Atlas Studio RAK** (`c4e51efc-846e-5e78-b699-67e7f9d203e8`) — the **25th maker and the first African city**. 26 MP3s, 3,093 s (~51.5m). **Never in this table** — arrived complete (audio + scripts + 109 already-1200×900 images in one Dropbox `/scl/fo/` drop) and wired the same day. First Arabic-script city (bilingual `English | العربية` on 18 of 26). ⚠️ Aït Benhaddou ships with `city: "Aït Benhaddou"` (~180 km southeast, near Ouarzazate).)_

_(✅ 🇩🇪 **Berlin = DONE (2026-08-06): 36 tours LIVE** — 31 single-stop (geofenced 30 m) + **5 walks** (The Imperial Spine, The Ghost Line, Cold War Centre, The Scheunenviertel, The River Border) under new maker **Atlas Studio BER** (`a0717b10-a295-5ab5-a875-d5a9587d0274`) — the **24th maker**. 57 MP3s, 7,489 s (~2h05m), the largest narration drop to date. **This one DID come from this table** — the first queue drain since Montreal, since Rio/São Paulo/Dubai all arrived complete and jumped it. Delivery matched the staging exactly: 57 MP3s, 1:1 with the scripts, nothing spare or missing, via a Dropbox `/scl/fo/` folder link that downloaded first try. Detail in the per-city section below.)_

_(✅ 🇧🇷 **São Paulo = DONE (2026-08-04): 42 tours LIVE** — 41 single-stop (geofenced 30 m) + **1 walk** (`sao-ibirapuera-walk` "Ibirapuera Park", manual intro + 6 stops at 40 m, 3.0 km) under new maker **Atlas Studio SAO** (`b366d042-881b-5226-aaa8-1dce36c7a2cb`) — the **23rd maker**, and Brazil's second bureau. 48 MP3s, 5,279 s narration. **Never in the PENDING table** — it arrived complete (audio + scripts + images in one Dropbox `/scl/fo/` drop) and was wired the same day, exactly like Rio. All 173 images arrived already 1200×900, so no image work was needed. ⚠️ Mercado Municipal de Campinas ships with `city: "Campinas"` (~90 km away); MAC USP appears twice by design (single-stop museum tour + walk stop 6 rooftop).)_
_(✅ 🇧🇷 Rio de Janeiro = DONE (2026-08-01): **46 single-stop tours LIVE** under **Atlas Studio RIO** — the 22nd maker. 46 MP3s, 5,102 s. Also never in the PENDING table; arrived complete and wired the same day.)_
_(✅ 🇦🇪 Dubai = DONE (2026-07-31): **26 tours LIVE** — 22 single-stop + **4 walks** (The Creek Crossing, The Old Quarter, The Downtown Loop, Marina & JBR) under new maker **Atlas Studio DXB** — the **21st maker**. 40 MP3s, 5,012 s narration. The delivery matched the staging exactly: 22 singles + 18 walk tracks, nothing spare, nothing missing. Detail in the LIVE section below.)_

_(✅ 🇪🇸 Madrid = DONE (2026-07-25, PR #435): **34 tours LIVE** — 30 single-stop + **4 walks** (Madrid de los Austrias, Paseo del Arte, El Retiro, Royal Madrid) under new maker **Atlas Studio MAD**. 55 MP3s. Note: the staged set was **30 singles / 55 MP3s**, not the 31/56 recorded here — the old figure was one over. Owner audio arrived complete, matching the staged drafts 1:1.)_
_(✅ 🇮🇹 Rome = DONE (2026-07-27): **30 tours LIVE** — 25 single-stop + **5 walks** (Ancient Rome, The Baroque Heart, The Ghetto and Trastevere, The Vatican and the Borgo, The Aventine and Testaccio) under new maker **Atlas Studio ROM**. 53 MP3s, 6,866 s narration. The delivery also contained **7 extra singles (25–31)** narrated after the image-staging session — Piazza del Quirinale, Monti, Santa Maria Maggiore, San Giovanni in Laterano, Trajan's Column, Porta San Sebastiano, Testaccio. They have **no scripts and no staged images** (Trajan's Column + Testaccio have a walk-only hero and nothing else), so they were NOT wired. Their audio is banked on gh-pages under its eventual slug (`piazza-quirinale.mp3`, `monti.mp3`, `santa-maria-maggiore.mp3`, `san-giovanni-laterano.mp3`, `trajans-column.mp3`, `porta-san-sebastiano.mp3`, `testaccio.mp3`) — see the new PENDING row below.)_
_(✅ 🇳🇱 Amsterdam = DONE (2026-07-16, PR #401): **38 tours LIVE** — 33 single-stop + **5 walks** (Canal Ring, Old Side, Museum Quarter, Jordaan, Jewish Quarter) under new maker **Atlas Studio AMS**. 64 MP3s. Sensitivity honored on the Jewish Quarter + De Wallen.)_
_(✅ 🇺🇸 Los Angeles = DONE (2026-07-15, PR #390): **42 tours LIVE** — 38 single-stop + **4 walks** (Beachfront, Downtown LA, Museum Row, **Hollywood Boulevard**) under new maker **Atlas Studio LAX**. 64 MP3s. Note: LA turned out to be 38 singles + 4 walks (the old "36 + 3" count was low, and a Hollywood walk was added at wire-in). Memorial Coliseum + The Huntington shipped with `transcriptText: null` — scripts never provided as text; trivial backfill when they arrive.)_
_(🇬🇧 London — "The Measure of the World" (Greenwich, 7-track walk) **went LIVE 2026-07-08, PR #378** — removed from pending. It was the last staged London tour.)_
_(✅ Paris = DONE: **45 single-stop tours LIVE** (PR #374) + **all 5 walks LIVE** — Le Marais (#379), Montmartre (#380), The Triumphal Way (#381), Paris Islands (#382), The Left Bank (#383). Nothing Paris pending.)_
_(✅ 🇨🇦 Toronto = DONE (2026-07-10): **all 42 tours LIVE** — 38 single-stop (10 batch A + 28 PR #384) + **all 4 walks** (Old Town #385, Museum Mile #386, Downtown Spine #387, Immigrant West/Kensington #388). Nothing Toronto pending.)_

### 📍 Where the paths in this file actually live

**The pick-map READMEs are on `main`, alongside this file.** As of 2026-07-28 `drafts/` on `main`
holds this tracker, `CREDITS.md`, a [`README.md` index](README.md), and **40 pick-map READMEs** —
one per staged batch or walk, for every city that has one (Amsterdam, Berlin, Dubai, London,
Montreal, Paris, Rome). Every `drafts/<city>-*/README.md` path named below now resolves on `main`.

They did not before. They lived only on their staging branches while this file referenced them by
path, so a session working from `main` — which the UPDATE RULE above tells every session to do —
followed those references to files that were not there, and could reasonably conclude the staging
did not exist. That is fixed: **`main` now answers "what is staged, and how does it wire in"
without checking out a branch.**

**Still branch-only, deliberately:** the narration `.txt` / `_TTS.txt` scripts. They are bulky and
nothing needs them until wire-in. Read them off the branch in the PENDING table's branch column:

```bash
git show origin/<branch>:drafts/<folder>/01_example.txt
git ls-tree -r --name-only origin/<branch> -- drafts/<folder>/
```

**When you stage a new city, land its READMEs on `main` in the same docs-only PR that updates this
file.** If they only ever exist on the staging branch, this whole problem comes straight back.

**Madrid, Toronto and Los Angeles have no pick-map READMEs anywhere** — their staging branches were
deleted after wire-in and the READMEs went with them. All three are fully live, so nothing is
blocked, but their image-pick provenance is unrecoverable. Another reason not to leave the only
copy on a branch.

**Two references that resolve nowhere at all:** `drafts/pending-tours.json` (`CLAUDE.md`,
`ROADMAP.md`) and `scripts/add-tour.swift` (`ROADMAP.md`) — leftovers from the pre-2026 staging
workflow. Delete the references next time those docs are touched.

### 🖼️ Image attribution ledger — `drafts/CREDITS.md`

**This file now lives on `main`, alongside this one.** It did not until 2026-07-28: the ledger
recording every attribution obligation on **already-shipped** images existed *only* on a staging
branch, while this tracker referenced it nine times. Any session working from `main` — which is
what the UPDATE RULE above now tells every session to do — followed those references to a file
that was not there. Same failure mode as the staged-tours drift, on the file with legal
obligations attached. **Both files are on `main`; keep them there and edit them from `origin/main`.**

**Audited 2026-07-28 — 115 rows, 111 verified, 4 failed.** Every row was machine-checked by
comparing the published `gh-pages` image against the Commons file the row names. The failures are
recorded in full at the top of `CREDITS.md`; two are on **live** cities:

- **`waterlooplein-rembrandt-house_hero.webp` (Amsterdam — LIVE)** — credits a photograph that is
  demonstrably not the one shipping; no Commons file matches the published image, which points to
  ship-safe stock. The row was asserting an obligation that probably does not exist.
- **`testaccio_hero.webp` (Rome — LIVE)** — the image was overwritten at the Rome-extras wire-in
  and the credit row was not moved with it, so it describes a superseded picture.
- **`ghostline_stop4` / `ghostline_hero`, `kollwitzplatz_2` (Berlin — staged)** — the first is
  unidentified (fetch log says CC0, so likely no obligation); the second was off by two frames in
  the same public-domain series and is corrected.

**Root cause, and the rule that follows from it:** those attributions were gathered by matching
image *dimensions* against a Commons category listing, which silently picks the wrong file whenever
two images in a category share a size. **Never attribute by dimension match. Hash the local
original and query `list=allimages&aisha1=<sha1>`** — exact file identity, not a guess.

**And: overwriting a published image filename silently invalidates its credit row.** Rome proves it.
If you replace an image under an existing name, update `CREDITS.md` in the same commit.

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


**🇦🇪 Dubai** — ✅ **LIVE 2026-07-31. 26 tours (22 single-stop + 4 walks)** under new maker **Atlas Studio DXB** 🇦🇪 (`e94b8814-2c31-5113-963c-1743e6c86b4b` = uuid5 `atlas-maker:dxb`) — the **21st maker**. Staged 2026-07-27 (scripts + images); narration arrived 2026-07-31 and wired in the same day. **40 MP3s** = 22 singles + 18 walk tracks, 5,012 s (~1h24m). Catalog 1014 → 1040 tours / 1280 → 1320 stops.
- **Batch 1 (22 single-stop)**, `drafts/dubai-batch1/`, in the owner's script order: Al Fahidi · Abra Crossing · Gold Souk · Spice Souk · Al Seef · Burj Khalifa · Dubai Fountain · Museum of the Future · Jumeirah Mosque · Etihad Museum · Textile Souk · Al Shindagha · Al Fahidi Fort · Dhow Wharfage · Dubai Frame · DIFC Gate · Alserkal Avenue · Kite Beach · Madinat Jumeirah · Marina Walk · JBR The Beach · Palm West Beach.
- **4 walks:** `dubai-creekcrossing-walk` (intro+4: textile souk, abra crossing, spice souk, gold souk) · `dubai-oldquarter-walk` (intro+4: Al Shindagha, Al Fahidi Fort, Al Fahidi lanes, Al Seef) · `dubai-downtown-walk` (intro+3: Burj Park, Dubai Fountain, Souk Al Bahar bridge) · `dubai-marinajbr-walk` (intro+3: Marina Walk, the seam, JBR The Beach).
- **Images: 71 files on `gh-pages`, coverage AUDITED 2026-07-28** — every one of the 22 singles has `<slug>_hero.webp` plus its full gallery, exactly as the pick-map records; no strays, nothing missing. Pushed 2026-07-27 across 9 commits (`35dc58e`, `47ef5ad`, `df2aff4`, `8a2bc43`, `e1c0451`, `788e719`, `d0cea4e`, `0d69d76`, `0a94484`), plus `dubai-fountain_*` staged earlier.
- **⚠️ The two walk-only stop images were RENAMED 2026-07-28** — `downtown_stop3` → **`dubai-downtown_stop3.webp`** and `marinajbr_stop2` → **`dubai-marinajbr_stop2.webp`**. `downtown_stop3` was city-ambiguous (LA, Montreal and Dubai all have a Downtown walk), so a future city's walk-stop image would have silently overwritten Dubai's Souk Al Bahar shot — the same class of clobber that hit `trajans-column_hero` and `testaccio_hero` in Rome. Nothing referenced the old names yet, so the rename was free. **Use the new names.**
- **✅ Master pick-map WRITTEN 2026-07-28 — `drafts/dubai-batch1/README.md`** (was the one gap flagged here). Carries slug ↔ script ↔ category ↔ coordinate ↔ hero/gallery ↔ tags ↔ credit for all 22 singles, plus the wire-in checklist for the DXB maker. **Each of the 4 walks now has its own README too** — per-stop image + coordinate, computed centroid, walking distance (taken from what each script itself claims), and the hero choice with its alternative named. Dubai is now documented to the same standard as Berlin/Madrid/Rome/Montreal.

- **✅ transcriptText gotcha handled at wire-in.** Singles **#17, #20, #21, #22** and the Creek Crossing / Old Quarter walks carried a single `DUBAI NN — …` title line; the Downtown and Marina/JBR walks carried an `ATLAS — DUBAI / Walk Wn / Segment nn / (clean version)` block terminated by `---`. Both shapes stripped, plus **30 `[beat]` markers** — the validator hard-errors on any `\[[A-Za-z]`.
- **⚠️ Two deviations from these READMEs, applied deliberately at wire-in — fix the READMEs before Berlin/Chicago repeat them.**
  1. **Singles set `stop0.imageURL` to the tour hero.** `drafts/dubai-batch1/README.md` says `imageURL: null`, but Montreal, Rome and Madrid set it on **100%** of their singles (353 of 966 catalog-wide, and all of the recent cities). Same class of staleness as the Rome READMEs saying `kind: "singleStop"` when the catalog value is `single`.
  2. **Walk galleries omit whichever stop image is the tour hero.** Each walk README lists `additionalImageURLs` as *every* stop image in order — but each walk's hero is picked from among those same stop images, so that spec trips the validator's `heroImageURL also appears in additionalImageURLs` error (the carousel renders hero first, then the list, so it would show the same photo twice). Montreal's walks already drop it: 6 stops → 4 gallery entries. Dubai now does the same (5 stops → 3, 4 stops → 2).
- **⚠️ Provenance flags (owner-directed, decide before ship):** `al-shindagha_hero` came from a googleusercontent URL — **license unverifiable**, and upscaled ~1.6× from 1200×550 so it is soft. `difc-gate_hero` is owner-supplied and shows garbled signage text, i.e. likely AI-generated rather than a photograph. Both were shipped at the owner's explicit direction after being flagged.
- **✅ Credits WRITTEN 2026-07-28 — `drafts/CREDITS.md`, Dubai section: 11 credit-required images** (Gold Souk ×2 — not ×4, the other two are stock; Jumeirah Mosque ×3; Al Fahidi Fort ×3; Textile Souk hero; Etihad Museum ×1; Al Shindagha gallery). The DIFC gallery image is **Pexels, ship-safe** — not CC as guessed here. Alserkal hero is **CC0** (no credit). **`al-shindagha_2` is FAL (Free Art License), not CC** — copyleft, same obligation as BY-SA; do not treat it as more permissive. Attributions were resolved by **SHA-1 reverse-lookup** against the Commons `allimages` API, i.e. exact file identity.
**🇺🇸 Chicago — ✅ LIVE (2026-08-09)** — all **30 tours (25 single-stop + 5 walks)** under new maker **Atlas Studio ORD** 🇺🇸 — the **27th maker** in the end (staging predicted 22nd; five complete-drop cities jumped the queue in between). Everything below is the staging record, kept for provenance; wire-in detail in `archive/HANDOFF-260809.md`.
Maker id (uuid5 of `atlas-maker:ord`): `f34cd76e-1e41-5c38-865d-d8eccd775cd3`. Staged 2026-07-29/30.
**MP3s needed: 53** = 25 singles + 28 walk tracks (three walks of intro+5, two of intro+4).

- **Master pick-map: `drafts/chicago-batch1/README.md`** — all 25 singles with slug, script, category, coordinate,
  image count, tags and credit, tag-validated against the controlled vocabulary. **Written as staging went, not
  after** — the lesson from Dubai.
- **Singles: image staging COMPLETE and audited** — 84 files, every hero present, every gallery contiguous from `_2`.
- **⚠️ The script numbering is NOT contiguous: 01–17, 20, 21, 23, 24, 25, 28, 29, 30. Numbers 18, 19, 22, 26 and 27
  were never delivered.** Recorded so nobody assumes a gap means a lost file — the Rome failure, written down in
  advance. If those five exist they are a second batch.
- **5 walks** — three of intro + 5 stops, two (the Magnificent Mile, Pilsen) of intro + 4:
  - `chicago-loopskyscraper-walk` — *Where the Skyscraper Was Born*. **COMPLETE.** 3 new images (hero, stop 1, stop 4);
    stops 2, 3, 5 reuse live single heroes.
  - `chicago-lakefront-walk` — *Millennium Park to Museum Campus*. **COMPLETE.** 1 new image (hero only); **all five
    stops reuse live single heroes**, so it adds no stop images and no credits.
  - `chicago-riverwalk-walk` — *The Riverwalk*. **COMPLETE.** 4 new images (hero, stops 1, 2, 5); stops 3 (Marina
    City) and 4 (DuSable Bridge) reuse live single heroes. **No credits** — Unsplash, Pexels, and one US Coast Guard
    public-domain file. Its README flags a **third transcript header format with a *variable* line count** (two of the
    six scripts carry an extra `SENSITIVITY:` / `DEVICE PAYOFF:` line), so start `transcriptText` after the `---`
    rule rather than counting header lines. Three stop coords **geofence where the listener stands, not the subject**
    — do not "correct" them to the landmark.
  - `chicago-magmile-walk` — *The Magnificent Mile*. **COMPLETE.** Intro + **4** stops (not 5). 2 new images (hero,
    stop 3); stops 1, 2 and 4 reuse live single heroes. **No credits.** Flags a **fourth transcript header format** —
    the fourth line is `Vantage:` not `Voice:`, and **the `_TTS.txt` files carry no header block at all**. The intro
    and stop 1 share an identical coordinate **on purpose**, so the listener is already inside stop 1's geofence when
    the intro ends — the AMNH case `ProximityMonitor` already handles (PR #251). **Not a data bug; do not separate
    them.**
  - `chicago-pilsen-walk` — *Pilsen: Eighteenth Street, East to West*. **COMPLETE.** Intro + **4** stops. 3 new
    images (stops 1, 3, 4); **hero and stop 2 reuse the two live owner images from single tour 25, crossed over** —
    `pilsen-18th-street_2` (spire + hall) is the walk hero, `pilsen-18th-street_hero` (Thalia Hall) is stop 2. Flags a
    **fifth transcript header format** (`Position:`, bare `[beat]` with no asterisks, TTS files heavily phoneticised —
    `transcriptText` MUST come from the clean `.txt`). **Pilsen is a stock desert: 95 images sourced across 4 pools,
    1 usable** — reach for an owner photograph early here. Two Commons traps: a `Pilsen, Chicago` category that
    returns **Plzen, Bohemia**, and **Casa Aztlan has zero files on Commons**.
  - **🔴 `chicago-pilsen-walk` stops 1 and 3 ship with UNRESOLVED MURAL RIGHTS** — the only such case in the whole
    corpus, at the owner's explicit direction after a buildings-only alternative was offered and declined
    (2026-07-30). Stop 1 is Patlan/Valadez's Casa Aztlan mural; stop 3 is Mendoza's station murals incl. the Aztec
    sun stone. In both, the mural is a **principal subject**, so de minimis does not apply. Logged as OPEN in
    `drafts/CREDITS.md`. **Two traps: an owner-supplied photo clears the photographer but NEVER the muralist; and the
    Chicago Picasso's public-domain ruling is a narrow exception that does not generalise.** Single tour 25 stays
    clean (buildings only) — keep it that way.
- **Chicago image-staging is finished end to end** — 25 singles + all 5 walks, every pick-map written.
- **⚠️ Sensitivity — two subjects:**
  - **Tour 02** is pointedly critical of the **Fort Dearborn relief** on the DuSable Bridge, whose 1920s sculptors
    "treated the removal of the Potawatomi from this land as an adventure story." **That relief must not be used as
    an image.**
  - **Riverwalk stop 2 is the Eastland disaster site** — 844 people died there in 1915. Memorial subject; dignified
    treatment only, same standard as Berlin's memorials and Amsterdam's Jewish Quarter. The script itself carries
    `SENSITIVITY: … NO mortality figure. No method detail.` — **honor that in the tour description and stop title too,
    not just the transcript.** The staged image is a Coast Guard wreath-laying from Commons `Category:Eastland
    disaster memorials`, chosen **deliberately over** `Category:Eastland disaster`, which holds 1915 press
    photographs of the recovery including the dead. **Do not re-source that stop from the latter.**
- **⚖️ Two sculpture-copyright cases that point OPPOSITE ways — do not reason from one to the other:**
  - **The Chicago Picasso (tour 14) is PUBLIC DOMAIN** in the US — *Letter Edged in Black Press, Inc. v. Public
    Building Commission of Chicago* (1970). Photographs are usable; only the photographer is credited.
  - **Calder's *Flamingo* (Federal Plaza, Loop walk stop 4) is IN COPYRIGHT** with no such exception. **12 of the 22
    files in `Category:Federal Center (Chicago)` are Calder-dominant**, so the obvious grab is the wrong one.
  - **Pilsen's murals (tour 25) are also in copyright.** That tour is built entirely from buildings, which the US
    architectural exemption covers. Keep it that way.
- **Credits: 18 rows / 17 real obligations** (one is public domain) across 88 images — `drafts/CREDITS.md`, Chicago
  section. All resolved by **SHA-1 reverse-lookup**, never dimension matching.
- **8 owner-supplied images across 6 tours** (Modern Wing, Rookery front, Monadnock, the North Avenue Beach house +
  Chess Pavilion, Thalia Hall ×2, the Obama Center ×2, the 1885 Home Insurance Building). **The pattern is
  consistent: when a script points at something specific and locally known, stock and Commons both fail and an owner
  photograph resolves it faster than more searching.**

**🔴 A REUSE RULE, learned the hard way on Chicago walk 4 — it applies to EVERY walk pick-map in `drafts/`:**

**Verify a reused hero by OPENING THE IMAGE. Never by matching the slug to the stop title.** Walk 4's stop 3 was
about to reuse `michigan-avenue-streetwall_hero` — the slug matches the stop perfectly. The file is an **aerial of
SOUTH Michigan Avenue across Grant Park with Buckingham Fountain in it**, a mile and a half from the stop, on the
wrong half of the street. Nothing but opening it would have caught that; the coordinate on the single (`41.88090` vs
the stop's `41.89305`) confirms it after the fact. **Slugs describe the single's subject, not the walk stop's
vantage.** Every walk in `drafts/` leans on reuse — Berlin's Imperial Spine and Cold War Centre are *entirely*
reuse, and Chicago's Lakefront is all five stops — so **an open-every-reused-hero pass is owed before any of them
ships.**

**🔴 TWO TOOLING DEFECTS FOUND WHILE STAGING CHICAGO — they affect every city, not just this one:**

1. **`wiki_grab.run(..., landscape=True)` silently DROPS PORTRAIT IMAGES.** For a tall subject that discards nearly
   everything. It produced a confident, wrong "no images of this exist" answer for the Obama Center, where **6 of the
   10 usable files were portrait, including the two best.** **Any city where a pool was reported as thin deserves
   re-checking on this basis — tall subjects especially.**
2. **`crop43` CENTRE-CROPS portrait sources**, taking an equal band off top and bottom. On a tower that decapitates
   the building; it cut straight through the Obama Center's carved lettering panel. **A top-biased crop is the right
   default for tall subjects.** This has been applied silently to every portrait source. **Berlin's Water Tower and
   Willis Tower are the likely casualties — check before Berlin ships.**

**Sourcing lessons (full list in the pick-map):** search for the Commons category name, never guess it — five wasted
fetches, including a bare `Monadnock Building` which is **San Francisco's**; **enumerate subcategories**, since the
Obama Center parent holds 8 logo files while a subcategory holds the real photographs; and verify the pixels, never
the result title — rejected this batch were Mexico City's Palacio de Bellas Artes (six times), the White House (seven
times), Fallingwater, the Guggenheim, Brooklyn's Barclays Center, and literal rookeries with egrets in them.

**🇩🇪 Berlin — ✅ LIVE (2026-08-06)** — all **36 staged tours** under **Atlas Studio BER** (`a0717b10-a295-5ab5-a875-d5a9587d0274` = uuid5 `atlas-maker:ber`), the **24th maker**: 31 single-stop (geofenced 30 m) + 5 walks — `berlin-imperialspine-walk` (intro+5, 1.5 km, history) · `berlin-ghostline-walk` (intro+5, 2.0 km, history) · `berlin-coldwarcentre-walk` (intro+4, 2.0 km, history) · `berlin-scheunenviertel-walk` (intro+4, 0.8 km, culturalHeritage) · `berlin-riverborder-walk` (intro+3, 2.0 km, culturalHeritage). **57 MP3s, 7,489 s (~2h05m)** — the largest narration drop to date. Catalog 1128 → 1164 tours / 1414 → 1471 stops. Nothing Berlin pending.

⚠️ **Three deviations from the staged READMEs were applied at wire-in — fix the READMEs before Chicago repeats the first two.** (1) Singles set `stop0.imageURL` to the tour hero, not `null`. (2) Walk galleries omit whichever stop image is also the walk hero, or the validator hard-errors. **Both are the exact errors flagged in the Dubai section below, still unfixed, and they duly recurred.** (3) **`ghostline_hero.webp` and `ghostline_stop4.webp` are byte-identical** (sha256-verified on the live URLs), so `ghostline_stop4` was dropped from the Ghost Line gallery — otherwise the carousel shows the same photo as cover and as slide 4. **The validator cannot catch that class: the URLs differ and both 200.** Only `check-image-duplicates.py` or a manual byte check finds it.

⚠️ **Imperial Spine stop 4 (Lustgarten) shipped with `museum-island_3.webp`, not the staged `museum-island_hero.webp`** — the hero is the **Bode Museum from the water**, 600 m north, while the script names the Altes Museum colonnade, the Dom and the palace facade. Same finding as [PR #475](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/475)'s 94-image reuse audit (still open at wire-in), verified independently by opening the file. **All 21 Berlin walk-stop images were opened and checked against their scripts; the other 20 are correct.** ⚠️ The **single-stop `museum-island` hero is still that Bode photograph** — defensible as a tour cover, but `museum-island_3` is already in its gallery if the owner would rather promote it.

⚠️ **`east-side-gallery_hero` is Vrubel's Brezhnev–Honecker mural**, in copyright, carried on **German freedom of panorama** (§59 UrhG), which does cover permanently-sited public artworks — a different footing from the Chicago Pilsen murals, where the US has no such provision.

⚠️ **2 tours ship hero-only** (Mauerpark, Nollendorfplatz); 4 more have hero + 1 (Bernauer Strasse, Karl-Marx-Allee, Kollwitzplatz, Treptower Park). Backfillable without touching audio.

✅ **The `crop43` portrait-decapitation scare was checked and cleared** — the Wasserturm (`kollwitzplatz_2`) was named as a likely casualty; it is intact base to chimney.

<details><summary>(staging detail — for reference)</summary>

**🇩🇪 Berlin** — **36 tours (31 single-stop + 5 walks)**, new maker **Atlas Studio BER** 🇩🇪. Complete 2026-07-21 (image-staged; awaiting narration):
- **Batch 1 (31 single-stop):** Brandenburg Gate, Reichstag, Holocaust Memorial, Bebelplatz, Museum Island, Humboldt Forum, Alexanderplatz, Gendarmenmarkt, Checkpoint Charlie, Bernauer Strasse, East Side Gallery, Potsdamer Platz, Oberbaumbrücke, Topography of Terror, Gedächtniskirche, Tiergarten/Siegessäule, Hackesche Höfe, Neue Synagoge, Nikolaiviertel, Tränenpalast, Neue Wache, Karl-Marx-Allee, Kollwitzplatz/Wasserturm, Mauerpark, Tempelhofer Feld, Charlottenburg, Kulturforum, Band des Bundes, Treptower Park, Landwehrkanal/Maybachufer, Nollendorfplatz. Master pick-map (slug/coord/category/hero+gallery/credit): `drafts/berlin-batch1/README.md`.
- **5 walks:** `berlin-imperialspine-walk` (intro+5, Unter den Linden) · `berlin-ghostline-walk` (intro+5, Bernauer Strasse Wall line) · `berlin-coldwarcentre-walk` (intro+4) · `berlin-scheunenviertel-walk` (intro+4) · `berlin-riverborder-walk` (intro+3). Each folder has its own README wire-in spec (per-stop image + coord + centroid + walking distance).
- **Walk images:** Imperial Spine + Cold War Centre reuse only live single-stop heroes; **7 walk-only new images** staged (Ghost Line: Nordbahnhof, steel-rod border strip, Chapel of Reconciliation, preserved Wall/hero; Scheunenviertel: Haus Schwarzenberg, Große Hamburger deportation memorial; River Border: East Side Park).
- **Sensitivity honored (dignified only, no graphic imagery):** Holocaust Memorial, Bebelplatz book-burning memorial, Topography of Terror (documentary, no swastika close-ups), Neue Synagoge (exteriors/dome), Große Hamburger deportation memorial, Neue Wache (Kollwitz Pietà), Treptower Park Soviet memorial (soldier/child + banners, no swastika close-ups), Nollendorfplatz pink-triangle history, Bernauer Strasse (owner-pasted).
- **MP3s needed: 57** = 31 singles + 26 walk tracks. Credits: `drafts/CREDITS.md` (Berlin — **~26 CC-credited** across Topography ×5, Neue Wache ×3, Hackesche ×3, Neue Synagoge ×2, Tränenpalast ×3, Bebelplatz ×2, + Karl-Marx-Allee, Kollwitz, Nollendorfplatz heroes, and the 7 walk-only images; everything else ship-safe/owner-pasted).
- **⚠️ Berlin image attributions were WRONG and were corrected 2026-07-28.** They had been produced by matching image *dimensions* against a Wikimedia category listing, which silently picks the wrong file whenever two images in a category share a size. Re-verified by **SHA-1 reverse-lookup** (exact file identity): **9 of the rows were wrong** — all five Topography of Terror rows (wrong author throughout, and `_4` is actually **public domain**, not CC BY-SA), the two Tränenpalast subjects swapped, the Nordbahnhof walk image, and the East Side Park riverbank (credited to the wrong photographer entirely). `drafts/CREDITS.md` now holds the corrected table. **Never attribute by dimension match again — SHA-1 the local file against `list=allimages&aisha1=…`.** Any other city whose credits were gathered the same way is suspect and worth a re-verify pass.

</details>

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

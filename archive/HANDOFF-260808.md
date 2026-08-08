# HANDOFF — 2026-08-08 (session 86, web) — Buenos Aires launched: 36 tours + 26th maker Atlas Studio BUE

**One-line summary:** Buenos Aires goes live as the catalog's **first Argentine city** — 34
single-stop tours + 2 walks under new maker **Atlas Studio BUE** 🇦🇷, wired the same day the
owner's complete Dropbox drop arrived. Catalog **1190 → 1226 tours / 25 → 26 makers /
1497 → 1543 stops**. The audio-pending queue is untouched: **Chicago alone, 30 tours / 53 MP3s.**

Branch: `claude/tourist-upload-assets-kkrbsk`. PR: [#487](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/487).

## What shipped

- **New maker:** Atlas Studio BUE (`64f37bdd-7cb4-5727-b525-6a801162ff9a` = uuid5
  `atlas-maker:bue`, 🇦🇷), the 26th.
- **34 single-stop tours**, geofenced 30 m: Abasto de Buenos Aires · Alo's Bistro · Banco de
  Londres y América del Sur · Bencich Building · Bis Bistró · Buenos Aires Metropolitan
  Cathedral · Café Tortoni · Caminito · Casa Cavia · Casa Rosada · Confitería del Molino ·
  Congreso de la Nación Argentina · Diego Iluminado · El Ateneo Grand Splendid · Encuentro
  Nativo · Escultura Atlas de Recoleta · Estación de La Plata · Florería Atlántico · Fundación
  Proa · Galerías Pacífico · Los Galgos · MALBA · Mercado de San Telmo · Mural de Evita ·
  Museo de Arte de Tigre · Museo Nacional del Cabildo · Nápoles · Palacio Barolo · Puente de
  la Mujer · Recoleta Cemetery — Duarte Family Mausoleum · Roux · Salón 1923 · Teatro Colón ·
  The Obelisk.
- **2 walks — the first drop since Berlin to carry walks:** `bue-uba-walk` "Universidad de
  Buenos Aires" (manual intro + 3 geofenced stops at 40 m, 1.0 km, architecture — the
  never-finished neo-Gothic "Engineering Cathedral" on Las Heras → the Law Faculty's Doric
  temple → Catalano's motionless Floralis Genérica) and `bue-tresdefebrero-walk` "Parque
  Tres de Febrero" (manual intro + 7 geofenced stops at 40 m, 4.8 km, natureAndParks —
  Monumento de los Españoles → Ecoparque → Jardín Japonés → Planetario Galileo Galilei →
  El Rosedal → Museo Sívori → Lago de Regatas).
- **46 MP3s, 6,156 s ≈ 1h43m** (all 44.1 kHz/128 kbps, byte-distinct) + **120 images** to
  `gh-pages` (commit `2346e1b`); Tours.json diff **1,766 insertions / 0 deletions**.
- **Category mix:** 10 foodAndDrink · 7 visualArt · 6 architecture · 5 history ·
  4 culturalHeritage · 1 each sacredSites / musicAndPerformance / literature / natureAndParks.
  Coverage splits between the civic canon (Casa Rosada, Cabildo, Congreso, Teatro Colón, the
  Obelisk, Recoleta Cemetery) and the food/bar scene the city actually runs on (Tortoni, Los
  Galgos, Florería Atlántico, Roux, Bis Bistró, Alo's, Nápoles, Casa Cavia, Salón 1923).

## The delivery — fourth zero-image-work drop

- Dropbox `/scl/fo/` shared-folder link, 111 MB zip, **downloaded first try** with `dl=1` —
  the transport rule holds for the fifth consecutive city.
- **All 120 images arrived already 1200×900**, byte-distinct — no pipeline, no cropping, no
  owner picks, no Gemini gate (the Rio/São Paulo/Marrakech shape).
- Same `output <Name> <lat>, <long>` folder convention. **New shape: two `Multi Stop <name>`
  folders** containing per-stop `output NN <name> <lat>, <long>` subfolders — the first time
  walks arrived pre-structured in a drop (Berlin's walks were staged from drafts). Walk intro
  folders carry **no coordinates**; the intro (stop 0, `manual`) was wired at the first
  stop's coordinate, the walk's natural start.
- Exactly one `[beat]` marker per script (46 total), stripped for `transcriptText`. Header =
  **two lines** — a `TITLE — Atlas Audio Tour` line **and a location line** ("Plaza Lavalle,
  Buenos Aires") — both stripped; the `_tts-safe` twin proved neither is narrated while the
  closing recommendation line **is**. The stripper matches the `— Atlas Audio Tour` suffix,
  not the first em-dash — "Recoleta Cemetery — Duarte Family Mausoleum" has an em-dash
  *inside* its title.
- One source quirk, harmless: the Teatro Colón MP3 arrived named `eatro Colón.mp3` (truncated
  first letter). Every MP3 is renamed to its slug at staging, so nothing shipped wrong.

## Flagged, not actioned

- **⚠️ Three tours ship outside the capital** with their own `city`, per the
  Campinas/Niterói/Aït Benhaddou convention: **Estación de La Plata** (`-34.904, -57.950`,
  La Plata, ~55 km southeast), **Museo de Arte de Tigre** (`-34.409, -58.591`, Tigre,
  ~28 km north), **Alo's Bistro** (`-34.479, -58.571`, Boulogne, San Isidro). All other 31
  singles + both walks sanity-checked inside CABA by bounding box.
- **⚠️ Slug collision found and dodged:** `catedral-metropolitana` already belongs to **Rio's
  cathedral**, so Buenos Aires' ships as **`catedral-metropolitana-bue`**. First-ever
  cross-city slug collision — check new slugs against the existing catalog *and* the gh-pages
  tree (the Rome banked extras live only there).
- **⚠️ The Argentine architecture canon is absent from the tag vocabulary** — Clorindo Testa
  (Banco de Londres, a brutalist landmark), Mario Palanti (Palacio Barolo), Víctor Meano
  (Congreso, Teatro Colón), Francesco Tamburini (Casa Rosada, Teatro Colón), Eduardo Catalano
  (Floralis Genérica), Alejandro Christophersen (Casa Cavia, Tortoni's façade) — all carry
  `Designed by a Master`. **`Santiago Calatrava` IS in the vocabulary and Puente de la Mujer
  uses it by name.** Tag-precedent note: recent Calatrava tours (Museu do Amanhã,
  Oberbaumbrücke) carry the named tag *without* an explicit `Designed by a Master` — the
  taxonomy doc says the named tag implies it — and BUE follows that. Same gap class as
  Schinkel/Niemeyer/Bo Bardi/Studio KO; the combined `Models/Tag.swift` PR case keeps growing.
- **✅ No tour ships hero-only** — minimum gallery is hero + 1; walk galleries carry 7 (UBA)
  and 11 (TDF) entries, all walk images referenced.

## Verification

- **0 errors, 0 warnings across all 1,226 tours** via the Python mirror of
  `validate-tours.swift` (parses the tag vocabulary from **both** `Models/Tag.swift` and the
  Swift validator, raises if they disagree or either parse is empty; **self-tested against 36
  injected fault classes first — 36/36 caught**, including decode-level classes).
- **uuid5 scheme reverse-verified** against 4 live makers (RAK/SAO/BER/RIO) **plus the São
  Paulo walk and two of its stops** (the walk-stop id pattern `…:<walkslug>-stop{N}`) and the
  Koutoubia tour/stop pair before minting BUE. 0 duplicate ids across 1226/1543/26.
- **gh-pages via pure plumbing** (blobless fetch → temp `GIT_INDEX_FILE` → `hash-object -w` →
  `update-index --cacheinfo` → `write-tree --missing-ok` → `commit-tree`): verified **0 of the
  166 target paths pre-existed** (5,885 existing paths compared) and the tree diff was
  **exactly 166 additions, 0 deletions, nothing outside `audio/` + `images/`**. Push exit code
  read from `${PIPESTATUS[0]}`, not the pipe tail.
- The Pages deploy lagged serving 404; the Actions API showed **`in_progress`, not
  `cancelled`**. All **166 asset URLs verified by hashing downloaded bytes against the
  uploaded git blob SHAs**, not by 200s. `check-image-duplicates.py --maker BUE` clean;
  **120 uploaded = 120 referenced, 0 orphaned** (the São Paulo count rule, asserted at
  assembly: the staged file set must equal the referenced URL set exactly).
- **Tours.json confirmed byte-stable under a Python re-dump before editing**, so the append
  produced no unrelated line churn. Key-order discipline held (full single-stop key set,
  explicit nulls, centroid mirroring the stop; walks mirror `sao-ibirapuera-walk` exactly —
  intro is stop 0 `manual`, `introAudioURL` stays null, walk centroid = mean of stops).
- One environment note: a mid-verification `git ls-tree` accidentally ran from outside the
  repo, silently producing an empty tree file and a meaningless "0 collisions" — caught
  because the tree line count was checked first. **Check the count before trusting a comm.**

## Queue after this session

**Chicago alone: 30 tours / 53 MP3s** — image-complete, awaiting narration only, staged on
`claude/amsterdam-handoff-preserve-hlhyp8` (new maker Atlas Studio ORD at wire-in).
⚠️ Chicago's staging READMEs still carry the two known spec errors (singles
`stop0.imageURL: null`, walk galleries listing the hero) — correct them at wire-in exactly as
Dubai/Berlin did.

# HANDOFF — session 48 (2026-06-30, web/PM — content)

**Tokyo launched as the 7th city.** Shipped to `main` via
**[PR #280](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/280)**
(`4ab886a`, squash, auto-merged on CI green). New maker **Atlas Studio
TYO** + **63 single-stop, geofenced tours**. **Confirmed live** on both
the Supabase `get_catalog` RPC and the gh-pages mirror.

## What shipped

- **New maker: Atlas Studio TYO** — `be5797bb-8d86-5b3f-99d4-09b2ffac65bd`,
  🇯🇵, bio "Atlas Studio's Tokyo bureau — audio tours of the city's
  temples, towers, backstreets, and design landmarks." Schema mirrors the
  existing makers (HKG/SFO).
- **63 single-stop tours**, all `kind: single`, `triggerMode: geofenced`,
  `triggerRadiusMeters: 30`, `priceUSD: 0`, `city: "Tokyo"`,
  `createdAt: "2026-06-30"`. **Bilingual titles `English | 日本語`** on both
  the tour and its single stop, mirroring the 52 HKG tours' `English | 中文`.
  Owner-supplied audio + images (**no image pipeline**).
- **Catalog 406 → 469 tours / 6 → 7 makers / 521 stops; Tokyo = 63.**
  Validator PASS (7 makers / 469 tours / 521 stops, no issues).

### ⚠️ Baseline correction (brief was stale)

The brief said current = 371 tours / 5 makers → 434/6 and called Tokyo the
"6th city." In reality **San Francisco (Atlas Studio SFO, 🌉, 35 tours) had
already shipped as the 6th city** (it's on `main`). So Tokyo is the **7th**
maker and the real counts are **406 → 469 / 6 → 7**. The launch intent was
unchanged; only the running totals differ.

## How it was built (routine content-batch workflow, larger scale)

- **Recon:** parsed all 63 drop folders (`output <EN> <日本語> <lat>, <lng>`)
  into a master spec — clean bilingual titles, slugs, coords, durations
  (via `afinfo`), image lists. Read the HKG + SFO entries in `Tours.json`
  and `scripts/validate-tours.swift` to match the schema exactly.
- **Slugs:** lowercase-hyphen, one slug per tour used for **both** audio and
  images (SFO convention: `ferry-building.mp3`, `ferry-building_hero.webp`).
- **Descriptions:** the 63 clean transcripts were turned into
  `shortDescription` / `longDescription` / `caption` / `primaryCategory` /
  `tags` in the Atlas British voice (condensed from each transcript, **no
  invented facts**) — fanned out across 7 parallel subagents (9 tours each),
  then merged + validated (categories in-enum, no CJK leakage, all fields
  present). `transcriptText` = the verbatim `_clean.txt`.
- **Assets-first:** copied 63 mp3 → `audio/<slug>.mp3` and 215 webp →
  `images/<slug>_hero.webp` + `_2…` (image `01` = hero, `02+` = gallery).
  **The Sumida Hokusai folder's `*.jpg.webp` double-extensions were cleaned**
  to `.webp`. Pushed to **gh-pages first** (`c940460..8009e2d`) from a
  dedicated worktree, before any `Tours.json` edit.
- **Assembly:** idempotent Python assembler appended the maker + 63 tours to
  `Tours.json` on a worktree off `origin/main`, with **deterministic uuid5
  ids** (`atlas-tour:tyo:<slug>` / `atlas-stop:tyo:<slug>` / `atlas-maker:tyo`)
  — collision-checked against existing ids. Rebased onto latest `origin/main`
  (unchanged) before push.
- **Ship:** PR #280; GitHub **native auto-merge** (`--auto --squash
  --delete-branch`) so the merge was server-gated on CI green, not on the
  agent's own check-counting.

### The 3 source-data fixes (geocoded — owner please confirm)

1. **Hōrin-ji Temple 法輪寺** — folder coord `35.010375, 135.677210` was in
   **Kyoto**. The transcript filename said *Waseda*; re-geocoded to the
   Nichiren 法輪寺 on Waseda-dōri, Nishi-Waseda, Shinjuku →
   **`35.70729, 139.71889`**.
2. **Edo-Tokyo Open Air Architectural Museum 江戸東京たてもの園** — folder had
   **no coord**. Geocoded to the museum in Koganei Park →
   **`35.71637, 139.51274`**.
3. **Nanago-Dori Park Toilets 七号通り公園 公衆トイレ** — folder had **no
   coord**. Geocoded to the park in Hatagaya, Shibuya →
   **`35.67902, 139.67477`**.
- All 63 coords sanity-checked inside Greater Tokyo (lat 35.5–35.75, lng
  139.5–139.85); no other outliers (Todoroki 35.604 and Edo-Tokyo 139.513
  are legitimate SW/W-edge spots).

### Supplied / cleaned Japanese (folder lacked or garbled it)

21_21 DESIGN SIGHT · アサヒビールホール (Asahi Beer Hall) · 宮乃湯 (Miyano-yu) ·
MoN高輪 · レフレクション・オブ・ミネラル · 渋谷アンティークマーケット ·
渋谷スカイ · 新宿ゴールデン街 · 東京銀座資生堂ビル. Also fixed a garbled
Shibuya Crossing folder name (`区渋谷交差点`) → **渋谷スクランブル交差点**.

## Verification — confirmed live

- **Validator:** PASS (7/469/521).
- **gh-pages assets:** 278 files pushed; sample hero/audio URLs 200 after
  Pages deploy.
- **Live poll (after merge):** the publish-catalog + Supabase auto-seed
  workflows ran; polled both sources until each served **7 makers / 469
  tours / Tokyo 63** — **Supabase RPC ~1 min**, **gh-pages mirror ~6 min**
  (CDN lag), sample asset URL 200 throughout.

## Category choices worth noting

Boutiques (Dior/LV/Prada/Tiffany/Hermès/Shiseido) and the Tokyo Toilet
restrooms → `architecture`; temples/shrines → `sacredSites`; markets /
yokocho / coffee / breweries / sweets → `foodAndDrink`; art museums →
`visualArt`; parks/ravine → `natureAndParks`; MoN Takanawa →
`architecture` (Kuma building, not its displayed art); Tokyo National
Museum → `history` (transcript centres on the 1938 Imperial Crown Style
building). 3 tours are hero-only (no gallery): Onibus Coffee, Reflection of
Mineral, Shibuya Antique Market.

## Process notes

- All mutating work ran in isolated worktrees (`/tmp/tokyo`,
  `/tmp/tokyo-ghpages`, `/tmp/tokyo-docs`); the primary checkout stayed on
  its parallel-session branch untouched — no branch-flip incidents. Worktrees
  removed + branch deleted at session end.
- macOS NFC/NFD: folder English names with macrons (Gōtoku-ji, Sensō-ji)
  needed `unicodedata.normalize("NFC", …)` to match the inventory keys.
- This handoff + the `CLAUDE.md`/`ROADMAP.md` Current-State refresh ship as
  a separate docs PR (auto-merge class), per the keep-docs-in-sync rule.

## Next

- Owner to eyeball the supplied Japanese names + confirm the 3 geocoded
  coordinates.
- No app/build change this session; TestFlight unaffected (content ships
  live via the remote catalog — no rebuild needed).

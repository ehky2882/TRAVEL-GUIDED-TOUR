# HANDOFF 2026-07-07 — Amsterdam content batch STAGED (awaiting narration MP3s)

**Web/PM content session.** No app-code, no build, no `Tours.json` change yet. Everything lives as
**drafts on branch `claude/amsterdam-handoff-preserve-hlhyp8`** + images live on `gh-pages`. The batch is
image-complete and script-complete; it wires into `Tours.json` only when the owner delivers narration MP3s.

## What's staged
- **33 single-stop Amsterdam tours** — `drafts/amsterdam-batch1/README.md` is the master pick-map
  (# / tour / slug / hero+gallery / credit / coord / category). Heroes + galleries sourced via the image
  pipeline, cropped 1200×900 WebP, pushed to `gh-pages` under each slug, all live (200-verified).
- **5 multi-stop WALKS** — each a folder with `00_intro.txt` + `NN_<stop>.txt` (+ `_TTS.txt`) pairs and a
  `README.md` carrying the full wire-in spec. **All reuse live single-stop heroes — zero new image sourcing.**
  All 5 walk heroes owner-confirmed:
  | Walk folder | Hero | Centroid | ~dist |
  |---|---|---|---|
  | `amsterdam-canalring-walk` | `canal-ring-golden-bend_hero` | 52.36828/4.89299 | ~3 km |
  | `amsterdam-oldside-walk` | `oude-kerk_hero` | 52.37470/4.89769 | ~2 km |
  | `amsterdam-museumquarter-walk` | `rijksmuseum_hero` | 52.35816/4.87880 | <2 km |
  | `amsterdam-jordaan-walk` | `westerkerk_hero` | 52.37654/4.88500 | ~2 km |
  | `amsterdam-jewishquarter-walk` | `portuguese-synagogue_hero` | 52.36712/4.90656 | ~1.5 km |

- **Credits:** `drafts/CREDITS.md` (Amsterdam section) logs all 22 CC-credited images. Walks add none
  (they inherit the single-stop credits). Unsplash/Pexels/Pixabay/CC0/PD are ship-safe.

## Wire-in (do when MP3s arrive) — NOT done yet
1. New maker **Atlas Studio AMS** 🇳🇱 (deterministic uuid5 id, same scheme as other makers).
2. 33 single-stop tours: ids `atlas-tour:ams:<slug>` / `atlas-stop:ams:<slug>`; `transcriptText` verbatim
   from each `.txt`; heroes+galleries per batch1 README; read durations from the MP3s.
3. 5 walks: `kind: multiStop`, ids `atlas-tour:ams:<walk-slug>`; stop 0 = intro (`triggerMode manual`,
   `introAudioURL null`); stops 1..N `geofenced` radius 40; per-walk README has coords, centroid,
   walkingDistanceMeters, category, hero + additionalImageURLs.
4. `swift scripts/validate-tours.swift` → fix errors. Then it auto-publishes to gh-pages + Supabase on merge.

## Sensitivity (persistent requirement — honored in staging)
Memorials / sensitive subjects (De Wallen, Anne Frank House, Portuguese Synagogue, Names Monument,
Hollandsche Schouwburg, Homomonument) use dignified exteriors / memorial architecture only — no
red-light windows/workers, no graphic Holocaust imagery. The Madurodam-miniature look-alike (HM52) was
caught and rejected; real Homomonument HM46 promoted to hero.

## State
- Catalog live in-app: **509 tours / 9 makers / 561 stops** (Amsterdam not yet in it — still drafts).
- After wire-in Amsterdam adds a **10th maker** and **38 tours** (33 single + 5 walks).
- Latest TestFlight build unchanged: **1.0 (74)**.

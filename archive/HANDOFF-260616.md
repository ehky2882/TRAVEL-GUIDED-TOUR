# HANDOFF 2026-06-16 — London batches 3 & 4 + 5 multi-stop walks image-staged ahead of audio (web/PM)

Web/PM session. **No changes to `main`** — all work is staged on `gh-pages`
(images) and on branch `claude/london-batch3-scripts-260616` (scripts + manifests).
Nothing wired into `Tours.json` yet (audio pending). Catalog on `main` unchanged at
**243 tours / 4 makers**; latest TestFlight still **1.0 (41)**.

**Session total: 37 single-stop tours + 5 multi-stop walks, all image-staged
ahead of audio.**

## What shipped (staged)

**37 new London tours image-staged ahead of audio**, all under the eventual
Atlas Studio LDN, single-stop:

- **Batch 3 — tours 59–80 (22):** South Kensington/Chelsea/Knightsbridge (V&A,
  Natural History, Science, Royal Albert Hall, Albert Memorial, Harrods, Brompton
  Oratory, Chelsea Physic Garden), Greenwich (Royal Observatory, Cutty Sark, Old
  Royal Naval College, Queen's House, National Maritime Museum, Foot Tunnel),
  East End (Christ Church Spitalfields, Brick Lane, Dennis Severs', Old Spitalfields
  Market, Bevis Marks, Columbia Road, Whitechapel Gallery, Wilton's Music Hall).
- **Batch 4 — tours 81–95 (15):** Camden/King's Cross/Regent's Park/Hampstead
  (St Pancras & King's Cross, Coal Drops Yard, Regent's Park, Primrose Hill, London
  Zoo, Camden, Highgate Cemetery, Abbey Road, Lord's, Kenwood), Notting Hill/
  Kensington (Kensington Palace, Portobello Road, Leighton House), edges (Battersea
  Power Station, Kew Palm House).

Each has `{slug}_hero.webp` + `{slug}_N.webp` (1200×900) on `gh-pages` under
`images/`. Per-tour slug + image manifests:
`drafts/london-batch3-scripts/README.md` and `drafts/london-batch4-scripts/README.md`.
Scripts (display `.txt` + `_TTS.txt`) for all 37 are in those two folders.

## New this session — 4-source image pipeline (codify into CLAUDE.md next)

Extended the pipeline from Unsplash-only to **4 sources, all ship-safe
(no attribution required) + Wikimedia fallback**:

- `/tmp/pipeline_multi.py` — queries **Unsplash + Pexels + Pixabay + Openverse
  (`license=cc0,pdm`)**, source-diversity interleave, Gemini verify gate, unified
  numeric labels with the source burned on each. Handles per-source 403s gracefully.
- Keys this session (owner-pasted, not stored): Unsplash, Pexels, Pixabay, Gemini;
  Openverse Bearer token registered at runtime.
- `/tmp/wiki_run.py` — Wikimedia Commons fallback for niche/restricted/interior
  subjects (CC BY-SA, owner accepted for these). `/tmp/process_multi.py`,
  `process_wiki.py`, `process_consolidated.py`, `consolidate.py` — crop→WebP→stage.

**Lessons:**
- The stock gate is brutal on niche/interior/restricted subjects (Cutty Sark,
  Lord's, Bevis Marks, Wilton's, Leighton's Arab Hall, Coal Drops). **Wikimedia
  (CC BY-SA) is the reliable rescue** — owner OK'd it given there's no in-app
  attribution UI; credits logged in `IMAGE-CREDITS-london-batch3.txt` on `gh-pages`.
- **Openverse CC0 depth tracks subject publicness** (Old Spitalfields 90, restricted
  interiors 0) — the gap is the subject, not the source.
- Owner pastes land as base64 in the session `.jsonl` (no filename) — decode the
  last user image; map by paste order when the filename is referenced but absent.
- Don't double-background (`nohup … &` inside a backgrounded tool call gets killed).

## Multi-stop walks (5) — staged this session

Each is one `Tour` with N ordered geofenced `Stop`s (intro = stop 0); every `Stop`
carries its own `imageURL`. Stops that overlap existing single-stop tours **reuse
that tour's hero URL** (no new file). Scripts + per-tour image manifests in
`drafts/<slug>/README.md`. Slugs / track counts:

| Walk | slug | tracks | notable |
|---|---|---|---|
| After the Fire: Wren's City | `after-the-fire-wrens-city` | 6 | intro = PD Great Fire painting; stops Pudding Lane→Monument→St Stephen Walbrook→St Mary-le-Bow→St Paul's |
| The Spine of Power | `the-spine-of-power` | 8 | Whitehall axis; stops 3 (Banqueting House) + 7 (Westminster Abbey) reuse existing tour heroes |
| The South Bank Mile | `the-south-bank-mile` | 10 | stop 3 (Royal Festival Hall) reuses existing hero; rest fresh |
| Albertopolis | `albertopolis` | 6 | intro = PD Crystal Palace 1851; **stops 1–5 all reuse existing museum/memorial heroes** |
| The Measure of the World | `the-measure-of-the-world` | 7 | Greenwich; **stops 1–4 + 6 reuse existing Greenwich heroes**; intro = Prime Meridian |

Catalog's multi-stop count goes 2 → **7** when these land (after AMNH Four Facades,
Fifth Avenue Walk). All images on `gh-pages` (`{slug}_hero` + `_stop0…`).

## Pending / next steps

1. **Audio → wire to `Tours.json`.** When MP3s arrive: pull
   `claude/london-batch3-scripts-260616`, add the **37 single-stop** tours + the
   **5 multi-stop** walks under Atlas Studio LDN with the staged image URLs, run
   `validate-tours.swift`. (Audio uploads → `gh-pages/audio/`.) Multi-stop stops need
   per-stop **coordinates looked up** (not in the drafts). Audio slugs match the
   script filenames (e.g. `london_greenwich_multistop_06_royal_observatory`).
2. **In-app attribution surface** — many batch-3/4 galleries are CC BY-SA; the app
   has no credit field. Worth a real attribution UI before these ship.
3. **Tag taxonomy** — parked on `claude/dreamy-wozniak-tags-260612` (spec
   `docs/tag-taxonomy.md`, seeder `scripts/seed_tags.py`, review
   `docs/tag-migration-review.md`). Next: review/correct per-tour assignments →
   apply to `Tours.json` → model + validator + faceted-filter UI (code PR).

## Branch state
- `gh-pages` — all 37 single-stop + 5 multi-stop walks' images + the reused single-stop
  heroes + `IMAGE-CREDITS-london-batch3.txt` (CC BY-SA log, appended per batch/walk).
- `claude/london-batch3-scripts-260616` — all scripts + per-tour manifests
  (`drafts/london-batch3-scripts/`, `drafts/london-batch4-scripts/`, and one folder
  per multi-stop walk) + this handoff.
- `claude/dreamy-wozniak-tags-260612` — tag taxonomy proposal (unmerged).

## Pipeline scripts (in `/tmp`, reusable — codify into CLAUDE.md's Image Pipeline)
`pipeline_multi.py` (Unsplash+Pexels+Pixabay+Openverse-CC0, source-interleaved,
Gemini verify, unified numeric labels) · `wiki_run.py` (Wikimedia Commons fallback) ·
`process_multi.py` / `process_wiki.py` / `process_consolidated.py` (crop→1200×900
WebP→stage; all take an optional out-slug arg) · `consolidate.py` (re-badge + merge
candidate sets into one numbered set).

# Belém batch 1 — Atlas Studio BEL (10 singles live, 1 held) — LIVE 2026-10-21

Source: contributor drop (Dropbox, arthur.yung), 11 `output <Name> <lat>, <lon>` folders. Each holds
`NN_<slug>_clean.txt` (title on line 1), `NN_<slug>_tts-safe.txt`, one MP3 and 2–5 photos at 1200×900 WebP.
`scripts/` holds both texts as delivered. `coordinates.tsv` is num · slug · lat · lon · radius · category · source
folder; each coordinate comes from its folder name except Muamba (03) and Ver-o-Pesinho (09), which use Google Maps
pins the contributor supplied after triage.

**Muamba (03) is HELD** (contributor, 2026-10-21) pending its location question: the script narrates Vila Container on
Av. Gov. Magalhães Barata, while the Google Maps pin is on the waterfront ~2.2 km west. `HOLD` in `wire_belem.py` skips
it and `coordinates.tsv` omits it; its audio (`audio/bel-muamba.mp3`) and photos (`images/bel-muamba_*.webp`) are
already on gh-pages, so releasing it is a catalogue edit only. `tools/wire_belem.py` is the assembler. Run it once: it refuses to add
the maker twice.

Every slug carries a **`bel-` prefix**. Audio is at `audio/bel-<slug>.mp3`, images at `images/bel-<slug>_hero.webp`,
`_2.webp`, … The drop's own `*_hero.webp` leads, or `01 … .webp` in the seven numbered folders. Folder names arrive
with accents escaped as `#U00e7` etc.; decode them before running `check-coordinates.py`.

Bilingual `English | Portuguese` titles on the 5 tours whose names genuinely differ. Full account:
`archive/HANDOFF-261021-belem.md`.

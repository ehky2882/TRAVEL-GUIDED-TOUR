# Lille batch 1 — Atlas Studio LIL (19 singles) — LIVE 2026-10-23

Source: contributor drop (Dropbox, arthur.yung), 19 `output <Name> <lat>, <lon>` folders, numbered 01–20 with no 14.
Each holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt` (every clean script but Bienheureux opens with a title
line), one MP3 and 1–7 photos at 1200×900 WebP. Folder names arrive with accents escaped as `#U00e9` etc.

`scripts/` holds both texts as delivered. `coordinates.tsv` is num · slug · lat · lon · radius · category · source
folder. Every coordinate comes from its folder name, unchanged.

`tools/wire_lille.py` is the assembler. Run it once: it refuses to add the maker twice. Every slug carries a
**`lil-` prefix**: audio at `audio/lil-<slug>.mp3`, images at `images/lil-<slug>_hero.webp`, `_2.webp`, … The drop's
own `*_hero.webp` leads; Place aux Oignons' single photo has no suffix and becomes the hero.

Cities are the real communes: 16 Lille, Bienheureux in **Wasquehal**, Le Fresnoy in **Tourcoing**, Villa Cavrois in
**Croix**. Bilingual `English | French` titles on the 5 tours whose names genuinely differ. Full account:
`archive/HANDOFF-261023-lille.md`.

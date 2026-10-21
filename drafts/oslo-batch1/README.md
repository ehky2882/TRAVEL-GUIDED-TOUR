# Oslo batch 1 — Atlas Studio OSL (17 singles) — LIVE 2026-10-21

Source: contributor drop (Dropbox, arthur.yung), 17 `output <Name> <lat>, <lon>` folders. Each holds
`NN_<slug>_clean.txt` (title on line 1), `NN_<slug>_tts-safe.txt`, one MP3 and 1–7 photos at 1200×900 WebP.
Number 16 is absent on purpose (skipped by the contributor). `scripts/` holds both texts as delivered.
`coordinates.tsv` is num · slug · lat · lon · radius · category · source folder; each coordinate comes from its folder
name except MUNCH (11), moved from the building's north tip onto the west quay the script names.
`tools/wire_oslo.py` is the assembler. Run it once: it refuses to add the maker twice.

Every slug carries an **`osl-` prefix**. Audio is at `audio/osl-<slug>.mp3`, images at `images/osl-<slug>_hero.webp`,
`_2.webp`, … The drop's own `*_hero.webp` leads, or `01 … .webp` in the three numbered folders (Aesop, Amerikalinjen,
Tim Wendelboe). Folder names arrive with `é`/`ø` escaped as `#U00e9`/`#U00f8`; decode them before running
`check-coordinates.py`.

Bilingual `English | Norwegian` titles on the 6 tours whose names genuinely differ. Full account:
`archive/HANDOFF-261021-oslo.md`.

# Warsaw batch 1 — Atlas Studio WAW (34 singles) — LIVE 2026-10-20

Source: contributor drop (Dropbox, arthur.yung), 34 `output <Name> <lat>, <lon>` folders. Each holds
`warsaw_NN_<slug>.txt` (a four-line header, `---`, then the script), `warsaw_NN_<slug>_TTS.txt` (the voice-engine
text), one MP3 and 1–7 photos at 1200×900 WebP. Numbers 03, 10 and 27 are absent on purpose: the contributor already
has those subjects as SovMod tours, or cut them. `scripts/` holds both texts as delivered. `coordinates.tsv` is
num · slug · lat · lon · radius · category · source folder, and each coordinate comes from its folder name.
`tools/wire_warsaw.py` is the assembler. Run it once: it refuses to add the maker twice.

Every slug carries a **`waw-` prefix**. Audio is at `audio/waw-<slug>.mp3`, images at `images/waw-<slug>_hero.webp`,
`_2.webp`, … The drop's own `*_hero.webp` leads, or `01 … Image.webp` in the eleven numbered folders.
The folder names arrive with Polish letters escaped as `#U0119` and the like. Decode them before running
`check-coordinates.py`, or 18 of 34 come back UNVERIFIABLE.

Bilingual `English | Polish` titles on the 23 tours whose names genuinely differ. Full account:
`archive/HANDOFF-261020-warsaw.md`.

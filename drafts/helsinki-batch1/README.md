# Helsinki batch 1 — Atlas Studio HEL (19 singles) — LIVE 2026-10-22

Source: contributor drop (Dropbox, arthur.yung), 19 `output <Name> <lat>, <lon>` folders. 17 hold
`NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt` (no title line); Central Station and Kuurna came from a different
pipeline and hold `<slug>.txt` + `<slug>-tts.txt` with the title on line 1. Each folder has one MP3 and 2–6 photos at
1200×900 WebP. Script number 17 does not exist (contributor, 2026-10-22: "no 17").

`scripts/` holds both texts as delivered. `coordinates.tsv` is num · slug · lat · lon · radius · category · source
folder (CS = Central Station, KU = Kuurna). Every coordinate comes from its folder name except **Katajanokka (05)**,
moved ~330 m from Linnankatu to Luotsikatu 1 (the Tallberg House, per OSM) on the contributor's instruction, because
the script stands the listener on Luotsikatu between numbers 1 and 2.

`tools/wire_helsinki.py` is the assembler. Run it once: it refuses to add the maker twice. Every slug carries a
**`hel-` prefix**: audio at `audio/hel-<slug>.mp3`, images at `images/hel-<slug>_hero.webp`, `_2.webp`, … The drop's
own `*_hero.webp` leads, or `01 … .webp`. Apotek's photos arrived without a `.webp` extension (a colon in the
folder name truncated them); the assembler matches every non-audio, non-text file. Folder names arrive with accents
escaped as `#U00e4` etc.

Bilingual `English | Finnish` titles on the 6 tours whose names genuinely differ. Full account:
`archive/HANDOFF-261022-helsinki.md`.

# Nairobi batch 1 — 13 singles under a new studio, Atlas Studio NBO 🇰🇪 — wired 2026-10-14

Source: contributor drop (Dropbox, arthur.yung), one `output <Name> <lat>, <lon>` folder per site holding
`NN-<slug>.mp3`, the display script `NN-<slug>.txt`, the voice script `NN-<slug>-tts.txt` and 3–5 webps at
1200×900. Numbers run 01–17; 05, 06, 09 and 14 were dropped by the contributor and are not coming.
Nine folders carried generic `NN <Name> Image.webp` photos, renamed `<slug>_hero.webp`, `_2.webp` … in
their numbered order. `scripts/` holds every script as delivered.
`coordinates.tsv` is slug · lat · lon · radius · category · title · city · country · tags · note.
`tools/wire_nairobi.py` is the assembler (run once — it refuses to add the maker twice).
Audio is at `audio/<slug>.mp3` on gh-pages; two KICC photos carry a `-2` name (see the tool's docstring).
Full account: `archive/HANDOFF-261014-nairobi.md`.

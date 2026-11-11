# Grands Ensembles batch 1 — 8 singles under a new creator, Grands Ensembles 🏢 — wired 2026-10-13

Source: contributor drop (Dropbox, arthur.yung), one `output <Name> <lat>, <lon>` folder per site holding
`NN-<slug>.mp3`, the display script `NN-<slug>.txt`, the voice script `NN-<slug>_tts.txt` and 2–6 webps at
1200×900 (`<slug>_hero.webp`, `_2.webp` …). `scripts/` holds every script as delivered.
`coordinates.tsv` is slug · lat · lon · radius · category · title · city · country · tags · note.
`tools/wire_grands_ensembles.py` is the assembler (run once — it refuses to add the maker twice).
Audio is at `audio/<slug>.mp3` on gh-pages; six photos carry a `-2` name (see the tool's docstring).
Full account: `archive/HANDOFF-261013-grands-ensembles.md`.

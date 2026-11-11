# SovMod batch 2 — 53 SovMod singles + Atlas Studio TAO (Qingdao, 1 single) — wired 2026-10-10

Source: contributor drop (Dropbox, arthur.yung), SovMod format: one `output <Name> <lat>, <lon>` folder per site
with an MP3, `_clean.txt`, `_tts-safe.txt` and 1–6 webps at 1200×900. `scripts/` holds every script as delivered.
`coordinates.tsv` is slug · lat · lon · radius · category · maker · title · city · country · tags · note.
`tools/wire_sovmod2.py` is the assembler (run once — it refuses to add the TAO maker twice). Audio is at
`audio/<slug>.mp3` and images at `images/<slug>_hero.webp`, `_2.webp`, … on gh-pages.
Full account: `archive/HANDOFF-261010-sovmod-batch2.md`.

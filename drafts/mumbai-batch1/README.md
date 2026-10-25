# Mumbai batch 1 — Atlas Studio BOM (28 singles) — LIVE 2026-10-15

Source: contributor drop (Dropbox), same format as Hanoi: one `output <Name> <lat>, <lon>` folder per site, each with
`mumbai_NN_<slug>.txt` (script, header above `---`), `_TTS.txt`, an MP3 and 1–5 webp photos at 1200×900.
Numbered 01–33; **19, 20, 22, 25 and 27 were not in the drop.** `scripts/` holds both texts as delivered;
`coordinates.tsv` is num · slug · lat · lon · radius · category · note; `tools/wire_mumbai.py` is the assembler
(run once — it refuses to add the maker twice).

Every slug carries a **`bom-` prefix**. Audio is at `audio/bom-<slug>.mp3`, images at `images/bom-<slug>_hero.webp`,
`_2.webp`, … (the drop's own `*_hero.webp`, where present, leads). Captions are each script's "Vantage" line.
Three MP3s arrived misnamed (`01 BMC Image.mp3`, `01 David Sassoon Library Image.mp3`, `St. Mary's ICSE.mp3`) and were
renamed. Full account: `archive/HANDOFF-261015-mumbai.md`.

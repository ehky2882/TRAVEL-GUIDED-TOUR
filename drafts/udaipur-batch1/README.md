# Udaipur batch 1 — Atlas Studio UDR (23 singles) — LIVE 2026-10-16

Source: contributor drop (Dropbox), same format as Mumbai: one `output <Name> <lat>, <lon>` folder per site, each with
`udaipur_NN_<slug>.txt` (script, header above `---`), `_TTS.txt`, an MP3 and 2–7 webp photos at 1200×900.
Numbered 01–24; **19 was left out on purpose** (contributor). Udaan Park's MP3 arrived in a second pass.
`scripts/` holds both texts as delivered; `coordinates.tsv` is num · slug · lat · lon · radius · category · note;
`tools/wire_udaipur.py` is the assembler (run once — it refuses to add the maker twice).

Every slug carries a **`udr-` prefix** (UDR = Maharana Pratap Airport). Audio is at `audio/udr-<slug>.mp3`, images at
`images/udr-<slug>_hero.webp`, `_2.webp`, … (the drop's own `*_hero.webp`, where present, leads). Captions are
written from each script's orientation paragraph. RAAS Devigarh's city is **Delwara** (25 km north).
Full account: `archive/HANDOFF-261016-udaipur.md`.

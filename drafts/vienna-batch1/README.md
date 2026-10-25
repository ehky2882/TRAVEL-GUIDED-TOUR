# Vienna batch 1 — Atlas Studio VIE (35 singles) — LIVE 2026-10-18

Source: contributor drop (Dropbox, arthur.yung), the same 35 architect-guide scripts staged on
`claude/vienna-city-guide-78rxw7` on 2026-10-12, now with audio and photos. One `output <Name> <lat>, <lon>`
folder per site, each with `NN_<slug>_clean.txt` (title on line 1), `NN_<slug>_tts-safe.txt`, one MP3 and
1–7 photos. `scripts/` holds both texts as delivered; `coordinates.tsv` is num · slug · lat · lon · radius ·
category · note; `tools/wire_vienna.py` is the assembler (run once — it refuses to add the maker twice).

Every slug carries a **`vie-` prefix** (VIE = Vienna International). Audio is at `audio/vie-<slug>.mp3`, images at
`images/vie-<slug>_hero.webp`, `_2.webp`, … The drop's own hero leads: `*_hero.*`, or `01 … Image.webp` in the four
numbered folders, or (Werkbundsiedlung) the hash-named `iqpxkuo1jxi8npecbwq4.webp`. The Prunksaal hero arrived as a
1834×1222 PNG and was centre-cropped to 1200×900 WebP. The 15 tours in the staging branch's `image-picks.txt` carry
the owner's 2026-10-17 picks (Unsplash/Pexels); the contributor says every other photo is royalty-free.

Captions are written from each script's orientation paragraph. Bilingual `English | German` titles on the 8 tours whose
English and German names genuinely differ (19, 24, 25, 27, 29, 30, 32, 34). Full account:
`archive/HANDOFF-261018-vienna.md`.

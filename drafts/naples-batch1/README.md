# Naples batch 1 — Atlas Studio NAP (19 singles) — LIVE 2026-10-27

Source: contributor drop (Dropbox, arthur.yung), 19 `output <Name> <lat>, <lon>` folders with scripts numbered 01–19.
Each holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt` (every clean script opens with a title line and carries one
`[beat]`), one MP3 (103–123 s) and 2–6 photos at 1200×900 WebP. Accented folder names arrived mangled by the zip
(`In#U00e8s`, `Mim#U00ec`); the assembler matches on the unaccented prefix.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
Every coordinate comes from its folder name, except one:
- **Doctor Vintage** moved 6 m, to 40.8349908844937, 14.239130067750816 — contributor's instruction. OSM has no node
  for the shop; the point sits on the building OSM numbers 14 Via Giuseppe Fiorelli, beside No. 12.

`tools/wire_naples.py` is the assembler (`python3 -I wire_naples.py <unzipped drop> <stage dir>`). Run it once: it
refuses colliding tour ids. Slugs carry an **`nap-` prefix**: audio at `audio/nap-<slug>.mp3`, images at
`images/nap-<slug>_hero.webp`, `_2.webp`, … in the drop's numeric order.

- **Two Castel Sant'Elmo photos dropped** (`castel-santelmo_4`, `_6`): they show the Certosa di San Martino next door.
  The gallery is renumbered, so the castle carries hero + 3.
- **Three tours within 21 m on Via dei Cristallini** (Atelier Inès, Casa D'Anna, Ipogeo dei Cristallini) carry the
  smallest radius in use, **20 m**; they still overlap, and the contributor chose to keep all three.
- **Geofence:** 20 m for that trio, 40 m for venues, 50 m for the theatre, the hotel and Rua Catalana, 60 m for
  Castel Sant'Elmo.
- **Bilingual `English | Italian`** on 3: San Carlo Theatre | Teatro di San Carlo, Cristallini Hypogeum | Ipogeo dei
  Cristallini, Former Church of Santa Maria della Misericordia ai Vergini | Ex Chiesa di …. Castel Sant'Elmo keeps
  its Italian name alone (contributor's choice).
- **L'Antiquario's audio says "this year it was placed twenty eighth"** in Europe's 50 best bars; it will date. Kept
  for now on the contributor's instruction.

Full account: `archive/HANDOFF-261027-naples.md`.

# Handoff — 2026-10-11 — Grands Ensembles scripts + image picker

**Branch:** `claude/fervent-ptolemy-o6s9ct` (no PR yet). The work is staged content only; nothing
touches `Tours.json` or Swift.

## What was done

- **8 single-stop tour scripts** in `drafts/grands-ensembles-batch1/scripts/`: the Aillaud Towers,
  Cité de la Muette/Drancy, La Grande Borne, Arcades du Lac, Étoiles de Renaudie, Orgues de Flandre,
  Arènes de Picasso and Choux de Créteil. Each comes as a clean `.txt`, an `.md` (metadata,
  respellings, sources) and a `_tts.txt`. `tools/build.py` regenerates the MD and TTS files and
  fails if a TTS file still holds a digit, an accent or a hyphen.
- **Image picker** published: https://claude.ai/artifact/3jLdc39jxBCdrtj7ouQyBq. It holds 84 photos.
  Only **11 are free to ship** (PD, CC0, Unsplash or Pexels); the other 73 are CC BY or BY-SA and
  marked CREDIT NEEDED. Arcades du Lac and Étoiles de Renaudie have **no** free photo at all.
- `drafts/grands-ensembles-batch1/images/IMAGE-SOURCES.md` lists every picker code with its source
  page, then every Commons file per site plus search links (Commons, Openverse, Unsplash, Pexels,
  Flickr, Google CC).

## Open / for the owner

- **Image picks**: waiting on the owner's paste. Then crop to 1200×900 WebP, upload to gh-pages and
  record any CC BY/BY-SA credit in `drafts/CREDITS.md`.
- **Maker**: undecided. The series spans 8 communes, so it is not clearly Atlas Studio PAR.
- **Gemini gates did not run.** The key supplied (`gen-lang-client-…`) is a Google Cloud *project
  ID* and the API rejected it. Every photo was instead checked by eye at full size. That check
  rejected three lookalikes: Grenoble's Île Verte (for Aillaud), La Tourette (for Ivry) and Renaudie's
  Givors stars (also for Ivry).
- Coordinates were not run through `check-coordinates.py`.

## Traps seen this session

- Wikimedia `upload.wikimedia.org` returns 429 for non-standard thumbnail widths (e.g. 1600px) and
  for originals. `Special:FilePath/<name>?width=1280` works.
- Unsplash and Pexels match on location tags, not captions, so a caption keyword filter throws away
  the real hits. Judge the pixels instead.

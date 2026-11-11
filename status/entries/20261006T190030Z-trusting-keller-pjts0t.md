# Philadelphia audio: 66 MP3s on gh-pages + assembler ready; launch held for owner's image backfill

_2026-10-06 19:00 UTC · branch `trusting-keller-pjts0t`_

The owner sent 66 MP3s on Dropbox, named one-to-one with the staged scripts.
- **Audio check:** each file was transcript-matched to its own script (lowest score 0.90). All are 128 kbps mono, with no byte duplicates.
- **Upload:** all 66 were pushed to gh-pages in one batch as `audio/<slug>.mp3` and `audio/<walk-slug>_stop<N>.mp3`. Durations and hashes are in `drafts/philadelphia-batch1/audio-manifest.json`.
- **Assembler:** `drafts/philadelphia-batch1/tools/wire_philly.py`. A dry run gave 0 validator errors and no Philadelphia warnings. A real run refuses until every image exists.
- **Launch held:** the owner said *"dont launch the tours until i've backfilled everything"*.

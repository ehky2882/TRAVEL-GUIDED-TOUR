# Handoff 2026-10-12: Shanghai batch 1 scripts and image picker

**Branch:** `claude/relaxed-pasteur-uaz2lp` (no PR; drafts only, nothing wired into `Tours.json`)

## Done
- **13 single-stop scripts** in `drafts/shanghai-batch1/`, each as `.md`, `.txt` and `_TTS.txt`. The source text is `scripts/_clean.py`, and `scripts/build.py` regenerates all three files. Primary sources for each venue are listed in the README.
- **Coordinates converted from GCJ-02.** All 13 came from a Chinese map app. The WGS-84 table is in the README and was verified against named OSM objects.
- **Image picker published:** https://claude.ai/artifact/1EjYxPqJjtFygrGfRzH7aU. It holds 24 photos across 7 tours, most of them labelled CONTEXT. Sources are in `image-candidates.tsv`, and every place to look further is in `IMAGE-LINKS.md`.

## Owed
1. **Owner:** send an Amap pin for 01 Blue Bottle Zhang Yuan. The given point was 10 km out, so the README uses Zhang Yuan's centroid.
2. ~~Meet the Bund branch~~: **the owner confirmed BFC** (2026-10-12). The point is the BFC complex, 31.22861, 121.49341.
3. **Owner picks** from the picker. Six tours have no candidates: they need owner photos, an OK for CC BY-SA, or press images with the venue's permission.
4. Before recording: re-check Mercato's status, Xin Rong Ji's star count and name, and Jesse's founding year (README § perishable).

## Environment notes (2026-10-12)
- The Gemini value supplied was a GCP project ID, not a key, so both gates were done by eye.
- The Unsplash key returned `Rate Limit Exceeded` all session.
- Wikimedia 429s this egress IP. Only standard `/1280px-` thumbnails got through, and Openverse's thumbnail proxy returns 424 on Commons files.

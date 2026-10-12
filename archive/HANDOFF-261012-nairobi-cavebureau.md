# Handoff 2026-10-12: Nairobi cave_bureau guide scripts and image picker

**Branch:** `claude/dreamy-gates-2hu3qn` (no PR opened)

## Done
- 17 single-stop scripts, one per venue in the Architecture Hunter Nairobi guide curated by cave_bureau: `drafts/nairobi-cavebureau-batch1/` (MD, clean TXT and TTS-safe TXT per tour, plus a README with coordinates).
- Primary sources were read for every venue before writing. Each tour's `.md` lists them.
- Image picker published: https://claude.ai/artifact/HtidruGBorVJdXKcn4CdSi (10 tours, 88 candidates).
- `IMAGE-SOURCES.md` gives links for every venue, including the 7 with no usable PD/Unsplash/Pexels photo.

## Not done / caveats
- **Gemini gates not run.** The key supplied was a GCP project ID (`API_KEY_INVALID`). Candidates were checked by eye.
- **Wikimedia Commons returned HTTP 429 for this egress all session.** PD photos of the Karura caves and more Nairobi National Park photos are listed but not downloaded.
- Not wired: no audio, no `Tours.json`, no maker code. No `drafts/AUDIO-PENDING-SURVEY.md` row on `main` yet.
- The guide's `data-map-latitude/longitude` is the map viewport for several venues. Use the `!3d/!4d` coordinates in the README, not the viewport values.

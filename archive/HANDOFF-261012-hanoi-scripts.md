# Handoff 2026-10-12: Hanoi batch 1 scripts + image picker

- **Scripts:** `drafts/hanoi-batch1/` holds 28 single-stop tours, one per entry in Architecture Hunter's Hanoi guide. Each has clean and TTS-safe versions, in .txt and .md. Primary sources are named in each script's header.
- **Guide errors found:** the guide's addresses for Duy Trí, Loading T and the Metropole are shuffled. The real addresses are Yên Phụ, 8 Chân Cầm and 15 Ngô Quyền. "Memoir 15" is really **Mémoire 15**. Concrete Flakes is an office (the OpenAsia HQ extension), not a house.
- **Coordinates:** taken from the guide's own map pins, plus two re-anchored districts (Old Quarter at Bạch Mã Temple, French Quarter at the Opera House). None has been checked yet; run `check-coordinates.py` before wiring.
- **Images:** picker at https://claude.ai/artifact/Xi38uYAKTnNnW8rpBJFp3J (169 photos). The supplied Gemini value was a GCP project id, not an API key, so both gates were done by eye. Tours 02, 12, 14 and 25 have no usable photo. Tours 01, 03–08, 10, 11, 13, 15, 24 and 26 have context photos only.
- **Not done:** audio, Tours.json wiring, gh-pages upload, and the AUDIO-PENDING-SURVEY row on `main`.

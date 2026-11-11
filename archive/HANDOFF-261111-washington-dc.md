# HANDOFF 2026-11-11: Washington DC launches (Atlas Studio WAS 🇺🇸, 31 singles + 5 walks)

**What shipped:** a new studio, **Atlas Studio WAS**, the 63rd: 31 single-stop audio tours of Washington (01–30 plus 40 Old
Stone House) and 5 walks with 34 stops.
- **Maker:** platform `dozent`, handle `atlas.was`, uuid5 `atlas-maker:was` = `e170d645-86aa-51d2-a5e6-ad1cacf06e26`.
- **Catalogue:** tours 2463 → 2499, makers 780 → 781, stops 2922 → 2987, single-stop 2374 → 2405, multi-stop 89 → 94. Cities
  (1098), countries (104) and places (513) did not move. Creator pins already covered Washington, and the new Washington
  Monument tour joined the existing place.
- **Walks:** The Long Room (W1, 7 stops, 2.1 km) · Around the Water (W2, 2 + Tidal Basin, 3.2 km) · Older Than the City
  (W3, Georgetown, 1.9 km) · The Avenue (W4, 8 stops, 2.6 km) · The City That Isn't a State (W5, 8 stops, 3.4 km). Distances
  are the author's stated route lengths.

**History:** staged 2026-10-13 from the owner's OneDrive drop; images picked and processed 2026-10-14 and 15 (168 files, 6
owner photos); audio arrived today by Dropbox.

**Audio:** 65 MP3s, 7,799 s. Every file was transcribed with faster-whisper (base.en, python3.13, decoded through ffmpeg because
av 19 breaks it) and matched to its own script before upload. The low scorers (18 at 0.08, 19 at 0.22) differ only in digits
against spelled-out numbers. gh-pages `493a56a`. Record: `drafts/washington-dc-batch1/audio-manifest.json`.

**Wiring:** `drafts/washington-dc-batch1/tools/wire_dc.py --created 2026-11-11`, adapted from Philadelphia's.
- ⚠️ **The DC scripts mark pauses as a bare `[beat]` line, not Philadelphia's `*[beat]*`.** Five more sit at the end of a
  sentence (W3). The first run leaked 48 into `transcriptText`, and `validate-tours-mirror` failed its control.
  The assembler now strips all three forms.
- Washington Monument joined its place (7.3 m) through `join-places.py`'s own `apply_join`, applied to that one entry only.
  The other eight joins `--max-move 100` reports were already pending on `main` before this batch and were left alone.

**Architect tags (Job 5):** 11 new names, one line each in `Models/Tag.swift` and `scripts/validate-tours.swift`. The list and
what was deliberately not tagged are in `drafts/washington-dc-batch1/README.md` § Wired.

**Places (owner: "make the 3 places"):** places 513 → 515. National Archives (0 m) and Old Post Office (pin moved 38.5 m)
are new. Union Station already existed as a two-pin place on OSM's station node, so the tour joined it (110.4 m). Done by
`drafts/washington-dc-batch1/tools/places_dc.py`.

**Owner:** `status/owner/washington-dc-launch.md` holds the Capitol trigger point, the Ford's Theatre hero banner and a pronunciation listen.

**Checks:** `validate-tours-mirror` 0 errors, 737 warnings (unchanged) · `check-image-duplicates --maker WAS` 168, clean, with
Pillow · `spine-lookup` 36 asked, 0 failed · `swift scripts/validate-tours.swift` not run locally (no Swift on Linux), so CI runs it.

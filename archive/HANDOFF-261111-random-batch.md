# Handoff 2026-11-11 — random batch: 56 link pins from 73 links

Worked with Edward's "Random 10/13" list (73 links). No place or hold question was ruled on in session; they are on `status/owner/random-batch-261111.md`.

## What shipped
- **56 link pins** from 44 creators (21 new). Catalogue pins 4728 → 4784, makers 786 → 807, cities 1100 → 1108 (Aljezur, Richardson, Namwon, Margate, Malvern, San Vicente de Tagua Tagua, Waddesdon, Nazareth), countries and places unchanged.
- **60 images** on gh-pages in one plumbing commit `e7febe9` (56 heroes + 4 TikTok avatars), 60 A, 0 modified. The existing `avatar-tiktok-francescobeggio.webp` was not re-uploaded.
- Minted one URL at a time with `--title` (captions are paragraphs). The Chipperfield post (Turner Contemporary + Hepworth Wakefield) was split into two pins by city, ids re-derived with `merge-link-pins.py`'s own `expected_ids`.
- 19 tags added to new pins so the validator's warning count stayed at the 742 baseline.

## Triage
- 5 LIVE (already pinned), 1 DEAD (DfN8sc9RHAv, embedding off).
- Skipped: five same-creator repeats of an already-pinned building (@askvivii Museumbrary, @_seoullista Park Seo-Bo, @iammikaeljohansson House of the Redeemer, @theinsidertoronto City Hall + Royal Bank Plaza) and @notenoughangers' Park Ave apartment auction plug (10-11 precedent).
- Held (see owner item): NYC vault, Zürich itinerary, Zoo Sindang NYC (no NYC address found), Fung Wah bus, City of London sculpture, BIG NL block (best guess Sluishuis), the dead post.
- Sponsored posts pinned on the 10-11 precedent: Julia Ideson (Houston Chronicle), Institut français (ad).

## Coordinates worth knowing
- Where the subject already existed, the existing coordinate was reused exactly, so joins/places are 0 m.
- Concrete Traffic: the U Chicago Campus North garage, 5525 S Ellis (OSM credit-union node at that address).
- Kim Byung Jong Art Museum: OSM gallery node (함파우길 65-14). Eke library: Steenweg 88 house point. Praia do Canal: the hotel node (Photon), not the beach.
- Renwick Gates: Enid A. Haupt Garden centroid (the gates are its Independence Ave entrance).
- 1107 Fifth Ave: Nominatim's first answer was Watervliet, NY — re-queried with "Manhattan".

## Checks
`validate-tours-mirror` 0 errors / 742 warnings (baseline) · filenames align (60) · `spine-lookup` 56 asked, 0 failed · `join-places --max-move 100` and `check-place-candidates` read (questions on the owner item).

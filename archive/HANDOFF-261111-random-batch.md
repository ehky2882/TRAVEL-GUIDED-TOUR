# Handoff 2026-11-11 — random batch: 56 link pins from 73 links

Worked with Edward's "Random 10/13" list (73 links). No place or hold question was ruled on in session; they are on `status/owner/random-batch-261111.md`.

## What shipped
- **61 link pins** from 46 creators (23 new). Catalogue pins 4728 → 4789, makers 786 → 809, cities 1100 → 1108 (Aljezur, Richardson, Namwon, Margate, Malvern, San Vicente de Tagua Tagua, Waddesdon, Nazareth), countries and places unchanged.
- **60 images** on gh-pages in one plumbing commit `e7febe9` (56 heroes + 4 TikTok avatars), 60 A, 0 modified. The existing `avatar-tiktok-francescobeggio.webp` was not re-uploaded.
- Minted one URL at a time with `--title` (captions are paragraphs). The Chipperfield post (Turner Contemporary + Hepworth Wakefield) was split into two pins by city, ids re-derived with `merge-link-pins.py`'s own `expected_ids`.
- 19 tags added to new pins so the validator's warning count stayed at the 742 baseline.

## Triage
- 5 LIVE (already pinned), 1 DEAD (DfN8sc9RHAv, embedding off).
- Skipped: five same-creator repeats of an already-pinned building (@askvivii Museumbrary, @_seoullista Park Seo-Bo, @iammikaeljohansson House of the Redeemer, @theinsidertoronto City Hall + Royal Bank Plaza) and @notenoughangers' Park Ave apartment auction plug (10-11 precedent).
- The NYC vault post (@johnnymurtaugh) was held, then pinned once Edward named it: the Woolworth Building vault, on the Woolworth tour's coordinate (hero uploaded in a second gh-pages commit).
- Edward: skip the @myint.san.aung Zürich itinerary.
- Zoo Sindang (@chaijoie): Edward gave 4 W 37th St, which is The Draper hotel (OSM hotel node 40.7504334, -73.9839857); the bar is pinned there.
- Fung Wah Bus (@norbertobriceno): Edward gave 1 Allen St; pinned as The Fung Wah Bus Mural on that building's OSM point.
- City of London sculpture (@livinglondonhistory): Edward gave 1 Poultry; pinned as The Reliefs at No 1 Poultry on the building's OSM node.
- BIG block (@cityloop_nl): Edward gave Richard Mortensens Vej, Copenhagen — not Sluishuis. BIG's building on that street is 8 House (10 storeys); pinned on the existing @blessedarch 8 House coordinate (@cityloop_nl is a new creator). The VM Houses are on Ørestads Boulevard, not this street.
- DfN8sc9RHAv: Edward says it is the Met Cloisters, but Instagram exposes no handle and no cover for it (embedding off), so it cannot be minted. Not worked around. Edward: drop it.
- Held (see owner item): Zürich itinerary, Zoo Sindang NYC (no NYC address found), Fung Wah bus, City of London sculpture, BIG NL block (best guess Sluishuis), the dead post.
- Sponsored posts pinned on the 10-11 precedent: Julia Ideson (Houston Chronicle), Institut français (ad).

## Coordinates worth knowing
- Where the subject already existed, the existing coordinate was reused exactly, so joins/places are 0 m.
- Concrete Traffic: the U Chicago Campus North garage, 5525 S Ellis (OSM credit-union node at that address).
- Kim Byung Jong Art Museum: OSM gallery node (함파우길 65-14). Eke library: Steenweg 88 house point. Praia do Canal: the hotel node (Photon), not the beach.
- Renwick Gates: Enid A. Haupt Garden centroid (the gates are its Independence Ave entrance).
- 1107 Fifth Ave: Nominatim's first answer was Watervliet, NY — re-queried with "Manhattan".

## Places (Edward: "do all the places you're suggesting")
- **Joins (0 m):** La Colombe d'Or, Coal Drops Yard, Ford Foundation Building, Populus, Grand Central Terminal, Tate Modern.
- **New (0 m, places 515 → 528):** The Frick Collection, St. Paul's Chapel, 520 West 28th Street, Balfron Tower, Boston City Hall, The Hepworth Wakefield, Untermyer Gardens, Fondation Beyeler, Lido Kaltern, One Kearny Rooftop, Nová scéna, The Woolworth Building, 8 House.
- Done with `join-places.apply_join` and `make-places.apply` on a hand-checked list, so the older backlog joins (Colosseum, Carpenter Center, Battersea, Hampton Court, Depot Boijmans, Deichman, Operaparken, Karl-Marx-Hof) were NOT applied.
- Not touched: the @insightcities "Nová Scéna & the National Theatre" pin, 452 m east of the new Nová scéna place.
- Merged `origin/main` (Washington DC, #1182) mid-flight; conflicts were docs, the Key facts line and `spine/lookups.json.gz`.

## Checks
`validate-tours-mirror` 0 errors / 742 warnings (baseline) · filenames align (60) · `spine-lookup` 56 asked, 0 failed · `join-places --max-move 100` and `check-place-candidates` read (questions on the owner item).

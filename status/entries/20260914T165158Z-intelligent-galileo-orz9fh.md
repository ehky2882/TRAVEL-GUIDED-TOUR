# 20 link pins from @japanbyfood (PR #896) — 7 need a coordinate precision follow-up

_2026-09-14 16:51 UTC · branch `intelligent-galileo-orz9fh`_

Opened [#896](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/896):
20 link pins from @japanbyfood (Tokyo/Hakone), triaged from a 33-link batch.

Triaged before minting: 3 candidates were already pinned by #893 (merged
earlier the same day, same creator cluster) — Nihonbashi Toyoda, Kappo
Yuzuha, Makiyaki Ginza Onodera — dropped. Also dropped: 1 food truck
(no fixed address) and 2 venues whose captions gave no neighborhood at
all (Sushi Ohtani, Tempura Ono).

**Coordinate precision — flagged for a follow-up pass, per #895's finding
that this exact fallback put #885's pins hundreds–thousands of metres off:**
3 of the 20 matched a real OSM POI (building-precise). 10 resolved to a
postal/chome-block centroid (postal code cross-checked). 7 had no street
address in the caption at all and are neighborhood/landmark-centroid only:
Sushi Hajime (Shibuya Station area), Shojin Ryori Daigo (anchored to Atago
Shrine, not the restaurant itself), Oniku Karyu (Ginza district centroid),
Daikanyama Rokkakutei (Daikanyama transit-stop centroid), Tempura Ten Soso
(Roppongi Hills polygon centroid), Gyunabe Ukon (Sukumogawa interchange,
Hakone), Nishiazabu Kamikura (Nishi-Azabu district centroid).

validate-tours-mirror.py: 0 errors, 5 pre-existing unrelated warnings.
Heroes pushed to gh-pages in one commit (d10aaf8) via git plumbing — no
`gh` CLI in this environment.

# 9 owner-verified link pins for @blessedarch merged (#859) - closes out the #842 triage at 140/145 minted

_2026-09-13 14:05 UTC · branch `clever-wozniak-mmyxa6`_

Third pass on the #842 @blessedarch triage. The 9 candidates #857 had narrowed to
a campus/street/village but held back for an owner call - the owner supplied
precise coordinates for all 9 directly.

Each reverse-geocoded before minting: two landed on exact OSM-named nodes
("Dhyanalinga" and "Linga Bhairavi" at the Isha Yoga Center - the earlier
Semmedu-village fallback was ~3.4km off and is now superseded), the rest
confirmed the same street/building already identified by name (Gem Cinema on
Mirza Ismail Road, MetaHive at Whiteland Westin's actual sector, Darwin Bucky
near Ambawadi, the Zig Zag Towers' Abraj Quartier block).

PR #859 merged as `4217465` (linkPins 1982 → 1991): Lilavati Lalbhai Library,
Amdavad ni Gufa, Darwin Bucky, Gem Cinema, Dhyanalinga dome, Zig Zag Towers,
Linga Bhairavi Temple, Baneshwar Shiv Mandir, MetaHive facade.

validate-tours-mirror.py 0 errors (same 3 pre-existing warnings as main).
check-image-duplicates.py --pins clean, 9 heroes hash-verified live on
gh-pages (`e221e44`). No owner SQL owed.

This closes out the #842 triage entirely: 121 original + 10 (#857) + 9 (#859)
= 140 pins minted from the 145-link batch. 7 remain genuinely unresolvable
(private residences, no public address anywhere) - Toy Storey house,
SaffronStays Asanja x2, Chitnavis Wada, TARANG Pavilion, Museum of Meenakari
Heritage - plus the 10 ASK vlog-roundup posts and 1 RESEARCH item (Statesman
House, Delhi vs Kolkata) from the original triage, still open for the owner
if they want to revisit.

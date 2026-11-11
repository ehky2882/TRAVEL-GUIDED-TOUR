# Sun Tower (Yantai) settled on the owner's address — 23.6 km, by district not distance

_2026-09-21 16:20 UTC · branch `scale-pinned-tours-automation-db`_

**Sun Tower (Yantai) settled — 23.6 km, on the owner's address.**

This one was **refused** yesterday and escalated, because the only Wikidata
candidate had no description outside German, no Chinese label and one sitelink
— too thin to move a pin 23 km. The owner supplied `煙台市福山區海濱路揚帆廣場`,
which is **independent of Wikidata** and settles it **by district, not by
distance**, as rule 8d requires:

| | reverse-geocodes to |
|---|---|
| our old pin | 滨海路街道, **莱山区** — the **wrong district** |
| the new pin | **海滨路**, 福莱山街道, 烟台经济技术开发区, **福山区** |

⚠️ **Likely cause: 滨海路 (Binhai Rd, Laishan) and 海滨路 (Haibin Rd, Fushan) are
the same two characters reversed.**

Published sources place the building in the *Yantai Yeda Development Zone* =
烟台经济技术开发区, which is where the new point sits. Moved to OSM way
1132670545 (`amenity=arts_centre`, `building=yes`), within 1 m of Wikidata's
point.

⚠️ **Residual uncertainty, stated not hidden:** OSM names that way 时光塔, not
太阳塔, and carries no wikidata tag. The identification rests on Wikidata placing
*Sun Tower* within 1 m of it, the building type matching a cultural observatory,
the owner's address matching district **and** street, and OSM holding **no**
building named 太阳塔 anywhere in Shandong — no competing candidate. The square
the owner named (扬帆广场) is 390 m away; the **building** was preferred over an
area centroid.

Owner item `link-pin-batch-1032-sun-tower` cleared. Audit holds at
`DISAGREES: 0 unexamined`, `STALE: 0`, CONFIRMS **1,825**.

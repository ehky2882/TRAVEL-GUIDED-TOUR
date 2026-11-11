# Second pass on the 79 city-outlier flags: no coordinate errors

_2026-09-22 13:30 UTC · branch `scale-pinned-tours-automation-db`_

**Second pass over the 79 city-outlier flags — read against FULL captions.**

Not a re-read: the first pass judged these with 140-character captions, so the
caption recovery made it new evidence.

**Result: no coordinate errors.** Cape Point is 48 km from Cape Town, Lantau is
23–31 km from Hong Kong, Chongqing's 360 km outlier is correct because the
municipality is the size of Austria. Airports, suburbs and country parks make up
most of the rest.

🔴 **One row contradicted itself, and resolving it cut against the day's whole
premise.** *Rock Pools at Tai Long, Sai Kung* is titled for Sai Kung but its
caption says **"Sai Wan Ho Rock Pools"** — 17 km away, an urban MTR district
with no rock pools and nowhere to cliff-jump. Our point reverse-geocodes to
**下鹿湖, Sheung Luk Wu, Sai Kung**, which is exactly where people do.

**The pin is right and the creator's caption is wrong** — *Sai Wan **Ho*** for
*Sai Wan*. After a day of treating the caption as the strongest evidence
available, that is the necessary counterweight: the caption is evidence, and
evidence gets weighed. Recorded in `docs/lessons.md`, together with the pattern
it shares with *Binhai Road*/*Haibin Road* and *Great Court*/*Great Notley* —
**a near-miss name is the dangerous kind.**

No changes to the catalogue. The flags stand as read.

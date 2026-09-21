# Captions cut at 140 chars, and the cut lands on the address

_opened 2026-09-21 · clear with `git rm status/owner/caption-truncation-140.md`_

🔴 **43% of stored captions are cut at 140 characters, and the cut lands on the
address.**

`scripts/make-link-pin.py:621` is `caption[:140]`. Creators put their 📍 address
**last**, so a fixed-length cut preferentially destroys the single most useful
line in the caption.

Measured on the live catalogue (2026-09-21):

| | |
|---|---|
| captions | 5,463 |
| **exactly 140 characters** | **2,375 (43%)** |
| of those, ending mid-sentence | **2,320** |
| carrying a 📍 at all | 535 — **a floor, not a count** |

**It has already shipped a wrong coordinate.** *Modern Coffee House* (New York)
sat **22.9 km out on Staten Island**. Its caption ends `📍 105 E BROADWAY, NY, NY
10002`; ours stops mid-word immediately before the 📍. Staten Island has an East
Broadway too, and the **postcode** is what separates them.

**This is your call, because the caption is what a user reads on the pin:**

- **(a)** keep the stored caption as it is, but preserve the 📍 line when the cut
  would remove it — smallest change, fixes future pins only;
- **(b)** store the full caption and truncate in the UI, where it can expand —
  the address becomes available to every future audit;
- **(c)** leave it.

Either (a) or (b) only helps pins made **from now on**. The 2,320 already cut
would need re-fetching from the source posts to recover their addresses.

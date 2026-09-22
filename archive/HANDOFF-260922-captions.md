# Handoff — 2026-09-22 · The day the catalogue got its addresses back

Continues `HANDOFF-260921-3-city-outliers.md`. That day ended with the coordinate
audit at zero and a new check that asks no external source. This one is about a
field the pipeline had been throwing away for months.

---

## What shipped

| PR | |
|---|---|
| [#1055](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1055) | Recovered **2,351** truncated captions |
| [#1057](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1057) | `check-caption-address.py` — the audit the recovery was for |
| [#1058](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1058) | Second pass on the outlier flags · the truncation guard |

## The recovery

`make-link-pin.py` stored `caption[:140]` and discarded the rest. **2,364
captions sat at exactly 140 characters**, nearly all ending mid-word — and
because creators put their address **last**, the cut landed on the most useful
line in the text.

| | |
|---|---|
| recovered | **2,351** |
| already complete | 7 |
| dead posts | 5 |
| **refused by the prefix guard** | **1** |
| characters restored | **897,983** (median +228) |

Captions carrying a 📍 went 535 → 943.

🔴 **CORRECTION, made later the same day: that number is true of the caption
FIELD and misleading about the evidence available.** `longDescription` was
never truncated — it carried the full text all along, and **913 entries already
had a location marker there** before a single caption was re-read. Measured:

| | caption | longDescription | **either** |
|---|---|---|---|
| before | 535 | **913** | **913** |
| after | 943 | 945 | **945** |

**The addressable evidence base gained 32 entries, not 408.** What the recovery
genuinely fixed is the display — 2,320 captions ended mid-word on screen — and
the two fields now agree. The audit could have been built yesterday by reading
`longDescription`, and now reads **both**.

This is the exact failure this file spends the rest of its length warning about:
**a number that is true of one field, stated as if it were true of the thing
that matters.**

**The prefix guard is the safety property.** A refetched caption is accepted only
if the stored 140 characters are a prefix of it, compared on **normalised** text
(the pipeline stores whitespace collapsed; comparing raw would have rejected
every Instagram post with a line break — the whole platform). One post failed it:
edited since, so no longer the same caption.

## 🔴 I was wrong about the cost, by 15×

I warned this would add **~12% egress** on a payload that has drawn two overage
notices, and offered that as a reason to hesitate. Measured at gzip level 1,
which is what PostgREST uses:

| | before | after | |
|---|---|---|---|
| raw | 15,667,186 | 16,602,669 | +6.0% |
| **gzip-1** | **4,431,645** | **4,467,188** | **+0.8%** |

**35 KB, not 300.** `CLAUDE.md` § Egress warns in bold that raw size *"overstates
text fields badly"* and that two earlier cuts were nearly decided on it. I quoted
that rule in my own commit messages the same day and still estimated from
character counts. Captions compress hard because they are the most repetitive
text here.

## The audit the recovery was for

`check-caption-address.py` asks: **the caption names a city we know — is it this
entry's city?** No geocoding, no external source; the gazetteer is the
catalogue's own city list.

🔴 **It tests the LOCALITY, not the distance**, per rule 8d. Both halves are
paid for: an address-only geocode put **Cube House** 1,421 m from a *correct*
pin, and **Sun Tower** was settled not by distance but by district.

**Result: of 551 captions naming a known city, 15 disagree — none is a wrong
pin.** Adjacent towns, Hong Kong's *Austin* Road and *Aberdeen* district,
Toronto's *Queens* Quay.

**What it did find: `St Louis` and `St. Louis` were one city stored twice.** The
`Sao Paulo`/`São Paulo` accent-folding written earlier cannot see a
**punctuation** variant. Merged.

## Two findings that cut against the day's own premise

**1 · The creator's caption can be wrong.** *Rock Pools at Tai Long, Sai Kung* is
titled for Sai Kung; its caption says **"Sai Wan Ho"** — 17 km away, an urban MTR
district with no rock pools. Our point reverse-geocodes to 下鹿湖, Sheung Luk Wu,
Sai Kung, which is exactly where people cliff-jump. **The pin is right.**

**2 · A pipeline fix does not reach work already in flight.** The day after the
recovery left 24 captions at the cut, there were **111**. Eighty-seven were
`@historicpubcrawls` pins from #1054, merged from a branch cut **before** the
fix. Every check passed; it surfaced only because a count was being re-derived by
hand. Recovered 86, and `refetch-captions.py --check` now fails CI on any
unexcused cut.

## State

| | |
|---|---|
| tours / pins / places | 1,582 · 3,657 · 408 |
| makers · cities · countries | 527 · 774 · 93 |
| entries with a 📍 in either field | **945** (was 913) |
| at exactly 140 | 24 — 10 with no URL, 14 excused, **0 unexcused** |
| validator | 0 errors, 557 warnings, `control clean` |

## Still open for the owner

- **Four @welldonestuff reel links** (Calgary Central Library, Guangzhou Circle,
  Huajiang Bridge, Three Gorges Dam) — the pins cannot be restored without them
- **Press *Release this version*** for 1.1.3 when Apple approves
- **List-description clamp** — the one surface of #1051 not checked on device
- **Stortorget** part-vs-whole · **two place candidates**
- ⚠️ **#1019 must NOT be merged**

## Next

`check-pin-subject.py` has better material now — more titles may be corroborable
from text alone, shrinking the set that needs vision. The place-candidate menu is
owed a regeneration after 117 new pins. And the **2,901 unmatched** entries remain
the frontier: three checks reach into them and none found an error today, which
is either good news or means the next question has not been asked.

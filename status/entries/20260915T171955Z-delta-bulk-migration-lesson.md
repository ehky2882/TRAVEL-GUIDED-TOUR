# A bulk migration makes the next delta bigger than a full fetch

_2026-09-15 17:19 UTC · branch `delta-bulk-migration-lesson`_

🔴 **A BULK MIGRATION TURNS THE NEXT DELTA INTO A FULL DOWNLOAD FOR EVERY USER — and charges more
than a full fetch for it.** Observed on production today, not theorised.

[#915](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/915)'s migration wrote
`related_tour_ids` and `authored_on` onto **every tour row**, so the `rev` trigger correctly bumped
**all 1,582 tours**. A `get_catalog_since` from a cursor older than that migration then returned:

| | bytes |
|---|---:|
| `get_catalog_since(14075)` after the backfill | **2,752,051** |
| a full `get_catalog` | 2,427,222 |
| the same call before the backfill (43 changed rows) | 19,496 |

**The delta was LARGER than the whole catalogue** — it is every row plus the envelope. Correct
behaviour; every one of those rows genuinely changed. But it means that **once 1.1.3 is in the
field, a catalogue-wide rewrite becomes an egress event costing more per user than a full fetch**,
where today it costs the same as any other day. Backfills that were free now have a price: batch
them, do them rarely, prefer a migration that touches only affected rows.

⚠️ **A cursor's AGE determines its cost.** A phone that has not opened the app since before a
backfill pays full price on its next launch however little real content changed — so "typical delta
size" measured from one sample is misleading.

Recorded in `docs/delta-catalog-fetch-design.md` § 8 (item 6b) as a property of the design, because
nothing else in that document implied it.

---

⚠️ **And the reason it was measured at all is a mistake worth recording.** The question was "did
#915's migration reach production?" — answered conclusively by a **407-byte** column select. A
second, redundant confirmation through `get_catalog_since` cost **2.75 MB**, about 1.6% of a day's
allowance, in a session whose entire subject is egress. The failure is not the expensive call; it
is **continuing to check after the question was answered.** `docs/lessons.md` § "Stop at the cheap
check when it is conclusive".

**Also confirmed live while there:** `tours.related_tour_ids` and `tours.authored_on` exist and
`get_catalog_since` emits `relatedTourIds` and `createdAt`, so #915 has real data behind it and
**nothing is owed to the owner** for it.

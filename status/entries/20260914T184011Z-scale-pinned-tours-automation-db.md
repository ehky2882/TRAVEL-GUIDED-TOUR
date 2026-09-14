# 100k pin scaling: design written, three fatal scale walls measured

_2026-09-14 18:40 UTC · branch `scale-pinned-tours-automation-db`_

**Design only — no code, no catalogue change.** Answers the owner's question: how to
reach 100,000 quality link pins without doing it by hand.

**Measured, this session:** 2,193 pins · 1.03 pins per subject · TikTok 1,253 /
Instagram 921 / **YouTube 19 (0.9%)** · **279 of 390 creators have exactly one pin
while the top 10 hold 1,258 — 57%** · one pin costs **~1,867 B raw / ~410 B gzip-1**.

**Three findings that shape everything:**

1. **There is no discovery step at all.** The owner pastes links; the scripts begin
   at "a list someone already decided is worth pinning." And crawling is not
   available: Instagram enumeration is impossible, TikTok caps at 14/handle,
   YouTube RSS ~15.
2. **Four human-typed fields gate every batch** — `lat,lon`, `city`, `country`,
   `category`/`tags`. `make-link-pin.py` has **no geocoder** (`grep -c` → 0).
   Everything else already runs itself.
3. 🔴 **100,000 entries breaks the product in three FATAL places**, not gradually:
   the app OOMs **inside `DataService.init`, before first frame** (>1 GB);
   `get_catalog` becomes **~60 MB gz per fetch — 83 fetches/month against the 5 GB
   quota**; and the snapshot becomes a **~320 MB jsonb row** on an instance that
   already OOM'd for ~11h45m at 8 MB on 2026-09-14.

**Owner decisions taken:** creator OAuth portal as the supply engine · densify to
~25–30k places × 3–4 creators · ingest to an unserved staging table in parallel with
the architecture work.

**The plan's core move:** a place spine from OpenStreetMap turns all four typed
fields into a join, so the coordinate is **copied from the official record rather
than inferred** — which retires the measured northward bias (208/262 north,
p = 1.7e-22) by construction rather than by care.

⚠️ **Blocked on the owner:** auto-created places (`status/owner/auto-created-places.md`).
⚠️ **External dependency to start on day one:** TikTok + Instagram platform app review.

# Phase 2 delta client open as #914, CI green

_2026-09-15 13:34 UTC · branch `catalog-delta-client`_

**Phase 2 is open as [#914](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/914) with all four
checks GREEN** — including `Build (iOS Simulator)` and `Run unit tests` on a real macOS toolchain,
which matters because **there is no Swift toolchain in a web session** and none of it could be
compiled locally. Branch `claude/catalog-delta-client`. **App code → owner simulator/TestFlight
review before merge.** Merge [#912](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/912) first.

🔴 **The load-bearing decision: the merge works on RAW JSON, not on `ToursData`.**
`ToursData.encode` writes exactly four keys and each `Tour` exactly its own declared properties, so
decode-then-re-encode would **silently delete every key this build does not model** — a field the
server starts sending tomorrow survives the fetch (unknown keys decode harmlessly) and is then
erased from the cache by the first merge. `ToursData` says so itself: *"the cache is written from
the raw response bytes, never re-encoded."* `testKeysThisBuildDoesNotModelSurvive` fails if that
stops holding.

⚠️ Ids compare **lowercased** — pin ids are UPPERCASE in `Tours.json`, lowercase from Postgres. A
case-sensitive match would not error; it would append a duplicate of every pin on every merge.

⚠️ **Rule 3 is measured against what the cache ALREADY lost, not against zero.** A build that
cannot read one existing row drops it on every decode, so a zero baseline would disable the delta
path permanently for that user.

⚠️ **The cursor for the next refresh is read BEFORE the download.** Read before, a reseed
mid-download leaves the cursor slightly behind and the next delta re-sends a few rows we already
hold — harmless, a merge replaces by id. Read after, the same reseed pairs a NEW cursor with OLDER
content and the rows between are never sent again. A full download from a source with no delta
fetcher **clears** the cursor.

⚠️ **The delta path decodes the catalogue TWICE** (baseline + merged) where a full download decodes
once. Documented in `mergedCatalog` rather than left to be discovered; no cheaper baseline exists
since `losses` and `tours.count` only exist after a decode.

⚠️ **Caught by reading, not compiling:** `Tour.priceUSD` is non-optional with no default, so the
first test fixtures would have decoded to **zero tours** and every assertion would have passed
vacuously.

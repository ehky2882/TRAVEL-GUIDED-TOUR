# Sending only what changed — delta catalogue fetching

**Status (2026-09-15): Phases 0, 1 and 2 are MERGED. Phase 3 is not built.**
This file was written as scope-and-design only; three of its four phases have since been built, so
read § 6 as a record of what exists, not as a proposal.

| phase | what it is | state |
|---|---|---|
| **0** | conditional seed writes — an unchanged re-seed writes **0 rows** instead of ~14,176 | **shipped** (#904), applied |
| **1** | `get_catalog_since(rev)` — the RPC that returns only changed rows | **shipped** (#912), **applied to production** |
| **2** | the client merges a delta into the catalogue on disk | **shipped** (#914), device-verified; **not released** |
| **3** | **removals** — `removedIds` is always empty, so content *deleted* from the catalogue still needs a full download | **NOT built** |

🔴 **Nothing above has reached a single phone.** Phase 2 ships with the next App Store release;
until then every build in the field downloads the whole catalogue on every change. The egress
problem this file exists for is **not solved yet** — the machinery to solve it merely exists now.

⚠️ **Do not quote the phase table without checking it** — the same rule this file already applies
to its measurements. `git log --oneline -- backend/catalog_since.sql backend/catalog_rev.sql` and
the live RPC are the sources; a `get_catalog_since` call with a sentinel cursor returns a
**131-byte** envelope if it is live and a 404 if it is not, for effectively no egress.

**Measured on production 2026-09-15**, on a real delta (3 tours + 40 link pins whose coordinates
had just been corrected by #917): **43 changed rows in 19,496 bytes**, against **2,427,222 bytes**
for the full catalogue — **124× smaller**. On the common case, nothing changed, the envelope is
**131 bytes**: about **19,000× smaller**. Those two numbers are the whole argument for Phase 2.

Written 2026-09-14, the morning after the Supabase project was unreachable for ~11h45m, and six
days after the second egress-overage notice. **One design decision caused both incidents, two
weeks apart.** That is the case for this work.

Every figure below was **measured against the live database on 2026-09-14 between 13:10 and 13:14
UTC**, from a single saved copy of the payload. None of it is quoted from another document — and
one number that *is* in another document turns out to be badly wrong (§ 3.1). Re-measure rather
than quoting this file: `§ Appendix A` is the method, and it costs one fetch.

---

## 0. In plain English — for the owner

**The problem.** Every time the app checks for new content and finds any, it downloads the entire
catalogue — all 3,674 tours and pins, every city, every description — **2.4 MB compressed**. Even
if one pin in Prague moved four metres. There is no way to ask the database for "just the bit that
changed", because we never built one.

**Why you should care, in money and in downtime.** It has already cost you twice:

- **8–10 September:** the egress bill. 11.82 GB against a 5 GB allowance.
- **14 September (last night):** the whole backend was down for nearly twelve hours. The database
  had 512 MB of memory and was sitting at 79% of it. Building and shipping an 8 MB document to
  every phone that opens the app is what filled it.

The second one was fixed by moving the database to a bigger machine (1 GB, free). **That bought
headroom, it did not fix the cause.** The cause is that we send everything, every time.

**What has already been done, so nobody re-proposes it:**

| Fix | Effect |
|---|---|
| The app asks "has anything changed?" (34 bytes) before downloading | Cuts **how often** we pay |
| Stop transcripts taken off the wire | Cut **how much** we pay, once — 37.5% gone |
| App only re-checks every 15 minutes, not every 60 seconds | Cuts how often we ask |

**What is left, and what this document is about:** when anything *has* changed, we still send all
of it. A typical day's change is **7 KB of new content**. We send **2.4 MB** to deliver it. We are
sending roughly **345 times more than we need to.**

**The honest answer to "how long?"** The database work is a weekend. The app work is a weekend.
But the relief does not arrive when the code is written — it arrives when people's phones have
the new version of the app, which means **an App Store release and then a few weeks of people
updating**. Call it **a fortnight of work and about a month before the bill actually falls.**

**The single most important thing to understand before deciding:** the app that is live on the
App Store right now cannot be changed. Whatever we build, **version 1.1.1 on someone's phone will
keep downloading the full 2.4 MB forever**, because it only knows how to ask the one question it
was built to ask. So this is not a switch we flip — it is a new, cheaper road that new versions of
the app take, while the old ones keep using the old one until people update. Any plan that tries
to make the *old* road cheaper breaks the app on phones we cannot reach. § 4 explains why, and it
is the part of this document that matters most.

**My recommendation, in one line:** do it as **four phases**, and the first two are database-only,
invisible to every phone, and independently worth doing — **Phase 0 alone would have reduced the
memory pressure that took the site down last night.** Then one app release carries the actual win.

---

## 1. What is actually being sent — measured

One `POST /rest/v1/rpc/get_catalog` with `Accept-Encoding: gzip`, 2026-09-14 13:10 UTC:

| | |
|---|---:|
| **On the wire (compressed — this is what is billed)** | **2,427,222 bytes** |
| Raw, after decompression | 8,393,814 bytes (8.0 MB) |
| Time to first byte | 1.27 s |
| Total transfer | 2.10 s |

⚠️ **`CLAUDE.md` records 2,276,264 bytes on 2026-09-12.** Two days and roughly 80 new link pins
later it is **2,427,222** — **+6.6% in 48 hours**. The payload is growing at about 3% a day. This
is not a stable problem that can be left alone.

**The allowance is 5 GB/month ≈ 167 MB/day ≈ 69 full fetches a day**, across every user, every
one of our scripts, and every cold launch. The daily figures in `CLAUDE.md` for 8/9/10 September
(1,963 / 493 / 241 MB) are 808 / 203 / 99 fetches respectively.

### 1.1 A calibration that matters for every number below

PostgREST compresses at **gzip level 1**, not level 9. Recompressing the decoded payload locally:

| level | bytes | |
|---|---:|---|
| **1** | **2,433,995** | ← matches the 2,427,222 actually served |
| 6 | 2,092,787 | |
| 9 (Python's `gzip.compress` default) | 2,076,021 | |

**Measure at level 1.** Python's default is level 9, so a naive `len(gzip.compress(...))` understates
the real bill by ~15% and, worse, *mis-ranks* fields: high-entropy prose compresses far better at 9
than at 1, so level-9 measurement makes text look cheaper than it is billed.

### 1.2 Where the bytes are

By removing one section and re-compressing (gzip level 1; base document 2,417,060 bytes
re-serialised):

| section | live count | cost | share |
|---|---:|---:|---:|
| `tours` | 1,553 | 1,333,202 | **55.2%** |
| `linkPins` | 2,121 | 956,778 | **39.6%** |
| `places` | 289 | 97,454 | 4.0% |
| `makers` | 448 | 28,935 | 1.2% |

⚠️ The live database holds **1,553 tours** against `Tours.json`'s 1,552 and **448 makers** against
420 — the database is legitimately a superset (in-app maker uploads live only in Postgres).
`linkPins` is 2,121 in both.

---

## 2. Which fields dominate — measured, not assumed

Cost of each field, measured by deleting it from every tour and pin and re-compressing at level 1.
Anything under 2% is listed for completeness; only the top of this table is worth designing around.

| field | cost (bytes) | share of the bill |
|---|---:|---:|
| **`tours[].longDescription`** | **1,060,588** | **43.9%** |
| `stops[].caption` | 121,397 | 5.0% |
| `tours[].shortDescription` | 86,765 | 3.6% |
| `tours[].tags` | 70,376 | 2.9% |
| `tours[].makerId` | 64,943 | 2.7% |
| `tours[].sourceURL` | 42,087 | 1.7% |
| `tours[].additionalImageURLs` | 40,321 | 1.7% |
| `tours[].heroImageURL` | 36,757 | 1.5% |
| `stops[].imageURL` | 38,903 | 1.6% |
| `tours[].title` | 26,429 | 1.1% |
| everything else (17 tour fields, 8 stop fields) | < 26,000 each | < 1.1% each |

`longDescription` splits **713,113 bytes on tours** (29.5%) and **347,567 on link pins** (14.4%) —
a pin's `longDescription` is the creator's caption text, 387 characters on average across 2,121
pins, 2,111 of them distinct.

### 2.1 🔴 The 8.2% figure in `CLAUDE.md` is wrong. It is 44%.

`CLAUDE.md` § Egress says `longDescription` is *"8.2% compressed — not the 18% once wrongly
recorded, which was a raw figure"*, and on that basis it was deliberately kept. **Measured today
it is 43.9% of the compressed payload** — by far the largest single thing we send, five times the
recorded figure.

Two independent methods agree, and it is not a compression-level artefact:

| method | saving | share |
|---|---:|---:|
| delete the key from every tour and pin | 1,060,588 | 43.9% |
| keep the key, blank the value (`""`) | 1,057,981 | 43.8% |
| delete the key, gzip level 6 | 915,366 | 44.0% |
| delete the key, gzip level 9 | 916,533 | 44.4% |

The control behaves as expected: `shortDescription` blanked saves 87,582 (3.6%), matching its
deletion figure of 86,765.

**And the underlying intuition in `CLAUDE.md` is backwards for this field.** That file's rule —
"raw overstates text fields badly" — holds for repetitive text. `longDescription` is the opposite:
**28.4% of the raw bytes but 43.9% of the compressed ones**, because it is high-entropy prose
(1,553 of 1,553 tour values distinct) sitting in a document otherwise made of UUIDs, repeated JSON
keys, coordinates and URLs off a single CDN host, all of which gzip flattens. **Prose is the part
that *survives* compression.** So the correct general rule is not "raw overstates text" but
"measure it at level 1, both ways, every time".

🔴 **This does NOT mean "drop `longDescription`".** § 4.2 shows that dropping it from the wire
would silently empty the catalogue on every phone in the field — it is the single most dangerous
change available in this codebase. It means something more useful: **the 44% is the prize any
delta or index scheme is actually competing for**, and that prize is much bigger than the
documentation says. It is also *why* transport-level fixes are now the only ones left: the field
trimming that worked for transcripts cannot be repeated here.

**Action owed regardless of this project:** correct the 8.2% line in `CLAUDE.md`. Left as it is, a
future session will decide something on it, exactly as this one nearly did.

---

## 3. How much of it is actually new — measured

The whole question is: when the catalogue changes, how much has changed?

Replaying the **last 30 commits that touched `Resources/Tours.json`**, diffing entries by id at
each commit against its parent, and compressing the resulting delta document (changed tours +
changed pins + removed ids) at level 1:

| | changed entries | delta, gzipped |
|---|---:|---:|
| **median commit** | **15.5** | **7,019 bytes** |
| mean | 20.7 | 14,650 bytes |
| largest in the sample (#881, 13 tour coordinate fixes) | 19 | 60,146 bytes |
| largest by count (#842, 86 link pins) | 86 | 21,405 bytes |
| smallest non-empty (#832, one pin becomes a place) | 1 | 868 bytes |
| metadata-only commit (#847, maker handles) | 0 | 53 bytes |

**The median change is 0.29% of what we send to deliver it.** We are sending about **345× more
than the change is worth.** The worst case in the sample is still only 2.5%.

⚠️ A phone that is several merges behind pays the *union* of those deltas, not their sum, and the
sample shows content commits are small and disjoint. Even a phone a full week behind (~36 commits)
would coalesce to well under 200 KB.

### 3.1 How often it changes — and why the version check does less than hoped

`Resources/Tours.json` changed on **28 of the last 30 days**, across **156 commits** — about **5.2
content merges a day**, each of which reseeds and bumps `catalog_snapshot.refreshed_at`.

That is the uncomfortable finding for the shipped version check. `docs/catalog-version-check-design.md`
estimated the catalogue changes "on roughly 20 days a month". It changes on **28 of 30**, more than
five times a day. So:

- the version check still does exactly what it claims for a **repeatedly-opening** user or script
  (the second, third and fourth open within a 15-minute window now cost 34 bytes);
- but for a user who opens the app **once or twice a day, it saves almost nothing** — there is
  nearly always something new, and "something new" costs the full 2.4 MB.

**This is the strongest argument in the document.** The cheap-question fix is doing its job and is
still leaving most of the bill on the table, because the frequency of change is high and the price
of change is the whole catalogue. Only cutting the *price* of a change helps now.

---

## 4. The hard constraint: builds already in the field

**This governs every option below. Read it before the options.**

`Dozent` is live on the App Store at **1.1.1** (released 2026-09-01), with **1.1.2 (build 160)
in App Review**. ⚠️ Both are perishable — I could not check App Store Connect from this session
(no key), so re-derive the review state rather than trusting this line;
`curl -s "https://itunes.apple.com/lookup?bundleId=com.ehky.TRAVEL-GUIDED-TOUR&country=us"`
gives the released version from anywhere.

Those builds are frozen. They will call `get_catalog()` and decode its answer exactly the way they
were compiled to, for as long as they are installed.

### 4.1 What is safe, and why — the two precedents

**An unknown top-level KEY is free.** `ToursData` is `Codable` with a fixed `CodingKeys` set, so a
key it has never heard of is skipped without a word. That is how `places`, `sourceURL`,
`sourceAuthor`, `country`, `videoURLs` and `videoRole` all reached shipped builds without breaking
one. **Every scheme in this document must arrive as a new sibling key, never as a change to an
existing one.**

**An unknown VALUE in a field an existing build already parses is fatal.** `TourKind` is a closed
`String` enum, so `kind: "link"` *inside* `tours` threw on every build predating `TourKind.link` —
and because `[Tour]` decoded as one array, one unreadable element failed the **whole** catalogue.
The loader's `try?` turned that into "this source is unusable", so those phones silently kept
their last good copy and stopped receiving content. That is why link pins live in a sibling
`linkPins` array.

**Since then there is a second layer**, and it is a genuine asset here: `ToursData.init(from:)`
decodes `makers`, `tours`, `linkPins` and `places` **element by element** (`Tolerated<Wrapped>`),
keeping what decodes and counting what it drops into `CatalogDecodeLosses`. One unreadable tour
now costs that tour, not the catalogue.

### 4.2 🔴 …and that second layer is also the trap. The most dangerous change available.

Element-wise tolerance turns a *loud* failure into a *silent total wipe*, and the fields that
matter most are exactly the ones that trigger it.

In `Models/Tour.swift`, these are **non-optional**:

```
id, title, shortDescription, longDescription, makerId, heroImageURL, kind, stops
```

Follow what happens if a future payload stops sending `longDescription` inside `tours`:

1. Every `Tour` element fails to decode — a missing non-optional key throws.
2. `Tolerated` swallows each throw. `tours` decodes successfully, **with zero elements**.
3. `ToursData` decodes fine — the document has a `tours` key, which is all `init(from:)` requires.
4. `RemoteCatalogLoader.decodeCatalog` returns a valid `ToursData`, logs the losses to
   `os.Logger`, and reports **`.fetched`**.
5. `writeCache` **overwrites the good on-disk cache with the empty payload**, and stamps it with
   the current catalogue version token.
6. The app shows an empty catalogue. On the next launch the version check matches, so it does not
   even re-download. **The phone is stuck on nothing until the snapshot version changes.**

No crash. No failed CI. One `os.Logger` line that nobody is reading. This is the 2026-08-19
failure — three features vanishing silently for 14 hours because optional fields decoded as nil —
except **worse**, because these fields are not optional, so it costs the whole catalogue rather
than one feature, and it *persists* through the version check.

**The three rules that fall out of this, and they are not negotiable:**

1. **Never remove a key from what `get_catalog()` returns.** Not `longDescription`, not
   `shortDescription`, not `makerId`. The 44% cannot be taken back from existing builds at any
   price. `scripts/check-catalog-keys.py`'s `REQUIRED_TOUR` set already encodes this; it must stay.
2. **A delta payload must never be served from `get_catalog()`.** A partial catalogue in the
   existing endpoint would present to a 1.1.1 phone as *the whole catalogue, now containing 15
   tours*, and it would be cached as such. New behaviour needs a **new RPC name**.
3. **`kind` stays closed and pins stay in `linkPins`.** Nothing here changes that.

### 4.3 One more compatibility fact that bounds the benefit

`RemoteCatalogLoader.readCache()` discards the cache when `Tours.cache.version` (the app's
`CFBundleVersion`) does not match the running build. **Every app update therefore throws away the
cache and pays a full 2.4 MB download on first launch, whatever delta scheme exists.** That is
correct behaviour — it is what stops a stale cache shadowing a newer bundled seed — and it is a
floor under the saving: one full fetch per user per app update.

There is a way to lift that floor later, and it is cheap: `publish-catalog.yml` could stamp the
bundled `Resources/Tours.json` with the snapshot token it corresponds to, so a freshly-updated app
could ask for the delta **against its own bundled seed** rather than downloading everything.
Noted as a Phase 3 idea, not costed here.

---

## 5. The options

### Option A — a changed-since cursor (`get_catalog_since(token)`) ✅ recommended

**The shape.** A new RPC takes the token the client already stores beside its cache and returns
only what has changed since:

```
{ "version": "<new token>",
  "tours":    [ …full tour objects that changed… ],
  "linkPins": [ …full pin objects that changed… ],
  "makers":   [ … ], "places": [ … ],
  "removedIds": [ … ] }
```

The client merges by id into its cached catalogue and rewrites the cache.

**Cost:** the median merge becomes **7 KB instead of 2,427,222** (§ 3). A quiet day is 53 bytes.

**Why it is the best of the four:**

- It changes **nothing the user can perceive.** The app still holds the entire catalogue; the map,
  the rails, search and place pages are all catalogue-wide today and stay that way. This is a
  transport change, not a product change — which is the opposite of Option B.
- It composes with the version check already shipped, rather than replacing it: the 34-byte probe
  still short-circuits the "nothing changed at all" case, and the new RPC handles "something
  changed".
- It degrades to today's behaviour on any error: an unknown token, a token older than the server's
  retention, a malformed response, or any failure → fall through to `get_catalog()`. **Fail
  toward the full download** is the same rule the version check was built on, and it is what makes
  this safe to ship.

**Its two real costs, stated honestly:**

- 🔴 **`updated_at` is useless as a cursor today, and fixing that is a prerequisite.**
  `backend/seed_from_toursjson.py` ends every tour upsert with `updated_at = now()`
  **unconditionally**, so every one of the ~3,674 rows is rewritten with a new timestamp on
  **every seed** — about 5.2 times a day — whether or not one byte of it changed. A naive
  `where updated_at > $1` cursor would return the entire catalogue every time and save nothing.
  The same is true for `makers` and `places`.
  **And `stops` has no `updated_at` column at all** — the seed does
  `delete from public.stops where tour_id = …` and re-inserts every stop of every tour on every
  run, so stop changes cannot be dated even in principle. This is Phase 0 and it is unavoidable.
- **Deletions need a mechanism.** `seed_from_toursjson.py` is upsert-only for tours and pins, so a
  deletion from `Tours.json` never reaches Postgres at all — `CLAUDE.md` § Egress already
  documents this as a known two-part manual change. A delta scheme makes it worse: a full fetch at
  least re-establishes ground truth, while a delta never mentions a row it does not see.
  **The fix is cheap:** a periodic reconciliation, where the client asks for the complete id list
  and drops anything it holds that the server does not. **Measured: all 3,674 ids gzip to 83,542
  bytes (74,445 with hyphens stripped) — 3.5% of a full fetch.** Once a week per phone is
  negligible; it also bounds any drift the delta path could accumulate.

### Option B — per-city / per-region scoping ❌ not recommended

**The shape.** `get_catalog_for_cities(['New York','London'])`, driven by the user's location and
whatever they have opened.

**Cost, measured:** New York alone is 264,719 bytes (11.0% of a full fetch); Hong Kong 158,668;
London 124,768; Tokyo 91,962. The top three together are 568,506 (23.5%). A city with one entry
is 1,557 bytes. The ten largest cities account for **43.7% of all entries**.

**Why not, despite the numbers looking good:** *it is a product change wearing a transport
change's clothes.* Home rails, `SearchView` and the map are **catalogue-wide**. Scope the
catalogue to a city and a user in Lisbon can no longer search for the London walk they saved, the
map shows nothing outside a boundary, and a saved library entry can point at a tour the app no
longer holds. There is no "download this city" concept in the app to hang it off, and inventing
one is a design project, not a plumbing job.

It is also **worse on repeat cost** than Option A: a travelling user pays a fresh city-sized
download per city rather than a merge-sized delta, and any city's content changing still re-sends
that whole city. Keep it in the drawer as a *later* refinement of Option A (scope the *first*
sync, delta everything after) — not as the thing to build.

### Option C — server-side diff against a client-held version ❌ not recommended

**The shape.** The server stores each client's last-known state (or a set of historical snapshots)
and computes a true diff.

**Why not:** it is Option A plus a large amount of state we would have to keep and expire, on the
instance that just ran out of memory. `catalog_snapshot` is deliberately **one row** — storing
per-version snapshots to diff against would reintroduce exactly the memory and storage pressure
the snapshot design removed, and per-client state on an anonymous, unauthenticated read path is a
new problem with no upside over a monotonic cursor. Option A gets the same benefit with one
timestamp comparison and no server-side memory of anyone.

### Option D — light index + detail on demand ⚠️ genuinely good, but second

**The shape.** The catalogue becomes a small index (everything needed for a map pin, a rail card
and a search hit), with `longDescription` and stop captions fetched per tour when the user opens
one.

**Cost, measured:** an index with `longDescription` and `stops[].caption` removed is **1,062,795
bytes — 44% of today's payload**, saving 56%. Stripping stops and galleries as well gets it to
746,200 (31%). A single tour's detail (`id` + `longDescription`) is a **median 590 bytes**.

**Why it is second, not first:**

- It cannot be applied to the existing endpoint at all — see § 4.2. `longDescription` is
  non-optional in `Tour`, so an index served to a 1.1.1 phone empties its catalogue. It is
  strictly a new-RPC, new-build change.
- A one-off 56% cut is smaller than Option A's ~99.7% cut on the recurring case, and it does not
  compound: the index still re-downloads in full whenever anything changes.
- `SearchView` searches `longDescription`. An index-only client either loses that (a visible
  regression the owner did not ask for) or needs a local search index built from detail it has
  not fetched.
- It adds a round trip and a loading state to `TourDetailView`, which today renders instantly from
  data already in memory, including offline.

**But it composes beautifully with Option A and should be the phase after it**: an index-shaped
delta makes the *first* sync of a new install cheap (1.06 MB rather than 2.43 MB) while deltas
keep it cheap afterwards. Detail-on-demand also caps the growth problem: the payload is growing
3% a day, and 44% of that growth is prose nobody reads until they open the tour.

### The options side by side

| | median steady-state cost | first sync | app release needed | user-visible change | risk |
|---|---:|---:|---|---|---|
| today | 2,427,222 | 2,427,222 | — | — | — |
| **A — changed-since** | **~7,019** | 2,427,222 | yes | none | low |
| B — city scoping | ~125,000–265,000/city | ~265,000 | yes | **yes — breaks search/map** | high |
| C — server-side diff | ~7,000 | 2,427,222 | yes | none | **high (server memory)** |
| D — index + detail | 1,062,795 | 1,062,795 | yes | detail loading state | medium |
| **A + D together** | **~7,019** | **1,062,795** | yes | detail loading state | medium |

---

## 6. Server side — what changes in `backend/`

Nothing in this section changes what `get_catalog()` returns. That is the point.

### Phase 0 — make "changed" mean something (no new RPC, no app change)

**`backend/seed_from_toursjson.py` — conditional upserts.** Add a
`where <table> is distinct from excluded` guard to the `on conflict do update` clauses for
`tours`, `makers` and `places`, so `updated_at = now()` fires only on rows that actually changed.
This is the load-bearing change: without it every cursor scheme returns everything.

⚠️ **Careful with `is distinct from` and the two columns the seed does not set.** `place_id` is
cleared and re-set by a separate statement, and `published_at` is written as `now()` on insert —
compare the column list the upsert actually writes, not the whole row, or every seed will still
look like a change.

**Give `stops` a change signal.** Today the seed deletes and re-inserts every stop of every tour.
Two options, in order of preference:

1. Make the stop write conditional the same way (upsert on `(id)`, delete only stops whose ids
   have gone), and **add `updated_at timestamptz not null default now()`** to `public.stops`.
2. Or treat a tour as changed if any of its stops changed, and keep the cursor on `tours` only.
   Simpler, and probably enough — stops are only ever edited as part of their tour.

**Add a monotonic revision, not just a timestamp.** A `rev bigint` fed by one sequence, bumped in
the same conditional update, is strictly better than a timestamp as a cursor: it cannot go
backwards across a clock adjustment, it cannot collide within a transaction, and it makes
"everything at or below rev N" exact. `refreshed_at` stays as the cheap public freshness token the
app already uses.

**This phase is worth doing on its own merits, independent of delta fetching.** Rewriting ~3,674
rows five times a day that did not change is pure WAL, pure bloat, and pure autovacuum work on an
instance that ran out of memory last night. Making the seed touch only what moved is the cheapest
piece of relief in this document and it touches no phone.

### Phase 1 — the new RPC

**`public.get_catalog_since(client_rev bigint)`** (or `since timestamptz`), `security definer`,
granted to `anon` and `authenticated`, returning:

```
{ version, rev, tours[], linkPins[], makers[], places[], removedIds[] }
```

**Design constraints that must hold:**

- 🔴 **It must be built from the same builder as the snapshot, not a second copy of the shaping
  logic.** `backend/README.md` and `scripts/check-catalog-keys.py` exist because
  `get_catalog` has been severed from its call chain before —
  `get_catalog → get_catalog_core → get_catalog_core_base`, plus `places.sql`'s merge and
  `split_link_pins.sql`'s pin lift. A second hand-written shaper would drift from the first, and
  the drift would be invisible: new builds would quietly get a different tour shape from old ones.
  **Factor the per-row shaping into one function and have both paths call it.**
- **It must emit exactly the keys `get_catalog()` emits, for the rows it does emit.** A delta row
  missing `priceTier` is the 2026-08-19 incident restricted to whichever tours changed that day.
- **It must be cheap when the answer is "nothing".** The common call returns an empty array.
- **`removedIds` needs a source.** With the seed still upsert-only, the honest first version
  returns an empty `removedIds` and relies on the reconciliation sweep (§ 5, Option A) rather than
  pretending to track deletions. A `catalog_tombstones` table is the eventual answer and can wait.
- ⚠️ **Do not materialise a per-request delta into the snapshot table**, and do not add a trigger
  on `tours` — `catalog_snapshot.sql` warns about exactly this and the warning stands.

**`scripts/check-catalog-contract.py`** parses the Swift models and asks the live RPC what it
returns. It must be extended to ask **both** RPCs — pointing `get_catalog_since` at a known-old
cursor so it returns at least one row — or the new path ships with no contract check at all, which
is the precise gap that let `places`, `priceTier` and `isPrivate` vanish for 14 hours.

**`scripts/check-catalog-keys.py`** needs the same treatment: `REQUIRED_TOP` gains `removedIds`
for the delta shape, `REQUIRED_TOUR`/`REQUIRED_STOP`/`FORBIDDEN_STOP` apply unchanged to delta
rows, and its **SQL audit** (the one that catches a file replacing `get_catalog` wholesale) needs
the new function name added to its watch list.

⚠️ **Both scripts fetch the full catalogue to do their job.** Adding a second full fetch per run
to check the delta path would add egress to a project whose problem is egress. Point the delta
check at a **recent** cursor (a few rows), not an empty one.

### Phase 2 — the client

All of it in `RemoteCatalogLoader`, which already owns the cache, the sidecar tokens, the source
order and the three-valued `RefreshOutcome`. The shape it needs already exists:

- `CatalogSource` grows an optional delta fetcher beside its optional `versionProbe`.
- `RefreshOutcome` grows a `.merged(ToursData)` case beside `.fetched` / `.upToDate` / `.unusable`.
- The cache gains a third sidecar holding the server `rev` the cache corresponds to.
- **The merge must be pure and testable**: `(cached, delta) -> ToursData`, replacing by id,
  appending new ids, removing `removedIds`, preserving the `tours` / `linkPins` split on write.

**The safety rules, each one earned by an incident in this repo:**

1. **Any doubt → full download.** No stored rev, rev older than the server retains, HTTP error,
   undecodable body, or a delta that fails to merge → call `get_catalog()` exactly as today.
2. **Never advance the stored rev on a merge that did not complete.** Same rule as the version
   check's "stamp the token only on bytes we actually decoded".
3. **A delta that drops elements must not be cached.** `CatalogDecodeLosses` is already counted —
   for the full path a loss costs one tour, but for a merge a loss means the cached catalogue is
   now missing a row it is supposed to have. Non-zero losses on a delta should fall back to the
   full download, not merge.
4. **Reconcile on a schedule.** The id sweep (83.5 KB) weekly per phone, or whenever the merged
   count and a server-reported count disagree — which also gives us a cheap invariant to alarm on.
5. **The gh-pages mirror path is untouched.** It publishes no version and no delta; if Supabase is
   unreachable the app behaves exactly as it does today.

### What does NOT change

`backend/catalog_snapshot.sql`'s core design is right and stays: one row, refreshed once per seed,
`get_catalog()` as a lookup, `refresh_catalog_snapshot()` running the builder as `anon`.

⚠️ **A note on the outage's stated root cause.** The brief says `get_catalog()` "builds the entire
catalogue as one in-memory document on every fetch". That was true until `catalog_snapshot.sql`
was applied — since then it is a lookup, and today's 1.27 s TTFB is consistent with that (the
migration's own notes measured rebuilds at 2.2–5.0 s). What remains per request is detoasting,
serialising and gzipping an **8.0 MB jsonb value**, which is still the dominant memory cost on a
512 MB instance with several concurrent callers, and still grows 3% a day. The conclusion is
unchanged — the payload size is the problem — but the mechanism should be stated accurately, or
someone will "fix" the snapshot that is already doing its job.

---

## 7. Effort — a weekend, or a fortnight?

**Both, and the distinction matters.** The *writing* is about a weekend. The *relief* is about a
month, because it has to travel through App Review and then through people updating their apps.

| phase | what | effort | ships independently | app release |
|---|---|---|---|---|
| **0** | Conditional upserts; `stops` change signal; `rev` sequence | **half a day** | ✅ yes | no |
| **1** | `get_catalog_since` + contract/keys checks extended | **1–2 days** | ✅ yes | no |
| **2** | Client delta fetch + merge + reconciliation + tests | **2–3 days** | ✅ yes | **yes** |
| **3** | Index + detail-on-demand (Option D); bundled-seed stamping | 3–5 days | ✅ yes | yes |

**≈ 4 days of work to the point where the bill falls, ≈ 8 with Phase 3.** Add one App Review cycle
and a few weeks of install-base migration before the daily egress figure actually moves.

### Which single phase buys the most relief for the least risk

**Phase 0.** It is half a day, it touches no phone, it cannot regress the app, and it pays twice:

- It is the prerequisite without which Phases 1 and 2 return the whole catalogue anyway.
- **On its own it removes ~3,674 row rewrites × 5.2 seeds a day** from an instance that ran out of
  memory last night — less WAL, less bloat, less autovacuum, shorter seed transactions. It is the
  only item here that helps the *outage* problem before any app release exists.

If the question is "which phase buys the most **egress** relief", the answer is **Phase 2** — it
is the one that turns 2.4 MB into 7 KB — but Phase 2 is worth nothing without Phase 0, and Phase 0
is worth something without Phase 2. **Start there, this week, and decide about the rest after.**

---

## 8. What this does NOT fix — stated plainly

1. **Every phone on 1.1.1 keeps downloading 2.4 MB, forever.** They cannot be taught a new
   question. Until the install base migrates, the bill falls only in proportion to how many people
   have updated. With the catalogue growing ~3% a day, **an install base that updates slowly could
   see the absolute bill stay flat for weeks** even after this ships.
2. **The first sync of any install is still a full download** — 2.4 MB, or 1.06 MB if Phase 3
   lands. A delta needs something to be a delta *against*.
3. **Every app update pays a full download**, because the cache is deliberately discarded when the
   build number changes (§ 4.3). Phase 3's bundled-seed stamping could fix this; it is not in the
   4-day estimate.
4. **It does not make the catalogue smaller.** The full document is still 2.4 MB and still growing
   3% a day; everything above changes how often that full size is transferred, not what it is.
   Option D is the only item that attacks the size, and only by 56%.
5. **It does not fix deletions reaching Postgres.** `seed_from_toursjson.py` is still upsert-only
   for tours and pins; content removed from `Tours.json` still survives in the database and is
   still served. The reconciliation sweep stops a *client* from keeping a deleted row, which is
   not the same thing. That remains a separate job.
6. **It does not reduce audio or image egress** — those are on gh-pages and are not billed by
   Supabase. This is the PostgREST line item only, which is 100.0% of Supabase egress every day.
6b. 🔴 **A BULK MIGRATION TURNS THE NEXT DELTA INTO A FULL DOWNLOAD FOR EVERY USER — AND CHARGES
   A PREMIUM FOR IT.** Observed, not theorised, on 2026-09-15: #915's migration wrote
   `related_tour_ids` and `authored_on` onto **every tour row**, so the `rev` trigger correctly
   bumped **all 1,582 tours**. A `get_catalog_since` call from a cursor older than that migration
   then returned **2,752,051 bytes — larger than the entire `get_catalog` payload (2,427,222)**,
   because it is the whole catalogue *plus* the delta envelope.

   This is correct behaviour, not a bug: every one of those rows genuinely changed. But it has a
   consequence nothing else in this document implies — **once 1.1.3 is in the field, any
   catalogue-wide rewrite is an egress event costing more than a full fetch per user**, where
   before it cost exactly the same as any other day. Backfills that used to be free now have a
   price, so batch them, do them rarely, and prefer a migration that touches only affected rows.

   ⚠️ It also means **a cursor's age determines its cost**: a phone that has not opened the app
   since before a backfill pays full price on its next launch, however little real content
   changed. Not worth engineering around today, but it is why measuring "typical delta size" from
   one sample is misleading.
7. **It does not remove the need for the version check or the 900 s debounce.** Both stay; the
   delta composes with them rather than replacing them.
8. **It adds a new way to be silently wrong.** A merge bug leaves a phone holding a catalogue that
   is *almost* right — a tour that should have been updated, or removed, and was not. That is a
   quieter failure than a download that fails outright, and it is why the reconciliation sweep and
   the "any doubt → full download" rule are load-bearing rather than nice-to-have.

---

## Appendix A — how to re-measure all of this (one fetch)

🔴 **Never poll `get_catalog` in a loop.** Fetch once, save it, and answer every subsequent
question from the saved copy.

```bash
# Both values are the ones the app ships, in TRAVEL GUIDED TOUR/Data/SupabaseConfig.swift
# (`anonKey` and `projectURL`). The anon key is publishable and client-safe by design;
# the service_role key must never appear in a command like this.
KEY="$(grep -o 'sb_publishable_[A-Za-z0-9_]*' "TRAVEL GUIDED TOUR/Data/SupabaseConfig.swift")"
URL="$(grep -o 'https://[a-z0-9]*\.supabase\.co' "TRAVEL GUIDED TOUR/Data/SupabaseConfig.swift" | head -1)/rest/v1/rpc/get_catalog"

# ONE fetch. -H 'Accept-Encoding: gzip' (NOT --compressed) so the bytes on disk
# are the bytes that get billed.
curl -sS -X POST "$URL" \
  -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" -H "Accept-Encoding: gzip" \
  -d '{}' -o catalog.json.gz \
  -w 'http=%{http_code} wire=%{size_download} ttfb=%{time_starttransfer}s\n'
python3 -c "import gzip;open('catalog.json','wb').write(gzip.decompress(open('catalog.json.gz','rb').read()))"
```

Then, locally and for free — **at gzip level 1, because that is what PostgREST serves** (§ 1.1):

```python
import json, gzip, io
d = json.load(open("catalog.json"))

def gz(o):                       # level 1 == what is billed
    b = io.BytesIO()
    with gzip.GzipFile(fileobj=b, mode="wb", compresslevel=1, mtime=0) as f:
        f.write(json.dumps(o, separators=(",", ":"), ensure_ascii=False).encode())
    return len(b.getvalue())

base = gz(d)
c = json.loads(json.dumps(d))                       # what does field X cost?
for arr in ("tours", "linkPins"):
    for t in c[arr]:
        t.pop("longDescription", None)
print(base - gz(c), f"{100*(base-gz(c))/base:.1f}%")
```

And for the delta figures, replay the content commits:

```bash
git log --format=%h -30 -- "TRAVEL GUIDED TOUR/Resources/Tours.json"
# for each: git show <sha>^:<path> and git show <sha>:<path>, diff entries by id,
# gzip the changed set at level 1.
```

## Appendix B — where the facts in this document live

| claim | source |
|---|---|
| payload size, field shares, city sizes, delta sizes | measured 2026-09-14 13:10–13:14 UTC, method above |
| change frequency | `git log --since="30 days ago" -- Resources/Tours.json` |
| non-optional Swift fields | `TRAVEL GUIDED TOUR/Models/Tour.swift` lines 293–321 |
| element-wise tolerant decode | `TRAVEL GUIDED TOUR/Data/ToursData.swift` `init(from:)` |
| cache discarded on build change | `RemoteCatalogLoader.readCache()` / `cachedVersionMatches()` |
| three-valued refresh outcome | `RemoteCatalogLoader.RefreshOutcome` |
| `updated_at = now()` on every seed | `backend/seed_from_toursjson.py`, tours upsert tail |
| stops deleted and re-inserted per tour | `backend/seed_from_toursjson.py`, "-- stops" block |
| `stops` has no `updated_at` | `backend/schema.sql`, `create table public.stops` |
| snapshot is a lookup, not a rebuild | `backend/catalog_snapshot.sql` §§ 3–4 |
| the `kind` / `linkPins` precedent | `ToursData.swift` header; `CLAUDE.md` § Key facts |
| the 2026-08-19 silent-nil incident | `CLAUDE.md` § Automation rule 11; `scripts/check-catalog-contract.py` header |

**Perishable — re-derive, do not quote:** the App Store released version, the review state of
1.1.2 (160), the live tour/pin/maker/place counts, and every byte figure above.

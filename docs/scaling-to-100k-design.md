# Scaling pinned tours to 100,000 — industrial ingestion

---

# PART 2 — What to build NOW (owner not ready for creator outreach)

All four items below were approved. None needs a single creator to say yes. Two findings from
this session's audit **reorder the priorities** — they are live defects, not scaling concerns.

## 🔴 Finding 1: ~32 pins are already live and invisible

`TourSetMap.swift:243` sets `maxStacked = 3`, applied at L206 as `placecardTours.prefix(3)`.

**502 pins (22.9%) share an exact coordinate with another pin, across 205 groups.** Nineteen of
those groups are bigger than 3, covering 87 pins — so **at least 32 pins are silently truncated
out of the placecard stack and cannot be reached from the map at all.** The largest is a 7-pin
group at the Strahov Library in Prague.

This is content you already have, already paid for, that no user can see. It needs no network, no
creators and no App Store release to find.

## 🔴 Finding 2: the mandatory place check is currently failing

`check-place-candidates.py` on this checkout (stamp `rev 78e69c22 · 2026-09-14T18:53:28Z`):
**15 EXACT · 75 TIGHT · 42 NEAR, exit code 1.** CLAUDE.md Rule 8c makes every EXACT group an
owner decision, and 15 are outstanding.

Also offline and actionable now: **34 pins at ≤3 dp** (~110 m — neighbourhood centroid, not a
building); **~44 pins across 13 cities where every pin shares one coordinate** (Windsor 6 pins/1
coordinate, Denver, Little Rock — unambiguous centroid dumps); **197 pins carrying the
known-unrepaired +20 m northward pipeline bias**; and **30 Japan pins already itemised in PR #893**
as owing a precision pass.

---

## The order of work

### 1. Backend Phase 0 — conditional seed writes · half a day · no app release

Fully specified in `docs/delta-catalog-fetch-design.md:438-468`, traps included. **Confirmed not
started**: unconditional `updated_at = now()` at `backend/seed_from_toursjson.py:160, 192, 234`;
no `rev` column anywhere in `backend/*.sql`; `stops` has no `updated_at` (only `makers`
`schema.sql:61` and `tours` `schema.sql:95` do).

- Add `where <table> is distinct from excluded` to the `on conflict do update` clauses for
  `tours`, `makers`, `places`.
- ⚠️ **Compare only the column list the upsert actually writes** — `place_id` is cleared and
  re-set by a separate statement and `published_at` is `now()` on insert, so a whole-row compare
  makes every seed still look like a change.
- Give `stops` a change signal — preferred: upsert on `(id)`, delete only vanished ids, add
  `updated_at`. (The doc's simpler option 2 — treat a tour as changed if any stop changed — is
  acceptable.)
- Add a monotonic `rev bigint` from one sequence. `refreshed_at` stays as the public token.

🔴 **The design doc understates its own payoff by ~4×, and its preference order is wrong.**
Measured this session by generating the seed (`seed.sql` = **18,556,620 bytes, 12,645 statements**,
applied to production in **one transaction ~5.2×/day**):

| statement | row versions per seed |
|---|---:|
| makers · places · tours upserts | 4,472 |
| `place_id` reset + 303 membership updates | 1,470 |
| **stop deletes + inserts** | **8,234** |
| **total** | **≈ 14,176 — about 73,700 a day, essentially all no-ops** |

The doc counts only the 3,745 tour upserts. **The stops delete-and-reinsert is the single biggest
win at 8,234 writes, and the doc's *preferred* option 3b — keep the cursor on `tours` only — does
not fix it at all.** If the goal is instance relief today rather than a delta cursor, do stops.

⚠️ **The one genuine hazard:** `stops` has `unique (tour_id, "order")` (`schema.sql:116`). Deleting
everything first makes reordering trivially safe; a conditional upsert that renumbers two stops in
one tour hits a unique violation mid-statement unless the constraint is made `deferrable initially
deferred`. This is the part that is not a half-day edit.

**Use row comparison, not a content hash.** A hash column is cheaper on the wire (~80 bytes vs
~1,400 per statement) but it can drift silently — add a column to the INSERT list, forget the hash
input, and that field stops reaching Postgres forever. In a repo whose scar tissue is exactly "a
field silently vanished" (2026-08-19), the row comparison cannot drift, because the `where` clause
and the `set` clause are the same column list. The extra ~5 MB of generated SQL costs nothing —
`backend/seed.sql` is built in CI and never committed.

**Bonus, ~1 hour, worth bundling:** move the snapshot refresh *outside* the seed transaction
(`seed_from_toursjson.py:310-321`). Today it rebuilds an 8.0 MB jsonb inside a transaction already
holding 14,176 row writes open — that is the peak-memory window.

**Realistic effort: 1–1.5 days**, not the doc's half day. The first two rows of the table above are
genuinely half a day and deliver ~40% of the write reduction.

**Why first:** it is the only item that helps the *outage* before any app release exists. ⚠️ Worth
knowing: the 2026-09-14 outage was resolved by a **free** instance bump (t4g.nano → micro, 512 MB →
1 GB, TTFB 2.3 s → 0.51 s). **No code fix landed.** Both root causes are still unbuilt.

⚠️ **One number nobody has measured**: what `refresh_catalog_snapshot()` costs *now* — the 2.2–5.0 s
figure predates both the hardware change and today's entry count. One
`select public.refresh_catalog_snapshot();` settles it and it is the cheapest missing fact here.

### 2. Per-pin fields in `make-link-pin.py` · small · scripts/ auto-merges

Confirmed at `scripts/make-link-pin.py:1117-1118`: `slug=a.slug if len(rows) == 1 else None`,
`title=a.title if len(rows) == 1 else None`. `category`, `tags` and `focus` are batch-wide.

- Extend `parse_batch` (L1021) beyond `url | lat,lon | city | country` to carry `title`, `slug`,
  `category`, `tags`, `focus` per line — a `key=value` tail is cleaner than more positional pipes,
  and stays backwards compatible with every existing batch file.
- Thread per-row values through the loop at L1111-1120.
- **Add a hero-filename collision guard**: refuse (or disambiguate) when two rows in one batch
  derive the same hero path. Two captions both opening `"Comment 'SUSHI' below…"` once silently
  overwrote each other's image, and fixing it needed two fields patched per entry.
- Extend `--selftest` to cover all of it.

**Why:** a 38-pin batch has had to run as **25 grouped invocations**. This is friction on the work
being done by hand today, and it ships with no owner review gate and no app release.

### 3. The invisible-pin repair · offline · reaches phones over the air

Driven by Finding 1. For each group over `maxStacked = 3`: either create a place (which collapses
members to one capsule) or separate the coordinates where the pins are genuinely different
subjects. **Blocked on `status/owner/auto-created-places.md`** for the auto-create half — but the
19 groups can be triaged and put to the owner as a single batch decision now, exactly as the
`@japanbyfood` affiliate network was escalated as one policy call rather than 70.

Same pass clears the 15 outstanding EXACT groups and the 13 single-coordinate cities.

### 4. The place spine · weeks · no creators needed

As designed in Part 1 § A1 — but note it pays off **before** any creator work:

- Today's paste-links workflow stops needing four hand-typed fields per pin.
- It gives `check-coordinates.py` something to audit pins *against* without Nominatim.
- ⚠️ **A network audit is not the cheap route.** 2,193 pins at `SLEEP = 1.1` s and ≥2 calls per
  point is **2–3 hours of wall clock**, and `names_resemble` (L145) has a Milan-specific stop-word
  set that will dump creator-caption titles into UNVERIFIABLE. A spine join is offline and exact.
- `--pins` mode still needs writing: `from_catalog` (L255) reads `d["tours"]` only and matches
  `displayName == "Atlas Studio XXX"`, so **no pin can ever match it**. Needs a `from_pins`, a
  per-city `region_viewbox` (L273), and a pin-aware name gate.

### 5. App performance · needs an App Store release + owner simulator review

Lowest priority only because it is slowest to reach users, not least valuable. Precedent: a prior
PR indexed `DataService`'s by-id lookups — "linear scans over 1,418 tours read per row on every
body evaluation" — and it was recorded as "an app-wide win, not only Library."

Targets: `SearchView.swift:745` (full lowercased index rebuild on the main thread; the
`count != count` guard also misses a refresh that changes content but not count — a real
correctness bug), `SearchView.swift:650` (full scan per keystroke), `MapClustering.swift` +
`HomeMapSection.swift:264` (O(N) cull and bucket per render; cull disabled above 30° span;
`precomputedMarkers` nil whenever a filter is active), `DataService.swift:275` (`toursNearby`
sorts with `distance(from:)` in the comparator).

---

## Verification

- **1** — prove a content merge now changes `updated_at` on only the rows that actually changed;
  confirm the snapshot still rebuilds; `check-catalog-contract.py` after the migration, not before.
- **2** — `make-link-pin.py --selftest` must read **71/71** (62/62 means Pillow is missing and is
  not a pass); re-run an existing batch file unchanged to prove backwards compatibility.
- **3** — `check-place-candidates.py` EXACT count must fall from 15; re-run the
  over-`maxStacked` sweep and confirm zero groups above 3.
- **5** — `test_sim` locally, or `ci.yml` on the PR from a web session; owner reviews on device.
- Everywhere: read the **run stamp and the counts**, never the verdict line.

---

## 0. In plain English — for the owner

### Why it's slow now

It isn't the software. The software is good. The bottleneck is that **every pin needs a human
to look up where it is.**

You find the videos yourself and paste them in. Then, for each one, somebody has to work out the
exact spot on the map, type in the latitude and longitude, the city, the country, and what kind of
place it is. Four things, typed by hand, for every single pin. Nothing else in the pipeline is
manual — the pictures, the IDs, the creator profiles, the checks, all of that runs itself.

At 2,193 pins that's fine. At 100,000 it's about **3,300 hours of typing and looking things up.**

### Why you can't just "search harder" for more videos

This is worth knowing because it rules out the obvious answer.

You cannot scan the platforms for content. We measured it:

- **Instagram gives you nothing at all.** There is no way to list someone's posts. The door was
  closed in December 2024 and it isn't reopening. Instagram is your biggest platform.
- **TikTok gives you 14 posts per creator.** That's it. The rest of their account is behind a
  security wall.
- **YouTube gives you about 15.**

So "build a crawler" is not on the table. That's not a budget problem, it's a locked door.

### The unlock: ask the creators to let you in

Here's the thing that changes everything. **Those limits only apply to strangers.** If a creator
logs in and gives you permission, TikTok and Instagram will hand over their *entire* back
catalogue — hundreds of posts — legally and for free.

And your own numbers say this is exactly the right shape. Look at where your pins actually come
from:

- 279 of your 390 creators have contributed **one pin each**.
- Your top 10 creators have contributed **1,258 pins — 57% of everything you have.**
- Your best single creator, `@urbanistariel`, has **326 pins on their own.**

**Depth beats breadth, and it isn't close.** About **350 creators at that depth gets you to
100,000.** You already have 386 creators to go and ask.

It also solves a problem you keep hitting: when a creator says yes properly, you have their
permission on record, and the "this reel won't play because of the music licence" problem largely
goes away.

### The second unlock: a ready-made list of every landmark on Earth

Right now, when a video comes in, someone has to figure out where it was filmed and find the
coordinates. That's slow, and it's the step that goes wrong most often — your notes record ten
Barcelona pins all placed in the wrong spot, a Milan abbey dropped on a motorway, and a measurable
tendency for pins to land slightly *north* of where they should be.

There's a free, public, open database — OpenStreetMap — that already contains every museum,
church, bridge, park, monument and landmark in the world, each with its exact position.

So we **download it once and turn the problem around.** Instead of *"here's a video, where on
earth is it?"* it becomes *"here's a known place — which videos are about it?"*

That one change gives you, for free, for every pin:

- **The coordinate, exactly right.** Not looked up, not guessed — copied from the official record.
  The whole category of wrong-location bugs stops being possible.
- **The city and country**, automatically.
- **The category and tags**, from what the database already knows the building is.
- **Grouping.** Three videos about the same cathedral are recognised as the same cathedral
  automatically, because they point at the same entry.

That last one matters for your decision to have several creators per place.

### How quality gets protected when nobody reads every one

Every candidate video gets asked **two separate questions** (never one combined question — your
own notes record that asking both at once makes it quietly answer only the first, which is how a
batch of 19th-century engravings once shipped as "photos"):

1. *Is this one specific, real place a person could go and stand at?* — this throws out tutorials,
   "top 10" roundups, ferry routes, adverts, announcements.
2. *Is the place in this video actually the place we think it is?* — and critically, we tell it
   what the lookalikes are. That's what catches the wrong column in Rome, or the wrong branch of
   the right library.

Then three outcomes:

- **Clearly good** → goes through.
- **Not sure** → goes in a queue for you.
- **Clearly not** → rejected.

**You only ever look at the "not sure" pile.** One screen, one keystroke — picture, caption, map,
place. About 3 seconds each.

| | your time for 98,000 pins |
|---|---|
| today, reading every one | **~3,300 hours** |
| this way | **~16 hours** |

**And nothing is ever thrown away.** Every rejection is kept, with the reason. This is the single
most important safety rule in the whole plan, and it comes straight out of your own notes: a *bad*
pin you'd spot on the map, but a *good* post wrongly binned disappears and nobody ever knows it
was considered. Keeping every rejection means when the checker improves, you re-run it over
everything it turned down.

On top of that, we spot-check 2 out of every 100 that went through automatically. If too many are
wrong, the whole batch stops and waits for a human.

### The part you won't like: the app cannot survive 100,000 pins

This is not a "it'll get a bit slow" problem. There are three places where it simply stops working,
and you should know about them before spending a penny on content.

**1. The app would crash on opening.** Today, the app downloads the whole catalogue and holds all
of it in the phone's memory at once, before it draws a single thing on screen. At 100,000 that's
over a gigabyte. The phone kills the app. Not slow — dead, every time, on launch.

**2. The download becomes enormous.** Every time anything changes, every phone re-downloads
*everything*. At 100,000 that's about **60 MB per go**. Your monthly allowance would cover about
**83 downloads in total, across all users.** You already got billed twice for this at the current
size, and the backend was down for nearly twelve hours on 14 September because of it.

**3. The database can't build it.** The catalogue is assembled into one giant record. At 100,000
that record is roughly 320 MB. The server already ran out of memory doing this at 8 MB.

**The fix is the one every map app already uses: stop sending the whole world to the phone.** The
app should ask "what's near me?" and "what did I save?" — never "give me everything." That's a
real piece of engineering work and it's the long pole in this plan.

### So the plan is two things at once

**Track 1 — build the collection machine.** The creator sign-in page, the landmark database, the
automatic checking, your review screen. Everything it produces goes into a **holding area the app
cannot see.** Content piles up safely while nothing is at risk.

**Track 2 — rebuild the app's plumbing** so it only fetches what's nearby.

Then you **turn it on region by region** as each one is checked. Nothing goes live until it's safe.

### Two honest warnings

1. **TikTok and Instagram both have to approve your app** before they'll let creators grant you
   access. That's an application to them, and it takes weeks. **It should be started on day one**,
   before we write the code that depends on it — because if either says no, that platform falls
   back to hand-submitted links and the plan changes shape.
2. **The real bottleneck becomes recruitment, not software.** You need roughly 350 creators to say
   yes. That's outreach, relationships and a pitch — a people job, not a coding job. The machine
   can be finished and sitting idle if nobody's signing up.

### One thing that needs your decision

Having 3–4 creators on the same landmark means those videos have to be **grouped into a single
place page** — otherwise they stack on one dot on the map, and **the map only shows three before
the fourth becomes permanently invisible.**

Grouping is what your "places" feature already does. But the rule today is that **a human approves
every single place by hand.** At 25,000 places that can't hold. The landmark database makes
grouping automatic and reliable — but **changing that rule is your call, not mine**, and it needs
saying out loud before any of this ships.

---

## Context

The catalogue holds **2,193 link pins**. The goal is **100,000**, quality-vetted and relevant.
Today the entire sourcing pipeline is: the owner pastes links into chat. Every batch since at
least 2026-09-05 began that way (`archive/HANDOFF-260914-4.md:7` — *"Owner pasted 86 links with
no context beyond 'a couple of creators'"*). `docs/link-pin-runbook.md:17` states the boundary
outright: *"Everything below assumes a list of links somebody has already decided are worth
pinning."*

Three things make that un-scalable, and they are different problems:

1. **No discovery exists**, and "crawl harder" is not available. Measured in this repo
   (`docs/lessons.md:1087-1112`): Instagram enumeration is **impossible** (profile 302s to login,
   Basic Display died Dec 2024) and Instagram is the largest platform by creator count; TikTok
   caps at **14 posts per handle**; YouTube RSS at **~15**.
2. **Four human-typed fields gate every batch** — `lat,lon`, `city`, `country`,
   `category`/`tags`. `make-link-pin.py` has no geocoder at all (`grep -c "nominatim\|geocod"` →
   **0**). Everything else in the pipeline is already automated and well-harnessed.
3. **100,000 entries breaks the product in three fatal places**, not gradually.

This plan builds an ingestion engine and, in parallel, the architecture that can serve what it
produces. Both are required; neither alone gets there.

### Decisions taken (owner, this session)

| | |
|---|---|
| **Supply** | Creator OAuth portal — creators authorise, we read their full back catalogue |
| **Shape** | Densify: ~25–30k places × 3–4 creators each |
| **Sequencing** | Parallel — ingest into an unserved staging table while the architecture lands |

---

## Measured starting point (2026-09-14, this checkout — re-derive, never quote)

| | |
|---|---|
| link pins · tours · makers · places | 2,193 · 1,552 · 424 · 303 |
| distinct pin subjects | 2,131 of 2,193 — **1.03 pins per subject** |
| platform split | TikTok 1,253 · Instagram 921 · **YouTube 19 (0.9%)** |
| creator concentration | **279 of 390 creators have exactly 1 pin; the top 10 hold 1,258 — 57%** |
| deepest creators | `@urbanistariel` 326 · `@hereinnyc` 262 · `@archimarathon` 182 |
| `Tours.json` | 13.68 MB raw / 3.67 MB gzip-1 |
| cost per entry on the wire | **~603 bytes gzip-1** (3,745 entries → 2,258,643 B) |

**The concentration figure is the whole strategy.** Depth per creator is the proven pattern; the
14-post ceiling is the only thing preventing it, and OAuth removes that ceiling entirely.

---

## Track A — the ingestion engine (start now; writes only to staging)

### A1. The place spine — the single highest-leverage artefact

A local gazetteer built from **OpenStreetMap** (Geofabrik per-country PBF) or **Overture Maps
Places**, filtered to visit-worthy features (`tourism=*`, `historic=*`, `amenity=place_of_worship|
theatre|arts_centre`, `building=cathedral|castle`, `man_made=lighthouse|bridge|tower`,
`leisure=park|garden`, `natural=peak|waterfall`, anything carrying `heritage=*` or `wikidata=*`),
ranked by notability (Wikidata sitelinks + Wikipedia pageviews + tag richness).

Target ~30,000 ranked subjects, seeded across the 542 cities already in the catalogue.

```sql
place_spine(spine_id, osm_type, osm_id, wikidata_id, name, name_local,
            lat, lon, city, country, admin_hierarchy jsonb,
            osm_tags jsonb, notability_score, geom)
```

**This converts all four human-typed fields into a join:**

| Field | Today | With the spine |
|---|---|---|
| `lat,lon` | typed by hand; **systematic northward bias, 208/262 matches north, p = 1.7e-22** (`docs/lessons.md:1311`) | exact, from the OSM node — the bias class disappears *by construction* |
| `city`, `country` | typed per line | admin hierarchy lookup, no geocoding |
| `primaryCategory`, `tags` | one value for the whole batch (`--category`/`--tags` are invocation-wide) | per-pin, from a one-time OSM-tag → taxonomy mapping |
| place identity | hand-approved, one at a time | **same OSM feature = same place**, automatic |

That last row is what makes the densify decision safe. `check-place-candidates.py`'s EXACT groups
stop being a thing you discover after the fact.

⚠️ Densifying has one hard app constraint: **`TourSetMap.maxStacked = 3`**. A fourth pin on an
identical coordinate is permanently invisible. Members of a spine place must collapse to one place
capsule, which is exactly what `places` already does — but `Place.swift` says places *"must be
approved by a human, never auto-created."* **Auto-creation from a spine id is a rule change and
needs the owner's explicit sign-off before any of it ships** (§ Open questions).

### A2. The creator OAuth portal

A small web surface added to `site/` (already Vercel-deployed from `main`).

- **TikTok** — Login Kit + Display API `video.list` scope → the creator's full video list.
- **Instagram** — Instagram API with Instagram Login, `/me/media` → full media list.
- **YouTube** — channel ID → Data API `playlistItems` on the uploads playlist (1 quota unit per
  50 items; the whole back catalogue is cheap). No OAuth strictly needed.

```sql
creator_connection(maker_id, platform, external_id, token_enc, refresh_enc, scopes, connected_at)
candidate(id, maker_id, platform, source_url, caption, thumbnail_url, posted_at,
          raw jsonb, spine_id, scores jsonb, state, reason, created_at)
```

🔴 **TikTok and Instagram both require platform app review before these scopes are granted.** That
is a real external dependency with a multi-week lead time and it should be started on day one,
before any of the code that depends on it.

Reaching 100k this way needs roughly **350 connected creators at `@urbanistariel` depth**. You
already have 386 pinned creators to approach, and consent at connect time also fixes the
rights-withheld problem (4 of 20 IG reels in one batch could not play inline).

### A3. Candidate → pin resolution

Per candidate, in order:

1. **Place match** — caption + on-frame text + any platform geotag against `place_spine`, scoped
   to the creator's usual geography. Combine pgvector similarity (reuse
   `scripts/build-embeddings.py`, already proven offline with all-MiniLM-L6-v2) with trigram name
   match. Emit ranked spine candidates + confidence.
2. **Two independent vision gates — never one compound prompt.** This is the repo's own mandated
   pattern and it was paid for: a single combined question is answered on subject match only and
   silently drops the rest, which shipped 19th-century Rijksmuseum prints as "photos".
   - **Gate A** — is this one specific, physically visitable place? Rejects MULTI posts, routes,
     tutorials, hauls, announcements, property listings.
   - **Gate B** — is the place in this frame *this* spine candidate? **With look-alikes named from
     the spine** (sibling branches, same-name features nearby). Naming distractors is what caught
     the Column of Marcus Aurelius posing as Trajan's Column, and Banning branch vs Huntington
     Beach *Central* Library.
3. **Category + tags** — from spine OSM tags + caption, against the closed vocabulary. Reuse the
   proposal shape of `scripts/seed_tags.py`; note it currently operates on `d["tours"]` **only and
   never touches `linkPins`**, so pins need it extended.
4. **Title** — authored from **hero frame *and* caption together**, never caption alone. The
   "Headless Horseman" pin was authored wrong from the caption and only corrected once someone
   opened the hero.
5. Hero crop, uuid5 ids, maker row — **already automated in `make-link-pin.py`, unchanged.**

### A4. Three-band gate, and the never-discard rule

`auto_accept` (both gates pass, place confidence over threshold, not a duplicate) ·
`review` (middle band) · `auto_reject`.

🔴 **Nothing is ever discarded.** Every rejection writes a row with its reason and scores. This is
the direct answer to the sharpest warning in `docs/lessons.md:1076`:

> *"Over-accepting is the safer setting only because a human reads every candidate before anything
> is minted… The over-rejection is the dangerous half, because it is invisible."*

A rejected candidate stays queryable and re-runnable when the classifier improves. That is the
replacement for the human read — not a better filter, but a filter whose mistakes leave a trace.

**Sampled audit**: 2% of every auto-accepted batch goes to a human; the batch quarantines if the
error rate exceeds threshold. This is what keeps quality honest without reading all 100,000.

### A5. The review queue

A single-keystroke review surface — hero, caption, map, resolved place — accept / reject /
re-pick place. Publish as an Artifact (it is a tool the owner uses repeatedly, not a document).

**The throughput case, which is the whole point:**

| | per item | 98,000 pins |
|---|---|---|
| today (read every candidate) | ~2 min | ~3,300 hours |
| 20% review band at 3 s | — | **~16 hours total** |

### A6. Staging, not serving

Everything above writes `status='staged'`. `get_catalog_core_base` filters `status='published'`.
Nothing reaches a phone until Track B lands. This is what makes the parallel sequencing safe.

---

## Track B — the architecture that can serve 100,000

Three walls are **fatal**, not gradual. All figures measured this session.

| # | Wall | Where |
|---|---|---|
| 1 | **App OOM on launch.** `DataService.init` decodes synchronously; `decodeTolerantArray` holds `[Tolerated<Tour>]` *and* `[Tour]` simultaneously; then 6 derived indexes; then SearchView allocates a full lowercased copy of every description. **>1 GB resident, inside `init`, before first frame.** | `Data/DataService.swift:100-118`, `Data/ToursData.swift:110-131`, `Features/Search/SearchView.swift:745` |
| 2 | **~60 MB gzipped per full fetch** = **83 fetches per month** against the 5 GB quota, across all users and scripts. | `docs/delta-catalog-fetch-design.md` |
| 3 | **~320 MB jsonb in one snapshot row**, detoasted and serialised per request. The instance already OOM'd for ~11h45m on 2026-09-14 at an 8 MB payload. | `backend/catalog_snapshot.sql` |

Severe but survivable: a 740 MB / ~600k-statement single-transaction seed run 5.2×/day; a
370–550 MB `Tours.json` in the app bundle; O(N) main-thread map culling per render; full-catalogue
search scan per keystroke.

### B0. Indexes — nothing else works without these

There is currently **no index on `updated_at`, `city`, `country`, `tags`, or the coordinates, and
no PostGIS** (`backend/schema.sql:122-125` is the complete list). Every scoped query would be a
seq scan of a ~450 MB table. Add them first: btree on `updated_at`/`city`/`country`, GIN on
`tags`, and a geo index (PostGIS, or an H3/geohash column with a btree if you'd rather not add the
extension).

### B1. Phase 0 of the delta design — make `updated_at` mean something

`seed_from_toursjson.py` writes `updated_at = now()` unconditionally on every row, 5.2×/day, and
`stops` has no `updated_at` column at all. Until that is fixed, no changed-since cursor can exist.
**Half a day, touches no phone, cannot regress the app** — the delta doc's own assessment, and the
prerequisite for everything else.

### B2. Server-side map, search and rails — the long pole

`docs/delta-catalog-fetch-design.md` rejects region scoping as *"a product change wearing a
transport change's clothes"* — and **it is right, at today's size.** At 100,000 it stops being
optional, because no whole-catalogue variant survives:

| shape | measured at 3,745 entries | extrapolated to 101,552 |
|---|---:|---:|
| full payload | 2,427,222 B | **~66 MB** |
| Option D index (no `longDescription`/captions) | 1,062,795 B | **~29 MB** |
| leanest measured index (also no stops/galleries) | 746,200 B | **~20 MB** |

A 20 MB first sync is 250 installs before the monthly quota is gone. So:

- **Map** — viewport bbox RPC, clustered server-side at low zoom. (The client's grid clustering
  already bounds *annotation count* to ~3,600 and should not be touched; what doesn't scale is the
  O(N) cull and bucket that runs on every render, and the cull being **disabled above 30° span**.)
- **Search** — Postgres FTS + `pg_trgm`, and pgvector for semantic search (reusing A3's embeddings).
- **Rails** — server-curated, small payloads.
- **Client holds** — library, downloads, recently viewed, and a viewport working set. Delta
  (Option A) then applies to that much smaller held set.

### B3. Seed rewrite

Content-hash-conditional upserts (skip unchanged rows), `COPY` into a temp table then merge, stops
touched only when changed, snapshot refresh moved outside the transaction. Also closes the
**upsert-only deletion gap** — content deleted from `Tours.json` currently survives in Postgres
forever and keeps being served.

### B4. Snapshot

Partition by region/tile, or retire the whole-catalogue snapshot once B2 lands — server-side
scoped queries do not need it.

### B5. Bundle

`Tours.json` stops being the source of truth for pins; it keeps the 1,552 narrated tours. The
bundled offline seed becomes a capped sample (top-N by notability) or is dropped.

---

## Order of work

1. **Day one, in parallel:** start TikTok/Instagram platform app review (external lead time), and
   build **A1 (place spine)** + **B0/B1 (indexes, real `updated_at`)**. None of these touch a phone.
2. **A2–A5** — portal, resolution, gates, review queue. Content banks into staging.
3. **B2** — server-side map/search/rails. An app release; the long pole.
4. Flip regions from `staged` to `published` as each is verified.

---

## Critical files

| Path | Change |
|---|---|
| `scripts/make-link-pin.py` | accept a `spine_id` per row; make `--title`/`--slug`/`--focus` **per-pin** (all three currently collapse to a batch-wide value or are silently dropped in batch mode, lines 1117–1118) |
| `scripts/merge-link-pins.py` | unchanged contract; keep all four refusal gates |
| `scripts/seed_tags.py`, `apply_tags.py` | extend to `linkPins` — they operate on `d["tours"]` only today |
| `scripts/check-coordinates.py` | **add a `--pins` mode** — link-pin coordinates are never machine-audited today; use it to prove the spine removed the northward bias |
| `scripts/build-embeddings.py` | reuse for A3 place matching; note the model-checkpoint trap it documents |
| `backend/schema.sql`, `catalog_snapshot.sql`, `split_link_pins.sql` | B0/B2/B4 |
| `backend/seed_from_toursjson.py` | B3 |
| `Data/DataService.swift`, `ToursData.swift`, `Features/Search/SearchView.swift`, `Components/MapClustering.swift` | B2 — owner-OK gate, simulator/TestFlight review |
| `site/` | A2 portal |
| new `scripts/spine-*.py`, `backend/place_spine.sql`, `backend/candidates.sql` | A1–A4 |

🔴 `scripts/validate-tours.swift` mirrors the Swift models — any model change edits both in the
same commit.

---

## Verification

- **A1** — `check-coordinates.py --pins` against spine-derived coordinates: the BIAS line must show
  the northward offset gone, not merely a clean GROSS list. That is the documented reading rule.
- **A3/A4** — held-out set of ~200 already-shipped pins: the pipeline must reproduce their place,
  city, country and category. Measure precision *and* recall against the known-good answer, since
  the silent-rejection direction is the dangerous one.
- **A4** — sampled-audit error rate reported per batch, with a quarantine threshold.
- **A5** — measure real seconds per review item against the 3 s assumption before trusting the
  16-hour figure.
- **Places** — `check-place-candidates.py` should trend to ~zero EXACT groups once identity comes
  from the spine.
- **Per batch, unchanged:** `validate-tours.swift` (or the mirror off-Mac),
  `check-image-duplicates.py --pins`, `check-place-candidates.py`. Read the **counts and the run
  stamp**, never the verdict line — a checker that fetched nothing still prints OK.
- **B1** — prove a content merge changes `updated_at` on only the rows that actually changed.
- **B2** — instrument peak RSS on launch at 10k / 50k / 100k staged entries before shipping.
- **CI** — PR runs `ci.yml` (the web-session stand-in for `test_sim`); app-code changes need owner
  simulator/TestFlight review before merge.

---

## Open questions for the owner

1. **Auto-created places.** Densifying requires it. `Place.swift` currently says places *"must be
   approved by a human, never auto-created."* Changing that is a rule change, and
   `docs/places.md` leaves part-vs-whole explicitly undecided. Needs sign-off before A1 ships.
2. **Creator recruitment is the real rate limiter.** ~350 creators at depth. Who does the outreach?
3. **Platform app review** (TikTok, Instagram) is an external dependency of unknown length. If
   either is refused, that platform falls back to contributor-submitted links and the YouTube
   Data API becomes proportionally more important.

# The place spine — turning four hand-typed fields into a join

**Status: `scripts/spine-build.py` IS BUILT and measured against production data. The rest is
spec.** The measurements in § 2a changed the design materially — read them before building more. Written 2026-09-15 for the owner's decision to build
this before approaching content creators. Every figure below was re-derived on `main` @ `ec734bf`,
not quoted from an earlier audit — see § 7 for why that distinction matters here.

---

## 0. In plain English

When a creator's video comes in, somebody has to work out **where on earth it was filmed** and type
in four things: the latitude and longitude, the city, the country, and what kind of place it is.
Everything else in the pipeline already runs itself — the pictures, the IDs, the creator profiles,
the checks.

At today's 2,318 pins that is tedious. At 100,000 it is roughly **3,300 hours of looking things up
and typing.** And it is the step that goes wrong most often: this project's own record has ten
Barcelona pins placed in the wrong spot, a Milan abbey dropped on a motorway, 85 Tokyo pins moved
onto their real addresses in a single day, and a measured tendency for pins to land slightly
**north** of where they should be.

There is a free, public database — **OpenStreetMap** — that already contains every museum, church,
bridge, park, monument and landmark on Earth, each with its exact position. So download it once and
**turn the problem around**: instead of *"here is a video, where is it?"* it becomes *"here is a
known place — which videos are about it?"*

That one change gives you, for free, for every pin: the coordinate **copied from the official
record** rather than guessed; the city and country automatically; the category and tags from what
the database already knows the building is; and — the part that matters most for having several
creators per place — **grouping**, because three videos about the same cathedral point at the same
entry.

**It needs no creators to say yes, and no App Store release.** That is why it is the right thing to
build while outreach waits.

---

## 1. The problem, measured

`scripts/make-link-pin.py` has **no geocoder at all** (`grep -c "nominatim\|geocod"` → 0). Every
coordinate arrives typed by a human. Three fields are worse than typed — they are
**invocation-wide**, so one batch cannot carry two categories:

```
scripts/make-link-pin.py:1117   slug=a.slug  if len(rows) == 1 else None,
scripts/make-link-pin.py:1118   title=a.title if len(rows) == 1 else None,
```

`--category`, `--tags` and `--focus` are batch-wide for the same reason. A 38-pin batch has had to
run as **25 grouped invocations**.

🔴 **And link-pin coordinates are machine-audited by nothing.** `scripts/check-coordinates.py`
exists and works — for studio tours only. Verified today:

```
check-coordinates.py:255   def from_catalog(maker_code, catalog):
check-coordinates.py:258       want = f"Atlas Studio {maker_code.upper()}"
check-coordinates.py:263       for t in d["tours"]:
```

It reads `d["tours"]`, which **does not contain pins** (they are a sibling `linkPins` array), and
matches a maker named `Atlas Studio XXX`, which no pinned creator is. **No pin can ever match it.**
So the 2,318 pins have never been audited as a set — every correction so far has been found by the
owner on the map, or by a session reading entries one at a time.

⚠️ Auditing them the existing way is not cheap: `SLEEP = 1.1` s and ≥2 Nominatim calls per point is
**2–3 hours of wall clock** for 2,318 pins, and `names_resemble` carries a Milan-specific stop-word
set that would dump creator-caption titles into UNVERIFIABLE. **A spine join is offline and exact.**

---

## 2. What the spine is

A local gazetteer, built once, of visit-worthy real-world features.

```sql
create table public.place_spine (
    spine_id      text primary key,        -- 'osm:node/123456789'
    osm_type      text not null,           -- node | way | relation
    osm_id        bigint not null,
    wikidata_id   text,
    name          text not null,
    name_local    text,                    -- the native-script name, where OSM has one
    lat           double precision not null,
    lon           double precision not null,
    city          text,
    country       text,
    admin         jsonb,                   -- the full admin hierarchy
    osm_tags      jsonb,                   -- kept whole; the taxonomy mapping reads it
    notability    double precision         -- for ranking, not for filtering
);
```

**Source:** Geofabrik per-country `.osm.pbf` extracts (free, no key, no rate limit), or Overture
Maps Places if a single global file is preferred. Filter to features carrying any of:
`tourism=*`, `historic=*`, `amenity=place_of_worship|theatre|arts_centre|museum`,
`building=cathedral|castle`, `man_made=lighthouse|bridge|tower`, `leisure=park|garden`,
`natural=peak|waterfall`, or anything with `heritage=*` or `wikidata=*`.

**Rank** by Wikidata sitelink count + Wikipedia pageviews + tag richness. Ranking decides what to
*offer first*, never what to exclude — a thing that is unranked is not a thing that is not there.

**Scope:** seed across the **580 city/country pairs already in the catalogue** (re-derived today).
The distribution is heavily concentrated, which makes a staged build sensible:

| city | entries |
|---|---:|
| New York | 536 |
| Hong Kong | 280 |
| London | 222 |
| Tokyo | 203 |
| Toronto | 101 |

**The first five cities cover 1,342 of 3,900 entries.** Build those, prove the join, then widen.

---

## 2a. 🔴 MEASURED 2026-09-15 — three findings that change the design

`scripts/spine-build.py` is built, `--selftest` is 13/13, and it harvested **1,204 distinct
features from an 8 km square of Tokyo with zero tile failures**. Then it was validated against the
60 catalogue pins inside that square. The results are not what this document assumed.

### (a) The data source had to change: OSM is unreachable, Wikidata is not

| source | result |
|---|---|
| `download.geofabrik.de` (`.osm.pbf`) | **http=000 — blocked by the egress proxy** |
| `overpass-api.de` | **no response — blocked** (also recorded by #913) |
| `query.wikidata.org` | **http=200** ✅ |

So the spine is built from the Wikidata Query Service. A local OSM extract is still the better
long-run source for *precision*; Wikidata is the one that is **reachable**, which is a different
claim and the operative one.

### (b) Admin containment undercounts by 49x — use the radius service

The natural query is "things whose `P131*` chain reaches this city". Measured, same nine types,
same day:

| city | `wdt:P131*` containment | `wikibase:around` 15 km |
|---|---:|---:|
| **London** | **557** | **27,295** |
| New York | 6,093 | 7,294 |

Cities model their hierarchies differently, so containment returns a plausible-looking number that
is mostly wrong. **A spine built that way would have left London near-empty and nothing downstream
would have flagged it** — pins would simply have failed to match, looking like thin coverage.
`spine-build.py`'s selftest asserts `P131*` is absent from the query for this reason.

⚠️ Also: WDQS enforces a **60 s** timeout and a 15 km radius over a dense city exceeds it. The
script walks overlapping tiles and unions them; a failed tile makes it print **COULD NOT VERIFY**
and exit 2, because a silently empty tile is precisely this project's recurring failure shape.

### (c) 🔴 THE BIG ONE: the spine fits landmark pins and does NOT fit food/retail pins

Against the 60 Tokyo pins in the harvested square:

| | pins | |
|---|---:|---|
| a spine feature within 150 m | **48 (80%)** | looks encouraging |
| …**and the names agree** | **20 (33%)** | **usable matches** |
| near something, names disagree | **28 (47%)** | **proximity alone would MIS-MATCH these** |

**Proximity is not a match.** The clearest case: *"Sou Fujimoto's Nishisando Toilet"* sits **19 m**
from *Shōshun-ji Temple* — a very close, completely wrong subject. Others: *Cream or Cruller* →
Kitaya Park (24 m), *Motohashi (watch dealer)* → Karasumori Inari Shrine (57 m), *Live Haus* →
Shimokitazawa Tollywood (69 m).

Read what those wrong matches **are**: donut shops, ramen counters, an onigiri vendor, a watch
dealer, a music venue. **They are not in Wikidata at all**, so the matcher attached them to
whatever landmark happened to be nearby. Wikidata is strong on museums, shrines, parks and
stadiums — and it is the recent byFood/`@nom_life`-style food pins that dominate new batches.

**Consequences, and they are structural:**

1. **The gate is name agreement AND proximity, never either alone.** Proximity alone mis-matches
   47%; the repo already records that name matching alone gave **3 false positives in 8**. Both
   together is the only defensible gate, and a pin that fails either goes to review, not to a
   guess.
2. **The spine is an assist for landmark content, not a universal geocoder.** Expect it to carry
   roughly a third of pins of this mix — far more for an architecture creator like
   `@archimarathon`, far less for a food creator.
3. **Food and retail pins need the other path, which already exists.** #917 built
   `scripts/parse-caption-address.py`: captions carry the address, and GSI geocodes Japanese
   addresses to banchi level. **The two are complementary, not competing** — spine for landmarks,
   caption-address for venues. Any plan that expected the spine to do both is wrong.

⚠️ These figures are one city and 60 pins. Re-run the same validation on New York (landmark-heavy)
and on a pure food batch before sizing the remaining work.

### (d) Validated on two cities and 415 pins — and it splits by CREATOR, not by city

Harvested midtown Manhattan (**4,244 features, 0 tile failures**; a first attempt at 4 km tiles hit
one timeout, correctly reported COULD NOT VERIFY, exited 2, and found **640 fewer** features — the
guard earns its place) and re-ran the match against every catalogue pin inside each box.

| | New York (360 pins) | Tokyo (55 pins) |
|---|---:|---:|
| **usable match** (near **and** name agrees) | **56%** | **33%** |
| near something, name disagrees | 42% | 47% |
| nothing within 150 m | 1% | 20% |

**The city is not the variable. The creator is:**

| creator | matched | rate |
|---|---:|---:|
| `@archimarathon` (architecture) | 5/6 | **83%** |
| `@archiwhisperer` (architecture) | 7/9 | **78%** |
| `@hereinnyc` (urbanism) | 94/160 | **59%** |
| `@urbanistariel` (urbanism) | 45/84 | **54%** |
| `@japanbyfood` (food) | 7/28 | **25%** |
| `@nom_life` (food) | 3/21 · 1/5 | **14% · 20%** |

🔴 **This is the number that should size the work.** Architecture and urbanism creators land
**54–83%**; food creators land **14–25%**. Wikidata knows buildings, not restaurants, and no amount
of tuning changes that — it is a coverage fact about the source, not a matcher weakness.

**And it lands where the volume is.** The two deepest creators in the catalogue — `@urbanistariel`
(326 pins) and `@hereinnyc` (262) — are exactly the urbanism profile, at 54% and 59%. The top ten
creators hold 57% of all pins. So the spine's usable fraction is concentrated in the accounts that
matter most for reaching 100k, which is the opposite of the usual "works on the easy cases" result.

**Therefore, the routing rule:** send a pin to the spine when the creator's history is
architecture/urbanism/landmarks, and to `scripts/parse-caption-address.py` + GSI when it is food or
retail. Measure per-creator match rate once and let it pick the path — do not run one geocoder over
everything and read the average, which is how a 56% and a 14% become a meaningless 40%.


## 3. What it replaces

| field | today | with the spine |
|---|---|---|
| `lat,lon` | typed by hand; a measured northward bias (208/262 matches north, p = 1.7e-22) | copied from the OSM node — **the bias class stops being possible** |
| `city`, `country` | typed per line | admin-hierarchy lookup, no geocoding |
| `primaryCategory`, `tags` | one value for the whole invocation | per-pin, from a one-time OSM-tag → taxonomy map |
| place identity | found after the fact by `check-place-candidates.py` | **same OSM feature = same place**, by construction |

---

## 3a. 🔴 BUILT 2026-09-17 — the audit, and why it is a NAME lookup not a tiled harvest

**Shipped: `scripts/spine-lookup.py` (network, cached) + `scripts/spine-match.py` (offline).**
Together they answer, for every tour and every link pin: *is our coordinate where the thing this
entry is named after actually stands?*

### The design changed, and the reason is structural

§ 4 below specifies harvesting a gazetteer by walking tiles around each city and joining pins to
it. Tiling the whole catalogue turns out to be affordable — **1,612 tiles of 2 km, ~67 minutes**,
measured, covering every entry rather than the five cities originally scoped. It was still the
wrong first build, because it **cannot catch the errors the audit exists for**:

> a tile is drawn around the coordinate the entry ALREADY HAS.
> **If that coordinate is wrong, the right feature is outside the tile.**

Grace Farms' pin sat **6.1 km** from Grace Farms. No tile drawn around the wrong point contains the
right answer. Asking by NAME has no such blind spot: the answer is wherever Wikidata says it is,
and the distance from our stored point **is** the finding.

⚠️ A tiled harvest is still right for the *other* jobs in § 4 — autofilling a NEW pin (step 3,
where there is no coordinate to be wrong yet) and an AMBIGUOUS band ("something is near this point
but it is not what the title says"). It is step 2 that this supersedes.

### Identity: `wd:` and not `osm:node/…`

Both this document and `docs/scaling-to-100k-design.md` § A1 specify `spine_id` as an OSM feature
id, and § 2a (a) already records that OSM is unreachable — **re-verified 2026-09-17: Overpass HTTP
000, Geofabrik blocked, WDQS 200.** `spine-build.py` has always emitted `wd:Q…`. Resolved in
favour of what answers: **the Wikidata QID is the identity, with P402 carried as an optional
secondary key.**

⚠️ **This weakens the later auto-creation argument and should not be glossed.** "Same OSM feature
= same place" becomes "same Wikidata item" — a smaller, differently-shaped universe that omits most
food and retail entirely. See § 6.

### Where it lives: a committed artefact, not Supabase

`spine/lookups.json.gz`, one record per entry, committed. Not `backend/place_spine.sql`, because
**the audit needs no database** and a SQL paste is an owner-blocking step in a project whose own
`CLAUDE.md` says Supabase work is beyond the owner's comfort. The table can come later, when the
matching in § 4 step 4 needs pgvector.

The cache is also the **resume state** — the sweep takes hours and is interruptible — and it makes
the analysis free to re-run: `spine-match.py` touches no network, so it runs in CI and on every
content change.

### The bands, and the numbers behind them

| Band | Test | Meaning |
|---|---|---|
| **DISAGREES** | a match ≥ 250 m away | 🔴 the finding |
| **REVIEW** | a match 120–250 m away | read it by hand |
| **CONFIRMS** | a match within 120 m | good |
| **UNMATCHED** | no geolocated item by that name | **not a verdict** — see below |

Calibrated on this catalogue's own ground truth rather than picked: entries known to be **correct**
read 6, 7, 67, 75, 85 and 88 m (our point and Wikidata's are rarely the same point), and entries
known to be **wrong** read 242 m (Domino Park, a 201 m error), 844 m (Casa de Vidro) and 5,451 m
(Geisel Library).

⚠️ **242 and 88 are close together.** That is this method's honest resolution limit, not a
threshold worth tuning — which is why there are two bands rather than one. A single cut would
either lose Domino Park or drown the report.

### Four guards, every one of them paid for by a real failure

1. 🔴 **Bound the answer by distance.** An unbounded label search for `La Collina` returns an item
   in Italy, **9,570 km** from the Japanese bakery of the same name, and it looks exactly like a
   confident hit. Everything beyond `--bound-km` (100) is discarded — far wider than any error on
   record (6.1 km), far narrower than a same-name collision on another continent.
2. 🔴 **Nearest is not best.** `Brooklyn Museum` returns `Brooklyn Museum Art School` 75 m away
   *alongside* the museum. Distance-only ranking answers a question about the museum with a fact
   about its art school — and where our coordinate is wrong, the sibling makes it look right.
   Label agreement outranks proximity.
3. 🔴 **Han does not name its own language.** `浅草地下街` is Japanese and `文武廟` is Chinese, and
   nothing in their codepoints says so. EntitySearch ranks by the language asked for, so a
   codepoint-only rule silently asks in the wrong one. The entry's **country** decides.
4. ⚠️ **The label that comes back need not be the name asked for, and that is correct.**
   `Casa de Vidro` resolves to an item labelled `Glass House`, 6 m away, matched through an alias.
   A strict label-equality *gate* would throw away a right answer — the name is the SEARCH, the
   distance is the finding. Label equality only ranks.

🔴 **UNMATCHED IS NOT A CLEAN BILL OF HEALTH.** It means Wikidata has never heard of the subject.
Of the six known errors it knows four and has never heard of two (`La Collina`,
`Asakusa Underground Street`); measured coverage is 78–83% for architecture creators and
**14–25% for food**, and food is a large part of this catalogue. An unmatched entry is
**unexamined**, and the report says so in those words.

### Known limitation: a large site reads as a disagreement

The first live findings were `Grand Concourse` (a four-mile boulevard, 4,486 m),
`Green-Wood Cemetery` (478 acres, 741 m) and `Brooklyn Bridge Park` (a linear waterfront strip,
634 m). **None is an error.** A site with no single point puts our coordinate and the gazetteer's
centroid hundreds of metres apart with neither being wrong — the same blind spot `docs/places.md`
records from the other direction: *"A forty-acre site cannot be found by a metre-scale sweep."*

The report warns about this in so many words rather than guessing. **The fix, when it is worth
doing, is to fetch Wikidata's `P2046` (area) in `spine-lookup.py`'s query and scale the bands by
the site's own radius** — a bigger place earns a bigger tolerance. It needs a re-sweep, so it waits
for a reason to re-sweep.

### Two false positives caught during the build, both from containment

Both appeared in the first 125 entries of the live sweep and both are now regressions in the
selftest:

- **`Municipal Library of Viana do Castelo` matched the TOWN `Viana do Castelo`**, 464 m away, and
  was promoted to a finding about the library. Plain containment reintroduces exactly the bug
  `check-place-candidates.same_name` uses equality to avoid — `Akihabara` matching
  `Gyukatsu Ichi Ni San, Akihabara`. Fixed by dropping the entry's city words from both sides.
- **The city drop alone is not enough**, because the containing thing is not always the `city`
  field: `Gyukatsu Ichi Ni San, Akihabara` is recorded in `Tokyo`. Fixed by a second rule — an
  English title names its subject FIRST and its locator LAST, so a candidate that is a *subset* of
  our title must carry our title's **head word**. `Geisel Library` carries `geisel`; `Akihabara`
  does not carry `gyukatsu`.

⚠️ The city drop is **not** redundant behind the head-word rule, though it looks it: a title that
*leads* with its city (`Brooklyn Botanic Garden`) has the city AS its head word, and without the
drop the borough matches the garden inside it. Mutation-testing is what surfaced that — the
obvious regression passed with the drop deleted.

### What it does not do

**It moves nothing.** `docs/lessons.md`: *"Move the pin, never the place, and only with the owner's
say-so"*, and three pins moved on a district-centroid distance came out 11 m right, 220 m wrong and
100 m wrong. The output is a report the owner approves from one line at a time, exactly as #930's
31 fixes went.

---

## 4. Build order — each step independently useful

⚠️ **Steps 1 and 2 are superseded — see § 3a.** Kept here because steps 3 and 4 still build on
them, and because the reasoning that replaced them is worth not re-deriving.

1. ~~**`scripts/spine-build.py`** — PBF → `backend/place_spine.sql`, five cities~~ — ✅ **the
   harvester exists** (Wikidata, not PBF; § 2a (a)), but nothing is committed from it and the
   audit did not need it. A tiled harvest is still the right shape for step 3.
2. ~~**`scripts/check-coordinates.py --pins` with the spine as reference**~~ — ✅ **DONE
   DIFFERENTLY, 2026-09-17.** `--pins` shipped in #927 as an *offline neighbour-consistency*
   check, and the spine half became **`scripts/spine-lookup.py` + `scripts/spine-match.py`**, a
   NAME lookup rather than a tile join. 🔴 The reason is structural and is in § 3a: a tile is drawn
   around the coordinate the entry already has, so a wrong coordinate puts the right feature
   outside the tile. This was indeed **the first real payoff**, and it audits shipped content.
3. **`make-link-pin.py --spine-id`** — derive all four fields from one id. Fold in the per-pin
   `key=value` tail at the same time, since both touch `parse_batch` (L1021) and the loop at
   L1111-1120.
4. **Matching** — caption + on-frame text + any platform geotag against the spine, scoped to the
   creator's usual geography. Reuse `scripts/build-embeddings.py` (pgvector, all-MiniLM-L6-v2,
   already proven offline here) plus trigram name match; emit ranked candidates with confidence.

---

## 5. Two traps this project has already paid for

🔴 **Nominatim cannot geocode a Japanese address, and fails looking like a success.** Asked in
romaji it returns a **postcode centroid** indistinguishable from a venue hit — 20 of 23 on one
batch. Use the GSI API (`https://msearch.gsi.go.jp/address-search/AddressSearch?q=`), which states
the precision of its own answer. The spine sidesteps this for anything OSM carries by name, but not
for a venue it does not.

🔴 **Verify by ward, not by distance.** That is what caught an address 229 km away in Aichi and a
caption whose postcode contradicted its own place name. **Never move a pin on a district-centroid
distance** — three such pins came out 11 m right, 220 m wrong and 100 m wrong, having read as
269 m, 144 m and unparseable.

⚠️ **Automated name matching gave 3 false positives in 8** on one run: a generic cuisine word
matched the wrong restaurant at 0 m, a chain name matched a branch 3.3 km away, and one matched a
different branch of the right chain. **Do not ship its output unread** — which is the argument for
ranked candidates plus a review queue, not a single best guess.

---

## 6. The owner decision this does NOT need yet

`TRAVEL GUIDED TOUR/Models/Place.swift:18` — *"Anything looser must be approved by a human, never
auto-created."*

Densifying to 3–4 creators per place eventually requires auto-creation, because the map caps a
stack (`TourSetMap.maxStacked = 3`, and `HomeView.maxStackedPlacecards = 4`). **But the human rule
is demonstrably working at today's scale:** of the 19 coordinate groups with more than 3 pins,
**18 are already fully collapsed into a place page** and the 19th is 4-of-5. So this decision
belongs *after* the spine exists and can be judged on real output — not now.

⚠️ `docs/places.md` leaves part-vs-whole explicitly undecided, and that will surface hard once a
spine offers both a building and its rooms as separate features.

### 🔴 The contradiction with `scaling-to-100k-design.md` § A1, resolved (2026-09-17)

That document says owner sign-off on auto-created places is needed **before A1 ships**; this
section says the decision belongs **after** the spine exists. Both were written before anything was
built, and the built thing settles it: **the audit in § 3a creates no place, changes no rule and
moves no coordinate**, so the question does not arise for it at all. `Place.swift:18` stands
untouched.

What the audit does is produce the evidence the decision actually needs — per-creator coverage,
measured on real content — rather than the unmeasured guess the board item was resting on. ⚠️ And
the identity change in § 3a is part of that evidence: the argument for auto-creation was "same OSM
feature = same place", and the reachable source makes it "same **Wikidata** item", which is a
weaker claim over a much thinner universe. That belongs in front of the owner before, not after,
they are asked to lift the rule.

⚠️ `status/owner/auto-created-places.md` still describes the pre-2026-09-16 state in places; its
own header records that its "46 invisible pins" evidence was **false** (the measured figure is 0).
Read the correction, not the body.

---

## 7. Verification, and why it is written this way

| | |
|---|---|
| the spine's coordinates | `check-coordinates.py --pins` **BIAS line** must show the northward offset gone — not merely a clean GROSS list. That reading rule is CLAUDE.md rule 8b |
| matching quality | a held-out set of ~200 already-shipped pins must reproduce their place, city, country and category. **Measure recall as well as precision** — a wrongly-rejected candidate leaves no trace, so over-rejection is the dangerous direction |
| places | `check-place-candidates.py` EXACT count should trend toward zero as identity comes from the spine. It is **3** today, down from 15 |
| every run | read the **run stamp and the counts**, never the verdict line — a checker that fetched nothing still prints OK |

🔴 **On quoting this document.** The audit that preceded it claimed ~32 link pins were invisible on
the map because of `maxStacked`. Re-derived, that was **wrong**: 18 of the 19 groups were already
collapsed into places, and the true residue was 2 pins. The error was counting raw coordinate
groups without checking the mechanism built to solve them. **Re-derive every figure here before
acting on it**; the commands are inline above precisely so that is cheap.

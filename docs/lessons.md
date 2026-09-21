# Lessons

Rules this project paid for, lifted out of ~4 months of session history so they can be
read in a few minutes instead of re-learned. Each one is a real incident, compressed.

Full narrative: `archive/CURRENT-STATE-HISTORY.md` (searchable, do not load whole) and
the `archive/HANDOFF-*.md` files it cites.

**This file is read on demand, not at session start.** Reach for it before a tour batch,
before touching `get_catalog`, or when a check tells you something surprising.

---

## 1. Knowing whether a check actually ran

🔴 **A check that cannot run must not be able to return a pass.** Three separate ways
that has already happened here:

- **The stale output file.** `grep -n "anchor" f.py && python3 suite.py > out.txt; cat out.txt` —
  the grep matches nothing, `&&` short-circuits, the suite **never runs**, and `cat` prints a
  file left by a run two days ago. It reads exactly like a pass. Caught once only because the
  count (22/22) disagreed with the suite's real size (20). **Every checker in `scripts/` prints
  `RUN <name> · rev <hash> · <UTC timestamp>` first** (`scripts/runstamp.py`); `--out PATH`
  stamps the file before the work starts. Confirm the stamp before believing anything under it.
  A stamped file with no verdict under it is a run that **died**.
- **`PIPESTATUS`.** `python3 check.py | tail; echo "EXIT=$?"` reports **tail's** status, so a
  script that exited 1 reads as 0. Read the exit code **directly** — redirect to a file, or use
  `${PIPESTATUS[0]}`.
- **The checker that fetched nothing.** `check-image-duplicates.py` once printed
  `OK — no suspicious duplicates` having failed every fetch with an SSL error. It now **exits 2
  with COULD NOT VERIFY** rather than 0. Same for `check-coordinates.py` (>20% failed fetches).

**Read the counts a checker prints, not only its verdict.** A run reporting 161 images when
173 were uploaded is a finding: walk-stop images are invisible unless they also land in the
walk's `additionalImageURLs`, so 12 uploaded files were referenced by nothing.

**Self-test a mirror before trusting it.** A Python mirror of `validate-tours.swift` has three
times silently passed everything: once because the vocabulary regex matched
`(facet:…, tags:…)` when `Tag.swift` writes `(.placeType, [ … ])` and parsed **empty**; once
because a bare `case manual` has an *implicit* raw value, so an enum parser matching only
`case x = "y"` read an empty domain; once because `load_vocab()` returns a 2-tuple that was
unpacked the other way round. **Assert the parse is non-empty and raise on it** — the mirror
now refuses to run otherwise, and pins each rule in its own selftest.

**Fault-harness gotchas, each paid for separately:**
- Count **errors AND warnings** — several rules are warnings, and an errors-only harness
  reports them as MISSED (session 141).
- `check()` returns an **`(errors, warnings)` tuple**, not an exit code. Reading it as one made
  every run, including the clean control, look like a failure (session 142's false pass).
- Inject **in memory** via the mirror's own `check()`. The mirror draws its control from the
  live catalogue and exits 2 when that file is dirty, so injecting onto disk reports 16 false misses.
- Run a **clean control before and after**, and assert each mutation's anchor appears **exactly
  once** — a fault that fails to apply otherwise passes for free.
- Derive the batch's ids **from the diff against `HEAD`**, never from a scratch file.

🔴 **A proximity sweep is a candidate finder, not the map's stack cap — they differ by
twenty.** The 65 m sweep sessions use to spot place candidates is *not* what `TourSetMap`
stacks on. Cards stack for markers sharing a cluster cell, and with `MapClustering.cellsAcross
= 20` at `buildingScaleSpan` (0.0006°, ~65 m across) **a cell is about 3 m** — anything 20–85 m
apart separates by zoom and stays reachable. Reported as the cap, the sweep told the owner that
three groups were at or over it and that a fourth entry would be permanently untappable; on
exact coincidence, the case no camera can separate, the catalogue has **0 groups at or over the
cap**. **Say which test produced a finding before calling it a defect** — and a genuine one
looks like #767's three pins on one identical derived coordinate.

⚠️ **A place's member invariant is FIRST-STOP equality, never centroid.** A `multiStop` walk's
centroid is the mean of its stops, so a centroid assertion fails for **26 live members** and is
right to: the walk begins at its place and then leaves it.

🔴 **Before calling a mirror miss a "blind spot", read the Swift rule.** Sessions 142, 143 and
145 each shipped one that turned out to be a rule they had invented — non-https heroes
(`isValidURL` accepts `http://`), duplicate tags (`Set(t.tags)` collapses them silently), a
non-empty `city` check (the field is `let city: String?` with no such rule), and a
`Designed by a Master` shelf rule the validator has never had.

### 🔴 Half a cache-invalidation is worse than none (2026-09-21)

`spine-lookup.py` keys every cached Wikidata answer by a digest of the entry's title,
coordinate and search bound, and re-asks when any of them moves. `spine/README.md` said so.
It was true — **of the fetcher**. `spine-match.py`, which is what CI runs and what a human
reads, never looked at the digest and printed the cached distance regardless.

So the audit reported **all nine coordinates corrected the previous night as still broken.**
Belgrade Tower read *2,329 m out* while sitting on Wikidata's own point — a 0 m agreement.
Fifty-nine rows were stale; refreshing them took **9 queries** and moved CONFIRMS 1,764 → 1,778.

Two things to take from it, and the second is the one that matters.

**The nuisance direction is the harmless one.** Being told a fix is unfixed wastes a session.
But the same blindness runs the other way: **a coordinate moved to the WRONG place keeps
reporting its OLD distance**, so the one check built to police such a move cannot see it, and
CI stays green. The visible symptom was the benign half of a silent defect.

**A stale number is a confident wrong answer, not a weak one.** The fix is not to flag such a
row and print its distance anyway — it is to print **no distance at all**. `spine-match.py`
bands them `STALE`, leaves them out of the coverage denominator (coverage is the claim
"Wikidata knows this subject", which a row cached against an entry we no longer hold does not
support), and exits **2 — COULD NOT VERIFY**, the same treatment `NOT-ASKED` already had.

Three general rules:

- **An invalidation rule belongs to every reader of the cache, not to the writer.** If only the
  fetcher checks the digest, the cache is unversioned from the point of view of everyone else.
- **Documentation describing an invariant is not evidence the invariant holds.** The README's
  promise is exactly what stopped anyone looking; it described one half of the system and read
  as describing all of it.
- **The tell was arithmetic, not intuition.** Our point equalled Wikidata's to five decimals
  and the tool said 2,329 m. When a check's output contradicts a number you can compute by
  hand, the check is the thing to doubt.

**The rule generalises, and the second instance was one layer up.** `checks/spine-verdicts.json`
holds 137 rulings on individual findings — *this one is Wikidata's error, ours is right*. Each was
a judgement about **one coordinate**, and the records stored none. Reading them back to quiet a
settled finding would have meant carrying a verdict across a move nobody had judged: a finding
suppressed on a point no human ever saw, which is **silence indistinguishable from agreement** on
the one defect nothing else catches. So every verdict is now stamped with the coordinate it was
reached against and **stops applying the moment that coordinate moves** — and an unstamped record
is not trusted at all, because "unstamped" and "unmoved" would otherwise read the same. With that
in place the findings list fell from **85 to 41 genuinely unexamined**.

Two structural notes worth keeping:

- **The verdict rides alongside the band, never replacing it.** A ruled entry that later stops
  confirming — a fix reverted by a bad merge — must still read as a finding, and it would not if
  the ruling overwrote the classification.
- **The stamp was provable, not assumed.** Diffing the catalogue at the verdict file's first
  commit against `HEAD` showed exactly eleven of the 137 entries had moved: the nine whose *fix
  was the verdict*, plus two that did not exist yet. So stamping today's coordinate was correct
  for all 137 — and one `fixed` note's hand-typed coordinate turned out to be **~60 m from what
  was actually applied**, which is the argument for storing the fact as data rather than prose.

**A third instance, found by looking for the SHAPE rather than for a bug.** Having fixed two,
the obvious question was which other committed cache has a reader that does not version it. The
answer was the vision sweep: `check-pin-subject.py` digests an entry's title **and hero image**
and re-asks on a mismatch — the fetcher, again — while nothing reading the cache back checks it.
**51 of 4,930 entries were retitled or re-imaged after their verdict, and 69 had never been asked
at all.** The single stale `CONTRADICTS` was **Old Spitalfields Market, whose hero was replaced
precisely because that check flagged it** — so the finding outlived its own fix, and read exactly
like a live one. A `--status` mode now reports both, offline and without the API key, because
coverage is answerable without one and refusing to answer it for want of a key is the same false
silence.

### Wikidata has three front doors and they fail independently (2026-09-21)

Mid-session WDQS returned `429 Aggressively rate-limiting to 1 req / min - this rule was created
during active wdqs outage`, and the action API (`w/api.php?action=wbgetentities`) 429'd as well.
The **REST endpoint answered 200 throughout**:

```
https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/<QID>/labels/en
https://www.wikidata.org/wiki/Special:EntityData/<QID>.json
```

It is one item per request rather than fifty, so it is a fallback and not a replacement — but it
is the difference between "Wikidata is down" and "the batch route is down". Same rule as the 42
Tokyo addresses and the Overpass mirror: **a blocked route is not an absent fact.** ⚠️ It is not a
free pass either: it resolved only 21 of 55 labels before throttling in turn, so say what you
could not get rather than reporting the partial set as the whole.

⚠️ This is also why the `refresh-spine` CI job is `continue-on-error`. A third party's outage must
degrade a reporting artefact, never block a content merge.

🔴 **Go looking for the shape.** Two instances of one defect are not a coincidence, they are a
pattern, and the third was found in a few minutes by grepping for which scripts read a committed
cache. Fixing the bug you tripped over and stopping there leaves the others.

⚠️ **A guard that reds a check must ship with the thing that clears it.** Exiting 2 on a stale
cache would have turned the coordinate audit permanently red on the next content merge —
`spine/README.md`'s own warning that *a red check nobody can fix reads as coverage and gets
ignored*. The `refresh-spine` job in `publish-catalog.yml` re-asks on every content merge, and
is deliberately `continue-on-error`: it is a reporting artefact, WDQS is a third party, and a
failed refresh degrades into precisely what the guard says — STALE, with the command named.
**The guard is what makes the automation safe to let fail.**

---

## 2. Live systems vs. documents

🔴 **A reachability question CAN be measured from a session — and the first tool to answer it was
wrong. Always run a known-blocked AND a known-open control through any third-party checker.**
Asked whether `github.io` reaches mainland China, `chinafirewalltest.com` reported OK from five
mainland nodes. It also reported **`www.google.com` as OK**, which OONI's real probes inside China
contradict at **91% anomaly over 512 measurements**. One control passed (TikTok → BLOCKED) and one
failed, and without the failing one the green ticks would have been written down as fact. The
asymmetry is still usable: a checker biased toward false-OK saying **BLOCKED** is a strong signal —
that is how `dozent.world` was found, corroborated independently by OONI putting `vercel.app` at
100% anomaly with zero OK.

**Querying a mainland DNS resolver is not a reachability check.** AliDNS and Tencent DNSPod (both
DoH, both answering from inside China) return correct IPs for our hosts — and **also** for
`www.tiktok.com`, which is definitively unavailable there. Clean DNS rules out DNS poisoning only;
the GFW's usual HTTPS mechanism is an SNI-triggered TCP reset that leaves DNS untouched.

**`api.ooni.io` is the primary source for this class of question** — real probes, real countries,
free, no key: `/api/v1/aggregation?probe_cc=CN&domain=<d>&since=&until=`, plus `axis_x=input` to see
which URLs were actually tested. ⚠️ Its `domain=` filter works on `aggregation` but silently returns
**zero results** on `/api/v1/measurements`, which reads exactly like "no censorship found" — § 1's
trap in a new costume. And check *what* was measured: the 38 China measurements for `github.io` are
the **bare apex**, a parking page, not a Pages site; **no real `*.github.io` has ever been tested
from China**, so that question stays open rather than answered.


🔴 **Never report perishable state from a document.** This has cost real trust four times:
an already-accepted Apple agreement reported as unaccepted by four sessions in a row; "our
account is in test mode" nearly sent to Stripe; a "V1: no backend, no payments" line sitting
above a shipped payments feature.

**A probe is a measurement with a timestamp, not a durable fact.** Re-probe immediately before
landing any claim about live state. Two sessions correctly measured the catalog RPC hours apart
and reported opposite things; both were right at their own moment.

**Sample a flapping endpoint before characterising it.** A 33%-failure endpoint returned clean
8 times in a row, and two later sessions closed it as "fixed" off 4- and 14-call samples. It was
~1 in 10. Say the failure **rate**, not "gone".

**Verify against the system, not the success line:**
- **A merged PR can carry nothing.** #629 reported "successfully merged" for an **empty commit** —
  the work had been committed to local `main` and the branch ref pushed while still at an
  already-merged commit. Check `git log origin/main..HEAD` before pushing; check the squash
  actually changed files after.
- **A green seed job can be a guarded no-op.** The seed's `perform refresh_catalog_snapshot()`
  is wrapped in `if to_regprocedure(...) is not null` — with the SQL unpasted the guard is false,
  the seed skips it, raises a notice and finishes green. Ask `catalog_snapshot_age()`.
- **A "Successfully uploaded all screenshots" line hid 4 duplicates** on the live listing — its
  verification pass ran before Apple finished processing and re-uploaded four. Ask Apple.
- **The committed blob, never the served URL, says a publish landed.** The gh-pages CDN lags
  6–17 minutes routinely; compare the committed blob hash instead.

🔴 **"I don't have the key" is a claim about ONE endpoint, not about the fact.** Before reporting
that something cannot be checked, ask which part of it actually needs the credential you lack. The
App Store row of the perishable table said a keyless session must say it could not check the
version — so no session checked, and **STATUS.md said 1.1.1 was still awaiting owner action for a
week after it was live on the App Store.** The **released** version, its release date and its live
release notes come from a public endpoint that needs no key at all:

```bash
curl -s "https://itunes.apple.com/lookup?bundleId=com.ehky.TRAVEL-GUIDED-TOUR&country=us"
```

Only an **unreleased** version's review state needs the ASC key. `scripts/session-start.sh` now
runs the public lookup unconditionally.

**A failure can be positive evidence — read the error, not just the colour.** Build 140 was
rejected at upload with **90186 `Invalid Pre-Release Train`**. A train closes because Apple
*approved* the version, so that rejection proved 1.1.1 had shipped — five days before anyone said
so. The same shape recurs: `get_catalog_built()` returning `57014` is the materialisation
migration **working** (the slow builder is off the request path), not failing.

---

## 3. Content and the catalog

**⚠️ `--title` is ignored in a `--batch` run of `make-link-pin.py`** (`title=a.title if
len(rows) == 1 else None`), so a batched pin takes its map title from the source caption, truncated
to 60 characters. TikTok captions usually survive that. **Instagram captions are paragraphs**, so a
batched Instagram pin gets named *"Architecture worth traveling for. 🤍☕🌿 Designed by @marlonbl…"*.
Mint an Instagram batch as **one single-`--url` run per pin**, driven from a TSV, with outputs
written to per-pin files and combined on disk — the conversation still never sees a pin's JSON.

**The thumbnail identifies the subject when the caption will not.** A creator post often names no
place at all (*"the coolest office ever"*, *"this tower gets wider the higher it climbs"*).
Downloading the post's thumbnail and **looking at it** settled four of five such cases in one
session — a carved pediment, a logo pylon, burnt-in caption text. Do that before researching, and
before asking.

**🔴 A section that every session appends to becomes the whole file.** Three files here caught the
same disease independently, and in each the growth was invisible because no single session added
much: `CLAUDE.md` § Current State (**97.7%** of a 1.5 MB file, and it was injected into every
request), `ROADMAP.md` § "Where we are right now" (**86%**, 120 dated `**Status (…)**` blocks), and
`archive/README.md` (**94%**, index rows averaging 2,089 characters where a line was wanted). The
tell is a heading that promises the present tense — *current state*, *where we are right now*,
*active handoff* — sitting on top of a log. **A per-session append needs a stated cap or a home
that is not the live document**; the fix each time was to move the history out verbatim, keep the
newest few, and point at the archive. And when you write the row, remember which file you are in:
an index takes a line, the account goes in the handoff.

**🔴 An index that names a file nobody can open is worse than one that omits it.** `archive/README.md`
carried a row for `HANDOFF-260819.md` that was never committed — indexed, promised, absent. It
survived because nothing ever checked the index against the directory. One `os.path.exists` per row
finds it. Mark the gap rather than deleting the row: the gap is the finding.

**⚠️ `ls archive/HANDOFF-*.md | tail -1` does not give you the newest handoff.** `-` sorts before
`.`, so `HANDOFF-260908-2.md` sorts *before* `HANDOFF-260908.md` and `tail -1` discards the newer
file. Parallel sessions produce those suffixes constantly. Order by when git first saw the file:
`git log --diff-filter=A --name-only --pretty=format: -- 'archive/HANDOFF-*.md' | grep . | head -1`.

**🔴 Bulk content must go disk to disk, never through the conversation.** A generator that
prints entries to stdout and a session that pastes them back to write them pays for the same
bytes twice — and because a conversation re-sends its whole history on every request, that
block is paid again on *every subsequent turn*. Link pins run ~1.9 KB of JSON each, so a batch
of 20 costs ~21,000 tokens on the turn it lands and again on each turn after. Redirect to a
file and merge from the file (`make-link-pin.py … > pins.json` → `merge-link-pins.py
pins.json`); the session sees a six-line summary. Print one entry only when you mean to *read*
one. The same reasoning is why `Tours.json` is never opened whole: at 11 MB it is three context
windows of a file nothing needs in full — query it with `python3 -c` and print the fields.

**🔴 A convention nobody checks is not a convention.** Link-pin ids are uuid5 over the source URL,
so a post naming several places needs a fragment to separate its pins — the city. When two of them
sit in the *same* city the city collides too, and **twice** the answer was an invented uuid, because
a made-up id is indistinguishable from a derived one by eye. The rule (fall back to
`#<slug(city)>-<slug(title)>`) was the easy half; the half that matters is that
`merge-link-pins.py` now **refuses** an id it cannot derive and prints the one the scheme gives.
Write the check in the same change as the rule, or the rule is a suggestion.

**🔴 An id is identity — never re-mint a live one.** Changing an id makes every phone treat the pin
as brand new, so anyone who saved it loses it from their library. The five existing non-derivable
ids stay exactly as they are, permanently; a new rule applies to new pins only. "Tidying" ids is
data loss wearing a neat haircut.

**⚠️ A check that groups records must deduplicate first.** The id check grouped catalog pins and
incoming pins by source URL — and re-merging an existing pin counted it twice, so an ordinary
single-post pin was told its id should have carried a city fragment. That broke the idempotence the
tool exists to guarantee, and **only a run against the real catalogue showed it**; the unit tests
were all green. Dedupe by id before grouping, and test the re-run, not just the first run.

**🔴 An absence you found by grepping the wrong field is not an absence.** The one-post-many-pins
id scheme adds `#<slug(city)>` to the *hashed key*, while `sourceURL` is stored clean. Grepping
`sourceURL` for `#` returns nothing, which reads exactly like "the scheme does not exist" — and
that conclusion was written into a runbook before `archive/README.md` contradicted it. The scheme
is real: 7 of the 10 live shared-URL pins reproduce from it on both the tour and the stop id.
Before recording that something does not exist, look for the thing it would *produce* (here:
pins sharing a `sourceURL`), not only for the spelling you expected.

**A tool you are about to write may already exist.** Before building a fault harness for a
content batch, note that `validate-tours-mirror.py` injects 32 known faults on every run and
refuses a verdict if it misses any. Three sessions' worth of "rebuild the harness" was work
already committed. Grep `scripts/` and read the neighbouring script's docstring first — this
repo's tooling is unusually well commented, and the answer is often in it.

**🔴 The pin moves, never the tour.** A geofenced tour's coordinate decides where its audio
fires; a link pin is `manual` and costs nothing to move. Assert `manual` before relocating
anything and refuse otherwise. The one documented override was an explicit owner instruction
(Barcelona Pavilion) — and it immediately forced the next rule.

**A coordinate and a radius are one decision.** Moving a geofenced stop changes which vantages
fall inside it. Re-derive the radius from what the script asks the listener to be looking at,
never inherit the city default. Barcelona Pavilion moved 78 m and needed 30 → 90 m or the
far-pavement vantage the script names stopped firing.

**Read the payload, not the heading.** Owner headings have been wrong in six consecutive batches —
"Itsblankcanvas" is `@itsblankcreative`, a "Miami" heading whose first link was an existing
Toronto pin, a "Domus" heading over an `@romeartstories` reel, a `@travpholer` post inside an
`@iamlamlammm` block.

**Count a batch from the maker row, never from an analysis file.** `drafts/*/analysis.json` is
not batch-scoped — it held two other creators' posts, and counting live shortcodes from it
overstated a batch by two. When two derivations disagree, the disagreement is the finding.

**A mention is not authorship (the Sullivan rule).** Louis Sullivan named in three Chicago tours
he did not design; Gustave Eiffel tagged on 2 of 5 because three narrations say explicitly he did
not design them; `James Stirling`'s Palazzo Citterio plans were **never built**; `Philip Johnson`
left the Rothko Chapel after Rothko rejected his design. Tag what the entry's own source says.

**Tag only what the source names (the Jules Dalou rule).** `Norman Foster` is not tagged on the
Hearst Tower and `Snøhetta` not on the Oslo Opera House, because neither caption names an
architect — even though both are in the vocabulary and both really did design them. **Do not
"finish the job."**

**`Designed by a Master` rides ALONGSIDE a named architect, never instead.** `Tag.matches`
performs no implication and the curated home shelf is keyed on that literal string, so dropping
it silently removes the tour from the shelf built for exactly those tours (the #493 defect).

**Both vocabularies must be edited.** `Models/Tag.swift` and `scripts/validate-tours.swift` each
keep a copy; editing one alone produced **193 validator errors**. Assert they are identical, and
compare new names on **normalised token sets**, not strings — `I.M. Pei` vs `I. M. Pei`,
`Kazuyo Sejima` vs `SANAA`, `Taniguchi Yoshio` vs `Yoshio Taniguchi`.

**A name sweep must be READ, never applied.** `Public Architecture` matched eight tours using the
ordinary phrase; `Van Eyck` matched the *painter*; `Massey` matched a chef; `Böhm` matched a cited
researcher; `Frank` matched Sinatra; `Larsson` matched a basket workshop.

**Bracketed stage directions hard-error.** The validator rejects any `\[[A-Za-z]` in
`transcriptText` — strip every `[beat]` (42 in Berlin, 44 in Rome, 78 in Barcelona). Note it is
`transcriptText`-only: `[HIDDEN GEM]` in a *caption* is a creator's own series marker and is fine.

**The sentence splitter must ignore abbreviations and loop.** `St./Ss./Mt./Dr./No./Ave./Blvd.`
otherwise produce 40-character caption fragments. Extend across sentences — and across
paragraphs — until the caption clears 60 chars.

**Making a `Place` means MOVING its members onto its coordinate — the validator hard-errors
otherwise.** `place … : member not on the place coordinate` fires when any member's **`stops[0]`**
is more than `1e-9` degrees from the place, so a place cannot merely gather pins that are near each
other. Making The Parthenon a place moved `The Parthenon: The Missing Roof` **9.7 m**; #746 moved a
pin 3.8 m onto the Gilder Center for the same reason. Move the *pin*, never the place, and only
with the owner's say-so — `Place.swift` records the standing rule that grouping looser than exact
coordinate equality **must be approved by a human, never auto-created**.

**Place ids are `uuid5(NAMESPACE_URL, "atlas-place:<city-slug>:<name-slug>")`, lowercase.** It
reproduces **131 of the 140** live places; the misses are accented names whose slug transliteration
differs and six with uppercase ids. Re-derive before minting rather than inventing a uuid — a
made-up id looks exactly like a derived one, which is how two link-pin ids got invented on the spot
(§ the link-pin runbook). Nothing in `scripts/` mints a place, so this is done by hand.

**A place's `heroImageURL` is optional and falling back is usually right.** With it absent the place
page uses its top-ranked member's hero, which for a link-pin place means the creator's own
thumbnail — better than pointing the place at a file a pin already claims, which is the "two entries,
one file" shape `check-image-duplicates.py` exists to catch.

---

## 4. Geocoding

**A supplied coordinate is not a verified coordinate.** Reverse-verify every one at **zoom 18**.
Ten Barcelona coordinates were wrong — **all ten displaced due north**, up to 3.2 km; a Milan
abbey sat on a motorway; a Dubai post pointed 7 km out; a Chandler House pin sat 423 m away on
the wrong street. At a 30 m geofence none of these error — the tour simply never fires.

**Systematic bias is upstream and measurable.** `scripts/check-coordinates.py` reports a BIAS
line with a significance test. Pipeline-sourced cities ran **+10.3 m north at p = 5.6e-06**
while hand-sourced cities were dead centred. Gross errors scale with zoom — one ~20 px screen
offset gives +10 m at zoom 19 and +3.2 km at zoom 11.

**A distance alone proves nothing.** Four Milan coordinates looked 200 m–9.4 km wrong and were
correct: same-name districts, a same-name café 8 km away, street-centroid noise, and a **towpath**
(a linear feature, where a centroid distance is meaningless).

🔴 **A geocoder's rate limit can arrive dressed as an answer.** Nominatim returns **HTTP 429** as an
HTML page; a script that only parses JSON turns that into an empty result list, and an empty result
list prints as "no match". Session 155 got **30 "NO MATCH" out of 35 subjects — Tribune Tower among
them** — and the only thing that exposed it was the implausibility of the list, not the code. Read
`%{http_code}` and keep three outcomes distinct: *found*, *genuinely empty*, *did not fetch*. A
geocoding sweep from a shared cloud IP will meet this; Photon (`photon.komoot.io`, no key) answered
where Nominatim was throttling.

🔴 **Read the returned NAME, not just the distance — the wrong building often has the right name.**
Geocoding 35 subjects returned four confidently wrong places, and two were near-misses no distance
check would flag: the **Banning branch** library when the post was about Huntington Beach's
**Central** Library, and **2178 Bloor W** (the public library) when the subject was the Runnymede
Theatre at **2225**. Both are real, both are close, both would validate, and both would leave a pin
that never fires in front of the right building. A county-level match (`兴隆县` for a specific
resort) and a name that misleads about its own city (**Conwell** *Coffee Hall* is in New York, not
Philadelphia) were the other two.

**Query in the local script when a place is not Western.** Aranya Wulingshan resolved only to its
county in English and to the exact Phase 2 development as `阿那亚·雾灵山2期`.

**Read the OSM class and type, never just the name or distance.** `The Hive` returned a
confident named hit that was a **bouldering gym** 1.2 km from the mass-timber office. An Orlando
McDonald's returned `[primary]` — a road.

**Re-query before concluding a place is unmapped.** This was the whole fix in at least eighteen
cases: `Avebury Manor`, `Fort Jefferson` (zero results unbounded, named at 10 m bounded),
`No Man's Land Fort` (the apostrophe), `Crystal Palace Subway` (reverse gave an unnamed way, the
forward names it at 11 m), `BP Bridge`, `狭山池博物館`, `Casa Milà` (OSM files it under
Carrer de Provença, not Passeig de Gràcia).

**Bound the query.** Unbounded searches matched **Raccoon Key 200 km away**, **Madeira instead of
Miami**, **Chad and Somaliland**, **Grand Street in Williamsburg**, and the **Taipei
Representative Office in the Netherlands**.

**Use structured parameters for a short Plus Code reference.** A free-text reference put
`Chuo City Tokyo` on a confectionery in **Osaka** and `Venice Italy` on a restaurant in **Graz**.

**The locality printed beside a short Plus Code is a guess, and the caption outranks it.** A short
code carries no absolute position — it recovers against whatever reference you hand it, so the
reference *is* the answer. Two `@urbanistariel` pins arrived labelled `Lower Town, Greece`; read as
Monemvasia, a real Peloponnesian lower town, both recovered to **37.074, 23.367 — 88 km out, in the
Myrtoan Sea**. Both captions said *Mystras*, next to Sparta, and against a Sparta reference both
land on the site. **Read every recovered coordinate back against what the post is actually about
before wiring it**, and treat a vague or generic locality (`Lower Town`, `Old Town`, `Centro`) as
unresolved rather than as a place name.

**An interpolated house number is not a mapped building.** `1529 Vassar Street` and
`165 Crosby Street` and `201 Wan Chai Road` all returned **road segments**. Reverse-geocode each
candidate and read the **road and the number** back; the distance between candidates tells you
nothing about which is right.

**A reverse-geocode landing elsewhere is usually correct, not wrong.** Documented shapes: the
**inner tenant** (M+ → Mosu, the Breuer Building → a Madison Avenue shop, Hoover Dam → Officers'
Quarters), the **nearest addressed node** (Säynätsalo → a hair salon literally named "Aalto"), and
the **enclosing feature** (COSM → The Interlock, Evermore → the lagoon). When it lands on a road
or a car park, **fetch the polygon and test containment** rather than arguing with it.

**A 0 m match against a named node is not proof a point is usable.** Waterfall Bay matched OSM's
own node exactly — a **label point offshore**, in the sea, reverse-geocoding to nothing at all.
No name, no address, no locality is the signature of a point that has landed on nothing.

**A reverse-geocode cannot tell you the business moved.** Tung Po's North Point coordinate
returned the right market building, confidently, 3 km from where the restaurant has been since
2022. Papaya King's 90-year flagship moved across the street. **Check the venue is still there.**

---

🔴 **Nominatim CANNOT geocode a Japanese address, and fails in a way that reads as success.**
Asked in romaji it returns a **postcode centroid** at full decimal precision, indistinguishable
from a venue hit — **20 of 23 addresses** on 2026-09-15. Japan addresses by chōme-banchi, not
by street, and OSM's coverage of those numbers is thin. Use the **Geospatial Information
Authority of Japan** instead — free, no key:

```
https://msearch.gsi.go.jp/address-search/AddressSearch?q=東京都台東区上野6-9-17
→ 35.710045, 139.775467   東京都台東区上野六丁目９番１７号
```

It echoes the matched 丁目/番/号, so **the precision of its own answer is readable**: an answer
ending 号 or 番地 is building-level; one stopping at 丁目 is coarser and says so. Cross-validate
before trusting a new geocoder — GSI's Mizutani Camera point agreed with the OSM venue node to
**~1 m** and Cafe de l'Ambre to **~3 m**, which is what earned it.

🔴 **A venue's address is findable by SEARCHING ITS NAME. Exhaust search before declaring data
unobtainable.** On 2026-09-15 a session needed 42 Tokyo restaurant addresses, tried scraping
byFood.com (403, Cloudflare), Tabelog search (403), Overpass (blocked by this environment) and
Instagram embeds (no location tag), concluded the data was out of reach, and handed the owner a
list to source by hand. The owner replied: *"the txt list all have names you can look up. you
really think my brother can do a better job than you?"* Searching each **Japanese name plus
住所** returned every address, corroborated across the restaurant's own site, Gurunavi, Navitime,
Hitosara and Ikyu. A blocked scrape is not an absent fact.

⚠️ **Automated venue-name matching produced 3 false positives in 8**, all caught only by reading
each: "Yakiniku Kappo Note" matched **焼肉花** (Yakiniku *Hana*) at **0 m** on the generic word
*yakiniku* — and 0 m means it matched something already sitting on the bad centroid, which should
be read as a red flag rather than a perfect hit; "Kiwamiya" matched a ramen shop **3.3 km** away;
"Saryo Tsujiri" matched a different branch of the same chain. **A chain name, a cuisine word and
a neighbouring branch each defeat it.** Never ship its output unread.

🔴 **Reverse-geocoding a stored coordinate cannot tell you whether it is right.** In a dense city
the nearest mapped feature is rarely the venue even when the pin is correct — 92 Tokyo pins came
back sitting on a brothel, a bench, a vending machine, a blood-donation centre and a kindergarten.
Name-matching that result is worse than useless: three Ginza restaurants "matched" a watch shop
called GINZA NJ TIME on the word *Ginza*.

✅ **The check that DOES hold is ward agreement.** Geocode the address, then confirm the ward
matches the pin's own stated neighbourhood — 赤坂 for an Akasaka pin, 銀座 for Ginza, 北沢 for
Shimokitazawa. That is what caught **Yakushu Bar**, where the supplied address was 愛知県豊橋市,
**229 km away**, while the post's caption placed the bar in Sangenjaya — where the pin already
sat. A different branch of the same bar, and the pin was left alone.

⚠️ **Two pins sharing one coordinate is usually a shared fallback, but not always.** After the
2026-09-15 pass, Kiwamiya and Saryo Tsujiri still share a point and are **correct**: both are
inside 丸の内1-9-1, the Daimaru Tokyo / Gransta building. Check the addresses before "fixing" it.

## 5. Images

🔴 **Correcting an image means a NEW filename — never overwrite bytes at a live URL.** A phone
that has downloaded a tour reads its photographs off its own disk and never asks the server
again (PR #567), and the offline fallback serves whatever `URLCache` holds (PR #568). Bytes
swapped under an unchanged URL reach neither. Publish as `..._hero-2.webp` and repoint.

**A byte check is not a duplicate check.** SHA-256 compares bytes, so a JPEG and a WebP of one
photograph share none — four Milan folders shipped every photo twice and a carousel read
**A A B B**. `check-image-duplicates.py` now runs a perceptual pass, in **two stages**: the hash
only nominates, a 32×32 thumbnail comparison decides (an average hash alone clustered the Empire
State Building with a Naoshima sculpture on tone).

**And the mirror-image bug: two entries pointing at ONE file.** One file hashed once is one file,
so it never forms a group. The London Natural History Museum played **Los Angeles' narration for
six and a half weeks** because both used the bare slug `natural-history-museum` — same URL, same
audio, every URL 200, validator clean. That half of the check is catalogue-wide and unscoped.

**The hero-slug handle suffix is load-bearing.** It has prevented a live Atlas tour's hero being
overwritten in at least eight batches — `westminster-abbey`, `natural-history-museum`,
`empire-state-building`, `alcatraz`, `eiffel-tower`, `marina-city`, `gamble-house`. It cannot
disambiguate **one creator posting twice about one venue** — use a subject-specific slug there.

**Open every hero and read it against its script.** This catches what nothing else can: a Royal
Arcade clock posing as Flinders Street Station, a DuSable Bridge hero showing the wrong bridge, a
Thyssen hero that was the Reina Sofía, a Mission District mural filed under Haight-Ashbury, a
Toronto market that was Los Angeles'. Five of these were live for weeks.

**`--focus` does nothing on a 9:16 source.** `render_hero` crops at `centering=(focus, 0.5)`, so
a vertical source is width-limited and the vertical is hardcoded. Re-render by hand through a
mirror of the tool's own pipeline (import its `trim_bars`, same blur/dim/quality, **same
filenames**, so `Tours.json` is untouched) — and **self-check the mirror against `render_hero` at
vfocus 0.5 first**.

**Recovering what a crop destroyed is not the same as removing what the creator put there.**
Owner instruction: *"i dont want to editorialize other people's work."* Recover a clipped subject
name; leave a clipped strapline alone.

**Render the hero and look at it before re-cropping.** A flag written while reading the source
frame is a prediction, not an observation — one was withdrawn after the output turned out fine.

**PD-only and "modern photos" pull against each other on famous old landmarks.** A strict
`cc0,pdm` search returns beautiful 19th-century engravings and almost no photography. Unsplash
and owner-supplied photos are the practical sources; don't grind PD for a subject that has none.

**Verify a download by size and signature.** Five Wikimedia candidates came back as **2,256-byte
error pages** that a naive check reads as a download. `upload.wikimedia.org` 429s on bursts —
pace ~8 s with backoff, and use the MediaWiki API's `imageinfo` `thumburl` rather than
hand-building a `/thumb/` path (a constructed one returns 400).

**rawpixel serves `editor_1024` whatever Openverse advertises.** Two images advertised at
7000×5249 delivered 1024×768. Download and measure.

### A creator's cover frame is not a picture of the venue (2026-09-16)

`make-link-pin.py` takes a pin's hero from the post's own `display_url`, so the hero is whatever
frame the creator chose. **Creators routinely open with an establishing shot of the
neighbourhood**, which produces a hero that is atmospheric, on-brand, and not the place the pin
points at. Four @nom_life pins in the 103-pin batch (#910) got Manhattan Chinatown streetscapes:
King's Kitchen and Phoenix Palace both the pagoda at Canal/Bowery, QQ Cafe and **The Monkey King
NYC — a Bushwick restaurant** — both 59 Bayard Market.

🔴 **The duplicate check can only see this when the same shot is REUSED.** Two pairs happened to
share an establishing frame, which is the only reason any of it surfaced; a pin with its *own*
generic streetscape is invisible to every check in the repo. The existing rule above —
*open every hero and read it against its script* — is the only thing that finds those, and it
does not scale to a 103-pin batch.

⚠️ **This is not a pipeline fault, so do not "fix" the extractor.** The other 80 pins in the same
batch were correct on inspection (a Paris bakery counter for Boulangerie Mamiche, dumplings and
peanut noodles for Shu Jiao Fu Zhou). The tool faithfully fetched what the creator published.

**Why these four were left as they are** (owner decision, 2026-09-16): every route needed an
image nobody had.

- **Instagram's embed is LOGIN-WALLED from a web container** — `/embed` returns HTTP 200 with
  624 KB of HTML containing **zero** post metadata (no `display_url`, no `username`, no
  `og:image`, no `scontent` URL) and 17 hits for `login`. `make-link-pin.py` raises
  `COULD NOT VERIFY` on this correctly. ⚠️ **That is an environment block, not a broken tool and
  not a renamed key** — do not "repair" the extractor on this evidence; try from elsewhere first.
- **No public-domain photography of a small restaurant exists.** Openverse `license=cc0,pdm`
  returned `result_count=0` for all four venues. Searched, not assumed.

Three of the four are at least in the neighbourhood they depict; only The Monkey King is
factually wrong, and correcting it needs one owner-supplied frame. **If a fix is ever made it is a
NEW filename** (`..._hero-2.webp`) plus a repoint — never bytes at the live URL.

---

## 6. Backend and Supabase

🔴 **`create or replace function public.get_catalog()` is DESTRUCTIVE.** The live RPC is three
functions composed — `get_catalog()` = `get_catalog_core() || {places: catalog_places()}` — and
`get_catalog()` itself is 260 characters. Replacing it with a full body severs the call and
silently drops `places`, `priceTier`, `isPrivate`, `country`, `videoURLs`, `videoRole`. **No
error.** It cost 14 hours of a live paywall being off and every private account served as public.
**Patch `get_catalog_core`; raise if the anchor is missing so the transaction rolls back.**
`backend/add_video_role.sql` is the worked example. Run `scripts/check-catalog-keys.py` after.

⚠️ **The RPC lowercases uuids; the catalogue stores them uppercase.** A case-sensitive id
comparison against `get_catalog` reports **0 of N pins present** and then reports every hero URL
mismatched, because every lookup missed — indistinguishable from "the seed never landed".
Compare `.upper()` on both sides. Same false-alarm shape as looking for `isPrivate` on a tour:
it is a **`Maker`** field, so it is absent from all 1,553 tours and present on all 375 makers.
**A check you wrote thirty seconds ago earns the same scepticism as one in `scripts/`.**

⚠️ **The seed lands minutes after the merge, and how many is not fixed** — 11 minutes in one
batch, **13 in another** (merge 00:22 UTC, RPC still serving the old count at 00:34, correct at
00:35). **Poll to the expected count**; a single reading taken on a guess reports the batch
missing from the primary source and is wrong.

**Every key an optional Swift field decodes is invisible when dropped.** `let priceTier: Int?`
decodes a missing key as nil and the feature just stops existing — no crash, no log, no failed CI.
Asking the live RPC what keys it returns is the only detection.

🔴 **Deleting from `Tours.json` does NOT remove it from Postgres.** `seed_from_toursjson.py` is
**upsert-only by design**, so a deletion reaches the gh-pages mirror and the bundled seed and
never reaches the database the app reads first. A removal is a two-part change: the catalogue
edit **plus SQL the owner runs**. `backend/pull_nycunfilteredstories.sql` sat committed and
unpasted for **eight days** while four "removed" pins kept being served.

**And the inverse: adding a key to `Tours.json` does not put it in front of users.** Supabase is
primary. Build 68 shipped the place layer and showed the old behaviour because `places.sql` had
never been applied.

**Compare UUIDs case-insensitively.** `Tours.json` stores some uppercase and Postgres returns
lowercase — a naive diff has twice reported ~100 tours and ~130 makers as missing when nothing was.

**Assert on link-pin counts, never on maker totals.** The RPC reads more tours and makers than the
catalogue: a documented `Zxxx` test tour, and every signup auto-creating a maker row.

**In PL/pgSQL `%` is a placeholder and `%%` is an escaped literal.** A RAISE with one placeholder
and two arguments **fails to compile the whole block**, even in a branch that never runs — and
`add_video_role.sql` carried the identical bug behind a banner calling itself safe to re-run.
`backend/test-migrations.sh` now applies every migration twice against a real throwaway Postgres.
**Gate on the psql exit code, never on grepping output** — its first version grepped `^ERROR`
while psql prefixes `psql:file:line:`, and printed "ok" for a migration that had failed.

**PostgREST's reserved `order` param collides with an `order` column.** `.eq("order", 0)`
serialises to `?order=eq.0` → HTTP 400, *"failed to parse order (eq.0)"*. Filter by `tour_id`.

**Synthesized `Encodable` omits nil optionals.** `encodeIfPresent` left `saved_at` out of the
upsert body entirely, so `ON CONFLICT DO UPDATE` kept the old value and an un-saved tour
resurrected on the next sign-in. Write a custom `encode(to:)` emitting explicit JSON `null`.

---

### A filtered view answers a different question than the one you asked

🔴 **Twice in one day, 2026-09-13.** Both times the fact read was correct and the
conclusion drawn from it was false, because the read went through a filter that
the conclusion forgot about.

**Instance 1 — counting.** Tours per maker were counted through PostgREST on the
anon key, which serves `status = 'published'` only. 27 accounts came back with
zero tours and were reported as "content-less". A maker owning nothing but drafts
or `taken_down` work is indistinguishable from one owning nothing at all through
that view. `backend/remove_test_creators.sql` already warned about exactly this,
in capitals, after two failed pastes: *"Anything that reasons about 'does this
maker have tours' must query the table as `postgres`, or it is reading a filtered
view and will conclude the opposite of the truth."*

**Instance 2 — access.** Account deletion was going to set a departing maker's
tours to `taken_down`, on the reasoning that the rows survive and `purchases`
rows are untouched, so **buyers keep access**. They do not. The catalogue builder
and the tours RLS **both** filter `status = 'published'`, and a purchaser reaches
tour content through that same path — so an intact `purchases` row grants access
to something invisible. The reasoning even quoted the RLS filter and did not
follow it through. Caught by the build session (#853); had it shipped it would
have silently revoked access from the exact people the decision existed to
protect.

**The habit:** when a fact comes from a query, name the filter that query applies
and ask whether the conclusion survives it. *"These rows exist"* is not *"this
user can see them."* *"This query returned nothing"* is not *"nothing is there."*
Where it matters, read as `postgres` or through the same path the user's request
takes — and if you cannot, say the answer is bounded by the view you used.

### A dead database: read the SHAPE of the failure, not the calendar

**2026-09-14, ~11h45m of total outage.** Supabase returned HTTP 522 on PostgREST
*and* Auth. Cause: the Postgres instance was **`t4g.nano` — 512 MB RAM, shared
CPU** — with memory at 79%. `get_catalog()` builds the whole catalogue as one
in-memory document on every call, and the instance ran out of room.

🔴 **Two sessions independently guessed "egress restriction" and both were
wrong.** The dates fitted beautifully — the egress grace period had ended the day
before — so nobody checked. **The owner had been on Pro since 10 September**, four
days earlier, so that grace period could never have applied. A hypothesis that
fits the calendar is not evidence; the owner was one question away the whole time.

**The shape told the truth, and it was in hand before either guess:**

| Time | State |
|---|---|
| 01:07 | `get_catalog` → **57014 statement timeout** (queries ran, too slowly) |
| 01:18 | **522** on everything |
| 12:44 | still **522** |

**An administrative block flips instantly. Resource exhaustion decays** — slow,
then timing out, then refusing connections. When a failure *degrades* rather than
switching, look at capacity, not at billing.

### 🔴 Upgrading to Pro raises EGRESS, not COMPUTE

The trap that made this invisible. The project was upgraded to Pro on 10
September to fix the egress overage — and **stayed on `t4g.nano` throughout**,
because compute size is a separate per-project setting. The plan upgrade fixed
the billing problem and left the hardware that would cause the next outage
completely untouched.

**Nano → Micro was FREE**: both `$0.01344/hour`, and Supabase itself labels Micro
a "Free Upgrade". It doubles memory to 1 GB and swaps a *shared* CPU for a
dedicated 2-core. Measured immediately after: `get_catalog` **TTFB 2.3 s → 0.51 s**.
There was never a reason to be on Nano.

**Check compute size whenever the database is slow, and before assuming a
plan upgrade changed anything about performance.**

### The diagnostic order that would have got there in minutes

Three cheap reads, none of which needs the dashboard:

1. **Does *auth* fail too?** Auth is a separate service. Both down = the whole
   project, not one bad query.
2. **Does a 47-byte row count fail?** `?select=id&limit=1` with `Range: 0-0`
   cannot time out on query cost. If *that* fails, it is not the query.
3. **Then the dashboard**, in this order: **compute size and memory** first,
   disk second, billing last. Disk was 22% and the whole database 132.7 MB —
   ruled out in one glance.

⚠️ **And the same root cause had already caused a different incident.** The
8–10 September egress overage (11.82 GB against 5 GB) and this outage are both
`get_catalog` shipping the entire catalogue on every fetch. One design decision,
two production incidents, two weeks apart. Delta fetching is still not built.

### Searching changes the JUSTIFICATION even when it does not change the pin (2026-09-15)

After the rule-8d failure above, the remaining three coarse pins were searched properly. **None of
them moved — and the exercise was still worth it**, because "we could not find it" became "we
looked, and here is why the current point stands":

| pin | what the search found | why it stays |
|---|---|---|
| **Horizons**, Auckland | Neil Dawson's sculpture at **Gibbs Farm**, 2421 Kaipara Coast Highway — identified only because the creator is `@avant.arte`, an **art** account | the address geocodes to the farm **gate**, 979 m away; the sculpture sits on the property's highest point across ~400 ha. Moving the pin a kilometre toward the entrance would probably make it worse |
| **St Pancras International** | Wikidata's own point is `51.53, -0.125278` | that is **2 dp — coarser than the pin already is** |
| **Maiden Lane Estate** | Wikidata's own point is `51.542, -0.128` | **byte-identical to the pin**; nothing to change |

🔴 **Read the pin's own record before choosing search terms.** "Horizons" alone returns nothing
useful. The creator handle was the key: an art account means the subject is an artwork, not a
building. The maker, the city and the caption are free context and the search fails without them.

⚠️ **A large site has no single right point, and an address is not it.** A farm gate, a 400 m
station concourse and a 479-home estate all resist a single coordinate. For these, ~110 m is not a
defect to be fixed — it is the honest precision of the subject.

### 🔴 Rule 8d was violated the same day it was written (2026-09-15)

A session concluded three Tokyo pins could not be placed because **Wikidata had never heard of the
venues**, and told the owner so. The owner replied with Hotel Siro's address and:

> *"why weren't you able to find this?! it was practically the first result on google"*

**One web search found each of the three immediately.** This is the identical failure recorded in
CLAUDE.md automation rule 8d **earlier that same day**, when another session tried byFood (403),
Tabelog (403), Overpass (blocked) and Instagram embeds, declared 42 addresses unobtainable, and
searching the names found 41 of them.

🔴 **The failure is not "I used the wrong source". It is treating ONE source's silence as the
absence of the fact.** Wikidata not having a ramen counter is a statement about Wikidata. Rule 8d
exists precisely to stop that inference, and it was not applied because the search was never run
at all — the conclusion "not in the gazetteer" felt like a finished investigation.

⚠️ **And the outcome corrected the diagnosis too.** Once geocoded with GSI and ward-checked:

| pin | move | |
|---|---:|---|
| Hotel Siro | **203 m** | genuinely misplaced |
| The Bellwood | **4 m** | already correct, merely written at 3 dp |
| Gyukatsu Ichi Ni San | **0 m** | already exactly right |

So "these three are broken" was also wrong. **An unverifiable pin is not a wrong pin** — the same
rule #917 recorded when three "unresolvable" pins came out 11 m right, 220 m wrong and 100 m wrong.

⚠️ **A decimal-places heuristic has a blind spot worth knowing:** Gyukatsu's correct coordinate is
`35.702`, a genuinely round number, so it still reads as LOW-PRECISION after being verified. The
flag measures how a number is *written*, not whether it is *right*. Read the flag, then check.

### Stop at the cheap check when it is conclusive (2026-09-15)

Asked whether a migration had reached production, I ran the right query first:

```
GET /rest/v1/tours?select=id,related_tour_ids,authored_on&limit=1     ->  407 bytes, answered it
```

and then ran a second, redundant confirmation through `get_catalog_since` — **2,752,051 bytes**,
larger than a full `get_catalog`, in a session whose entire subject was egress. ~1.6% of a day's
allowance spent proving something already proven.

🔴 **The failure is not "I used an expensive call". It is "I kept checking after the question was
answered."** A second confirmation feels like rigour and is only rigour when the first check could
have been wrong. Decide what would change your conclusion *before* making another call; if nothing
would, the call is decoration.

⚠️ And **a delta call is not automatically cheap.** Its size is the size of everything that changed
since the cursor, so an old cursor after a backfill is the whole catalogue plus overhead. For
liveness use a sentinel cursor (131 bytes); for a row count use `content-range` (47 bytes); for
"does this column exist" select the column directly.

## 7. Shell and environment

**`pkill -f <script>` kills your own shell** (exit 144) — the pattern matches the wrapping
`bash -c` command line, which contains the script name. Use
`pgrep -f "[p]attern\$" | xargs -r kill`.

**A background script's `echo` to a redirected stdout is block-buffered**, so a poll loop looks
stalled at one line while running fine. Append to a log file per iteration.

**`git fetch` and `scripts/session-start.sh` exceed the 120 s tool timeout here.** Run them in
the background and read the output file.

**A missing trailing newline silently drops the last line.** `'\n'.join(files)` fed to
`while read -r f` loses it — a gh-pages tree came out 44 files instead of 45, and a hero would
have shipped as a 404. `grep -c .` and `wc -l` differ by exactly one when this is present.

**`curl` to `api.github.com` returns nothing from the shell in a web session** — a polling loop
looks like it is working and reports nothing. Poll through the MCP tools; but note `actions_list`
on a busy workflow returns ~420 KB and blows the tool budget, so use `list_workflow_jobs`.

**`urllib` fails SSL verification on the owner's Mac.** Use `curl`.

**A browser user-agent trips Instagram's challenge page from a datacenter IP.** curl's default
and the tool's own UA both work. **A control that differs in one header is not a control.**

🔴 **A probe that throws the response away still pays for it, and `-o /dev/null` hides that from
you.** A liveness check added to `scripts/session-start.sh` called `get_catalog` four times per
session purely to read a status code and discarded ~44 MB of body every time — on a script every
session runs. **The owner was emailed for exceeding the Supabase free egress quota the same day.**
Before adding any repeated network check, ask what the *response* weighs, not just how long it
takes: `curl -w '%{size_download}'` answers it in one call. The flags that make a status probe
cheap are `--compressed --max-filesize 2000`; ⚠️ **curl then exits 63 on success**, so read
`%{http_code}` and never the exit code. `CLAUDE.md` § Egress has the per-question cost table.

---

## 8. Git, gh-pages, CI, builds

**A merged PR is finished.** Restart the branch from the latest `main`; never stack new commits
on merged history.

🔴 **Branch from `origin/main`, never the local `main`** — this checkout is shared and routinely
behind, and a stale base reaches Apple. On 2026-09-19 a branch cut from a local `main` still at
`MARKETING_VERSION = 1.1.2` built and signed fine, then died at upload with **90186, "train 1.1.2
is closed"** — 1.1.2 had released on 2026-09-14 and `origin/main` was already 1.1.3. **The fix is
`git rebase origin/main`, never a hand-edited version**; see the 90186 entry below for why that
rejection is also evidence the version shipped.

**A conflicted PR triggers NO CI at all** — 0 check runs. Read `mergeable_state`; don't wait.

**Resolve a `Tours.json` conflict by taking `main`'s file and re-running the idempotent
assembler** — never hand-resolve. When `Tours.json` *auto*-merges, that is the case that most
needs checking: discard the auto-merge and redo it the documented way.

**Don't restore a shared doc wholesale.** `git checkout <sha> -- <docs>` silently discarded
another PR's entry in the same file. Re-apply doc edits onto `main`'s file with **targeted
anchored replacements**, and assert each anchor matches exactly once.

**Check `archive/` for the next free handoff suffix before writing**, and expect to renumber on an
add/add collision — five happened in one afternoon. A parallel session once **overwrote** a
handoff wholesale with no conflict at all, because their branch predated the file's creation.

**gh-pages, from a web session:** a full `git fetch` times out; use `--filter=blob:none`. Then
`git add`/`diff`/`checkout` all **hang** in a `--no-checkout` worktree (every index op tries to
fetch missing blobs). **Use pure plumbing**: `read-tree` into a temp `GIT_INDEX_FILE` →
`hash-object -w` → `update-index --cacheinfo` → **`write-tree --missing-ok`** → `commit-tree`.
Never `git add -A` there — every file reads as an unstaged deletion.

**Re-read the remote head in the same command as the push** — it moves within the hour on a busy
day. Then verify the tree diff is exactly N additions, 0 deletions, nothing outside the expected
directories, and afterwards **hash the live bytes against the uploaded blob SHAs**. A 200 is not
proof; a 404 during a slow deploy is not a failed upload; and a **cancelled** Pages deploy is not
a lost upload (each commit is an ancestor of the next).

🔴 **Deleting a gh-pages branch takes the whole Pages site down**, and a blobless clone **cannot
push it back** (it lacks the 4 GB of blobs). Recover with `gh api -X POST .../git/refs`. Guard
every push refspec on a non-empty variable; prefer the Contents API for single-file edits.

**Archive from a clean checkout, then grep the binary.** Build 47 was poisoned by an uncommitted
local edit from a parallel session pointing the catalog at a dead URL — it shipped, and silently
stopped receiving content. `.xcodebuildmcp/config.yaml` is now gitignored for the same reason: no
defaults fails loudly, a wrong path fails silently.

**Build numbers are `github.run_number` — shared across every branch and session, and cannot be
predicted.** Read it back after dispatching. Gaps are normal (failed runs increment it too).

**The version train closes the moment Apple approves it.** Build 140 compiled and signed cleanly
and died at upload with `90186 Invalid Pre-Release Train`. That rejection is *evidence the version
shipped* — in a web session with no App Store Connect key it is the only such signal.

**A "Set up job" failure is not the certificate cap.** The cap fails later, at Archive, naming
certificates. `scripts/revoke-dev-certs.py` now frees slots automatically — but `key_path` must be
called first, or it runs before the key exists and silently frees nothing.

**Build notes must be plain ASCII.** One `✕` made a build upload, process, and *then* go red seven
minutes later at the changelog step — live and installable while the run was red.
`scripts/ascii-build-notes.py` transliterates.

**Never classify a CI error on a bare word.** A retry loop matched `processing` inside fastlane's
own **option list** and buried the real error for 20 minutes. Check permanent signatures first and
**default to permanent**.

**Read the whole CI log for `error:`** — one build had exactly one error line in 95,219 characters,
and the failure summary names the file but never the reason.

---

## 9. App code

### A visual unit on screen must be tuned in SCREEN units (2026-09-19)

🔴 **Map clustering bucketed pins into a lat/lon grid of "20 cells across the region".
On a 390pt phone that is a ~20pt cell, under a badge 36–44pt wide** — so neighbouring
badges necessarily overlapped, and the defect grew with the catalogue until Manhattan was
unreadable at ~3,600 markers. No value of `cellsAcross` fixes it: a grid bucket answers
"same cell?", never "how far apart on screen?", so two pins a few points apart either side
of a cell line stayed separate at **every** zoom.

**The tell was already in the repo.** The maker map passed `cellsAcross: 12` with a comment
explaining that 20 cells across a *short* frame span too few points. A constant that has to
be re-tuned per surface is a unit error, not a taste setting. The fix (#1010) was greedy
radius clustering in `MKMapPoint` space with the radius **in points** — one number that
means the same thing on every surface, so both maps deleted their local tuning.

**Degrees are not screen distance.** `latSpan/20 × lonSpan/20` cells are not square on
screen and stretch with latitude; Mercator map-point distance is proportional to screen
distance at any zoom, which is the only reason a points radius is meaningful.

**Keep what the old design was protecting.** The grid's absolute (lat 0, lon 0) origin
existed so a pan could not re-key a bucket and churn SwiftUI's annotation IDs. The
replacement earns the same property differently: quantise zoom to half-steps, cluster the
**whole** set, and cull the **output** to the viewport. Cluster *before* culling and a
marker entering the window can re-form clusters mid-pan — the exact bug the original
comments were written about.


🔴 **The mini-player and tab bar are in a window ABOVE the app, so anything the main window
presents goes behind them — present it from THEIR window instead of hiding them.**
`BottomModuleWindowController` installs a `PassThroughWindow` at `windowLevel = .normal + 1`
deliberately, so ordinary modals slide up behind the persistent player the way Apple Music's do.
A `.sheet` from a main-window view therefore has its bottom 126 pt covered — and for the filter
panels that took the floating commit pill with it.

Hiding the bars for the duration looks like the fix and is not. It has now been tried and
reverted **twice**: session 24 with `PlayerView` (*"hiding the module around the transition made
it worse; presenting from this window was the fix"*), and session 160 with the filter panels,
where the owner filmed the result — at 60 fps the module vanished in one frame and the sheet's
top edge did not enter for **another ~130 ms**, so the transition ran map → hole → sheet. The
withdrawal fires on a state change; the presentation does not begin for an eighth of a second,
and no delay tuned by hand is a fix for that.

**What presenting from the module's window costs:** the state the modal edits has to be reachable
from that window, which means `AppSharedState` (the object injected into both) rather than
anything `ContentView` owns, such as `HomeSharedState`. That is a real refactor of where state
lives, and it is the whole trick — session 160's first attempt talked itself out of this fix by
asserting the state "is not open to a sheet bound to the row's own state", which was simply
untrue once the state moved. `PassThroughWindow.hitTest` already claims every touch while that
window has a presented view controller, so interactivity needs no work.

⚠️ **And `hidesBottomModule` is a plain Bool, not a count.** Every owner it gains is a new way
for the bars to go missing for a whole session — a failure this app has shipped three times.
Deleting an owner is worth more than it looks.


🔴 **A cross-origin iframe cannot fail in a way `WKNavigationDelegate` can see, so a WebView
embed needs a POSITIVE signal and a deadline — never a failure callback.** `LinkEmbedView` hands
WebKit its shell with `loadHTMLString`, so the main frame never touches the network; the player is
in a cross-origin iframe we may not script. It had a `navigationDelegate` the whole time and still
rendered **a black rectangle forever** whenever TikTok, Instagram or YouTube was unreachable — the
state every one of the catalogue's link pins is in on a network that blocks them, mainland China
included. The only signal available is the `<iframe>` element's own `load` event (it fires for a
cross-origin child even though the contents stay unreadable), relayed from our own shell over a
script message handler. Failure is then the **absence** of it within a deadline (#785).

**When a verdict is inferred from a timeout, make being wrong cheap — put the message in an
OVERLAY over the thing that is still loading.** The deadline is a guess, and the only regression
route is a *false* failure: the message over a player that works. Keeping the player mounted
underneath means a slow-but-working network that arrives late clears the message by itself, so the
exact number stops being load-bearing. Swapping the player out for the message would have made a
guess final. Same shape as `withdrawsBottomModule`'s `@unknown default`: decide which of the two
failure directions you can afford, then make the mechanism land on it.

**Say what you observed, not what you infer caused it — in UI copy too.** We can see that a player
did not load. We cannot see *why*: a country or network that blocks the platform, captive-portal
wifi, a post gone private, the platform down. The copy says "can't be reached" and never "is
blocked", and the unrecognised-host case names no platform at all. This is § 2's rule pointed at
the viewer instead of at the owner.

🔴 **Never put a side effect that must run in a window a modal can cover.** SwiftUI can stop
delivering updates to a hierarchy behind a modal presentation, so the write lands and the
`.onChange` never runs. This has produced: a dead tab bar, a dead place pin (#532), a dead X
(#535), and a tour layer that stayed on screen after `dismiss()`. Presenters carry a
`performDismiss` closure and tear their own layer down.

**Derive once, use many.** SwiftUI re-evaluates a computed property at **every reference**. Paid
for four times: `toursInViewCount` twice per header; `savedTours` three times per row;
`rankedTours(at:)` three times per row; and `filteredTours` **1,419 full catalog scans for one
keystroke** (2 million comparisons). Also `railList` — 13 shelves × the whole catalog, twice per
render, on the frame the map lands.

**A performance comment is a claim with an expiry date.** *"Cheap for V1's small catalog"* was
true once and had silently stopped being true at 1,512 tours.

**`.automatic` map camera over EMPTY content is a synchronous layout loop** — it resolves, writes
back through the binding, re-renders, resolves again. It hung the app until the watchdog killed it,
through **seven builds and six wrong diagnoses**, because a crash stack only shows where a spin is
standing. **Diff the working path against the broken one before trusting any stack.**

**`withAnimation` does not step a plain `Double` through intermediate values** — SwiftUI
re-renders once with the value already at its end state, so every `delay` and `window` computed
from it is evaluated at 1 and thrown away. Tick the value at display rate.

**An optional `@Environment` lookup turns a dropped injection into a silent dead control.** Two
UIKit layers never injected `PlacePresenter`, so a place pin did nothing with no error anywhere.
Give the nil branch a debug `assertionFailure`.

**Two `.fullScreenCover` modifiers on one view: the second is silently ignored.**

**A paged `TabView`'s `UIPageControl` spans the full width of its dot strip** and hit-tests above
page content — a button drawn there renders, sits in the accessibility tree, and does nothing.
**Presence in the accessibility tree says nothing about hit-testing; probe the action.**

**`GeometryReader` reports safe-area insets of ZERO once `.ignoresSafeArea()` is applied** — read
them from the window.

**`.offset` does not move a `.background`.** It is a rendering transform; the layout frame stays.

**A control that visibly does nothing is worse than one that is absent.** Hide it, don't disable it —
unless the owner has ruled otherwise (list bookmarks are greyed deliberately).

**A rule enforced in the action row is not enforced until the overflow menu enforces it too.** The
paywall shipped with Download and Group Listen ungated in the `•••` menu — one buyer could have
handed a full tour to a whole group.

**Configure the audio session at init; activate it only when playback starts.** `setActive(true)`
is what seizes audio focus, so activating at launch stopped the user's Spotify before any tour ran.

**A fixed hero height crops differently on every phone** — 320pt against a width that varies meant
8% of the frame lost on one device and 23% on another, and each device looks self-consistent.

---

## 10. Working with the owner

### Any keep-or-pull question about a picture leads with the picture

🔴 **Paid for twice.** Session 138 hit it on the `@notbadgalriri__` Rednaxela Terrace hero and wrote
the rule down; it was then repeated on 2026-09-02 with the In's Point and Hong Kong Railway Museum
heroes.

Both times the question went to the owner **in prose** — *"two one-line hero swaps sitting ready if
you'd rather have the naming than the framing"* — and both times the answer was a version of
***"i dont understand, more clearly pls"***. Reasonably so: it turned on jargon that means nothing
outside this repo (hero, place page, framing-vs-naming), and it described two photographs the owner
could not see.

**What settled it in a single exchange:** two labelled side-by-side comparison images, one per place,
each panel captioned `A — USING THIS NOW` / `B — THE OTHER OPTION`, one plain line per panel saying
what that frame does and does not show, sent with `SendUserFile`, plus an explicit *"you don't have
to do anything"*.

⚠️ The same shape applies past images: **if a decision turns on something the owner can be shown,
show it.** A description of a picture is not a picture, and a paragraph of internal vocabulary is not
a question.



- **Not a Terminal user.** Claude does all shell and git work. Supabase/SQL/infra needs
  copy-paste-ready blocks and click-by-click dashboard walkthroughs.
- **Show, don't describe.** *"can you show me first before i decide?"* Mockups and rendered images
  settle UI and image questions in one round that prose cannot settle in three. A keep-or-pull
  question about a picture leads with the picture — an early attempt in prose got *"i dont
  understand what you're asking me."*
- **A settled decision stays settled.** Weak heroes, the Yankee Stadium carriage, the Coca-Cola
  ad, Casa Lleó Morera's interior hero, the Ministry of Enterprise photograph, Gilder Center
  staying separate from AMNH, paid partnerships (*never flag one again*). An audit will re-flag
  these; honour the decision rather than "fixing" it.
- **Check what a flagged discrepancy CHANGES in the shipped fields before raising it.** Two
  sources disagreeing is only a decision if a field we author has to pick one.
- **A one-time "cut a build" is not standing permission.**

## Never hand the owner a rendered preview beside a paste-ready template

Session 150. A branded Supabase email template was delivered as two artifacts: a *rendered
preview* (sent first, with `{{ .ConfirmationURL }}` swapped for a literal `token=EXAMPLE` so it
would display) and the paste-ready code. The preview was the more obvious thing to copy, so it is
what reached the dashboard — and every confirmation link in every signup email pointed at a dead
placeholder. Five test signups and four wrong theories (scanners, prefetch, expiry) went by before
the owner pasted the link and it read `EXAMPLE`.

**Send one artifact.** If a preview genuinely helps, make its placeholder impossible to ship
(`DO_NOT_PASTE_THIS`) and say in the same breath which of the two is the deliverable.

The same shape applies to any copy-paste handoff — SQL, Edge Function code, DNS values. The moment
there are two plausible things to copy, the wrong one will be copied eventually.

## Confirm an auth state against the database, not against the page

Same session. The final, working confirmation *looked* like a failure: the browser showed
`#error=...otp_expired`, because confirmation links are single-use and the screenshot was a second
click — the first had already succeeded. Reading the page would have sent us back to debugging
something that was fixed.

A signed-out check needs only the publishable key:

```bash
curl -sS -X POST "https://<ref>.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: <publishable>" -H "Content-Type: application/json" \
  -d '{"email":"...","password":"..."}'
# access_token present = confirmed;  "email_not_confirmed" = not
```

This is the live-systems-over-appearances rule in a new place: **ask the system that holds the
truth.**


## Never rebuild a catalogue function from a committed file (2026-09-10)

`drop_transcript_from_catalog.sql` set out to remove one field from the
catalogue payload. It was written by copying the body of `get_catalog_core()`
out of `backend/restore_catalog_keys.sql` and deleting one line.

That body was **four days out of date at the time it was committed, and two
weeks out of date when it was copied.** `split_link_pins.sql` had renamed the
builder aside to `get_catalog_core_base()` and turned `get_catalog_core()` into
a wrapper that lifts link pins out of `tours` into their own `linkPins` key.
Retyping the old body reverted that: the live catalogue went from
`tours 1553 / linkPins 1700` to **`tours 3253 / linkPins 0`**, which fails the
whole catalog decode on every build predating `TourKind.link` — silently,
because `RemoteCatalogLoader`'s `try?` reads a throw as a failed fetch and keeps
its last good copy.

**The rule: transform what the live chain returns; never retype it.** A wrapper
cannot lose a key it never mentions. The repaired version calls
`get_catalog_core_base()` and strips one key on the way past, so every other
key — including ones added after it was written — rides through untouched.

Three things made this survivable rather than expensive, and all three are
worth keeping:

- **Counting the live payload immediately after applying SQL.** `tours 3253`
  against an expected 1553 was visible in the first check, about a minute after
  the paste. "Success. No rows returned." said nothing.
- **The migration now verifies its own shape.** It ends in a `do $$` block that
  raises if `linkPins` is empty, if a pin is still inside `tours`, if `places`
  is empty, or if a transcript survived. A migration that cannot fail loudly is
  a migration you have to remember to check.
- **The guard was widened to the layer that was actually hit.**
  `check-catalog-keys.py`'s audit only inspected `create or replace function
  public.get_catalog()`. The destructive statement was against
  `get_catalog_core()`, one layer down, so the file passed the audit that exists
  for precisely this. It now audits both, and `restore_catalog_keys.sql` carries
  the `NO LONGER SAFE TO RE-RUN` banner it had always warranted.

⚠️ **The generalisation is bigger than SQL.** Committed files record what was
true when they were written. That is the same failure this project has paid for
repeatedly with perishable facts in `CLAUDE.md` — here it just arrived wearing
a `.sql` extension.

## Measure the payload at gzip LEVEL 1, and prose does not shrink (2026-09-10, corrected 2026-09-14)

Two payload cuts were nearly decided on raw byte counts. Measured on the live
payload:

| field | raw | gzipped (what is billed) |
|---|---|---|
| `stops.transcriptText` | 34.8% | **37.5%** |
| `longDescription` | **29.4%** | **43.9%** |

The transcripts were removed (nothing reads them; 41.4% off the actual wire
bytes, 3,698,842 → 2,167,209). `longDescription` is **kept** — it is rendered by
`TourDetailView` and searched by `SearchView` — but on being load-bearing, not
on being small.

🔴 **This entry said `longDescription` was 8.2% gzipped, and that was wrong by a
factor of five.** Re-measured on 2026-09-14 by two independent methods (delete
the key; keep the key and blank the value) at three compression levels, it is
**43.9%** — the single largest thing the catalogue sends. Part of the raw shift
is legitimate: these shares were taken while transcripts were still on the wire,
so removing 37.5% of the payload raised everything else's share. **That explains
13.3% → 29.4% raw. It does not explain 8.2% → 43.9%**, which was simply a bad
measurement that then sat in two files being quoted as settled.

🔴 **And the heading this entry used to carry — "raw sizes overstate text
badly" — is BACKWARDS for prose.** It holds for repetitive text like the
transcripts. `longDescription` is 29.4% raw and 43.9% compressed: its share went
*up*. The catalogue is otherwise UUIDs, repeated JSON keys, coordinates and URLs
off a single host, all of which gzip flattens almost to nothing, while distinct
prose (1,553 of 1,553 tour values are unique) survives compression nearly
intact. **Prose is the part that is left after gzip, not the part that
disappears.**

**Method — and the method is where the error came from.** Save one payload with
`Accept-Encoding: gzip` (never `--compressed`, which decompresses and reports
the raw figure), then in Python remove one key at a time and re-compress. But
⚠️ **`gzip.compress(...)` defaults to LEVEL 9 and PostgREST serves LEVEL 1.**
Level 9 understates the bill by ~15% and, far worse, *mis-ranks* fields —
high-entropy prose compresses much better at 9 than at 1, so measuring at the
default makes exactly the fields that dominate the bill look cheap. Calibrate
first: recompress the saved payload at each level and take the one that matches
the bytes actually served.

```python
def gz(o):                                    # what is billed
    b = io.BytesIO()
    with gzip.GzipFile(fileobj=b, mode="wb", compresslevel=1, mtime=0) as f:
        f.write(json.dumps(o, separators=(",", ":"), ensure_ascii=False).encode())
    return len(b.getvalue())
```

⚠️ **Knowing a field is 44% is not permission to drop it.** `longDescription` is
**non-optional** in `Models/Tour.swift`, and `ToursData` decodes element by
element — so a payload without it decodes `tours` as ZERO elements, succeeds,
and `RemoteCatalogLoader` overwrites the good cache with the empty result. The
size of a field and the safety of removing it are unrelated questions.
`docs/delta-catalog-fetch-design.md` § 4.2 has the full walk-through.

## A title rule cannot find a place; only the coordinate can (2026-09-11)

`check-place-candidates.py` matched two entries as the same site when one title's meaningful
words contained the other's. That rule is precise and it is **structurally blind to the
commonest shape in this catalogue: one site that two entries call by two unrelated names.**

*Hook & Ladder 8* and *The Ghostbusters Firehouse* are one firehouse **4 m** apart and share
not one word. So are *Britain's Oldest Door* and *The Tomb of Elizabeth I* (both Westminster
Abbey, 5 m), *Chelsea Market* and a pin about Oreos (the same Nabisco building, 8 m), and
*The Federal Reserve Bank of New York* and *$500 Billion of Gold Under 33 Liberty Street*
(0 m). No string comparison will ever reach any of them.

Adding a **TIGHT** tier — within 25 m, whatever the titles say — found **151 pairs, 82 of
which no title rule could have produced**, and **55 of which share no word at all**. The
sweep it produced is `docs/place-candidates-260911.md`.

🔴 **The lesson generalises past places: when the thing you are identifying is physical,
match on the physical fact and use the text only to explain the match.** The title was never
the evidence — the coordinate was, and the title was doing the work because it was easier to
compare.

⚠️ **And the converse still holds, which is why the tier does not auto-create anything.**
Proximity is evidence, not proof. Two classes of false positive are real and permanent: a
dense block of separate venues (Hong Kong's restaurant pins are 10–20 m apart and are
different restaurants), and **coordinates rounded to four decimal places — ~11 m — which can
round two genuinely separate sites to within a few metres** (El Retiro sits 8 m from the
Puerta de Alcalá). Exact coincidence exits non-zero; everything looser is for a human.

## Joining a place means MOVING the entry, not just listing it (2026-09-11)

A place's membership looks like a list you append to. It is not. `Place.swift` makes a place's
identity **exact coordinate equality**, and `validate-tours` enforces it at **1e-9 degrees**:

```
place Griffith Observatory: member not on the place coordinate
```

🔴 **All 362 existing place members sit EXACTLY on their place — 362 of 362.** That is not a
coincidence, it is the schema. So adding an entry to a place also means **snapping that entry's
stop coordinate (and its centroid, or the centroid falls outside the stop range) onto the
place**. Session 157 added eight ids without snapping and got exactly eight errors.

**Check the move against the entry's own `triggerRadiusMeters` before making it.** All eight
moves there were 0.6–20.9 m against a 30 m radius, so nothing changed about when any tour
fires — but a larger move would silently redefine where a tour triggers, and nothing else in
the pipeline would object.

⚠️ **This is also why a place candidate is never free.** A sweep can say "these two entries are
4 m apart"; turning that into a place means choosing the one true coordinate and moving
everything onto it. That is an editorial decision, which is why nothing auto-creates one.

## A literal `|` in a title silently corrupts a markdown table (2026-09-11)

24 entries in this catalogue carry a pipe in the title — the bilingual convention,
`Museum SAN | 뮤지엄 산`, `Tai Kwun | 大館`. Dropped unescaped into a markdown table it **opens an
extra column and shifts every cell after it in that row**.

🔴 **It does not look broken.** There is no error and no ragged output — the row renders as a
perfectly plausible table with the wrong data in the wrong columns. It was caught here only by
counting columns, not by reading the page.

Two habits close it, and `scripts/make-place-menu.py` carries both:

- Escape once, centrally (`esc()`), on **every** field that reaches a cell — the title *and* any
  name interpolated beside it.
- **Count the columns before writing**, and refuse the write when they disagree. Removing `esc()`
  makes that guard exit 2 with `inconsistent table columns [4, 5, 6, 7]`, which is how it was
  proved to work rather than assumed.

⚠️ The same hazard applies to any generated markdown built from catalogue text — titles,
`shortDescription`, maker display names. It is not specific to places.

## A generated menu's numbers renumber — never record a decision by label (2026-09-11)

`docs/place-candidates-260911.md` numbers its open groups `P1…Pn`. **Those numbers are positions
in a filtered, sorted list, not identities.** Create a batch of places and every remaining group
shifts up.

🔴 **So a decision read back by label after the batch lands names a different site.** That happened
here: 26 places were created, then the owner's declines were looked up by their `P` numbers — and
12 of the 19 labels no longer existed while the other 7 had silently moved onto other groups. It
was caught only because the missing-label count was printed.

**Record a decision by the thing itself** — here, the frozen set of member titles — and write it
from the list the person actually answered, not from a fresh derivation. `DECLINED_GROUPS` in
`scripts/make-place-menu.py` is keyed that way for exactly this reason.

⚠️ **The same run turned up a second version of the fault**: the script's own summary line counted
holds with `DECLINED` (which only knows groups attached to an existing place) rather than
`declined_reason()`, so it reported **28 open groups when 4 were open**. A count and the document
it describes must be derived the same way, or the summary quietly contradicts the table under it.

## An upsert-only seed cannot delete — a dissolved place leaks (2026-09-11)

🔴 **`seed_from_toursjson.py` could create and update a place but never remove
one.** So a place deleted from `Tours.json` survived in the database as an
**empty row** — it kept its name and its point on the map while owning nothing.

Splitting the Jordaan out of `Westerkerk` dissolved that place in the catalogue
(one entry describing Westerkerk is not a place). The catalogue then held
**266** places; the live count read **267**, with **0 tours** pointing at the
orphan.

⚠️ **Nothing downstream objects, which is the whole danger.** The row is valid
SQL, the validator only ever reads `Tours.json`, CI is green, `get_catalog`
serves it happily, and the only symptom is a number that is one too big —
against a count check the runbook *relies on* to confirm a publish landed. Had
the Jordaan split not changed the total, the leak would have been invisible.

**What made it findable:** the merge was verified against the live database by
polling the cheap 47-byte count, and the number simply disagreed with the
catalogue. **Verify the count, and when it disagrees, find out why rather than
assuming a race.** Two earlier readings were legitimately stale (the seed takes
up to fourteen minutes), so "wait longer" was the tempting answer and would have
been wrong.

The fix mirrors a comment already in that file: the `place_id` reset was
documented as *load-bearing* because membership must be able to **shrink**. The
same is true one level up — the set of places must be able to shrink too. The
prune is emitted **after** the `place_id` reset, because `tours.place_id`
references `places`: clear the links, then delete.

**The general rule: any derived table seeded by upsert needs a matching delete,
or it can only ever grow.** Check for that the first time you delete a row from
the catalogue rather than adding one — deletion is the rare operation here, and
the path is correspondingly untested.

## A filter's green count is not a verdict — it fails in BOTH directions (2026-09-11)

`scripts/triage-account.py` sorts a creator's posts by reading their captions. The temptation is
to trust its SINGLE ("good to pin") count and mint those. Do not. Measured on `@jamiepeva`, in a
single run:

- **It over-accepted.** 9 of 11 posts came back SINGLE; exactly **3** were pinnable. The others
  were a reply-to-commenters video, a press-mention post, a property listing, and a post about a
  Metro station that was **never built** — a video with no place to pin at all.
- **It over-rejected, in the same run.** It binned a post captioned **`📍 Mount Vernon, Virginia`**
  as non-place content, because "anniversary" had been added that morning to catch a creator's own
  channel milestone and the caption read "celebrating the United States' 250th anniversary". It
  was the best post in the batch and the tool threw it away.

Both were fixed — an explicit location marker now clears THIN outright, and "anniversary" must
name the channel's own — but the fixes are not the lesson. **A caption is evidence, not a label**,
and every keyword added to catch one failure creates the other. Over-accepting is the safer
setting **only because a human reads every candidate before anything is minted.** Skip the reading
and that safety is gone in both directions at once: junk ships, and the best post is silently
dropped where nobody ever sees it was considered.

⚠️ The over-rejection is the dangerous half, because it is **invisible**. A bad pin gets noticed on
the map. A good post filtered into THIN leaves no trace anywhere.

Corollary for anything of this shape: when a heuristic changes, re-run it against a real batch, not
only its self-tests. Three of this tool's patterns exist because a live run contradicted what the
tests said was fine — including one that read `🙌 Stay curious, my friends!` as naming a place
called **Stay**, because a leading emoji shifted which word looked sentence-initial.

## What a bare social handle can and cannot reach (2026-09-11)

Measured from a cloud session, so nobody re-derives it or over-promises to the owner:

| | |
|---|---|
| `tiktok.com/@handle` | 200, 371 KB, **zero** video ids, 25 mentions of captcha |
| `tiktok.com/embed/@handle` | 200, **14 video ids**, no captcha — the usable route |
| `instagram.com/<handle>/` | 302 to login |
| `instagram.com/<handle>/embed/` | 200, a Facebook shell, **zero** post links |
| `instagram.com/api/v1/users/web_profile_info` | **401 `require_login`** |
| `youtube.com/@handle` | 200, carries `channelId` → RSS (~15 newest) |

A bare handle reaches **~14 recent posts on TikTok, ~15 on YouTube, and none on Instagram**.
⚠️ A `cursor` or `count` parameter does **not** deepen the TikTok embed — tested on two creators,
both capped at 14. Do not add one thinking it was missed.

🔴 **For Instagram the gap is the platform's, not ours.** Basic Display died December 2024, the
Graph API only reaches accounts that authorised *you*, and Meta's oEmbed is per-post and lists
nothing. There is no third-party post-listing route at all. Say that plainly rather than implying
more effort would help — and note Instagram is the *largest* platform in this catalogue (216 of
347 pinned creators), so this is the main constraint on link-pin work, not a footnote.

Web search was tried as a second channel. It is a **lucky dip, not an enumerator**: one query
returned 8 real TikTok URLs spanning 2021–2026, while topical follow-ups returned TikTok
*discover* pages and other creators entirely.

## A place propagates a coordinate error — check the place, not just its members (2026-09-11)

🔴 **`Habitat 67`'s PLACE sat 363 m from the building, and both its members sat
with it.** A place's coordinate *is* its identity, so every member is pinned to
it — which means **one wrong coordinate silently relocated two entries, and
neither could disagree**: sitting exactly on the place is what membership
requires. The validator was satisfied. The sweep was satisfied. Nothing in the
pipeline is capable of noticing.

The only reason it was visible at all is that a **third pin, outside the place**,
sat 10.9 m from the real building. Without that pin the place would have stayed
wrong indefinitely.

⚠️ **So a place is a way to PROPAGATE a coordinate error, not only a way to group
entries.** Check a place's own coordinate against the source, not only its
members against the place — the second check passes by construction.

Found the same day as three plain entry defects (Gamble House 343 m, the Noguchi
Museum 497 m), all by the same method: **ask which member OSM agrees with.** In
the 26–49 m band that question showed the link pin sitting on the feature in
**fifteen of seventeen** groups, with the Atlas tour off — pins are geocoded per
link at import, while tours carry coordinates typed once and never checked. A
4-decimal coordinate is the signature.

⚠️ **And check a "false positive" as hard as a real one.** `Lloyd's of London /
The Leadenhall Building at 7 m` was called an obvious two-buildings-across-a-
street false positive and recommended for decline. It was a defect in disguise —
the Lloyd's tour was on the Leadenhall Building — and **declining it would have
buried the bug under a decision**, where nothing would look again. From the
titles, a wrong coordinate and a genuine neighbour are indistinguishable; that is
the whole reason the tight tier is distance-only.

⚠️ **Before "fixing" an inconsistency, check whether it is a convention.** The
Gamble House tour says `city: Los Angeles` while its pin says `Pasadena`, and the
building is in Pasadena. That maker files **all 42** of its tours as Los Angeles,
so changing this one would make it the sole exception. Flag, don't fix.

## Merge a green content PR immediately — waiting costs a rebuild each time (2026-09-12)

[#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) went green on **8 September** and
was not merged until **12 September**. In those four days `main` moved **72 commits and 473 link
pins**, and the branch had to be rebuilt **eight times** — seven while the session was still live,
once more to land it.

**Nothing went wrong with the content**: every rebuild reproduced the identical diff (2,483
insertions / 0 deletions), overlap re-verified at 0 on every axis each time, and the final
re-check found **0 repeats** among the 473 pins that had landed. The cost was pure churn — and
each rebuild is a fresh chance to hand-resolve an 11 MB JSON wrongly.

- **The rule: when CI is green on a content PR, squash it in that turn.** Do not report "I'll
  merge on green" and then wait on a further check, a further question, or a further batch.
- **A stale branch is not a safe branch.** The longer it waits, the more of the merge is
  conflict resolution rather than content — and the docs conflict every time, because every
  session edits the same `CLAUDE.md` / `STATUS.md` / `archive/README.md` header lines.
- **Corollary on handoff filenames: pick the suffix at push time, not at write time.** This
  session's handoff was renumbered four times — `-260907-3` → `-4` → `260908` → `260912-2` — as
  parallel sessions claimed each one. Re-check immediately before pushing, and expect to renumber
  on the merge anyway.
- ⚠️ **The four-day gap also invalidated the whole structure the docs were written for**:
  `CLAUDE.md`'s dated Current State blocks were moved to `archive/CURRENT-STATE-HISTORY.md` on
  2026-09-08, so the entry had to be re-homed. **Re-read the file you are editing after any long
  gap; the convention may have changed under you.**

## A "first/new/Nth" claim has an expiry date — re-derive it at merge, not at write (2026-09-12)

[#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) shipped documentation saying
**"Puerto Rico is the catalogue's 59th country."** That was **true when it was written on
7 September** — the catalogue had no Puerto Rico at all — and **false by the time it merged on the
12th**, because another session landed 6 Puerto Rico entries during the four-day wait. Measured
against the parent of the batch's own squash commit: **64 countries before the merge, 64 after.
It added none.** A parallel session had meanwhile claimed the 59th slot for **Tanzania**, so two
merged PRs each called a different country "the 59th".

- **The rule: any superlative or ordinal about the catalogue — first, new, Nth, largest, only —
  must be re-derived immediately before merge**, not carried forward from when the work was built.
  The counts are cheap; the claim is not self-correcting.
- **This is the same class as the Key-facts line that has gone stale eighteen times**, and the fix
  is the same: re-derive from the merged file, never quote a number written earlier.
- ⚠️ **It is also a second-order cost of not merging promptly** (see the lesson above). A batch
  merged the day it goes green cannot be overtaken this way.

## A splash animation is only real if it is on screen, on a layer, and verified at real timings (2026-09-12)

Restoring the splash's breathing brass circle (#836) took three TestFlight builds, and each device
round broke for a reason the simulator check before it had hidden.

- 🔴 **SwiftUI `onAppear` is not "on screen".** It fired **27 ms** after launch; the splash's first
  frame reached the screen **~4.9 s** later, because the app behind it was still being built. A
  minimum on-screen time counted from launch was spent behind iOS's static launch picture, and the
  breath showed for ~0.77 s — the owner saw none. Time anything the user must *see* from its first
  **drawn** frame (`SplashDiscView`'s `CADisplayLink` tick).
- 🔴 **An overlay cannot draw until the view under it is built.** With `ContentView` mounted on the
  first frame, the whole map/drawer build had to finish before the splash could appear.
  `LaunchDeferredContent` draws the splash first and mounts the app one drawn frame later.
- 🔴 **Anything that animates during launch belongs on Core Animation.** The main thread is blocked
  for seconds there; a SwiftUI-driven fade was measured holding one value for 0.4–0.6 s. A layer
  animation is run by the render server and keeps going.
- 🔴 **One view breathes, a different view zooms.** Growing the breathing layer — even with a 50 ms
  "settle to solid" animation — filled the screen at ~25% brass, and the owner noticed the lost
  zoom. Swap to a solid view at hand-off, and hide the swap by timing it on the way INTO a bright
  stretch (`breathStaysBright`: bright now and 0.35 s ahead). Checking only "now" started the zoom at
  ~37%, because the first zoom frame lands a few hundred ms after the decision.
- ⚠️ **Never stretch a timing to film it.** Raising the floor to 6 s made the breath visible on video
  and hid that most of any floor ran behind the launch picture. Measure at the real timings before
  telling the owner what to expect.
- ⚠️ **A centre pixel cannot show the opacity of a shape that covers the centre.** The pale zoom was
  only found by sampling off-centre points and opening the frame.
- ⚠️ **The simulator recorder drops almost every frame of a 0.37 s hand-off**, and a launch can
  outlast one screenshot — screenshot until the home map is visible before stopping a recording.
- **Probe, don't reason.** Temporary logging of predicted vs actual layer brightness (0.737 vs
  0.749) settled in one run what three theories had not. Detail: `archive/HANDOFF-260912-4.md`.

## A walled-in environment breaks the batch halfway, not at the start (2026-09-13)

A new contributor's first link-pin batch stalled with `COULD NOT VERIFY — could
not resolve https://vm.tiktok.com/…`. Nothing was wrong with the tool, the
links, or the catalogue. A cloud environment starts on the **Trusted** network
access level — package registries and GitHub, nothing else — and the pin
pipeline needs `tiktok.com`, `instagram.com` and `ehky2882.github.io`, none of
which is on that list.

**The shape of the failure is what matters.** GitHub *is* reachable, so the
session could resolve coordinates, mint ids, write entries and commit them. It
could do everything except fetch a thumbnail. So the batch fails **half done**,
with `Tours.json` already pointing at hero files nobody has uploaded — which
`validate-tours.swift` passes, because the URLs are well-formed and it does not
fetch them. Left alone, that ships pins whose photographs 404 forever.

Three rules, in order of how much they cost:

1. **Probe the three hosts before minting anything.** Three `curl -o /dev/null
   -w '%{http_code}'` calls. A wall discovered before the work is a config
   change; discovered after, it is a two-session handoff.
2. **When walled in, stop and hand off — never half-ship.** The session that hit
   this did the right thing: committed the pins plus a `pins.tsv` and a README
   naming exactly what was missing, and said plainly that nothing must merge
   until the heroes existed. A session with network reproduced the 20 images
   from that file in minutes. The research was never redone.
3. **The fix is the environment, not the code.** claude.ai/code → the cloud icon
   above the message box → settings → **Network access: Trusted → Full**. A
   session already open keeps the old setting; it takes a new one.

⚠️ **Two neighbouring defaults bite the same way — invisibly, and only in the
image path.** `Pillow` is often absent, and without it `make-link-pin.py
--selftest` reports **62/62, which reads as a pass**, against **71/71** with it
installed. And `gh` may be missing, which `upload-images.py` shells out to.

⚠️ **Do not solve a missing `gh` by checking out gh-pages.** That branch is
~4 GB. A checkout killed partway leaves a working tree where `git add` stages
**thousands of deletions**, and committing it would wipe live images — this came
within one command of happening. Build the commit with plumbing instead
(`read-tree` → `update-index` → `write-tree` → `commit-tree` → push a ref), which
is also the one-rebuild property `upload-images.py` exists to protect. Read the
tree diff before pushing: it must be additions only, nothing outside `images/`.

⚠️ **And `check-image-duplicates.py --pins` will tell you it is fine when it
fetched nothing.** A gh-pages deploy takes ~10 minutes; a run started right
after the push 404s on every new hero and still prints `OK — no suspicious
duplicates`. That is §1 of this document with a fresh costume: read the WARN
lines and the counts, never the verdict, and confirm the live URLs and their
hashes once the Pages build reports success.
## A merge watcher that waits on ALL checks never merges while an unrelated check is down (2026-09-13)

On 2026-09-13 **Vercel was rate-limited on every PR** (`Deployment rate limited — retry in 24 hours`). Vercel only deploys `site/`, but `gh pr checks --watch` exits non-zero if **any** check fails. So three "wait for green, then merge" background jobs (#846, #851, #854) each **finished, reported exit 0 for the job, and merged nothing.** Their PRs sat open with every real check passing.

- **Gate a merge on the checks that matter, by name, and say which one you are ignoring.** The watcher that worked excluded only `Vercel` and still refused on any other failing or cancelled check. `main` has **no branch protection** (`GET …/branches/main/protection` → 404), so GitHub will not block a merge for you; the script is the gate.
- **Read the PR's state after a watcher finishes, never its exit code.** A job that "completed" is not a merged PR.
- **Polling checks immediately after `gh pr create` reads "no checks reported" and exits 1.** Wait until at least one check has registered before watching.

## `check-catalog-contract.py` needs `SSL_CERT_FILE` on the local Mac, or it cannot run (2026-09-13)

Run bare on the owner's Mac, it fails every fetch with `SSL: CERTIFICATE_VERIFY_FAILED` and **exits 2 — COULD NOT VERIFY**. Given `--out`, it wrote no file at all. That is correct behaviour, and it is **not a pass**.

```bash
SSL_CERT_FILE=/etc/ssl/cert.pem python3 scripts/check-catalog-contract.py
```

That one prefix is the fix (python.org's Python ships without the system CA bundle). Scripts that shell out to `curl` (`check-catalog-keys.py`, `merge-link-pins.py`) are unaffected.

## "Centred on average" is not "correct" — hand-typed coordinates were never checked one by one (2026-09-13)

A catalogue-wide OpenStreetMap sweep (2026-09-12) found **13 locations, 20 entries, standing 135 m to 1 km from where their own scripts put the listener.** Every one carried a 4-decimal coordinate typed once at a city launch (Los Angeles #390, Madrid #435, Berlin #479, the NYC and London batches) and never looked up at the spot.

**The errors have one shape: right neighbourhood, wrong building.** Bebelplatz sat on Gendarmenmarkt. Park Avenue Armory sat at 64th Street while the script says *"You're at Park Avenue and 66th Street."* The Egyptian Theatre was a kilometre east on the same boulevard, the Rosaleda at another corner of the Retiro, Notre-Dame at the apse instead of the square in front. A coordinate for *the area* was written down as the coordinate for *the place*.

**Nothing could catch it, and one check looked as though it had:**
- `validate-tours` checks that a coordinate is a coordinate, not that it is the place.
- `check-coordinates.py` runs on **new drops only** (Rule 8b). Its 2026-08-22 measurement found the hand-typed cities *"dead centred"* (London −0.4 m, New York −1.4 m) and that was read as clean. It is a **bias** test: random errors in every direction average to zero. It proved the method unbiased and said nothing about any single entry.
- A geofence that never fires produces no error anywhere. Only someone standing at 1,500 venues would notice.

**And one wrong number was copied, not retyped.** A walk stop reused its single tour's coordinate (Egyptian Theatre, Magere Brug, Rosaleda, Bebelplatz), a walk's intro reused its first stop, and a place took its members' point (Square Saint-Louis). One mistake became up to four wrong entries.

**The rules:**
- **Check a coordinate against the entry's own words.** The script names the street, the gate, the square; a distance alone proves nothing (§ 4).
- **Repair to where the script stands you, not to the OSM centroid**: the parvis at Point Zéro, the Redcross Way gates, the corner of Park Avenue and 66th.
- **Moving a walk's stop 0 can dissolve a place.** Hackesche Höfe was a place only because the Scheunenviertel walk's intro sat on it; correcting the intro left one member, and the owner dropped the place (2026-09-13).
- The same sweep found the **drop pipeline's northward offset in every city it made**: 208 of 262 building-level matches north, median +20 m, p = 1.7e-22. Those entries are still unrepaired.

## Two posts on one exact point can be a mislabel, not a place (2026-09-14)

The **First National Bank of Hollywood** place page held the **Westlake Theatre**. `@nickcabotrodriguez` titles every video *"What's up with this building? Part N"*, so the subject exists only in the thumbnail. #790 read most thumbnails and caught several mislabels, but not Part 5's, which says **"The Westlake Theatre"** in large type. It was titled and placed as a second First National Bank of Hollywood, 10 km from MacArthur Park. #790 then noticed both posts sat on *the exact same coordinate* and filed it as a place question; #801 made the place page, whose description reads *"Two separate posts by the same creator sit on it."*

- **An exact coincidence is evidence two entries were geocoded from the same assumption, not only that they describe one site.** Before grouping two posts from one creator, look at both thumbnails.
- **Coordinates that match to the last digit are suspicious when they came from a title.** Two independently geocoded posts about one building land metres apart, not on the same six decimal places.
- **A place's own description can record its doubt and nobody reads it.** "Two separate posts by the same creator" was the whole case for this page.

## A new catalogue key still lands in `get_catalog_core_base` — and one cannot be `created_at` (2026-09-15)

Adding `relatedTourIds` ("More like this") and `createdAt` in one migration, two
traps, both of which have already cost this repo a live outage in another form.

**The tour keys have moved again.** `split_link_pins.sql` renamed
`get_catalog_core` to **`get_catalog_core_base`** and wrapped it, so the live
chain is `get_catalog()` → `get_catalog_core()` → `get_catalog_core_base()`.
**`add_video_role.sql` — the file this repo's own notes call the worked example
— predates that rename** and searches only
`proname in ('get_catalog_core','get_catalog')`. Copied verbatim it finds
nothing and raises. It fails closed, so the cost is a rolled-back transaction
rather than a silent regression, but the finder list has to be updated every
time that chain grows a layer. Read `split_link_pins.sql`'s own "FOR THE NEXT
MIGRATION" paragraph before writing one.

**🔴 `createdAt` CANNOT be served from `tours.created_at`, and the reason
generalises to any audit column.** That column is
`timestamptz not null default now()` — it records when the ROW was written, and
every row in it holds the moment of a seed run. Serving it would have lit up
four sort controls that do nothing today (Newest/Oldest on maker pages, date
ordering on places and lists) and ordered them **by seed sequence**: fixed-
looking and wrong, which is strictly worse than visibly doing nothing. The
editorial date got its own nullable `authored_on date` column instead.

**Nullable was the point, not an oversight.** 36 tours genuinely have no
authored date, and `Tour.createdAt` is optional precisely so those sort last. A
`coalesce(..., now())` to satisfy the not-null constraint would have reinvented
the bug in one character.

**And they could not be backfilled here.** 35 of the 36 are Atlas Studio SFO —
*the whole maker*, so no sibling carries a date to borrow — and **this checkout
is a shallow clone whose history stops at 2026-08-17**, which is why a
`git log -S <id>` pickaxe returns that same date for every id and looks like an
answer. Validate a git-archaeology method against rows whose value you already
know before trusting 36 you don't.

**A seed change and its migration are ordered, and the order is load-bearing.**
`seed_from_toursjson.py` writes the new columns and `publish-catalog.yml` runs
it under `ON_ERROR_STOP=1` in one transaction — so on a database without them
the entire seed aborts and **every content merge stops reaching Supabase**.
Apply the migration BEFORE merging. It is free to apply early: until a re-seed
both columns are NULL, both keys are emitted as null, and the app decodes them
as nil, which is what it already does.

## A similarity between two documents is not the similarity between a query and one (2026-09-15)

`tour_scores` blends `0.6 × best-chunk + 0.4 × mean`, tuned so a *query* —
"art deco lobby" — finds the one paragraph that is about that. Reused for
tour-to-tour similarity that rule pairs two tours because they each spend one
sentence on brickwork. "More like this" asks whether two tours are **about the
same kind of place**, so it compares mean vectors and nothing else. The two
functions look like they should agree and must not.

- **Do not loop a per-query scorer over the catalogue.** `tour_scores`' `owners
  == index` mask is a full pass over every chunk per call — ~10^10 operations at
  1,582 tours. Grouping with `reduceat` over the offsets array that already
  existed is one matmul.
- **A relevance floor has to sit UNDER the thin cities, not over them.** 0.50
  looked better on paper and was rejected on the data: it evicts *good*
  same-city matches where a city is small — Fisherman's Wharf loses "Pier 39 Sea
  Lions" (0.477) and is handed a fishing village in Hong Kong (0.592), which is
  thematically apt and useless to someone standing on the wharf. 0.45 keeps the
  first and still cuts Boulders Beach's 0.395-and-below tail.
- **A test can pass for the wrong reason.** The first same-city-first fixture
  ranked the same-city candidate highest anyway, so it would have passed with
  the rule deleted. The cross-city candidate now scores *higher*, which is what
  makes the assertion mean anything.
- 🔴 **An exclusion needs a measurement, not a plausible reason.** #915 kept
  link pins out of "More like this" on the stated grounds that *"a pin has no
  transcript, so its vector is near-meaningless"*, and that sentence was
  repeated into a code comment, this file, the PR body and the handoff without
  anyone measuring it. Measured a day later: **all 2,318 pins carry title, both
  descriptions, tags, city, country and a stop caption — median 540 characters,
  p10 311.** Only `transcriptText` is missing, and #795 took that field off the
  wire for *tours* too. The matches were good wherever Atlas had local coverage
  (a Tempelhof pin → Tempelhofer Feld, 0.644) and correctly silent where it did
  not (a Toronto BBQ pin's best match was a Sydney restaurant at 0.413, under
  the floor). The cost of the guess was a whole feature withheld from 2,318
  entries. **It is cheaper to run the probe than to write the justification.**
- **The real limit was coverage, and only counting found it.** 978 of 2,318
  pins sit in a city where Atlas has no tours at all. That is why pins take
  same-city matches only and no cross-city fill: the alternative offers someone
  standing in Prague a walk in Vienna, and it is the 978 that would have made
  the egress bill large (~447 KB against ~253 KB).
- **Letting two kinds of thing match each other creates a THIRD direction, and
  it will be the biggest one.** "Pins can suggest tours and tours can suggest
  pins" sounds like two directions; it is three, because a pin's same-city
  candidates include other pins. That third one dominated: of 1,902 pins that
  gained a section, **1,322 saw only other creators' posts and no Atlas audio
  at all**, and only 580 got a real tour. The run had to be priced and put back
  to the owner rather than shipped as "what they asked for". Enumerate the
  pairs — A→A, A→B, B→A, B→B — before quoting a number for "both directions".
- **Price a content decision on the real payload, not on an estimate.**
  Measured at gzip level 1 on the live RPC body: 2,885,384 bytes as shipped,
  2,932,051 with pins restricted to naming tours, 3,176,601 with pins naming
  pins too. The estimate made beforehand from average id length was ~253 KB;
  the answer was **+291 KB**. Close enough to sound right, far enough to have
  argued the wrong case.

### 🔴 And then the THRESHOLD was reused in the other direction — a day later (2026-09-16)

**The section you are reading already said this, and it still happened.** The
scoring *function* was kept apart correctly. The *floor* was not: semantic search
shipped in build 166 with `scoreFloor = 0.45`, copied from `RELATED_FLOOR` above.

0.45 is right where it sits — it gates **tour ↔ tour**, mean-to-mean, two long
documents that score high against each other by construction. Search gates a
**short typed query ↔ a long document**, which scores far lower for the same
quality of match. Reusing the number looked like consistency and silenced three
of nine natural queries on the live index:

    quiet garden away              0.4498   ← the owner's first search
    quiet garden away from crowds  0.4136
    stained glass windows          0.4479
    somewhere romantic for a date  0.4323
    art deco lobby                 0.5444   (6 results)
    brutalist concrete tower       0.6455   (46 results)

**A floor wrong by a hair does not degrade — it disappears.** 0.4498 against 0.45
fails by two ten-thousandths and produces something that looks completely broken
rather than slightly strict. Now 0.35, measured in both directions: nonsense
(`asdfgh qwerty zxcvb`, 0.3361), "my tax return" (0.2392) and "how do i reset my
password" (0.1376) all still return nothing.

⚠️ **A cleverer rule was looked for and does not exist — do not re-attempt it.**
"quiet garden away" (good) and "stained glass windows" (weak) top out at 0.4498
and 0.4479, indistinguishable. What separates them is whether the catalogue
contains the thing, which no score can see; a relative rule ("within 0.08 of the
best") fires identically on both.

**The number was in our own output all along.** `verify-coreml-parity.py` printed
`top score 0.4136` for "quiet garden away from crowds" on every ranking run, for
days. It was read as a ranking check rather than as a distribution — the figure
that disproves a threshold can sit in a passing report, because the report was
asked a different question.

**So the habit, stated as a rule:** a constant carries the measurement it was
calibrated on. Moving it to a different comparison is a new calibration, not a
reuse — and calibrating means running it against the real input at least once.
The floor was never tested against a single typed query before it shipped.

⚠️ **And it is compiled in.** The floor is a Swift constant, so every adjustment
costs a TestFlight build. A tuning knob inside the app is not a knob you can
turn; if a number is expected to move on judgement, it belongs in the catalogue.


## A correctly-applied migration is not evidence either — the snapshot in front of it (2026-09-15)

`backend/add_related_tours.sql` patched the catalogue builder exactly as
intended, the owner got **"Success. No rows returned."**, and the live RPC went
on serving neither new key for another 25 minutes.

**`get_catalog()` has not been a live composition since `catalog_snapshot.sql`.**
It is `select payload from catalog_snapshot` — a lookup at a **pre-built row** —
and the chain `get_catalog_core_base → get_catalog_core → get_catalog_built` is
kept wholesale as the *builder*, run once per seed rather than once per request
(the live build was sitting on the anon statement timeout: 4 calls in 12 failed
with `57014`). **So patching the builder changes nothing a phone can see until
`refresh_catalog_snapshot()` runs.**

This repo already knew that — it is Automation Rule 11b, and six migrations in
`backend/` end with the line. The migration was written without it anyway.

**The sharper version of the existing rule.** "Success. No rows returned." was
already known to lie one way: a `create or replace get_catalog()` that severs
the wrapper prints it while dropping every place. This is a second, opposite
way — the SQL was *right*, and the result was still invisible. **Neither the
message nor the correctness of the patch is evidence. Only the served payload
is.**

**How to tell the two apart in one cheap call.** `catalog_snapshot_age()` costs
**34 bytes** and answers it outright: a timestamp *older* than the paste means
the snapshot is stale and the migration is probably fine; a *fresh* timestamp
with keys still missing means the patch itself did not take. That is the first
thing to ask, before spending 2.3 MB on the whole catalogue.

**And a key can be present while every value is null.** After the refresh but
before a re-seed, `relatedTourIds` and `createdAt` were served as `null` on all
1,583 rows. `check-catalog-contract.py` reads key *presence*, so that is a PASS
and correctly so — but "the contract passes" and "the feature works" are two
different statements, and only a seed makes the second true.

## "The server has it" is not "the phone has it" (2026-09-16)

The owner reported a place missing from their map. It was verified present in the
live `get_catalog`, in the gh-pages mirror, with valid members and a working hero.
**On the strength of that, they were twice told to go and look — and twice the
phone still did not have it.**

The error was reading `catalog_snapshot_age` as proof of *delivery*. It is proof
of *publication*. Every server-side check answers "did we publish it", and not one
of them answers "did that device receive it". Those are different claims and the
second is the one a person reporting a bug is making.

🔴 **What settled it was a screenshot, not a query.** The marker was a **circle**,
and `MapPins.swift` draws `ClusterPin` as a circle and `PlacePin` as a capsule —
so the place was not being applied at all, on a device that had other places from
the same merge. **One picture of the actual screen outranked five server checks.**
Ask for one early.

⚠️ **And the first check should have been rule 11's.** `CLAUDE.md` says an owner
reporting a feature missing that the code clearly ships is the trigger to ask the
**live RPC what keys it returns**. That was run fifth, after three rounds of
reading timestamps.

**The cause was never found.** Deleting the app fixed it; a partial publish was
ruled out (the seed is one transaction and `refresh_catalog_snapshot()` is its
last statement, so no reader sees a half-written catalogue).

### The design lesson, which is the durable half

`RemoteCatalogLoader` asks a 34-byte "anything new?" question and, on a match,
returns the cache without downloading. That saving is real and worth keeping. But
**a token match is a claim about the server, not evidence about the disk** — so
believing it without bound means a cache that goes wrong for *any* reason stays
wrong forever, silently, with no recovery but reinstalling. The owner restarted
the app for an hour and never got out.

Fixed in #955 by bounding it (`maxCacheAge`, 7 days) rather than by explaining it.
**A catch-all beats a targeted fix when the cause is unknown.** Two details worth
copying:

- the guards **decline rather than discard**, so a *failed* download still leaves
  the existing cache serving — discarding first would make an offline device
  strictly worse off than the staleness being guarded against
- a test asserts the 34-byte path **still** fires for a fresh cache, because
  guards like these are an easy way to silently re-inflate an egress bill that has
  already drawn two overage notices

### A fix nobody can see is a fix nobody can trust

The owner's verdict on the first build: *"honestly hard to test any of it."* They
were right. The self-heal fires after seven days and the length check only on a
truncated file, so it shipped with nothing observable — **the same property that
let the original bug survive an hour of restarts.**

The answer was one row in Settings → About: **"Updated"**, when the catalogue last
arrived. It makes the refresh button provable (tap it, read "just now") and would
have turned that hour into a glance. **When shipping a fix for something invisible,
ship the thing that makes it visible in the same change.** (That button was called
**Clear Cache** at the time; it is **"Check for new content"** since 2026-09-17 —
see the entry below.)

### Name a control for its outcome, not its mechanism (2026-09-17)

Settings carried a button labelled **"Clear Cache"** under a **trash** icon. It was
the only control that made new content appear on demand, and it was wrong twice over:

- **It named the mechanism.** Nobody who wanted the newest tours would go looking for
  a cache. The owner used it constantly and said plainly that *"most people wont know
  about it"* — which is not a discoverability problem to be solved with a tooltip, it
  is the name being about the implementation rather than the result.
- **It read as destructive, and was not.** Downloaded tours live in Documents under
  `TourDownloader`; the button touches `URLCache`, the image cache and the stored
  catalogue, and **cannot reach a download**. Someone abroad with tours saved for the
  trip had every reason to avoid the one control that would have fixed them.

Now **"Check for new content"** over `arrow.clockwise`, with a footer that says
downloads are not removed. 🔴 **The real fix is elsewhere**: the app already refreshes
on cold launch and on foreground after 900 s, so this button should be a repair hatch
rather than the normal path. Once **1.1.3** ships delta fetching the download falls
from ~2.4 MB to ~19 KB, and `foregroundRefreshInterval` can drop far below 900 s at
almost no egress cost — **that** is what stops an ordinary listener ever needing this
row. ⚠️ Pull-to-refresh is the obvious idiom and does **not** fit Home: Home is a map,
and a downward drag pans it.

## A proxy is not the rule, and it fails silently forever (2026-09-17)

`docs/places.md` Rule 1 is *two names for one thing is always a place*.
`check-place-candidates.py` tested **whether two entries sat on the same coordinate**.
Coincidence is a good proxy for identity and it found plenty — but it is not the rule,
and **everything the proxy missed stayed invisible however many times the catalogue was
scanned**. The owner kept finding candidates by eye and asking, reasonably, why a
system built for exactly this kept missing them.

🔴 The specific case, Rothko Chapel, **was in the tool's own output.** An ad-hoc scan run
beside the checker dropped it because `"therothkochapel" != "rothkochapel"`. Two failures
in one: a proxy standing in for the rule, and a hand-rolled scan trusted over the
checker that had already answered correctly.

The fix (#950) tests names, and three details of it are load-bearing:

- **Set equality, not containment.** Containment matched *"Akihabara"* to *"Gyukatsu Ichi
  Ni San, Akihabara"* — a restaurant in a district, not two names for one thing.
- **Drop the UNION of both entries' city words.** Dropping each side's own words stripped
  `asakusa` from `Tokyo (Asakusa)` but not from `Tokyo`, and the tier lost Asakusa
  Underground Street. **Caught only by re-running against the pre-#941 catalogue** — the
  tier recovered 8 of the 9 places that had just been minted, not 9. Any change to a
  matcher deserves that regression: run it against a base where the answer is already known.
- **CI-wire it.** A rule that depends on a session remembering rule 8c will be missed; it
  had been, twice. ⚠️ Actions runs `run:` under `bash -e`, so `|| code=$?` is what lets the
  report be written before a non-zero exit kills the step.

## A place candidate can be two WRONG names for one right place (2026-09-17)

"Pavilion in the Pond" and "The Glass House" came up as a group, and I filed it as
**part-vs-whole** — which `docs/places.md` records as explicitly undecided, so a question
for the owner. That framing questioned the *relationship between the two titles while
assuming both were true.* The owner: *"IT'S AT GRACE FARMS!"* — 6.1 km away. Neither
title was right.

**A candidate group is not only a question about whether to merge.** It is evidence that
at least one of the two entries is describing something else. Check what each one *is*
before reasoning about how they relate.

## The tour is usually the thing in the wrong place (2026-09-17)

Clearing the place backlog turned up coordinate errors in **13 of 15** groups, and in
almost every one it was the **Atlas tour** that was displaced, not the pin: Grace Farms
6.1 km, Geisel Library 5.4 km, La Collina 1,440 m, Casa de Vidro 833 m, Asakusa
Underground Street 718 m, Domino Park 201 m.

🔴 **Every one was precise, plausible and in the right city** — which is exactly why no
check has ever caught them. `check-coordinates.py` finds gross displacement and city
outliers; a hand-typed coordinate that lands on the wrong building in the right
neighbourhood passes everything. A place group is currently the only mechanism that
surfaces them at all, because it puts two independent opinions about one subject side by side.

**Corollaries paid for the same day:**

- **A pin 0 m from an OSM hit can still be wrong.** SESC Pompéia: the tour sat exactly on
  the community centre, the pin exactly on the *railway station* of the same name, 158 m
  apart. Both "verified" against a named node.
- **Wikidata's own coordinate can be the neighbouring building.** Casa Batlló's lands on
  Casa Amatller — the house `docs/places.md` records the owner deliberately keeping
  separate. Domino Park's lands on a restaurant. **Reverse-geocode every anchor before
  minting a place**, because a place is a coordinate and minting one MOVES every member onto it.
- **Moving a map pin is not moving the tour.** #930 changed 26 coordinates and **zero**
  centroid lines; `Tour.coordinate` and the "distance away" label read `centroidLatitude`,
  not stop 0 (`Models/Tour.swift:393,448`). 36 entries were left with the pin in one place
  and every distance calculation in another — worst 366 m, 4,270 m of total drift (#936).

## An EXACT group reporting does NOT mean no place exists (2026-09-17)

`check-place-candidates.py` reports a group when **a member** is unplaced. A place for
that subject may already exist with other members. Reading the report as "no place here"
minted a duplicate for 1111 Lincoln Road and turned CI red on `duplicate place id` — the
membership query had the matching omission, not excluding already-placed entries.

🔴 **And the process failure underneath it is the more general one: re-run the WHOLE check
after every mutation.** The full invariant check had been run, *then* a group was added,
and only the candidate scan re-run. Both bugs sat inside what had been verified and
outside what was re-verified. A check is a statement about a state, and every edit
retires it.

## A CDN resizer URL is not the image (2026-09-17)

The owner pasted a `popmenucloud.com/cdn-cgi/image/width=1200,height=1200,fit=scale-down/...`
URL for the Monkey King hero. It serves **1200×800** — under the pipeline's 900 floor, so
it cannot crop to 1200×900 without upscaling. The **untransformed original is 7200×4802**.

Strip the transformation segment from any `/cdn-cgi/image/`, `/_next/image`, `?w=`,
`/thumb/` or similar URL and re-fetch before concluding a source is too small. The
dimensions you measure are the ones the resizer was asked for, not the ones the file has.

## A background process does not outlive an idle session (2026-09-17)

A 4.5-hour Wikidata sweep was started with `nohup … &`, checkpointed to a
committed file, and left to run while the session went idle. A scheduled
check-in found it **dead**: it had stopped at 316 of 4,566 entries,
**about five minutes after the turn ended.** The container suspends when the
session goes idle, and nothing in the process outlives that.

🔴 **So "start it in the background and check back later" is not a strategy in
this environment**, however carefully the check-in is re-armed. Work that must
finish has to fit inside an active turn.

Two things follow, and the second is the one worth keeping:

- **Bound each foreground run** (`--limit`) so it completes and saves rather
  than being cut off mid-flight. A resumable cache makes the chunking free.
- **Make the work fast enough to fit.** The sweep was 3 s per entry because it
  sent one query per name. Batching eight searches into one query took it to
  **0.31 s per entry — 22 minutes instead of 4.5 hours** — which is the
  difference between a job that can be finished and one that cannot.

⚠️ The scheduled check-in was still worth having: it is what *discovered* the
death. A job you cannot supervise is not the same as a job you should not check.

## The faster endpoint was the wrong one, and only measuring showed it (2026-09-17)

Wikidata offers two ways to search: the `wbsearchentities` **action API**, and
the same search wrapped in SPARQL via `SERVICE wikibase:mwapi` on WDQS. The
action API is obviously the faster of the two — **~0.3 s against ~2 s** per
call — and obviously the one to switch a slow sweep to.

Measured in bulk it is unusable: **5 of 15 requests succeeded at a 0.5 s sleep,
9 of 15 at 0.25 s**, the rest HTTP 429. WDQS, meanwhile, had just run **316
consecutive entries with zero failures** at the same politeness. The shared
egress proxy means the rate limit is not ours alone to spend.

**The win was batching the permissive endpoint, not switching to the fast one**
— eight searches UNION'd into one WDQS query, each branch tagged so results map
back, which is 10× on the measure that mattered.

🔴 **Per-call latency is not throughput.** Benchmark the thing you will actually
do — a burst, sustained, from this network — not a single call from `curl`. The
single call looked fine; three of them in a row looked fine; ten in a row did not.

⚠️ And when a batch can fail, **one bad member must not lose the others**. A
failed batch here re-asks every name individually before recording anything,
because the alternative caches seven innocent entries as "nothing found" — which
is indistinguishable from a real miss forever after, since the cache is also the
resume state.

## The gazetteer can be the wrong one (2026-09-17)

An audit that checks our coordinates against Wikidata produced 86 findings. Five
of the top ones were opened by hand, and **none was a catalogue error**:

- **Prada Aoyama** — ours is correctly in Minami-Aoyama; Wikidata's point is
  10.6 km east. **Wikidata is wrong.**
- **Pérez Art Museum Miami** — ours is correctly at Museum Park; Wikidata's is
  1.6 km southwest. **Wikidata is wrong.**
- **Hōrin-ji Temple** — a *different* Hōrin-ji, 16 km away in Katsushika.
- **Palácio da Justiça** — a different one; every Portuguese district has one.

🔴 **An external reference is evidence, not an oracle.** This is the same shape
as the earlier finding that *Wikidata's own coordinate can be the neighbouring
building* (Casa Batlló → Casa Amatller) — but one step further: there the
reference was imprecise, here it is simply wrong, and a check that trusted it
would have "fixed" four correct entries into wrong ones.

⚠️ **And the base rate moves with the work.** The six errors that motivated this
audit had already been fixed, and the catalogue had been through coordinate
sweeps — so the true-error rate was low enough that the false-positive classes
dominated the top of the list. **A detector's precision is not a property of the
detector alone**; it falls as the thing it detects gets rarer. Report the sample,
not the count, and never hand over a findings list as a worklist without opening
some of it first.

The tool was right to build: **1,667 entries independently confirmed** is a fact
about the catalogue nobody had, and per-creator coverage (86% for one studio
against **1%** for a food creator) settles a routing question that had been
argued from guesses. Those were the durable outputs — not the findings.

## A concept with a named home must not be restated somewhere else (2026-09-17)

A "Because you saved …" rail shipped to TestFlight and showed nothing at all
for the owner, who had tours saved in their account *and* saved a fresh one
while testing.

**This app stores saves in two places.** Liked is backed by `LibraryStore`;
named lists are backed by `TourListService`. The rail read the first only, so
anyone who files tours into lists was invisible to it.

🔴 **`Data/SaveState.swift` exists to prevent precisely this, and says so in
its opening lines:**

> *"a tour is saved when it belongs to at least one list … There is no separate
> saved flag living alongside list membership — that split … is exactly what
> this replaces."*

The rule already had one implementation — `TourSaveActions.isSaved`, used by
every bookmark surface in the app, one line long. Writing a second one
recreated the split that file was written to remove.

**Seven unit tests passed.** They all shared the wrong premise, so they
confirmed each other rather than the behaviour. Testing thoroughly *around* a
mistaken assumption produces confidence, not correctness — and the volume of
green makes it feel like the opposite. The two tests that mattered were the
ones nobody had written: a tour saved **only** in a named list, and a
suggestion excluded because it lives in one.

**The habit:** before writing a predicate about a domain concept — saved,
liked, downloaded, visible, published — grep for it. If a type or a file is
named after the rule, it owns the rule. A second definition is not a
convenience; it is a fork that will disagree with the first one eventually, and
the disagreement will be invisible until someone uses the half you did not
implement.

⚠️ **A related trap in the same feature, worth knowing when testing saves:**
`SaveState.tapAction` returns `.chooseLists` for a tour that is already saved
somewhere, so tapping the bookmark a second time **opens the list sheet rather
than re-saving**. Testing the Liked path therefore needs a tour that is
currently saved nowhere — otherwise the tap files it into a named list and the
Liked path is never exercised at all.

## A guard is only as complete as the record it reads (2026-09-18)

Auto-creating places needed one safety property: never mint a pairing the owner
has already declined. The check consulted `make-place-menu.py`'s `DECLINED`,
`DECLINED_GROUPS` and `DECLINED_PAIRS`, and on its first real run it **failed**
on *Bar Luce at Fondazione Prada* — declined under Rule 4, a tenant is not the
site.

**The code was correct. The data was missing.** That decision and **eight
others existed only as prose in `docs/places.md`** and had never been written
into the machine-readable record. Every tool that read the record rather than
the document believed nine owner decisions were still open.

🔴 **A decision recorded only in prose is not a decision any tool can honour.**
When a rule is written down for humans and separately encoded for scripts, the
two drift, and the drift is invisible until something tries to act on it. Before
automating anything that must respect past decisions, **diff the prose against
the encoding** — do not assume the encoding is the prose.

⚠️ And the direction of the risk is the wrong way round from intuition: **a
signal that fires more often makes an incomplete record more dangerous, not
less.** Widening what a tool can decide raises the cost of every gap in what it
has been told not to decide.

## Proof must drive the grouping, not follow it (2026-09-18)

Grouping catalogue entries into places by "cluster on proximity, then test
whether the cluster is really one venue" has a failure mode that no amount of
threshold-tuning reaches: **an arbitrary anchor decides the outcome.**

Measured: **Saigon Social** — a different restaurant — absorbed **Una Pizza
Napoletana** 23.8 m away. That pair then correctly failed the proof test, so
nothing was minted, which looks like the guard working. But Una Pizza had been
**consumed** by the rejected cluster, so its true partner — its own caption pin
12.4 m off, naming `@unapizzanapoletana` — never formed a group at all.

🔴 **A wrong anchor silently destroyed a right answer**, and the only visible
symptom was an absence. Testing candidate PAIRS first and unioning the ones that
pass cannot do it: Saigon Social and Una Pizza never pair, so Una Pizza stays
free.

**The general rule: when a cheap filter and an expensive test are combined, the
filter must only ever narrow the search, never decide membership.** If the
filter can consume a candidate, it can veto the test's correct answer.

⚠️ Related, and easy to get backwards: **exact coordinate equality is not the
same as zero distance.** Kossar's sits 0.0 m from its caption pin *by distance*
while the two stored coordinates differ below a centimetre, so an equality
bucket filed them apart. Cluster on the distance you actually mean.

## A title is an assertion, and 466 pins have nothing that can contradict it (2026-09-18)

The owner found a pin titled **"Vittoriano"**, in Rome, sitting on the Vittoriano's
real coordinate. It was **Torre Velasca — a building in Milan, 476 km away.**

**Every check we own passed it.** `validate-tours` saw a well-formed entry.
`check-coordinates.py --pins` saw a point consistent with its neighbours and its
own stated city. `spine-match.py` confirmed it, because the coordinate *did*
belong to the thing the title named. The caption —

> Italy's Ugliest Building Became a National Monument😱

— names no building at all, so nothing in the record disagreed with anything.

🔴 **Every check in this repo verifies INTERNAL CONSISTENCY or EXTERNAL
POSITION. Not one verified that a title matches the content it links to.**

Measured on the catalogue: **466 of 3,083 link pins (15%) carry no venue
`@handle` and a caption sharing no word with their title.** For those, the title
is unfalsifiable from anything we store. `@pasttworld` holds 119 of them — and
`@pasttworld` is the creator whose pin was 476 km out of place.

The project had already solved this shape once, for images, and the answer was
the same both times: **when no metadata check can reach a class of error, open
the artefact and read it.** `scripts/check-pin-subject.py` asks the hero image,
through two independent Gemini calls, whether the place shown is the place
claimed.

⚠️ Two properties that are the whole point, and both were mutation-tested:

- **Two calls, never one compound question.** A single "is this the subject AND
  a usable photo" gets answered on subject match alone — that is what shipped
  Rijksmuseum prints as photographs (§ Image Pipeline).
- **UNUSABLE is not a pass.** A frame showing a person, a plate of food or a
  title card cannot testify about a title. It means *unexamined*, exactly as
  `spine-match.py`'s UNMATCHED does.

⚠️ It **cannot run in CI** — it needs the owner's Gemini key, which is pasted per
session and never stored. With no key it exits **2, COULD NOT VERIFY**, and says
so; it never returns a pass it did not earn.

## Creating a place makes the next entry on it invisible (2026-09-18)

The owner found the **Washington Monument**: a place with two members, and a
third entry sitting **7.0 m outside it**, carrying the place's exact name.

Every tier of `check-place-candidates.py` — EXACT, TIGHT, NEAR, NAME — hunts for
*sites that have no place page*. `scan_names` drops every already-placed entry
outright. **So the moment a place exists, that site is treated as finished, and
an entry landing on it afterwards is never questioned again.**

🔴 **A creation operation with no matching JOIN operation leaves a growing
blind spot**, and it grows precisely where the content is densest — the sites
popular enough to have earned a place are the ones most likely to get another
entry. Measured the day it was found: **20 entries within 25 m of an existing
place, 10 carrying the place's exact name.**

The pair *was* in the report, as a 7.0 m row among 91 TIGHT ones, with nothing
saying one side was already a place. **Reported is not surfaced.**

## Asserting what a function says is not asserting what it does (2026-09-18)

`check-pin-subject.py`'s gate D must never be shown the image — given one, it
answers about the picture again, which is the disagreement it exists to settle.
There was a selftest for it, and it was green, and it was worthless: it asserted
the **prompt text** never mentions an image. Nothing asserted the request body.

A mutation that sent the image on *every* call was **MISSED**.

The fix was to extract `build_payload()` so a test can look inside the wire
format. ⚠️ **The pattern generalises:** a test that reads a function's prose, its
docstring, or the string it builds is testing the description, not the
behaviour. Test the thing that goes out.

## A fixture that stops being able to fail is a dead test (2026-09-18)

`audit-board.py` has a test that a check which raises reports `ERR`, never `0`.
Its fixture was a malformed entry that made one function raise — **because of a
signature bug elsewhere**. The moment that signature was fixed, nothing raised,
the assertion became vacuous, and it kept printing green.

⚠️ **A test written against an incidental failure dies silently when the
incident is fixed.** The fixture must cause the failure *on purpose* — here, a
deliberately malformed catalogue.

⚠️ And the same run showed the flip side: **two of the first sixteen mutants
were no-ops**, so they "passed" while exercising nothing. A mutation that cannot
change behaviour is not a test of the guard; it is a test of nothing.

## A guard masked by another guard cannot be tested by a realistic fixture (2026-09-18)

`audit-board.city_spelled_twice` has four rules: a prefix test, a country test,
a proximity test and a fold. Mutation testing found **four of them unable to
fail**, every one masked by a different rule.

The clearest: `York` / `New York` was chosen to prove proximity separates two
far-apart cities. It proves nothing — **York is a SUFFIX of New York**, so the
prefix rule excludes the pair before proximity is ever consulted.

🔴 **Every fixture must isolate exactly one rule**: the pair has to be excluded
by the rule under test *and by nothing else*. A realistic example usually fails
several rules at once, which is exactly what makes it useless as a test.

## A check that says where it runs can be lying (2026-09-18)

`audit-board.py`'s own rows said three new classes `run: CI`. **Nothing ran it.**

A checklist that misstates where it runs is worse than no checklist: it answers
*"is this covered?"* with a yes that nothing backs. If a tool reports its own
coverage, something must verify that claim — here, the CI job that actually runs
it, added in the same change.

## The accent check that was asked for, and silently skipped the accents (2026-09-18)

`CLAUDE.md` asks for an accent-folded duplicate check on city names, after
`Sao Paulo`/`São Paulo` and `Zurich`/`Zürich` were found merged. Nothing
implemented it for two months.

Then the first implementation **skipped exactly those pairs**: two spellings
that fold to the same string hit a `fa == fb` guard meant to stop a city pairing
with itself, and were dropped — while the docstring claimed to catch them.

Selftests were green. **Mutation testing found it.** The fix is that only an
identical *raw* name is a non-event; two different spellings that fold together
are the strongest finding the check can make.

⚠️ It also turned up a convention nobody had questioned: **`City (District)`**,
applied to Tokyo (nineteen variants), New York, Osaka, Bangkok and Los Angeles.
Not typos — a deliberate style, each variant counting as a separate city.

## Search the ADDRESS, not the coordinate (2026-09-20)

Two 2025-opened resorts — the St. Regis Cap Cana and W Punta Cana — were reported to
the owner as having no obtainable coordinate. Neither is in OpenStreetMap or Wikidata,
and Marriott returns **403** to WebFetch *and* to curl with a browser user-agent. Every
route tried had been a route to a **coordinate**: Nominatim by name in three spellings,
bounded OSM hotel sweeps of both areas, Wikidata, two booking aggregators.

The owner asked: *"why can't you search for the address for those properties?"*

Both fell within minutes. The venues publish a street address — "Punta Espada, Cap Cana",
"Carretera Uvero Alto" — and that address then geocodes, or places the venue against a
neighbour that **is** mapped (the Punta Espada driving range 2.4 km north; Zoetry Agua
0.4 km west).

🔴 **"Search the name" and "search the address" are different searches, and for a venue too
new to be mapped only the second one works.** `docs/link-pin-runbook.md` § "Exhaust search
before saying an address cannot be found" was read this session and then not applied,
because the search that felt exhaustive was exhaustive *of coordinate lookups*.

⚠️ **And a distance that corroborates is not a location that corroborates.**
`godominicanrepublic.com` offered 18.4459845, −68.4261917 for the St. Regis. It matched
Cvent's independently-published "9.32 miles from the airport" to within **0.03 mi** — as
convincing as a cross-check gets. It is **2.3 km from the real point** and reverse-geocodes
to bare scrub. What actually settled it was a **named OSM feature agreeing with the street
address the venue itself publishes**: two statements about *where*, not two about *how far*.

## A truncated checker output cannot be grepped for your own work (2026-09-20)

A PR claimed its batch added no validator warnings. It had added fifteen.

`validate-tours-mirror.py` prints a header count — `0 errors, 518 warnings` — and then only
the **first 40 warning lines**. Grepping the saved output for the batch's titles returned
nothing, which read exactly like a clean bill of health. The truth came from recomputing the
facet rules directly against the catalogue.

🔴 **A checker's summary count and its printed detail are two different artefacts.** When the
detail is truncated, absence from it is not evidence. This is the stale-output-file trap
(§ 1) wearing different clothes: the run was real, the stamp was current, the file was
fresh — and the thing being looked for was simply never printed.

**The habit:** before concluding "none of mine are in here", check that the file could have
contained them. `grep -c WARN file` against the header's own total answers it in one command.

## A check keyed on a non-unique field silently tests half its subject (2026-09-20)

Four places were created from pairs of entries. The guard that was supposed to
refuse a member being dragged too far built `{title[:30]: distance}` — but both
members of each pair carry the **same title**, which is why they are a place at
all. The dict collapsed to one key per pair, the assertion tested one entry
instead of two, and it printed `moves 0.0 m` for every pair: the pin's distance,
never the tour's.

The result happened to be sound. That was established afterwards by a different
method — diffing every entry's coordinate against `origin/main`, which reported
4 moved, max 62.9 m, all tours, no pin touched. **That is the number the guard
should have produced and did not.**

🔴 **Keying a check by a field that is not unique reduces its sample without
saying so.** It is the same shape as the truncated-output trap above: a check
that cannot see its whole subject returns a pass for the part it saw. Both read
exactly like success.

**The habit:** key a per-entry check by `id`, never by a display field — and when
a check reports N results, assert N is the number you expected to test.

## The release lane BUILDS — it cannot submit a build you already tested (2026-09-20)

1.1.3 was ready to submit with nothing left to write: build **176** was uploaded, `VALID`,
tested on the owner's device and approved — *"looks good! merge it"* — and
`git diff a0671e39 HEAD` over `*.swift`, `*.pbxproj`, `Info.plist` and `Assets.xcassets`
was **empty**, so the code on `main` was that binary.

The documented way to ship is Actions → **App Store release** → type `RELEASE`
(`docs/launch-runbook.md` Step 15, and Step U6 for an update, which says *"same as Step 15"*).

🔴 **That workflow runs `bundle exec fastlane release`, and the lane's first real action is
`build_ipa`.** It compiles a *fresh* binary from the checkout and submits that. Pressing the
button named "App Store release" on a release whose build is already approved therefore
**throws away the tested artifact and submits an untested one with the same source** — same
code, different binary, never run on a device, with a new build number the owner has never
seen. Nothing in the workflow name, its description or the runbook says so.

⚠️ **And the same lane pushes metadata.** `upload_to_app_store` runs with `force: true` and
skips **screenshots only, not metadata**, so `fastlane/metadata/` goes to Apple with no
confirmation prompt. On the same day, `release_notes.txt` still held **1.1.2's text verbatim**
(fixed hours earlier in #1028) — the lane would have shipped an update whose What's New
described the *previous* update.

**When the build already exists, submit it through the App Store Connect REST API instead.**
Six calls, each verifiable before the next, with the key at `~/Downloads/AuthKey_*.p8`:

```
POST /v1/appStoreVersions                       versionString, platform IOS, releaseType MANUAL
PATCH /v1/appStoreVersionLocalizations/{en-US}  whatsNew
PATCH /v1/appStoreVersions/{id}/relationships/build   → the build you tested
POST /v1/appStoreVersionPhasedReleases          phasedReleaseState INACTIVE
POST /v1/reviewSubmissions  +  /v1/reviewSubmissionItems
PATCH /v1/reviewSubmissions/{id}                submitted: true
```

✅ **Creating the version this way copies the previous version's localization AND its
media**, exactly as the UI's *"+ Version"* button does — all ten screenshots appeared on
1.1.3 with an **identical `sourceFileChecksum` to 1.1.2**, which is the check worth making
rather than trusting the copy. That matters because `fastlane/screenshots` is empty and
gitignored on purpose: any lane that "uploads screenshots" replaces the live set with
nothing. They only ever go via `.github/workflows/upload-screenshots.yml`.

⚠️ Pulling the current screenshots down first as insurance needs **`curl`, not `urllib`** —
`urllib` fails certificate verification on this Mac. Substitute `{w}`/`{h}`/`{f}` in each
`imageAsset.templateUrl`, and read the tab-separated filename properly: *"App Store
Preview-01.png"* contains spaces, so a bare `read fn w h url` splits it and curl answers
`(3) URL rejected`.

🔴 **The general shape: a workflow named after the OUTCOME can be named after a path to it
that no longer applies.** "App Store release" is the right name for the case where the build
does not exist yet, and the wrong tool for every release after a TestFlight cycle the owner
has already signed off. Read what the lane does, not what it is called.

## Overpass is reachable through a MIRROR (2026-09-21)

`CLAUDE.md` rule 8d records Overpass as "blocked by the web egress proxy", and
`overpass-api.de` does indeed fail here — `curl: (35) Recv failure: Connection
reset by peer`, every time.

🔴 **`https://overpass.kumi.systems/api/interpreter` works.** That is a real
extra source for the one question no gazetteer always answers: *where is this
building, by name?* It settled Belgrade Tower, where Wikidata stated no address
and Wikipedia carried no coordinate in either English or Serbian.

Two things to know before relying on it:

- **A named node is not necessarily the thing.** Searching `Кула Београд`
  returned three elements: **two bus stops named after the tower**, and one
  `way` tagged `building=apartments` which is the tower itself. Read the tags,
  not the name. Taking the first node would have moved the pin onto a bus stop.
- **It times out on an unindexed query.** A regex over a bounding box, or an
  `area[...]` lookup, returns **504** on anything but a small city. The Belgrade
  query only succeeded because the area was small; the same shape 504'd
  repeatedly for Balneário Camboriú. Prefer an exact `["name"="…"]` match, keep
  the bbox tight, and expect to be rate-limited after a few calls.

- **Query the name LOOSELY.** `["name"="Yachthouse Residence Club"]` returned
  nothing; OSM calls it **"Yachthouse Residence"**, without the "Club" our title
  carries. A regex on `Yacht` found it immediately. An exact-name miss is not
  evidence the building is absent — it is evidence the two names differ.

**A blocked host is not an absent fact** — the same lesson as the 42 Tokyo
addresses. Try a mirror before saying a source is unavailable.

### ⚠️ Backticks inside a double-quoted shell string are COMMAND SUBSTITUTION

Writing this very lesson, a `python3 -c "…"` one-liner containing
`` `overpass.kumi.systems` `` in its text silently lost the hostname: bash ran
it as a command, printed `command not found` to stderr, and substituted the
empty string. The edit reported success and the committed index row read
*"reachable through \*\*"*.

**Use a heredoc (`python3 - <<'PYEOF'`) for any text containing backticks** —
the quoted delimiter stops bash touching the body at all. And when a command
prints something odd to stderr but still exits 0, read what it actually wrote
rather than trusting the exit code.

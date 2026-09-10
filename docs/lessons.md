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

---

## 2. Live systems vs. documents

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


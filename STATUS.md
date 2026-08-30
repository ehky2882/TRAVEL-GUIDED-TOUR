# STATUS — the live board

**What this file is.** A short, mechanical record of *what is in flight right now*: open PRs,
which TestFlight build carries which branch, and what is waiting on the owner. It is the thing
a session reads to answer "what is everyone else doing?" before it starts work.

**What this file is NOT.** History. `CLAUDE.md` § Current State is the narrative record of what
shipped and why, and it stays the authority for anything already merged. When an item here is
finished, it leaves this file and its story goes there. Never let this file grow a history
section — two histories drift, and drift is the problem this file exists to fix.

**Update rule (automatic, no prompting).** Any session that opens or merges a PR, dispatches a
TestFlight build, or discovers/clears an owner-blocked item updates the relevant table here in
the same commit. Re-derive rather than trust: `gh pr list --state open`, and read the build
numbers back from the Actions run list — never from what a PR body predicted.

**Last verified:** 2026-08-30 (session 124 — [#662](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/662) merged as `845f0d86` after owner device-verification on **1.1.1 (137)**. 🔴 **The marketing version is now 1.1.1** — 1.1 is released and Apple refuses further builds on it, see § Builds. Session 122c: [#657](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/657) and the architect PR [#654](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/654) are both merged and re-verified on `main`, and **one dead hero image was found — see § 1**)

**⚠️ This board is no longer polled on a timer.** The coordinator session ran a 25-minute check
from 04:50 to 12:25 and found something worth reporting on two of fifteen ticks, at roughly 20k
tokens a tick — so it is now **on demand** (owner decision, 2026-08-20). It goes stale the moment
a parallel session merges something. **Re-derive before trusting it**, per the update rule above.

---

## 1. Awaiting owner — device review

🟡 **OPEN, AUTO-MERGE CLASS — GLASSHOUSE THEATRE BECOMES A PLACE
([#663](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/663), `claude/tour-links-upload-3bqlib`,
restarted off `main` after #659 merged).** Owner: *"make place card for glasshouse theater."* The two
coincident pins from #659 become one place; **places 44 → 45**, `check-place-candidates.py` **4 EXACT
→ 3**. **Nothing moved** — both pins were already on the identical coordinate, so the exact-coordinate
identity rule held with no pin relocated. **🔴 The hero is BORROWED from the interior pin because no
third photograph exists**: the venue opened March 2026 and every Commons image of it is CC BY-SA 4.0,
off-policy while the app has no attribution UI. **The Hotel Casa del Mar case — do not go sourcing a
replacement.** Content only; the seed carries `places`, so **no owner SQL**.


✅ **MERGED — FOURTEEN LINK PINS + THE CHECKER THAT CRIED WOLF
([#659](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/659), squash `e21b4fd5`), AND ALL
FOURTEEN ARE LIVE.** Verified against the **live sources**, not the workflow's success line: the
Supabase RPC (what the app reads first) and the gh-pages mirror each serve **256 link pins**, with
**0 pins wrongly inside `tours`** and `priceTier` / `isPrivate` both intact.
🟡 **OPEN — LA CLEANUP: TWO DUPLICATE PINS PULLED, FOUR LA PLACES BUILT
([#658](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/658), `claude/la-tours-cleanup-place-cards-r3m4af`).**

✅ **MERGED — FOURTEEN LINK PINS + THE CHECKER THAT CRIED WOLF
([#659](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/659), `claude/tour-links-upload-3bqlib`).**
Fourteen links from the owner — 13 TikToks + 1 Instagram reel, **all alive, nothing parked**.
**linkPins 242 → 256 · makers 188 → 191 · New Zealand the 37th country** (re-derived after [#658](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/658) merged under it; the PR body's 244 → 258 was measured against the older base). Then, on owner
instruction (*"fix the checker"*), the tooling half: **`check-image-duplicates.py` was hashing error
pages and caching them**, so two URLs failing the same way became a permanent false "duplicate" — it
reported two unrelated pins as byte-identical when they are not. `download()` now reads the status
code (a 200 is the only success), `looks_like_image()` gates the hasher, nothing failing either is
cached, and the cache dir moved to `.cache/image-dupes-v2/` because a poisoned entry is
indistinguishable from a good one. **Content + tooling + docs, no Swift — auto-merge on green.**
⚠️ **`Diminish and Ascend` is pinned at Christchurch though its thumbnail shows Waiheke — owner
decided: *"keep christchurch."* Settled; do not "fix" it.**


✅ **MERGED — LA CLEANUP: TWO DUPLICATE PINS PULLED, FOUR LA PLACES BUILT
([#658](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/658), squash `2a222899`), AND ITS SQL
HAS BEEN RUN.**
Owner instructions: remove one of the two Hotel Casa del Mar pins and its place page, take out the
YouTube Castle Green, then *"make bradbury, griffith and union station places. make petersen also a
place, and go with your recommended coordinate."* **linkPins 244 → 242 · makers 189 → 188 · places
41 → 40 → 44 · tours unchanged at 1,552.** Content + one SQL file; no Swift, no build.
**✅ `backend/pull_la_duplicates_260830.sql` HAS BEEN RUN (owner, 2026-08-30) and nothing is owed** —
re-read from the **live RPC** rather than the SQL Editor's success line: all four deleted rows gone,
all three survivors present, `TikTok @thedesigndetourist` still at 19 pins, 0 pins wrongly inside
`tours`, `priceTier` (66 priced) and `isPrivate` both intact. **The four places needed no SQL** — the
seed carries them, so they arrived with the merge. **The pin moved and the tour did not — verified by diff: 0 Atlas tours changed a coordinate,
trigger mode or radius.** Every place hero is a **third photograph promoted from the member tour's
own gallery**, nothing sourced.

✅ **MERGED — THE DUPLICATE-IMAGE CHECKER HAD NEVER SEEN A LINK PIN
([#657](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/657), `claude/tour-links-upload-qeoxe7`),
squash `597b5aff`.**
Owner: *"do it now if it helps."* `scripts/check-image-duplicates.py` reads `catalog["tours"]` and
nothing else, so **all 244 link-pin heroes were invisible to it, `--all` included**, from the day
#597 split them into a sibling `linkPins` array. Measured before the fix: **`--all` saw 5,595 images
and 0 of the 240 pin heroes.** Tooling + docs only — no catalogue change, no Swift, no SQL — so this
is the **auto-merge class**: merge on green, no owner gate. ⚠️ **The catalogue is clean, and that is
now measured** (5,835 images, 0 errors, 27 INFO, 0 fetch failures) rather than assumed — my first
description of this to the owner called it a convenience gap and said nothing was wrong because of
it, which was not something I had checked. Adds **`--pins`**; **`--maker <CODE>` stays tours-only
deliberately**, because pinned handles collide with city codes as substrings (`STO` matches
`@urbanstoriesyt`; 31 collisions catalogue-wide).


✅ **MERGED — FIVE ARCHITECTS JOIN THE VOCABULARY
([#654](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/654), squash `f93321b6`).** `Moshe
Safdie` · `John Augustus Roebling` · `William Henry Barlow` · `KieranTimberlake` · `José Ignacio
Linazasoro`. **⚠️ IT MERGED *AFTER* THE PORTMAN PR ([#655](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/655), `0086a212`) THOUGH IT WAS BRANCHED BEFORE IT** — the case where one
session's vocabulary edit silently reverts another's. **Checked rather than assumed, on `main`:
Portman survived, 330 + 5 = 335 architects / 385 tags, and the two copies of the vocabulary agree
exactly** (`Models/Tag.swift` and `scripts/validate-tours.swift` — a mismatch produces an error per
tagged entry). Validator mirror: **0 errors, 2 warnings across 1,552 tours + 244 pins + 41 places**,
both pre-existing; **0 unused names**, and **0 of the 497 named-architect entries missing `Designed
by a Master`**. ⚠️ **Still never compiled or seen in a simulator** — it is a `Models/Tag.swift`
change and CI's build is the only check it has had.

🔴 **OPEN, NEEDS AN OWNER DECISION — `MoMA PS1` SHIPS A DEAD HERO IMAGE.** Its
`heroImageURL` returns a hard **404**, confirmed across seven spaced attempts against four
same-host controls that all return 200, so it is not the rate limiting that hid it. **The tour has
no gallery**, so there is nothing to promote in its place (the Castello / DuSable free fix does not
apply) — a replacement has to be sourced through the image pipeline, which means owner picks.
**⚠️ It is the ONLY `upload.wikimedia.org/wikipedia/en/` URL in the catalogue** — an English
Wikipedia *local* upload rather than a Commons file, which is where non-free/fair-use images live
and where deletion is routine. Everything else Wikimedia-hosted is on Commons and healthy. **One
dead image in 5,848**, found only because #659's fetch fix stopped error-page bodies being hashed
as though they were pictures.

✅ **THE `@nycunfilteredstories` REMOVAL SQL HAS BEEN RUN (2026-08-30).** Owner applied
`backend/pull_nycunfilteredstories.sql`; verified against the live RPC — all four pins and both
creator rows gone, 0 pins wrongly inside `tours`. **Nothing owed; do not ask again.**

✅ **THE LINK-PIN FULLSCREEN BUG IS FIXED, SHIPPED AND OWNER-VERIFIED.**
[#622](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/622) squash `e22dba7`, **build 134 from
`main`**. Owner on the probe build carrying the same fix: *"133 is live. that seem to be done the
trick."* **Nothing is open from this work; the story moves to `CLAUDE.md` § Current State.**

- **🔴 IT TOOK FOUR BUILDS AND THREE WRONG DIAGNOSES, and this board carried two of them as fact.**
  #611 (build 129) and #617 (build 130) both shipped as "the fix" and neither was. **TikTok and
  YouTube embeds do not use WebKit element fullscreen at all** — the video takes its **own
  `UIWindow`**, at or below `.normal + 1`, which is where the module window lives. `fullscreenState`
  never changed, so nothing ever fired. **Never record a fix as verified on the strength of a merge.**
- **⚠️ The probe branch `claude/link-fullscreen-probe` is still on the remote and was never merged**
  — builds 131/132/133 came from it. **Owner must delete it in the GitHub UI**; the git proxy blocks
  branch deletion from a session. `grep TEMP-PROBE` on `main` is clean.

✅ **NINETEEN LINK PINS MERGED, ONE PULLED, AND THE PULL SQL IS APPLIED.**
[#638](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/638) squash `ce6ec46b` ·
[#641](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/641) squash `2f84df52` ·
[#642](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/642) (scratch files that rode in on a
`git add -A`). **This batch took linkPins 150 → 169 → 168 and makers 153 → 154.**

⚠️ **A PARALLEL SESSION'S [#640](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/640) LANDED
MINUTES LATER** (*"Thirty-two link pins, and the stack cap that demanded a place"*, squash
`cd32e293`), so read the counts above as **this batch's deltas, not the catalogue's totals**.
That session then closed itself out with two more merges — [#646](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/646)
squash `f172f07b` (**Jefferson Market Garden**, the one link it had parked for want of an
identifiable subject, wired on the owner's *"pretty sure it's jefferson market garden"*) and
[#647](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/647) squash `cec3aa39` (docs).

**`main` now carries 201 link pins · 184 makers · 38 places.** Pins and places were re-derived
from the **live Supabase RPC** after the last merge (201 · 38, confirmed); the maker figure is the
**catalogue's**, because ⚠️ **the RPC reports 194** — upsert-only accumulation plus real sign-ups,
long-standing and expected. **Assert on link-pin counts, not maker totals.** Both branches
auto-deleted. Its story is in
`CLAUDE.md` § Current State and `archive/HANDOFF-260829-2.md`. **Open PRs: [#657](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/657) (tooling, auto-merge class) plus the architect-vocabulary PR above.**

- **✅ THE SWAN & DOLPHIN HERO IS SETTLED — the owner keeps it** (*"i'm fine with the swan dolphin
  hero"*, 2026-08-29). Its YouTube thumbnail is a dark, indecipherable frame and **no better one
  exists** — `maxresdefault` and `sddefault` both 404 on that upload. **A hero audit will flag it
  again; it is closed**, like the Royal Hospital Chelsea and Ministry of Enterprise heroes above.
- **⚠️ Two of the thirty-five links are dead at the source and cannot be recovered from this end** —
  each returns a ~215 KB embed shell with no owner blob on six spaced fetches, against ~257–262 KB
  with one for a live post. **Only the owner re-sharing live links fixes those.**

- **✅ `backend/pull_pins_260829.sql` HAS BEEN RUN and verified against the live RPC** — `linkPins`
  **168**, all five pins gone (the Instagram Zacherlhaus plus the four from 2026-08-28 that had
  never been removed from Postgres), both pulled creator rows gone, `places` still 37 and
  `priceTier` still on all 1,553 with 66 priced. **Nothing is owed on the backend.**
- **✅ THE LAST OWNER CALL IS CLOSED: the Royal Hospital Chelsea hero stays** — *"keep chelsea,
  i'm fine with it"* (2026-08-29), though its thumbnail is a podcast talking head with no view of
  the building. **A hero audit will flag it again; it is settled.** Nothing from this work is open.

✅ **COPENHAGEN AND THE DANISH ARCHITECTS BOTH MERGED AND VERIFIED LIVE (2026-08-26).**
[#615](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/615) squash `1e966661` ·
[#616](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/616) squash `5196e459`. Both branches
auto-deleted. **Nothing is open from this work and nothing is owed on the backend** — the story
moves to `CLAUDE.md` § Current State, per this file's own rule.

- **Verified against the LIVE RPC, not the merge:** Atlas Studio CPH 🇩🇰 serving all 40 tours,
  `country: Denmark` on 40, `places` still 27 and `priceTier` still emitted (no keys dropped).
  Architect tags landed too — `Henning Larsen` 0 → 2, `Designed by a Master` 449 → 466. The
  gh-pages mirror converged about seven minutes after Supabase.
- **⚠️ OWED — no simulator or device review of #616.** Owner approved the merge without one. The
  visible effect is 24 new architect names as filter chips and 21 tours joining the
  "Designed by a master" shelf; no layout change, and CI's simulator build + unit tests were green.
- **🔴 STILL UNRESOLVED: an ATLANTA batch is staged on gh-pages with no tracker row.** gh-pages
  `c533f3c4` (2026-08-24) pushed 41 Atlanta images while `drafts/AUDIO-PENDING-SURVEY.md` said the
  queue was empty. Flagged in the tracker; **whether scripts exist, and on which branch, was never
  established.** Do not report the queue empty without re-deriving.

---

## 1b. Earlier board state (link pins)

**Eight PRs merged between 01:22 and 03:10. Zero are open.** The link-pin feature went from four
throwaway test pins to real content in under two hours.

✅ **BUILD 117 IS UP, FROM `main` AT `2a47e28`** — the tip itself, succeeded 03:33 with notes
attached. It carries #592 (the WALK pill below the metadata), which was the only merged app code not
in a build. **Nothing is stranded and nothing is open except the board PR below.**

🟡 **[#596](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/596) OPEN — this board, the contract
check and `restore_catalog_keys.sql` finally reach `main`.** All three had only ever existed on
`claude/project-tracking-dashboard-1kggmu`, so `CLAUDE.md`'s own session-start ritual
(`git show origin/main:STATUS.md`) has been 404ing for every parallel session. **Additive only: 5
files, +614, −0.** The branch was 41 commits behind, so `main` was merged in first and both conflicts
(`CLAUDE.md`, `backend/schema.sql`) resolved toward `main` — `schema.sql`'s newer warning is strictly
better, and rules 10/11 plus the 2026-08-20 block were re-added surgically.

✅ **THE TEST CREATORS ARE GONE — 49 makers → 45, verified against the live RPC.** Exactly the seven
real sign-ups remain, every one carrying a `user_id`. Places still 25, contract check passes.

**🔴 IT TOOK THREE PASTES, AND THE REASON IS WORTH KEEPING. THE TEST TOURS WERE TAKEN DOWN, NOT
DELETED.** Each of the four creators still owned one tour at `status = 'taken_down'` —
`takedown_tour()`, run in an earlier session. **A taken-down tour is invisible to every ordinary
read:** `get_catalog` serves published only, and so does the RLS policy behind PostgREST. So the
catalogue reported those creators had no tours, a direct API read agreed, and **both were wrong**.
Only a query run as `postgres` saw them.

- **⚠️ DURABLE RULE: anything reasoning about "does this maker have tours" must query the table as
  `postgres`.** Otherwise it is reading a filtered view and will conclude the exact opposite of the
  truth. The same applies to any tour count, any orphan check, any cleanup script.
- **⚠️ AND THE GUARD MADE IT INVISIBLE — the sharper lesson.** The first version's maker delete
  carried `not exists (select 1 from tours …)`, which the hidden rows failed, so the statement matched
  zero rows and reported *"Success. No rows returned."* **`tours.maker_id` is `on delete restrict`**,
  so without that guard Postgres would have raised a foreign-key violation naming the exact blocking
  row, and the answer would have arrived on the first paste. **A guard that turns a loud, specific
  error into silence is worse than no guard.**
- **⚠️ It could not be one statement:** `restrict` fires the moment the parent row goes, even when the
  child is being deleted alongside it. Tours first, then makers. `purchases.tour_id` is also
  `restrict`, so a tour that had ever been bought would raise rather than destroy the record of a sale.
- **The wider debt is unchanged and still real:** `seed_from_toursjson.py` is upsert-only, so nothing
  ever leaves the live database on its own. Every future removal needs a hand-written delete like
  this one. Worth fixing properly before launch.

## 1c. ✅ RESOLVED — build 66 can read the catalogue again

**Both fixes merged and are LIVE. Verified against both sources, not the PR descriptions.**

| | `tours` | `linkPins` | Build 66 decodes? |
|---|---|---|---|
| gh-pages mirror | 1,512, only `single`/`multiStop` | 4 | ✅ all of it |
| Supabase RPC | 1,513, only `single`/`multiStop` | 4 | ✅ all of it |

Top-level keys on both: `linkPins`, `makers`, `places`, `tours`. **Zero unfamiliar kinds inside
`tours`** — which is the whole test. Build 66 now catches up to the full catalogue on first launch
rather than freezing at its 1,350-tour August seed.

- **[#597](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/597)** — link pins move out of `tours`
  into their own top-level array, carried consistently through `Tours.json`, the gh-pages mirror
  (`publish-catalog.yml`), `seed_from_toursjson.py` and `get_catalog` (`backend/split_link_pins.sql`).
  New `LegacyCatalogCompatibilityTests` pins the guarantee.
- **[#598](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/598)** — per-field tolerance plus a
  tolerant array, and it **counts what it drops** rather than swallowing silently.

**🔴 WHY THIS WORKED AT ALL, and the rule to keep:** an unknown top-level KEY is free; an unknown
VALUE in a known field is fatal. `ToursData` uses synthesised `Codable`, which ignores keys it does
not know. Proven on this app before it was relied on: `sourceURL`, `sourceAuthor`, `country`,
`videoURLs` and `videoRole` were all added over time with no shipped build noticing. Nothing ever
broke until a new *value* appeared inside a field builds already parsed.

**⚠️ Tolerance could not have fixed this and must not be mistaken for the fix.** It protects only
builds shipped after it; build 66 is strict and always will be. The separate section is the only
thing that rescues an already-shipped build. Keep both — different jobs.

✅ **BUILD 118 IS LIVE, FROM `main` AT `d80465b`** — the tip itself. It is the first build that reads
`linkPins`, so the four creator pins reappear after being absent from 116 and 117. **The one-build
lag is closed and nothing merged is stranded.**

⚠️ **118 changed HOW THE CATALOGUE IS READ, so ordinary browsing is the real test** — home map, a few
cities, a walk, the library. A decode regression would not look like a decode regression; it would
look like content quietly missing.

⚠️ **Build 66's release decision is now the owner's, unblocked.** It can be released safely, or
replaced with something current. It is still eight days and three cities behind in what it ships in
the box; it just no longer stays that way.

⚠️ **A cloud session cannot be messaged from a web session** — `ListAgents` does not reach it and
`SendMessage` fails. A session briefed on tolerance only had to be archived and replaced rather than
corrected. **Brief a spawned cloud session completely up front.**

## 1b. ✅ RESOLVED — the catalog regression, fixed and verified

**Owner ran `backend/restore_catalog_keys.sql` 2026-08-20, and has since confirmed on device that
the place pages and capsule pins are back.** Verified against the live RPC as well, not just the
success message:

| | Before | After |
|---|---|---|
| `places` | absent | **25** ✅ |
| `priceTier` | absent on 1419 tours | present on 1419, **66 priced** ✅ |
| `isPrivate` | absent on 39 makers | present on **39** ✅ |
| `country` | 1418 | **1418** — held ✅ |
| `videoURLs` · `userId` | intact | intact ✅ |

All 25 places carry ≥2 tours, so every one renders. **`country` holding is the specific proof that
mattered** — re-running `places_apply.sql` instead would have restored places and knocked country
back out, which is why the separate file existed.

**Cause, for the record:** `add_country.sql` rebuilt `get_catalog()` from `schema.sql`'s body —
correctly, by its own design — but `schema.sql` had never carried `places`, `priceTier` or
`isPrivate`, all added by later migrations. Nothing errored; all three are optional in Swift, so
the features silently stopped existing. **Not a code fault, and not build 91's.**

**Hardened, two ways.** `schema.sql` now carries both missing keys plus a 🔴 warning that the
function is wrapped in production and every later key must be added there too. And there is now a
check that runs whether or not anyone is paying attention:

**`scripts/check-catalog-contract.py`** — queries the live RPC and diffs its key set against the
Swift models. The expected keys are **parsed out of `Models/Tour.swift`, `Maker.swift` and
`Place.swift`**, never hardcoded, so adding a field starts requiring it on the next run with no
edit to the script. A hardcoded list would drift and quietly stop testing anything, which is the
exact class of bug it exists to catch.

**It works: its first run found a fourth missing key nobody knew about** — `tours[].createdAt`.
That one is **pre-existing, not a regression** (the RPC has never served it). `Place.ranked` sorts
NEWEST FIRST on it, so that rule has no dates to sort on and falls through to its tiebreaks.
⚠️ **Do not "fix" it by emitting `tours.created_at`** — that column is `default now()` and the seed
never carries the authored date, so it holds *seed* time; most of the catalog shares 2026-06-27,
the original bulk seed. It would look fixed and rank wrongly. The real fix is to make
`seed_from_toursjson.py` carry the authored `createdAt` first. Recorded in the script as a **known
gap**: printed as a warning every run, but not a failure — a check that always fails gets ignored,
and then it catches nothing.

## 1d. ✅ DOZENT IS LIVE ON THE APP STORE

**Owner-reported 2026-08-28: approved by Apple and published.** Submitted 2026-08-18 03:22 UTC as
version 1.1 on **build 66**, `releaseType` MANUAL, so the owner pressed Release themselves. Ten
days from submission to live. **This is the first public release; every prior build was TestFlight.**

⚠️ **Not machine-verified from this session** — a remote container has no App Store Connect key
(`~/Downloads/AuthKey_*.p8` lives on the owner's Mac), so `scripts/session-start.sh` skips the
check here. The owner is the primary source and outranks any document; a local session should
confirm the live version/state from the API before quoting numbers back.

**🔴 WHAT CHANGES NOW, AND IT CHANGES THE STAKES OF EVERY CONTENT MERGE.** Until today a bad
catalogue reached TestFlight testers. It now reaches **App Store users on build 66**, which is a
strict decoder frozen at 18 August:

- **Build 66 has no tolerance layer.** [#598](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/598)'s
  per-field fallbacks and tolerant array **only protect builds shipped after it**. On 66, one
  unfamiliar value inside a known field still fails the whole catalogue decode, silently, and the
  phone keeps its last good copy forever.
- **What saves it is [#597](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/597)** — link pins
  travel in their own `linkPins` array, which 66 ignores as an unknown key. **That split is now
  load-bearing for a shipped App Store build. Never put a `kind: "link"` row back inside `tours`.**
- **The three guards that enforce it must stay green**: `scripts/check-catalog-keys.py`,
  `publish-catalog.yml`'s mirror refusal, and `validate-tours.swift`.
- ⚠️ **Build 66 bundles 1,350 tours against 1,552 live** — it catches up on first launch from
  Supabase, which is exactly the path the split protects.

**Owed, and worth doing before the next release:** ship an update, because every fix since
18 August — the launch sequence, offline photographs, fullscreen video, the search rewrite, the
link-pin fullscreen fix — is **not** in what the public has. Build 135 is the candidate.

## 2. Blocked on owner — outside the repo

**🔴 A DEAD TIKTOK LINK NEEDS RE-SHARING (2026-08-27).** `https://www.tiktok.com/t/ZP8vkb5bP/`, the twentieth of the "SF Architecture" batch, resolves to a real id (`@aggie.sanfrancisco/video/7660328152421387534`) and then fails everywhere: an empty oEmbed shell on three spaced attempts (no `thumbnail_url`), and a 367 KB *"Video currently unavailable"* page with zero `og:` tags. No caption means no subject and no location; no thumbnail means no hero, and a pin with no hero cannot ship. **Nothing on our side recovers it — only the owner re-sharing a live link.** ⚠️ It is an ordinary `/video/` post that has gone, **not** a `/photo/` carousel; that limitation is separate and permanent.


Nothing here can be done from a session. Ordered by what blocks the most.

| Item | Why it matters | State |
|---|---|---|
| ~~**App Store 1.1 review**~~ | ✅ **APPROVED AND LIVE** — owner-reported 2026-08-28. Submitted 2026-08-18 03:22 UTC on build 66. See § 1d. | ✅ Done |
| **Stripe platform review** | Response submitted; account flagged under Restricted Businesses. | ❓ Awaiting Stripe reply |
| **9 IAP tiers `MISSING_METADATA`** | Each needs a review screenshot at its real price. Deliberately blocked: every walk is $0.99 today, so a genuine $2.99 screenshot cannot exist yet. | ⏸ Blocked by design |
| **EU trader declaration** | App declared **non-trader** while selling ten IAP tiers into EU cities. Declaring trader publishes an address. | 🔴 Decision owed |
| **LLC vs sole proprietor** | Gates the Stripe payout path, and collapses the EU-trader and the AHWY/EHKY-initials trade-offs at once. | 🔴 Decision owed |

### SQL pastes owed (Supabase SQL Editor, project **Dozent**)

✅ **Applied:** `add_country.sql` (Countries row live) · `restore_catalog_keys.sql` (places, priceTier,
isPrivate restored 2026-08-20) · **`pull_la_duplicates_260830.sql` (owner ran it 2026-08-30 —
verified against the live RPC, not the SQL Editor's success line: all four deleted rows gone, all
three survivors present, `TikTok @thedesigndetourist` still at 19 pins, 0 pins wrongly inside
`tours`, `priceTier` and `isPrivate` both intact. **Nothing is owed here — do not ask again.**)**.

| File | Unlocks | Without it |
|---|---|---|
| `backend/saved_places.sql` | Saved places syncing across devices | Saving works, stays on one device |
| `backend/places_photos.sql` | Places serving their own photographs | Optional — the app is correct without it |

## 3. Builds — which run number carries what

🔴 **Build numbers are `github.run_number` and are SHARED across every branch.** Read them back
after dispatching; never promise one in advance. And a build carries its branch's **merge-base**,
not `main` — GitHub reports a PR's base as main's current tip, which is misleading.

| Build | Branch | Carries | Result |
|---|---|---|---|
| **137** | `instagram-player-fit` | #662 the Instagram crop + fullscreen scrubber, `main` merged in, **marketing version 1.1.1** | ✅ **owner-verified — *"works! thank you"*; #662 merged as `845f0d86`** |
| 136 | `instagram-player-fit` | Same code at **1.1** (`49ac5382`) | 🔴 **rejected at upload** — 1.1 is released, so Apple refuses the version string |
| **134** | **`main`** | #622 the real fullscreen fix — the video's own window (`e22dba7`) | ✅ **install this** |
| 133 | `link-fullscreen-probe` | Same fix + the temporary readout (`f6aaf78c`) | ✅ owner-verified — *"that seem to be done the trick"* |
| 132 | `link-fullscreen-probe` | `isElementFullscreenEnabled` theory + probe (`839d2296`) | 🔴 wrong theory — probe proved it |
| 131 | `link-fullscreen-probe` | The probe readout alone (`773727ae`) | ✅ diagnostic — this is what cracked it |
| 130 | **`main`** | #617 the `onDisappear` guard (`adbe3b94`) | 🔴 shipped as "the fix"; was not |
| 129 | **`main`** | #611 withdraw the module on `fullscreenState` (`8df37de8`) | 🔴 shipped as "the fix"; was not |
| 128 | **`main`** | Everything, from the tip (`43c9411a`) — functionally identical to 127 | ✅ superseded |
| 127 | `open-source-ai-integration-pxuxdh` | #605 search + map, merged as `43c9411` | ✅ superseded |
| 126 | `instagram-best-effort` | #606 Instagram, merged as `2ecb95a9` | ✅ owner-verified — superseded |
| 125 | `open-source-ai-integration-pxuxdh` | #605 search, branch caught up to `main` (`73364503`) | ✅ superseded |
| 124 | `open-source-ai-integration-pxuxdh` | Merged app code + #605's then-unmerged search work (`fc94f197`) | ✅ superseded |
| 123 | `open-source-ai-integration-pxuxdh` | Same work, earlier commit (`2f1784e9`) | ✅ superseded |
| 122 | **`main`** | #603 Instagram tap (`e106fd3e`) | ⚠️ carries the behaviour #604 withdrew |
| 121 | `new-task-i2k12e` | #601 list-page grid + sort (`33d2b0c4`) | ✅ owner-verified — *"121 went live. Looks good."* |
| 120 | `new-task-i2k12e` | #600 place-page grid + sort (`ad1ff15e`) | ✅ owner-verified — *"120 is live. works"* |
| 119 | `new-task-i2k12e` | Same work, one commit earlier (`8b4e6cdc`) | ✅ superseded |
| 118 | **`main`** | #597 link pins split out + #598 decode tolerance (`d80465b`) | ✅ superseded — owner-verified, pins visible |
| 117 | **`main`** | #592 WALK pill, on the real AMNH pins (`2a47e28`) | ✅ superseded — shows no link pins |
| 116 | **`main`** | #584 link pins + #585 YouTube/Short fixes (`233eb912`) | ✅ superseded — shows no link pins |
| 115 | **`main`** | #583 the stale hero fix (`8f5748b7`) | ✅ superseded — **un-frozen by #597** |
| 114 | **`main`** | Fullscreen video, Swedish architects, Akalla hero, `get_catalog` hardening (`8d2ad947`) | ✅ superseded |
| 113 | `chrome-row-modifier` | #576 chrome row extracted — head merged `main` at 13:14 (`e90d9995`) | ✅ superseded |
| 112 | `color-mismatch-elements-pj2ptt` | #573 chrome row made opaque | ✅ merged |
| 111 | **`main`** | #565 architects, #566 launch mark, #567 + #568 offline photographs (`891702fd`) | ✅ last true from-main build |
| 110 | **`main`** | Everything to 22 Aug, plus #563 light mode (`b421bde9`) | ✅ superseded |
| 109 | `launch-performance-animations-df4d7p` | #559 launch sequence (`52a86cfa`) | ✅ superseded by 110 |
| 108 | `launch-performance-animations-df4d7p` | Same work, one commit earlier | ⚠️ superseded |
| 98 | `wizard-comments-round2` | #558 wizard round two (`e0132c90`) | ✅ merged |
| 97 | `wizard-comments-round2` | Same work, one commit earlier | 🔴 **Live and installable, run shows RED, no notes** |
| 96 | `upload-wizard-improvements-ejopz3` | #552 the seven-step wizard | ✅ owner-verified — *"so much better"* |
| 95 | `ellipsis-button-consistency-vdorpi` | Became #555 — Liked on the shared list screen | ✅ merged |
| 94 | `ellipsis-button-consistency-vdorpi` | #553 list page as a layer | ✅ owner-verified, merged |
| 93 | `library-launch-jitter` | #549 Library launch jitter | ✅ merged |
| 91 | `main` | Wizard, Settings, list page, 5:4 heroes | ✅ owner-verified |
| 90 | `tour-upload-polish-qiliop` | #540 + the saved-tour hang fix | ✅ owner-verified — hang closed |

✅ **#552 merged `main` in before merging out** (`a9a3b32`, two real conflicts resolved by hand) — so
the stale-base warning this board carried against build 96 was dealt with by the session itself.


## 4. Branches

| Branch | State |
|---|---|
| `claude/tour-links-upload-tbcerj` | **This session, pushed, no PR** — twenty link pins (15 × `@breatheart_hk` Hong Kong). Cut off `origin/main` `05e90f47`, **rebased onto `00a420bd`** after #640 and three doc commits landed mid-session; catalogue edit redone by re-running the idempotent assembler against the new `main`, never hand-resolved. gh-pages `a8a81767` |
| `claude/tour-links-upload-wa3e0g` | Merged (#640, squash `cd32e293`) — 32 pins. ⚠️ **Its branch diff was 33 pins, not 32**: it carried the Instagram Zacherlhaus the owner pulled in #641. Flagged pre-merge; **checked after and the pull held** — only the TikTok Zacherlhaus is on `main` |
| `claude/tour-links-upload-qeoxe7` | **Merged as [#648](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/648); follow-up places PR open** — twenty-three link pins from three creators (18 TikToks `@thedesigndetourist`, 4 Instagram `@shaunbirley`, 1 `@meliluu__`); linkPins 168 → 191, makers 154 → 157. Content only, images live on gh-pages at `251cf95e`. **🔴 MERGE HAZARD, NOW THE OTHER SESSION'S: this branch created the `TikTok @thedesigndetourist` maker row (uuid5 `67CA14A6-…`) and a parallel session's unmerged branch creates the identical id — that branch must drop the duplicate or the validator errors.** ⚠️ Ships two subjects twice on one coordinate each (Westin Bonaventure, Hotel Casa del Mar) — deliberate, both links were sent; `check-place-candidates.py` therefore reports 3 EXACT groups against main's 1 |
| `claude/link-fullscreen-probe` | 🔴 **Never merged, still on the remote** — carried the temporary readout and builds 131/132/133. **Owner deletes it in the GitHub UI**; the git proxy blocks branch deletion from a session |
| `claude/link-fullscreen-window` | Merged (#622, squash `e22dba7`) — the real fullscreen fix |
| `claude/link-fullscreen-module-ojs556` | Merged (#617, squash `adbe3b94`) — the `onDisappear` guard. ⚠️ The designated branch name; the first attempt's work was actually on `claude/link-fullscreen-module` |
| `claude/link-fullscreen-module` | Merged (#611, squash `8df37de8`) |
| `claude/new-tour-links-nniny1` | Merged (#626, squash `303012b3`) — nineteen San Francisco architecture link pins. **Verified live on BOTH sources afterwards**, not on the merge: the RPC and the gh-pages mirror each serve 76 link pins with 0 wrongly inside `tours`, and `places` / `priceTier` / `isPrivate` all survived. ⚠️ Restarted from `origin/main` for this board update — never stacked on merged history |
| `claude/new-tour-links-yr5o7r` | **Open as [#627](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/627)** — ten "Atlanta Architecture" TikToks, **nine shipped as link pins; the tenth (Mercedes-Benz Stadium) pulled by the owner over a probably-AI hero**. Cut clean off `origin/main` `c5e8862`, then **merged `main` in to resolve a four-way conflict with #626** (both batches touched `Tours.json`, `CLAUDE.md`, `STATUS.md`, and both claimed `archive/HANDOFF-260827.md`). Content only. Images live on gh-pages at `a93c06d4`. |
| `claude/tiktok-orlando-links-ziegoe` | **Restarted from `origin/main` after #621 merged** — now carries the Orlando *architecture* batch (10 pins, commit `da9c96ad`). ⚠️ Same branch name, fresh history: never stacked on merged commits. |
| ~~`claude/tiktok-orlando-links-ziegoe` (first run)~~ | Merged as #621 (squash `1c05613b`) — nine Orlando link pins, live on Supabase |
| `claude/library-launch-jitter` | Merged (#549 at 03:52) — auto-delete should remove it |
| `claude/upload-wizard-improvements-ejopz3` | Merged (#552 at 19:05) |
| `claude/wizard-comments-round2` | Merged (#558) and deleted |
| `claude/launch-performance-animations-df4d7p` | Merged (#559 at 16:43) — built as 108/109 |
| `claude/milan-tours-upload` · `claude/milan-docs-260822` | Merged (#560, #561) |
| `claude/coordinate-guard` | Merged (#562 at 17:20) |
| link-pin branches (#584, #585, #586, #587) | All merged 20:59–22:51; auto-delete should remove them |
| `claude/link-pin-batch-workflow` | Merged (#588 at ~01:40) |
| link-pin follow-ups (#589–#595) | All merged 01:40–03:10 |
| `claude/ellipsis-button-consistency-vdorpi` | Merged twice from one branch (#553, #555). ⚠️ The second stacked on already-merged history, which CLAUDE.md says to avoid — it worked, but no PR existed while build 95 was installable |
| `claude/tour-upload-polish-qiliop` | Merged (#540) — auto-delete should remove it |
| `claude/stripe-questions-fjhdo3` | ⚠️ No PR — verify contents before deleting |
| `claude/amsterdam-handoff-preserve-hlhyp8` | 🔒 Keep — only copy of staging pick-maps |
| `claude/web-landing-site-preserve` | 🔒 Keep — only copy of the Next.js landing site |
| `claude/london-batch3-scripts-260616` · `claude/paris-scripts-260622` · `claude/dreamy-wozniak-tags-260612` | 🔒 Keep (documented archival) |

## 5. Content

**⚠️ Re-derived from `Tours.json` on 2026-08-29 (session 122, after merging #640): 1,552 tours + 244 link pins, 189 maker rows (34 Atlas studios + 155 pinned creators — 98 TikTok, 44 Instagram, 13 YouTube), 1,924 tour stops, 38 places, 36 countries.** Twenty pins added on branch `claude/tour-links-upload-tbcerj`; **no PR opened** (harness forbids it unasked). **🔴 THREE LINK-PIN SESSIONS WERE IN FLIGHT SIMULTANEOUSLY ON NEAR-IDENTICAL BRANCH NAMES** (`…-tbcerj`, `…-wa3e0g`, plus a third pushing 23 heroes straight to gh-pages), so **deduping against `main` alone is no longer sufficient** — check the open PRs' branches too, and re-check after each merge. **⚠️ The Key-facts line written an hour earlier said 201 pins / 149 creators against a real 200 / 149, so not one session's own number has survived its merge.** **✅ Duddell Street Steps is now a place (places 38 → 39), built on owner instruction** from the Atlas tour and the new pin, which sat 9 m apart under the same name. ⚠️ **Neither member is geofenced**, so the pin moved on the CalAcademy rounding-artifact reasoning rather than the usual geofence one; the place hero is a **third** photograph promoted from the tour's own gallery; and **the two members disagree on three dates, so the place copy asserts none of them.** **⚠️ Four heroes are weak and one badly so**: the Bird Bridge pin's thumbnail is a red X the creator drew over a photograph to retract an earlier post, so it renders as a red X on the map (the Hugo de Grootplein shape). The Mercedes-Benz Stadium precedent says the owner may pull it.

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 119, this batch): 1,552 tours + 124 link pins, 133 maker rows (34 Atlas studios + 99 pinned creators — 83 TikTok, 11 YouTube, 5 Instagram), 1,924 tour stops.** **Places 30 → 31: Barcelona Pavilion**, built on owner instruction from the Atlas tour and the new pin (77 m apart, same subject) — **the pin moved onto the geofenced tour, never the reverse**. Twenty-three pins added on branch `claude/tour-links-paste-thsd6q`, open as **[#632](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/632)** (owner asked for it). ⚠️ **#632 moves a GEOFENCED tour 78 m** — the Atlas *Mies van der Rohe Pavilion* onto the building — **on explicit owner instruction, overriding "the pin moves, never the tour"**; the move improves the geofence (old point was 64 m outside the building's edge, so standing at the pavilion did not fire it) and is recorded in `CLAUDE.md` so it is not reverted. ⚠️ **This batch adds NO new country** — India and Mexico both look new against the 22 that `tours` span, and both were already in the catalogue via existing link pins (Maya Somaiya Library; two Mexican food pins). **The catalogue spans 30 countries across tours AND pins, and it did before this batch too — never quote the tours-only figure as the catalogue's.** ⚠️ **This is the first batch where Instagram arrives at scale** — 6 reels across 4 creators, all playable inline, and **all four Instagram makers ship `avatarURL: null`** because Instagram's embed exposes no creator avatar; they fall back to the platform mark. ⚠️ **Pinned creators now outnumber Atlas studios almost three to one**, so the raw `dataService.makers.count` in Settings → About is further past the tipping point flagged when there were four pins; the owner's decision (userId-only / published-tour-only / split the row) is **still owed and getting worse each batch**.

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 117, after merging #626 and #625): 1,552 tours + 85 link pins, 99 maker rows (34 Atlas studios + 65 pinned creators), 1,924 tour stops.** **⚠️ THREE CONTENT BATCHES LANDED WITHIN TWO HOURS** — nineteen San Francisco pins (#626), four Orlando architect names (#625) and ten Atlanta pins (#627, of which nine shipped). **#626 and #627 conflicted in four files, including an add/add on the same handoff filename**, and #627 had to merge `main` twice. Expect that whenever content sessions run in parallel. **⚠️ THE ATLANTA TOUR BATCH IS ALSO IN FLIGHT** and is in the tracker: 30 single-stop tours, 30 MP3s outstanding, under a new **Atlas Studio ATL**. Its Oakland Cemetery tour will land beside #627's pin for the same site. **The audio-pending queue is NOT empty.**

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 116): 1,552 tours + 76 link pins, 90 maker rows (34 Atlas studios + 56 pinned creators — 46 TikTok, 9 YouTube, 1 Instagram), 1,924 stops. Live-confirmed on both the Supabase RPC and the gh-pages mirror after #626 merged.** ⚠️ The RPC reports **1,553 tours / 98 makers** against that — the long-standing `Zxxx` test tour plus upsert-only maker accumulation, both pre-existing. **Assert on link-pin counts, not maker totals.** The paragraph below predates Copenhagen and the last three link-pin batches and its figures are stale — **re-derive, do not quote.** **🔴 Pinned creators now outnumber Atlas studios nearly two to one**, so the raw `dataService.makers.count` in Settings → About has passed the tipping point flagged when there were four pins; the owner's decision (userId-only / published-tour-only / split the row) is still owed. **⚠️ An ATLANTA batch is still being staged by another session and is still not in the tracker** — a gh-pages push landed mid-session (MLK Birth Home ×7 + the Candler Building). Do not report the audio-pending queue as empty without re-deriving.
**⚠️ THE PARAGRAPH BELOW IS STALE AND IS KEPT ONLY FOR ITS LIVE-RPC NOTES — re-derive, do not quote.** Its figures predate Copenhagen and the last five link-pin batches, and **its claim that the audio-pending queue is EMPTY is now false**: Atlanta sits in it with 30 tours awaiting narration.

**Catalog 1,516 tours live / 45 maker rows served** (49 before the test-creator cleanup). The four `TEST -` pins are gone (#593),
replaced by **4 real AMNH creator link pins** (#591). **7 served makers have zero tours**, all of them real sign-ups who have not published yet. — **Stockholm (Atlas Studio STO, 45 tours) landed 2026-08-24**
and is live in the RPC, along with VIA 57 West. Milan (48 tours) landed 2026-08-22. ⚠️ The RPC reports **40** maker rows against a true 32: upsert-only accumulation,
long-standing. The audio-pending queue is **EMPTY**. `drafts/AUDIO-PENDING-SURVEY.md` on `origin/main` stays the
authority; read it from `origin/main`, never from a branch.

## 7. Verification traps — each one produced a wrong answer here

Not general advice. Every entry below is a check that **returned a confident, wrong result** on this
repo, and the correction that makes it honest.

- 🔴 **A MERGED PR IS NOT EVIDENCE THAT NO BUILD CARRIES IT.** This board twice reported "nothing
  waiting on a build" from a list of merged PRs without re-reading the run list in the same turn, and
  was wrong within five minutes both times — another session had already built the work from its own
  branch. **Re-read the Actions run list in the same turn as any claim about what is waiting**,
  including when the answer is "nothing".
- 🔴 **`git diff` AGAINST A COMMIT GIT DOES NOT HAVE RETURNS EMPTY** — indistinguishable from "no
  differences". Branches auto-delete on merge, so a build's commit is routinely unreachable. **This
  produced a false clean twice in one session.** Fetch `refs/pull/<n>/head`, confirm with
  `git cat-file -t`, and only then trust the diff.
- 🔴 **A TAKEN-DOWN TOUR IS INVISIBLE TO EVERY ORDINARY READ.** `get_catalog` serves published only,
  and so does the RLS policy behind PostgREST. On 2026-08-25 the catalogue reported four creators had
  no tours, a direct API read agreed, and **both were wrong** — each still owned one `taken_down` row,
  which is why a delete matched nothing three times. **Anything reasoning about "does this maker have
  tours" must query the table as `postgres`.**
- 🔴 **A GUARD THAT TURNS A LOUD, SPECIFIC ERROR INTO SILENCE IS WORSE THAN NO GUARD.** That same
  delete carried `not exists (select 1 from tours …)`, which the hidden rows failed — so it reported
  *"Success. No rows returned."* Without the guard, `tours.maker_id` being `on delete restrict` would
  have raised a foreign-key violation **naming the exact blocking row**.
- ⚠️ **A GREEN `publish-catalog` RUN IS NOT PROOF THE CATALOGUE CHANGED.** It reported success while
  the live RPC still served the old place count for three more checks. **Ask the RPC.**
- ⚠️ **A SPAWNED CLOUD SESSION MAY HAVE NO GITHUB TOOLS, AND CANNOT BE MESSAGED FROM A WEB SESSION.**
  One spawned 2026-08-26 wrote the link-fullscreen fix, could not open a PR, and sat blocked eight
  hours while another session solved it independently; **its branch was never pushed, so the work was
  lost with the container.** Brief a spawned session completely up front, tell it to **push its branch
  early**, and check on it rather than reading silence as progress.

## 6. Known debt — real, not urgent

**⚠️ UNGROUPED PLACE CANDIDATES, catalogue-wide (2026-08-27, owner asked for report-only).**
Re-derive with **`python3 scripts/check-place-candidates.py`** — do not quote the table below.

**🔴 ONE EXACT COINCIDENCE WITH NO PLACE PAGE, and it is a known deferral, not a new fault.**
**Casa Lleó Morera** and the **Dreta de l'Eixample** walk share the coordinate
`41.39134849385539, 2.16545472553582` exactly — the walk's intro stop is wired to the landmark, the
standard convention. CLAUDE.md already records it as *"a place candidate, deliberately NOT created
here (a place needs its own copy, address and photograph; that is separate editorial work)."*
**⚠️ The checker exits 1 on it, so a clean exit is not the current expected state** — that is the
one outstanding item, and it clears the moment someone writes the Barcelona place.

**NEAR — same subject, not coincident. None is acted on.**

| pair | apart | note |
|---|---|---|
| The Jordaan / The Jordaan (Amsterdam) | 136 m | **Identical titles.** Could be a place or could be a duplicate — open both before deciding |
| Gamla stan 1859 / Gamla stan (Stockholm) | 301 m | A historical tour and a present-day one of the same quarter |
| Benesse House Museum / …Outdoor Works (Naoshima) | 455 m | The museum vs its outdoor works |
| Tibidabo / Tibidabo Amusement Park (Barcelona) | 48 m | **🔴 NOT a candidate — settled.** #541 left these separate: a mountain and a funfair are two subjects. Do not re-raise |
| Chinatown (pin) / two Atlas Chinatown tours (SF) | 257 m, 395 m | **Owner declined 2026-08-27** — a district is not a site. Do not re-propose |

**🔴 THE PROCESS GAP THAT PRODUCED THIS ROW.** The SF batch shipped three place candidates without
anyone asking — the owner spotted them on a glance at the map. The evidence was in hand at the time
(two pins on an exactly identical coordinate, and two hero-slug collisions against existing Atlas
tours) and was read only as a rendering and filename concern. **A place-candidate sweep now runs as
part of the link-pin batch checks** so this never depends on a session noticing again.

**🔴 AND #629 MERGED AS AN EMPTY COMMIT.** The places were committed onto the local `main` by
mistake, then `git push -u origin <branch>` pushed the branch ref — still at an already-merged
commit. CI went green, GitHub said "successfully merged", and nothing shipped; re-landed as #630.
**"Successfully merged" is not evidence anything landed. Check `git log origin/main..HEAD` before
pushing and confirm the squash changed files afterwards.**



- **Supabase over-reports.** The RPC serves ~1,419 tours / 39 makers against a true 1,418 / 31.
  Upsert-only accumulation: rows deleted from `Tours.json` are never deleted from the database.
  Any count shown in-app inherits this.
- **2 dead gallery images** — The Oculus and The Charging Bull, Wikimedia 404s, deferred since
  2026-06-21.
- **Square Saint-Louis** is the one place still repeating an image; needs one sourced photo.
- **15 tours** missing a Place-type or Theme tag (validator warnings, content-only fix).
- **Policy pages** are long legal prose at 13px monospace — readability at length unconfirmed.

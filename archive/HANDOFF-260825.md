# HANDOFF 2026-08-25 — session 110 (part 1): link pins leave `tours`

Web session (Linux, no Swift toolchain, no Mac). Branch
`claude/catalog-forward-compat`. **Code + content + backend — needs owner OK and
a simulator look before merge**, per CLAUDE.md § Merging PRs.

⚠️ **GitHub API access was NOT enabled for this session** (`403: GitHub access is
not enabled for this session`), so no PR could be opened from here and CI could
not be dispatched. The branch is pushed; the PR has to be opened by hand or by a
session that has API access. Everything below was verified locally instead.

---

## What was wrong

Four `kind: "link"` pins went into the live catalogue on **2026-08-24 at 22:51**.

`ToursData` decodes `let tours: [Tour]` as **one array**, `TourKind` is a closed
`String` enum with no custom `init(from:)`, and `RemoteCatalogLoader` wraps the
decode in `try?` at three sites (lines 242, 296, 302). So **one** tour carrying a
value the build does not know fails the **entire** catalogue decode; `try?` turns
that into `nil`; the loader reads `nil` as a failed fetch, keeps its last good
copy, and logs nothing.

No crash. The phone silently stops receiving all new content.

**Every build before 116 has been frozen since that timestamp — including build
66, at Apple in "Waiting for Review", submitted 17 August.**

### Verified, not assumed

| Claim | How it was checked |
|---|---|
| Build 66 is strict, forever | Fetched its own source at `2bcf0df2`: `struct ToursData { let makers; let tours }`, `enum TourKind { case single; case multiStop }`. No `country`, no `videoRole`, **no `Place` type at all** |
| Build 66's catalogue is 1,350 / 30 | Fetched its bundled `Tours.json` at the same commit |
| Live is 1,516 / 37 | Fetched `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/Tours.json` |
| 166 tours missing | Set difference by id: 156 single, 6 multiStop, 4 link. Barcelona 53 (+ Montserrat 6, Sant Just 2, El Prat 1, Santa Coloma 1), Milan 47, Stockholm 41 |
| The gh-pages mirror is the bundled seed | sha256 of both matched exactly; `publish-catalog.yml` copies the one file |
| Four link pins, one stop each | Counted in the live payload |

---

## The fix, and why it is the only one that reaches backwards

🔴 **An unknown top-level KEY is free. An unknown VALUE in a known field is
fatal.** That is a fact about *this app*, not a claim about Swift: `sourceURL`,
`sourceAuthor`, `country`, `videoURLs`, `videoRole` and `places` have all been
added to the catalogue and every shipped build carried on. Nothing has ever
broken until `kind: "link"` appeared **inside** a field builds already parsed.

So link pins move to a sibling **`linkPins`** array. Old builds read `tours`,
find only words they know, and ignore the rest. New builds decode `linkPins` and
merge it into `tours` at decode, so map, rails, search, library and the place
page are untouched.

**Tolerance cannot do this.** Tolerance protects builds shipped *after* it. Build
66 is already at Apple. This is why part 1 exists and why it comes first.

### The proof (`LegacyCatalogCompatibilityTests`)

Build 66's model layer is transcribed **verbatim** into the test file and used to
decode the **real shipped `Resources/Tours.json`** — not a fixture.

```
BEFORE — pins inside `tours` (the shape live right now):
  -> THREW: dataCorrupted at .tours[1512].kind: invalid String value 'link'
  -> RemoteCatalogLoader's `try?` turns that into nil: 0 tours reach the phone.

AFTER — pins under their own top-level `linkPins`:
  -> DECODED: 37 makers / 1512 tours
     (unknown top-level keys skipped: ['linkPins', 'places'])
```

⚠️ **Do NOT "update" `private enum Legacy` in that test to match `Models/`.** It
is a frozen record of what is already on people's phones. The moment it tracks
the current models, the test stops testing anything.

The negative control relabels one *ordinary* tour `kind: "link"` inside `tours`
and asserts the whole catalogue is lost — content-independent, and without it the
test would pass against a decoder that never rejects anything.

---

## All four places carry the same shape

A mismatch here reintroduces the bug the moment the source above it is
unreachable, so each was checked rather than assumed.

1. **`Resources/Tours.json`** — 1,512 in `tours`, 4 in `linkPins`, appended last
   for the smallest diff. Byte-stable under a Python re-dump at
   `indent=2, ensure_ascii=False` + trailing newline (verified before editing).
   Asserted afterwards that tour *content* is identical and `tours` order is
   preserved — only placement changed.
2. **The gh-pages mirror** — nothing to do: `publish-catalog.yml` copies the
   bundled file byte-for-byte. Its validation gate now **refuses to publish** a
   catalogue with a link pin inside `tours`.
3. **`backend/seed_from_toursjson.py`** — new `merge_link_pins()` folds
   `linkPins` back into `tours` on load. 🔴 **The split is a WIRE-FORMAT concern,
   not a storage one**: in Postgres a pin is still an ordinary `public.tours` row
   with `kind = 'link'`. ⚠️ It must run **before** `validate_places` — the AMNH
   place legitimately names link pins among its members. Output unchanged: 37
   makers / 1,516 tours / 1,888 stops / 25 places, 4 `'link'`.
4. **`get_catalog`** — `backend/split_link_pins.sql`. **Owner must run this.**

### The migration, and why it does not touch `get_catalog()`

🔴 Replacing `get_catalog()` with an inline body severs the composition and
silently drops every place, price and private account, with **no error**.

This file repeats the move `places.sql` invented, one level down: rename
`get_catalog_core` aside to **`get_catalog_core_base`** — so its body, volatility
and security attribute all carry over untouched — and create a new
`get_catalog_core()` that calls it and lifts `kind: "link"` out of `tours`.
`get_catalog()` still says `get_catalog_core() || { places: … }` and needs no
edit; `||` merges at the top level so `linkPins` rides through beside `places`.
**Nothing is parsed, so formatting drift cannot break it.**

⚠️ **The new layer is deliberately SECURITY INVOKER** (note the absence of
`security definer`). The base is invoker too, so the privilege chain is exactly
what it was. Making this layer `definer` would change who RLS evaluates the base
as — that is how anon starts seeing unpublished tours. Do not "tidy" it in.

⚠️ **The function holding the tour keys is now `get_catalog_core_base`.**
`add_video_role.sql`'s finder searches `proname in ('get_catalog_core',
'get_catalog')` and must gain the new name — or better, search by *content*.
It fails closed (raises rather than guessing), which is the failure mode we want.
Recorded in `backend/README.md` and in `schema.sql`'s banner.

### Verified against real Postgres

`backend/test-migrations.sh` now applies `split_link_pins.sql` too. Its fixture
gained a link pin, a `makers` key, and the `anon`/`authenticated` roles Supabase
ships (a grant fails without them for reasons nothing to do with the migration).

```
  ok add_video_role.sql
  ok add_link_pins.sql
  ok split_link_pins.sql
MIGRATIONS OK - 3 applied, idempotent, all catalog keys and places intact
```

**Broken on purpose, twice, to prove the guards fire:**

- Neuter the split so pins stay in `tours` → the migration's own verify block
  raises *"1 link pin(s) are still inside tours after the split"* and rolls back.
- Sever `get_catalog` wholesale → *"get_catalog() does not emit linkPins — the
  wrapper did not take"* on the next run. (Its first run passed only because the
  sabotage was appended *after* the verify block; a real wholesale replacement
  lives in its own file and is caught by the places assertion and by
  `check-catalog-keys.py`.)

---

## Three new guards

The last one of these went undetected for a day, so the shape is now asserted in
three independent places:

- **`scripts/check-catalog-keys.py`** — asks the LIVE RPC. Fails on a link pin
  inside `tours` **and** on `linkPins` vanishing from the payload. 8/8 self-tests.
- **`.github/workflows/publish-catalog.yml`** — refuses to publish a mirror
  carrying a pin inside `tours`.
- **`scripts/validate-tours.swift`** — errors on a pin in `tours` and on a
  non-link tour filed under `linkPins`; validates pins exactly as strictly as
  before, via a new `locatedTours` so an error still names the array to edit.

⚠️ **`scripts/make-link-pin.py` now emits `linkPins`, not `tours`** — otherwise
the next pin lands straight back in the array that breaks old builds. Self-test
43/43.

---

## Accepted costs and things to know

- **⚠️ Builds 116 and 117 stop showing the pins** until a build reads the new
  key. One build's lag, once. Already understood by the owner.
- **⚠️ A place may legitimately name a link pin.** AMNH has 6 `tourIds`, 4 of
  them pins — so an old build resolves 2, which is ≥2, and still collapses to a
  place pin exactly as it did before pins existed. The validator and the seed
  both resolve members against `allTours` for this reason.
- **⚠️ No Swift toolchain in this session and no Mac**, so nothing here was
  compiled. Per Automation Rule #3, CI on the PR is the `test_sim` stand-in —
  **and CI has not run**, because the API was unavailable. The Swift work
  (`ToursData`, the validator, the new test) is unverified by a compiler.
- The proof was additionally reproduced in Python against both shapes before and
  after, which is where the 0-tours / 1,512-tours numbers above come from.

## Integrating this from another session

⚠️ **This session was not attached to the project.** It pulled the repo in
mid-session, so it never appeared in the PR queue and never coordinated
filenames or numbering with whatever else was in flight. Both branches are on
the real remote (`github.com/ehky2882/travel-guided-tour`) and integrate as
ordinary git, but three things need a human's attention:

### 1. `Tours.json` will conflict, and it must NOT be hand-merged

The split moved 178/176 lines inside an 8 MB file, and this project merges city
batches constantly — so any content branch cut before the split reintroduces
pins inside `tours`. Do not resolve that by hand. **`scripts/split-link-pins.py`
exists so the resolution is mechanical:**

```bash
git checkout --theirs "TRAVEL GUIDED TOUR/Resources/Tours.json"   # take main's
python3 scripts/split-link-pins.py                               # re-apply the split
swift scripts/validate-tours.swift                               # prove it
```

Idempotent, `--check` reports without writing, `--selftest` is offline (6/6). It
**refuses to write** if the file is not already byte-stable under
`indent=2, ensure_ascii=False` + trailing newline, so it can never reformat the
catalog as a side effect. Verified: run against `main`'s pre-split catalog it
reproduces the committed file **exactly**.

### 2. The PR numbers are `TBD` and must be patched before merge

No PR could be opened from that session (`403: GitHub access is not enabled for
this session`), so the docs carry `PR TBD` with branch-compare links rather than
invented numbers. **Three places per PR** need the real number once opened:

- `CLAUDE.md` — the Current State block heading
- `ROADMAP.md` — the status paragraph
- `archive/README.md` — the handoff entry

⚠️ CLAUDE.md's own rule applies here: *the squash commit inherits the PR body,
so a stale description becomes the permanent record.* Patch the numbers
immediately before merging, not when the PR opens.

### 3. Two doc-ownership collisions to check first

- **`CLAUDE.md` Current State** — `claude/project-tracking-dashboard-1kggmu` is
  in flight and is most likely the STATUS.md coordinator (PR #596). If that PR
  moves Current State out of `CLAUDE.md`, this block belongs in `STATUS.md`
  instead. **STATUS.md was deliberately not touched by that session.**
- **`archive/HANDOFF-260825.md` / `-2.md`** — no collision on `main` at the time
  of writing, but a parallel session can claim the suffix first. Check
  `archive/` for the next free suffix and expect to renumber, per the
  session-99 add/add precedent.

## Owner actions

1. Open the PR from `claude/catalog-forward-compat` and let `ci.yml` run.
2. After merge, paste **`backend/split_link_pins.sql`** into the Supabase SQL
   Editor (project "Dozent"). Expect *"Success. No rows returned."*
3. Then run `python3 scripts/check-catalog-keys.py` — do not trust the success
   message. Expect `tours` 1512, `linkPins` 4, `places` 25, `makers` 37.

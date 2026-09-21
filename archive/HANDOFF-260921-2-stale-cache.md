# HANDOFF 2026-09-21 (2) — the coordinate audit was reporting its own fixes as broken

**PR:** [#1037](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1037) · follows
[#1035](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1035) (merged) and
[#1034](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1034).

## How it was found

#1035 merged, `main` synced, and the first thing done afterwards was re-run
`scripts/spine-match.py` to see where the catalogue stood. It reported **93 DISAGREES**,
Belgrade Tower among them at **2,329 m** — a coordinate that had been moved onto
Wikidata's own point hours earlier, in the very PR that had just merged.

The tell was arithmetic, not intuition. Our stored point was `44.80562, 20.44679`;
Wikidata's is `44.805621765, 20.446790704`. Those agree to five decimals and the tool
said 2,329 m. **When a check's output contradicts a number you can compute by hand, the
check is what to doubt.**

## What was wrong

`scripts/spine-lookup.py` keys every cached answer by `ask_digest(title, coordinate,
bound)` and re-asks when any of them moves. `spine/README.md` documented this. It was
true **of the fetcher**. `scripts/spine-match.py` — what CI runs, what a human reads —
never looked at the digest and printed the cached `distance_m` regardless.

**59 of 4,930 rows were keyed to a title or coordinate the catalogue no longer held.**
Nine of them were the nine coordinates corrected across #1034 and #1035; the other fifty
were mostly food pins retitled during the title-recovery work.

| | reported | after refresh |
|---|---|---|
| Belgrade Tower · Yachthouse · Robie House · Etihad Museum · Govind Dev Ji Temple · Bahrain WTC · Intempo · InterContinental Shanghai · MahaNakhon | 888 – 11,921 m out | **0 m — all nine CONFIRMS** |
| DISAGREES | 93 | **85** |
| CONFIRMS | 1,764 | **1,778** |

Refreshing all 59 took **9 SPARQL queries** and under a minute, because the fetcher's
digest gate does work — it re-asks only what moved.

## 🔴 The finding that matters is not the one that was visible

Being told a fix is unfixed wastes a session and is obvious. The same blindness runs the
other way and is silent: **a coordinate moved to the WRONG place keeps reporting its OLD
distance.** The one check built to police such a move could not see it, and CI would stay
green. The visible symptom was the benign half of a silent defect.

This is a coordinate — the defect `CLAUDE.md` calls invisible to every other check: the
validator passes, CI compiles, every URL 200s, and the tour simply never fires.

## The fix

**A stale number is a confident wrong answer, not a weak one.** So the row gets *no
distance at all* rather than a flagged one:

- banded **`STALE`** and listed by name **above** the findings, so a reader knows what the
  run could not speak for before reading what it could;
- **left out of the coverage denominator** — coverage is the claim "Wikidata knows this
  subject", which a row cached against an entry we no longer hold does not support, and
  counting it would inflate the figure that decides where the address-parsing path is
  needed instead;
- exit **2 — COULD NOT VERIFY**, the treatment `NOT-ASKED` already had, and it **outranks
  findings**: a run printing "no entry disagrees" while holding rows it never evaluated is
  the exact shape § "Reading a check's result" warns about;
- the bound is read from the **record**, not from the run — the bound is the fetcher's
  business, and the two things a reporter can see change are title and marker.

## ⚠️ A guard that reds a check must ship with the thing that clears it

Exiting 2 on a stale cache would have turned the coordinate audit permanently red on the
next content merge — which is `spine/README.md`'s own warning that *a red check nobody can
fix reads as coverage and gets ignored*.

So `publish-catalog.yml` gains **`refresh-spine`**, modelled on `rebuild-related`:
`needs: rebuild-related` so it reads the catalogue actually published, digest-gated,
`--limit 400` to bound a cold cache on a runner, `[skip ci]`, and the same self-healing
warning if `main` moves underneath. It is deliberately **`continue-on-error`** — WDQS is a
third party, nothing a phone reads comes from here, and a failed refresh degrades into
precisely what the guard says: STALE, with the command named in the output. **The guard is
what makes the automation safe to let fail.**

## A third instance, found by looking for the shape

Two instances of one defect are a pattern, so the next question was which *other* committed cache
has a reader that does not version it. `grep` over `scripts/` for each file in `checks/` and
`spine/` answered it in minutes.

**The vision sweep.** `check-pin-subject.py` digests an entry's title **and hero image** and
re-asks on a mismatch — the fetcher again — while nothing reading the cache back checks it.

- **51 of 4,930** entries were retitled or re-imaged after their verdict (47 UNUSABLE, 3 CONFIRMS,
  1 CONTRADICTS);
- **69** had never been asked at all, and read as covered because nothing said otherwise.

🔴 The single stale `CONTRADICTS` is **Old Spitalfields Market — whose hero was replaced precisely
because that check flagged it.** The finding outlived its own fix and read exactly like a live one.

Re-asking needs a Gemini key (the owner pastes one fresh; it does not survive the container), so
the fix here is to make the gap **visible without one**: `check-pin-subject.py --status` reports
what the cache can and cannot speak for, offline, and deliberately answers *before* the key check —
coverage is answerable without a key, and refusing for want of one would be the same false silence.
`cache_coverage()` was extracted so the guard is reachable from the selftest at all.

## Verification

| | |
|---|---|
| `spine-match.py --selftest` | **68/68** (was 52) |
| `scripts/mutate-spine-match.py` (new) | **19/19 caught**, control-first |
| `spine-lookup.py --selftest` | 43/43 |
| `check-pin-subject.py --selftest` | **52/52** |
| `scripts/mutate-check-pin-subject.py` (new) | **10/10 caught** |
| `validate-tours-mirror.py` | **0 errors**, 523 warnings — unchanged; no catalogue change in this PR |

🔴 **Four guards were initially unreachable from the selftest**, each reading as an
ordinary green check — the ninth, tenth, eleventh and twelfth time this session that
mutation testing found a guard that could not fail:

- the **exit-code contract** itself was only ever exercised through `main()`, which the
  selftest never calls → extracted as `exit_code(counts)`;
- the **coverage denominator** likewise → extracted as `covered_rows(rows)`;
- `classify()`'s wiring of `band()`'s **`related`** and **`extended`** arguments. The
  thresholds were tested directly and passed while the call site could still have
  hard-coded either flag.

One mutant also exposed a bad anchor in the harness itself (`SKIP (anchor 0x)`), which is
why the harness counts a skip as a miss rather than passing over it.

## The 41 that remain — one finding, and a hypothesis that did NOT hold

With the verdicts read, 41 disagreements are genuinely unexamined. Reading their Wikidata *types*
suggested a systematic answer — islands, canals, districts, parks, a tram line, a dam, a pier all
sitting in the findings list — which would have echoed the original `EXTENDED_TYPES` work that took
145 findings to 86.

🔴 **It did not hold.** The types are scattered, one entry each, and many are plainly point-like:
`hotel`, `apartment building`, `Japanese restaurant`, `belvedere`. There is no missing class to add.

Two things did fall out, both worth the owner's eye rather than a unilateral fix:

- 🔴 **Roosevelt Island (New York) is being compared against an underground station** (`Q22808403`),
  not the island. **Lakhta Center** likewise matches *"Lakhta Center 3"*, a different tower in the
  same complex. These are name collisions — the failure `triage-spine.py` exists for — not
  coordinate errors, and moving either pin would break a correct one.
- Eight do carry genuinely extended types (`esplanade`, `promenade`, `avenue`, `canal inclined
  plane`, `cultural district`, `Tram transport`, `ghost town`, `Tokyo metropolitan park`).

**Deliberately not acted on.** Adding types to `EXTENDED_TYPES` reclassifies a finding as *not a
finding*, and `spine-match.py`'s own footer says every line goes to the owner individually. Doing
it during a Wikidata outage that resolved only **21 of 55** type labels would mean deciding on a
third of the evidence. It is a good next task with the outage over.

## What is still open

- **41 DISAGREES / 166 REVIEW genuinely unexamined**, down from 85 / 198 — the same PR
  taught `spine-match.py` to read `checks/spine-verdicts.json`, where 44 + 32 of those
  were already settled. **The verdicts carry the same discipline as the cache**: each is
  stamped with the coordinate it was reached against and stops applying when that
  coordinate moves, and an unstamped record is not trusted. The stamp was *proved* rather
  than assumed — diffing the catalogue at the verdict file's first commit against `HEAD`
  showed exactly eleven entries had moved: the nine whose fix *was* the verdict, plus two
  that did not exist yet. ⚠️ One `fixed` note's hand-typed coordinate was **~60 m from
  what was actually applied** (still inside the 120 m confirm band); the applied value
  came from Wikidata. Prose is not a machine-readable fact.
- **Sun Tower (Yantai)** remains `undecided` at 23.5 km — no description, no municipality,
  nothing in OSM under 阳光塔/陽光塔 in a Yantai bbox, and English Wikipedia's "Sun Tower" is
  Vancouver's. An opinion is not a source.
- **237 caption titles with no 📍 marker and 73 bare handles** are unresolved;
  `scripts/recover-pin-title.py` has no `--apply` deliberately.
- **Root cause of the coordinate errors is still unfixed**: `make-link-pin.py` takes
  `--lat --lon --city --title` as *inputs*; nothing derives or checks them at authoring
  time. Every tool built this week audits after the fact.
- For the owner: the two deliberate shared set-images (3 obelisks, 4 Italian markets);
  whether CC BY-SA with a burned-in credit becomes policy or stays a one-off; whether
  ", NYC" / ", Brooklyn" suffixes should be trimmed from recovered titles.

🔴 **And from the previous stretch, still owed to the owner:** three titles shipped with
`@handles` still attached (`Pinacoteca di Brera Milan Italy @pinacotecabrera`,
`Hepworth Wakefield @hepworthwakefield`, `Villa Medici in Rome @villa_medici`) and were
described in chat more cleanly than they actually were. Corrected since.

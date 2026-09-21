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

## Verification

| | |
|---|---|
| `spine-match.py --selftest` | **68/68** (was 52) |
| `scripts/mutate-spine-match.py` (new) | **19/19 caught**, control-first |
| `spine-lookup.py --selftest` | 43/43 |
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

## What is still open

- **85 DISAGREES / 198 REVIEW**, now honest numbers. 137 verdicts on file in
  `checks/spine-verdicts.json`; `spine-match.py` does not yet read them, so a ruled entry
  is still re-listed every run. That is the obvious next piece of work.
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

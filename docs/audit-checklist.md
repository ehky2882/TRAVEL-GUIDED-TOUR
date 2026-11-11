# The audit checklist — every way a catalogue entry can be wrong

```bash
python3 scripts/audit-board.py              # the live counts
python3 scripts/audit-board.py --detail join|name|city|hero
```

🔴 **The counts are not in this file, deliberately.** `CLAUDE.md` § READ FIRST:
never report perishable state from a document. This file explains what each
class *is* and why it exists; the script says how many there are today.

## Why it exists

Every gap in this catalogue has been found the same way: **the owner noticed
something on a map.**

| what they saw | what it turned out to be |
|---|---|
| A tour called "Vittoriano" in Rome | **Torre Velasca**, a building in Milan, 476 km away |
| Kossar's and Una Pizza on the map | Two sites with two entries each and no place page |
| The Washington Monument | A place with two members and a **third entry 7 m outside it** |
| The Thyssen's hero | Byte-identical to the Reina Sofía's, written 40 seconds earlier |
| A London museum playing LA's audio | Two tours sharing the bare slug `natural-history-museum` |

Each time the answer was a new one-off check, and each time **the next gap
stayed invisible until a person tripped over it.** A list of checks cannot fix
that, because it can only describe what is already covered.

So the board enumerates **defect classes, not defects**, and a class with no
check keeps its row. An uncovered class is the shape of the next incident.

## Reading a row

Three things, and the third is the one that gets misread:

1. **What the class is** — the kind of wrongness, not an instance of it.
2. **What covers it, and where that runs.** "by hand" means nobody is running
   it unless someone decides to; treat those rows as unknown, not clean.
3. **🔴 What the number MEANS.** A count is *not* a defect count. Several
   classes are dominated by legitimate entries:
   - One creator post pinned to five antique markets shares one hero on
     purpose — that is the designed shape of a link pin, and it is excluded.
   - A walk and a single-stop tour on the same landmark share a hero
     editorially.
   - `Miami`/`Miami Beach` and `Osaka`/`Osakasayama` are genuinely different
     cities, and the city check reports them anyway.

## The classes

### Covered, and running on every PR

| class | check | what a count means |
|---|---|---|
| Malformed entry, broken reference, a place member not on its place | `validate-tours.swift` | every one is a defect |
| Coordinate disagrees with a gazetteer | `spine-match.py` | **not a worklist** — five sampled by hand, none a catalogue error; two were Wikidata's own |
| A site with two entries and no place page | `check-place-candidates.py` | candidates; the owner decides each |
| Same name, different place | `check-same-name.py` | **not a worklist** — of the first six, a stream and a two-branch chain span legitimately and two were a repeated caption, not a name |
| An entry sitting on a place it is not a member of | `audit-board.py` | some are correctly out — the Channel Gardens and the Blue Ribbon Garden are declined |
| One city spelled two ways | `audit-board.py` | each splits one city in two; a few are real neighbours |
| One hero on two subjects with two source posts | `audit-board.py` | every one is a defect |

### Covered, but only when somebody runs it

| class | check | why it is not automatic |
|---|---|---|
| Coordinate implausible for its city | `check-coordinates.py` | designed for a new city drop, not the whole catalogue |
| Image written under the wrong tour's filename | `check-image-duplicates.py` | fetches every image; ~7 minutes |
| `get_catalog` silently dropped a key | `check-catalog-contract.py` | needs the live RPC |
| **The title does not match the picture** | `check-pin-subject.py` | needs a Gemini key, which is pasted per session and never stored |

⚠️ **`check-pin-subject.py` can never run in CI**, so its class is permanently
"unknown" between runs. That is a structural limit, not an oversight.

### Reachable by nothing else

**Titles nothing stored can corroborate** — no venue `@handle`, and a caption
sharing no word with the title. This is the class Torre Velasca was in: the
caption read *"Italy's Ugliest Building Became a National Monument😱"*, which
names no building, so no check reading the record could ever disagree with the
title. Only the pixels can answer, and only with a key.

## 🔴 The three gaps this board was built by finding

1. **Nothing asked whether an entry should JOIN an existing place.** Every tier
   of `check-place-candidates.py` hunts for sites with *no* place page; the
   moment a place exists, that site is treated as finished. `scan_names` drops
   every already-placed entry outright.
2. **The accent check that was asked for did not exist.** `CLAUDE.md` asks for
   an accent-folded duplicate check after `Sao Paulo`/`São Paulo` and
   `Zurich`/`Zürich` were merged. Nothing implemented it — and the first
   version written here *skipped* exactly those pairs through a `fa == fb`
   guard, silently, while its docstring claimed to catch them. **Mutation
   testing found that; the selftests were green.**
3. **`City (District)` splits a city and nothing noticed.** Not a typo — a
   convention, applied to Tokyo, New York, Osaka, Bangkok and Los Angeles, each
   variant counting as a separate city.

## Verification, non-negotiable

- **Mutation-test every guard.** On this script alone, mutation testing found
  one real bug and **four guards that could not fail**, each masked by another:
  `York`/`New York` does not isolate the proximity rule, because York is a
  *suffix* and the prefix rule already excluded it. Every fixture must isolate
  exactly one rule.
- **A check that cannot run reports `ERR`, never `0`.** The board's first live
  run printed `ERR:TypeError` from a signature mismatch; a `0` would have read
  as clean. The CI job fails on any `ERR` row.
- **A fixture that stops being able to fail is a dead test.** The one asserting
  `ERR` stopped raising the moment that signature was fixed, and then asserted
  nothing while still reading green.

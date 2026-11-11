# HANDOFF 2026-09-20 (2) — ten places, and a work queue for 301 findings

Follows `archive/HANDOFF-260920-vision-sweep.md`, which covers the sweep itself.

## What shipped

**Places 398 → 408** on `claude/scale-pinned-tours-automation-dba3lx`
([#1023](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1023)).

🔴 **This started as nine auto-minted places and ended as ten owner-approved ones.** While
the branch was open, another session shipped **#1024 and minted EIGHT of the same nine from
the same candidates**, naming them locally where this branch used the gazetteer's English
(`Cirkelbroen` / Circle Bridge, `Jardin Majorelle` / Majorelle Garden). Theirs merged first,
so theirs won and the duplicate work was **dropped, not resolved**. `make-places.py` now
proposes **0** — every proven and gazetteer candidate is already placed.

**What the duplicated run WOULD have created** (kept for the record, all now on `main` under
other names) by `make-places.py --apply` — the band it is allowed to act on
alone, because each has two coincident members **plus an independent second signal**:
Isle of Capri, Essanay Studios, Pinacoteca di Brera, Fairmont Banff Springs, Stedelijk
Museum (all 0 m); Circle Bridge, Majorelle Garden, Coal Drops Yard, Wilton's Music Hall
(gazetteer, ≤98 m). It **refused** Salón 1923 and Fondazione Prada, which the owner had
already declined — that refusal list is what stops a re-run re-proposing them.

**Ten owner-approved** (of eleven put to the owner) from the EXACT·ASK band — coincident but with no second signal,
so the script correctly would not mint them: MoMA, The Royal Academy, Louvre, Pont
Alexandre III & Petit Palais, Rietveld Schröder House, Isabella Stewart Gardner Museum,
Miami Slice, Taste of Heaven, Hungarian Parliament Building, Budafok Cellars, David N.
Dinkins Municipal Building.

Minted through `make-places.apply()` rather than by hand, so the marker stop (`order == 0`,
not `stops[0]`) and the centroid move together and `places` is appended, never sorted.
Every group was already coincident, so **nothing moved**: `git diff origin/main` shows ten
place objects appended and nothing else.

⚠️ **The first warning comparison in this branch was WRONG.** `git stash` restored the
branch's own pre-merge state rather than `main`, so it compared this work against itself and
reported a reassuring "511 before and after". The honest check is to run the validator **back
to back on main's catalogue and on this tree**: **0 errors and 514 warnings both times.**

### Two names came from the posts, not the pin titles
- **"Chef Tony's" is the chef.** Both Brooklyn pins point at **Taste of Heaven**
  (`@tasteofheavenbk`).
- **"Miami Slice" is itself the restaurant** (`@miamislicepizza`).
- The NYC pair is named for the **building**, not its tenant Centre 360 — `docs/places.md`
  says name the whole.
- ⚠️ **"Budafok Cellars" was INVENTED.** Neither member names the whole (one is the Cave
  Dwelling Exhibit, the other St Stephen's Barrel wine cellar), so there was nothing to
  inherit. Rename freely if it is wrong.

### Two the owner overrode, deliberately
The Hungarian Parliament library/tunnels pair, the Budafok pair and the Municipal Building
pair were all put to the owner **as likely part-vs-whole or co-location traps**, and the
owner approved all three. That is now precedent on a question `docs/places.md` records as
undecided.

## 🔴 Merging two sessions' place runs — do not hand-resolve it

Merging `main` produced **17 conflict hunks in `Tours.json`, every one a pair of coordinates**
for an entry that both runs had moved onto its own place point. Hand-resolving that inside a
100k-line JSON is exactly the edit nobody can review. **Take `main`'s catalogue whole and
re-run the place creation against it** — re-derive, never merge. The residual merge then
resolves to `ours` correctly, and the proof is that `git diff origin/main` shows only the
appended places.

The apply step **refused to write anything** when a group it expected to hold 2 members held
0, rather than minting a partial set. It now also refuses an entry that already belongs to a
place — the guard that stops two sessions double-placing one pin.

## 🔴 The stale-branch near-miss — read this before trusting any proposal

The first `make-places.py` run proposed **6** places. The real answer was **9**. The branch
named in this session's instructions **already existed, pointing behind `main`**, and
`git checkout -b … || git checkout …` silently landed on the old one — so four of the nine
pins were *not in the checkout at all*. The run was clean, stamped, and computing against
the wrong catalogue.

**Merge `origin/main` into the working branch BEFORE running any proposal, and compare the
rev on the runstamp between two runs that should agree.** Two runs minutes apart printing
different revs is the tell; that is exactly what happened here
(`009562b7` vs `318ea128`) and it was nearly missed.

## The work queue for the 301 findings — `scripts/rank-pin-findings.py` (NEW)

The sweep's 323 CONTRADICTS are **42% precise**, so the raw list is not a queue. The new
script bands them by the one thing that correlates with a real error — **geographic
distance between what the catalogue claims and what gate C named**:

| band | count | what it means |
|---|---|---|
| **cross-country** | **23** | picture is a place in a different country. **7 of the owner's 14 real errors looked like this** |
| cross-city | 37 | different city, same country |
| same-area | 241 | the low-signal tail |

Plus **22 already ruled on**, dropped automatically (matched on folded title, because
`owner-verdicts.json` is keyed by title).

`--band cross-country` prints one band in full; `--json` writes them all. 12/12 selftests.
🔴 **Mutation testing is OWED** — every other checker in `scripts/` has a
`mutate-*.py` harness and this one does not yet.

**Two limitations are documented in the code and must not be forgotten:**
1. **The catalogue is its own gazetteer**, so a city we do not carry cannot be located and
   bands as `same-area` however far away it is. The bands **understate** cross-country, and
   `same-area` means "nothing here could place it", never "it is nearby".
2. A country named mid-phrase ("somewhere in France") is missed, because the split is on
   commas and brackets. Asserted as a known false negative rather than hidden.

⚠️ **A band is a reading order, not a verdict.** A replica reads as its original — the three
Leaning Tower of Niles pins land in `cross-country` on every run and the owner has ruled
them correct. The ruling reached only one of the three, because matching is per-title.

## Also found, not yet acted on

- **Two images each serving several different pins**, which is certain rather than probable:
  `three-freemason-obelisks-urbanistariel_hero.webp` (Worth Monument, Obelisk of Thomas
  Addis Emmet, The Obelisk) and `italian-antique-markets-malata_hero.webp` (four antique
  markets in Lucca, Arezzo, Milan, Parma). The filenames suggest these were **deliberate
  set images**, so it is an owner decision, not a bug. **Put to the owner; not answered.**
- **Ten other shared-hero groups were checked and dismissed** — they are multi-stop walks
  using one of their own stops as the hero, which the audit board already allows.
- **The Municipal Building has four more entries 0.5 m away** ("The Manhattan Municipal
  Building", "Inside the Municipal Building"). They were **not** in the approved group, and
  joining them would *move* them — a different operation from minting. Put to the owner;
  not answered.
- **89 pairs within 25 m and 58 same-subject pairs 25–500 m** remain unread. The Barbican
  has six entries across 149 m and Rockefeller Center five — those two are single decisions,
  not pair-by-pair ones.

## State

- `claude/scale-pinned-tours-automation-dba3lx` → #1023, five commits, CI not yet read.
- **Isle of Capri is NOT a place**: another session found the two entries are an Instagram
  duplicate and opened `status/owner/remove-isle-of-capri-instagram-dup.md` plus
  `backend/remove_nickcabotrodriguez_instagram_duplicate.sql`. It was in this branch's first
  nine and is correctly absent now.
- #1021 (the sweep) merged as `d6438455`; its branch is deleted.
- The Gemini key lived in the session scratchpad and **dies with the container**.

## 🔴 CORRECTION: the cross-country band is NOT the dense one

Eight of the 23 cross-country findings were checked by opening the hero image and
looking at it. The result contradicts the hypothesis this branch was built on:

| finding | verdict |
|---|---|
| Green-Wood Cemetery → "St. Stephen's, Vienna" | check wrong — it is the Upjohn gate, monk-parakeet nest visible |
| DZ Bank → "Experience Music Project, Seattle" | check wrong — Gehry's Berlin atrium; SIBLING BY THE SAME ARCHITECT |
| The Valley → "The Interlace, Singapore" | check wrong — MVRDV Amsterdam |
| The Sistine Chapel → "Pantheon, Rome" | check wrong — the chapel's plain exterior, which is the post's point |
| Ba Son Bridge → "Lupu Bridge, Shanghai" | check wrong — Lupu is an arch, this is cable-stayed |
| Reiyūkai Shakaden → "National Taichung Theater" | check wrong — 霊友会 is legible ON the building |
| **Old Spitalfields Market → "La Grande Halle de la Villette"** | **🔴 REAL — the hero is a vast iron hall with cobbles, interior pavilions and a vendor sign reading YVONNE. Not Spitalfields** |
| Kaktus Towers → "Esplanade, Singapore" | **undecided** — spiky surfaces curve like a dome; could be either |

**One real error in eight, possibly two.** That is **12–25%, against the 42% baseline for
findings overall** — so cross-country is, if anything, WORSE than an unranked list.

**Why the hypothesis failed.** When gate C cannot identify a building it names a *famous*
one of the same type, and famous buildings are spread across the world — so "a different
country" is the DEFAULT SHAPE OF THE NOISE, not a signal. The owner's real errors were
cross-country (MSG Sphere → Lucas Museum), but so is almost all the noise, and the band
cannot separate them. Two of the eight are the sharper pattern: **the same architect's other
building** (Gehry, and arguably MVRDV/OMA).

🔴 **Do not spend the owner's attention on the remaining 15 cross-country rows on the
strength of the band alone.** The banding still has value as a *reading order*, but the
claim that it concentrates real errors is **withdrawn**.

**What actually worked** was looking at the picture directly — eight settled in minutes,
six of them decisively, without asking the owner anything. That is the method to scale:
the checker should present the image, not the label.

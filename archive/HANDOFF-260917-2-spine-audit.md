# Handoff — 2026-09-17 (2) · the spine audit, and what it actually found

**Session:** web/remote, branch `claude/scale-pinned-tours-automation-dba3lx`
**Merged:** [#979](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/979) (the earlier session
record) · [#988](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/988) (this)

Follows `archive/HANDOFF-260917-places-and-deletion.md`, which covers the place work that prompted
this.

---

## The question

Clearing the place-candidate backlog surfaced six coordinate errors that **every check in this repo
passes**, because each was precise, plausible and in the right city — Grace Farms 6,104 m, Geisel
Library 5,412 m, La Collina 1,440 m, Casa de Vidro 833 m, Asakusa 718 m, Domino Park 201 m. In 13 of
15 place groups the displaced entry was the Atlas *tour*.

`check-coordinates.py` asks whether a point is **plausible**. `validate-tours.swift` asks whether it
is **well-formed**. Neither asks whether it is **right**, and that is the only question that catches
this class.

## What shipped

| | |
|---|---|
| `scripts/spine-lookup.py` | network, cached, resumable — asks Wikidata where each subject is |
| `scripts/spine-features.py` | asks what *kind* of thing each match is (~300 QIDs a query) |
| `scripts/spine-match.py` | offline, CI-wired — bands every entry |
| `spine/lookups.json.gz` | 4,566 entries, complete, zero failures, 448 KB |
| `spine/features.json.gz` | 2,828 matched items classified, 30 KB |

🔴 **A NAME lookup, not the tiled harvest `docs/place-spine-design.md` § 4 specified.** Tiling the
whole catalogue is affordable — **1,612 tiles of 2 km, ~67 minutes, measured**, covering everything
rather than the five cities originally scoped. It was still the wrong first build, structurally:

> A tile is drawn around the coordinate the entry **already has**. If that coordinate is wrong, the
> right feature is outside the tile.

Grace Farms' pin sat 6.1 km from Grace Farms. § 3a of that document now records this.

## 🔴 The result, which is not the one expected

```
audited 4566 entries · CONFIRMS 1667 · EXTENDED 114 · UNMATCHED 2507
DISAGREES 86 · REVIEW 192
```

**Five of the top DISAGREES were sampled by hand. None was a catalogue error.**

| Entry | Verdict |
|---|---|
| Prada Aoyama | **Wikidata is wrong** — ours is correctly in Minami-Aoyama |
| Pérez Art Museum Miami | **Wikidata is wrong** — ours is correctly at Museum Park |
| Hōrin-ji Temple | A *different* Hōrin-ji, 16 km away in Katsushika |
| Palácio da Justiça | A different one — every Portuguese district has one |
| Casa Costa | Unresolved |

**Why, and it is not a defect in the tool:** the six errors that motivated this were already fixed,
and the catalogue has been through coordinate audits. The true-error rate is now low enough that the
false-positive classes dominate the top of the list. The regression tests prove the tool *does* catch
the known errors — Geisel at 5,451 m, Casa de Vidro at 844 m — there are simply few left.

⚠️ **Do not hand the 86 to the owner as a worklist.** The PR says so and so does the tool.

**What IS new and valuable:** 1,667 entries independently confirmed against an outside source — a
fact about the catalogue nobody had before — and coverage measured per creator, which settles the
routing question for good:

| Atlas Studio LDN | `@pasttworld` | Atlas Studio NYC | `@jacksdiningroom` | `@japanbyfood` |
|---|---|---|---|---|
| **86%** | 85% | 75% | **7%** | **1%** |

Wikidata knows buildings, not restaurants. Food content will never be served by this method; it needs
`parse-caption-address.py` + GSI, exactly as `docs/place-spine-design.md` § 2a (c) predicted.

## Guards, every one paid for by a real failure during the build

1. **La Collina** matched an item in Italy **9,570 km** away, looking like a confident hit; a live
   sweep then matched *"Church of Santa Maria"* to a different church **88 km** away. Findings cap
   at 30 km — five times the worst real error on record.
2. **`Brooklyn Museum` returned its own art school**, 75 m away, alongside the museum. Distance-only
   ranking answers a question about the museum with a fact about the school — and where our point is
   wrong, the sibling makes it look right. Label agreement outranks proximity.
3. **Han does not name its own language.** `浅草地下街` is Japanese and `文武廟` is Chinese, and no
   codepoint says so. The entry's **country** decides.
4. **`Municipal Library of Viana do Castelo` matched the TOWN.** Containment reintroduced the bug
   `check-place-candidates.same_name` uses equality to avoid. Fixed by dropping the city **and** a
   head-word rule — an English title names its subject first and its locator last, so
   `Geisel Library` carries `geisel` while `Akihabara` does not carry `gyukatsu`.
5. **145 → 86** by separating extended sites. `EXTENDED_TYPES` was read off the data, not guessed,
   and every QID's label confirmed before use.

## Two things that changed mid-build, and why

🔴 **The background sweep died.** Started with `nohup`, it reached 316 of 4,566 and stopped **five
minutes after the turn ended**; a scheduled check-in found no process 52 minutes later. **A
background process does not outlive an idle session here** — the container suspends. Two fixes:
batching (below) so a sweep fits in one active turn, and slicing so an interrupted run keeps its
progress. Proven: a later run killed mid-slice-4 kept 600 entries against 0 before.

🔴 **The obvious optimisation was the wrong one.** Wikidata's `wbsearchentities` action API answers a
single search faster (~0.3 s against ~2 s) and **429s hard in bulk** — 5 of 15 at a 0.5 s sleep, 9 of
15 at 0.25 s — while WDQS ran 316 consecutive entries with zero failures. **The win was batching the
permissive endpoint**: 8 searches UNION'd per query, 3 s/entry → **0.31 s/entry**, verified to return
results **identical** to the per-name path (8/8 on real data, 6.2× faster).

## Verification

43/43 · 52/52 · 6/6 selftests, **mutation-tested** — 8/8 and 14/14 deliberate breakages caught.

🔴 **Three selftests passed while being unable to fail**, and only mutation testing found them: a
distance bound asserted as *arithmetic* rather than through the code applying it; a two-element
fixture where `reverse()` happened to equal `sort()`; and a city-drop guard entirely masked by a
later rule. All three read as ordinary green checks first.

## What is still open

| | |
|---|---|
| The 86 DISAGREES | Not a worklist. Triage further, or accept as the method's noise floor |
| Wikidata's own errors | Two found in five samples. No mechanism yet to feed corrections back |
| Large sites | `EXTENDED` catches most; the principled fix is `P2046` area, which needs a re-sweep |
| Food coverage | 1–7%. Needs `parse-caption-address.py` + GSI, not this |
| Auto-created places | `status/owner/auto-created-places.md` — still the owner's call, now with real coverage evidence behind it |
| Phase 3 client half | Reconciliation in `RemoteCatalogLoader`; app code, needs TestFlight |
| **1.1.3** | Carries the delta client, device-verified on build 161. Not submitted |

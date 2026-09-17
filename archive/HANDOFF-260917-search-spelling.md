# Handoff — 2026-09-17 · Spelling correction in search

**#973**, merged. Owner-confirmed on TestFlight build 168.

Both halves of search were unforgiving about spelling, in different ways, and
the owner noticed: *"i still feel the search is very unforgiving about
spelling"*. Measured on the live catalogue before writing anything:

    museum       → The British Museum      musuem        → NOTHING
    food market  → Ben Thanh Market        fud markit    → NOTHING
    art deco lobby → Radio City            art deko loby → the wrong tour

The keyword list is a literal substring test, so a typo matches no text
anywhere. The semantic half chops an unknown word into subword fragments that
no longer resemble the real one, so it drifts or falls under the floor.

---

## 🔴 Prototype against the real catalogue BEFORE writing Swift

This is the transferable part. The algorithm was written in Python and run
over the live `Tours.json` first, and **it was wrong**:

    deko → deno      (should be deco)
    loby → lobo      (should be lobby)
    towr → tour      (should be tower)

The cause: the search stopped at the first candidate one edit away. **Several
catalogue words sit one edit from any given typo**, so "first match" was decided
by set-iteration order. Three fixes, each measured:

1. **Frequency-ordered candidates + a strictly-better comparison**, so the
   commonest word wins a tie — `deco` 56 uses vs `deno` 1; `tower` 169 vs
   `tour` 7.
2. **A correction target must occur at least twice** (`minimumTargetCount`).
   `loby → lobo` was landing on a word used once in the entire catalogue, and
   there are thousands of those to land on.
3. **`shortDescription` in the vocabulary**, `longDescription` not. "lobby"
   appears in no title anywhere; without short descriptions there was nothing
   correct to reach. Long descriptions are prose nobody types and would add
   thousands more one-off targets.

Had this gone straight to Swift, all three would have shipped and been found on
a phone, or not at all.

## The design, and the asymmetry in it

**The dictionary is the catalogue, not English.** A general speller would
"correct" Naoshima, Kubuswoningen or Trellick into nonsense. A correction can
only ever move a query toward something we actually ship.

| half | when it corrects | why |
|---|---|---|
| keyword | **only when the typed query found nothing** | a working search is never overridden; the feature can add results and never remove one |
| semantic | **always** | a typo there does not return nothing, it returns something subtly wrong — there is no empty result to trigger on |

Safe either way because a word the catalogue knows is never touched, whatever
it looks like. That is what stops `soho` becoming `sofa`.

**Never silent** — a corrected search says *Showing results for "…"*. Quietly
answering a different question than the one asked is worse than answering
nothing.

**Damerau, not Levenshtein.** `musuem → museum` is two substitutions but ONE
transposition, and a word under six letters never gets a two-edit budget.

## ⚠️ The knobs are compiled in

`scoreFloor`, `minimumLength`, `minimumTargetCount` are Swift constants, so
**every adjustment costs a TestFlight build**. The owner was told at one point
that this class of change was content-side; it is not. If a number is expected
to move on judgement rather than on evidence, it belongs in the catalogue.

## Two self-inflicted CI failures, both worth the warning

- **A string-slice edit duplicated a whole section.** Removing a dead stub by
  cutting from marker A to marker B assumed B came after A. It came before, so
  the cut *copied* the section instead of deleting it and `SearchEntry` was
  declared twice. The second attempt asserted the two copies were identical
  before removing either — **and that assertion failed**, because they differ
  by the line carrying the type's closing brace. Cutting blindly would have
  taken the brace with it.
- **A test failed on the FIXTURE, not the code.** "Brutalist" appeared in a
  single title in the miniature test corpus, so it fell below
  `minimumTargetCount` and was not an eligible target at all. The live
  catalogue has it many times, which is why the Python run passed. There is now
  a test that guards the corpus itself — every word the other assertions expect
  a typo to land on must resolve back from a one-edit typo.

## What was measured about conversational search, and is NOT built

The owner asked whether they can converse with the search bar, and whether
"agentic" is the word. Measured against the live index:

    "where can I see brutalist buildings?"                    0.615  ✓
    "I'm in London tomorrow, what brutalist stuff …?"         0.526  ✓ London results
    "anything near the Eiffel Tower?"                         0.601  ✓
    "what's good on a rainy day?"                             matched a Chamonix
                                                              post containing the
                                                              literal words

Natural phrasing copes better than expected — **but it is resemblance, not
understanding**. The London query worked because "London" resembles London
tours, not because it knew they were travelling. There is no follow-up and no
state; asking "and what about Tuesday?" means nothing to it.

"Agentic" is not the word for what they described — that means taking actions
over several steps. **Conversational** is. Real conversational search needs a
language model on-device or on a server, with the size, cost and privacy
tradeoffs that implies. A separate decision, not a tweak.

## Open

- **Is 0.35 the right semantic floor?** The owner's judgement, on real use.
  "stained glass windows" is the case to watch: the catalogue holds almost no
  stained glass, so it reaches for glass-adjacent entries instead.
- **Under four letters is not corrected** — `fud` stays `fud`. At three letters
  almost everything is one edit from something else. Deliberate.
- **Non-Latin queries pass through untouched.** A character-level edit distance
  over ideographs is meaningless and a CJK title has no spaces to tokenise on.

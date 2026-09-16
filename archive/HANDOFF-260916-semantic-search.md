# Handoff — 2026-09-16 · Semantic search

**PR #949**, branch `claude/open-source-ai-integration-pxuxdh`.

Type "quiet garden away from crowds" and get tours that are *about* that rather
than tours whose text contains those letters. Additive: today's keyword results
stay exactly where they are; smart matches get a labelled section underneath.
Two sections rather than one blended list is the owner's decision of 2026-09-16,
with blending deferred to device evidence.

---

## What is live right now

**The Core ML model is published and independently verified.**

```
https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/releases/download/
  search-model-v1/AtlasQueryEmbedder.mlpackage.aar
41,925,589 bytes · sha256 a895338aa909326bc2c4cf52ad04ae6dceba236c8204ecf7366e2a62132b86c2
```

Checked by fetching the public URL from a separate session and hashing the
bytes, not by reading the workflow's green tick.

**The index is NOT published and cannot be from here.** It ships from the
`rebuild-related` job on the next content merge. ⚠️ **Until then the "More Like This"
section is empty on every build** — expected, not a regression.

## The three seams, and why each has an alarm

A phone that disagrees with the server does not crash. It ranks the catalogue
subtly wrongly, forever, with nothing to say so.

| Seam | Alarm | Where |
|---|---|---|
| Tokenizer | 61 cases pinned against the real HuggingFace tokenizer | `TokenizerParityTests` |
| Model | run on a real Mac before it may be published | `scripts/verify-coreml-parity.py` |
| Scoring + file format | a real sidecar from the real writer | `RankingParityTests` |

**The gate's verdict (export run 12, and identically on run 9):**

```
worst cosine 0.999891 over 69 vectors
relations:   0.530 vs 0.096 · 0.473 vs 0.189 · 0.525 vs 0.025
6 queries:   query/query cosine 0.99998–0.99999
             int8 keeps 10/10 of the fp32 order on five of six
             'food market' 9/10 — one swap, the two entries 0.00017 apart
```

---

## Four things that cost a cycle each, and what they taught

### 1. The model emitted pure NaN and the gate reported a PASS

`nan < floor` is False, so a cosine floor passes it. `near <= far` is False, so a
relation guard passes it too. **A model producing nothing but NaN scored a clean
run**, and the numbers that would have shown it had already scrolled out of the
retrievable log window.

Cause: `get_extended_attention_mask` builds an additive mask as
`(1 - mask) * torch.finfo(dtype).min`. That constant is ~-3.4e38, overflows fp16
to `-inf`, and `0 * -inf` is NaN.

⚠️ **The obvious fix does not work.** Replacing the mask *input* with
`torch.ones_like(input_ids)` looks like it folds to a constant. It does not:
`input_ids` is a graph input, so `ones_like` is dynamic and the whole mask
computation stays traced. Removing the input did not remove the arithmetic. The
override builds the additive mask as zeros directly.

**Every comparison in the checker is now written so NaN fails** — `not (x >= floor)`
rather than `x < floor` — and three separate guards refuse a non-finite vector at
source (`export-coreml.py` at trace time, `verify-coreml-parity.py` at
prediction, `QueryEmbedder` on device).

### 2. The gate then failed four of six queries on a model that was fine

It ranked Core ML + int8 against Python + full precision, reasoning that the
first pairing is what a phone runs. True — but it made the MODEL answerable for
the INDEX's rounding, so it could only ever pass by luck. The diagnostics said so
plainly: query/query cosine 0.99999, top scores agreeing to 0.0005, every
disagreement an adjacent swap at ranks 7-10.

Now: the ship gate holds the index constant and varies only the query, so a
failure **is** the conversion. What int8 costs is measured on the same queries
and **reported rather than asserted** — demanding zero would be demanding that
quantization be free. A position where the two disagree is excused only when the
same index scores both entries within 0.001.

### 3. A .mlpackage is a directory, and iOS cannot read a zip

It has to travel as one file, and there is no public zip API on iOS. Apple
frameworks only, so a third-party unzip is out and hand-rolling one over
`Compression` would put several hundred lines of format parsing between the app
and its search index. `aa` ships with macOS, `AppleArchive` ships with iOS.

⚠️ `aa`'s **`-subdir` resolves relative to `-d`** — passing the package to both
sends it looking for itself inside itself.

The export job now **unpacks its own archive and loads the result**, because "it
compressed without error" is a different claim from "what comes back out is still
a model".

### 4. gh-pages is the wrong home for a 42 MB binary

The Contents API 502'd on it (~56 MB base64 in one PUT). A retry was the obvious
move and the wrong one: **a git branch keeps what it is given**, so every export
would add 42 MB to gh-pages history forever, on a branch whose clone already
times out. Releases are CDN-served, outside the tree, and equally free of
Supabase egress — which was gh-pages' only advantage here.

🔴 **The tag is versioned and the app pins it.** The model is fetched once and
compiled once, then read off the phone's own disk forever, so swapping bytes
behind an unchanged URL reaches nobody who has already searched — the rule
CLAUDE.md § Image Pipeline step 9 was written for. A new model means a new tag
**and** a change to `SearchModelLoader.remoteURL`: correct, because a new model
needs a new index and the two must move together.

---

## Files

| Path | What |
|---|---|
| `Features/Search/WordPieceTokenizer.swift` | BERT WordPiece by hand. Walks `Unicode.Scalar`, **not** `Character` — a grapheme cluster is one Character and several code points, so emoji tokenize wrongly the other way |
| `Features/Search/QueryEmbedder.swift` | Core ML wrapper. Pooling and L2 are **inside the graph**, not reimplemented here |
| `Features/Search/TourEmbeddingStore.swift` | Reads `ATLSEMB2`, ports `tour_scores`. Validates the header and every length before trusting a number |
| `Features/Search/SemanticSearch.swift` | State, debounce, download, `AppleArchive` unpack |
| `Features/Search/SearchView.swift` | The "More Like This" section. Exclusion happens here, where the keyword list is in hand |
| `scripts/verify-coreml-parity.py` | The gate |
| `scripts/export-coreml.py` | The conversion, and the NaN fix |
| `scripts/dump-ranking-fixture.py` | 48 entries / 122 chunks, sampled every 81st |
| `.github/workflows/export-search-model.yml` | Convert → verify → package → round-trip → release |
| `.github/workflows/publish-catalog.yml` | `rebuild-related` now also writes and publishes the sidecar |

## Open

- 🔴 **Unverified: the `rebuild-related` commit-and-push path AND the new sidecar
  publish.** Both need a real content merge on a real runner; the manual trigger
  runs `main`'s copy, not the branch's. **Watch the next city launch or pin batch**
  for `chore(catalog): rebuild More like this suggestions [skip ci]` on `main` and
  `search/embeddings.bin` + `search/embeddings.digest` on gh-pages.
- **Blending** the two lists — deferred to device evidence by the owner.
- **int8 for the model** — halves the download, but only if it re-passes the gate.
  Measure, do not assume.
- **Multilingual** — the model is English-centric; Thai largely `[UNK]`.
- `nearbySubtitleText` fix from #926 still rides the next build cut.

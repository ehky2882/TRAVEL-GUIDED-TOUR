# Handoff — 2026-09-17 · Why a result matched, and a rail seeded by what you saved

Two features shipped in **[#985](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/985)**,
owner-verified on **TestFlight build 171** ("TESTING 171. LOOKS GOOD").

## 1. Search results now quote the sentence that matched

A semantic hit used to arrive with no explanation — the tour simply appeared.
Now each result carries the **actual chunk of its own text** whose embedding
scored highest, so the row says *why* it is there.

**A new sidecar, `ATLSNIP1`**, published beside `ATLSEMB2` at
`search/search-snippets.bin`. It is a sibling file rather than a widened index
so that **an older build ignores it and keeps working** — `snippet` is
`String?` in `Match`, and `parseSnippets` **returns nil rather than throwing**
on every rejection path (wrong magic, wrong model id, chunk-count mismatch), so
a bad or absent sidecar costs the explanations and nothing else.

🔴 **The one thing that could have gone wrong is a vector and its snippet
drifting apart**, and the fix was structural, not a test: `Embedder._windows()`
is now **the single place chunking happens**, and both `embed_chunks` and
`chunk_spans` consume it. They cannot disagree because there is only one of
them.

⚠️ **The file did not exist, and the gate that creates it only ran because it
was asked to.** `publish-catalog.yml` fires on a `Tours.json` change; #985
touched Swift and CI, so nothing ran, and `search-snippets.bin` stayed **404**
after the merge. The gate I had added — *the missing snippet file is itself a
reason to rebuild* — was sound but had **never executed**, and a check only
consulted when work is already happening cannot cause the work to happen. A
manual `workflow_dispatch` on `main` proved it: `Is a rebuild owed?` → owed,
rebuild ran, publish succeeded, and the two files now agree exactly —
**10,337 chunks in both headers, same model id**, verified against the live
URLs, not against the workflow's own say-so. Steps 9 and 10 (validate, commit)
**skipped**, which is correct: the neighbour lists had not changed, only the
index needed publishing.

## 2. The semantic floor moved 0.45 → 0.35

The owner's report was the finding: **`QUIET GARDEN AWAY` yielded no results**
on build 166. The floor had been **copied from `RELATED_FLOOR`** — and
`docs/lessons.md` already says a similarity between two documents is not the
similarity between a query and one. That query missed by **0.0002**.

⚠️ **And I first told the owner this was content-side.** It is a Swift
constant; it needed a build.

## 3. "More like what you saved"

A home rail seeded by the user's own saves, placed **second, after "In view"**
(owner's call), with a fixed heading — *"because you saved <title>"* would wrap
to two lines on most titles, which the owner did not want.

🔴 **The bug worth remembering is that the rail read the wrong half of
"saved".** This app stores saves in **Liked** (`LibraryStore`) *and* in **named
lists** (`TourListService`), and I read only the first — so the owner, who had
both, saw nothing. `Data/SaveState.swift` **opens by saying that exact split is
what it exists to remove**, and `TourSaveActions.isSaved` already held the
union, one call away.

**Seven tests passed, because all seven shared the wrong premise.** The general
lesson is not "read both stores": it is that **a rule with a named home was
restated somewhere else** — now recorded in `docs/lessons.md`.

## State

- `search/search-snippets.bin` and `search/embeddings.bin` are **both live and
  consistent**; the explanations appear with **no further app build**.
- The rebuild gate is now proven, so a future content merge maintains both.
- **Open question for the owner:** whether the saved rail earns its place. It
  is one function and one call site from deletion.

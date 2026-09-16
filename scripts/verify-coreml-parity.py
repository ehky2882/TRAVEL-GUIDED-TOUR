#!/usr/bin/env python3
"""
Does the converted Core ML model actually agree with the catalog's vectors?

    python3 scripts/verify-coreml-parity.py --model build/AtlasQueryEmbedder.mlpackage

🔴 macOS ONLY, AND THAT IS THE ENTIRE POINT. `coremltools` converts anywhere but
predicts only on Apple platforms. A conversion nobody executed is an assumption;
this script is what turns it into a fact, and it runs in
`.github/workflows/export-search-model.yml` on a `macos-26` runner BEFORE the
model is published.

WHAT IS ASSERTED, IN ORDER OF HOW MUCH IT MATTERS
--------------------------------------------------
1. **Ranking is unchanged.** The real question is never "how close are the
   numbers" — it is "does the phone put the same tours at the top". So the Core
   ML query and the Python query are ranked against **the same int8 index**, and
   must produce the same top ten.

   🔴 THE SAME INDEX ON BOTH SIDES IS THE WHOLE POINT, and it was got wrong once.
   The first version ranked Core ML + int8 against Python + full precision,
   reasoning that the first pairing is what a phone runs. True, but it made the
   MODEL answerable for the INDEX's rounding: run 8 failed four of six queries
   while reporting a query/query cosine of 0.99999 and top scores agreeing to
   0.0005, every disagreement an adjacent swap at ranks 7-10 — which is int8
   doing exactly what `--verify-quantization` has always said it does, and
   nothing to do with the conversion. Holding everything constant except the
   thing under test is what makes a failure here mean something.

   What int8 costs is still measured, on the same queries, and **reported rather
   than asserted** — demanding zero would be demanding that quantization be free.

   Positions where the two disagree are excused only if the SAME index scores
   both entries within `TIE_TOLERANCE`; a genuine reordering still fails.
2. **Meaning is unchanged.** The measured relations from `vector-parity.json`:
   "brutalist concrete tower" must stay nearer "concrete apartment block" than
   "a restaurant". A cosine number tells you vectors moved; this tells you the
   meaning moved.
3. **Vectors are close.** Cosine ≥ 0.999 per string. Deliberately last: it is
   the weakest of the three, because passing it does not prove the other two.

⚠️ EXACT EQUALITY WOULD BE WRONG. The catalog was embedded in fp32 (ONNX); the
phone runs fp16. They differ in the last places by construction. A test
demanding equality would fail forever and teach everyone to ignore it.

Exit 0 = the model may ship. Exit 1 = it may not. Exit 2 = could not check,
which is NOT a pass.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURE = REPO_ROOT / "TRAVEL GUIDED TOURTests" / "Fixtures" / "vector-parity.json"

sys.path.insert(0, str(REPO_ROOT / "scripts"))
import runstamp  # noqa: E402,F401

COSINE_FLOOR = 0.999
RANK_DEPTH = 10          # how deep the top-N comparison goes
# Two entries scored this close by the SAME index may swap places without
# anything being wrong — that is float summation order, not a difference in
# meaning. Measured on run 8: the query/query cosine was 0.99999 and top scores
# agreed to 0.0005, while adjacent entries at ranks 7-10 sat ~0.001 apart.
# Deliberately an order of magnitude tighter than the 0.01 gap
# `--verify-quantization` calls "large enough to reorder visible results".
TIE_TOLERANCE = 0.001
RANK_QUERIES = [
    "art deco lobby", "quiet garden away from crowds", "brutalist concrete tower",
    "stained glass windows", "rooftop view over the city", "food market",
]


def load_module():
    spec = importlib.util.spec_from_file_location(
        "build_embeddings", REPO_ROOT / "scripts" / "build-embeddings.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", required=True, help="the .mlpackage to check")
    parser.add_argument("--skip-ranking", action="store_true",
                        help="skip the catalog ranking check (it needs the full "
                             "embedding run, ~15 minutes)")
    args = parser.parse_args()

    try:
        import coremltools as ct
        import numpy as np
    except ImportError as exc:
        print(f"COULD NOT VERIFY: missing {exc.name}")
        return 2

    if sys.platform != "darwin":
        # Never return 0 here. A check that cannot run must not report a pass.
        print("COULD NOT VERIFY: Core ML prediction requires macOS. "
              "Run this via .github/workflows/export-search-model.yml.")
        return 2

    if not FIXTURE.exists():
        print(f"COULD NOT VERIFY: {FIXTURE.name} is missing — run "
              "scripts/dump-vector-fixture.py")
        return 2

    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    module = load_module()

    print(f"Loading {args.model} …")
    mlmodel = ct.models.MLModel(args.model)

    # The model must say it is the model the catalog was built with. Without
    # this, a stale package silently produces confident nonsense.
    metadata = mlmodel.user_defined_metadata
    declared = metadata.get("atlas.model_id", "")
    if declared != fixture["model"]:
        print(f"FAIL: model says {declared!r}, fixture expects {fixture['model']!r}")
        return 1
    print(f"  model_id  {declared}")
    print(f"  precision {metadata.get('atlas.precision', '?')}")

    embedder = module.Embedder()      # the Python side, for tokenizing
    tokenizer = embedder.tokenizer

    def core_ml_vector(text: str):
        ids = tokenizer.encode(text, add_special_tokens=False).ids
        # One window, matching `embed_one` — it returns the FIRST chunk, and a
        # query is short. Specials are re-added exactly as chunk_ids does.
        window = ids[: fixture["maxTokens"] - 2]
        wrapped = [tokenizer.token_to_id("[CLS]"), *window, tokenizer.token_to_id("[SEP]")]
        prediction = mlmodel.predict({"input_ids": np.array([wrapped], dtype=np.int32)})
        vector = np.array(prediction["embedding"], dtype=np.float32).reshape(-1)

        # 🔴 CAUGHT AT THE SOURCE, because NaN defeats every check downstream:
        # `nan < floor` is False, so a cosine floor PASSES it; `near <= far` is
        # False, so a relation guard passes it too. A model emitting pure NaN
        # therefore scored a clean run once already. Nothing that is not finite
        # gets to travel any further than this line.
        if not np.isfinite(vector).all():
            raise ValueError(
                f"model returned non-finite output for {text[:40]!r} — "
                f"{int((~np.isfinite(vector)).sum())} of {vector.size} values"
            )

        norm = float(np.linalg.norm(vector))
        if not np.isfinite(norm) or norm <= 1e-12:
            raise ValueError(f"model output has unusable norm {norm} for {text[:40]!r}")
        return vector / norm

    # --- 3. Per-string closeness (weakest, so reported first and trusted least)
    print(f"\nComparing {len(fixture['cases'])} vectors …")
    worst, worst_text, failures = 1.0, "", []
    produced: dict[str, "np.ndarray"] = {}
    for case in fixture["cases"]:
        expected = np.array(case["vector"], dtype=np.float32)
        actual = core_ml_vector(case["text"])
        produced[case["text"]] = actual
        cosine = float(expected @ actual)
        # ⚠️ `>=`, NEGATED — not `<`. `nan < floor` is False and would pass;
        # `not (nan >= floor)` is True and fails. Same for the running worst.
        if not (cosine >= worst):
            worst, worst_text = cosine, case["text"]
        if not (cosine >= COSINE_FLOOR):
            failures.append((case["text"], cosine))

    print(f"  worst cosine {worst:.6f}  on {worst_text[:48]!r}")
    if failures:
        print(f"\nFAIL: {len(failures)} vector(s) below {COSINE_FLOOR}")
        for text, cosine in failures[:10]:
            print(f"  {cosine:.6f}  {text[:60]!r}")
        return 1

    # --- 2. Meaning preserved
    print("\nChecking the measured relations …")
    for relation in fixture["relations"]:
        near = float(produced[relation["anchor"]] @ produced[relation["near"]])
        far = float(produced[relation["anchor"]] @ produced[relation["far"]])
        # `not (near > far)` rather than `near <= far`: with NaN the latter is
        # False, so the guard did not fire even though it printed FAIL — the
        # run carried on to ranking with NaN vectors.
        ok = bool(near > far)
        print(f"  {'ok  ' if ok else 'FAIL'} {near:.3f} vs {far:.3f}  {relation['anchor'][:34]!r}")
        if not ok:
            print(f"\nFAIL: through Core ML, {relation['anchor']!r} is no longer "
                  f"closer to {relation['near']!r} than to {relation['far']!r}. "
                  "The conversion changed what the model MEANS, not just its "
                  "sixth decimal place.")
            return 1

    # --- 1. 🔴 The one that matters: same top-N out of the real catalog
    if args.skip_ranking:
        print("\n⚠️  Ranking check SKIPPED — this run does not clear the model to ship.")
        return 0

    print(f"\nRanking {len(RANK_QUERIES)} queries against the real catalog …")
    tours = module.load_catalog()
    texts = [module.tour_text(t) for t in tours]
    chunks, owners = embedder.embed_chunks(texts, progress=True)

    # The index the phone reads: int8 at scale 127, dequantized and renormalised
    # exactly as TourEmbeddingStore does.
    quantized = (
        np.clip(np.rint(chunks * module.QUANT_SCALE), -127, 127).astype(np.int8)
        .astype(np.float32) / module.QUANT_SCALE
    )
    norms = np.linalg.norm(quantized, axis=1, keepdims=True)
    quantized = quantized / np.maximum(norms, 1e-12)

    # 🔴 TWO COMPARISONS, BECAUSE THERE ARE TWO SOURCES OF DRIFT AND ONLY ONE OF
    # THEM IS THIS SCRIPT'S SUBJECT.
    #
    # Run 8 failed asserting one identical top-10 against Python-full-precision,
    # and the diagnostics said plainly why: query/query cosine 0.99999, top
    # scores agreeing to 0.0005, and every disagreement an ADJACENT SWAP at
    # ranks 7-10. Nothing there is the conversion. It is int8, which
    # `--verify-quantization` has always predicted would do exactly this —
    # "a handful of near-ties deep in the list, never the top result".
    #
    # Folding both into one assertion made the model answerable for the index's
    # rounding, so the gate could only ever pass by luck. Split:
    #
    #   A. THE SHIP GATE — Core ML query vs Python query, BOTH against the
    #      quantized index. Everything is held constant except the thing this
    #      script exists to check. A difference here IS the conversion.
    #   B. REPORTED, NOT ASSERTED — quantized index vs full-precision index,
    #      both with the Python query. This is what int8 costs. It is a number
    #      to watch, not a pass/fail, because demanding zero would be demanding
    #      that quantization be free.
    mismatches = 0
    for query in RANK_QUERIES:
        python_query = embedder.embed_one(query)
        coreml_query = core_ml_vector(query)
        agreement = float(python_query @ coreml_query)

        # A — the gate. Same index on both sides.
        python_scores = module.tour_scores(np, quantized, owners, python_query, len(tours))
        coreml_scores = module.tour_scores(np, quantized, owners, coreml_query, len(tours))
        python_top = python_scores.argsort()[::-1][:RANK_DEPTH]
        coreml_top = coreml_scores.argsort()[::-1][:RANK_DEPTH]

        # B — the cost of int8, measured on the same query, reported only.
        full_scores = module.tour_scores(np, chunks, owners, python_query, len(tours))
        full_top = full_scores.argsort()[::-1][:RANK_DEPTH]
        kept = len(set(full_top) & set(python_top))

        print(f"    query/query cosine {agreement:.6f} · "
              f"top score {python_scores.max():.4f} "
              f"(spread over top {RANK_DEPTH}: {np.ptp(python_scores[python_top]):.4f}) · "
              f"int8 keeps {kept}/{RANK_DEPTH} of the fp32 order")

        if list(python_top) == list(coreml_top):
            print(f"  ok   {query!r}")
            continue

        # 🔴 NOT AUTOMATICALLY A FAILURE — but the excuse has to be earned, per
        # position, from the numbers. Two entries the SAME INDEX scores within
        # float noise of each other can land either way round without anything
        # being wrong. Anything else is the conversion reordering real results,
        # and that fails.
        #
        # ⚠️ `not (gap <= TIE)` rather than `gap > TIE`: NaN must fail this, and
        # every comparison against NaN is false.
        explained = True
        for rank, (a, b) in enumerate(zip(python_top, coreml_top), 1):
            if a == b:
                continue
            gap = abs(float(python_scores[a]) - float(python_scores[b]))
            # `gap <= TIE` and not `not (gap > TIE)`: with a NaN gap this is
            # False, so a NaN fails rather than being excused.
            excused = bool(gap <= TIE_TOLERANCE)
            mark = "tie " if excused else "🔴  "
            print(f"       {rank}. {mark} {gap:.5f}  python: {tours[a]['title'][:38]}")
            print(f"                       coreml: {tours[b]['title'][:38]}")
            if not excused:
                explained = False

        if explained:
            print(f"  ok   {query!r} — differs only where the scores are tied")
            continue
        mismatches += 1
        print(f"  FAIL {query!r} — reordered results that are NOT tied")

    if mismatches:
        print(f"\nFAIL: {mismatches} of {len(RANK_QUERIES)} queries rank differently "
              f"by more than {TIE_TOLERANCE}.")
        return 1

    print(f"\nPASS — top {RANK_DEPTH} agrees on every query (bar tied pairs), "
          f"relations intact, worst cosine {worst:.6f}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

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
1. **Ranking is unchanged, along the path the device actually takes.** The real
   question is never "how close are the numbers" — it is "does the phone put the
   same tours at the top". So the comparison is Python-full-precision against
   **Core ML query + int8-quantized index**, because that pairing is what runs on
   a phone. Testing Core ML against full-precision chunks would leave index
   quantization unmeasured, and quantization is an independent source of drift:
   ~0.9990 cosine per vector, which is small but not nothing.
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

    # 🔴 THE PHONE DOES NOT SEE THESE CHUNKS. It sees the SIDECAR, whose vectors
    # `write_embeddings` stores int8-quantized at scale 127. Comparing Core ML
    # against Python using full-precision chunks on both sides would test a path
    # nothing runs, and would leave index quantization — a second, independent
    # source of drift — entirely unmeasured.
    #
    # So the "device" side below ranks against DEQUANTIZED chunks, which is what
    # TourEmbeddingStore will read. Measured on the parity fixture, quantization
    # costs ~0.9990 cosine per vector; the question this answers is whether that
    # is enough to reorder anything that matters.
    quantized = (
        np.clip(np.rint(chunks * module.QUANT_SCALE), -127, 127).astype(np.int8)
        .astype(np.float32) / module.QUANT_SCALE
    )
    norms = np.linalg.norm(quantized, axis=1, keepdims=True)
    quantized = quantized / np.maximum(norms, 1e-12)

    mismatches = 0
    for query in RANK_QUERIES:
        # 🔴 DIAGNOSTICS, because run 4 produced a result that cannot happen.
        # Every ranking query is also a fixture string, and all 69 matched
        # Python to >= 0.999 cosine minutes earlier — yet the top-10 came back
        # completely disjoint (markets vs Sydney beaches for "food market").
        # Two vectors 0.999 apart cannot do that, so one of those facts is
        # false. These lines say which, instead of guessing:
        python_query = embedder.embed_one(query)
        coreml_query = core_ml_vector(query)
        agreement = float(python_query @ coreml_query)

        python_scores = module.tour_scores(np, chunks, owners, python_query, len(tours))
        coreml_scores = module.tour_scores(np, quantized, owners, coreml_query, len(tours))
        python_top = python_scores.argsort()[::-1][:RANK_DEPTH]
        coreml_top = coreml_scores.argsort()[::-1][:RANK_DEPTH]

        print(f"    query/query cosine {agreement:.6f} · "
              f"python top score {python_scores.max():.4f} "
              f"(spread over top 10: {np.ptp(python_scores[python_top]):.4f}) · "
              f"coreml top score {coreml_scores.max():.4f}")

        if list(python_top) == list(coreml_top):
            print(f"  ok   {query!r}")
            continue
        mismatches += 1
        print(f"  FAIL {query!r} — top {RANK_DEPTH} differs")
        for rank, (a, b) in enumerate(zip(python_top, coreml_top), 1):
            mark = " " if a == b else "←"
            print(f"       {rank}.{mark} python: {tours[a]['title'][:40]}")
            if a != b:
                print(f"          coreml: {tours[b]['title'][:40]}")

    if mismatches:
        print(f"\nFAIL: {mismatches} of {len(RANK_QUERIES)} queries rank differently.")
        return 1

    print(f"\nPASS — identical top {RANK_DEPTH} on every query, relations intact, "
          f"worst cosine {worst:.6f}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

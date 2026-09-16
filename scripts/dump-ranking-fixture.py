#!/usr/bin/env python3
"""
Pin the Swift port of `tour_scores` against Python, on a real sidecar.

    python3 scripts/dump-ranking-fixture.py

Writes `TRAVEL GUIDED TOURTests/Fixtures/ranking-parity.{bin,json}` — a small
but genuine `ATLSEMB2` sidecar plus the scores and ordering Python produces
from it for a handful of queries.

🔴 WHY THIS EXISTS. `build-embeddings.py`'s own docstring on `tour_scores` says
"THIS IS THE FUNCTION THE APP RE-IMPLEMENTS… keep this in step with the Swift
side". A re-implementation that drifts does not crash — it returns a slightly
different order, forever, with nothing to say so. `verify-coreml-parity.py`
proves the MODEL agrees; `TokenizerParityTests` proves the TOKENIZER agrees.
This is the third seam: the SCORING and the file format.

⚠️ THE SIDECAR IS SMALL ON PURPOSE. It is committed to the test bundle, so it
has to stay small — but it is built by the real `write_embeddings` from real
catalogue text, so the offsets, the int8 quantization and the multi-chunk tours
are all genuine. A hand-written fixture would test the reader against my idea
of the format rather than against the format.

⚠️ QUERY VECTORS ARE SHIPPED, NOT TEXTS. This fixture is about scoring alone.
Feeding Swift a query string here would make a tokenizer or model failure look
like a scoring failure; the other two fixtures cover those seams separately.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURES = REPO_ROOT / "TRAVEL GUIDED TOURTests" / "Fixtures"

sys.path.insert(0, str(REPO_ROOT / "scripts"))
import runstamp  # noqa: E402,F401

# Enough entries that ties, multi-chunk tours and a floor all get exercised,
# few enough that the committed sidecar stays a few hundred KB.
SAMPLE = 48
QUERIES = [
    "art deco lobby",
    "quiet garden away from crowds",
    "brutalist concrete tower",
    "food market",
]
FLOOR = 0.25          # low, so a short fixture still returns several matches
LIMIT = 10


def main() -> int:
    import numpy as np

    spec = importlib.util.spec_from_file_location(
        "build_embeddings", REPO_ROOT / "scripts" / "build-embeddings.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    tours = module.load_catalog()
    # Spread the sample across the catalogue rather than taking the first N:
    # the first N are one city and one maker, which is the least interesting
    # thing a ranking fixture could contain.
    step = max(1, len(tours) // SAMPLE)
    sample = tours[::step][:SAMPLE]
    print(f"Sampling {len(sample)} of {len(tours)} entries (every {step}th)")

    embedder = module.Embedder()
    texts = [module.tour_text(t) for t in sample]
    chunks, owners = embedder.embed_chunks(texts, progress=True)
    print(f"  {len(chunks)} chunks for {len(sample)} entries")

    binary = FIXTURES / "ranking-parity.bin"
    size = module.write_embeddings(sample, chunks, owners, binary, np)

    # 🔴 SCORE AGAINST THE DEQUANTIZED CHUNKS, not the full-precision ones.
    # Swift reads int8 out of that file and divides by the scale; comparing it
    # against Python's fp32 chunks would bake quantization drift into the
    # expected numbers and make the tolerance meaningless.
    dequantized = (
        np.clip(np.rint(chunks * module.QUANT_SCALE), -127, 127).astype(np.int8)
        .astype(np.float32) / module.QUANT_SCALE
    )
    dequantized /= np.maximum(
        np.linalg.norm(dequantized, axis=1, keepdims=True), 1e-12
    )

    cases = []
    for query in QUERIES:
        vector = embedder.embed_one(query)
        scores = module.tour_scores(
            np, dequantized, owners, vector, len(sample)
        )
        order = [i for i in scores.argsort()[::-1] if scores[i] >= FLOOR][:LIMIT]
        cases.append({
            "query": query,
            "queryVector": [float(v) for v in vector],
            "expected": [
                {"id": sample[i]["id"], "score": float(scores[i]),
                 "title": sample[i]["title"][:60]}
                for i in order
            ],
        })
        print(f"  {query!r}: {len(order)} above {FLOOR} "
              f"(top {scores[order[0]]:.4f})" if order else
              f"  {query!r}: nothing above {FLOOR}")

    payload = {
        "model": module.MODEL_ID,
        "dims": module.DIMS,
        "bestChunkWeight": module.BEST_CHUNK_WEIGHT,
        "quantScale": module.QUANT_SCALE,
        "floor": FLOOR,
        "limit": LIMIT,
        "entries": len(sample),
        "chunks": int(len(chunks)),
        "cases": cases,
    }
    out = FIXTURES / "ranking-parity.json"
    out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
                   encoding="utf-8")

    print(f"\nWrote {binary.name} ({size:,} bytes) and {out.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

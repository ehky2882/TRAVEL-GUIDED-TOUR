#!/usr/bin/env python3
"""
Freeze the VECTORS the Python pipeline produces, so Core ML can be held to them.

    python3 scripts/dump-vector-fixture.py

Writes `TRAVEL GUIDED TOURTests/Fixtures/vector-parity.json`: query strings, the
384-dim unit vector each one embeds to, and enough metadata to refuse a
mismatched model.

🔴 THE SECOND HALF OF THE SAME RISK. `tokenizer-parity.json` proves the phone
splits text into the same token ids. This proves the phone turns those ids into
the same NUMBERS. Both must hold: identical ids through a different model, or
identical model over different ids, each produce a vector that is quietly wrong
and ranks the catalog quietly wrongly — no crash, no log, no red build.

⚠️ EXACT EQUALITY IS THE WRONG TEST HERE, unlike the tokenizer. The catalog was
embedded with the fp32 ONNX model; the phone runs a **fp16** Core ML conversion.
Those differ in the last few decimal places by construction, so the assertion is
cosine similarity ≥ 0.999 — and, far more importantly, that RANKING is unchanged
(see `--rank-fixture`). A vector may drift slightly and still rank identically;
ranking is the property search actually depends on, so it is asserted directly
rather than inferred from a distance.

The strings are reused from the tokenizer fixture so the two suites cover the
same ground, plus real queries someone would type.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURES = REPO_ROOT / "TRAVEL GUIDED TOURTests" / "Fixtures"
TOKENIZER_FIXTURE = FIXTURES / "tokenizer-parity.json"
OUT = FIXTURES / "vector-parity.json"

sys.path.insert(0, str(REPO_ROOT / "scripts"))
import runstamp  # noqa: E402,F401


# Queries a person would actually type, chosen so that a human can look at the
# ranking and say whether it is right. "Does this rank sensibly?" is not a
# question a list of random strings can answer.
REAL_QUERIES = [
    "art deco lobby",
    "quiet garden away from crowds",
    "brutalist concrete tower",
    "stained glass windows",
    "where the river bends",
    "modernist housing estate",
    "rooftop view over the city",
    "food market",
    # The comparison halves for RELATIONS below.
    "concrete apartment block",
    "a peaceful temple garden",
    "a restaurant",
]


# Pairs whose ORDER must survive the trip through Core ML, each with a wide
# enough margin that fp16 rounding cannot flip it.
#
# ⚠️ THE FIRST VERSION OF THIS CHECK WAS WRONG, and it is worth recording why.
# It asserted "art deco lobby" sits closer to "stained glass windows" than to
# "food market". It does not: 0.133 against 0.224. That is not the model
# misbehaving — the two are architectural details from unrelated traditions, and
# both figures are down in the noise where the model holds no real opinion. The
# assertion was an assumption about what the model *ought* to think, dressed up
# as a check.
#
# These replacements were MEASURED first. Each is a case where the model is
# emphatic (≈0.5 against ≈0.1), so the margin is the point, not the value.
RELATIONS = [
    ("brutalist concrete tower", "concrete apartment block", "a restaurant"),
    ("quiet garden away from crowds", "a peaceful temple garden", "food market"),
    ("food market", "a restaurant", "brutalist concrete tower"),
]


def load_module():
    spec = importlib.util.spec_from_file_location(
        "build_embeddings", REPO_ROOT / "scripts" / "build-embeddings.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    module = load_module()

    if not TOKENIZER_FIXTURE.exists():
        raise SystemExit(
            f"ERROR: {TOKENIZER_FIXTURE.relative_to(REPO_ROOT)} is missing — run "
            "scripts/dump-tokenizer-fixture.py first. The two fixtures cover the "
            "same strings on purpose."
        )
    tokenizer_fixture = json.loads(TOKENIZER_FIXTURE.read_text(encoding="utf-8"))

    # Every tokenizer case that produces at least one token. An empty string has
    # no vector to compare — the app must never embed one, and the tokenizer
    # suite already pins that it yields no tokens.
    inherited = [c["text"] for c in tokenizer_fixture["cases"] if c["ids"]]
    strings = REAL_QUERIES + inherited

    embedder = module.Embedder()
    np = embedder.np

    vectors = [embedder.embed_one(text) for text in strings]

    cases = []
    for text, vector in zip(strings, vectors):
        norm = float(np.linalg.norm(vector))
        # The pipeline L2-normalizes, so anything else means the Swift side is
        # being handed a contract this file does not actually keep.
        if abs(norm - 1.0) > 1e-4:
            raise SystemExit(f"ERROR: vector for {text!r} is not unit length ({norm})")
        cases.append({
            "text": text,
            # Rounded to 6 places: the fixture is compared at 1e-3, so full
            # float repr would be 3x the bytes for precision nothing asserts.
            "vector": [round(float(value), 6) for value in vector],
        })

    # Relationships, so a failure says something a human can act on. A cosine
    # number tells you the vectors moved; this tells you the MEANING moved.
    def similarity(a: str, b: str) -> float:
        return round(float(vectors[strings.index(a)] @ vectors[strings.index(b)]), 6)

    relations = []
    for anchor, near, far in RELATIONS:
        close, distant = similarity(anchor, near), similarity(anchor, far)
        if close <= distant:
            raise SystemExit(
                f"ERROR: {anchor!r} is not closer to {near!r} ({close}) than to "
                f"{far!r} ({distant}). Do not pin this — either the model changed "
                "or the relation was never true."
            )
        relations.append({
            "anchor": anchor, "near": near, "far": far,
            "nearScore": close, "farScore": distant,
        })

    payload = {
        "model": module.MODEL_ID,
        "dims": module.DIMS,
        "maxTokens": module.MAX_TOKENS,
        "chunkStride": module.CHUNK_STRIDE,
        "bestChunkWeight": module.BEST_CHUNK_WEIGHT,
        "relations": relations,
        "cases": cases,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    size = OUT.stat().st_size
    print(f"Wrote {OUT.relative_to(REPO_ROOT)}")
    print(f"  {len(cases)} vectors x {module.DIMS} dims · {size:,} bytes")
    for relation in relations:
        margin = relation["nearScore"] - relation["farScore"]
        print(f"  {relation['nearScore']:.3f} vs {relation['farScore']:.3f} "
              f"(margin {margin:.3f})  {relation['anchor'][:34]!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""
Convert all-MiniLM-L6-v2 to a Core ML package the phone can run.

    python3 scripts/export-coreml.py --out build/AtlasQueryEmbedder.mlpackage

🔴 RUN THIS ON macOS, VIA `.github/workflows/export-search-model.yml`. Conversion
itself works on Linux, but a Core ML model can only be **executed** on an Apple
platform — and an unexecuted conversion is exactly the kind of "probably fine"
this project does not ship. The workflow converts and then predicts with the
result, asserting it matches `vector-parity.json` before publishing anything.

WHAT IS EXPORTED, AND WHY IT IS MORE THAN THE BARE MODEL
--------------------------------------------------------
The wrapper below folds **mean-pooling and L2 normalisation into the graph**, so
the model's single output is the finished unit vector. That is deliberate: those
two steps are where `embed_chunks` in `build-embeddings.py` is fussy —

    "Mean over real tokens only — padding must not drag vectors toward zero."

— and every line of that logic re-written in Swift is a line that can drift from
Python without anything noticing. Inside the graph it is converted once, from
the same source, and verified end-to-end.

FP16, NOT INT8
--------------
fp16 is ~45 MB; int8 would be ~23 MB. int8 perturbs the weights, which is
precisely what makes a phone and a server disagree. Ship fp16, then try int8 as
a MEASURED follow-up: re-run the parity check against an int8 export and keep it
only if it still passes. Guessing here costs a silent quality regression.

⚠️ coremltools dropped ONNX conversion at v6, so this goes via PyTorch — the
~800 MB dependency `build-embeddings.py` deliberately avoids. That is acceptable
here because this is a one-off export, not a per-merge job.
"""
from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))
import runstamp  # noqa: E402,F401


def load_constants():
    """MODEL_ID / DIMS / MAX_TOKENS from the one file that defines them."""
    spec = importlib.util.spec_from_file_location(
        "build_embeddings", REPO_ROOT / "scripts" / "build-embeddings.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def build_wrapper(torch, transformers, model_id: str):
    """
    The transformer plus the two steps that turn its output into a vector.

    Mirrors `Embedder.embed_chunks` exactly:
      1. last_hidden_state
      2. mean over positions where attention_mask == 1  (NOT over padding)
      3. L2 normalise
    """
    import torch.nn as nn

    class SentenceEmbedder(nn.Module):
        def __init__(self, backbone):
            super().__init__()
            self.backbone = backbone

        def forward(self, input_ids, attention_mask):
            # 🔴 token_type_ids PASSED EXPLICITLY, not left to default.
            # Omitting them sends BertModel down a branch that fabricates them
            # from a registered buffer via `new_ones`/`expand` — and coremltools
            # has no converter for `new_ones`, so the trace fails with
            # "PyTorch convert function for op 'new_ones' not implemented".
            # Zeros is also exactly what the ONNX path feeds
            # (`build-embeddings.py`: `feed["token_type_ids"] = zeros_like(ids)`),
            # so this matches the catalog rather than merely compiling.
            hidden = self.backbone(
                input_ids=input_ids,
                attention_mask=attention_mask,
                token_type_ids=torch.zeros_like(input_ids),
            ).last_hidden_state

            # 🔴 Masked mean. Summing over ALL positions and dividing by the
            # sequence length would pull every short query toward zero by
            # however much padding it happened to carry — the exact bug the
            # Python comment warns about.
            mask = attention_mask.unsqueeze(-1).to(hidden.dtype)
            summed = (hidden * mask).sum(dim=1)
            counts = mask.sum(dim=1).clamp(min=1e-9)
            pooled = summed / counts

            return pooled / pooled.norm(p=2, dim=1, keepdim=True).clamp(min=1e-12)

    # ⚠️ `attn_implementation="eager"` is load-bearing for conversion. The
    # default (SDPA) routes through transformers' mask utilities, which build
    # masks with dynamic ops coremltools cannot convert. Eager attention is the
    # same arithmetic written plainly — the numbers are identical, the graph is
    # traceable.
    backbone = transformers.AutoModel.from_pretrained(
        model_id, attn_implementation="eager"
    )
    backbone.eval()
    wrapper = SentenceEmbedder(backbone)
    wrapper.eval()
    return wrapper


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, help="destination .mlpackage path")
    parser.add_argument("--int8", action="store_true",
                        help="quantize to int8 (~23 MB). Only ship this if the "
                             "parity check still passes — see the module docstring.")
    args = parser.parse_args()

    try:
        import coremltools as ct
        import numpy as np
        import torch
        import transformers
    except ImportError as exc:
        raise SystemExit(
            f"ERROR: missing dependency ({exc.name}). This script needs torch, "
            "transformers and coremltools:\n"
            "    pip install torch transformers coremltools"
        )

    constants = load_constants()
    model_id, dims, max_tokens = constants.MODEL_ID, constants.DIMS, constants.MAX_TOKENS

    print(f"Loading {model_id} …")
    wrapper = build_wrapper(torch, transformers, model_id)

    # Trace at a representative length. The converted model accepts any length
    # in [1, max_tokens] via the RangeDim below; the trace length only has to
    # exercise the graph.
    trace_length = 16
    example_ids = torch.ones((1, trace_length), dtype=torch.int32)
    example_mask = torch.ones((1, trace_length), dtype=torch.int32)

    with torch.no_grad():
        reference = wrapper(example_ids, example_mask)
        traced = torch.jit.trace(wrapper, (example_ids, example_mask))

    if reference.shape[-1] != dims:
        raise SystemExit(
            f"ERROR: model produced {reference.shape[-1]} dims, catalog expects {dims}"
        )

    # A query is ONE window: `Embedder.embed_one` returns the first chunk, and
    # queries are short. So a single flexible-length input covers the whole
    # query path — no chunking on device.
    sequence = ct.RangeDim(lower_bound=1, upper_bound=max_tokens, default=trace_length)
    inputs = [
        ct.TensorType(name="input_ids", shape=(1, sequence), dtype=np.int32),
        ct.TensorType(name="attention_mask", shape=(1, sequence), dtype=np.int32),
    ]

    print("Converting to Core ML (fp16) …")
    mlmodel = ct.convert(
        traced,
        inputs=inputs,
        outputs=[ct.TensorType(name="embedding")],
        minimum_deployment_target=ct.target.iOS17,
        compute_precision=ct.precision.FLOAT16,
        convert_to="mlprogram",
    )

    if args.int8:
        print("Quantizing to int8 — parity MUST be re-checked before shipping this …")
        from coremltools.optimize.coreml import (
            OpLinearQuantizerConfig, OptimizationConfig, linear_quantize_weights,
        )
        config = OptimizationConfig(
            global_config=OpLinearQuantizerConfig(mode="linear_symmetric", dtype="int8")
        )
        mlmodel = linear_quantize_weights(mlmodel, config=config)

    # The model id travels WITH the model, for the same reason the embeddings
    # sidecar carries it in its header: a model/index mismatch is otherwise
    # completely invisible — every vector is plausible and every ranking wrong.
    mlmodel.author = "Atlas / Dozent"
    mlmodel.short_description = (
        f"Sentence embeddings for semantic search. {model_id}, {dims} dims, "
        f"masked mean-pooled and L2-normalised in-graph."
    )
    mlmodel.user_defined_metadata["atlas.model_id"] = model_id
    mlmodel.user_defined_metadata["atlas.dims"] = str(dims)
    mlmodel.user_defined_metadata["atlas.max_tokens"] = str(max_tokens)
    mlmodel.user_defined_metadata["atlas.precision"] = "int8" if args.int8 else "fp16"

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    mlmodel.save(str(out))

    total = sum(f.stat().st_size for f in out.rglob("*") if f.is_file())
    print(f"\nWrote {out}")
    print(f"  {total:,} bytes ({total / 1e6:.1f} MB)")
    print(f"  model_id  {model_id}")
    print(f"  precision {'int8' if args.int8 else 'fp16'}")
    print("\n🔴 NOT YET PROVEN. Run scripts/verify-coreml-parity.py against this "
          "package on macOS before it goes anywhere near a phone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

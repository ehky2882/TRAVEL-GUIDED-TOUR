#!/usr/bin/env python3
"""
Extract `vocab.txt` for the app from the model's own `tokenizer.json`.

    python3 scripts/export-tokenizer-vocab.py

Writes `TRAVEL GUIDED TOUR/Resources/vocab.txt` — one token per line, id = line
number, which is what `WordPieceTokenizer.init(vocabularyText:)` expects.

🔴 EXTRACTED, NEVER HAND-MAINTAINED, AND NEVER DOWNLOADED SEPARATELY. The ids
in this file ARE the contract: the catalog's vectors were produced from these
exact token ids, so a vocabulary that is off by one line anywhere produces
vectors that are quietly wrong — every query slightly misaligned, nothing
crashing, nothing logged. Deriving it from the same `tokenizer.json` the
embedding pipeline loads is what keeps the two from ever disagreeing.

⚠️ The file is written in ID ORDER, densely. A BERT vocabulary is a contiguous
0..n-1 range; if this script ever finds a gap it refuses to write, because a
gap means the assumption "line number == id" has stopped holding and every
token after the gap would be misread.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT = REPO_ROOT / "TRAVEL GUIDED TOUR" / "Resources" / "vocab.txt"

sys.path.insert(0, str(REPO_ROOT / "scripts"))
import runstamp  # noqa: E402,F401


def main() -> int:
    spec = importlib.util.spec_from_file_location(
        "build_embeddings", REPO_ROOT / "scripts" / "build-embeddings.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    directory = module.ensure_model()          # downloads tokenizer.json if absent
    raw = json.loads((directory / "tokenizer.json").read_text(encoding="utf-8"))
    vocab: dict[str, int] = raw["model"]["vocab"]

    ordered = sorted(vocab.items(), key=lambda pair: pair[1])
    expected = list(range(len(ordered)))
    actual = [identifier for _, identifier in ordered]
    if actual != expected:
        # Find the first disagreement and say so precisely — "the vocab is
        # wrong" is not an actionable error message.
        for position, (token, identifier) in enumerate(ordered):
            if position != identifier:
                raise SystemExit(
                    f"ERROR: vocabulary ids are not dense — expected {position} "
                    f"at this position, found {identifier} ({token!r}). "
                    "`line number == id` no longer holds; the Swift tokenizer "
                    "would misread every token after this point."
                )

    # A token containing a newline would break the one-per-line format and
    # silently shift every id after it. BERT vocabularies do not contain one,
    # so this is a guard against a future model rather than a live case.
    for token, identifier in ordered:
        if "\n" in token or "\r" in token:
            raise SystemExit(f"ERROR: token {identifier} contains a newline: {token!r}")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(token for token, _ in ordered) + "\n", encoding="utf-8")

    size = OUT.stat().st_size
    print(f"Wrote {OUT.relative_to(REPO_ROOT)}")
    print(f"  {len(ordered):,} tokens · {size:,} bytes")
    for special in ("[PAD]", "[UNK]", "[CLS]", "[SEP]", "[MASK]"):
        print(f"  {special:<7} = {vocab[special]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

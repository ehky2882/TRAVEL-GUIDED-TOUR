#!/usr/bin/env python3
"""
Freeze what the Python tokenizer does, so the Swift one can be held to it.

    python3 scripts/dump-tokenizer-fixture.py

Writes `TRAVEL GUIDED TOURTests/Fixtures/tokenizer-parity.json`: a list of
strings and the exact token ids `tokenizers` produces for each, plus the
tokenizer's own identifying metadata.

🔴 WHY THIS EXISTS, AND WHY IT IS THE FIRST THING BUILT.

Semantic search needs the phone to turn a typed query into a vector, and the
vector is only comparable to the catalog's vectors if the query is tokenized
EXACTLY as the catalog was. There is no Apple framework for BERT WordPiece, so
the Swift side is a hand-written reimplementation of
`all-MiniLM-L6-v2`'s `tokenizer.json` — and a reimplementation that is subtly
wrong does not crash. It returns slightly different ids, which produce a
slightly different vector, which produces plausible-looking but worse results,
with nothing anywhere saying so. That is the failure shape this project keeps
paying for (`docs/lessons.md`).

So the ids are pinned here, from the real tokenizer, and
`SemanticParityTests` fails the build when Swift disagrees.

⚠️ THE FIXTURE IS DELIBERATELY NASTY, and each group is here because it is a
way the Swift side could plausibly differ:

  * **CJK** — `BertNormalizer` has `handle_chinese_chars: true`, which pads
    every CJK codepoint with spaces so each becomes its own token. Miss that
    and Japanese queries tokenize as one huge [UNK]. 281 catalog titles carry
    CJK, so this path is live, not theoretical.
  * **Thai** — NOT in the CJK ranges, so it must NOT be padded. It is the
    control that catches over-applying the rule.
  * **Arabic** — right-to-left, and also not padded.
  * **Accents** — `strip_accents` is null, which for a lowercasing BERT means
    it follows `lowercase`: accents ARE stripped via NFD. Easy to get backwards.
  * **Emoji** — pin titles begin with them (🦑, 🔥). They are not letters, not
    punctuation, and not CJK.
  * **Long text** — must exceed the 256-token window so chunking is exercised.
  * **Degenerate** — empty, whitespace, control characters, a 150-character
    word that trips `max_input_chars_per_word: 100`.

The strings come from the real catalog wherever possible: a fixture invented
from imagination tests the imagination, not the content.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT = REPO_ROOT / "TRAVEL GUIDED TOURTests" / "Fixtures" / "tokenizer-parity.json"
CATALOG = REPO_ROOT / "TRAVEL GUIDED TOUR" / "Resources" / "Tours.json"

sys.path.insert(0, str(REPO_ROOT / "scripts"))
import runstamp  # noqa: E402,F401  (stamps the run; see scripts/runstamp.py)


def load_embedder_module():
    """Reuse build-embeddings.py rather than re-deriving any of its setup."""
    spec = importlib.util.spec_from_file_location(
        "build_embeddings", REPO_ROOT / "scripts" / "build-embeddings.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# Hand-written cases, each one a specific way Swift could differ. Kept separate
# from the catalog-drawn ones so a content change cannot quietly drop a case.
SYNTHETIC = [
    # Ordinary queries — what someone would actually type.
    "art deco lobby",
    "quiet garden away from crowds",
    "brutalist concrete tower",
    "Where can I hear about bridges?",
    # Casing and punctuation.
    "ART DECO LOBBY",
    "St. Paul's Cathedral",
    "co-operative — the em dash",
    "hyphen-separated words",
    '"quoted" (parenthesised) [bracketed]',
    # Accents: strip_accents is null, which follows lowercase → stripped.
    "café façade",
    "Gaudí's Sagrada Família",
    "Ångström Malmö Zürich",
    # Numbers, which WordPiece splits in its own way.
    "1920s architecture",
    "57th street",
    "a 1,200-metre walk",
    # Degenerate input. A search box receives all of this.
    "",
    " ",
    "\t\n  \r",
    "a",
    "?",
    "🙂",
    # 🔴 GRAPHEME CLUSTERS, which is the one class of bug the Python mirror of
    # this tokenizer cannot detect. Swift's `Character` counts each of these as
    # ONE; BERT counts code points (a flag is 2, a skin tone is 2, a ZWJ family
    # is 5). A Swift WordPiece walking `Character` passes every other case here
    # and silently disagrees on these.
    "🇯🇵 Tokyo",
    "👍🏽 great tour",
    "👨‍👩‍👧 family walk",
    "x" * 150,  # over max_input_chars_per_word (100) → [UNK]
    "zzzzqqqq",  # not in a 30k vocab → subwords or [UNK]
    # Mixed scripts in one string, which is what a bilingual title is.
    "Tokyo Tower | 東京タワー",
    "Senso-ji 浅草寺 temple",
]


def catalog_samples(limit_per_script: int = 8) -> list[str]:
    """
    Real titles, chosen for script rather than at random.

    Random sampling would be 90% Latin and would miss the cases that matter —
    the point is coverage of the normalizer's branches, not of the catalog.
    """
    import re

    if not CATALOG.exists():
        return []
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    entries = list(data.get("tours") or []) + list(data.get("linkPins") or [])

    patterns = {
        "cjk": re.compile(r"[぀-ヿ一-鿿가-힯]"),
        "thai": re.compile(r"[฀-๿]"),
        "arabic": re.compile(r"[؀-ۿ]"),
        "emoji": re.compile(r"[\U0001F000-\U0001FAFF]"),
    }
    picked: list[str] = []
    for pattern in patterns.values():
        hits = [t["title"] for t in entries if t.get("title") and pattern.search(t["title"])]
        # Sorted, not sampled: the fixture must be stable across runs, or every
        # regeneration produces a spurious diff.
        picked.extend(sorted(set(hits))[:limit_per_script])

    # One genuinely long body, to exercise the 256-token window and chunking.
    longest = max(
        (t.get("longDescription") or "" for t in entries), key=len, default=""
    )
    if longest:
        picked.append(longest[:4000])
    return picked


def main() -> int:
    module = load_embedder_module()
    embedder = module.Embedder()          # loads tokenizer.json, downloads if absent
    tokenizer = embedder.tokenizer

    strings = SYNTHETIC + catalog_samples()
    cases = []
    for text in strings:
        encoding = tokenizer.encode(text, add_special_tokens=False)
        cases.append({
            "text": text,
            "ids": encoding.ids,
            "tokens": encoding.tokens,   # not asserted; it makes a failure readable
        })

    vocab = tokenizer.get_vocab()
    payload = {
        "model": module.MODEL_ID,
        "vocabSize": len(vocab),
        # Pinned so a Swift side reading a different vocab file fails loudly
        # rather than scoring everything against the wrong ids.
        "specialTokens": {
            name: vocab[name] for name in ("[PAD]", "[UNK]", "[CLS]", "[SEP]", "[MASK]")
        },
        "maxInputCharsPerWord": 100,
        "cases": cases,
    }

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    unk = payload["specialTokens"]["[UNK]"]
    with_unk = sum(1 for c in cases if unk in c["ids"])
    print(f"Wrote {OUT.relative_to(REPO_ROOT)}")
    print(f"  {len(cases)} cases · {len(vocab):,} vocab entries")
    print(f"  {sum(len(c['ids']) for c in cases):,} token ids pinned")
    print(f"  {with_unk} case(s) contain [UNK] — expected for the degenerate ones")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

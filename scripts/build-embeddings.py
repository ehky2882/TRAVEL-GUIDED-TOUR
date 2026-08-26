#!/usr/bin/env python3
"""
build-embeddings.py — make the catalog searchable by MEANING, not by letters.

WHY THIS EXISTS
---------------
The catalog carries 1,774 stop transcripts — every word every narrator says —
and nothing can search them. `SearchView.filteredTours` is a case-insensitive
substring match over title, category, maker name, tags and the two
descriptions. Stops are never scanned. So "art deco lobby" returns nothing
even though a dozen scripts describe exactly that, and no amount of work on a
substring matcher will ever fix it: the words simply are not in the fields
being searched, and often are not in the transcript either. A tour about a
quiet riverside promenade rarely contains the word "quiet".

Semantic search fixes the category of problem, not one query. A sentence
embedding model turns text into ~384 numbers positioned so that text about
similar things lands in similar places. Comparing two of those is arithmetic,
which is why the whole catalog can be ranked in milliseconds on a phone.

THE ARCHITECTURAL POINT — THE PHONE DOES ALMOST NONE OF THE WORK
---------------------------------------------------------------
This script embeds all 1,418 tours ONCE, here, and ships the result as a
~2.7 MB sidecar file. The phone only ever embeds the one short string the
model has not already seen: the user's query. That is what makes this viable
for a walking-tour app — no server, no network while walking, no per-search
cost, and a model small enough to bundle.

🔴 THE TRAP THAT MAKES THIS SILENTLY WRONG: the model here and the model on
the phone must be THE SAME CHECKPOINT. Embeddings from two different models
are not comparable — they do not error, they return confident nonsense, which
is exactly the failure mode `AudioTranscriber` refuses to allow when it will
not fall back to an English speech model for Spanish narration. So the model
identifier is written into the file's header and the app must refuse to load a
file whose identifier it does not recognise.

WHAT IT DOES
------------
Reads Tours.json, builds one text blob per tour (title, city, country, tags,
both descriptions, and EVERY stop's transcript), embeds it, and writes
`embeddings.bin`.

Long tours exceed the model's 256-token window, so a blob is split into
overlapping chunks (~5 per tour) and each chunk is embedded separately.
Truncating instead would throw away most of a six-stop walk.

⚠️ CHUNKS ARE STORED, NOT A SINGLE AVERAGED VECTOR PER TOUR, and that is a
measured decision rather than a tidy one. Averaging a tour's chunks dilutes
whatever is distinctive about it: the Chrysler Building's art deco lobby is
one paragraph in six, and the mean buries it. Scoring instead against the
BEST-MATCHING chunk put Radio City Music Hall and the Chrysler top for
"art deco lobby", where the mean returned neither. But the mean is better for
broad, atmospheric queries — "somewhere quiet to sit near the water" wants a
tour that is calm throughout, not one calm sentence. So the app scores

    0.6 x best-chunk + 0.4 x mean-of-chunks

and the mean is derived on the phone from the chunks, costing no extra bytes.
Store only tour means and the specific queries get materially worse with no
way to recover them.

USAGE
-----
    python3 scripts/build-embeddings.py --query "somewhere quiet near water"
    python3 scripts/build-embeddings.py --query "art deco lobby" --compare
    python3 scripts/build-embeddings.py --write
    python3 scripts/build-embeddings.py --selftest      # logic only, no model

Dry run by default (reports what it would write), matching
check-image-duplicates.py and apply_tags.py. Nothing is written without
--write.

MODEL
-----
sentence-transformers/all-MiniLM-L6-v2 — Apache 2.0, genuinely open source,
384 dimensions, ~87 MB as fp32 ONNX here and ~23 MB quantized for Core ML on
the phone. Fetched to ~/.cache/atlas-embed on first run.

Stored vectors are int8-quantized against a single global scale. Unit-length
embeddings live in [-1, 1], so one scale is enough and the error is far below
the gap between a relevant tour and an irrelevant one — --verify-quantization
measures it rather than assuming it. That halves the download against fp16.

Exit codes: 0 = fine, 1 = a check failed, 2 = missing file / model / network.
"""

from __future__ import annotations

import argparse
import json
import os
import struct
import sys
import urllib.request
import uuid
from pathlib import Path

# --- Layout -----------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
TOURS_JSON = REPO_ROOT / "TRAVEL GUIDED TOUR" / "Resources" / "Tours.json"
OUTPUT = REPO_ROOT / "build" / "embeddings.bin"

MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
MODEL_DIR = Path(os.environ.get("ATLAS_EMBED_CACHE", Path.home() / ".cache" / "atlas-embed"))
HF_BASE = f"https://huggingface.co/{MODEL_ID}/resolve/main"
MODEL_FILES = {"tokenizer.json": "tokenizer.json", "onnx/model.onnx": "onnx/model.onnx"}

DIMS = 384
MAX_TOKENS = 256          # MiniLM's window.
CHUNK_STRIDE = 192        # Overlap, so a sentence split across chunks survives in one of them.

# How much a tour's single best chunk counts against its overall average. 0.6
# was chosen by comparing rankings, not by taste: at 1.0 "somewhere quiet to
# sit near the water" drifts to museums that mention water once; at 0.0 the
# Chrysler's art deco lobby vanishes under five other paragraphs.
BEST_CHUNK_WEIGHT = 0.6

# --- Binary format ----------------------------------------------------------
#
# magic "ATLSEMB2" | u32 version | u32 tours | u32 chunks | u32 dims
# | u32 flags | f32 scale | 64-byte model id, null-padded
# | tours  x 16-byte tour UUID
# | tours  x u32 first-chunk index   (a tour's chunk count = next offset - this)
# | chunks x dims x int8
#
# Fixed-width and self-describing so the Swift side can mmap it and validate
# before trusting a single number. The model id is in the header precisely
# because a mismatch is otherwise invisible — see the trap noted above.

MAGIC = b"ATLSEMB2"
FORMAT_VERSION = 2
FLAG_INT8 = 1
HEADER_STRUCT = "<8sIIIIIf64s"
HEADER_SIZE = struct.calcsize(HEADER_STRUCT)
QUANT_SCALE = 127.0


def header_bytes(tours: int, chunks: int, dims: int, scale: float = QUANT_SCALE) -> bytes:
    return struct.pack(
        HEADER_STRUCT,
        MAGIC,
        FORMAT_VERSION,
        tours,
        chunks,
        dims,
        FLAG_INT8,
        scale,
        MODEL_ID.encode("utf-8")[:64].ljust(64, b"\0"),
    )


def parse_header(raw: bytes):
    """Read a header back. Returns a dict, or raises ValueError saying why not."""
    if len(raw) < HEADER_SIZE:
        raise ValueError("file is shorter than its own header")
    magic, version, tours, chunks, dims, flags, scale, model = struct.unpack(
        HEADER_STRUCT, raw[:HEADER_SIZE]
    )
    if magic != MAGIC:
        raise ValueError(f"not an Atlas embeddings file (magic was {magic!r})")
    if version != FORMAT_VERSION:
        raise ValueError(f"format version {version}, expected {FORMAT_VERSION}")
    return {
        "version": version,
        "tours": tours,
        "chunks": chunks,
        "dims": dims,
        "flags": flags,
        "scale": scale,
        "model": model.rstrip(b"\0").decode("utf-8"),
        "header_size": HEADER_SIZE,
    }


# --- Text assembly ----------------------------------------------------------


def tour_text(tour: dict) -> str:
    """
    Everything about one tour, worth embedding, in one blob.

    Order matters a little: title and place first, so that even a chunk cut
    short still carries what the tour IS. Transcripts last and in stop order —
    they are the bulk and the reason this exists.
    """
    parts: list[str] = []
    if title := tour.get("title"):
        parts.append(title)

    place = " ".join(p for p in (tour.get("city"), tour.get("country")) if p)
    if place:
        parts.append(place)

    if tags := tour.get("tags"):
        parts.append(", ".join(tags))

    for key in ("shortDescription", "longDescription"):
        if value := tour.get(key):
            parts.append(value)

    for stop in sorted(tour.get("stops", []), key=lambda s: s.get("order", 0)):
        for key in ("title", "caption", "transcriptText"):
            if value := stop.get(key):
                parts.append(value)

    return "\n".join(parts)


def chunk_ids(ids: list[int], max_tokens: int = MAX_TOKENS, stride: int = CHUNK_STRIDE) -> list[list[int]]:
    """
    Split a token sequence into overlapping windows.

    Reserves two slots per window for the [CLS]/[SEP] the caller re-adds, so a
    window can never overflow the model once wrapped.
    """
    body = max_tokens - 2
    if body <= 0:
        raise ValueError("max_tokens must leave room for [CLS] and [SEP]")
    if not ids:
        return [[]]
    if len(ids) <= body:
        return [ids]

    step = min(stride, body)
    windows = [ids[i:i + body] for i in range(0, len(ids), step)]
    # The final window can be a stub that duplicates its predecessor's tail;
    # it adds noise to the mean and no information.
    if len(windows) > 1 and len(windows[-1]) < body // 4:
        windows.pop()
    return windows


# --- Model ------------------------------------------------------------------


def ensure_model() -> Path:
    """Download the model on first use. Returns the cache directory."""
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    for remote, local in MODEL_FILES.items():
        path = MODEL_DIR / local
        if path.exists() and path.stat().st_size > 0:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        url = f"{HF_BASE}/{remote}"
        print(f"  fetching {remote} …", flush=True)
        try:
            urllib.request.urlretrieve(url, path)
        except Exception as exc:  # noqa: BLE001 - reported, not swallowed
            raise SystemExit(f"ERROR: could not fetch {url}: {exc}")
    return MODEL_DIR


class Embedder:
    """
    all-MiniLM-L6-v2 over ONNX Runtime.

    Deliberately not sentence-transformers: that pulls PyTorch (~800 MB) for a
    23 MB model, which is a poor trade in CI. Tokenizer + ONNX is the same
    numbers in a fraction of the footprint.
    """

    def __init__(self) -> None:
        try:
            import numpy as np
            import onnxruntime as ort
            from tokenizers import Tokenizer
        except ImportError as exc:
            raise SystemExit(
                f"ERROR: missing dependency ({exc.name}). "
                "Install with: pip3 install -r scripts/requirements-embeddings.txt"
            )

        self.np = np
        directory = ensure_model()
        self.tokenizer = Tokenizer.from_file(str(directory / "tokenizer.json"))
        # 🔴 THE TOKENIZER PADS AND TRUNCATES BY DEFAULT, AND BOTH ARE WRONG HERE.
        # The published tokenizer.json carries a fixed-length padding/truncation
        # policy meant for one-shot sentence encoding. Left on, it silently threw
        # away everything past the first ~128 tokens of a tour — the whole
        # transcript, which is the entire point of this file — and then handed
        # back [PAD] zeros that this code counted as real words. It does not
        # error; it just returns vectors so alike that two tours topped every
        # query. Chunking and padding are handled below, deliberately, so the
        # tokenizer must do neither.
        self.tokenizer.no_padding()
        self.tokenizer.no_truncation()
        options = ort.SessionOptions()
        options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        self.session = ort.InferenceSession(
            str(directory / "onnx" / "model.onnx"),
            options,
            providers=["CPUExecutionProvider"],
        )
        self.input_names = {i.name for i in self.session.get_inputs()}

        vocab = self.tokenizer.get_vocab()
        self.cls_id = vocab.get("[CLS]", 101)
        self.sep_id = vocab.get("[SEP]", 102)
        self.pad_id = vocab.get("[PAD]", 0)

    def _forward(self, batch: list[list[int]]):
        """Run one padded batch and mean-pool to one vector per row."""
        np = self.np
        width = max(len(row) for row in batch)
        ids = np.full((len(batch), width), self.pad_id, dtype=np.int64)
        mask = np.zeros((len(batch), width), dtype=np.int64)
        for row, tokens in enumerate(batch):
            ids[row, : len(tokens)] = tokens
            mask[row, : len(tokens)] = 1

        feed = {"input_ids": ids, "attention_mask": mask}
        if "token_type_ids" in self.input_names:
            feed["token_type_ids"] = np.zeros_like(ids)

        hidden = self.session.run(None, feed)[0]
        # Mean over real tokens only — padding must not drag vectors toward zero.
        expanded = mask[..., None].astype(np.float32)
        pooled = (hidden * expanded).sum(axis=1) / np.clip(expanded.sum(axis=1), 1e-9, None)
        return l2_normalize(np, pooled)

    def embed_chunks(self, texts: list[str], batch_size: int = 64, progress: bool = False):
        """
        Per-chunk vectors plus the map saying which tour each chunk came from.

        Returns (vectors, owners). Chunks are NOT averaged here — see the
        pooling note in the module docstring; the caller decides, and the app
        needs both the best chunk and the mean.
        """
        np = self.np
        windows: list[list[int]] = []
        owners: list[int] = []

        for index, text in enumerate(texts):
            ids = self.tokenizer.encode(text, add_special_tokens=False).ids
            for window in chunk_ids(ids):
                windows.append([self.cls_id, *window, self.sep_id])
                owners.append(index)

        vectors = np.zeros((len(windows), DIMS), dtype=np.float32)
        for start in range(0, len(windows), batch_size):
            stop = start + batch_size
            vectors[start:stop] = self._forward(windows[start:stop])
            if progress and (start // batch_size) % 20 == 0:
                pct = 100.0 * min(stop, len(windows)) / max(len(windows), 1)
                print(f"    {min(stop, len(windows))}/{len(windows)} chunks ({pct:.0f}%)", flush=True)

        return vectors, np.asarray(owners)

    def embed_one(self, text: str):
        """One unit-length vector for a short string — the query path."""
        vectors, _ = self.embed_chunks([text])
        return vectors[0]


def tour_scores(np, chunks, owners, query_vector, count: int, best_weight: float = BEST_CHUNK_WEIGHT):
    """
    Rank tours against a query. THIS IS THE FUNCTION THE APP RE-IMPLEMENTS.

    Blends the single best-matching chunk with the tour's mean chunk, because
    the two disagree in a useful way: the best chunk finds a tour that mentions
    the thing once, the mean finds a tour that is about the thing throughout.
    Keep this in step with the Swift side or the two will quietly rank
    differently.
    """
    similarities = chunks @ query_vector
    scores = np.zeros(count, dtype=np.float32)
    for index in range(count):
        rows = similarities[owners == index]
        if len(rows):
            scores[index] = best_weight * rows.max() + (1.0 - best_weight) * rows.mean()
    return scores


def l2_normalize(np, matrix):
    """Unit-length rows, so cosine similarity is a plain dot product."""
    norms = np.linalg.norm(matrix, axis=-1, keepdims=True)
    return matrix / np.clip(norms, 1e-9, None)


# --- Catalog ----------------------------------------------------------------


def load_catalog() -> list[dict]:
    if not TOURS_JSON.exists():
        raise SystemExit(f"ERROR: {TOURS_JSON} not found")
    with TOURS_JSON.open(encoding="utf-8") as handle:
        return json.load(handle)["tours"]


def substring_search(tours: list[dict], query: str, limit: int) -> list[dict]:
    """
    Today's search, reproduced, so --compare shows what actually changes.

    Mirrors SearchView.filteredTours: title -> category -> tags -> descriptions,
    first bucket wins. Maker name is skipped (it lives on a separate object).
    """
    q = query.lower()
    buckets: list[list[dict]] = [[], [], [], []]
    for tour in tours:
        fields = (
            tour.get("title") or "",
            tour.get("primaryCategory") or "",
            " ".join(tour.get("tags") or []),
            (tour.get("shortDescription") or "") + " " + (tour.get("longDescription") or ""),
        )
        for rank, field in enumerate(fields):
            if q in field.lower():
                buckets[rank].append(tour)
                break
    return [t for bucket in buckets for t in bucket][:limit]


def write_embeddings(tours: list[dict], chunks, owners, path: Path, np) -> int:
    """
    Write the sidecar. Chunks must already be grouped by owner, ascending —
    the format stores one offset per tour and derives counts from the next.
    """
    offsets = np.searchsorted(owners, np.arange(len(tours)), side="left").astype("<u4")
    quantized = np.clip(np.rint(chunks * QUANT_SCALE), -127, 127).astype(np.int8)

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        handle.write(header_bytes(len(tours), len(chunks), DIMS))
        for tour in tours:
            handle.write(uuid.UUID(tour["id"]).bytes)
        handle.write(offsets.tobytes())
        handle.write(quantized.tobytes())
    return path.stat().st_size


def quantization_error(np, chunks, query_vectors):
    """
    How far int8 moves a similarity score. Reported, never assumed.

    The number that matters is not the average error but the worst one, and
    whether it is small next to the gap between adjacent search results.
    """
    quantized = np.clip(np.rint(chunks * QUANT_SCALE), -127, 127).astype(np.int8)
    restored = quantized.astype(np.float32) / QUANT_SCALE
    deltas = np.abs((chunks @ query_vectors.T) - (restored @ query_vectors.T))
    return float(deltas.mean()), float(deltas.max())


# --- Self-test --------------------------------------------------------------


def selftest() -> int:
    """Format and text-assembly logic, with no model and no network."""
    failures: list[str] = []

    def check(name: str, condition: bool) -> None:
        print(f"  {'ok  ' if condition else 'FAIL'}  {name}")
        if not condition:
            failures.append(name)

    print("Header round-trip")
    parsed = parse_header(header_bytes(1418, 7100, DIMS))
    check("tour count survives", parsed["tours"] == 1418)
    check("chunk count survives", parsed["chunks"] == 7100)
    check("dims survive", parsed["dims"] == DIMS)
    check("model id survives", parsed["model"] == MODEL_ID)
    check("int8 flag set", parsed["flags"] == FLAG_INT8)
    check("scale survives", parsed["scale"] == QUANT_SCALE)

    print("Header rejects bad input")
    for name, raw in (
        ("truncated file", b"ATLS"),
        ("wrong magic", b"NOTATLAS" + bytes(88)),
        ("older format version", struct.pack(HEADER_STRUCT, MAGIC, 1, 0, 0, 0, 0, 0.0, b"x" * 64)),
    ):
        try:
            parse_header(raw)
            check(name, False)
        except ValueError:
            check(name, True)

    print("Chunking")
    check("short text is one chunk", chunk_ids(list(range(50))) == [list(range(50))])
    check("long text is several", len(chunk_ids(list(range(2000)))) > 1)
    check("no chunk exceeds the window", all(len(c) <= MAX_TOKENS - 2 for c in chunk_ids(list(range(2000)))))
    check("chunks cover the whole text", max(max(c) for c in chunk_ids(list(range(2000)))) == 1999)
    check("empty text is handled", chunk_ids([]) == [[]])

    print("Text assembly")
    blob = tour_text({
        "title": "Casa Batllo",
        "city": "Barcelona",
        "country": "Spain",
        "tags": ["Architecture"],
        "shortDescription": "A short one.",
        "longDescription": "A long one.",
        "stops": [
            {"order": 1, "title": "Second", "transcriptText": "SECOND TRANSCRIPT"},
            {"order": 0, "title": "First", "transcriptText": "FIRST TRANSCRIPT"},
        ],
    })
    check("title present", "Casa Batllo" in blob)
    check("place present", "Barcelona Spain" in blob)
    check("tags present", "Architecture" in blob)
    check("every transcript present", "FIRST TRANSCRIPT" in blob and "SECOND TRANSCRIPT" in blob)
    check("stops in order", blob.index("FIRST TRANSCRIPT") < blob.index("SECOND TRANSCRIPT"))
    check("missing fields do not crash", tour_text({"title": "Bare"}) == "Bare")

    print("Scoring")
    try:
        import numpy as np
    except ImportError:
        check("numpy available (skipping scoring checks)", False)
    else:
        # Tour 0 has one chunk matching the query exactly; tour 1 has one
        # matching chunk buried among three that do not. Best-chunk alone would
        # tie them, the mean alone would sink tour 1 — the blend must place the
        # focused tour first while still ranking the other above pure noise.
        query = np.array([1.0, 0.0], dtype=np.float32)
        chunks = np.array(
            [[1.0, 0.0],
             [1.0, 0.0], [0.0, 1.0], [0.0, 1.0]],
            dtype=np.float32,
        )
        owners = np.array([0, 1, 1, 1])
        scores = tour_scores(np, chunks, owners, query, 2)
        check("focused tour outranks diluted one", scores[0] > scores[1])
        check("diluted tour still scores above zero", scores[1] > 0.0)

        offsets = np.searchsorted(owners, np.arange(2), side="left")
        check("chunk offsets point at the right owner", list(offsets) == [0, 1])

        quantized = np.clip(np.rint(chunks * QUANT_SCALE), -127, 127).astype(np.int8)
        check("int8 round-trip stays close", float(np.abs(quantized / QUANT_SCALE - chunks).max()) < 0.01)

    print()
    if failures:
        print(f"{len(failures)} FAILED: {', '.join(failures)}")
        return 1
    print("All self-tests passed.")
    return 0


# --- Entry point ------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--write", action="store_true", help=f"write {OUTPUT.relative_to(REPO_ROOT)}")
    parser.add_argument("--query", action="append", metavar="TEXT", help="rank the catalog against TEXT (repeatable)")
    parser.add_argument("--compare", action="store_true", help="show today's substring search beside it")
    parser.add_argument("--top", type=int, default=8, help="results per query (default 8)")
    parser.add_argument("--limit", type=int, metavar="N", help="only embed the first N tours (fast iteration)")
    parser.add_argument("--verify-quantization", action="store_true",
                        help="measure how far int8 storage moves a similarity score")
    parser.add_argument("--selftest", action="store_true", help="logic only, no model, no network")
    args = parser.parse_args()

    if args.selftest:
        return selftest()

    tours = load_catalog()
    if args.limit:
        tours = tours[: args.limit]

    texts = [tour_text(t) for t in tours]
    chars = sum(len(t) for t in texts)
    print(f"{len(tours)} tours, {chars:,} characters "
          f"(avg {chars // max(len(texts), 1):,} per tour)")

    print(f"Embedding with {MODEL_ID} …")
    embedder = Embedder()
    chunks, owners = embedder.embed_chunks(texts, progress=True)
    np = embedder.np
    print(f"  {len(chunks):,} chunks x {DIMS} dims "
          f"({len(chunks) / max(len(tours), 1):.1f} per tour)")

    queries = args.query or []
    for query in queries:
        print(f"\n=== {query!r}")
        scores = tour_scores(np, chunks, owners, embedder.embed_one(query), len(tours))
        print(f"  semantic (blend {BEST_CHUNK_WEIGHT:.1f} best-chunk / "
              f"{1 - BEST_CHUNK_WEIGHT:.1f} mean):")
        for rank, index in enumerate(scores.argsort()[::-1][: args.top], 1):
            tour = tours[index]
            print(f"    {rank}. {scores[index]:.3f}  {tour['title']}  — {tour.get('city', '?')}")

        if args.compare:
            hits = substring_search(tours, query, args.top)
            print("  substring (today's search):")
            if not hits:
                print("    (nothing)")
            for rank, tour in enumerate(hits, 1):
                print(f"    {rank}. {tour['title']}  — {tour.get('city', '?')}")

    if args.verify_quantization:
        probes = queries or ["art deco lobby", "brutalist concrete", "quiet water", "market food"]
        vectors = np.stack([embedder.embed_one(q) for q in probes])
        mean_error, max_error = quantization_error(np, chunks, vectors)
        print(f"\nint8 quantization error over {len(probes)} queries: "
              f"mean {mean_error:.5f}, worst {max_error:.5f}")
        gap = 0.01
        print(f"  scores run ~0.2-0.6. Two tours closer together than the WORST error "
              f"({max_error:.5f}) can swap places;")
        print(f"  measured at 1,418 tours that is a handful of near-ties deep in the "
              f"list, never the top result.")
        if max_error > gap:
            print(f"  ⚠️  worst error exceeds {gap} — large enough to reorder visible "
                  f"results. Consider fp16 (flags=0).")

    print()
    if args.write:
        size = write_embeddings(tours, chunks, owners, OUTPUT, np)
        print(f"Wrote {OUTPUT.relative_to(REPO_ROOT)} — {size:,} bytes ({size / 1e6:.2f} MB)")
        parsed = parse_header(OUTPUT.read_bytes()[:HEADER_SIZE])
        print(f"Verified header: {parsed['tours']:,} tours, {parsed['chunks']:,} chunks "
              f"x {parsed['dims']} dims, model {parsed['model']}")
    else:
        size = HEADER_SIZE + len(tours) * 20 + len(chunks) * DIMS
        print(f"Dry run — would write {size:,} bytes ({size / 1e6:.2f} MB). Pass --write to do it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

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
import re
import struct
import sys
import urllib.request
import uuid
from pathlib import Path

# --- Layout -----------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
TOURS_JSON = REPO_ROOT / "TRAVEL GUIDED TOUR" / "Resources" / "Tours.json"
OUTPUT = REPO_ROOT / "build" / "embeddings.bin"
SNIPPETS_OUTPUT = REPO_ROOT / "build" / "search-snippets.bin"

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

# --- "More like this" -------------------------------------------------------
#
# How many neighbours to store per tour. The page renders about five after it
# has dropped whatever the Place and Nearby sections already showed, so this is
# deliberately larger than what appears: the overlap with Nearby is heavy in a
# dense city, and the surplus is what keeps the section from collapsing there.
RELATED_COUNT = 8

# Below this cosine, ship nothing rather than something weak. An empty section
# hides; a bad suggestion sits on screen under a heading promising it is
# similar.
#
# MEASURED at 1,582 tours, not chosen for roundness. What it cuts: Boulders
# Beach's tail ran 0.395 down to 0.321 — Battery Park, a restaurant, the
# Company's Garden, i.e. "other things in Cape Town", which is not what the
# heading claims. What it KEEPS, and why 0.50 was rejected: a thin city's best
# matches are genuinely weaker, and at 0.50 Fisherman's Wharf loses "Pier 39
# Sea Lions" (0.477) and is given a fishing village in Hong Kong (0.592)
# instead. Thematically apt, useless to someone standing on the wharf. The
# floor has to sit under the thin cities, not over them.
#
# Re-do this with --related-of when the catalog grows, rather than trusting
# that 0.45 still separates the two.
RELATED_FLOOR = 0.45

# Where the digest of the embedded text lives. It answers one question — "has
# anything the MODEL reads changed since the last rebuild?" — so CI can skip a
# 15-minute run on the many content merges that touch only coordinates, image
# URLs or other fields `tour_text` never sees.
TEXT_DIGEST = REPO_ROOT / "scripts" / "related-text.digest"

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

# --- Snippets ---------------------------------------------------------------
# magic "ATLSNIP1" | u32 version | u32 count | 64-byte model id
# | (count + 1) x u32 byte offset into the blob | utf8 blob
#
# One readable sentence per chunk, in EXACTLY the order `embed_chunks` emits
# them, so snippet[i] explains chunk[i]. That is what lets a search result say
# why it matched instead of just asserting that it did.
#
# 🔴 A SIBLING FILE, NOT A NEW VERSION OF THE SIDECAR. Bumping ATLSEMB2's
# format version would make every build already in the field reject the index
# and lose search entirely. A file older builds never request cannot hurt them.
#
# ⚠️ DELIBERATELY UNCOMPRESSED, at ~1 MB rather than ~400 KB. Compressing it
# would mean pairing Python's deflate with Foundation's, whose framing differs
# (raw DEFLATE vs zlib-wrapped), and that pairing cannot be tested from a Linux
# session — it would surface on a phone. It is a one-time download from
# gh-pages, beside a 4 MB index and a 42 MB model, and costs no Supabase
# egress. Not worth a class of failure nobody here can see.
SNIPPETS_MAGIC = b"ATLSNIP1"
SNIPPETS_VERSION = 1
SNIPPETS_HEADER_STRUCT = "<8sII64s"
SNIPPETS_HEADER_SIZE = struct.calcsize(SNIPPETS_HEADER_STRUCT)

SNIPPET_MIN_CHARS = 30
SNIPPET_MAX_CHARS = 200
# Every link pin carries this as its shortDescription — 2,979 of 2,984 of them.
# It is true and it explains nothing, so it is never the reason a result
# matched and must never be offered as one.
# ⚠️ A PREFIX MATCH, not a whole-string one. The boilerplate is its own line in
# `tour_text`, so a snippet can legitimately span it AND the caption after it —
# which slipped past a full-string check as
# "A post by @someone on TikTok. The last four working gas lamps…". Anchored at
# the start only, so such a candidate is skipped and the next boundary (the
# caption itself) is tried instead.
BOILERPLATE_SNIPPET = re.compile(r"^A post by @[\w.\-]+ on \w+\.?(?:\s|$)")
# A caption that is mostly hashtags and handles (15% of pins) is poor but still
# the creator's own words, so it is DEPRIORITISED rather than rejected: a
# mediocre snippet beats an empty row.
TAG_HEAVY_RATIO = 0.35


def metadata_prefix_length(tour: dict) -> int:
    """
    Where `tour_text` stops being metadata and starts being prose.

    Mirrors `tour_text`'s own opening order. Snippets never quote this region:
    it is title, place and tags, all of which the result row already shows, and
    none of which is a sentence — so it reads as a broken caption rather than
    an explanation.
    """
    parts: list[str] = []
    if title := tour.get("title"):
        parts.append(title)
    place = " ".join(p for p in (tour.get("city"), tour.get("country")) if p)
    if place:
        parts.append(place)
    if tags := tour.get("tags"):
        parts.append(", ".join(tags))
    return len("\n".join(parts)) + 1 if parts else 0


def chunk_snippet(text: str, lo: int, hi: int, skip_to: int = 0) -> str:
    """
    One readable sentence from `text[lo:hi]`, or "" when there is none.

    🔴 IT MUST NEVER START MID-WORD. A chunk boundary falls wherever the
    tokenizer put it, so the naive slice produces things like
    "n 1904 as the headquarters of the New York Times" — which reads as a bug,
    and no test would catch it. So a snippet may only begin where a sentence
    genuinely begins: at a boundary found INSIDE the span, or at the span's own
    start when the character before it was already one.
    """
    lo = max(lo, skip_to)
    if lo >= hi:
        return ""
    span = text[lo:hi]

    starts = [match.end() for match in re.finditer(r"[.!?][\"')]?\s+|\n", span)]
    if lo == 0 or text[lo - 1] in ".!?\n":
        starts.insert(0, 0)

    fallback = ""
    for start in starts:
        rest = span[start:].strip()
        # Captions routinely open with an emoji; drop leading non-letters so the
        # sentence starts on a word and the capitalisation check still means
        # something.
        rest = re.sub(r"^[^\w\u00C0-\u024F]+", "", rest).strip()
        if len(rest) < SNIPPET_MIN_CHARS:
            continue
        match = re.match(
            r".{%d,%d}?[.!?](?:[\"')]?)(?:\s|$)" % (SNIPPET_MIN_CHARS, SNIPPET_MAX_CHARS),
            rest, re.S,
        )
        candidate = re.sub(r"\s+", " ", (match.group(0) if match else rest[:150]).strip())
        if not candidate or candidate[0].isdigit():
            continue
        if not (candidate[0].isupper() or not candidate[0].isascii()):
            continue
        if BOILERPLATE_SNIPPET.match(candidate):
            continue
        words = candidate.split()
        tagged = sum(1 for word in words if word.startswith(("#", "@")))
        if words and tagged / len(words) > TAG_HEAVY_RATIO:
            fallback = fallback or candidate
            continue
        return candidate
    return fallback


def write_snippets(snippets: list[str], path: Path) -> int:
    blob = bytearray()
    offsets = [0]
    for snippet in snippets:
        blob += snippet.encode("utf-8")
        offsets.append(len(blob))

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        handle.write(struct.pack(
            SNIPPETS_HEADER_STRUCT, SNIPPETS_MAGIC, SNIPPETS_VERSION,
            len(snippets), MODEL_ID.encode("utf-8")[:64].ljust(64, b"\0"),
        ))
        handle.write(struct.pack(f"<{len(offsets)}I", *offsets))
        handle.write(bytes(blob))
    return path.stat().st_size


def parse_snippets_header(raw: bytes):
    if len(raw) < SNIPPETS_HEADER_SIZE:
        raise ValueError("file is shorter than its own header")
    magic, version, count, model = struct.unpack(
        SNIPPETS_HEADER_STRUCT, raw[:SNIPPETS_HEADER_SIZE]
    )
    if magic != SNIPPETS_MAGIC:
        raise ValueError(f"not an Atlas snippets file (magic was {magic!r})")
    if version != SNIPPETS_VERSION:
        raise ValueError(f"format version {version}, expected {SNIPPETS_VERSION}")
    return {
        "version": version,
        "count": count,
        "model": model.rstrip(b"\0").decode("utf-8"),
        "header_size": SNIPPETS_HEADER_SIZE,
    }



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


def text_digest(tours: list[dict]) -> str:
    """
    One sha256 over exactly what the model reads, in catalog order.

    🔴 THIS IS NOT THE VECTOR CACHE THAT WAS REJECTED, and the difference is the
    failure mode. A per-entry cache decides for each tour whether a saved answer
    is still good; one wrong decision leaves that tour's neighbours stale
    FOREVER, with no error. This digest is written ONLY by a rebuild that
    actually succeeded and committed — so a run that is skipped, fails, or loses
    its push race leaves the old value in place and the next run rebuilds.
    Its worst case is a redundant 15-minute run, never a stale list.

    The id is included so that reordering or renaming an entry counts as a
    change even when the prose is untouched, and the count is prefixed so a
    truncated catalog can never collide with a whole one.
    """
    import hashlib
    digest = hashlib.sha256()
    digest.update(f"{len(tours)}\n".encode("utf-8"))
    for tour in tours:
        digest.update(tour["id"].lower().encode("utf-8"))
        digest.update(b"\x00")
        digest.update(tour_text(tour).encode("utf-8"))
        digest.update(b"\x00")
    return digest.hexdigest()


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

    def _windows(self, texts: list[str]):
        """
        Every chunk, as (owner index, token ids, character span).

        🔴 THE ONE PLACE CHUNKING HAPPENS. `embed_chunks` and `chunk_spans` both
        consume this, so a vector and its snippet cannot drift apart: chunk N is
        chunk N because there is only one loop deciding what chunk N is. Two
        loops agreeing today is not the same promise.
        """
        for index, text in enumerate(texts):
            encoding = self.tokenizer.encode(text, add_special_tokens=False)
            offsets = encoding.offsets
            # `chunk_ids` slices by position, so windowing the POSITIONS gives
            # exactly the windows it would give the ids themselves.
            for positions in chunk_ids(list(range(len(encoding.ids)))):
                if not positions:
                    yield index, [], (0, 0)
                    continue
                window = [encoding.ids[p] for p in positions]
                yield index, window, (offsets[positions[0]][0], offsets[positions[-1]][1])

    def chunk_spans(self, texts: list[str]) -> list[tuple[int, int, int]]:
        """(owner index, start, end) per chunk, in `embed_chunks` order."""
        return [(index, span[0], span[1]) for index, _ids, span in self._windows(texts)]

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

        for index, window, _span in self._windows(texts):
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


def tour_means(np, chunks, owners, count: int):
    """
    One unit-length vector per tour: the mean of its chunks.

    `owners` is non-decreasing (embed_chunks walks tours in order), so the
    chunks of a tour are contiguous and `reduceat` sums each run in one pass.
    Looping instead is what makes the obvious implementation unusable at
    catalog scale — see the warning on `related_tours`.
    """
    if count == 0:
        return np.zeros((0, DIMS), dtype=np.float32)
    offsets = np.searchsorted(owners, np.arange(count), side="left")
    # reduceat on a zero-length run returns the row AT the offset rather than a
    # zero sum, so a tour with no chunks would silently borrow its neighbour's
    # vector. Every tour has at least one chunk (chunk_ids never returns []),
    # so this is a guard against a future change, not a live case.
    if not np.all(np.diff(offsets) > 0):
        raise ValueError("a tour has no chunks; tour_means cannot group them")
    sums = np.add.reduceat(chunks, offsets, axis=0)
    counts = np.diff(np.append(offsets, len(chunks))).astype(np.float32)
    return l2_normalize(np, sums / counts[:, None])


def related_tours(np, means, tours, count: int = RELATED_COUNT, floor: float = RELATED_FLOOR):
    """
    Nearest neighbours per entry, same city first, then cross-city to fill.

    Tours and link pins both take part, in both directions: a pin can suggest
    tours and a tour can suggest pins. The one asymmetry is the cross-city
    tail, which pins do not get — see the comment on that branch below.

    🔴 MEAN-TO-MEAN, DELIBERATELY NOT `tour_scores`' BLEND, AND THE DIFFERENCE
    IS THE POINT. `tour_scores` weights the single best-matching chunk at 0.6
    because a QUERY is a narrow thing that should find the one paragraph about
    art deco lobbies. A whole tour is not narrow. Scored best-chunk against
    best-chunk, two tours pair up because they each spend one sentence on
    brickwork, which is not what "more like this" promises. The mean asks
    whether they are ABOUT the same kind of place. If you are here to make the
    two functions agree, this is the comment that exists to stop you.

    Same city leads because it is measured: cross-city matches are thematically
    fine and geographically useless — Casa Batllo's best cross-city neighbour
    is a Madrid park, which is a correct answer to a question nobody asked.
    Cross-city still fills the tail, or a tour in a thin city gets nothing.

    ⚠️ Do NOT reach for `tour_scores` in a loop here. Its `owners == index`
    mask is a full pass over every chunk per call; at catalog scale that is
    ~10^10 operations. The mean matrix is one matmul.
    """
    n = len(tours)
    if n == 0:
        return {}

    # ⚠️ Link pins were excluded here when this shipped (#915), on the stated
    # grounds that "a pin has no transcript, so its vector is near-meaningless".
    # That was a guess and it was WRONG. Measured 2026-09-15: all 2,318 pins
    # carry title, both descriptions, tags, city, country and a stop caption —
    # median 540 characters, p10 311. Only `transcriptText` is absent, and #795
    # took that field off the wire for tours too. The matches are good where
    # Atlas has local coverage and correctly silent where it has none.
    is_pin = np.array([t.get("kind") == "link" for t in tours])

    cities = [(t.get("city") or "").strip().casefold() for t in tours]
    city_codes = {}
    coded = np.array([city_codes.setdefault(c, len(city_codes)) if c else -1 for c in cities])

    similarity = means @ means.T
    np.fill_diagonal(similarity, -1.0)          # nothing is its own neighbour

    related: dict[str, list[str]] = {}
    for index in range(n):
        row = similarity[index]
        above = row >= floor
        # A city of -1 is "unknown", which must never match another unknown.
        same_city = above & (coded == coded[index]) & (coded[index] >= 0)

        def best(mask, limit):
            picks = np.flatnonzero(mask)
            if len(picks) == 0:
                return []
            return list(picks[np.argsort(-row[picks], kind="stable")][:limit])

        chosen = best(same_city, count)
        # A PIN TAKES NO CROSS-CITY FILL, and a tour does. 978 of 2,318 pins
        # sit in a city where Atlas has no tours at all; filling their eight
        # slots from elsewhere offers someone standing in Prague a walk in
        # Vienna. A pin with no local match shows no section. Owner decision
        # 2026-09-15 — one line to reverse.
        #
        # A pin's same-city candidates DO include other pins, and that was also
        # put to the owner and taken: it is what carries pin coverage from 580
        # to 1,902, at the cost of 1,322 of those seeing only other creators'
        # posts and no Atlas audio. Measured on the live payload at gzip level 1
        # (which is what PostgREST uses): 2,885,384 bytes today, 2,932,051 if a
        # pin could only name a tour, 3,176,601 as chosen — +291 KB. 🔴 That is
        # real money on an account that has had two egress overage notices;
        # re-measure rather than quoting these, and see § Egress in CLAUDE.md.
        if len(chosen) < count and not is_pin[index]:
            chosen += best(above & ~same_city, count - len(chosen))

        if chosen:
            related[tours[index]["id"]] = [tours[j]["id"] for j in chosen]
    return related


def apply_related(related: dict, path=TOURS_JSON) -> tuple[int, int]:
    """
    Patch `relatedTourIds` into Tours.json in place, idempotently.

    The key is inserted immediately after `country` rather than appended, so
    the diff is one added line per tour instead of a reshuffle, and so the file
    matches the order the field sits in on `Tour`. Re-running over the script's
    own output is a no-op.
    """
    data = json.loads(path.read_text(encoding="utf-8"))
    changed = 0
    total = 0
    # Both arrays, because a link pin carries the key too. They are separate on
    # the wire only to keep old builds decoding — see `load_catalog`.
    for array in ("tours", "linkPins"):
        entries = data.get(array)
        if not entries:
            continue
        total += len(entries)
        for position, tour in enumerate(entries):
            ids = related.get(tour["id"])
            if tour.get("relatedTourIds") == ids or (not ids and "relatedTourIds" not in tour):
                continue
            rebuilt = {}
            for key, value in tour.items():
                if key == "relatedTourIds":
                    continue
                rebuilt[key] = value
                if key == "country" and ids:
                    rebuilt["relatedTourIds"] = ids
            if ids and "relatedTourIds" not in rebuilt:
                rebuilt["relatedTourIds"] = ids     # an entry with no `country` key
            entries[position] = rebuilt
            changed += 1

    # indent=2 + ensure_ascii=False + trailing newline reproduces the file
    # byte for byte; anything else rewrites all 14 MB as one diff.
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return changed, total


def l2_normalize(np, matrix):
    """Unit-length rows, so cosine similarity is a plain dot product."""
    norms = np.linalg.norm(matrix, axis=-1, keepdims=True)
    return matrix / np.clip(norms, 1e-9, None)


# --- Catalog ----------------------------------------------------------------


def load_catalog() -> list[dict]:
    """
    Every entry the app sees, tours and link pins in one list.

    Pins live in a sibling `linkPins` array on the wire — not because they are
    a different kind of thing, but because one unknown `kind` inside `tours`
    fails the whole catalog decode on every build shipped before
    `TourKind.link`. `ToursData` folds them back together at decode and
    everything downstream sees one list; this mirrors that.
    """
    if not TOURS_JSON.exists():
        raise SystemExit(f"ERROR: {TOURS_JSON} not found")
    with TOURS_JSON.open(encoding="utf-8") as handle:
        data = json.load(handle)
    return list(data["tours"]) + list(data.get("linkPins") or [])


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

    print("Snippets — the failures the prototype actually hit")
    header = metadata_prefix_length(
        {"title": "Grand Central", "city": "New York", "country": "United States",
         "tags": ["Notable Building", "Architecture"]}
    )
    text = ("Grand Central\nNew York United States\nNotable Building, Architecture\n"
            "Two minutes on the south facade. You will know the place by its clock.")
    check("skips the metadata header",
          chunk_snippet(text, 0, len(text), header).startswith("Two minutes"))
    # 🔴 The one that produced "n 1904 as the headquarters of the New York Times".
    mid = text.index("the south facade")
    check("never starts mid-sentence",
          chunk_snippet(text, mid, len(text), 0) != ""
          and chunk_snippet(text, mid, len(text), 0)[0].isupper())
    check("a chunk with no whole sentence yields nothing",
          chunk_snippet("no terminator here at all", 0, 25, 0) == "")
    pin = "A post by @someone on TikTok.\nThe last four working gas lamps in Hong Kong, still lit."
    check("never quotes the pin boilerplate",
          not BOILERPLATE_SNIPPET.match(chunk_snippet(pin, 0, len(pin), 0)))
    check("reaches the caption past the boilerplate",
          chunk_snippet(pin, 0, len(pin), 0).startswith("The last four"))
    emoji = "\U0001F991 The whale and squid diorama is the museum's most captivating room."
    check("drops a leading emoji rather than failing the capital check",
          chunk_snippet(emoji, 0, len(emoji), 0).startswith("The whale"))
    tagged = ("#tokyo #cafe #coffee #latte @someplace #art\n"
              "Latte Art Mania is a tiny counter in Shibuya with astonishing coffee.")
    check("prefers prose over a hashtag pile",
          chunk_snippet(tagged, 0, len(tagged), 0).startswith("Latte Art Mania is"))

    print("Snippet file round-trip")
    raw_path = REPO_ROOT / "build" / "_selftest-snippets.bin"
    write_snippets(["first one.", "", "third one."], raw_path)
    parsed_snips = parse_snippets_header(raw_path.read_bytes())
    check("count survives", parsed_snips["count"] == 3)
    check("model id survives", parsed_snips["model"] == MODEL_ID)
    check("an empty snippet is still a slot", parsed_snips["count"] == 3)
    raw_path.unlink(missing_ok=True)

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

        print("More like this")
        # Four tours on two axes. The CROSS-city match "c" deliberately scores
        # HIGHER than the same-city "b", so ranking on score alone would put it
        # first — that is what makes this a real test of the same-city rule
        # rather than one the scores happen to satisfy anyway.
        means = l2_normalize(np, np.array(
            [[1.00, 0.00],     # a, Lisbon
             [0.97, 0.20],     # b, Lisbon  — same city, LOWER score than c
             [0.99, 0.10],     # c, Porto   — cross city, HIGHER score
             [0.00, 1.00],     # d, Lisbon  — unrelated
             [0.93, 0.30]],    # e, Lisbon  — same city, weaker than b
            dtype=np.float32,
        ))
        sample = [
            {"id": "a", "city": "Lisbon", "title": "A"},
            {"id": "b", "city": "Lisbon", "title": "B"},
            {"id": "c", "city": "Porto", "title": "C"},
            {"id": "d", "city": "Lisbon", "title": "D"},
            {"id": "e", "city": "Lisbon", "title": "E"},
        ]
        related = related_tours(np, means, sample, count=3, floor=0.5)
        check("a tour is never its own neighbour",
              all(tid not in ids for tid, ids in related.items()))
        check("same city leads even when cross-city scores higher",
              related["a"] == ["b", "e", "c"])
        check("cross-city really was the stronger match",
              float(means[0] @ means[2]) > float(means[0] @ means[1]))
        check("the unrelated tour is below the floor", "d" not in related.get("a", []))
        check("an isolated tour gets nothing", "d" not in related)

        # The list is descending WITHIN each group, not globally — a weaker
        # same-city match outranking a stronger cross-city one is the rule
        # working, not a sort bug.
        by_id = {s["id"]: i for i, s in enumerate(sample)}
        same = [float(means[0] @ means[by_id[i]]) for i in related["a"]
                if sample[by_id[i]]["city"] == "Lisbon"]
        check("same-city neighbours are sorted descending", same == sorted(same, reverse=True))
        check("a cross-city match trails a weaker same-city one",
              float(means[0] @ means[by_id["c"]]) > min(same))

        # Pins take part in both directions (#915 excluded them on a wrong guess
        # about transcripts; see the comment in `related_tours`). The fixture is
        # built so the CROSS-CITY tour "c" scores HIGHER against the pin than the
        # same-city "a" does — otherwise "no cross-city fill" would pass for the
        # wrong reason, ranking having satisfied it anyway.
        pinned = sample[:3] + [{"id": "pin", "city": "Lisbon", "title": "P", "kind": "link"}]
        pin_means = l2_normalize(np, np.array(
            [[0.97, 0.20],     # a, Lisbon — same city as the pin, WEAKER
             [0.00, 1.00],     # b, Lisbon — unrelated, below the floor
             [1.00, 0.00],     # c, Porto  — cross city, STRONGER
             [0.99, 0.10]],    # pin, Lisbon
            dtype=np.float32))
        pin_related = related_tours(np, pin_means, pinned, count=3, floor=0.5)
        check("a link pin can be suggested under a tour",
              any("pin" in ids for ids in pin_related.values()))
        check("a link pin gets neighbours of its own", "pin" in pin_related)
        check("a pin takes no cross-city fill", pin_related["pin"] == ["a"])
        check("the cross-city tour really was the pin's stronger match",
              float(pin_means[3] @ pin_means[2]) > float(pin_means[3] @ pin_means[0]))
        check("a tour still takes cross-city fill", "c" in pin_related["a"])

        # The digest exists to let CI skip a rebuild, so the test that matters is
        # the NEGATIVE one: a coordinate edit must NOT change it. Most content
        # merges are coordinate fixes (#930 moved 34 entries and touched no
        # embedded text at all), and if the digest moved for those it would buy
        # nothing.
        base_entry = {"id": "a", "title": "A", "city": "Lisbon", "country": "Portugal",
                      "tags": ["x"], "shortDescription": "S", "longDescription": "L",
                      "centroidLatitude": 1.0, "centroidLongitude": 2.0,
                      "stops": [{"order": 0, "title": "T", "caption": "C",
                                 "latitude": 1.0, "longitude": 2.0}]}
        def with_change(**kw):
            import copy
            entry = copy.deepcopy(base_entry)
            entry.update(kw)
            return [entry]
        original = text_digest([base_entry])
        check("the digest is stable across calls", text_digest([base_entry]) == original)
        check("a coordinate edit does NOT move the digest",
              text_digest(with_change(centroidLatitude=9.9)) == original)
        moved = copy_stop = json.loads(json.dumps(base_entry))
        moved["stops"][0]["latitude"] = 9.9
        check("a STOP coordinate edit does NOT move the digest",
              text_digest([moved]) == original)
        check("an image edit does NOT move the digest",
              text_digest(with_change(heroImageURL="https://example.com/x.webp")) == original)
        check("a title edit DOES move the digest",
              text_digest(with_change(title="B")) != original)
        check("a description edit DOES move the digest",
              text_digest(with_change(longDescription="different")) != original)
        check("an id change DOES move the digest",
              text_digest(with_change(id="b")) != original)
        check("the digest is case-insensitive on ids",
              text_digest(with_change(id="A")) == original)
        check("an added entry moves the digest",
              text_digest([base_entry, base_entry]) != original)

        # A pin in a city with no tours at all gets nothing rather than filler.
        stranded = sample[:2] + [{"id": "far", "city": "Prague", "title": "F", "kind": "link"}]
        far_means = l2_normalize(np, np.array(
            [[1.0, 0.0], [0.99, 0.10], [1.0, 0.0]], dtype=np.float32))
        check("a pin with no local match gets no section",
              "far" not in related_tours(np, far_means, stranded, count=3, floor=0.5))

        # Tour 0 owns two chunks, tour 1 owns one. The mean must group by owner.
        grouped = tour_means(
            np,
            np.array([[1.0, 0.0], [0.0, 1.0], [1.0, 0.0]], dtype=np.float32),
            np.array([0, 0, 1]),
            2,
        )
        check("means group by owner", abs(float(grouped[0] @ grouped[1]) - 0.7071) < 0.01)
        check("means are unit length",
              float(np.abs(np.linalg.norm(grouped, axis=1) - 1.0).max()) < 1e-5)

        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            fixture = Path(tmp) / "Tours.json"
            payload = {
                "tours": [
                    {"id": "a", "title": "A", "country": "Portugal", "stops": []},
                    {"id": "b", "title": "B", "stops": []},
                ],
                "linkPins": [
                    {"id": "p", "title": "P", "country": "Portugal",
                     "kind": "link", "stops": []},
                ],
            }
            fixture.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
            patch = {"a": ["b"], "p": ["a"]}
            first, _ = apply_related(patch, fixture)
            again, _ = apply_related(patch, fixture)
            reloaded = json.loads(fixture.read_text())
            written = reloaded["tours"]
            check("patch writes a pin's ids too",
                  reloaded["linkPins"][0].get("relatedTourIds") == ["a"])
            check("patch writes the ids", written[0].get("relatedTourIds") == ["b"])
            check("patch sits after country",
                  list(written[0]).index("relatedTourIds") == list(written[0]).index("country") + 1)
            check("a tour with no neighbours gets no key", "relatedTourIds" not in written[1])
            check("patching is idempotent", first == 2 and again == 0)

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
    parser.add_argument("--related", action="store_true",
                        help="compute \"more like this\" neighbours and report coverage")
    parser.add_argument("--write-related", action="store_true",
                        help="patch relatedTourIds into Tours.json (implies --related)")
    parser.add_argument("--related-of", action="append", metavar="TEXT",
                        help="print the neighbours of every tour whose title contains TEXT (repeatable)")
    parser.add_argument("--related-floor", type=float, default=RELATED_FLOOR, metavar="F",
                        help=f"drop neighbours scoring below F (default {RELATED_FLOOR})")
    parser.add_argument("--text-digest", action="store_true",
                        help="print the sha256 of the embedded text and exit (no model, no network)")
    parser.add_argument("--selftest", action="store_true", help="logic only, no model, no network")
    args = parser.parse_args()

    if args.selftest:
        return selftest()

    # Before anything expensive: this needs no model and no network, so CI can
    # ask "is a rebuild owed?" in under a second.
    if args.text_digest:
        print(text_digest(load_catalog()))
        return 0

    want_related = args.related or args.write_related or args.related_of
    if args.limit and (args.write or args.write_related):
        raise SystemExit("ERROR: --limit with --write/--write-related would ship a partial catalog")

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

    if want_related:
        means = tour_means(np, chunks, owners, len(tours))
        related = related_tours(np, means, tours, floor=args.related_floor)

        by_id = {t["id"]: t for t in tours}
        pins = [t for t in tours if t.get("kind") == "link"]
        pins_with = sum(1 for t in pins if related.get(t["id"]))
        full = sum(1 for ids in related.values() if len(ids) >= RELATED_COUNT)
        cross = sum(
            1 for tid, ids in related.items()
            for other in ids
            if (by_id[other].get("city") or "") != (by_id[tid].get("city") or "")
        )
        total = sum(len(ids) for ids in related.values())
        print(f"\n=== more like this (floor {args.related_floor:.2f}, "
              f"up to {RELATED_COUNT} each)")
        print(f"  {len(related):,} of {len(tours):,} entries have at least one neighbour "
              f"({100.0 * len(related) / max(len(tours), 1):.0f}%)")
        print(f"  {full:,} have a full {RELATED_COUNT}; "
              f"{len(tours) - len(related):,} have none and will hide the section")
        print(f"  {total:,} links, {cross:,} of them cross-city "
              f"({100.0 * cross / max(total, 1):.0f}%)")
        # Pins are reported separately because they take no cross-city fill, so
        # a low share here is city coverage, not a bad floor.
        print(f"  pins: {pins_with:,} of {len(pins):,} have a neighbour "
              f"({100.0 * pins_with / max(len(pins), 1):.0f}%) — same-city only")

        for needle in (args.related_of or []):
            for tour in tours:
                if needle.casefold() not in (tour.get("title") or "").casefold():
                    continue
                print(f"\n  {tour['title']} — {tour.get('city', '?')}")
                ids = related.get(tour["id"], [])
                if not ids:
                    print("    (nothing above the floor)")
                for rank, other in enumerate(ids, 1):
                    o = by_id[other]
                    score = float(means[tours.index(tour)] @ means[tours.index(o)])
                    mark = " " if o.get("city") == tour.get("city") else "*"
                    print(f"    {rank}.{mark} {score:.3f}  {o['title']} — {o.get('city', '?')}")

        if args.write_related:
            changed, seen = apply_related(related)
            print(f"\n  Patched {TOURS_JSON.name}: {changed:,} of {seen:,} tours changed")
            # Written AFTER the patch, and only here: this file is the record
            # that a rebuild actually completed. Commit it in the same commit as
            # the catalog — a digest that disagrees with the catalog beside it
            # either forces one redundant rebuild or, far worse, suppresses an
            # owed one. Re-read from disk rather than reusing `tours`, so the
            # digest describes the bytes that were written.
            TEXT_DIGEST.write_text(text_digest(load_catalog()) + "\n", encoding="utf-8")
            print(f"  Wrote {TEXT_DIGEST.relative_to(REPO_ROOT)}")
        else:
            print("\n  Dry run — pass --write-related to patch Tours.json.")

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

        # Snippets are written in the SAME invocation as the vectors, never on
        # their own. They are only meaningful paired with that exact index, and
        # the app refuses a pair whose chunk counts disagree — so producing one
        # without the other just yields a file nothing will load.
        spans = embedder.chunk_spans(texts)
        if len(spans) != len(chunks):
            raise SystemExit(
                f"ERROR: {len(spans)} spans for {len(chunks)} chunks — the "
                "snippet and vector paths have diverged, which would attach "
                "confident, wrong sentences to every result"
            )
        prefixes = [metadata_prefix_length(tour) for tour in tours]
        snippets = [
            chunk_snippet(texts[owner], start, end, prefixes[owner])
            for owner, start, end in spans
        ]
        snippet_size = write_snippets(snippets, SNIPPETS_OUTPUT)
        empty = sum(1 for snippet in snippets if not snippet)
        print(f"Wrote {SNIPPETS_OUTPUT.relative_to(REPO_ROOT)} — {snippet_size:,} bytes "
              f"({snippet_size / 1e6:.2f} MB)")
        print(f"  {len(snippets):,} snippets, {empty:,} empty "
              f"({100.0 * empty / max(len(snippets), 1):.1f}%)")
    else:
        size = HEADER_SIZE + len(tours) * 20 + len(chunks) * DIMS
        print(f"Dry run — would write {size:,} bytes ({size / 1e6:.2f} MB). Pass --write to do it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
A line-by-line Python port of `WordPieceTokenizer.swift`, checked against the
same fixture the Swift test uses.

    python3 scripts/tokenizer-mirror.py

⚠️ THIS IS A STAND-IN, NOT THE AUTHORITY. `TokenizerParityTests` is what decides,
because it runs the actual Swift. This exists because a Linux web session has no
Swift toolchain and would otherwise be editing a tokenizer blind, discovering
mistakes only after an 18-minute CI cycle.

🔴 IT CANNOT CATCH EVERYTHING, AND THE GAP IS SPECIFIC. Python strings iterate
code points; Swift's `String` iterates GRAPHEME CLUSTERS. A Swift WordPiece that
walks `Character` instead of `Unicode.Scalar` passes every case this script can
express and still disagrees on clustered emoji — a flag, a skin tone, a ZWJ
family. That bug was written and caught by inspection, not by this mirror. The
fixture now carries three such cases so the SWIFT test can catch it; this file
structurally cannot.

So: use this to iterate, never to conclude. A clean run here means "worth
pushing", never "verified".
"""
import json, sys, unicodedata

MAXCHARS = 100

def is_whitespace(ch):
    if ch in (" ", "\t", "\n", "\r"): return True
    return unicodedata.category(ch) == "Zs"

def is_control(ch):
    if ch in ("\t", "\n", "\r"): return False
    return unicodedata.category(ch) in ("Cc", "Cf", "Cs", "Co", "Cn")

def is_punct(ch):
    cp = ord(ch)
    if (33 <= cp <= 47) or (58 <= cp <= 64) or (91 <= cp <= 96) or (123 <= cp <= 126):
        return True
    return unicodedata.category(ch).startswith("P")

CJK = [(0x4E00,0x9FFF),(0x3400,0x4DBF),(0x20000,0x2A6DF),(0x2A700,0x2B73F),
       (0x2B740,0x2B81F),(0x2B820,0x2CEAF),(0xF900,0xFAFF),(0x2F800,0x2FA1F)]
def is_cjk(ch):
    cp = ord(ch)
    return any(lo <= cp <= hi for lo, hi in CJK)

def normalize(text):
    out = []
    for ch in text:                                   # 1. clean_text
        if ord(ch) == 0 or ord(ch) == 0xFFFD: continue
        if is_whitespace(ch): out.append(" ")
        elif is_control(ch): continue
        else: out.append(ch)
    padded = []
    for ch in out:                                    # 2. handle_chinese_chars
        if is_cjk(ch): padded += [" ", ch, " "]
        else: padded.append(ch)
    decomposed = unicodedata.normalize("NFD", "".join(padded))   # 3. strip_accents
    stripped = "".join(c for c in decomposed if unicodedata.category(c) != "Mn")
    return stripped.lower()                           # 4. lowercase

def pre_tokenize(s):
    words, cur = [], []
    for ch in s:
        if is_whitespace(ch):
            if cur: words.append("".join(cur)); cur = []
        elif is_punct(ch):
            if cur: words.append("".join(cur)); cur = []
            words.append(ch)
        else:
            cur.append(ch)
    if cur: words.append("".join(cur))
    return words

def encode(text, vocab, unk):
    ids = []
    for word in pre_tokenize(normalize(text)):
        chars = list(word)
        if not chars: continue
        if len(chars) > MAXCHARS:
            ids.append(unk); continue
        pieces, start, failed = [], 0, False
        while start < len(chars):
            end, matched = len(chars), None
            while start < end:
                cand = "".join(chars[start:end])
                if start > 0: cand = "##" + cand
                if cand in vocab:
                    matched = vocab[cand]; break
                end -= 1
            if matched is None:
                failed = True; break
            pieces.append(matched); start = end
        ids.append(unk) if failed else ids.extend(pieces)
    return ids

fix = json.load(open("TRAVEL GUIDED TOURTests/Fixtures/tokenizer-parity.json"))
tok = json.load(open("/root/.cache/atlas-embed/tokenizer.json"))
vocab = tok["model"]["vocab"]
unk = fix["specialTokens"]["[UNK]"]

bad = 0
for c in fix["cases"]:
    got = encode(c["text"], vocab, unk)
    if got != c["ids"]:
        bad += 1
        if bad <= 6:
            print(f"MISMATCH {c['text'][:44]!r}")
            print(f"  expected {c['ids'][:14]}")
            print(f"  got      {got[:14]}")
            inv = {v:k for k,v in vocab.items()}
            print(f"  exp toks {[inv.get(i,'?') for i in c['ids'][:14]]}")
            print(f"  got toks {[inv.get(i,'?') for i in got[:14]]}")
print(f"\n{len(fix['cases']) - bad}/{len(fix['cases'])} cases match")
sys.exit(1 if bad else 0)

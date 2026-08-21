#!/usr/bin/env python3
"""Make build notes safe for TestFlight's "What to Test" field.

🔴 APPLE REJECTS NON-ASCII THERE, AND THE REJECTION LANDS *AFTER* A GOOD
BUILD IS ALREADY UPLOADED. Build 1.1 (97) on 2026-08-20 archived, signed,
uploaded and finished processing, then the run went red on:

    Could not set changelog: An attribute value has invalid text.
    - Text for whatsNew contains invalid characters:'[✕]'

because one line of the notes used a ✕ to name the button it described. The
build was live and installable while the run reported failure and the notes
were missing — the worst of both. Nothing is gained by finding this out on
the far side of a seven-minute build, so the notes are transliterated here
rather than trusted.

Known typography is MAPPED, not deleted: an em dash stays a dash and a
bullet stays a bullet, because deleting them silently runs words together.
Accents fall back to their base letters. Anything still outside printable
ASCII — emoji, arrows, box drawing — is dropped.

Deliberately conservative. The exact set Apple refuses is undocumented, and
a build note is not the place to discover it.

Reads stdin, writes stdout. `--selftest` checks the mapping with no I/O.
"""
import sys
import unicodedata

SWAPS = {
    "—": "-",  "–": "-",  "−": "-",    # em dash, en dash, minus
    "·": "-",  "•": "-",                    # middle dot, bullet
    "‘": "'",  "’": "'",                    # curly single quotes
    "“": '"',  "”": '"',                    # curly double quotes
    "…": "...",                                  # ellipsis
    "✕": "x",  "✖": "x",  "×": "x",    # cross, multiplication sign
    "✓": "v",  "✔": "v",                    # check marks
    " ": " ",                                    # non-breaking space
}


def to_ascii(text: str) -> str:
    for bad, good in SWAPS.items():
        text = text.replace(bad, good)
    # Decompose accents so "é" becomes "e" + a combining mark, which the
    # printable-ASCII filter below then drops — rather than losing the letter.
    text = unicodedata.normalize("NFKD", text)
    return "".join(c for c in text if c == "\n" or 32 <= ord(c) < 127)


def selftest() -> int:
    cases = [
        ("the ✕ on a photo", "the x on a photo"),           # the character that failed build 97
        ("Step 5 · Audio", "Step 5 - Audio"),
        ("boxes — sized", "boxes - sized"),
        ("it’s fine", "it's fine"),
        ("“quoted”", '"quoted"'),
        ("wait…", "wait..."),
        ("café", "cafe"),                                    # accent falls back to its letter
        ("done ✓", "done v"),
        ("a b", "a b"),
        ("emoji \U0001F534 gone", "emoji  gone"),                 # dropped, not mapped
        ("line1\nline2", "line1\nline2"),                         # newlines survive
        ("plain ascii", "plain ascii"),
    ]
    failures = 0
    for raw, want in cases:
        got = to_ascii(raw)
        if got != want:
            failures += 1
            print(f"FAIL {raw!r}: expected {want!r}, got {got!r}")
    # The real guarantee: whatever goes in, only printable ASCII comes out.
    messy = "".join(chr(c) for c in range(0x20, 0x3000) if chr(c).isprintable())
    out = to_ascii(messy)
    if any(not (c == "\n" or 32 <= ord(c) < 127) for c in out):
        failures += 1
        print("FAIL: non-ASCII survived the sweep")
    print(f"{len(cases) - failures}/{len(cases)} cases pass" if failures else
          f"selftest OK — {len(cases)} cases, plus a 12k-codepoint sweep")
    return 1 if failures else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    sys.stdout.write(to_ascii(sys.stdin.read()))

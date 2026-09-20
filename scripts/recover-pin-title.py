#!/usr/bin/env python3
"""Recover a real venue name for a pin whose title is a caption.

WHY
---
404 entries — about a tenth of the catalogue — carry a title nothing can ever
verify: a sentence, a question, an @handle, an emoji. `check-pin-title.py`
REFUSES these at authoring time now, but the ones already shipped keep costing
us. A caption title cannot be asked of a picture (gate B becomes "is this
photograph *POV: Finding Empty Grandma Restaurant*?"), cannot be geocoded, and
cannot be matched against a gazetteer, so every other check in the repo goes
blind on them at once.

The recovery signal is the creator's own **📍 marker**: 171 of the 404 captions
name the venue in the post itself. This reads that marker, and REFUSES to
propose anything it cannot defend.

🔴 WHAT IT WILL NOT DO
----------------------
**A postal address is not a name.** `〒152-0003 東京都目黒区碑文谷１丁目１３−18`
locates a restaurant without naming it, and a title made from it would be as
unverifiable as the caption it replaced — worse, because it would LOOK
authoritative. Those are reported as ADDRESS-ONLY and left alone.

**A bare @handle is not a name either.** `@imdonut.nyc` is a username; the venue
is "I'm Donut?". A handle is reported, never proposed.

⚠️ **The caption gate has FALSE POSITIVES, and this tool must not launder them.**
"I'm Donut? NYC" is flagged only because a real venue name contains "?". Any
proposal is a QUESTION for a human, never an edit — this script has no --apply,
by design. The output is a review list.
"""
import argparse
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import runstamp  # noqa: E402

CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")

_spec = importlib.util.spec_from_file_location(
    "_gate", os.path.join(HERE, "check-pin-title.py"))
_gate = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_gate)

# A Japanese postcode, a US street number, a UK-ish postcode, a CJK address run.
ADDRESS_TELLS = (
    re.compile(r"〒\s*\d"),
    # ⚠️ Must survive an abbreviated directional and an ordinal: the first
    # version demanded [A-Z][a-z]+ for the street word and so missed
    # "154 W 45th St, New York" -- caught by the selftest, not by reading it.
    re.compile(r"\b\d{1,5}\s+(?:[NSEW]\.?\s+)?[A-Za-z0-9'.]+(?:\s+[A-Za-z0-9'.]+)?\s+"
               r"(?:St|Street|Ave|Avenue|Rd|Road|Blvd|Dr|Ln|Way)\b\.?", re.I),
    re.compile(r"\b\d{1,4}\s*(Chome|chome|丁目)"),
    re.compile(r"\b[A-Z]{1,2}\d{1,2}[A-Z]?\s*\d[A-Z]{2}\b"),
    re.compile(r"\b\d{5}(-\d{4})?\b"),
    # ⚠️ A ROMAJI Japanese address carries neither 〒 nor "Chome": it looks like
    # "8-15 Obasecho, Tennoji Ward, Osaka". Three of these were proposed as
    # venue NAMES by the first version and were caught by reading the output,
    # not by any test — which is why the output gets read.
    re.compile(r"\b\d{1,4}-\d{1,4}\s+\w+", re.U),
    re.compile(r"\b(Ward|ku|Chuo|Shi)\b,", re.I),
    # A REGION is a location, not a venue. "Tigray Region, Ethiopia" named no
    # place you could stand in front of.
    re.compile(r"\b(Region|Province|Prefecture|County|District)\b,", re.I),
)
# Words that mean "here is where", not "here is what".
LOCATION_WORDS = re.compile(r"\b(Where|Address|Location)\s*:", re.I)


def marker(text):
    """The 📍 segment of a caption, or "". Stops at a newline or a hashtag."""
    m = re.search(r"📍\s*([^\n#]{1,80})", text or "")
    return m.group(1).strip() if m else ""


def classify(segment):
    """NAME / ADDRESS / HANDLE / EMPTY for a 📍 segment.

    🔴 ADDRESS wins over NAME when both are present, deliberately. A segment
    like "Kariyushi かりゆし Japan, 〒337-0051 Saitama" does contain a name, but
    picking it out means guessing where the name stops and the address starts,
    and a wrong guess ships a title that reads authoritative and is not. Those
    go to a human with the whole segment shown.
    """
    seg = (segment or "").strip(" :·-—,")
    if not seg:
        return "EMPTY", ""
    if any(p.search(seg) for p in ADDRESS_TELLS) or LOCATION_WORDS.search(seg):
        return "ADDRESS", seg
    if seg.startswith("@") and " " not in seg:
        return "HANDLE", seg
    # Trailing sentence fragments: the marker often runs into the next clause.
    seg = re.split(r"\s+(?:I |we |you |and |it |that |this )", seg)[0].strip(" ,.")
    if not seg or len(seg) > 60:
        return "ADDRESS", (segment or "").strip()
    return "NAME", seg


def proposals(catalog):
    entries = list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])
    makers = {m["id"]: m.get("displayName", m["id"])
              for m in catalog.get("makers") or []}
    out = {"NAME": [], "ADDRESS": [], "HANDLE": [], "NONE": []}
    for e in entries:
        title = e.get("title")
        if not (_gate.looks_like_caption(title) or _gate.looks_like_description(title)):
            continue
        seg = marker(e.get("longDescription") or "")
        kind, value = classify(seg) if seg else ("NONE", "")
        if kind == "EMPTY":
            kind = "NONE"
        out[kind].append({
            "id": e.get("id"), "title": title, "proposed": value,
            "city": e.get("city"), "maker": makers.get(e.get("makerId"), "?"),
        })
    return out


def selftest():
    ran = failed = 0

    def check(label, ok):
        nonlocal ran, failed
        ran += 1
        if not ok:
            failed += 1
            print(f"  FAIL {label}")

    check("the marker is extracted",
          marker("Trying the best pizza in Miami 📍@miamislicepizza") == "@miamislicepizza")
    check("a marker stops at a hashtag",
          marker("great 📍Taste of Heaven #food") == "Taste of Heaven")
    check("a marker stops at a newline",
          marker("great 📍Taste of Heaven\nmore text") == "Taste of Heaven")
    check("no marker gives empty", marker("no pin here") == "")
    check("a missing caption does not crash", marker(None) == "")

    check("a plain venue name is a NAME",
          classify("Taste of Heaven") == ("NAME", "Taste of Heaven"))
    check("a bare handle is a HANDLE",
          classify("@miamislicepizza")[0] == "HANDLE")
    check("a handle with a name after it is not a bare handle",
          classify("@corpus Museum Hall")[0] == "NAME")

    # 🔴 The whole point: an address must never become a title.
    check("a Japanese postcode is an ADDRESS",
          classify("〒152-0003 東京都目黒区碑文谷１丁目１３−18")[0] == "ADDRESS")
    check("a US street address is an ADDRESS",
          classify("154 W 45th St, New York")[0] == "ADDRESS")
    check("a chome address is an ADDRESS",
          classify("3 Chome-8-12 Motomachi, Naniwa Ward")[0] == "ADDRESS")
    check("🔴 a NAME followed by an address is still an ADDRESS",
          classify("Kariyushi かりゆし Japan, 〒337-0051 Saitama")[0] == "ADDRESS")
    check("'Where:' marks a location, not a name",
          classify("Oeda Antique Market Where: Tokyo International")[0] == "ADDRESS")
    check("an empty segment is EMPTY", classify("")[0] == "EMPTY")
    check("a segment of only punctuation is EMPTY", classify(" : - ")[0] == "EMPTY")
    check("an over-long segment is not offered as a name",
          classify("x" * 70)[0] == "ADDRESS")
    # 🔴 Found by READING THE OUTPUT, not by a test: a romaji Japanese address
    # has no postcode and no "Chome" and was being proposed as a venue name.
    check("a romaji Japanese address is an ADDRESS",
          classify("8-15 Obasecho, Tennoji Ward, Osaka")[0] == "ADDRESS")
    check("and another shape of it",
          classify("10-10 Ikedacho, Kita Ward, Osaka")[0] == "ADDRESS")
    check("a REGION is not a venue",
          classify("Tigray Region, Ethiopia")[0] == "ADDRESS")
    check("but a hyphenated NAME is still a name",
          classify("Coca-Cola Museum")[0] == "NAME")
    # 🔴 Each address tell needs a fixture where ONLY IT can fire. The two
    # above match both the "N-N Placecho" and the "Ward," rules at once, so
    # dropping either one still read as caught — the mutation harness found
    # that immediately. A realistic string usually trips several rules, which
    # is exactly what makes it useless as a test of any one of them.
    check("the N-N street-block tell fires alone",
          classify("8-15 Obasecho, Osaka")[0] == "ADDRESS")
    check("the Ward tell fires alone",
          classify("Tennoji Ward, Osaka")[0] == "ADDRESS")

    check("a trailing clause is trimmed",
          classify("A Cap Coconut, Kowloon City I was so surprised")
          == ("NAME", "A Cap Coconut, Kowloon City"))

    cat = {"tours": [], "makers": [{"id": "m", "displayName": "M"}], "linkPins": [
        {"id": "1", "title": "Would you visit this?", "makerId": "m",
         "longDescription": "go here 📍Taste of Heaven", "city": "X"},
        {"id": "2", "title": "Centre Pompidou", "makerId": "m",
         "longDescription": "📍Somewhere Else", "city": "X"},
        {"id": "3", "title": "POV: a place?", "makerId": "m",
         "longDescription": "📍〒152-0003 東京都", "city": "X"},
    ]}
    got = proposals(cat)
    check("a caption title with a clean marker is proposed",
          len(got["NAME"]) == 1 and got["NAME"][0]["proposed"] == "Taste of Heaven")
    check("🔴 a GOOD title is never touched, even with a marker",
          all(r["title"] != "Centre Pompidou" for v in got.values() for r in v))
    check("an address-only caption is reported, not proposed",
          len(got["ADDRESS"]) == 1 and not got["NAME"][0]["proposed"].startswith("〒"))

    print(f"selftest {ran - failed}/{ran} passed")
    return 1 if failed else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--kind", choices=("NAME", "ADDRESS", "HANDLE", "NONE"),
                    help="print this group in full")
    ap.add_argument("--json", metavar="PATH")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        if not os.path.exists(a.catalog):
            print(f"COULD NOT VERIFY — missing {a.catalog}")
            return 2
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        got = proposals(catalog)
        total = sum(len(v) for v in got.values())
        print(f"{total} caption/description titles\n")
        print(f"  NAME    {len(got['NAME']):4d}  a venue name to put to a human")
        print(f"  ADDRESS {len(got['ADDRESS']):4d}  located but not named — leave alone")
        print(f"  HANDLE  {len(got['HANDLE']):4d}  a username, not a name")
        print(f"  NONE    {len(got['NONE']):4d}  no marker at all")
        if a.kind:
            print()
            for i, r in enumerate(got[a.kind], 1):
                print(f"{i:3d}. {r['title'][:58]}")
                print(f"      {r['maker']} · {r['city']}  ->  {r['proposed']}")
        if a.json:
            with open(a.json, "w", encoding="utf-8") as fh:
                json.dump(got, fh, indent=1, ensure_ascii=False)
            print(f"\nwrote {a.json}")
        # 🔴 Never an edit. A proposal is a question.
        return 1 if got["NAME"] else 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())

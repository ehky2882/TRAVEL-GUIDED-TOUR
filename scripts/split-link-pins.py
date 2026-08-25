#!/usr/bin/env python3
"""Move `kind: "link"` tours out of `tours` into the top-level `linkPins` array.

WHY THIS IS A SCRIPT AND NOT A ONE-OFF EDIT
-------------------------------------------
🔴 A link pin inside `tours` fails the WHOLE catalog decode on every build
shipped before `TourKind.link`. `ToursData` decodes `tours` as one array, the
enum is closed, and `RemoteCatalogLoader` wraps the decode in `try?` — so the
throw becomes a nil, the loader reads that as a failed fetch, keeps its last
good copy and logs nothing. No crash; the phone silently stops receiving all
new content. An unknown top-level KEY costs those builds nothing, which is why
the pins move rather than the enum widening.
See `TRAVEL GUIDED TOUR/Data/ToursData.swift` for the whole argument.

The reason it is a *script*: this repo merges city batches into `Tours.json`
constantly, and a content branch cut before the split will reintroduce pins
inside `tours` on every merge. Resolving that by hand, in a 8 MB reshuffled
JSON file, is how content gets lost. Instead:

    git checkout --theirs "TRAVEL GUIDED TOUR/Resources/Tours.json"   # take main's
    python3 scripts/split-link-pins.py                               # re-apply the split
    swift scripts/validate-tours.swift                               # prove it

Idempotent: running it on an already-split catalog is a no-op.

    python3 scripts/split-link-pins.py            # rewrite in place
    python3 scripts/split-link-pins.py --check    # exit 1 if a split is needed, write nothing
    python3 scripts/split-link-pins.py --selftest # offline, no file touched

⚠️ Writes with `indent=2, ensure_ascii=False` and a trailing newline — the
format `Tours.json` is byte-stable under. It verifies that round-trip before
writing anything, so it can never reformat the file as a side effect.
"""
import argparse
import json
import sys
from pathlib import Path

DEFAULT_INPUT = "TRAVEL GUIDED TOUR/Resources/Tours.json"


def dumps(data: dict) -> bytes:
    return json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n"


def split(data: dict) -> tuple[dict, int]:
    """Return (catalog, moved). Pure — no I/O, so --selftest can exercise it.

    Order is preserved in both arrays, and a pin already in `linkPins` is left
    alone rather than duplicated, so this is safe to run repeatedly.
    """
    tours = data.get("tours") or []
    pins = list(data.get("linkPins") or [])
    seen = {p.get("id") for p in pins}

    keep, moved = [], 0
    for t in tours:
        if t.get("kind") == "link":
            if t.get("id") not in seen:
                pins.append(t)
                seen.add(t.get("id"))
            moved += 1
        else:
            keep.append(t)

    if moved == 0 and "linkPins" not in data:
        return data, 0

    out = dict(data)
    out["tours"] = keep
    # Appended last: smallest diff, and it reads as "the section older builds
    # skip". Key order is cosmetic — JSON objects are unordered to a decoder.
    out.pop("linkPins", None)
    out["linkPins"] = pins
    return out, moved


def selftest() -> int:
    cases = []

    pin = {"id": "p1", "kind": "link"}
    tour = {"id": "t1", "kind": "single"}

    out, moved = split({"tours": [tour, pin], "makers": []})
    cases.append(("a pin in tours is moved out",
                  moved == 1 and out["tours"] == [tour] and out["linkPins"] == [pin]))

    again, moved2 = split(out)
    cases.append(("running twice changes nothing",
                  moved2 == 0 and again["tours"] == [tour] and again["linkPins"] == [pin]))

    out3, _ = split({"tours": [pin], "linkPins": [pin], "makers": []})
    cases.append(("a pin already in linkPins is not duplicated",
                  out3["linkPins"] == [pin] and out3["tours"] == []))

    a, b, c = {"id": "a", "kind": "single"}, {"id": "b", "kind": "multiStop"}, {"id": "c", "kind": "single"}
    out4, _ = split({"tours": [a, pin, b, c], "makers": []})
    cases.append(("catalog order is preserved", out4["tours"] == [a, b, c]))

    untouched = {"makers": [{"id": "m"}], "tours": [tour], "places": [{"id": "pl"}]}
    out5, moved5 = split(untouched)
    cases.append(("a catalog with no pins is returned unchanged",
                  moved5 == 0 and out5 is untouched))

    out6, _ = split({"tours": [pin], "makers": [], "places": [{"id": "pl"}]})
    cases.append(("every other top-level key survives",
                  out6.get("places") == [{"id": "pl"}] and out6.get("makers") == []))

    failed = [name for name, ok in cases if not ok]
    for name, ok in cases:
        print(f"  {'PASS' if ok else 'FAIL'}  {name}")
    print(f"\n{len(cases) - len(failed)}/{len(cases)} self-tests passed")
    return 1 if failed else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--input", default=DEFAULT_INPUT, help="path to Tours.json")
    ap.add_argument("--check", action="store_true",
                    help="report whether a split is needed; write nothing; exit 1 if it is")
    ap.add_argument("--selftest", action="store_true", help="offline self-test, touches no file")
    args = ap.parse_args()

    if args.selftest:
        return selftest()

    path = Path(args.input)
    raw = path.read_bytes()
    data = json.loads(raw)

    # 🔴 Never reformat the catalog as a side effect. If this file is not
    # already byte-stable under our dump settings, refuse rather than commit a
    # whole-file rewrite that buries the real change.
    if dumps(data) != raw:
        sys.stderr.write(
            "ERROR: Tours.json is not byte-stable under `indent=2, ensure_ascii=False` + "
            "trailing newline. Rewriting it would reformat the whole file and bury the "
            "actual diff. Refusing.\n"
        )
        return 2

    out, moved = split(data)
    pins = len(out.get("linkPins") or [])

    if moved == 0:
        print(f"Already split: {len(out.get('tours') or [])} tours / {pins} link pins. Nothing to do.")
        return 0

    if args.check:
        sys.stderr.write(
            f"{moved} link pin(s) are inside `tours`. Every build predating TourKind.link "
            f"fails the whole catalog decode on this file.\n"
            f"Fix: python3 {sys.argv[0]}\n"
        )
        return 1

    path.write_bytes(dumps(out))
    print(f"Moved {moved} link pin(s) out of `tours`.")
    print(f"  tours:    {len(out['tours'])}")
    print(f"  linkPins: {pins}")
    print("Now run: swift scripts/validate-tours.swift")
    return 0


if __name__ == "__main__":
    sys.exit(main())

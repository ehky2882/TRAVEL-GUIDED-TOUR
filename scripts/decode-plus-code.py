"""Open Location Code (Plus Code) decode + recover_nearest, written by hand.

    python3 scripts/decode-plus-code.py --selftest
    python3 scripts/decode-plus-code.py "742M+X7" --near 22.32 114.17
    python3 scripts/decode-plus-code.py "8FW4V75V+8Q"

🔴 RUN --selftest BEFORE TRUSTING A DECODE. This has been rebuilt from memory in
at least six sessions and has been WRONG on rebuild more than once — most
recently recover_nearest put seven Hong Kong codes in Thailand, because it took
the missing prefix from the total character count instead of the count before
the '+'. It is committed now so it stops being rewritten; keep the selftest
green rather than trusting the arithmetic.

pip install openlocationcode cannot build a wheel in this container, so this is
hand-rolled — and therefore self-tested against PUBLISHED anchors before use.
Every expectation below is derived from the specification's own pair table, not
from memory: the pair place values are 20**4 .. 20**0 in units of 1/8000 deg.

Two traps this suite pins, both of which have bitten before:
  * encode must FLOOR, not round — rounding tips a point sitting on a cell
    boundary into the next cell (the Eiffel centre is the worked example).
  * grid digits (an 11th character onward) are REFUSED rather than guessed;
    whether the grid's row 0 is the cell's north or south edge cannot be
    settled from any vector verifiable here.
"""
from fractions import Fraction

ALPHABET = "23456789CFGHJMPQRVWX"
UNIT  = Fraction(1, 8000)          # the finest pair resolution, in degrees
PLACE = [160000, 8000, 400, 20, 1] # 20**4 .. 20**0, in units of 1/8000 deg


def _clean(code):
    c = code.upper().replace("+", "").replace("0", "")
    assert c, "empty code"
    for ch in c:
        assert ch in ALPHABET, f"bad character {ch!r} in {code!r}"
    return c


def decode(code):
    """Return (south_lat, west_lon, lat_size, lon_size) as Fractions."""
    c = _clean(code)
    if len(c) > 10:
        raise ValueError("grid digits (>10) refused: row direction unverifiable here")
    lat = lon = 0
    for i in range(0, len(c), 2):
        lat += ALPHABET.index(c[i]) * PLACE[i // 2]
        if i + 1 < len(c):
            lon += ALPHABET.index(c[i + 1]) * PLACE[i // 2]
    size = PLACE[(len(c) - 1) // 2]
    return (lat * UNIT - 90, lon * UNIT - 180, size * UNIT, size * UNIT)


def centre(code):
    la, lo, dla, dlo = decode(code)
    return float(la + dla / 2), float(lo + dlo / 2)


def encode(lat, lon, length=10):
    """FLOOR, never round — see the module docstring."""
    assert length % 2 == 0 and 2 <= length <= 10
    la = int((Fraction(lat).limit_denominator(10**9) + 90) / UNIT)
    lo = int((Fraction(lon).limit_denominator(10**9) + 180) / UNIT)
    out = ""
    for i in range(length // 2):
        p = PLACE[i]
        out += ALPHABET[(la // p) % 20] + ALPHABET[(lo // p) % 20]
        la %= p; lo %= p
    return out[:8] + "+" + out[8:] if length > 8 else out + "0" * (8 - length) + "+"


def recover_nearest(short, ref_lat, ref_lon):
    """Recover a full code from a short one plus a nearby reference.

    A full code carries EIGHT characters before the '+'. A short code has had
    2, 4, 6 or 8 of those dropped from the FRONT, so the count missing is
    8 - (characters before the '+') — NOT 8 - (total characters), which is the
    mistake that put seven Hong Kong codes in Thailand.

    The reference supplies the missing prefix; because that prefix is itself
    ambiguous at its own resolution, the 3x3 block of neighbouring cells is
    tested and the one nearest the reference wins.
    """
    s = short.upper()
    assert "+" in s, f"short code needs a '+': {short!r}"
    head = s.split("+")[0].replace("0", "")
    missing = 8 - len(head)
    assert missing in (2, 4, 6, 8), f"unexpected short code {short!r} (head {head!r})"

    full_ref = encode(ref_lat, ref_lon, 10).replace("+", "")
    prefix = full_ref[:missing]
    cand = prefix + s.replace("+", "")
    cand = cand[:8] + "+" + cand[8:]

    # the prefix resolves only to the size of its own last pair
    block = float(PLACE[missing // 2 - 1] * UNIT)
    la, lo = centre(cand)
    best = (la, lo)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            cy, cx = la + dy * block, lo + dx * block
            if (cy - ref_lat) ** 2 + (cx - ref_lon) ** 2 < (best[0] - ref_lat) ** 2 + (best[1] - ref_lon) ** 2:
                best = (cy, cx)
    return best


def _selftest():
    def approx(a, b, eps=1e-9): return abs(a - b) < eps
    # three published anchors
    la, lo = centre("8FW4V75V+8Q"); assert approx(la, 48.8583125) and approx(lo, 2.2944375), (la, lo)
    la, lo = centre("7FG49Q00+");   assert approx(la, 20.375) and approx(lo, 2.775), (la, lo)
    sla, slo, dla, dlo = decode("7FG49Q00+")
    assert approx(float(sla), 20.35) and approx(float(sla + dla), 20.4)
    # the documented floor-not-round encode
    assert encode(20.375, 2.775, 10) == "7FG49QGG+22", encode(20.375, 2.775, 10)
    assert encode(48.8583125, 2.2944375, 10) == "8FW4V75V+8Q", encode(48.8583125, 2.2944375, 10)
    # grid digits refused rather than guessed
    try:
        decode("8FW4V75V+8QX"); raise AssertionError("grid digits were NOT refused")
    except ValueError:
        pass
    # round trips
    import random
    random.seed(7)
    for _ in range(2000):
        y = random.uniform(-89.9, 89.9); x = random.uniform(-179.9, 179.9)
        c = encode(y, x, 10)
        sla, slo, dla, dlo = decode(c)
        assert float(sla) <= y < float(sla + dla), (y, c)
        assert float(slo) <= x < float(slo + dlo), (x, c)
    # recover_nearest: derive the expectation from a real encode, never recall it
    for y, x in [(48.8583125, 2.2944375), (20.375, 2.775), (22.3193, 114.1694),
                 (-33.8568, 151.2153), (40.7484, -73.9857), (-22.9519, -43.2105)]:
        full = encode(y, x, 10)
        for drop in (2, 4, 6):
            short = full.replace("+", "")[drop:]
            short = short[:8 - drop] + "+" + short[8 - drop:]
            ry, rx = recover_nearest(short, y + 0.02, x + 0.02)
            fy, fx = centre(full)
            assert abs(ry - fy) < 1e-9 and abs(rx - fx) < 1e-9, (full, drop, short, (ry, rx), (fy, fx))
    print("SELFTEST OK: 3 published anchors + floor-encode + grid refusal + "
          "2000 round-trips + 18 short-code recoveries across 4 hemispheres")


def main(argv):
    import argparse
    ap = argparse.ArgumentParser(description="Decode an Open Location Code.")
    ap.add_argument("code", nargs="?", help="full code (8FW4V75V+8Q) or short (742M+X7)")
    ap.add_argument("--near", nargs=2, type=float, metavar=("LAT", "LON"),
                    help="reference point, required for a SHORT code")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args(argv)

    if a.selftest or not a.code:
        _selftest()
        return 0

    # the selftest is cheap and this is the whole point of the file
    _selftest()
    head = a.code.split("+")[0].replace("0", "")
    if len(head) < 8:
        if not a.near:
            ap.error("that is a SHORT code — pass --near LAT LON so it can be recovered")
        la, lo = recover_nearest(a.code, *a.near)
    else:
        la, lo = centre(a.code)
    print(f"{la:.7f}, {lo:.7f}")
    return 0


if __name__ == "__main__":
    import sys
    raise SystemExit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""Convert GCJ-02 ("Mars") coordinates to WGS-84.

🔴 WHY THIS EXISTS. China's public map services do not publish WGS-84. Amap and
every other domestic service serve **GCJ-02**, a deliberate obfuscation offset
from true WGS-84 by roughly **100–700 m**, varying with position; Baidu serves
**BD-09**, which is GCJ-02 with a further offset on top.

A coordinate pasted out of an Amap share link is therefore NOT the number to
store. It looks precise — fifteen decimal places — and is wrong by more than the
distance most of our pin corrections move a pin at all.

⚠️ THE OPPOSITE MISTAKE IS WORSE. Applying this transform to a coordinate that
is ALREADY WGS-84 corrupts a correct pin by the same 100–700 m, and nothing
downstream can tell. `out_of_china` makes the transform a no-op outside the
bounding box, which protects the rest of the catalogue — but INSIDE China
nothing can distinguish the two datums by inspection. **Convert only a number
you know came from a Chinese map service, and record that you did.**

The forward transform (WGS-84 → GCJ-02) is the published one. The inverse has no
closed form, so it is solved by iteration: guess, transform forward, correct by
the residual. That converges to well under a millimetre and is exact enough that
the round-trip selftest below holds to 1e-9 degrees.
"""
from __future__ import annotations
import math
import sys

A = 6378245.0                  # Krasovsky 1940 semi-major axis
EE = 0.00669342162296594323    # ... and its squared eccentricity


def out_of_china(lng, lat):
    """Outside this box the transform is the identity — see the module note."""
    return not (72.004 <= lng <= 137.8347 and 0.8293 <= lat <= 55.8271)


def _tf_lat(x, y):
    ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * math.sqrt(abs(x))
    ret += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    ret += (20.0 * math.sin(y * math.pi) + 40.0 * math.sin(y / 3.0 * math.pi)) * 2.0 / 3.0
    ret += (160.0 * math.sin(y / 12.0 * math.pi) + 320 * math.sin(y * math.pi / 30.0)) * 2.0 / 3.0
    return ret


def _tf_lng(x, y):
    ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(abs(x))
    ret += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    ret += (20.0 * math.sin(x * math.pi) + 40.0 * math.sin(x / 3.0 * math.pi)) * 2.0 / 3.0
    ret += (150.0 * math.sin(x / 12.0 * math.pi) + 300.0 * math.sin(x / 30.0 * math.pi)) * 2.0 / 3.0
    return ret


def wgs84_to_gcj02(lng, lat):
    if out_of_china(lng, lat):
        return lng, lat
    dlat, dlng = _tf_lat(lng - 105.0, lat - 35.0), _tf_lng(lng - 105.0, lat - 35.0)
    rad = lat / 180.0 * math.pi
    magic = 1 - EE * math.sin(rad) ** 2
    sq = math.sqrt(magic)
    dlat = (dlat * 180.0) / ((A * (1 - EE)) / (magic * sq) * math.pi)
    dlng = (dlng * 180.0) / (A / sq * math.cos(rad) * math.pi)
    return lng + dlng, lat + dlat


def gcj02_to_wgs84(lng, lat, iterations=40):
    """Inverse by iteration — no closed form exists."""
    if out_of_china(lng, lat):
        return lng, lat
    wlng, wlat = lng, lat
    for _ in range(iterations):
        mlng, mlat = wgs84_to_gcj02(wlng, wlat)
        dlng, dlat = lng - mlng, lat - mlat
        wlng, wlat = wlng + dlng, wlat + dlat
        if abs(dlng) < 1e-11 and abs(dlat) < 1e-11:
            break
    return wlng, wlat


def metres(lat1, lng1, lat2, lng2):
    return math.hypot((lat1 - lat2) * 111320.0,
                      (lng1 - lng2) * 111320.0 * math.cos(math.radians(lat1)))


def selftest():
    fails, ran = [], []

    def check(name, ok):
        ran.append(name)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    # 🔴 The round trip needs no external truth, which is the point: it pins the
    # inverse against the forward transform rather than against a number someone
    # half-remembered.
    worst = 0.0
    for lng, lat in [(116.39123, 39.90871), (114.36971, 22.66283),
                     (121.47370, 31.23037), (119.31695, 39.65615),
                     (87.61688, 43.82663), (113.32446, 23.10667)]:
        g = wgs84_to_gcj02(lng, lat)
        back = gcj02_to_wgs84(*g)
        worst = max(worst, abs(back[0] - lng), abs(back[1] - lat))
    check(f"🔴 wgs→gcj→wgs round-trips (worst {worst:.2e}°)", worst < 1e-9)

    # 🔴 The offset must be REAL and in the documented band. A transform that
    # quietly did nothing would pass a round-trip test perfectly.
    off = [metres(lat, lng, *reversed(wgs84_to_gcj02(lng, lat)))
           for lng, lat in [(116.39123, 39.90871), (114.36971, 22.66283),
                            (121.47370, 31.23037), (119.31695, 39.65615)]]
    check(f"🔴 the offset is non-zero inside China ({min(off):.0f}–{max(off):.0f} m)",
          100.0 <= min(off) and max(off) <= 800.0)

    # ⚠️ Applying this outside China would corrupt a correct pin by ~500 m.
    for name, lng, lat in [("London", -0.1276, 51.5072), ("New York", -74.0060, 40.7128),
                           ("Tokyo", 139.6917, 35.6895)]:
        check(f"outside China is the IDENTITY — {name}",
              wgs84_to_gcj02(lng, lat) == (lng, lat) and gcj02_to_wgs84(lng, lat) == (lng, lat))
    check("🔴 Tokyo is east of the box, so it must NOT be transformed",
          out_of_china(139.6917, 35.6895))
    check("Shenzhen IS inside the box", not out_of_china(114.36971, 22.66283))

    # Determinism — a converter that drifts between calls is unusable for ids.
    check("the conversion is deterministic",
          gcj02_to_wgs84(114.36971, 22.66283) == gcj02_to_wgs84(114.36971, 22.66283))

    total = len(ran)
    if fails:
        print(f"SELFTEST FAILED — {len(fails)}/{total}")
        return 1
    print(f"SELFTEST OK — {total}/{total}")
    return 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    lat, lng = float(sys.argv[1]), float(sys.argv[2])
    wl, wt = gcj02_to_wgs84(lng, lat)
    print(f"GCJ-02 {lat:.7f}, {lng:.7f}")
    print(f"WGS-84 {wt:.7f}, {wl:.7f}   (moved {metres(lat, lng, wt, wl):.0f} m)")

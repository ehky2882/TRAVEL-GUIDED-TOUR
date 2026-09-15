#!/usr/bin/env python3
"""Pull a Japanese street address out of a creator caption.

    python3 scripts/parse-caption-address.py --selftest

WHY THIS EXISTS
---------------
byFood-network captions carry the venue's address in three different shapes,
and one of them is a trap:

    '6 Chome-11-7 Jingumae, Shibuya, Tokyo 150-0001'   -> 6-11-7
    '〒151-0071 ... Yoyogi, 3 Chome-39-15 ヴィラージュ'  -> 3-39-15
    '〒104-0061 7-15-17 Ginza, Chuo, Tokyo'             -> 7-15-17

🔴 THE CHOME NUMBER SITS BEFORE THE WORD "CHOME" AND IS EASY TO DROP. A naive
`\\d+-\\d+-\\d+` match reads '6 Chome-11-7' as '11-7', which is a real-looking
but NONEXISTENT address. It does not fail — it geocodes to the district
centroid, i.e. exactly the defect this whole exercise exists to fix, wearing a
fresh coordinate. On 2026-09-15 that bug reported 20 pins as >300 m wrong,
including one at 3,913 m, when several were already correct: Park Side Donuts
went from "186 m off" to 0 m once the parser was fixed.

⚠️ A caption's postcode can also contradict its own place name. Le Souffle's
caption read 'Yoyogi, 3 Chome-39-15' under postcode 151-0071, which is 本町,
not 代々木. Geocoding the postcode would have moved that pin 1,296 m the wrong
way; the place name was the correct half, and the real address is 163 m from
where the pin already sat. ALWAYS check the geocoded ward against the
neighbourhood the pin itself names.

Downstream: feed the postcode to zipcloud for the kanji district, append the
block number, then geocode with the GSI API (NOT Nominatim, which returns a
postcode centroid for a Japanese address). See docs/lessons.md § 4.
"""

import argparse
import re, unicodedata
DASH=r'[-–—−ー‐]'
def norm(s):
    s=unicodedata.normalize('NFKC', s or '')
    return re.sub(DASH, '-', s)
def parse_addr(seg):
    """Return (postcode, 'a-b-c') from a byFood caption, or (None, None).

    Handles the three shapes seen in the wild:
      '6 Chome-11-7 Jingumae, Shibuya, Tokyo 150-0001'   -> 6-11-7
      '〒151-0071 ... Yoyogi, 3 Chome-39-15 ヴィラージュ'  -> 3-39-15
      '〒104-0061 7-15-17 Ginza, Chuo, Tokyo'             -> 7-15-17
    🔴 The chome number sits BEFORE the word Chome and is easy to drop; doing so
    builds a real-looking but nonexistent address that geocodes to the district
    centroid — i.e. exactly the defect being fixed, wearing a fresh coordinate.
    """
    s=norm(seg)
    zp=re.search(r'〒?\s*(\d{3})-(\d{4})', s)
    zipcode=zp.group(1)+zp.group(2) if zp else None
    # blank the postcode so it cannot be read as a block number
    if zp: s = s[:zp.start()] + ' '*(zp.end()-zp.start()) + s[zp.end():]
    m=re.search(r'(\d+)\s*[Cc]home\s*-\s*(\d+)\s*-\s*(\d+)', s)
    if m: return zipcode, f"{m.group(1)}-{m.group(2)}-{m.group(3)}"
    m=re.search(r'(\d+)\s*[Cc]home\s*-\s*(\d+)', s)
    if m: return zipcode, f"{m.group(1)}-{m.group(2)}"
    m=re.search(r'(?<!\d)(\d{1,2})-(\d{1,3})-(\d{1,3})(?!\d)', s)
    if m: return zipcode, f"{m.group(1)}-{m.group(2)}-{m.group(3)}"
    m=re.search(r'(?<!\d)(\d{1,2})-(\d{1,3})(?!\d)', s)
    if m: return zipcode, f"{m.group(1)}-{m.group(2)}"
    return zipcode, None
def _selftest():
    T=[("📍PARK STORE 1 Chome-7-2 Ikejiri, Setagaya City, Tokyo 154-0001","1540001","1-7-2"),
       ("Cerise 〒105-7337 1-9-1 Higashishinbashi, Minato, Tokyo","1057337","1-9-1"),
       ("📍BASO OMOTESANDO 6 Chome-11-7 Jingumae, Shibuya, Tokyo 150-0001","1500001","6-11-7"),
       ("📍Le Souffle 〒151-0071 Tokyo, Shibuya City, Yoyogi, 3 Chome−39−15 ヴィラージュ 1F","1510071","3-39-15"),
       ("Tonkatsu Marushichi 4 Chome-13-3 Ginza, Chuo City, Tokyo 104-0061","1040061","4-13-3"),
       ("〒530-0002 Osaka, Kita Ward, Sonezakishinchi, 2 Chome−2−5 第３シンコービル","5300002","2-2-5"),
       ("だいつねうどん 銀座本店 〒104-0061 7-15-17 Ginza, Chuo, Tokyo","1040061","7-15-17")]
    bad=0
    for seg,ez,eb in T:
        z,b=parse_addr(seg)
        ok = (z==ez and b==eb)
        if not ok: bad+=1
        print(f"{'ok ' if ok else 'FAIL'} {b!s:10s} (want {eb:10s})  zip {z} {seg[:50]}")
    print(f"\nselftest: {len(T)-bad}/{len(T)} passed")
    return 1 if bad else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--selftest", action="store_true", help="run the parser against real caption shapes")
    ap.add_argument("text", nargs="*", help="caption text to parse")
    a = ap.parse_args()
    if a.selftest:
        raise SystemExit(_selftest())
    if a.text:
        z, b = parse_addr(" ".join(a.text))
        print(f"postcode={z}  block={b}")
    else:
        ap.print_help()

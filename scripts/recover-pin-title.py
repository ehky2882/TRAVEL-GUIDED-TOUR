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
import unicodedata

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
    # ⚠️ A EUROPEAN address puts the NUMBER AFTER the street and uses a four-
    # digit postcode: "Getreidegasse 33, 5020 Salzburg, Austria". The US and
    # Japanese tells both missed it, and it was proposed as a venue name.
    # ⚠️ The street word may be COMPOUNDED ("Getreidegasse 33") or SEPARATE
    # ("Kärntner Strasse 12"); German does both, and the first version only
    # matched the compound form.
    re.compile(r"\b[A-Za-zÄÖÜäöüß'’-]{3,}\s?(?:strasse|straße|gasse|weg|platz|"
               r"allee|laan|straat|gata|vej|gade|via|rue|calle)\s+\d{1,4}\b", re.I),
    re.compile(r",\s*\d{4}\s+[A-Z]"),
)
# Words that mean "here is where", not "here is what".
LOCATION_WORDS = re.compile(r"\b(Where|Address|Location)\s*:", re.I)


def marker(text):
    """The 📍 segment of a caption, or "". Stops at a newline or a hashtag."""
    m = re.search(r"📍\s*([^\n#]{1,80})", text or "")
    return m.group(1).strip() if m else ""


def strip_trailing_handles(text):
    """Drop @handles hanging off the end of a name. "Louvre Museum @museelouvre"."""
    out = re.sub(r"(\s*@[\w.]+)+\s*$", "", (text or "").strip())
    return out.strip(" ,·-—")


# 🔴 Words that essentially NEVER appear inside a venue name, and that a
# creator's next sentence very often starts with. Deliberately small: a broad
# list ("and", "with", "for") would cut real names in half, and a wrong cut
# ships a truncated name that reads deliberate.
HARD_CLAUSE = (
    "if", "when", "where", "because", "swipe", "tag", "follow", "dm",
    "comment", "save", "book", "link", "check", "watch", "wait",
)
# After a LEADING handle, these mean what follows LOCATES the venue rather
# than naming it: "@berlinischegalerie in Kreuzberg".
LOCATORS = ("in", "at", "near", "by", "on", "off", "inside", "outside")


def trim_trailing_clause(text):
    """Cut a name at the first word that can only start a new sentence.

    "Mount St. Restaurant If you love art" -> "Mount St. Restaurant".
    ⚠️ Only from the SECOND word on, so a name is never emptied, and only on
    the HARD list -- "The Wizard of Park Avenue" keeps every word.
    """
    words = (text or "").split()
    for i in range(1, len(words)):
        if words[i].lower().strip(".,:;!?") in HARD_CLAUSE:
            return " ".join(words[:i]).strip(" ,·-—")
    return (text or "").strip(" ,·-—")


def strip_leading_handle(text):
    """"" if an @handle OPENS the text and what follows only LOCATES it.

    🔴 "@berlinischegalerie in Kreuzberg" names nothing -- "in Kreuzberg" is a
    location, so the entry stays a handle for a human. But "@corpus Museum
    Hall" does carry a name, and keeps it.
    """
    words = (text or "").strip().split()
    if not words or not words[0].startswith("@"):
        return (text or "").strip()
    rest = words[1:]
    if not rest or rest[0].lower() in LOCATORS:
        return ""
    return " ".join(rest).strip(" ,·-—")


def is_place_name(text, place_names):
    """Is this the name of a CITY or COUNTRY we carry, rather than a venue?

    🔴 "Vatican City", "Cordoba, Spain" and "Barcelona, Spain" were all offered
    as venues. A city locates a pin; it never names one, and a title made from
    one is exactly as unverifiable as the caption it replaced.
    """
    t = (text or "").strip().strip(".,")
    if not t:
        return False
    key = place_key(t)
    if key in place_names:
        return True
    # "Cordoba, Spain" -- every comma-separated part is itself a place.
    parts = [place_key(p) for p in t.split(",")]
    parts = [p for p in parts if p]
    return bool(parts) and all(p in place_names for p in parts)


def classify(segment):
    """NAME / ADDRESS / HANDLE / EMPTY for a 📍 segment.

    🔴 ADDRESS wins over NAME when both are present, deliberately. A segment
    like "Kariyushi かりゆし Japan, 〒337-0051 Saitama" does contain a name, but
    picking it out means guessing where the name stops and the address starts,
    and a wrong guess ships a title that reads authoritative and is not. Those
    go to a human with the whole segment shown.
    """
    seg = (segment or "").strip(" :·-—,")
    # ⚠️ No empty-check here: the one after strip_trailing_handles() below
    # covers it, and a duplicate guard is one the mutation harness can never
    # prove load-bearing -- it read as MISSED because its twin caught the
    # sabotage. One guard, tested.
    if any(p.search(seg) for p in ADDRESS_TELLS) or LOCATION_WORDS.search(seg):
        return "ADDRESS", seg
    if seg.startswith("@") and " " not in seg:
        return "HANDLE", seg
    # 🔴 Only AFTER the bare-handle check: stripping first turns
    # "@miamislicepizza" into the empty string and it is never seen as a
    # handle at all -- caught by a selftest, not by reading the code.
    # Loop to a fixed point: stripping decoration can expose a handle that was
    # hidden behind an emoji, and vice versa. Calling each once, or twice, just
    # moves the boundary -- and a duplicated call also MASKS its own guard from
    # the mutation harness.
    prev = None
    while seg != prev:
        prev = seg
        seg = trim_trailing_clause(
            strip_decoration(strip_trailing_handles(seg)))
    seg = strip_leading_handle(seg)
    if not seg:
        return "EMPTY", ""
    # Trailing sentence fragments: the marker often runs into the next clause.
    seg = re.split(r"\s+(?:I |we |you |and |it |that |this )", seg)[0].strip(" ,.")
    if not seg or len(seg) > 60:
        return "ADDRESS", (segment or "").strip()
    return "NAME", seg


def place_key(text):
    """Fold a place name for comparison: accents DECOMPOSED, not deleted.

    🔴 `[^a-z0-9 ]` alone deletes an accented letter outright, so "Córdoba"
    became "crdoba" and never matched the proposal "Cordoba". The catalogue has
    paid for this exact mistake before -- Zürich/Zurich were two cities until
    an accent-folded check merged them.
    """
    t = unicodedata.normalize("NFKD", text or "")
    t = "".join(c for c in t if not unicodedata.combining(c))
    return " ".join(re.sub(r"[^a-z0-9 ]", " ", t.lower()).split())


def strip_decoration(text):
    """Drop emoji and stray symbols a caption leaves inside a name."""
    # ⚠️ Cf catches the VARIATION SELECTOR (U+FE0F) and ZWJ that trail an
    # emoji. Without it "🎨 🖼️" reduced to a single invisible character and
    # was proposed as a venue name.
    out = "".join(c for c in (text or "")
                  if unicodedata.category(c) not in ("So", "Sk", "Cs", "Cf"))
    out = re.sub(r"\s{2,}", " ", out).strip(" ,·-—")
    # A name with no letter or digit left in it is not a name.
    return out if any(c.isalnum() for c in out) else ""


def handle_key(text):
    """Fold to just letters+digits, so a handle and a name compare directly."""
    return re.sub(r"[^a-z0-9]", "", (text or "").lower())


def name_from_caption(handle, caption, max_words=6):
    """The venue name as the CAPTION spells it, corroborated by the handle.

    🔴 A handle cannot be un-mangled by rule. "@lindustriebk" is *L'Industrie
    Pizzeria*; "@marksoffmadison" is *Marks Off Madison*. De-camel-casing and
    title-casing would produce "Lindustriebk" and "Marksoffmadison" -- names
    that look plausible, are wrong, and would read as authoritative in the app.

    So the handle is used only as CORROBORATION: scan the caption for a run of
    words whose letters, folded, equal the handle's letters. That run is the
    creator's own spelling of the venue, punctuation and all. No match, no
    proposal.
    """
    want = handle_key(handle.lstrip("@"))
    if len(want) < 4:
        return ""
    words = re.findall(r"[^\s]+", caption or "")
    for i in range(len(words)):
        acc = ""
        for j in range(i, min(i + max_words, len(words))):
            acc += handle_key(words[j])
            if not acc:
                break
            if acc == want:
                phrase = " ".join(words[i:j + 1])
                return phrase.strip(" .,:;!?-–—")
            if len(acc) > len(want):
                break
    return ""


def place_vocabulary(entries):
    """Every city and country name the catalogue carries, folded."""
    out = set()
    for e in entries:
        for field in ("city", "country"):
            v = e.get(field)
            if v:
                out.add(place_key(v))
    return out


def proposals(catalog):
    entries = list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])
    makers = {m["id"]: m.get("displayName", m["id"])
              for m in catalog.get("makers") or []}
    places = place_vocabulary(entries)
    out = {"NAME": [], "ADDRESS": [], "HANDLE": [], "NONE": []}
    for e in entries:
        title = e.get("title")
        if not (_gate.looks_like_caption(title) or _gate.looks_like_description(title)):
            continue
        caption = e.get("longDescription") or ""
        seg = marker(caption)
        kind, value = classify(seg) if seg else ("NONE", "")
        if kind == "EMPTY":
            kind = "NONE"
        if kind == "NAME" and is_place_name(value, places):
            kind = "ADDRESS"        # a city locates a pin; it never names one
        if kind == "HANDLE":
            # 🔴 Scan the caption WITHOUT its 📍 segment. The marker holds the
            # handle, and handle_key() strips the pin glyph and the @, so the
            # handle corroborated ITSELF and every one was promoted -- caught
            # by a selftest, not by reading the code.
            body = re.sub(r"📍[^\n#]{0,80}", " ", caption)
            spelled = name_from_caption(value, body)
            if spelled:
                kind, value = "NAME", spelled
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

    # --- 🔴 handle -> name, corroborated by the caption's own spelling
    check("the caption's spelling is recovered through the handle",
          name_from_caption("@marksoffmadison",
                            "This steak is a thing of beauty at Marks Off Madison tonight")
          == "Marks Off Madison")
    check("punctuation in the real name survives",
          name_from_caption("@lindustriebk", "we love L'Industrie BK so much")
          == "L'Industrie BK")
    check("🔴 a handle the caption never spells out yields NOTHING",
          name_from_caption("@someplace", "great food, loved it") == "")
    check("a too-short handle is never matched",
          name_from_caption("@ab", "a b c") == "")
    check("a partial overlap does not match",
          name_from_caption("@marksoffmadison", "Marks Off") == "")
    check("trailing punctuation is trimmed",
          name_from_caption("@wildair", "go to Wildair, seriously") == "Wildair")

    # --- 🔴 the three guards that blocked 15 owner-reviewed proposals
    check("a trailing handle is stripped from a name",
          classify("Louvre Museum @museelouvre") == ("NAME", "Louvre Museum"))
    check("several trailing handles are stripped",
          classify("Crosby Street Hotel @crosby @firmdale")[0] == "NAME"
          and "@" not in classify("Crosby Street Hotel @crosby @firmdale")[1])
    check("🔴 a BARE handle is still a handle, not an empty name",
          classify("@miamislicepizza")[0] == "HANDLE")
    check("a handle in the MIDDLE is left alone",
          "@" in classify("Dinner at @marks with friends here")[1])

    # European address: number AFTER the street, four-digit postcode.
    check("🔴 a European street address is an ADDRESS",
          classify("Getreidegasse 33, 5020 Salzburg, Austria")[0] == "ADDRESS")
    check("the street-then-number form alone is enough",
          classify("Kärntner Strasse 12")[0] == "ADDRESS")
    check("the four-digit postcode form alone is enough",
          classify("Somewhere Nice, 1010 Vienna")[0] == "ADDRESS")
    check("a street NAME with no number is still a name",
          classify("Friedrichstrasse")[0] == "NAME")

    # A city is not a venue.
    cities = {"vatican city", "cordoba", "spain", "barcelona", "paris"}
    check("🔴 an ACCENTED city matches its unaccented spelling",
          is_place_name("Cordoba, Spain", {place_key("Córdoba"), "spain"}))
    check("and the reverse direction too",
          is_place_name("Córdoba", {place_key("Cordoba")}))
    # --- 🔴 the fourth defect: a trailing clause and a leading handle
    check("a trailing IF-clause is cut at the If",
          trim_trailing_clause("Mount St. Restaurant If you love art")
          == "Mount St. Restaurant")
    check("another sentence-starter cuts too",
          trim_trailing_clause("Pave Bakery Swipe for the cookie") == "Pave Bakery")
    check("🔴 a name with no hard clause word is untouched",
          trim_trailing_clause("The Wizard of Park Avenue")
          == "The Wizard of Park Avenue")
    check("🔴 a name is never emptied by the trim",
          trim_trailing_clause("If Only") == "If Only")
    # 🔴 TWO clause words, so first-vs-last actually differ. Every fixture
    # above has only one, and a mutant scanning from the END read as caught.
    check("the cut is at the FIRST clause word, not the last",
          trim_trailing_clause("Pave Bakery Swipe for it If you dare")
          == "Pave Bakery")
    check("🔴 a LEADING handle leaves a fragment, so nothing is proposed",
          classify("@berlinischegalerie in Kreuzberg")[0] == "EMPTY")
    check("and another shape of it",
          classify("@crosbystreet_hotel in SoHo")[0] == "EMPTY")
    check("a name merely CONTAINING a handle mid-way is untouched",
          strip_leading_handle("Dinner at @marks") == "Dinner at @marks")
    check("🔴 a leading handle followed by a real NAME keeps that name",
          strip_leading_handle("@corpus Museum Hall") == "Museum Hall")

    check("punctuation is folded when comparing place names",
          is_place_name("St. Louis", {"st louis"}))
    check("emoji are stripped from a name",
          classify("Colonnes de Buren 🎨 Daniel Buren")[1]
          == "Colonnes de Buren Daniel Buren")
    check("a name of only decoration is EMPTY", classify("🎨 🖼️")[0] == "EMPTY")
    check("🔴 a bare city is not a venue", is_place_name("Vatican City", cities))
    check("a city, country pair is not a venue",
          is_place_name("Cordoba, Spain", cities))
    check("a venue that merely CONTAINS a city word still is one",
          not is_place_name("Barcelona Pavilion", cities))
    check("🔴 a venue NAMED WITH its city is still a venue",
          not is_place_name("Mies Pavilion, Barcelona", cities))
    check("a country alone is a place",
          is_place_name("Spain", cities))
    check("an unknown name is not a place", not is_place_name("Taste of Heaven", cities))
    check("an empty string is not a place", not is_place_name("", cities))

    cat = {"tours": [], "makers": [{"id": "m", "displayName": "M"}], "linkPins": [
        {"id": "1", "title": "Would you visit this?", "makerId": "m",
         "longDescription": "go here 📍Taste of Heaven", "city": "X"},
        {"id": "2", "title": "Centre Pompidou", "makerId": "m",
         "longDescription": "📍Somewhere Else", "city": "X"},
        {"id": "3", "title": "POV: a place?", "makerId": "m",
         "longDescription": "📍〒152-0003 東京都", "city": "X"},
        # 🔴 A handle the caption never spells out must STAY a handle. The
        # tempting shortcut -- fall back to the bare @handle -- would ship
        # "@someplacebk" as a venue name.
        {"id": "4", "title": "Best in town!", "makerId": "m",
         "longDescription": "so good 📍@someplacebk", "city": "X"},
        {"id": "5", "title": "Wow!!", "makerId": "m",
         "longDescription": "we loved Marks Off Madison 📍@marksoffmadison",
         "city": "X"},
        # 🔴 The marker names the CITY, not a venue. Offering it as a title
        # would be exactly as unverifiable as the caption it replaced.
        {"id": "6", "title": "So pretty!!", "makerId": "m",
         "longDescription": "wandering 📍Lisbon", "city": "Lisbon",
         "country": "Portugal"},
        {"id": "7", "title": "Amazing trip!!", "makerId": "m",
         "longDescription": "so good 📍Portugal", "city": "Lisbon",
         "country": "Portugal"},
    ]}
    got = proposals(cat)
    check("a caption title with a clean marker is proposed",
          any(r["id"] == "1" and r["proposed"] == "Taste of Heaven"
              for r in got["NAME"]))
    check("🔴 a GOOD title is never touched, even with a marker",
          all(r["title"] != "Centre Pompidou" for v in got.values() for r in v))
    check("🔴 a handle the caption never spells out stays a HANDLE",
          any(r["proposed"] == "@someplacebk" for r in got["HANDLE"]))
    check("and never leaks into the NAME band",
          all("@" not in r["proposed"] for r in got["NAME"]))
    check("a handle the caption DOES spell out becomes that name",
          any(r["proposed"] == "Marks Off Madison" for r in got["NAME"]))
    check("🔴 a marker naming the CITY is not proposed as a venue",
          all(r["proposed"] != "Lisbon" for r in got["NAME"]))
    check("🔴 nor one naming the COUNTRY",
          all(r["proposed"] != "Portugal" for r in got["NAME"]))
    check("an address-only caption is reported, not proposed",
          any(r["id"] == "3" for r in got["ADDRESS"])
          and all(not r["proposed"].startswith("〒") for r in got["NAME"]))

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

"""A Python mirror of scripts/validate-tours.swift — for Linux web sessions.

    python3 scripts/validate-tours-mirror.py        # selftest, then the catalogue

⚠️ THIS IS A STAND-IN, NOT THE AUTHORITY. `scripts/validate-tours.swift` is what
CI runs and what decides; this exists because a Linux web session has no Swift
toolchain and needs an answer before opening the PR. A clean run here means
"worth pushing", never "verified".

🔴 It has been rebuilt from memory in many sessions and has been wrong on
rebuild more than once — a bare `case manual` has an IMPLICIT raw value, so an
enum parser matching only `case x = "y"` reads an EMPTY domain and then passes
anything. It is committed now so it stops being rewritten. Keep the selftest
green rather than trusting the checks.

Two disciplines make it worth anything at all:

  1. The vocabulary is PARSED from BOTH Models/Tag.swift and the Swift
     validator, and this refuses to run if the two disagree or either parse
     comes back empty — a mirror that silently parses nothing passes anything.
  2. It is self-tested against injected faults before its verdict is believed.
"""
import json, os, re, sys, math

ROOT = "."
TAGSWIFT = f"{ROOT}/TRAVEL GUIDED TOUR/Models/Tag.swift"
VALSWIFT = f"{ROOT}/scripts/validate-tours.swift"
CATALOG  = os.environ.get("ATLAS_CATALOG") or f"{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json"


def _strip_comments(src):
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return re.sub(r"//[^\n]*", "", src)


def parse_vocab_tagswift(src):
    src = _strip_comments(src)
    out = {}
    for facet, body in re.findall(r"\(\s*\.(\w+)\s*,\s*\[(.*?)\]\s*\)", src, re.S):
        names = re.findall(r'"([^"]+)"', body)
        if names:
            out.setdefault(facet, set()).update(names)
    return out


def parse_vocab_validator(src):
    src = _strip_comments(src)
    out = {}
    for name, body in re.findall(r"let\s+(\w+)Tags\s*:\s*Set<String>\s*=\s*\[(.*?)\]", src, re.S):
        names = re.findall(r'"([^"]+)"', body)
        if names:
            out[name] = set(names)
    return out


def parse_enum(src, name):
    """Read a Swift String enum's raw values.

    ⚠️ A bare `case manual` has an IMPLICIT raw value equal to the case name —
    matching only `case x = "y"` parses nothing, and the mirror then has no
    domain to check against. Both forms are handled, and the caller asserts the
    result is non-empty.
    """
    src = _strip_comments(src)
    m = re.search(r"enum\s+" + name + r"\s*:[^{]*\{(.*?)\n\}", src, re.S)
    if not m:
        return set()
    body = m.group(1)
    out = set()
    for line in body.splitlines():
        line = line.strip()
        mm = re.match(r'case\s+(\w+)\s*=\s*"([^"]+)"', line)
        if mm:
            out.add(mm.group(2)); continue
        mm = re.match(r"case\s+([A-Za-z_]\w*)\s*$", line)
        if mm:
            out.add(mm.group(1))
    return out


def load_vocab():
    a = parse_vocab_tagswift(open(TAGSWIFT, encoding="utf-8").read())
    b = parse_vocab_validator(open(VALSWIFT, encoding="utf-8").read())
    assert a, "parsed ZERO facets out of Tag.swift — refusing to run"
    assert b, "parsed ZERO facets out of the Swift validator — refusing to run"
    fa = {t for s in a.values() for t in s}
    fb = {t for s in b.values() for t in s}
    assert fa == fb, ("the two vocabularies disagree: "
                      f"only in Tag.swift={sorted(fa-fb)[:6]} only in validator={sorted(fb-fa)[:6]}")
    assert len(fa) > 300, f"vocabulary suspiciously small ({len(fa)}) — refusing to run"
    return a, fa


def enums():
    stop = open(f"{ROOT}/TRAVEL GUIDED TOUR/Models/Stop.swift", encoding="utf-8").read()
    tour = open(f"{ROOT}/TRAVEL GUIDED TOUR/Models/Tour.swift", encoding="utf-8").read()
    cat  = open(f"{ROOT}/TRAVEL GUIDED TOUR/Models/TourCategory.swift", encoding="utf-8").read()
    d = {
        "triggerMode":     parse_enum(stop, "StopTriggerMode"),
        "kind":            parse_enum(tour, "TourKind"),
        "primaryCategory": parse_enum(cat,  "TourCategory"),
    }
    for k, v in d.items():
        assert v, f"parsed ZERO cases for {k} — refusing to run"
    return d


def check(cat, facets, vocab, dom):
    errors, warnings = [], []
    tours = cat["tours"]
    pins  = cat.get("linkPins", [])
    places = cat.get("places", [])
    allt = tours + pins
    makerids = {m["id"].lower() for m in cat["makers"]}
    # `validate-tours.swift:414` errors on a duplicate maker id; this mirror did not,
    # so two maker rows sharing an id passed here and would have failed CI.
    if len(makerids) != len(cat["makers"]):
        seen_m = set()
        for m in cat["makers"]:
            if m["id"].lower() in seen_m:
                errors.append(f"duplicate maker id {m['id']} ({m['displayName']})")
            seen_m.add(m["id"].lower())

    seen_t, seen_s = set(), set()
    for e in allt:
        t = e["title"]
        tid = e["id"].lower()
        if tid in seen_t: errors.append(f"duplicate tour id: {t}")
        seen_t.add(tid)
        if e["makerId"].lower() not in makerids: errors.append(f"{t}: unknown makerId")
        if e["kind"] not in dom["kind"]: errors.append(f"{t}: bad kind {e['kind']!r}")
        if e["primaryCategory"] not in dom["primaryCategory"]:
            errors.append(f"{t}: bad primaryCategory {e['primaryCategory']!r}")
        if e["kind"] == "link" and e in tours: errors.append(f"{t}: link pin inside tours")
        if e["kind"] != "link" and e in pins:  errors.append(f"{t}: non-link filed under linkPins")
        # `validate-tours.swift:572-576` requires stop `order` to pack 0..<count with no
        # gaps or dupes; this mirror did not check it, so a stop numbered anything but 0
        # on a single-stop entry passed here and would have failed CI.
        orders = sorted(st.get("order") for st in e["stops"])
        if orders != list(range(len(e["stops"]))):
            errors.append(f"{t}: stop order values must be 0..<{len(e['stops'])}, got {orders}")
        hero = e.get("heroImageURL")
        if hero and hero in (e.get("additionalImageURLs") or []):
            errors.append(f"{t}: hero also appears in additionalImageURLs")
        if hero and not hero.startswith("http"): errors.append(f"{t}: bad heroImageURL")
        if "//" in (hero or "").split("://", 1)[-1]: errors.append(f"{t}: double slash in hero URL")
        tags = e.get("tags") or []
        if not isinstance(tags, list): errors.append(f"{t}: tags is not a list")
        else:
            for g in tags:
                if g not in vocab: errors.append(f"{t}: unknown tag {g!r}")
            if not (set(tags) & facets.get("placeType", set())):
                warnings.append(f"{t}: no Place type tag")
            if not (set(tags) & facets.get("theme", set())):
                warnings.append(f"{t}: no Theme tag")
        # A link pin's whole reason to exist is the post it points at, and its
        # creator credit. validate-tours.swift errors on both (lines 556-562);
        # the mirror was blind to them until session 145 injected the fault.
        if e["kind"] == "link":
            if not is_url(e.get("sourceURL") or ""):
                errors.append(f"{t}: link pin with invalid sourceURL {e.get('sourceURL')!r}")
            if not (e.get("sourceAuthor") or "").strip():
                errors.append(f"{t}: link pin with no sourceAuthor — a pin must credit its creator")
        else:
            if e.get("sourceURL") is not None:
                errors.append(f"{t}: sourceURL set on a '{e['kind']}' tour — only 'link' may carry one")
            if e.get("sourceAuthor") is not None:
                errors.append(f"{t}: sourceAuthor set on a '{e['kind']}' tour — only 'link' may carry one")
        stops = e["stops"]
        if e["kind"] != "link":
            for s_ in stops:
                if not (s_.get("audioURL") or "").startswith("http"):
                    errors.append(f"{t}: stop with no audioURL")
        if e["kind"] in ("single", "link") and len(stops) != 1:
            errors.append(f"{t}: {e['kind']} with {len(stops)} stops")
        for s in stops:
            sid = s["id"].lower()
            if sid in seen_s: errors.append(f"duplicate stop id in {t}")
            seen_s.add(sid)
            if s["triggerMode"] not in dom["triggerMode"]:
                errors.append(f"{t}: bad triggerMode {s['triggerMode']!r}")
            if not (-90 <= s["latitude"] <= 90):   errors.append(f"{t}: latitude out of range")
            if not (-180 <= s["longitude"] <= 180): errors.append(f"{t}: longitude out of range")
            txt = s.get("transcriptText") or ""
            if re.search(r"\[[A-Za-z]", txt): errors.append(f"{t}: bracketed stage direction in transcript")
        # ⚠️ the field is totalDurationSeconds on the tour and
        # audioDurationSeconds on the stop — there is no `durationSeconds`.
        if e["kind"] != "link" and e.get("totalDurationSeconds", 0) <= 0:
            errors.append(f"{t}: non-positive totalDurationSeconds")
        if e["kind"] != "link":
            for s_ in e["stops"]:
                if s_.get("audioDurationSeconds", 0) <= 0:
                    errors.append(f"{t}: stop with non-positive audioDurationSeconds")

    byid = {e["id"].lower(): e for e in allt}
    claimed = {}
    for pl in places:
        if len(pl["tourIds"]) < 2: errors.append(f"place {pl['name']}: fewer than 2 members")
        if not pl.get("name"):     errors.append("place with empty name")
        for tid in pl["tourIds"]:
            k = tid.lower()
            if k not in byid: errors.append(f"place {pl['name']}: unknown tour id"); continue
            if k in claimed:  errors.append(f"place {pl['name']}: member claimed by {claimed[k]}")
            claimed[k] = pl["name"]
            s = byid[k]["stops"][0]
            if abs(s["latitude"] - pl["latitude"]) > 1e-9 or abs(s["longitude"] - pl["longitude"]) > 1e-9:
                errors.append(f"place {pl['name']}: member not on the place coordinate")
        h = pl.get("heroImageURL")
        # `validate-tours.swift` checks the place hero URL (its `isValidURL`);
        # this mirror did not, so a malformed hero passed here and failed CI.
        if h and not is_url(h):
            errors.append(f"place {pl['name']}: heroImageURL is not a valid URL")
        for u in (pl.get("additionalImageURLs") or []):
            if not is_url(u):
                errors.append(f"place {pl['name']}: gallery URL is not valid")
        if h and h in (pl.get("additionalImageURLs") or []):
            errors.append(f"place {pl['name']}: hero repeated in its own gallery")
        if not (-90 <= pl["latitude"] <= 90) or not (-180 <= pl["longitude"] <= 180):
            errors.append(f"place {pl['name']}: coordinate out of range")
    ids = [pl["id"].lower() for pl in places]
    if len(ids) != len(set(ids)): errors.append("duplicate place id")
    return errors, warnings


def is_url(u):
    """Mirrors `isValidURL` in validate-tours.swift: an absolute http(s) URL."""
    return isinstance(u, str) and u.startswith(("http://", "https://")) and " " not in u


def selftest(facets, vocab, dom):
    base = json.load(open(CATALOG, encoding="utf-8"))
    def clone(): return json.loads(json.dumps(base))
    cases = []
    def case(name, fn): cases.append((name, fn))

    case("unknown tag",            lambda c: c["linkPins"][0]["tags"].append("Not A Real Tag"))
    case("duplicate tour id",      lambda c: c["linkPins"][1].__setitem__("id", c["linkPins"][0]["id"]))
    case("duplicate stop id",      lambda c: c["linkPins"][1]["stops"][0].__setitem__("id", c["linkPins"][0]["stops"][0]["id"]))
    case("bad triggerMode",        lambda c: c["linkPins"][0]["stops"][0].__setitem__("triggerMode", "geofence"))
    case("bad kind",               lambda c: c["linkPins"][0].__setitem__("kind", "linkpin"))
    case("link pin: invalid sourceURL",
         lambda c: c["linkPins"][0].__setitem__("sourceURL", "not a url"))
    case("link pin: empty sourceAuthor",
         lambda c: c["linkPins"][0].__setitem__("sourceAuthor", ""))
    case("sourceURL on a non-link tour",
         lambda c: c["tours"][0].__setitem__("sourceURL", "https://example.com/x"))
    case("bad primaryCategory",    lambda c: c["linkPins"][0].__setitem__("primaryCategory", "snacks"))
    case("latitude out of range",  lambda c: c["linkPins"][0]["stops"][0].__setitem__("latitude", 991.0))
    case("longitude out of range", lambda c: c["linkPins"][0]["stops"][0].__setitem__("longitude", -900.0))
    case("unknown makerId",        lambda c: c["linkPins"][0].__setitem__("makerId", "00000000-0000-0000-0000-000000000000"))
    case("hero in own gallery",    lambda c: c["linkPins"][0].__setitem__("additionalImageURLs", [c["linkPins"][0]["heroImageURL"]]))
    case("double slash in hero",   lambda c: c["linkPins"][0].__setitem__("heroImageURL", "https://x/images//a.webp"))
    case("link pin inside tours",  lambda c: c["tours"].append(c["linkPins"][0]))
    case("bracketed direction",    lambda c: c["linkPins"][0]["stops"][0].__setitem__("transcriptText", "[beat] hello"))
    case("place with one member",  lambda c: c["places"][0].__setitem__("tourIds", c["places"][0]["tourIds"][:1]))
    case("place member off coord", lambda c: c["places"][0].__setitem__("latitude", c["places"][0]["latitude"] + 0.01))
    case("place unknown member",   lambda c: c["places"][0]["tourIds"].append("11111111-1111-1111-1111-111111111111"))
    case("place bad hero url",     lambda c: c["places"][0].__setitem__("heroImageURL", "not a url"))
    case("place bad gallery url",  lambda c: c["places"][0].__setitem__("additionalImageURLs", ["not a url"]))
    case("place lat out of range", lambda c: c["places"][0].__setitem__("latitude", 999.0))
    case("zero tour duration",     lambda c: c["tours"][0].__setitem__("totalDurationSeconds", 0))
    case("zero stop duration",     lambda c: c["tours"][0]["stops"][0].__setitem__("audioDurationSeconds", 0))
    case("empty stop audioURL",    lambda c: c["tours"][0]["stops"][0].__setitem__("audioURL", ""))
    # Found by session 143: both are enforced by validate-tours.swift and were NOT
    # mirrored here, so each passed locally and would have failed CI.
    case("duplicate maker id",     lambda c: c["makers"][1].__setitem__("id", c["makers"][0]["id"]))
    case("stop order != 0",        lambda c: c["linkPins"][0]["stops"][0].__setitem__("order", 1))

    passed = 0
    for name, fn in cases:
        c = clone(); fn(c)
        e, w = check(c, facets, vocab, dom)
        if e: passed += 1
        else: print(f"  MISSED: {name}")
    e, w = check(clone(), facets, vocab, dom)
    ctrl = not e
    print(f"selftest {passed}/{len(cases)} faults caught; control {'clean' if ctrl else 'DIRTY'}")
    return passed == len(cases) and ctrl


if __name__ == "__main__":
    facets, vocab = load_vocab()
    dom = enums()
    print(f"vocabulary: {len(vocab)} tags across {len(facets)} facets; "
          f"enums {[f'{k}:{len(v)}' for k,v in dom.items()]}")
    if not selftest(facets, vocab, dom):
        print("SELFTEST FAILED — verdict not trustworthy"); sys.exit(2)
    cat = json.load(open(CATALOG, encoding="utf-8"))
    e, w = check(cat, facets, vocab, dom)
    print(f"\n{len(e)} errors, {len(w)} warnings across "
          f"{len(cat['tours'])} tours + {len(cat['linkPins'])} pins + {len(cat['places'])} places")
    for x in e[:40]: print("  ERROR:", x)
    for x in w[:40]: print("  WARN :", x)
    sys.exit(1 if e else 0)

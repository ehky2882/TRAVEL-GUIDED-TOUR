#!/usr/bin/env python3
"""Does the picture show the place the title claims? Ask the pixels.

WHY THIS EXISTS — THE ONE CLASS NOTHING ELSE CAN REACH
-------------------------------------------------------
On 2026-09-18 the owner found a pin titled **"Vittoriano"**, in Rome, at the
Vittoriano's real coordinate. It was **Torre Velasca — a building in MILAN,
476 km away.**

**Every check passed.** `validate-tours` saw a well-formed entry.
`check-coordinates.py --pins` saw a point consistent with its own neighbours and
its own stated city. `spine-match.py` had nothing to say. The coordinate agreed
with the title; the title was simply wrong, and the caption —

    "Italy's Ugliest Building Became a National Monument😱"

— names no building at all.

🔴 **Every check we own verifies INTERNAL CONSISTENCY or EXTERNAL POSITION.
Not one verifies that an entry's title matches the content it links to.** A
title is an assertion, and for a large share of the catalogue nothing we store
can contradict it:

    3,083 link pins
      466 (15%) have NO venue @handle and a caption sharing no word with the
           title — so nothing in the record corroborates what they claim to be

`@pasttworld` holds 119 of those, and `@pasttworld` is the creator whose pin was
476 km out of place.

The project already solved this exact shape once, for images: *"Open every hero
and read it against its script"* — a vision check, because no metadata check
could do it. This is that, for titles.

🔴 TWO INDEPENDENT CALLS. NEVER ONE COMPOUND QUESTION.
-------------------------------------------------------
`CLAUDE.md` § Image Pipeline records what a single combined prompt does: asked
"is this the subject AND a usable photo", the model answers on subject match
only and **silently drops the second half**. That shipped a set of 19th-century
Rijksmuseum prints to the owner as photographs. Owner: *"i need actual photos not
scans of old books."*

So:

  **Gate A** — is this a picture of ONE specific, identifiable PLACE at all?
              Rejects a person, a plate of food, a title card, a map, a
              screenshot, a generic street with no identifiable structure. A
              creator's video thumbnail is very often one of these, and a frame
              that shows no place cannot testify about a title.

  **Gate B** — is that place the one the title names? Asked separately, with the
              city given and the look-alikes named, because `CLAUDE.md` records
              that naming the distractors is what caught the Column of Marcus
              Aurelius posing as Trajan's Column.

  **Gate C** — open-ended: *what* is it? ⚠️ **EVIDENCE FOR A HUMAN, NEVER THE
              VERDICT.** It is what turns "not the Vittoriano" into "it is Torre
              Velasca", which is the difference between a flag and a fix.

VERDICTS
--------
    CONTRADICTS  A=yes, B=no  -> 🔴 the finding. The frame shows a specific
                                place and it is not the one claimed.
    CONFIRMS     A=yes, B=yes
    UNUSABLE     A=no         -> the frame shows no identifiable place. NOT a
                                pass: the check simply cannot speak.
    UNCHECKED    no answer    -> a call failed. Never cached, never a pass.

⚠️ **UNUSABLE IS NOT CLEAN**, in exactly the way `spine-match.py`'s UNMATCHED is
not clean. It means unexamined.
"""

from __future__ import annotations

import argparse
import base64
import gzip
import hashlib
import importlib.util
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
CACHE = os.path.join(REPO, "checks", "pin-subject.json.gz")

MODEL = "gemini-2.5-flash-lite"
ENDPOINT = ("https://generativelanguage.googleapis.com/v1beta/models/"
            f"{MODEL}:generateContent")
SLEEP_S = 0.4
MAX_RETRY = 3
RECORD_VERSION = 2


def _load(name, alias):
    path = os.path.join(HERE, name)
    spec = importlib.util.spec_from_file_location(alias, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_cpc = _load("check-place-candidates.py", "_place_candidates")


def uncorroborated(catalog):
    """Pins whose title NOTHING we store backs up.

    No venue `@handle` anywhere in the record, and a caption that shares no
    meaningful word with the title. These are the entries where the title is an
    unverifiable assertion — the class Torre Velasca belonged to.
    """
    out = []
    for pin in catalog.get("linkPins") or []:
        title_words = _cpc.subject_words(
            _cpc.display_stem(pin.get("title")), pin.get("city"))
        blob = " ".join([(pin.get("shortDescription") or ""),
                         (pin.get("longDescription") or "")])
        caption_words = _cpc.subject_words(blob, pin.get("city"))
        if _cpc.venue_handles(pin):
            continue
        if title_words & caption_words:
            continue
        out.append(pin)
    return out


def by_creator(catalog, pins, needle):
    """Pins by one creator, matched on the creator's own handle.

    ⚠️ Matched against `sourceAuthor` and the maker's `handle` — NOT against a
    substring of the whole record, which would sweep in any pin whose caption
    happened to mention them.
    """
    want = needle.strip().lstrip("@").lower()
    if not want:
        return pins
    makers = {m["id"]: (m.get("handle") or "").strip().lstrip("@").lower()
              for m in (catalog.get("makers") or [])}
    out = []
    for pin in pins:
        author = (pin.get("sourceAuthor") or "").strip().lstrip("@").lower()
        if author == want or makers.get(pin.get("makerId")) == want:
            out.append(pin)
    return out


def gate_a_prompt():
    return (
        "Does this image show ONE specific, identifiable real-world PLACE — a "
        "building, monument, venue, bridge, or site?\n\n"
        "Answer NO if it is instead: a person or people with no identifiable "
        "building behind them; a close-up of food or a drink; a text or title "
        "card; a map or diagram; a screenshot of an app or website; a generic "
        "street, interior, sky or landscape with no distinctive structure; or "
        "any image where you could not name the place from what is shown.\n\n"
        "Reply with exactly one word: YES or NO.")


def gate_b_prompt(title, city, distractors):
    lines = [
        f"Is the place shown in this image {title!r}"
        + (f", in {city}?" if city else "?"),
        "",
        "Answer NO if the image shows a DIFFERENT building or place, even a "
        "similar or neighbouring one, and even if it is in the same city.",
    ]
    if distractors:
        named = ", ".join(repr(d) for d in distractors[:6])
        # 🔴 Naming the look-alikes is what caught the Column of Marcus Aurelius
        # posing as Trajan's Column (CLAUDE.md § Image Pipeline).
        lines.append(f"In particular, answer NO if it is instead: {named}.")
    lines += ["", "Reply with exactly one word: YES or NO."]
    return "\n".join(lines)


def gate_c_prompt():
    return ("What is this place called? Reply with just the name of the "
            "building, monument or venue, and the city if you can tell. If you "
            "cannot identify it, reply exactly: UNKNOWN.")


def gate_d_prompt(title, named, city):
    """Do the title and what gate C named denote the SAME thing?

    🔴 WHY THIS GATE EXISTS. The first real run produced 23 CONTRADICTS on
    @pasttworld and at least seven were the check arguing with itself:
    gate B answered "not the title's subject" while gate C named the very same
    building — `Hearst Tower` -> "Hearst Tower", `Mohammed VI Tower` ->
    "Mohammed VI Tower", `Exchange 106` -> "The Exchange 106".

    ⚠️ And a STRING comparison cannot fix it, which is the whole reason this is
    a model call and not `subject_words`. Three of the seven share no word at
    all with the title and are still the same building:

        Steinway Tower   == 111 West 57th Street   (two names, one tower)
        MetLife Building == Pan Am Building        (a former name)
        Tianducheng      -> Eiffel Tower           (the replica IS the subject)

    So it is asked as its own question, about names alone, with no image: the
    model is good at "are these two names for one building" and that is all it
    is asked. A yes means the two gates disagree, which is a fact about the
    CHECK, not a finding about the catalogue.
    """
    return (
        f"Do these two names refer to the SAME building, monument or place?\n\n"
        f"  A: {title!r}" + (f" (in {city})" if city else "") + "\n"
        f"  B: {named!r}\n\n"
        "Answer YES if they are the same thing under two names, a former and "
        "current name, a formal name and a nickname, an address and a building "
        "name, or if one is a replica or copy that the other is a copy OF.\n"
        "Answer NO if they are genuinely different buildings or places.\n\n"
        "Reply with exactly one word: YES or NO.")


def fetch_image(url, *, timeout=30):
    request = urllib.request.Request(url, headers={"User-Agent": "Atlas/1.0"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read(), response.headers.get("Content-Type", "image/jpeg")


def build_payload(prompt, image_bytes, mime):
    """The request body. Its own function so a test can look inside it.

    🔴 A mutation that sends the image on EVERY call read as caught by nothing
    until this was extracted: the prompt text was asserted, the wire format was
    not. Gate D shown a picture answers about the picture, which is exactly the
    disagreement it exists to settle.
    """
    parts = [{"text": prompt}]
    if image_bytes:
        parts.append({"inline_data": {
            "mime_type": mime,
            "data": base64.b64encode(image_bytes).decode()}})
    return {"contents": [{"parts": parts}],
            "generationConfig": {"temperature": 0, "maxOutputTokens": 40}}


def ask(prompt, image_bytes, mime, key, *, timeout=60):
    """One question, optionally about one image. Raises on failure.

    ⚠️ `image_bytes=None` sends NO image part at all, rather than an empty one.
    Gate D is a question about two NAMES and must not be shown a picture: given
    one, the model answers about the picture again, which is the very
    disagreement gate D exists to adjudicate.

    🔴 An empty answer and a failed call must not be indistinguishable: a caller
    that cannot tell them apart caches a network error as "the model said no".
    """
    payload = build_payload(prompt, image_bytes, mime)
    request = urllib.request.Request(
        f"{ENDPOINT}?key={urllib.parse.quote(key)}",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    last = None
    for attempt in range(1, MAX_RETRY + 1):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                body = json.load(response)
            parts = body["candidates"][0]["content"]["parts"]
            return " ".join(p.get("text", "") for p in parts).strip()
        except Exception as exc:                            # noqa: BLE001
            last = exc
            if attempt < MAX_RETRY:
                time.sleep(SLEEP_S * 2 * attempt)
    raise RuntimeError(f"{type(last).__name__}: {last}")


def yes_no(answer):
    """YES/NO from a one-word reply. None when it is neither.

    ⚠️ `None` is deliberately NOT folded into NO. A model that answered with a
    sentence has not said no, and treating it as no would manufacture findings.
    """
    text = (answer or "").strip().upper()
    if text.startswith("YES"):
        return True
    if text.startswith("NO"):
        return False
    return None


def verdict(gate_a, gate_b, gate_d=None):
    """`gate_d` is asked only when B says no, and can only WITHDRAW a finding.

    🔴 It is never allowed to create one: an unanswered D (None) leaves
    CONTRADICTS standing, because a reconciliation that did not run must not
    quietly excuse a disagreement.
    """
    if gate_a is None or (gate_a and gate_b is None):
        return "UNCHECKED"
    if not gate_a:
        return "UNUSABLE"
    if gate_b:
        return "CONFIRMS"
    return "DISPUTED" if gate_d else "CONTRADICTS"


def neighbours(catalog, pin, limit=6):
    """Other titles in the same city — the distractors for gate B."""
    city = (pin.get("city") or "").strip().lower()
    if not city:
        return []
    out = []
    for other in (catalog.get("tours") or []) + (catalog.get("linkPins") or []):
        if other["id"] == pin["id"]:
            continue
        if (other.get("city") or "").strip().lower() != city:
            continue
        name = _cpc.display_stem(other.get("title")).strip()
        if name and name not in out:
            out.append(name)
        if len(out) >= limit:
            break
    return out


def digest(pin):
    payload = json.dumps([pin.get("title") or "", pin.get("heroImageURL") or "",
                          pin.get("city") or "", RECORD_VERSION],
                         ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16]


def load_cache(path):
    if not os.path.exists(path):
        return {}
    with gzip.open(path, "rt", encoding="utf-8") as fh:
        return json.load(fh)


def save_cache(path, cache):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with gzip.GzipFile(tmp, "wb", compresslevel=9, mtime=0) as raw:
        raw.write(json.dumps(cache, ensure_ascii=False, sort_keys=True,
                             indent=1).encode("utf-8"))
    os.replace(tmp, path)


def selftest():
    fails = []
    ran = []

    def check(name, ok):
        # 🔴 The total is COUNTED, never declared. A hardcoded total drifts the
        # moment a check is added or removed, and then reports a number that is
        # simply false while still printing green.
        ran.append(name)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    check("yes_no reads YES", yes_no("YES") is True)
    check("yes_no reads NO", yes_no("no") is False)
    check("yes_no tolerates punctuation", yes_no("Yes.") is True)
    check("🔴 an unparseable reply is None, NOT a no", yes_no("I think so") is None)
    check("an empty reply is None", yes_no("") is None)

    check("🔴 gate A no -> UNUSABLE, which is not a pass",
          verdict(False, None) == "UNUSABLE")
    check("🔴 gate A yes + gate B no -> CONTRADICTS", verdict(True, False) == "CONTRADICTS")
    check("gate A yes + gate B yes -> CONFIRMS", verdict(True, True) == "CONFIRMS")
    check("🔴 an unanswered gate A is UNCHECKED, never a verdict",
          verdict(None, True) == "UNCHECKED")
    check("🔴 an unanswered gate B is UNCHECKED too",
          verdict(True, None) == "UNCHECKED")

    # 🔴 The two gates must be two SEPARATE questions. A compound prompt gets
    # answered on subject match alone — that shipped 19th-century prints as
    # photographs (CLAUDE.md § Image Pipeline).
    a, b = gate_a_prompt(), gate_b_prompt("X", "Y", [])
    check("🔴 gate A never mentions the title", "X" not in a)
    check("gate B asks about the title", "'X'" in b)
    check("gate A enumerates what to reject",
          all(w in a.lower() for w in ("food", "text", "map", "person")))
    check("gate B names the distractors when given",
          "'Duomo'" in gate_b_prompt("X", "Milan", ["Duomo"]))
    check("gate B says nothing about distractors when there are none",
          "in particular" not in gate_b_prompt("X", "Milan", []).lower())
    check("gate C is open-ended and offers an out",
          "UNKNOWN" in gate_c_prompt())

    check("🔴 gate B no + gate D yes -> DISPUTED, not a finding",
          verdict(True, False, True) == "DISPUTED")
    check("🔴 gate B no + gate D no -> CONTRADICTS stands",
          verdict(True, False, False) == "CONTRADICTS")
    check("🔴 an UNANSWERED gate D leaves CONTRADICTS standing",
          verdict(True, False, None) == "CONTRADICTS")
    check("🔴 gate D can never turn a CONFIRMS into anything else",
          verdict(True, True, False) == "CONFIRMS"
          and verdict(True, True, True) == "CONFIRMS")
    check("🔴 gate D can never rescue an UNUSABLE",
          verdict(False, None, True) == "UNUSABLE")
    check("gate D defaults to absent, so old callers still get CONTRADICTS",
          verdict(True, False) == "CONTRADICTS")

    dp = gate_d_prompt("Hearst Tower", "Hearst Tower, New York City", "New York")
    check("gate D names both candidates", "'Hearst Tower'" in dp
          and "'Hearst Tower, New York City'" in dp)
    check("🔴 gate D covers former names, nicknames and addresses",
          all(w in dp.lower() for w in ("former", "nickname", "address")))
    check("🔴 gate D covers the replica case (Tianducheng)",
          "replica" in dp.lower())
    check("gate D asks about NAMES and never mentions an image",
          "image" not in dp.lower() and "photo" not in dp.lower())
    check("🔴 a call with no image SENDS no image part",
          len(build_payload("q", None, None)["contents"][0]["parts"]) == 1)
    check("a call with an image sends two parts",
          len(build_payload("q", b"xy", "image/jpeg")["contents"][0]["parts"]) == 2)
    check("the image part carries base64 of the bytes given",
          build_payload("q", b"xy", "image/jpeg")["contents"][0]["parts"][1]
          ["inline_data"]["data"] == base64.b64encode(b"xy").decode())

    # The selection: exactly the class Torre Velasca was in.
    cat = {"tours": [], "linkPins": [
        {"id": "p1", "title": "Torre Velasca", "city": "Milan",
         "shortDescription": "A post by @pasttworld on Instagram.",
         "longDescription": "Italy's Ugliest Building Became a National Monument",
         "sourceAuthor": "@pasttworld"},
        {"id": "p2", "title": "Kossar's", "city": "New York",
         "shortDescription": "", "longDescription": "bialys at @kossars",
         "sourceAuthor": "@jack"},
        {"id": "p3", "title": "Duomo", "city": "Milan",
         "shortDescription": "", "longDescription": "the Duomo at sunrise",
         "sourceAuthor": "@x"},
    ]}
    picked = [p["id"] for p in uncorroborated(cat)]
    check("🔴 the Torre Velasca shape IS selected", "p1" in picked)
    check("a pin with a venue handle is NOT selected", "p2" not in picked)
    check("a caption naming the title is NOT selected", "p3" not in picked)

    mk_cat = {"makers": [{"id": "m1", "handle": "pasttworld"},
                         {"id": "m2", "handle": "hereinnyc"}]}
    pins = [{"id": "a", "sourceAuthor": "@pasttworld", "makerId": "m1"},
            {"id": "b", "sourceAuthor": "@hereinnyc", "makerId": "m2"},
            {"id": "c", "sourceAuthor": "", "makerId": "m1"},
            {"id": "d", "sourceAuthor": "@someoneelse", "makerId": "m2",
             "longDescription": "as seen on @pasttworld"}]
    got = [p["id"] for p in by_creator(mk_cat, pins, "pasttworld")]
    check("--maker matches the sourceAuthor", "a" in got)
    check("--maker matches via the maker's handle", "c" in got)
    check("--maker tolerates a leading @", got == [p["id"] for p in
          by_creator(mk_cat, pins, "@pasttworld")])
    check("--maker excludes another creator", "b" not in got)
    check("🔴 --maker does NOT match a MENTION in someone else's caption",
          "d" not in got)
    check("an empty --maker changes nothing",
          by_creator(mk_cat, pins, "") == pins)

    d1 = digest({"title": "A", "heroImageURL": "u", "city": "c"})
    check("digest is stable", d1 == digest({"title": "A", "heroImageURL": "u", "city": "c"}))
    check("digest moves when the title changes",
          d1 != digest({"title": "B", "heroImageURL": "u", "city": "c"}))
    check("🔴 digest moves when the IMAGE changes",
          d1 != digest({"title": "A", "heroImageURL": "v", "city": "c"}))

    nb = neighbours({"tours": [], "linkPins": [
        {"id": "a", "title": "Torre Velasca", "city": "Milan"},
        {"id": "b", "title": "Duomo di Milano", "city": "Milan"},
        {"id": "c", "title": "Colosseum", "city": "Rome"},
    ]}, {"id": "a", "title": "Torre Velasca", "city": "Milan"})
    check("distractors come from the same city only", nb == ["Duomo di Milano"])

    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — "
          f"{len(ran) - len(fails)}/{len(ran)}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--key", default=os.environ.get("GEMINI_API_KEY", ""),
                    help="Gemini API key. The owner pastes one per session; it "
                         "is never stored in the repo.")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--only", default="", help="substring filter on the title")
    ap.add_argument("--maker", default="",
                    help="one creator's handle, e.g. pasttworld (the @ is optional)")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()

        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        cache = load_cache(a.cache)
        targets = uncorroborated(catalog)
        if a.maker:
            targets = by_creator(catalog, targets, a.maker)
        if a.only:
            targets = [p for p in targets
                       if a.only.lower() in (p.get("title") or "").lower()]

        todo = [p for p in targets if (cache.get(p["id"]) or {}).get("digest") != digest(p)]
        print(f"{len(targets)} uncorroborated pin(s) · {len(cache)} cached · "
              f"{len(todo)} to check")

        if not a.key:
            # 🔴 A check that cannot run must not be able to return a pass.
            print("\nCOULD NOT VERIFY — no Gemini key. Pass --key or set "
                  "GEMINI_API_KEY.\n⚠️ The key starts with 'AQ.' — do not "
                  "prepend anything (CLAUDE.md § Image Pipeline).")
            return 2
        if a.limit:
            todo = todo[:a.limit]

        counts = {"CONTRADICTS": 0, "CONFIRMS": 0, "DISPUTED": 0,
                  "UNUSABLE": 0, "UNCHECKED": 0}
        findings = []
        for index, pin in enumerate(todo, 1):
            title = _cpc.display_stem(pin.get("title")).strip()
            try:
                blob, mime = fetch_image(pin["heroImageURL"])
                ans_a = ask(gate_a_prompt(), blob, mime, a.key)
                gate_a = yes_no(ans_a)
                gate_b = gate_d = named = None
                if gate_a:
                    # ⚠️ Separate call. Never folded into gate A.
                    gate_b = yes_no(ask(gate_b_prompt(
                        title, pin.get("city"), neighbours(catalog, pin)),
                        blob, mime, a.key))
                    if gate_b is False:
                        named = ask(gate_c_prompt(), blob, mime, a.key)
                        if named and named.strip().upper() != "UNKNOWN":
                            # ⚠️ No image: a question about NAMES, on its own.
                            gate_d = yes_no(ask(gate_d_prompt(
                                title, named.strip(), pin.get("city")),
                                None, None, a.key))
            except Exception as exc:                        # noqa: BLE001
                counts["UNCHECKED"] += 1
                print(f"  {index}/{len(todo)} UNCHECKED {title[:34]}: "
                      f"{type(exc).__name__}")
                continue

            call = verdict(gate_a, gate_b, gate_d)
            counts[call] += 1
            if call != "UNCHECKED":
                cache[pin["id"]] = {"digest": digest(pin), "version": RECORD_VERSION,
                                    "title": pin.get("title"), "verdict": call,
                                    "identified_as": named}
            if call == "DISPUTED":
                print(f"  {index}/{len(todo)} ~ DISPUTED    {title[:30]:30} "
                      f"= {(named or '?')[:36]}")
            if call == "CONTRADICTS":
                findings.append((title, pin.get("city"), named))
                print(f"  {index}/{len(todo)} 🔴 CONTRADICTS {title[:30]:30} "
                      f"-> {(named or '?')[:36]}")
            if index % 25 == 0:
                save_cache(a.cache, cache)

        save_cache(a.cache, cache)
        print(f"\nCONTRADICTS {counts['CONTRADICTS']} · CONFIRMS {counts['CONFIRMS']}"
              f" · DISPUTED {counts['DISPUTED']} · UNUSABLE {counts['UNUSABLE']}"
              f" · UNCHECKED {counts['UNCHECKED']}")
        if findings:
            print("\n🔴 the picture disagrees with the title:")
            for title, city, named in findings:
                print(f"  {title[:34]:34} {(city or '')[:14]:14} looks like: "
                      f"{(named or 'unidentified')[:40]}")
        if counts["DISPUTED"]:
            print(f"\n⚠️  {counts['DISPUTED']} DISPUTED — gate B said 'not the "
                  "title's subject' while\n    gate C named the same thing "
                  "under another name. That is the CHECK\n    disagreeing with "
                  "itself, not a finding about the catalogue.")
        print("\n⚠️  UNUSABLE is NOT clean — it means the frame shows no")
        print("    identifiable place (a person, a plate, a title card), so the")
        print("    check could not speak. Those titles remain unverified.")
        print("⚠️  A CONTRADICTS is evidence, not a verdict. Open the post before")
        print("    changing a title: the model can be wrong, and so can the hero.")
        if counts["UNCHECKED"]:
            print(f"\nCOULD NOT VERIFY — {counts['UNCHECKED']} pin(s) went "
                  f"unanswered; re-run to finish them")
            return 2
        return 1 if counts["CONTRADICTS"] else 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())

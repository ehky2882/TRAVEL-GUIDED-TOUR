#!/usr/bin/env python3
"""Triage a creator's posts before any of them become pins.

    python3 scripts/triage-account.py --handle @pacificmodernism --out /tmp/t.md
    python3 scripts/triage-account.py --urls /tmp/links.txt --out /tmp/t.md

A creator's feed is not uniformly pinnable. Some posts are about one place and
belong on the map; some name several places and need a human decision; some are
not about a place at all. This reads the captions, flags each post, and writes a
report. It mints nothing and writes nothing into the catalog — `make-link-pin.py`
still does that, from a batch file the owner has approved.

🔴 IT FLAGS, IT DOES NOT DECIDE. Every signal below is a HINT computed from a
caption, and a caption lies: "Top 5" appears in videos about one shop, and a
video listing nine cathedrals can mention none of them by name. The flags exist
to order a human's attention, never to authorise a merge. MULTI in particular
is a question — the owner decides per post whether it explodes into several
pins, keeps only its lead location, or does not fit the app at all.

WHY NOT JUST SCRAPE THE PROFILE
-------------------------------
Measured 2026-09-11 from a cloud session, not assumed:

  tiktok.com/@handle          200, 371 KB, ZERO video ids, 25 mentions of captcha
  tiktok.com/embed/@handle    200, 14 video ids, no captcha      ← what we use
  instagram.com/<handle>/     302 to login
  instagram.com/<h>/embed/    200, but a Facebook login shell: zero post links
  youtube.com/@handle         200, carries the channelId → RSS   ← what we use

So a bare handle yields the newest ~14 posts on TikTok and ~15 on YouTube, and
nothing at all on Instagram. `--urls` exists because that ceiling is real: for a
back catalogue, or for any Instagram account, the list has to be supplied.
⚠️ A `cursor` or `count` parameter does NOT deepen the TikTok embed — tested on
two creators, both capped at 14. Do not "fix" that by adding one.

NETWORK
-------
Every fetch goes through `make-link-pin.py`'s `curl`, so the two tools cannot
drift and neither can use urllib — which fails SSL verification on the owner's
Mac and is how `check-image-duplicates.py` once printed OK having fetched
nothing. A run that cannot reach the network exits 2 and says COULD NOT VERIFY;
it never reports an empty feed as a clean one.
"""

import argparse
import importlib.util
import json
import os
import re
import sys
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
CATALOG = os.path.join(HERE, os.pardir, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")


def _sibling(name, path):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, path))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


mlp = _sibling("make_link_pin", "make-link-pin.py")
runstamp = _sibling("runstamp", "runstamp.py")


# ── signals ──────────────────────────────────────────────────────────────────
# Deliberately few and deliberately blunt. Each one is a reason to LOOK, and the
# report prints which fired so a reader can disagree with it on sight.

NUMBERS = r"(?:two|three|four|five|six|seven|eight|nine|ten|\d{1,2})"

MULTI_PATTERNS = [
    (rf"\btop\s*{NUMBERS}\b", 'says "top N"'),
    (rf"\b{NUMBERS}\s+(?:best|favourite|favorite|hidden|underrated|must[- ]see)\b", "ranks N things"),
    (rf"\b{NUMBERS}\s+(?:places?|spots?|stops?|buildings?|markets?|museums?|"
     rf"churches|cathedrals?|bars?|cafe?s?|restaurants?|shops?|parks?|bridges?|"
     rf"houses?|towers?|streets?|neighbou?rhoods?)\b", "counts N places"),
    (rf"\bthese\s+{NUMBERS}\b", 'says "these N"'),
    (r"\bpart\s*\d\b", "is part of a series"),
    (r"^\s*\d[\.\)]\s.*^\s*\d[\.\)]\s", "caption is a numbered list"),
    (r"\b(?:itinerary|road ?trip|day\s*\d|guide to)\b", "reads as an itinerary"),
    # ⚠️ Added after the @urbanistariel run of 2026-09-11, which flagged
    # "Two of the things that made Venice…" as SINGLE. A count need not be
    # followed by a place noun to be a list.
    (rf"\b{NUMBERS}\s+of\s+the\b", "counts N of something"),
    # ⚠️ A bare "both" was tried and removed the same day: it fires on idiom
    # ("the boat does both jobs") far more often than on two places.
    #
    # ROUTES are their own problem, and the reason this pattern replaced it.
    # A vaporetto line, a ferry, a long street — the post is about a path, and
    # this app geofences POINTS. It is neither a single pin nor a roundup, and
    # it is the commonest reason a good post does not fit the app at all.
    (r"\b(?:line\s*\d|route|metro|subway|vaporetto|ferry|tram|bus|cable ?car|"
     r"\d+\s*stops|end to end|walk(?:ed|ing)? the (?:whole|entire))\b",
     "describes a route, not a point"),
]

# Not about a place. These are about the creator, the craft, or nothing.
THIN_PATTERNS = [
    (r"\b(?:how (?:i|to)|tutorial|tips?|hacks?|my gear|q ?& ?a|storytime|"
     r"day in (?:my|the) life|get ready with me|grwm|tier list|rating|"
     r"follow for|link in bio|giveaway|announcement|podcast|newsletter|"
     # Added 2026-09-11: the same run flagged two 10-year-anniversary
     # livestream posts as SINGLE. A creator talking about their own channel
     # is the commonest non-place post there is, and none of the words above
     # covered it.
     r"anniversary|livestream|live ?stream|merch|my book|out now|new video|"
     r"subscribe|patreon|thank you all|years of making)\b",
     "reads as non-place content"),
]

CITY_TAG = re.compile(r"#(\w{3,})")


def names_nothing(caption: str) -> bool:
    """True when the caption carries no capitalised word that could be a place.

    Hashtags are stripped first — they are lowercase by convention and a
    #sanfrancisco is a hint, not a name — and so is the first word of each
    sentence, which is capitalised by grammar rather than by being a proper
    noun. What survives is a rough proper-noun count.
    """
    text = re.sub(r"#\w+", " ", caption or "")
    text = re.sub(r"https?://\S+", " ", text)
    sentences = re.split(r"(?<=[.!?\n])\s+", text)
    for s in sentences:
        # ⚠️ Strip leading emoji before deciding which word is sentence-initial.
        # Creators open with one constantly, and counting it as the first word
        # made the REAL first word look like a proper noun — "🙌 Stay curious,
        # my friends!" read as naming a place called "Stay".
        words = [w for w in s.split() if re.search(r"[A-Za-z]", w)]
        for w in words[1:]:
            if re.match(r"^[A-Z][a-zA-Z'’\-]{1,}$", w.strip(",;:()\"")):
                return False
    return True


def flags_for(caption: str) -> tuple[list[str], list[str]]:
    """Pure. Returns (multi_reasons, thin_reasons) — never a verdict."""
    low = (caption or "").lower()
    multi = [why for pat, why in MULTI_PATTERNS
             if re.search(pat, low, re.IGNORECASE | re.MULTILINE | re.DOTALL)]
    thin = [why for pat, why in THIN_PATTERNS if re.search(pat, low, re.IGNORECASE)]
    if caption and names_nothing(caption):
        thin.append("names nothing capitalised — no place in the caption")
    return multi, thin


def tour_id_for(url: str) -> str:
    """The catalog's id scheme, so a post already pinned is recognised rather
    than proposed again. uuid5 over the NORMALISED url — the same post shared
    with a tracking parameter must land on the same id."""
    clean = mlp.normalize_url(url)
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"atlas-tour:link:{clean}")).upper()


def already_live(urls: list[str]) -> dict[str, str]:
    """Map url → the title it is already pinned under. Read from the catalog on
    disk; a post already in `linkPins` must never be proposed a second time."""
    try:
        with open(CATALOG, encoding="utf-8") as fh:
            cat = json.load(fh)
    except OSError:
        return {}
    by_id = {}
    for p in cat.get("linkPins", []):
        by_id.setdefault(p["id"], p.get("title", "?"))
    # A post may carry several pins under fragment keys; match on sourceURL too.
    by_src = {}
    for p in cat.get("linkPins", []):
        by_src.setdefault(p.get("sourceURL", ""), []).append(p.get("title", "?"))
    out = {}
    for u in urls:
        hit = by_id.get(tour_id_for(u))
        if hit:
            out[u] = hit
        else:
            same = by_src.get(mlp.normalize_url(u)) or by_src.get(u)
            if same:
                out[u] = f"{len(same)} pins: " + ", ".join(same[:3])
    return out


# ── enumeration ──────────────────────────────────────────────────────────────

def posts_for_handle(handle: str, platform: str) -> list[str]:
    h = handle.lstrip("@")
    if platform == "tiktok":
        html = mlp.curl(f"https://www.tiktok.com/embed/@{h}")
        ids = sorted(set(re.findall(r'"id":"(\d{15,})"', html)), reverse=True)
        return [f"https://www.tiktok.com/@{h}/video/{i}" for i in ids]
    if platform == "youtube":
        page = mlp.curl(f"https://www.youtube.com/@{h}")
        m = re.search(r'"channelId":"(UC[\w-]{22})"', page)
        if not m:
            raise SystemExit(
                f"COULD NOT VERIFY — no channelId on youtube.com/@{h}. The handle may be\n"
                "wrong, or YouTube may have renamed the key. Supply --urls instead.")
        feed = mlp.curl(f"https://www.youtube.com/feeds/videos.xml?channel_id={m.group(1)}")
        return re.findall(r"<link rel=\"alternate\" href=\"([^\"]+watch\?v=[^\"]+)\"", feed)
    raise SystemExit(
        "COULD NOT VERIFY — Instagram exposes no post list to a server: the profile\n"
        "redirects to login and the profile embed is a Facebook shell with zero post\n"
        "links (measured 2026-09-11). Supply the URLs with --urls.")


# ── report ───────────────────────────────────────────────────────────────────

def render(rows: list[dict]) -> str:
    order = {"LIVE": 0, "SINGLE": 1, "MULTI": 2, "THIN": 3, "DEAD": 4}
    rows = sorted(rows, key=lambda r: (order[r["flag"]], r["url"]))
    out, n = [], 0
    for r in rows:
        n += 1
        cap = " ".join((r["caption"] or "").split())
        out.append(f'[{n:>3}] {r["flag"]:<6} {r["url"]}')
        out.append(f'      {cap[:150]}{"…" if len(cap) > 150 else ""}' if cap
                   else "      (no caption)")
        if r["why"]:
            out.append(f'      ↳ {" · ".join(r["why"])}')
        out.append("")
    tally = {k: sum(1 for r in rows if r["flag"] == k) for k in order}
    out.append("— " * 30)
    out.append(f'LIVE {tally["LIVE"]} already pinned · SINGLE {tally["SINGLE"]} one place · '
               f'MULTI {tally["MULTI"]} need a decision · THIN {tally["THIN"]} probably not '
               f'place-based · DEAD {tally["DEAD"]} unreadable')
    out.append("")
    out.append("SINGLE and THIN are hints from the caption, not verdicts — read them.")
    out.append("MULTI is a question for the owner: explode into several pins, keep only the")
    out.append("lead location, or leave it out of the app. Nothing here has been minted.")
    return "\n".join(out)


def selftest() -> int:
    cases, failed = [], 0

    def check(name, got, want):
        nonlocal failed
        cases.append(name)
        ok = got == want
        if not ok:
            failed += 1
        print(f"  {'PASS' if ok else 'FAIL'}  {name}" + ("" if ok else f"\n        got {got!r}\n        want {want!r}"))

    m, t = flags_for("Top 5 Italian antique markets, we recommend as vintage dealers !!!")
    check("counts a 'Top N' roundup as MULTI", bool(m), True)
    m, _ = flags_for("Do you think the alignment of these three Freemason obelisks is a coincidence?")
    check("catches a spelled-out number", bool(m), True)
    m, _ = flags_for("Chapel of the Cross by James Leefe and Ezra Ehrenkrantz, 1965 #berkeley")
    check("a single building is not MULTI", m, [])
    m, _ = flags_for("3 hidden courtyards in Milan you have to see")
    check("catches 'N hidden ...'", bool(m), True)
    _, t = flags_for("How I shoot architecture on a phone — my full setup")
    check("a gear video is THIN", bool(t), True)
    _, t = flags_for("Therme Vals, Peter Zumthor, 1996")
    check("a named building is not THIN", t, [])
    m, _ = flags_for("")
    check("an empty caption raises nothing", m, [])
    m, _ = flags_for(None)
    check("a missing caption raises nothing", m, [])

    # Regressions from the @urbanistariel run, 2026-09-11.
    m, _ = flags_for("I almost skipped Venice. Two of the things that made Venice great…")
    check("catches 'Two of the things'", bool(m), True)
    m, _ = flags_for("I rode Line 2 down the Grand Canal. Fifteen stops in under four km.")
    check("flags a transit route", bool(m), True)
    m, _ = flags_for("The boat does both jobs here, and does them well.")
    check("a bare 'both' is no longer a flag", m, [])
    _, t = flags_for("🧡 It's the 10-year anniversary of me making videos!")
    check("a channel anniversary is THIN", bool(t), True)
    _, t = flags_for("🙌 Stay curious, my friends!")
    check("a caption naming nothing is THIN", bool(t), True)
    _, t = flags_for("Westlake Daly City Doelger home, 1952 #housetour #dalycity")
    check("a named house is still not THIN", t, [])
    check("hashtags alone do not count as a name",
          names_nothing("love this one #sanfrancisco #bayarea"), True)

    # 🔴 The id must match the catalog's scheme exactly, or an already-pinned
    # post is proposed a second time. Pinned against a known-live pin.
    check("tour id reproduces a live pin",
          tour_id_for("https://www.instagram.com/reel/DFxyNa9xMSm/"),
          "6192A9EC-C601-5145-A600-5F7E8FF6940E")
    check("a tracking parameter does not change the id",
          tour_id_for("https://www.youtube.com/watch?v=abc123&si=XYZ"),
          tour_id_for("https://www.youtube.com/watch?v=abc123"))

    body = render([{"url": "u1", "caption": "Top 5 markets", "flag": "MULTI",
                    "why": ['says "top N"']},
                   {"url": "u2", "caption": "One chapel", "flag": "SINGLE", "why": []}])
    check("the report sorts SINGLE above MULTI",
          body.index("u2") < body.index("u1"), True)
    check("the report never prints raw JSON", "{" in body, False)

    total = len(cases)
    print(f"\n{total - failed}/{total} self-tests passed")
    return 1 if failed else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--handle", help="@name. TikTok gives ~14 recent posts, YouTube ~15, "
                                     "Instagram none — see the module docstring")
    ap.add_argument("--platform", choices=["tiktok", "youtube", "instagram"], default="tiktok")
    ap.add_argument("--urls", help="File of post URLs, one per line; # and blanks ignored")
    ap.add_argument("--limit", type=int, default=0, help="Stop after N posts (0 = all)")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        if not a.handle and not a.urls:
            ap.error("give either --handle or --urls")

        if a.urls:
            with open(a.urls, encoding="utf-8") as fh:
                urls = [l.split("|")[0].strip() for l in fh
                        if l.strip() and not l.lstrip().startswith("#")]
        else:
            urls = posts_for_handle(a.handle, a.platform)
            print(f"{a.platform} @{a.handle.lstrip('@')} → {len(urls)} posts "
                  f"(the platform's ceiling, not the account's size)")
        if a.limit:
            urls = urls[:a.limit]
        if not urls:
            print("COULD NOT VERIFY — no posts found. That is not the same as an empty "
                  "account; supply --urls.", file=sys.stderr)
            return 2

        live = already_live(urls)
        rows, reached = [], 0
        for u in urls:
            if u in live:
                rows.append({"url": u, "caption": "", "flag": "LIVE",
                             "why": [f"already in the catalog — {live[u]}"]})
                reached += 1
                continue
            try:
                meta = mlp.oembed(u)
                reached += 1
            except SystemExit as exc:
                rows.append({"url": u, "caption": "", "flag": "DEAD",
                             "why": [str(exc).splitlines()[0][:110]]})
                continue
            cap = meta.get("title") or ""
            multi, thin = flags_for(cap)
            why = list(multi) + list(thin)
            if meta.get("plays_inline") is False:
                why.append("will not play inline (licensed music)")
            flag = "MULTI" if multi else ("THIN" if thin else "SINGLE")
            rows.append({"url": u, "caption": cap, "flag": flag, "why": why})

        # 🔴 A run that reached nothing must not read as a clean feed.
        if reached == 0:
            print("COULD NOT VERIFY — every post failed to fetch. Network or platform "
                  "change, not an account of dead posts.", file=sys.stderr)
            return 2

        print()
        print(render(rows))
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())

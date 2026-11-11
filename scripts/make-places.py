#!/usr/bin/env python3
"""Create places automatically, from whichever signal can prove one.

WHY THIS IS ALLOWED TO CREATE WITHOUT ASKING
---------------------------------------------
`Models/Place.swift` says identity is exact coordinate equality and *"anything
looser must be approved by a human, never auto-created"*. That rule was written
because the only looser test available at the time was PROXIMITY, and proximity
was measured and rejected: grouping anything within 40 m produced 43 places of
which **19 were wrong** — it merged LACMA with the Academy Museum and chained
three separate La Boca venues into one site.

**A shared gazetteer id is not a looser version of that test. It is a different
one.** Two entries are grouped here only when Wikidata's own search resolves
both to the **same item**, and both sit within 120 m of that item's coordinate.
Nothing is inferred from how close the two entries are to each other: `The
Shard` and `The Shard` are one place because they are the same building, which
is exactly `docs/places.md` Rule 1 — *two names for one thing is always a
place* — decided by a gazetteer instead of by eye.

⚠️ **This does NOT settle part-vs-whole**, which `docs/places.md` leaves
explicitly undecided. A gazetteer has no opinion on whether the River Building
is Grace Farms. Those cases still go to the owner.

🔴 THE DECLINED LIST IS NOT OPTIONAL
-------------------------------------
The first run of this proposed **Bar Luce at Fondazione Prada** + **Fondazione
Prada** — a pairing the owner has already declined under Rule 4, *a tenant is
not the site*. Wikidata cannot know that Bar Luce is a café inside the
foundation; it resolves both to the foundation and is, on its own terms,
correct.

So every proposal is checked against `make-place-menu.py`'s `DECLINED`,
`DECLINED_GROUPS` and `DECLINED_PAIRS` — the record of ~60 owner decisions —
and a match is **refused, not merely flagged**. Those lists are keyed by TITLE
rather than by any generated label, deliberately, so they survive renumbering.

WHAT CREATING A PLACE ACTUALLY DOES
------------------------------------
🔴 **A place is a COORDINATE, so creating one MOVES every member onto a single
point.** `validate-tours.swift` errors if a member's `order == 0` stop is not
within 1e-7° of it. This uses the **Wikidata item's own coordinate** as that
point, which is the honest choice: it is what both entries were independently
matched against.

⚠️ Measured on the first run: median member move **22 m**, maximum **86 m** —
inside the 30 m default `triggerRadiusMeters` for most, and small enough that no
geofence moves off its own building. `--max-move` refuses anything further, so a
group that would drag an entry somewhere new fails loudly instead of quietly.
"""

from __future__ import annotations

import argparse
import collections
import gzip
import importlib.util
import json
import os
import re
import sys
import unicodedata
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
CACHE = os.path.join(REPO, "spine", "lookups.json.gz")
FEATURES = os.path.join(REPO, "spine", "features.json.gz")

MAX_MOVE_M = 120.0      # a member further than this is a group worth reading


def _load(name, alias):
    path = os.path.join(HERE, name)
    spec = importlib.util.spec_from_file_location(alias, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_sm = _load("spine-match.py", "_spine_match")
_menu = _load("make-place-menu.py", "_place_menu")
_cpc = _sm._cpc
haversine = _cpc.haversine
display_stem = _cpc.display_stem


def slug(text):
    """The place-id slug. Matches the scheme that reproduces the live ids.

    ⚠️ Deliberately does NOT transliterate: `Chichén Itzá` becomes
    `chich-n-itz`. Ugly, and correct — it is the rule the existing ids were
    minted under, and changing it would orphan them.
    """
    lowered = unicodedata.normalize("NFC", (text or "")).lower()
    return re.sub(r"-+", "-", re.sub(r"[^a-z0-9]+", "-", lowered)).strip("-")


def place_id(city, name):
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"atlas-place:{slug(city)}:{slug(name)}"))


def declined(titles):
    """Has the owner already said no to this exact set of titles?

    🔴 Checked three ways because the record is kept three ways, and a proposal
    only has to match ONE of them to be refused.
    """
    as_set = frozenset(titles)
    if as_set in _menu.DECLINED_GROUPS:
        return "an owner-declined group"
    for pair in _menu.DECLINED_PAIRS:
        if frozenset(pair) <= as_set:
            return "an owner-declined pair"
    for title in titles:
        if title in _menu.DECLINED:
            return f"an owner-declined entry ({title})"
    return None


def propose_proven(catalog, *, max_move_m=MAX_MOVE_M):
    """Coincident entries that are PROVABLY one venue. Returns (make, skip).

    🔴 THIS IS THE SIGNAL THAT COVERS FOOD, and it is why a gazetteer alone was
    never enough. Kossar's sits at **0.0 m** from a pin whose title is a caption
    ("Someone fact check my bialy claim 📍@kossars"); Wikidata has never heard of
    either, and no name lookup could match that string. What proves them one
    venue is the coordinate PLUS the shared `@kossars` handle.

    The proof test is `check-place-candidates.proven_same_venue`, reused
    unchanged — identical name, or a shared venue handle (the creator's own
    handle excluded, or every pin by one food reviewer would pair), or one
    entry's name written in the other's caption. ⚠️ A coincident coordinate
    ALONE is not proof: a centroid dump puts unrelated pins on one point.

    🔴 MEMBERS CAN MOVE, and an earlier version of this docstring said they
    could not. `proven_groups` bounds the search at `TIGHT_M` (25 m), not at
    0 m, so a proven group may span up to that — and minting pulls every member
    onto the anchor. On 2026-09-22 eight groups were minted after the proposal
    reported `move<=0 m` for all of them; two entries moved, by 19.5 m and
    11.6 m. Small, and the groups were right, but the figure the decision was
    made on was hardcoded rather than measured.

    `max_move_m` is now computed from the members, so `--max-move` is a real
    guard here and the printed number is the true one.
    """
    claimed = {t for p in (catalog.get("places") or []) for t in p.get("tourIds", [])}
    # ⚠️ A tourism-board handle is not a venue handle — see
    # check-place-candidates.ubiquitous_handles. Without this, The Last Drop
    # and Biddy Mulligan's (two Grassmarket pubs, 24 m apart, both tagging
    # @visitscotland) mint as ONE place.
    everywhere = _cpc.ubiquitous_handles(_cpc.entries(catalog))
    by_point = proven_groups(_cpc.entries(catalog), TIGHT_M, everywhere)

    make, skip = [], []
    for point, (members, proof) in sorted(by_point.items()):
        if len(members) < 2:
            continue
        entries_only = [e for _, e in members]
        titles = [e.get("title") or "" for e in entries_only]
        item = {
            "signal": "PROVEN", "name": place_name(entries_only), "titles": titles,
            "city": next((e.get("city") for e in entries_only if e.get("city")), None),
            "lat": point[0], "lon": point[1],
            "members": [e["id"] for e in entries_only],
            # 🔴 Measured, not assumed — see the note above.
            "max_move_m": max((haversine(_sm.entry_marker(e), point)
                               for e in entries_only), default=0.0),
        }
        if any(e["id"] in claimed for e in entries_only):
            item["why"] = "a member already belongs to a place"
            skip.append(item)
            continue
        item["proof"] = proof
        blocked = declined(titles)
        if blocked:
            item["why"] = f"REFUSED — {blocked}"
            skip.append(item)
            continue
        make.append(item)
    return make, skip


# 🔴 NOT exact coordinate equality, and the reason is a real miss.
# Kossar's sits 0.0 m from its caption pin BY DISTANCE, but the two coordinates
# differ below a centimetre — so bucketing on rounded equality put them in
# different buckets and the first version of this signal did not propose them.
# Una Pizza Napoletana is 12.4 m from its caption pin, so equality could never
# have reached it at all.
#
# ⚠️ THE RADIUS IS NOT THE PROOF. `docs/places.md` records a 40 m proximity rule
# being measured and rejected (43 places, 19 wrong), and the nearest
# owner-declined part-vs-whole case sits **6.9 m apart** — inside this radius.
# What keeps those out is `proven_same_venue` AND the declined record, not the
# distance. The radius only decides who is even considered.
#
# 25 m is the repo's existing reviewed TIGHT threshold, and the chain length is
# capped at one hop for the reason session 95 found: transitive linking at 40 m
# chained three separate La Boca venues into one site.
TIGHT_M = 25.0


def proven_groups(entries_in, radius_m, ubiquitous=frozenset()):
    """Groups built from PAIRS THAT PASS PROOF, then unioned.

    🔴 PROOF DRIVES THE GROUPING. PROXIMITY ONLY BOUNDS THE SEARCH — and the
    first version had it the other way round, with a real cost. It clustered by
    distance and then tested proof, so an arbitrary anchor decided everything:
    **Saigon Social** grabbed **Una Pizza Napoletana** 23.8 m away, the pair
    correctly failed proof, and Una Pizza was consumed — so its true partner,
    its own caption pin 12.4 m off, never formed a group at all. A wrong anchor
    silently destroyed a right answer.

    Testing pairs first cannot do that: Saigon Social and Una Pizza never pair
    because nothing proves them one venue, and Una Pizza stays free to pair
    with the caption that names `@unapizzanapoletana`.

    ⚠️ Union of proven PAIRS, so a chain is only ever built from links that were
    each independently proven. That is not the transitive proximity chaining
    session 95 rejected, where three separate La Boca venues merged through
    links nothing had verified.
    """
    items = [(kind, e, _cpc.marker(e)) for kind, e in entries_in]
    items = [(k, e, p) for k, e, p in items if p]

    parent = {}

    def find(x):
        while parent.get(x, x) != x:
            parent[x] = parent.get(parent[x], parent[x])
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    by_id = {e["id"]: (k, e) for k, e, _ in items}
    proofs = {}
    for index, (kind, entry, point) in enumerate(items):
        parent.setdefault(entry["id"], entry["id"])
        for other_kind, other, other_point in items[index + 1:]:
            parent.setdefault(other["id"], other["id"])
            if haversine(point, other_point) > radius_m:
                continue
            ok, reason = _cpc.proven_same_venue(
                [(kind, entry), (other_kind, other)], ubiquitous)
            if ok:
                union(entry["id"], other["id"])
                proofs.setdefault(find(entry["id"]), reason)

    grouped = collections.defaultdict(list)
    for entry_id in parent:
        grouped[find(entry_id)].append(by_id[entry_id])

    out = {}
    for root, members in grouped.items():
        if len(members) < 2:
            continue
        point = _cpc.marker(members[0][1])
        out[(round(point[0], 7), round(point[1], 7))] = (members, proofs.get(root, "proven"))
    return out


def dedupe_across_signals(proposals):
    """A member may be claimed by exactly ONE place. Returns (kept, rejected).

    🔴 Whichever signal named it first wins, and the loser is REPORTED rather
    than dropped. Two signals proposing the same member is not a bug — the
    gazetteer and the proof tier legitimately see overlapping subjects — but
    minting both would put one entry in two places, which `validate-tours`
    rejects with "already belongs to place".
    """
    taken, kept, rejected = set(), [], []
    for item in proposals:
        if any(member in taken for member in item["members"]):
            item = dict(item, why="a member was already claimed by another signal")
            rejected.append(item)
            continue
        taken.update(item["members"])
        kept.append(item)
    return kept, rejected


def place_name(entries_only):
    """The place's editorial name: the shortest non-caption member title.

    ⚠️ A caption is long and a name is short, so the shortest title is almost
    always the venue ("Una Pizza Napoletana" over "This place is special
    📍@unapizzana"). `docs/places.md`: name it for the WHOLE, not a component.
    """
    stems = []
    for e in entries_only:
        stem = display_stem(e.get("title") or "").strip()
        # "Kossar's: How a New York Bagel Is Made" -> "Kossar's". An editorial
        # tail after a colon is a framing, and `docs/places.md` Rule 2 says a
        # framing never names the site.
        head = stem.split(":")[0].strip()
        if len(head) >= 3:
            stem = head
        if stem:
            stems.append(stem)
    return min(stems, key=len) if stems else "Unnamed place"


def propose(catalog, cache, features, *, max_move_m=MAX_MOVE_M):
    """Groups of entries that resolve to one Wikidata item. Returns (make, skip)."""
    rows = _sm.classify(catalog, cache, features)
    claimed = {t for p in (catalog.get("places") or []) for t in p.get("tourIds", [])}

    by_item = collections.defaultdict(list)
    for row in rows:
        if row["band"] == "CONFIRMS" and row["best"]:
            by_item[row["best"]["qid"]].append(row)

    make, skip = [], []
    for qid, group in sorted(by_item.items()):
        if len(group) < 2:
            continue
        titles = [r["entry"].get("title") or "" for r in group]
        anchor = group[0]["best"]
        point = (anchor["lat"], anchor["lon"])
        moves = [haversine(_sm.entry_marker(r["entry"]), point) for r in group]
        cities = [r["entry"].get("city") for r in group if r["entry"].get("city")]
        item = {
            "signal": "GAZETTEER", "qid": qid,
            "name": anchor["label"], "titles": titles,
            "city": cities[0] if cities else None,
            "lat": point[0], "lon": point[1],
            "members": [r["entry"]["id"] for r in group],
            "max_move_m": max(moves),
        }

        if any(m["entry"]["id"] in claimed for m in group):
            # Partially or fully placed already — joining an existing place is a
            # different operation, and one that changes a place people can see.
            item["why"] = "a member already belongs to a place"
            skip.append(item)
            continue
        reason = declined(titles)
        if reason:
            item["why"] = f"REFUSED — {reason}"       # 🔴 never silently minted
            skip.append(item)
            continue
        if max(moves) > max_move_m:
            item["why"] = f"a member would move {max(moves):.0f} m"
            skip.append(item)
            continue
        make.append(item)
    return make, skip


def apply(catalog, make):
    """Mint the places and move every member onto the shared point."""
    entries = {e["id"]: e for e in _sm.entries(catalog)}
    places = catalog.setdefault("places", [])
    existing = {p["id"] for p in places}
    minted = 0
    for item in make:
        pid = place_id(item["city"] or "", item["name"])
        if pid in existing:
            continue                                   # id collision: leave it
        for member in item["members"]:
            entry = entries[member]
            stops = entry.get("stops") or []
            target = next((s for s in stops if s.get("order") == 0), stops[0])
            target["latitude"] = item["lat"]
            target["longitude"] = item["lon"]
            # `Tour.coordinate` and the distance label read the CENTROID, not
            # stop 0 — #930 moved 26 coordinates and no centroids, leaving the
            # pin in one place and every distance in another.
            if "centroidLatitude" in entry:
                entry["centroidLatitude"] = item["lat"]
                entry["centroidLongitude"] = item["lon"]
        places.append({
            "id": pid, "name": item["name"], "description": None,
            "latitude": item["lat"], "longitude": item["lon"],
            "city": item["city"], "address": None,
            "heroImageURL": None, "additionalImageURLs": None,
            "tourIds": item["members"],
        })
        existing.add(pid)
        minted += 1
    # 🔴 DO NOT SORT `places`. An earlier version did, "for tidiness", and
    # reordering the 351 existing entries turned a 23-place addition into a
    # 4,048-insertion / 3,701-deletion diff that touched 1,570 coordinate
    # lines — indistinguishable, on review, from a change that had moved
    # content it should not have. New places are APPENDED; the array's order
    # is not meaningful to anything, and a reviewable diff is.
    return minted


def selftest():
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    check("slug is lowercase and hyphenated", slug("The Shard!") == "the-shard")
    check("🔴 slug does NOT transliterate — it must reproduce the live ids",
          slug("Chichén Itzá") == "chich-n-itz")
    check("place_id is stable",
          place_id("London", "The Shard") == place_id("London", "The Shard"))
    check("place_id differs by city",
          place_id("London", "X") != place_id("Paris", "X"))

    # 🔴 The guard the first live run demanded.
    luce = ["Bar Luce at Fondazione Prada", "Fondazione Prada"]
    check("🔴 an owner-declined pairing is REFUSED", declined(luce) is not None)
    check("an ordinary pairing is not refused",
          declined(["The Shard", "The Shard"]) is None)
    # Each of the three declined records is consulted, and each is tested
    # against a REAL entry in it — a mutation test showed that checking only
    # the pair list left the other two able to be deleted unnoticed.
    a_group = sorted(_menu.DECLINED_GROUPS)[0]
    check("🔴 a declined GROUP is refused", declined(list(a_group)) is not None)
    an_entry = sorted(_menu.DECLINED)[0]
    check("🔴 a declined ENTRY is refused",
          declined([an_entry, "Something Else Entirely"]) is not None)
    check("the declined record is actually loaded, not an empty set",
          len(_menu.DECLINED_GROUPS) > 10 and len(_menu.DECLINED_PAIRS) > 0)

    def entry(eid, title, lat, lon, city="X"):
        return {"id": eid, "title": title, "city": city, "kind": "single",
                "stops": [{"order": 0, "latitude": lat, "longitude": lon}]}

    cat = {"tours": [entry("a", "The Shard", 51.5045, -0.0865),
                     entry("b", "The Shard", 51.5046, -0.0866)],
           "linkPins": [], "places": []}
    # 🔴 The digest is not decoration. `spine-match.classify` bands a record
    # STALE when `ask_digest(title, at, bound_km)` does not match the stored
    # one, and a fixture with no digest bands STALE rather than CONFIRMS — so
    # `propose` sees no group at all and this selftest died with an IndexError
    # instead of a verdict. That is exactly what happened when the STALE band
    # was added on 2026-09-21: nothing noticed, because this file's selftest
    # is not run in CI. It is now.
    cache = {eid: {"candidates": [{"qid": "Q18536", "label": "The Shard",
                                   "lat": 51.5045, "lon": -0.0865,
                                   "distance_m": d, "sitelinks": 50}],
                   "bound_km": 100.0}
             for eid, d in (("a", 5.0), ("b", 12.0))}
    for eid, rec in cache.items():
        of = next(e for e in cat["tours"] if e["id"] == eid)
        rec["digest"] = _sm.ask_digest(of.get("title"), _sm.entry_marker(of),
                                       rec["bound_km"])
    make, skip = propose(cat, cache, {})
    check("two entries on one item propose a place", len(make) == 1)
    # ⚠️ Prove the fixture is LIVE: strip the digest and the group must vanish.
    # A fixture that silently stops producing a group is how this selftest
    # spent a day raising IndexError instead of a verdict.
    stale_cache = {eid: dict(rec, digest="not-the-digest") for eid, rec in cache.items()}
    check("🔴 the fixture is live — a stale digest makes the group disappear",
          propose(cat, stale_cache, {})[0] == [])
    check("the proposal carries both members", len(make[0]["members"]) == 2)

    # 🔴 A proven group may span up to TIGHT_M, so the reported move must be
    # the real one. This was hardcoded to 0.0 and two entries moved anyway.
    spread = {"tours": [entry("p", "Same Pub", 51.50000, -0.12000),
                        entry("q", "Same Pub", 51.50015, -0.12000)],
              "linkPins": [], "places": []}
    spread_make, _ = propose_proven(spread)
    check("🔴 a proven group reports the distance it will actually move a member",
          spread_make and spread_make[0]["max_move_m"] > 10.0)

    minted = apply(cat, make)
    check("apply mints exactly one place", minted == 1 and len(cat["places"]) == 1)
    moved = [s["latitude"] for e in cat["tours"] for s in e["stops"]]
    check("🔴 apply MOVES every member onto the shared point",
          all(abs(v - 51.5045) < 1e-9 for v in moved))
    check("the place carries the gazetteer coordinate",
          abs(cat["places"][0]["latitude"] - 51.5045) < 1e-9)
    check("apply is idempotent", apply(cat, make) == 0)

    cat2 = json.loads(json.dumps(cat)); cat2["places"] = []
    cat2["tours"][1]["stops"][0]["latitude"] = 51.5200      # ~1.7 km away
    cache2 = json.loads(json.dumps(cache))
    # ⚠️ Moving the entry invalidates its cached lookup — that is the STALE
    # guard doing its job, not a problem to route around. A real run refreshes
    # the cache after a move, so the fixture does too; without this the group
    # vanishes as STALE and this check would pass for the wrong reason.
    for eid, rec in cache2.items():
        of = next(e for e in cat2["tours"] if e["id"] == eid)
        rec["digest"] = _sm.ask_digest(of.get("title"), _sm.entry_marker(of),
                                       rec["bound_km"])
    make2, skip2 = propose(cat2, cache2, {}, max_move_m=120.0)
    check("🔴 a group that would drag a member too far is SKIPPED, not minted",
          make2 == [] and len(skip2) == 1 and "would move" in skip2[0]["why"])

    # --- signal A: proof drives grouping -----------------------------------
    def pin(pid, title, lat, lon, author=None, desc=""):
        return {"id": pid, "title": title, "city": "New York", "kind": "link",
                "sourceAuthor": author, "shortDescription": desc,
                "stops": [{"order": 0, "latitude": lat, "longitude": lon}]}

    # 🔴 The Una Pizza case. Saigon Social sits 23.8 m away and is a DIFFERENT
    # restaurant; an anchor-first cluster swallowed Una Pizza into it, the pair
    # failed proof, and the true pair never formed. Proof-first cannot.
    kossar = {"tours": [], "places": [], "linkPins": [
        pin("u1", "Una Pizza Napoletana", 40.72100, -73.98800, "@a",
            "the best 📍@unapizzanapoletana"),
        pin("u2", "This place is special 📍@unapizzanapoletana", 40.72111, -73.98800, "@b"),
        pin("s1", "Saigon Social", 40.72120, -73.98800, "@c", "📍@saigonsocialnyc"),
    ]}
    made, held = propose_proven(kossar)
    names = {i["name"] for i in made}
    check("🔴 proof-first pairs Una Pizza with its caption, not its neighbour",
          names == {"Una Pizza Napoletana"})
    check("🔴 and the unrelated neighbour 23.8 m away is NOT absorbed",
          all("Saigon Social" not in t for i in made for t in i["titles"]))

    check("a shared venue handle is proof",
          made and "unapizzanapoletana" in made[0]["proof"])
    # 🔴 This used to assert `max_move_m == 0.0` and so could never have caught
    # the hardcoded value it was reading. The Una Pizza fixture's members sit
    # 12.4 m apart, and minting really does pull one onto the other.
    check("🔴 a PROVEN group reports the move it will actually make",
          made and 5.0 < made[0]["max_move_m"] < 25.0)

    # 🔴 The creator's own handle must never be the proof, or every pin by one
    # food reviewer would pair with every other.
    same_author = {"tours": [], "places": [], "linkPins": [
        pin("c1", "Some Diner", 40.75, -73.98, "@jacksdiningroom", "📍@jacksdiningroom"),
        pin("c2", "Another Diner", 40.75001, -73.98, "@jacksdiningroom", "📍@jacksdiningroom"),
    ]}
    check("🔴 the CREATOR's own handle is not proof",
          propose_proven(same_author)[0] == [])

    # Proximity alone is never proof.
    bare = {"tours": [], "places": [], "linkPins": [
        pin("b1", "Alpha Bar", 40.76, -73.98, "@x"),
        pin("b2", "Beta Cafe", 40.760005, -73.98, "@y"),
    ]}
    check("🔴 two different venues on one point are NOT proposed",
          propose_proven(bare)[0] == [])

    check("place_name drops an editorial tail after a colon",
          place_name([{"title": "Kossar's: How a New York Bagel Is Made"},
                      {"title": "Someone fact check my bialy claim"}]) == "Kossar's")
    check("place_name keeps a plain venue name",
          place_name([{"title": "Una Pizza Napoletana"},
                      {"title": "This place is special"}]) == "Una Pizza Napoletana")

    far_apart = {"tours": [], "places": [], "linkPins": [
        pin("f1", "Same Venue", 40.77, -73.98, "@x", "📍@samevenue"),
        pin("f2", "Same Venue", 40.7710, -73.98, "@y", "📍@samevenue"),
    ]}
    check("🔴 proven but 111 m apart is outside the radius, so not proposed",
          propose_proven(far_apart)[0] == [])

    # 🔴 A declined pair that IS coincident and IS proven must still be refused.
    # This is the Bar Luce shape reaching signal A rather than signal B.
    a_pair = sorted(_menu.DECLINED_PAIRS)[0]
    t1, t2 = sorted(a_pair)
    dpair = {"tours": [], "places": [], "linkPins": [
        pin("d1", t1, 40.78, -73.98, "@x", f"see {t2}"),
        pin("d2", t2, 40.780005, -73.98, "@y", f"see {t1}"),
    ]}
    made_d, held_d = propose_proven(dpair)
    check("🔴 signal A refuses an owner-declined pair, even when proven",
          made_d == [] and any("REFUSED" in i["why"] for i in held_d))

    placed = {"tours": [], "linkPins": [
        pin("p1", "Shared Venue", 40.79, -73.98, "@x", "📍@sharedvenue"),
        pin("p2", "Shared Venue", 40.790005, -73.98, "@y", "📍@sharedvenue"),
    ], "places": [{"id": "zz", "name": "X", "latitude": 0, "longitude": 0,
                   "tourIds": ["p1"]}]}
    check("🔴 signal A skips a group whose member is already placed",
          propose_proven(placed)[0] == [])

    lone = {"tours": [], "places": [], "linkPins": [
        pin("l1", "Solo Venue", 40.80, -73.98, "@x", "📍@solovenue")]}
    check("🔴 a lone entry never becomes a place", propose_proven(lone)[0] == [])
    # ⚠️ Tested on `proven_groups` DIRECTLY as well. `propose_proven` also
    # checks the minimum, so breaking either one alone is masked by the other
    # and a test that only goes through the outer function cannot tell.
    check("🔴 proven_groups itself never emits a group of one",
          proven_groups(_cpc.entries(lone), TIGHT_M) == {})

    check("🔴 place_name picks the SHORTEST name, not the first",
          place_name([{"title": "A Very Long Descriptive Caption Indeed"},
                      {"title": "Brief"}]) == "Brief")

    kept, rejected = dedupe_across_signals([
        {"signal": "PROVEN", "members": ["m1", "m2"], "name": "first"},
        {"signal": "GAZETTEER", "members": ["m2", "m3"], "name": "second"},
        {"signal": "GAZETTEER", "members": ["m4", "m5"], "name": "third"},
    ])
    check("🔴 a member claimed twice is minted ONCE",
          [i["name"] for i in kept] == ["first", "third"])
    check("...and the loser is reported, not dropped",
          len(rejected) == 1 and "already claimed" in rejected[0]["why"])

    cat3 = json.loads(json.dumps(cat))
    check("an already-placed member is skipped",
          propose(cat3, cache, {})[0] == [])

    # 🔴 A place needs TWO members. validate-tours errors below that, and a
    # one-member "place" renders a count badge reading "1".
    solo = {"tours": [entry("s1", "Lone Tower", 1.0, 2.0)], "linkPins": [],
            "places": []}
    solo_cache = {"s1": {"candidates": [{"qid": "Q1", "label": "Lone Tower",
                                         "lat": 1.0, "lon": 2.0,
                                         "distance_m": 4.0, "sitelinks": 3}]}}
    check("🔴 a single entry on an item proposes NOTHING",
          propose(solo, solo_cache, {})[0] == [])

    # 🔴 Only a CONFIRMED match may group. A far match means we are not sure
    # the entry is even at that subject, so it cannot decide identity.
    # ⚠️ The match sits in the REVIEW band (200 m), and `max_move_m` is raised
    # so the move guard CANNOT also reject it. With both able to fire, deleting
    # the band check changed nothing and this test passed against a mutant.
    far = {"tours": [entry("f1", "Far Hall", 1.0, 2.0),
                     entry("f2", "Far Hall", 1.0, 2.0)],
           "linkPins": [], "places": []}
    far_cache = {eid: {"candidates": [{"qid": "Q2", "label": "Far Hall",
                                       "lat": 1.0018, "lon": 2.0,
                                       "distance_m": 200.0, "sitelinks": 3}]}
                 for eid in ("f1", "f2")}
    check("🔴 an UNCONFIRMED match never groups, even when nothing else stops it",
          propose(far, far_cache, {}, max_move_m=1000.0)[0] == [])

    total = 36
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--features", default=FEATURES)
    ap.add_argument("--max-move", type=float, default=MAX_MOVE_M)
    ap.add_argument("--only", choices=["PROVEN", "GAZETTEER"],
                    help="mint only this signal. 🔴 PROVEN groups are already "
                         "coincident so minting moves nobody; GAZETTEER MOVES "
                         "members onto a gazetteer point, which is a coordinate "
                         "change and a separate decision.")
    ap.add_argument("--apply", action="store_true",
                    help="write the places into the catalogue (default: propose only)")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        for path in (a.cache, a.features):
            if not os.path.exists(path):
                print(f"COULD NOT VERIFY — missing {path}")
                return 2
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        with gzip.open(a.cache, "rt", encoding="utf-8") as fh:
            cache = json.load(fh)
        with gzip.open(a.features, "rt", encoding="utf-8") as fh:
            features = json.load(fh)

        # 🔴 SIGNAL ORDER IS NOT A QUALITY RANKING. PROVEN runs first only
        # because a coincident group moves nobody, so it cannot be spoiled by a
        # gazetteer group claiming a member first. Neither signal subsumes the
        # other: Grace Farms' pin sat 6.1 km from Grace Farms (no coordinate
        # test reaches it) and Kossar's is in no gazetteer at all.
        make_a, skip_a = propose_proven(catalog, max_move_m=a.max_move)
        make_b, skip_b = propose(catalog, cache, features, max_move_m=a.max_move)

        make, extra = dedupe_across_signals(make_a + make_b)
        skip = list(skip_a) + list(skip_b) + extra

        if a.only:
            before = len(make)
            make = [i for i in make if i["signal"] == a.only]
            print(f"--only {a.only}: {len(make)} of {before} proposal(s) kept\n")

        by_signal = collections.Counter(i["signal"] for i in make)
        print(f"{len(make)} place(s) to create "
              f"({by_signal['PROVEN']} proven-coincident, {by_signal['GAZETTEER']} gazetteer) "
              f"· {len(skip)} skipped\n")
        for item in sorted(make, key=lambda i: -len(i["members"])):
            print(f"  {len(item['members'])}x  {item['signal'][:9]:9} {item['name'][:30]:30} "
                  f"{(item['city'] or '')[:13]:13} move<={item['max_move_m']:.0f} m"
                  + (f"  [{item['proof']}]" if item.get("proof") else ""))
            for title in item["titles"]:
                print(f"        · {title[:60]}")
        refused = [i for i in skip if i["why"].startswith("REFUSED")]
        if refused:
            print(f"\n🔴 REFUSED — the owner has already decided these:")
            for item in refused:
                print(f"  {item['name'][:34]:34} {item['why']}")

        ask = [i for i in skip if i["why"].startswith("coincident but NOT proven")]
        if ask:
            print(f"\n{len(ask)} coincident group(s) with NO second signal — these need you:")
            for item in ask[:15]:
                print(f"  {item['name'][:34]:34} {(item['city'] or '')[:14]}")
                for t in item["titles"][:3]:
                    print(f"        · {t[:58]}")

        if not a.apply:
            print("\n(proposal only — pass --apply to write them)")
            return 1 if make else 0

        minted = apply(catalog, make)
        with open(a.catalog, "w", encoding="utf-8") as fh:
            json.dump(catalog, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print(f"\nOK — created {minted} place(s); run validate-tours next")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())

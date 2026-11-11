#!/usr/bin/env python3
"""Owner-approved places for the Washington DC launch (2026-11-11: "make the 3 places").

National Archives and Old Post Office are new; Union Station already existed (two creator pins),
so the DC tour joins it. Every move goes through join-places.py's own apply_join. Ids follow
docs/places.md: uuid5(NAMESPACE_URL, "atlas-place:<slug(city)>:<slug(name)>").
"""
import importlib.util, json, re, uuid

P = "TRAVEL GUIDED TOUR/Resources/Tours.json"
B = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/"
spec = importlib.util.spec_from_file_location("jp", "scripts/join-places.py")
jp = importlib.util.module_from_spec(spec); spec.loader.exec_module(jp)
slug = lambda s: re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
pid = lambda name: str(uuid.uuid5(uuid.NAMESPACE_URL, f"atlas-place:washington:{slug(name)}"))

doc = json.load(open(P, encoding="utf-8"))
entries = {e["id"]: e for e in doc["tours"] + doc["linkPins"]}
places = {p["id"]: p for p in doc["places"]}

NEW = [  # name, point-from (the member whose point is the building's own), members, address, description, hero
    ("National Archives", "2ed82217-f8ff-5103-947a-edc78a52a601",
     ["2ed82217-f8ff-5103-947a-edc78a52a601", "89C85E50-E043-5277-B5C5-5D3C447B707C"],
     "700 Pennsylvania Avenue NW, Washington, DC",
     "John Russell Pope's temple between Constitution and Pennsylvania Avenues, finished in 1935 to hold the "
     "nation's records. The Declaration of Independence, the Constitution and the Bill of Rights are on show "
     "under the dome of its Rotunda.", "national-archives-dc_hero.webp"),
    ("Old Post Office", "b175bd46-1ca3-55c0-bcc8-2d1db230dd22",
     ["b175bd46-1ca3-55c0-bcc8-2d1db230dd22", "687E8957-6DE8-5FC3-BC0A-AA3A98F514FC"],
     "1100 Pennsylvania Avenue NW, Washington, DC",
     "Willoughby J. Edbrooke's granite Romanesque block on Pennsylvania Avenue, finished in 1899 as the city's "
     "main post office and saved from demolition in the 1970s. The rest of the building is now a hotel; the "
     "clock tower's observation deck is run by the National Park Service.", "old-post-office-dc_hero.webp"),
]
for name, frm, members, address, desc, hero in NEW:
    i = pid(name)
    assert i not in places, f"{name} already exists"
    s = jp.marker_stop(entries[frm])
    place = {"id": i, "name": name, "description": desc, "latitude": s["latitude"], "longitude": s["longitude"],
             "city": "Washington", "address": address, "heroImageURL": B + hero, "additionalImageURLs": None,
             "tourIds": []}
    doc["places"].append(place)
    for m in members:
        assert not any(m in p.get("tourIds", []) for p in doc["places"]), f"{m} already in a place"
        print(f"{name:20} {entries[m]['title'][:40]:40} moved {jp.apply_join(doc, entries[m], place):5.1f} m")

# Union Station: the place exists (Union Station + Continental Club pins, on OSM's station node). Join the tour,
# and fill the description, address and hero the place was created without.
us = places[pid("Union Station")]
assert us["city"] == "Washington"
print(f"{'Union Station':20} {'Union Station (tour)':40} moved "
      f"{jp.apply_join(doc, entries['93ac542c-12ad-51b8-b5f3-564e97cdcd2a'], us):5.1f} m")
us["description"] = us["description"] or (
    "Daniel Burnham's Beaux-Arts station at the foot of Capitol Hill, opened in 1907. Its triple-arched front "
    "borrows from Rome's triumphal arches, and its main hall from the Baths of Diocletian.")
us["address"] = us["address"] or "50 Massachusetts Avenue NE, Washington, DC"
us["heroImageURL"] = us["heroImageURL"] or B + "washington-union-station_hero.webp"

with open(P, "w", encoding="utf-8") as fh:
    json.dump(doc, fh, ensure_ascii=False, indent=2); fh.write("\n")

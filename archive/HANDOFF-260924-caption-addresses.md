# Handoff 2026-09-24: caption-address sweep, 33 pins moved

Follows `HANDOFF-260923-caption-names.md`.

## What was checked
The link pins that neither Wikidata (spine UNMATCHED) nor the 2026-09-23 OSM name sweep had
confirmed: **1,722**. Of those, **352** carry a street address in their own caption. Each address was
geocoded at house level and compared with the pin. Record: `checks/caption-address-sweep-260924.json`.

| | |
|---|---|
| first pass (script: GSI for Japanese script, Photon house-number hits) | 106 geocoded; 66 within 50 m; **4 moved** |
| second pass (three reviewers; GSI, Hong Kong ALS, NYC Geosearch, US Census, Photon) | 246 read: 157 OK, 24 MOVE, 24 UNSURE, 39 no real address, 2 not geocodable; **29 moved** (24 MOVE + 2 named-POI UNSUREs + 3 Prague statues and one McDonald's whose caption named the subject) |

**The move rule:** a house-level geocode of the caption's own address, or a same-name OSM point.
Never a street midpoint, a block, a postcode centroid or a district node.

Largest moves: Ng Kam Chun stamps **18 km** (Tai Po → Man Wa Lane, Sheung Wan), Maoao station
8 km, Mr. Kanso 4.3 km (the Ueno branch the caption names; it is a chain), Yu Zai Fan Shu 3.4 km,
Cafe Fang Studio 1.7 km, Juqi NY 1.1 km, Saengchai Phochana 1 km, World's Largest McDonald's
905 m. **A recurring cause: the pin sits exactly on a district/admin node or a street midpoint** —
Gongliao district office, Ruifang district, the 迪化街商圈 node, Gamcheon Culture Village — i.e.
it was geocoded from the area name, not the venue.

## Left for the owner
- **Sky Coffee (Miami):** the caption's 1420 SW 1st Ct is Brickell; the pin sits on a Sky Coffee
  at 1825 Biscayne Blvd; Yelp now says 710 Brickell Ave. Which site?
- **Bloomsbury Tavern** (781 m, postcode centroid only), **Sushi Ishimatsu** (pin on the Honen-in
  temple node), **Sushi Punch** (block level), **Daljib, Gamcheon** (pin on the village node),
  **Uncle Liu's** (1036/24 Sukhumvit, would not geocode), **V-Sign Hand Sculpture** (caption says in
  front of the Russian Embassy; pin 1–1.5 km from it), **Chuka Soba Aoba** (reviewer's memory only).

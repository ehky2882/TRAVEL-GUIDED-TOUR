# Two coordinate pairs need per-building points (Aranya + Changshou Village)

_opened 2026-09-22 · clear with `git rm status/owner/china-pin-coordinates.md`_

Four pins sit on **two** shared coordinates. Each pair is two genuinely different
buildings, so the shared point is a geocoding artefact — but **no source I can
reach gives a per-building coordinate**, and inventing a separation would put a
geofence in the wrong place while looking precise.

| pair | shared coordinate | what the point actually is |
|---|---|---|
| `Seashore Library` + `Chapel of Music` | `39.6561544, 119.3169543` | `阿那亚三期` (Aranya Phase 3), Changli County — **inside the right compound** |
| `Long Ma She` + `Soft Square` | `22.6657039, 114.3607473` | Jiangling Road, Maluan Sub-district, Pingshan District, Shenzhen |

🔴 **The locality is right in both cases; only the precision is wrong.** These are
not misplaced pins.

All four are `@archimarathon` TikTok posts. Both pairs are two separate buildings:

* **Seashore Library** (Vector Architects, 2015) — on the sand, the building
  closest to the sea, no paved path. **Chapel of Music** (Vector Architects,
  2023) — inland, in the Aranya community proper.
* **Long Ma She** 龙马社 and **Soft Square** (ZXD Architects) — different
  buildings, different architects, both in Changshou Village.

## What was tried

| route | result |
|---|---|
| Nominatim / OSM, English **and** Chinese (`三联海边图书馆`, `龙马社 长寿村`) | no results — OSM has no coverage of these |
| Wikidata entity search | HTTP **429**, so retried via SPARQL |
| Wikidata SPARQL bounding-box over the whole Aranya area | **4 items, none of them these buildings** |
| Web search ×2, incl. explicitly for coordinates | architecture press only; ArchDaily's location field says just *"Qinhuangdao Shi, China"* |
| Overpass | blocked by the egress proxy |

⚠️ **And a hazard if a coordinate is taken from a Chinese map:** Baidu and Amap
publish **GCJ-02 / BD-09**, which are offset from WGS-84 by **100–700 m** in
China. A number copied from one of those is wrong by more than the gap we are
trying to create. Google Maps' satellite layer is WGS-84 and is safe; so is
Apple Maps.

## What would settle it

The quickest unblock: open each building on Google or Apple Maps, drop a pin on
it, and paste the two lat/long pairs. Each pair takes a minute and is
authoritative. Alternatively, if the `@archimarathon` posts carry a location
tag, that would do it — the `sourceURL` for each is in the catalogue.

Until then the pins stay where they are, and `check-place-candidates.py` will
keep reporting both as `EXACT · ASK`, which is correct behaviour rather than
noise.

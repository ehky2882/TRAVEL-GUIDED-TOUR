# spine-match.py was reporting stale distances: all nine coordinates fixed overnight still read as broken (Belgrade Tower 2,329 m out while sitting on Wikidata's own point). The digest that invalidates the cache was consulted by the fetcher only. Such rows are now STALE with no distance and exit 2; publish-catalog.yml refreshes the cache on every content merge. PR open.

_2026-09-21 06:29 UTC · branch `overnight-audit-3`_

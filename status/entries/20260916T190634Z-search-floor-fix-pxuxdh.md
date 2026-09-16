# Search floor bug found on build 166: scoreFloor was 0.45, copied from RELATED_FLOOR (a tour-to-tour threshold) and applied to query-to-document scoring. Silenced 3 of 9 natural queries; owner's 'quiet garden away' topped 0.4498 and missed by 0.0002. Lowered to 0.35, measured both ways - nonsense still returns nothing. Needs a NEW BUILD (Swift constant), contrary to what the owner was told. Also found: two identical 'Glasshouse Theatre' Brisbane link pins on the same coordinate - owner decision, not deleted.

_2026-09-16 19:06 UTC · branch `search-floor-fix-pxuxdh`_

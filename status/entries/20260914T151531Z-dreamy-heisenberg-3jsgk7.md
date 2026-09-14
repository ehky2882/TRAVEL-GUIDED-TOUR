# PR #893: 72 link pins minted (2 Budapest + 70 Tokyo/Osaka/Kyoto byFood-network, owner-approved ad-policy call)

_2026-09-14 15:15 UTC · branch `dreamy-heisenberg-3jsgk7`_

Owner asked for a triage of 86 links from two creators before minting anything
(published as an artifact table); then approved both the 2 clean Budapest pins
and the ad-policy call on the 70-post `@japanbyfood`-network cluster.

Minted 72 link pins (2 kristofooro + 70 japanbyfood-network) via
`make-link-pin.py` in 6 category/tag groups, merged with `merge-link-pins.py`,
validated clean (0 errors, 5 pre-existing unrelated warnings). Caught and fixed
a hero-filename collision between two identically-worded captions before
merging. Heroes pushed to `gh-pages` via plumbing.

**30 of the 70 japanbyfood pins are neighborhood-level coordinates, not exact
addresses** — the caption named the restaurant but gave no street address.
Listed in PR #893's description; worth a precision pass later.

Left out: the Budapest Metro Line 1 post (a route, not a point — owner to pick
a station or skip) and 14 other posts with no locatable venue (insufficient
caption data, ambiguous chain branch, no fixed address, or already pinned).

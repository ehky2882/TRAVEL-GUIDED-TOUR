# Kogane Sushi / Matsushima Izakaya pins share a coordinate (PR #938)

_opened 2026-09-16 · clear with `git rm status/owner/kogane-matsushima-pin-precision.md`_

# Kogane Sushi / Matsushima Izakaya pins share a coordinate (PR #938)

Two of the 38 pins added in PR #938 landed on the exact same point:
35.7285534, 139.7299292.

- **Kogane Sushi** ("POV: Eating Sushi Alone at a 90-Year-Old Hidden
  Restaurant") — address given was 3-54-6 Minamiotsuka, Toshima, Tokyo 170-0005
- **Matsushima Izakaya** ("POV: Eating at 85 year old Chef restaurant... with
  no voice") — address given was 1-1-51 Minamiotsuka, Toshima, Tokyo 170-0005

Both are in the same postal code (170-0005, Minami-Otsuka, Toshima) but I
could not resolve either to a distinct chome/block-level point — geocoding
kept failing or returning nothing for the specific chome, so both fell back
to the postal-code-wide centroid. `check-place-candidates.py` correctly flags
this as an EXACT coincident pair.

**These are NOT a place** — two unrelated restaurants, not one site
(`docs/places.md`'s co-location-isn't-identity rule). This is the same class
of coordinate-precision gap already open in
`ginza-shimokitazawa-pin-precision.md`: it needs a real address per venue
(TikTok's own comment section, Google Maps, or you), not another automated
guess from me.

**What I did NOT do:** create a place page, or guess a split coordinate to
make the collision look resolved.

**Ask:** same as the other open item — worth a batch precision pass across
both, or fine to leave until then?

_opened 2026-09-16 · clear with `git rm status/owner/kogane-matsushima-pin-precision.md`_

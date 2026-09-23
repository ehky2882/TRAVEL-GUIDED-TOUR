# 55 @preetigills link pins (Paris + France + California)

_2026-09-23 10:45 UTC · branch `beautiful-lamport-po8eh6`_

**55 link pins from a new creator, Instagram @preetigills** (Paris food & travel; also Normandy, Brittany, Saint-Émilion, Versailles and four in California). Triaged from 65 links; the owner skipped 10 (brand collabs, a duplicate Landline post, an interview, an unidentifiable bakery, Galerie Vivienne, Jinchan's two locations).

- Every venue was resolved from the Instagram tag in its caption to its own site/listing, then geocoded to street-number precision; the Chalet des Îles uses the restaurant's own published coordinate.
- Café de la Paix, Musée Carnavalet and Le Relais de Venise sit 0–21 m from existing entries. **Owner decision: keep them as separate entries — do not offer them as places again.**
- ⚠️ Instagram's `/embed` page returned NO data for any of these posts, so `make-link-pin.py`/`triage-account.py` could not read them. Metadata came from the post page served to a `facebookexternalhit` user agent, and heroes from `/p/<code>/media/?size=l` (720×1280). Two posts 404 there and used the 640 square cover, which carries a play-button overlay (Bubble Bliss, Le Repaire de Bacchus).
- Heroes: 55 added to gh-pages in one commit (`e0050771`), additions only.

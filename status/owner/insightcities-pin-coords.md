# 6 new link-pin coordinates need a map check

_opened 2026-09-13 · clear with `git rm status/owner/insightcities-pin-coords.md`_

From PR #867 (52 @insightcities link pins). These 6 pins were minted with
my best-knowledge coordinate estimate, not a verified GPS/address lookup
(Instagram's oEmbed carries no location data):

- Lok Hau Fook Terrazzo Column (Kowloon City) — approximate district
  center; exact restaurant address unconfirmed
- Corso Karlín (Prague) — approximate Karlín block
- Fragment / Lilith sculpture (Prague) — approximate Karlín block
- Masaryčka (Prague) — approximate, near Masaryk Station
- YMCA Palace Paternoster (Prague) — approximate address
- Brummel House (Plzeň) — exact address unconfirmed

If any of these turn out to be off, the fix is a plain coordinate edit
in Tours.json (no filename/image concerns — these are link pins, not
tour images), pinned to the same `id` each already has.

Clear with `git rm status/owner/insightcities-pin-coords.md` once
checked (or after the coordinates are corrected).

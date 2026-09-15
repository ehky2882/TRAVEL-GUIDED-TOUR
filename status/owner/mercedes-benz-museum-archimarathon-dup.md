# Mercedes-Benz Museum: two pins on the exact same coordinate

_opened 2026-09-15 · clear with `git rm status/owner/mercedes-benz-museum-archimarathon-dup.md`_

`check-place-candidates.py`, run right after PR #910 merged, found this
batch's new Mercedes-Benz Museum pin (Instagram, @archimarathon) sitting on
the EXACT same coordinate (48.7882006, 9.2339924) as an existing pin for the
same museum (TikTok, also @archimarathon, posted 2026-09-03).

Both are genuine posts about the real building — this isn't a geocoding
error, the museum really is at that one point. What I did NOT do: create a
place page or merge/delete either pin. That's your call per docs/places.md
(two entries about one site is the textbook "place" case, but you may also
just want to keep both as separate creator posts).

Also worth knowing: I had to rename this batch's hero file to
`mercedes-benz-museum-archimarathon-2_hero.webp` because the auto-derived
filename collided byte-for-byte with the existing pin's hero (same
subject text + same handle). That part is fixed; the duplicate-place
question is still open.

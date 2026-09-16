# Sandwich Club now sits on an existing pin (Live Haus), same underlying issue on the other side

_opened 2026-09-16 · clear with `git rm status/owner/sandwich-club-live-haus-collision.md`_

Re-geocoding Sandwich Club (2-12-2 Kitazawa) moved it off the old
4-pin Shimokitazawa stack -- but its best available point (a
neighbourhood-level centroid, no closer data found) happens to land
exactly on an existing pin, Live Haus (@tokyo24h.journey), which was
itself never given a precise address and geocoded to the same fallback.
Not something I caused by picking a bad query; both pins are independently
imprecise and coincide by chance. Fixing it for good means finding Live
Haus's own real address too, which is outside what I was asked to look at
this pass.

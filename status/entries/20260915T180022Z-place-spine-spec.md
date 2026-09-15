# Place spine spec written — the one item that blocks creator outreach

_2026-09-15 18:00 UTC · branch `place-spine-spec`_

`docs/place-spine-design.md` — **spec only, nothing built.** The owner asked what remains before
approaching content creators; re-derived rather than quoted, the answer is this and essentially
only this.

**The case, measured:** `make-link-pin.py` has **no geocoder** (`grep -c "nominatim\|geocod"` → 0),
so every pin's coordinate is typed by hand, and `slug`/`title` collapse to batch-wide at
`make-link-pin.py:1117-1118` (a 38-pin batch has run as 25 invocations). At 100k pins the typing is
~3,300 hours, and it is the step that goes wrong most often.

🔴 **Verified today, and worse than the friction: link-pin coordinates are audited by NOTHING.**
`check-coordinates.py:255` `from_catalog` reads `d["tours"]` (L263) and matches
`Atlas Studio {CODE}` (L258) — pins live in a sibling `linkPins` array and no pinned creator has
that maker name, so **no pin can ever match it.** All 2,318 pins are unaudited as a set; every
correction so far was found by the owner on the map or by reading entries one at a time. A
`--pins` mode is step 2 of the spec and is the first real payoff.

Scope is staged off the real distribution — **580 city/country pairs**, but New York 536 +
Hong Kong 280 + London 222 + Tokyo 203 + Toronto 101 = **1,342 of ~3,900 entries in five cities**.

⚠️ **The auto-created-places decision is deliberately NOT asked for yet.** `Place.swift:18` forbids
it, and the human rule is demonstrably working: of 19 coordinate groups over `maxStacked`, **18 are
already fully collapsed into a place page** and the 19th is 4-of-5. It becomes a real question only
when a spine is minting places in bulk.

---

🔴 **RETRACTION recorded in the spec itself.** An earlier audit of mine claimed **~32 link pins were
invisible on the map**, truncated by `TourSetMap.maxStacked = 3`. Re-derived on today's catalogue
that is **false** — 18 of the 19 groups are already places, and the true residue is **2 pins**
(Strahov Library, 4 of 5 members). The error was counting raw coordinate groups without checking
the mechanism built to solve them, and a follow-up check then looked for a `placeId` field on pins
**which does not exist** (membership is `place.tourIds`), nearly producing the opposite wrong
answer. Only the contradiction between the two checks exposed it.

⚠️ **Second retraction of the day**, after the stop-reorder crash that came from this session's own
test harness. Both were "a check I designed myself said so". The rule now in the spec:
**a finding that contradicts a mechanism the repo already built is probably wrong about the
mechanism.**

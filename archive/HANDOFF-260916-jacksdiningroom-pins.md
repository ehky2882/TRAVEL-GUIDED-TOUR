# HANDOFF — 2026-09-16 — @jacksdiningroom link pins

**128 link pins added, [#959](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/959), merged.**

## What the owner asked for

A pile of 135 links (134 Instagram reels + 1 TikTok short link), with instructions to
pull each post's caption via oEmbed, reverse-geocode to figure out what's actually
there, search the shop/restaurant's own IG account from the caption when needed, and
propose subject/category/tags per pin — triage first, add nothing until told to.

## Triage

`triage-account.py` flagged 129 SINGLE, 1 LIVE (already pinned), 4 THIN, 1 DEAD. Reading
every caption by hand (per the tool's own warning that flags are hints, not verdicts)
reclassified 3 of the 4 THIN as usable — their location signal was an `@handle` or a
hashtag (`#goldendiner`) rather than the `📍` marker the regex looks for. All 134
Instagram links turned out to be one creator, **@jacksdiningroom**, a food-review
account posting one restaurant per reel. The lone TikTok link was a *different*,
unrelated creator — **@ninosbuildings**, the architecture account whose 65-pin batch
had merged earlier the same day in #940 — with no venue named in the caption; the
thumbnail (a brick-arched gallery balcony with a bronze figurative sculpture) was a
strong visual match for the Pinacoteca de São Paulo, reported to the owner as an
unconfirmed lead rather than minted on a guess. The owner confirmed it directly.

Most captions named the venue explicitly or via its own `@handle`; for the ones that
didn't (mostly LA and Paris posts naming only a neighbourhood), the caption's IG handle
was resolved to the actual business name and address by searching it — turning a
handle like `@bsdiningexperiencesc` into "an itinerant BBQ caterer/festival act, no
fixed venue" (skip), and `@nadcburger` into "NADC Burger, 25 Cleveland Pl, NYC" (pin).

**Skipped (4):** one already pinned (Joe's Stone Crab), one video about Adam Perry
Lang's rotating BBQ pop-ups with no fixed location for *that* post, two posts naming no
venue at all. **Owner-flagged (1):** Stella, West Hollywood, dropped after a source
suggested it had paused operations. **Duplicates (3 pairs):** the creator filmed Le
Coupe, I' Girone De' Ghiotti, and Divorare each twice; owner picked one video per venue.
**Exploded (1 → 2):** a Paris post named both Chez Janou and Le Bon George — two pins,
sharing one hero image since it's one post/one thumbnail.

## Geocoding

Nominatim by name resolved about half the venues on the first pass; the rest needed a
real street address (searched via WebSearch, since named-POI search is much flakier
than address search on Nominatim, matching the documented lesson). Every result was
scored to prefer a named-amenity match and a city match over a bare address hit, then
checked against a per-city bounding box — this caught a real bug: **Salt Hank's**
(280 Bleecker St, West Village) first resolved to a same-numbered **Bleecker Street in
Ridgewood, Brooklyn**, 8 km away, because Nominatim's first hit for the bare address was
the wrong borough's street of the same name. The scored pick corrected it to the named
`amenity` node in the right place. Two venues needed a city correction the caption
didn't carry: Asador Etxebarri (caption said San Sebastián; it's an hour away in
Atxondo) and Casa Julián de Tolosa (also captioned as San Sebastián; it's in Tolosa).

## Build

- **Minting**: same pattern as the previous session's `mint_batch.py` (not committed —
  scratch) — imports `make-link-pin.py` and calls `make_one()` per row for per-pin
  tags, collecting the same `{makers, linkPins}` shape `main()` emits.
- **The two-pins-from-one-post id scheme is not what `make-link-pin.py`'s URL fragment
  implies.** Passing `url#chez-janou` does nothing — `canonical_url()` strips it, so
  both entries hashed to the identical bare-URL id and the second was silently dropped
  by `merge-link-pins.py --check` as "already in catalog" (i.e. a duplicate of the
  first, not of anything already live). The runbook's actual rule hashes a **fragment
  appended after the fact**: `#<slug(city)>` normally, escalating to
  `#<slug(city)>-<slug(title)>` when siblings share a city (both Paris, here) —
  computed by hand with `uuid.uuid5(NAMESPACE_URL, ...)` and confirmed against
  `merge-link-pins.py`'s own "the scheme gives …" error message before use.
- **Two identical hero images consolidated to one file** (`chez-janou-le-bon-georges-
  jacksdiningroom_hero.webp`) per the runbook — one post has one thumbnail, and the
  pair had been minted with two byte-identical files under different names.
- **gh-pages**: `gh` unavailable; built via plumbing (`git read-tree` on
  `origin/gh-pages`, stage 126 new blobs, `commit-tree`, push) — diff was exactly 126
  additions. All 126 live URLs hash-verified against the uploaded bytes after Pages
  finished deploying.

## Verification

- `merge-link-pins.py --check` then a real merge: all 128 ids derivable, 0 skipped
  (after the Chez Janou/Le Bon Georges fix), 0 collisions against a `main` that had
  moved 9 commits since the session started (fast-forwarded before merging).
- `validate-tours-mirror.py`: 0 errors, 361 warnings, none touching these pins.
- `check-image-duplicates.py --pins`: no new duplicate/shared-URL findings — the one
  `ERROR` and 4 `INFO` groups it reported all predate this batch.
- PR #959: all 5 CI checks green (unit tests, Validate Tours.json, iOS Simulator build,
  Place candidates, Account deletion), no merge conflict, squash-merged.

## Left alone

CLAUDE.md's Key-facts paragraph was not hand-edited, matching the previous session's
decision and for the same reason: the file's own history shows every prior correction
going stale before or during its own merge, because parallel sessions keep landing.
Re-derived directly from `Tours.json` at merge time: **1582 tours + 2667 link pins,
469 makers, 334 places, 618 cities, 69 countries** — re-derive again rather than
trusting this line, the same rule the paragraph itself states.

## Known debt / left open

None specific to this batch — all 4 flagged skips and the 1 owner caution were
resolved before merging.

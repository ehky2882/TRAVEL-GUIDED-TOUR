# Handoff — 2026-09-15 · The Tokyo coordinate precision pass

**PR:** #913 (69 pins moved). Earlier in the same session: #886, #891, #894 (merged for
another session), #895, #901.

## What was wrong

Two separate batches put pins on coordinates that were not the venue:

- **PR #885** (Tokyo, several creators) — audited in #895: 3 gross, 3 borderline, 18
  unverifiable because the venues are absent from OpenStreetMap.
- **PRs #893 and #896** (the byFood/@japanbyfood affiliate cluster, 92 pins) — **both PR
  bodies flagged the problem themselves** and deferred it: "40 with a precise street address,
  30 at neighborhood level only" and "7 resolved to an actual OSM POI, the other 13 to a
  postal-address or neighborhood centroid."

🔴 **The per-pin list those two PRs promised was never written.** #893's body says "list in
the handoff"; the handoff says "full list is in PR #893's description." Each points at the
other. It had to be reconstructed from the catalogue.

## How the flagged pins were identified

Two independent tests, union = 47 pins (45 clean):

1. **Stacked (19)** — shares a coordinate with another pin to 7 decimal places. Cannot happen
   by chance; both are on one fallback point.
2. **No address in the caption (38)** — the documented cause of the fallback.

⚠️ **A method that does NOT work: reverse-geocoding the stored coordinate** to see what it
sits on. In dense Tokyo the nearest mapped feature is rarely the venue even when the pin is
correct — the 92 pins came back sitting on a brothel, a bench, a vending machine, a blood
donation centre, a kindergarten. And name-matching the result gives false positives: three
Ginza restaurants "matched" a watch shop called GINZA NJ TIME on the word *Ginza*.

## 🔴 Nominatim cannot geocode a Japanese address

Asked in romaji it returns a **postcode centroid**, at full decimal precision, indistinguishable
from a venue hit — 20 of the first 23 addresses. Japan addresses by chōme-banchi, not by street,
and OSM's coverage of those numbers is thin.

**Use the Geospatial Information Authority of Japan instead.** Free, no key:

```bash
curl -s "https://msearch.gsi.go.jp/address-search/AddressSearch?q=$(python3 -c \
  'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))' 東京都台東区上野6-9-17)"
# → coordinates + 東京都台東区上野六丁目９番１７号
```

It echoes the matched 丁目/番/号, so **the precision of its own answer is readable**: an answer
ending 号 or 番地 is building-level, one stopping at 丁目 is coarser, and it says which.
Cross-validated before use — its Mizutani Camera point agrees with the OSM venue node to ~1 m,
Cafe de l'Ambre to ~3 m.

## 🔴 How to find a Japanese venue's address

**Search the web for the venue's Japanese name plus 住所.** The address comes back corroborated
across the restaurant's own site, Gurunavi, Navitime, Hitosara and Ikyu.

⚠️ **This session nearly failed the task by not trying it.** It went straight to scraping
byFood.com (403, Cloudflare), Tabelog search (403), Overpass (blocked by this environment's
egress) and Instagram embeds (no location tag), concluded the addresses were unobtainable, and
handed the owner a list of 42 to source by hand. The owner asked: *"the txt list all have names
you can look up. you really think my brother can do a better job than you?"* They were right.
**Exhaust search before declaring data unobtainable.**

All 41 addresses found this way are kept in `docs/byfood-addresses-260915.tsv`.

## ⚠️ Automated name matching produced 3 false positives in 8

Caught only by reading each one:

| Query | Matched | Why it is wrong |
|---|---|---|
| Yakiniku Kappo Note | 焼肉花 at **0 m** | generic word *yakiniku*; 0 m = matched something already on the bad centroid. Real answer: 焼肉割烹 **ノ音**, 麻布十番2-9-5 |
| Kiwamiya | 俺の創作らぁめん 極や | a ramen shop 3.3 km away |
| Saryo Tsujiri | a different branch | the pin names the Daimaru Tokyo branch |

## The check that holds: ward agreement

Geocode the address, then confirm the **ward matches the pin's own stated neighbourhood** —
赤坂 for an Akasaka pin, 銀座 for Ginza, 北沢 for Shimokitazawa. This is what caught
**Yakushu Bar**: the supplied address was 愛知県豊橋市, **229 km away**, while the post's own
caption places the bar in Sangenjaya, where the pin already sat. A different branch. Not moved.

## Result

**69 pins moved.** Biggest: Mizutani Camera 4,339 m · Mr. Kanso 4,304 m · Mendokoro Kawano
3,807 m · Sushi Oumi 3,300 m · Sukiyaki Sasaki 934 m · Kashiwa Komainu Brewery 796 m ·
Gyunabe Ukon 667 m.

Every stacked cluster is cleared — Ginza, Akasaka, Shimokitazawa, Hatagaya, Nihonbashi,
Kaminarimon, Shinjuku Gyoen. ⚠️ **Kiwamiya and Saryo Tsujiri still share a coordinate and that
is CORRECT** — both are inside 丸の内1-9-1, the Daimaru Tokyo / Gransta building.

## Nothing is still open — and note what this section said first

⚠️ **This section originally read "Still open" and listed three items. All three were
closed within the hour, in #917, #918 and #920, while this file said otherwise.** It is
corrected here rather than rewritten, because a handoff going stale hours after it merged
is the same failure the § READ FIRST rule exists for.

What those three turned into:

- **"Sushi Hajime, Shibuya"** — filed as unresolvable (鮨 はじめ in Roppongi vs 鮨 一 in
  Shibuya, homophones). The owner supplied *Gleme Building B1F, 3-15-5 Shibuya*, which is
  鮨 一's. Moved **649 m** (#918).
- **Yakushu Bar** — confirmed correct as it stood. The address supplied was 愛知県豊橋市,
  **229 km** away; the post's caption places the bar in Sangenjaya, where the pin already
  sat. A different branch. Not moved.
- **The 45 byFood pins that passed both tests** — verified in #917. 🔴 **37 of the 45 were
  wrong**, the worst by **3,778 m**. Only 5 were actually correct. They passed because the
  two tests detect a SHARED fallback point and a caption with NO address; a pin alone on
  its own wrong coordinate trips neither.

**The byFood cluster is closed: 85 corrected, 7 verified correct, 0 outstanding, across all
92 pins.** `status/owner/` is empty.

Two further rules came out of finishing it, both in `docs/link-pin-runbook.md`:

- 🔴 **A district-level geocode proves nothing in either direction.** The three pins that
  could only be resolved to a district came out 11 m right, 220 m wrong and 100 m wrong —
  having read as 269 m, 144 m and unparseable against those centroids. Moving the first on
  the strength of its 269 m would have introduced the error it appeared to have.
- 🔴 **A parser that drops the chome number builds a plausible NONEXISTENT address**, which
  geocodes to the district centre rather than failing. That bug reported 20 correct pins as
  >300 m wrong, one at 3,913 m; Park Side Donuts went from "186 m off" to 0 m once fixed.
  `scripts/parse-caption-address.py` exists, with a selftest, so it is not re-written badly.
  **The tell was GSI reporting its own answers as district-level** — a geocoder that states
  its precision is worth more than a confident one.

## Also in this session

- **#901** — three places: the Bowie pin joined The Reichstag (moved 208 m onto the building),
  the ghost-station pin joined Potsdamer Platz, and **L.D. Institute of Indology** (Ahmedabad)
  created from two @blessedarch pins naming one Doshi building.
- **#895** — ten places from the backlog, plus the Gotokuji Temple pin moved off Gotokuji
  **Station**, 562 m, the error that started this whole thread.

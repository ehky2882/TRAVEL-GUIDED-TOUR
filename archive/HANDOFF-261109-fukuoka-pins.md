# Handoff 2026-11-09: 22-pin Fukuoka/Kyushu batch

The contributor pasted 25 links (two of them duplicates, so 23 posts) labelled "Fukuoka" and approved the triage with: "A pin anyway, B pin anyway, C split into 2 pins, D add as Moonstar, E leave out, F I'll watch it later and decide."

## What shipped
- **22 link pins from 19 creators, 17 of them new.** Eleven are in Fukuoka city: Hilton Sea Hawk, ACROS, Il Palazzo, Coffee Bimi, ALSO Moonstar ×2, Meiji Park ×2, AMAM DACOTAN, Yusentei Park and Ocean House. The rest are around Kyushu: Dazaifu Tenmangu, Kawachi Fujien, Takasumi Shrine, Sasaguri Kyudai Forest, Mori no Café Midori no Uta, Totoro Forest and Keya Beach (Itoshima), Yufuin Floral Village and Takachiho Gorge. Two are outside Kyushu on the contributor's word: Akiyoshidō Cave (Yamaguchi) and Kamikochi (Nagano).
- **Coordinates.** Pins on a FUK tour's subject use that tour's coordinate exactly. Addresses (AMAM DACOTAN, Moonstar, Meiji Park, Ocean House at 1119-1 Imajuku Aoki) were geocoded through GSI at house-number precision. The landmarks came from OSM named nodes. Midori no Uta came from the prefectural tourism site's map pin, because GSI resolves 白糸561 only to the district. Totoro Forest is pinned at the Keya no Ōto lookout: the path has no map node, so this is approximate (~100 m).
- **One post, two pins.** The @japantripplanners post became Totoro Forest and Keya Beach. Both are in Itoshima, so the ids use `#itoshima-<slug(title)>`, per the runbook's collision rule. They share one cover image, which `check-image-duplicates` allows.
- **Images.** 22 heroes and 5 TikTok avatars went to gh-pages in a single plumbing commit (`c211263`, 27 additions, nothing else).
- **Checks.** Validator: 0 errors. Spine lookups: 22 asked, 0 failed. Tags: *Architecture* on Meiji Park (Sou Fujimoto) and *Bridge* on Kamikochi. The other nature pins keep their "no Theme tag" warnings, because the theme list has no nature theme.
- **Inline play.** 9 pins will open Instagram instead of playing inline, because the reels use licensed music.

## For Edward
- **`status/owner/place-triage-261109.md`**: six sites, each at 0 m: Sea Hawk, ACROS, Il Palazzo, Bimi, Moonstar (now three pins) and Meiji Park (two). Nothing was created or joined. join-places found nothing new.
- **`status/owner/pins-261109-held.md`**:
  - **@laureen's vintage-shop reel.** Neither the caption nor the cover frame names the shop. The contributor will watch it.
  - **The Yufuin no Mori route post**, left out.
- @foxmaskdaze (the Sasaguri pin) is a repost account. The video is credited to @samrat_fyp.

## Traps
- `make-link-pin.py --batch` still ignores `--title`, `--category` and `--tags`. So this batch ran once per URL from a TSV, and the outputs were combined (driver script in the session's scratchpad).

## Follow-up: six places created (owner approved, same day)
Edward said "make those six sites place pages". The places are Hilton Fukuoka Sea Hawk, ACROS Fukuoka, Hotel Il Palazzo, Coffee Bimi, ALSO MOONSTAR (3 pins) and Meiji Park (2 pins).
- They were built with `make-places.py`'s `place_id` and `apply`, so the ids follow `atlas-place:fukuoka:<slug>`.
- Every member already shared one point, so no coordinate moved. The diff is additions only.
- None matched a declined group. The validator reports 0 errors, and check-place-candidates no longer lists any of the six. `status/owner/place-triage-261109.md` was cleared.

## Follow-up: the held @laureen reel is now pinned
Edward watched it and identified the shop as "takayama pawn shop in kasuga".
- **Location:** 高山質店販売 春日店, the chain's retail branch in Okamoto 4-chome, Kasuga, taken from its named OSM node. takayama78.co.jp turned out to be a different, single-shop Chikushino business.
- **Pin:** "Takayama Shichiten Kasuga | 高山質店販売 春日店". It opens Instagram rather than playing inline (licensed music).
- **Checks:** no place candidate, and 0 validator errors. The hero is on gh-pages at `6a6307b`.
- **Board:** `status/owner/pins-261109-held.md` is cleared. The Yufuin no Mori route post stays left out, as recorded above.
- **Note:** the 2026-11-07 batch had skipped "the Takayama pawnshop" on a contributor's word. The owner has now chosen to pin it.

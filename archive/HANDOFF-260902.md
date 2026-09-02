# HANDOFF 2026-09-02 — 118 Hong Kong link pins from @shivanidukhandee (session 137)

**Branch `claude/tour-links-ujocag`, cut clean off `origin/main` at `d25670c`. NOT finished — this
session did the verification half. The catalogue is UNTOUCHED; no `Tours.json` edit, no gh-pages
push, no PR.** Everything needed to finish is staged in `drafts/hk-shivanidukhandee/`.

## What the batch is

The owner pasted **118 Instagram reel links** with two annotations ("Shivanidykhandee" and "Hung kee
seafood restaurant"). Every readable post is one creator — Instagram **`@shivanidukhandee`**, a Hong
Kong food-and-venue account. **At 116 pinnable posts this is the largest batch to date**, past the
106-pin `@hereinnyc` record (#699).

**118 links → 118 distinct shortcodes, 0 in-batch duplicates, 0 overlap** with the 740 pins on
`main` *and* 0 against both branches sitting ahead of main (`claude/tour-links-yg5yw2`,
`claude/tours-links-upload-h6t2cs`, both merged, checked anyway). **`@shivanidukhandee` has no maker
row** — it would be the 263rd maker, shipping `avatarURL: null` by design.

## ✅ TWO POSTS ARE BLOCKED, AND THE CONTROLS ARE WHAT MAKE THAT TRUSTWORTHY

`C6vyhv4NhMu` and `DW_uE17B0dW` return a **218,395–218,396 byte shell with `contextJSON: null`**
against **256,793–265,451 bytes with content** for the other 116. The split is cleanly bimodal with
no overlap.

**⚠️ Decisive because two LIVE CONTROLS were fetched in the same pass with the same user-agent** —
`DcTW0yzsEok` (`@poche_space`) and `DcLpQ7yOoBU` (`@sato_stays`), both already live pins — and both
came back healthy at ~260 KB. Without controls a transient failure reads as a restriction.

🔁 **These are "blocked now", not "gone".** A restriction is often temporary. **Do NOT re-wire them
on "the link opens on my phone"** — the owner is signed in; a logged-out Atlas user gets a blank card
and no hero. The test is `contextJSON` non-null on the embed, run with a live control alongside.
⚠️ `DW_uE17B0dW` is the batch's FIRST link — the owner's "Shivanidykhandee" note beside it was
naming the creator, not flagging that post.

## ✅ ALL 116 HEROES READ AGAINST THEIR CAPTIONS — ZERO WRONG SUBJECTS

**Method, stated honestly:** all 116 thumbnails were downloaded and rendered as **13 labelled contact
sheets at 420 px per tile**, each read against its caption. **Not** opened individually at full size —
116 full-size reads would have exhausted the session's context. ⚠️ Tiles are keyed by **shortcode**
(which is what the thumbnail file is named after, i.e. derived from `heroImageURL`) — **never by slug
prefix**, which is the session-121b bug.

**This creator burns a title card naming the venue into nearly every frame**, which is the only
reason a batch this size was tractable. Named in frame: `百味`, `九龍坎麻辣火鍋`, `志明蔴雀 CHI MING
MAJONG`, `明華`, `公和荳品`, `大和堂`, `citygate outlets 東薈城`, `KNOCKBOX COFFEE COMPANY`,
`Lucky 7`, `milkfill`, `CTMA`, `matsukiyo`, `CHAGEE`, `Takimoto`, `Chop Alley`, `Man Mo Temple`.

**Six subjects were settled by the picture where the caption could not settle them** — see
`drafts/hk-shivanidukhandee/audit_verdicts.json`. Notably: a caption reading only *"Yau Ma Tei"* is
the **Jade Market**; *"Fuk Wing Street"* is the **toy street**; *"Yu Chau Street"* is the **bead
street**; and the two captions with no `📍` at all are **Ocean Park** (its own title card) and the
**Sai Kung seafood restaurant** the owner named as Hung Kee (its own hashtag is `#saikung`).

**Independent corroborations worth keeping:** Ma Wan Tung Beach's frame has the **Tsing Ma Bridge**
in it, which is exactly where that beach is; Kowloon Park's frame is **pink flamingos** and Kowloon
Park has the flamingo aviary; Wong Tai Sin's frame is people kneeling with fortune sticks.

## 🔴 THE ONE REAL PROBLEM: ONLY ~44% OF THESE PINS WOULD LAND ON THEIR VENUE

`drafts/hk-shivanidukhandee/GEOCODE-STATUS.md` has the per-pin list. Summary over all 116:

| outcome | count | pin lands on |
|---|---:|---|
| venue-precise | **54** | the actual shop node in OSM |
| DISTRICT-ONLY | **45** | the district centroid — can be hundreds of metres out |
| unresolved | **17** | nothing |

These are small independent Hong Kong food shops and most are **simply not in OpenStreetMap** — the
documented COSM Atlanta case. ⚠️ **This was NOT a bad-query problem**: a multi-strategy pass was run
(venue+district → venue → bare venue → Chinese name → district), and `countrycodes=hk` was correctly
avoided because **OSM files Hong Kong under `cn`** (session-135 lesson) — a viewbox was used instead.
Strategy is recorded per row in `geo.json`, so precision is auditable rather than assumed.

**The documented fallback is the venue's own published address.** That means ~62 real per-venue
lookups and it is **NOT DONE**. A batch whose whole value is *go to this specific shop* should not
ship on district centroids without the owner deciding that explicitly.

## Other findings, flagged not resolved

- **3 pins are NOT in Hong Kong**, each confirmed by its own frame: `DFz3e_nSs7D` (**Macau** — card
  reads "MAGIC SHOP IN MACAU") · `DX8-l9ERoJr` (**Macau** — CHAGEE cup in the Venetian's Grand Canal
  Shoppes) · `DUIaMRxDD-N` (**Mumbai, India** — card reads "Puri Pani in Mumbai"). ⚠️ **India already
  exists in the catalogue (Agra, Kopargaon); MACAU DOES NOT.** Hong Kong ships as its own `country`
  across 89 entries, so filing Macau the same way is the consistent choice — **owner's call.**
- **4 same-subject pairs inside the batch** (Cheung Hing Coffee Shop, The Hideout Mui Wo, Hong Kong
  Disneyland, Kowloon Hum hotpot). Both of each ship on the documented precedent; they need distinct
  slugs or one hero overwrites the other.
- **6 place candidates against existing Atlas Hong Kong tours** — Lan Fong Yuen, Man Mo Temple, Upper
  Lascar Row, Lau Kee Aberdeen Boat Noodle, plus Ice Bean/Monster Building and Kowloon Park/Stone
  Columns. **Nothing was nudged** to manufacture a coincident group.
- **6 weak heroes** (venue not visible in frame) and **3 that want a full-size look** where the title
  card and the caption's venue disagree slightly — `DQ6e_iOkVSL` (herbal-tea shop vs "a local
  bakery") is the sharpest. All listed in `audit_verdicts.json`.
- **1 ambiguous location the creator never resolved**: `DTpmGYJker2`'s caption literally reads
  *"cosme, tsim sha tsui **or** causeway bay"*.
- **20 of 116 will not play inline** — the documented licensed-music gate. Poster +
  OPEN IN INSTAGRAM is the correct outcome, not a defect.

## Verification actually performed

`make-link-pin.py --selftest` **71/71** — ⚠️ **with Pillow installed first**; a fresh container
reports 62/62, which reads as a pass and is not one. Shortcode dedupe, catalogue dedupe and
branch dedupe all clean. **Nothing else has been run**: no validator mirror, no filename-collision
check against gh-pages, no byte/perceptual duplicate check, no `Tours.json` edit, no CI.

## 🔴 A PROCESS TRAP THIS SESSION HIT

The first geocode run **died at 103/116 and wrote no output file at all, while its launcher reported
exit code 0.** It was caught only by checking for the output file rather than trusting the exit
status. The rewrite (`geocode2.py`) **writes incrementally after every row** for exactly this reason.
Same family as every other false-pass in this project's history.

## What the next session should do

1. Decide the geocoding question with the owner (address lookups vs district pins vs a smaller batch).
2. Resolve Macau's `country` value.
3. Generate entries with `scripts/make-link-pin.py`, **suffixing hero slugs with the handle** — this
   batch contains subjects that already have live Atlas heroes (Man Mo Temple, Lan Fong Yuen, Upper
   Lascar Row, Lau Kee) and a bare slug would overwrite them, which since #567 a downloaded tour
   would never see corrected.
4. Filename-collision check against gh-pages **asserting the tree listing holds >1,000 images** (the
   session-123 false pass), byte + perceptual duplicate check, validator mirror self-tested against
   injected faults, `Tours.json` byte-stable under a Python re-dump before editing.

---

# ADDENDUM — owner decision: "land the ones that can be located first"

**47 pins are cleared to wire in. 69 are deferred.** The selection is
`drafts/hk-shivanidukhandee/keep.json`; the deferrals are `defer.json` (bad geocode) plus the
45 DISTRICT-ONLY / 17 unresolved in `GEOCODE-STATUS.md`, plus the 2 blocked posts.

## 🔴 A FORWARD GEOCODE HIT IS NOT A VERIFIED COORDINATE — 7 of 54 "precise" hits were WRONG

Every one of the 54 venue-precise coordinates was **reverse-geocoded at zoom 18** and compared
against the district its own caption named. Seven contradicted it and are deferred:

| code | venue | what the coordinate actually was |
|---|---|---|
| `C_dANa4y1yH` | Tung Lok Tong, Sheung Wan | **Shing Mun Tunnel Road, New Territories** |
| `DGAsg8HyIdt` | 雞蛋仔屋, To Kwa Wan | **Tai Po Road, Tai Po** |
| `DRws9_-EW5Z` | Chun Hing Garden, Kam Tin | **Hong Kong Jockey Club** |
| `DRCY1a0EUna` | Lau Kee Noodle, Aberdeen | **"Fu Kee Teochew Noodle", Tuen Mun** — a different restaurant |
| `DEcbpCkSpkC` | Komeda Cafe, Whampoa | Komeda at **Kai Tak** — wrong branch of a chain |
| `DX8-l9ERoJr` | Chagee, Macau Venetian | Chagee at **Kai Tak, Hong Kong** — wrong branch |
| `DQ9IueBEbRS` | Lin Heung Tea House, TST | Lin Heung on **Wellington St, Central** — creator and OSM disagree |

**Without the reverse check all seven would have shipped**, three of them kilometres out. At the
30 m geofence a link pin fires nothing, so nothing would have errored — the pin would simply have
sat in the wrong place.

## ⚠️ AN AUTOMATIC NAME-RESCUE RULE WAS TRIED AND REJECTED AS TOO LOOSE

Two of the nine the district filter flagged were the **filter's** fault, not the data's:
`DAnwHXaSEIF` (OSM writes "Wan Chai", the caption wrote "Wanchai") and `DBWBQezyHgN`
(百味食品 on Nathan Road vs the caption's Sai Yeung Choi Street — both Mong Kok, adjacent). Both
reverse-geocode onto the venue **by name**, so both are kept.

A generic "rescue it if the reverse names the venue" rule was written to catch those two — and it
**rescued `Lau Kee Noodle` onto `Fu Kee Teochew Noodle` on the shared word "noodle"**, and
`Chagee`-Macau onto `Chagee`-Kai Tak. It was discarded; all nine are adjudicated explicitly in
`select.py`'s FORCE_KEEP / FORCE_DEFER with the reasoning recorded per code.

## Still to do for the 47

Nothing has been generated or uploaded. Remaining: render heroes with `make-link-pin.py`
(**handle-suffixed slugs — Man Mo Temple and Upper Lascar Row are live Atlas heroes**), gh-pages
filename-collision check asserting the tree holds >1,000 images, byte + perceptual duplicate check,
`Tours.json` assembly, validator mirror self-tested against injected faults, PR.

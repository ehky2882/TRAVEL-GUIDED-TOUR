# Handoff — 2026-09-20 · a 56-link drop becomes 54 pins

**PR:** [#1017](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1017) ·
**Branch:** `claude/eloquent-hawking-zrnnxt` · **Catalogue:** `linkPins` 3,226 → 3,280 · makers 483 → 514

The owner pasted 56 links collected since 16 September. Triage, geocoding, minting, four
gh-pages pushes. **The Dominican Republic is a new country for the catalogue.**

## What shipped

54 pins from 41 creators. Chicago 12 · New York 11 · Los Angeles 3, and one each in 25 other
cities. Two pins sit on the Fairmont Banff Springs from two different creators.

Not shipped: **2 already pinned** (Hungarian State Opera House, Cirkelbroen), and **1
unmintable** — the Cathedral of St. John the Divine reel `DdcamqzoaGv`, whose Instagram embed
yields neither a creator handle nor a thumbnail, so there is no maker row and no hero. Owner
chose to skip it. **Transnistria (`DXt1t_fEi2o`) is still undecided** — a reel about a whole
unrecognised state, and the app fires on points; the offer on the table is the Lenin statue
outside the Supreme Soviet in Tiraspol, or leaving it out.

## 🔴 The lesson this session paid for again

**Two resorts were reported to the owner as having no obtainable coordinate. That was wrong,
and the owner caught it in one sentence: *"why can't you search for the address for those
properties?"***

The St. Regis Cap Cana and W Punta Cana are 2025 openings, in neither OpenStreetMap nor
Wikidata, and Marriott returns **403** to WebFetch *and* to curl with a browser UA. Every
route tried was a route to a **coordinate**. Searching the **street address** instead found
both within minutes:

| | coordinate | how |
|---|---|---|
| St. Regis Cap Cana | 18.456149, −68.415118 | Address "Punta Espada, Cap Cana" from two independent sources; OSM's Punta Espada driving range sits 2.4 km north in the same longitude band |
| W Punta Cana | 18.836325, −68.606867 | "Carretera Uvero Alto, next to Playa Escondida"; lands between Zoetry Agua (0.4 km west) and Sivory |

⚠️ **A near-miss worth recording.** `godominicanrepublic.com` offered 18.4459845, −68.4261917
for the St. Regis, and it matched Cvent's "9.32 miles from the airport" to within 0.03 mi —
a *very* convincing coincidence. It is **2.3 km from the real point** and reverse-geocodes to
bare scrub. **A distance that corroborates is not a location that corroborates.** What
actually settled it was a named OSM feature (the driving range) agreeing with the street
address the venue publishes.

This is `docs/lessons.md` § 4 and the runbook's § "Exhaust search before saying an address
cannot be found", both read this session, then not applied. The failure mode is specific and
worth naming: **searching for the coordinate instead of the address.** Those are different
searches and only one of them works on a venue too new to be mapped.

## 🔴 The second correction: a check that could not see its own subject

The PR's first version claimed the batch added no validator warnings. **It had.**

`validate-tours-mirror.py` prints a header count (`0 errors, 518 warnings`) and then only the
**first 40 warning lines**. Grepping the output file for this batch's titles found nothing and
read exactly like a pass. The real figure came from recomputing the facet rules directly
against the catalogue: **15 of this batch's pins carried no Theme tag.**

13 were fixed. **Five are left without one deliberately** — Lake Louise, Marco Island and the
three beaches are natural places and the taxonomy has no nature theme; inventing one is worse
than the warning. Pre-existing baseline on `main`: 364 entries already miss a facet.

**The habit:** a checker's *summary count* and its *printed detail* are two different things.
When the detail is truncated, grepping it proves nothing. Recompute, or read the count.

## One post, three pins — the fragment rule exercised

`@imjennychang`'s reel names Island Beach (Westport CT), Canopus Beach (Fahnestock, Kent NY)
and Brighton Beach. Owner chose three pins over the lead location alone.

`make-link-pin.py` has **no fragment support**, so the ids were minted by hand under the
runbook's rule: `uuid5` over `atlas-tour:link:<url>#<slug(city)>`, same on `atlas-stop:`. The
minting script **asserted the cities were distinct before writing** (so the subject fallback
was provably not needed), checked all six ids were unique, and refused if any were already
live. `sourceURL` is stored clean — the fragment exists only in the hashed key.

The three share one hero, named for the post (`three-northeast-beaches-imjennychang_hero.webp`)
rather than for any one beach. `check-image-duplicates.py` did **not** flag it: the tool
understands one-post-many-pins and counted it among its 213 documented reuses.

## What the cover frame can and cannot do

The tooling reads the caption and **exactly one frame** — the cover thumbnail. No video, no
audio. TikTok's terms forbid obtaining the video file and `make-link-pin.py` deliberately never
downloads one; Instagram withholds the media file outright for reels using licensed music.

That one frame identified **five** subjects whose captions named no place: Fordham University
Rose Hill, the Hollywood First National Bank Building, Lake Placid Lodge, Pullman, and (via
search on `#gothtarget`) the Sullivan Center. It failed on four, and the owner supplied all
four from memory in seconds — the Irish Hunger Memorial, the three beaches, the Ritz-Carlton
O'ahu and the cathedral.

**Open question for the owner:** sampling frames from music-free Instagram reels and running a
local transcription model would close most of that gap. It is a build, not a flag, and the
TikTok half needs an explicit decision because the no-download rule is deliberate.

## Verification actually performed

- `validate-tours-mirror.py` after **every** merge — 0 errors, selftest 37/37, control clean.
- Hero filenames diffed against the catalogue diff: **58/58 align** on the main batch.
- Four gh-pages pushes, each diffed before pushing: **58 A · 1 A · 5 A · 1 A — zero M, zero D.**
  One avatar path collided with an existing file and produced **no modification**, proving the
  bytes identical; nothing live was overwritten (the Thyssen rule).
- After the Pages deploy landed: **all 66 uploaded files fetched from the live URL and
  hash-compared against the local bytes — 66 identical, 0 mismatched, 0 missing.**
- ⚠️ The intermediate Pages deploys were **cancelled as superseded**, so the new URLs 404'd for
  ~15 minutes. That is "wait", not "fail" — confirmed against the Actions run list rather than
  assumed.

## 🔴 Pre-existing findings this session surfaced but did NOT cause

`check-image-duplicates.py --pins` exits **1** on `main`, and all four findings were confirmed
present on `origin/main` before this branch existed:

| Finding | Files |
|---|---|
| One image on entries in **different cities** | `here-s-one-of-our-favorite-suzyandaustin_hero.webp` — Keelung **and** Paris |
| Same | `here-s-another-michelinguide-spot-you-suzyandaustin_hero.webp` — Tainan **and** Taipei |
| Same | `le-relais-de-venise-jacksdiningroom_hero.webp` — New York **and** Paris |
| A hero written twice from one decode | `beverly-mai-ninosbuildings_hero.webp` = `the-concourse-ninosbuildings_hero.webp` |

⚠️ Two of those files **also 404 on gh-pages** — the catalogue points at images nobody uploaded.
This is the same shape as the London/Los Angeles Natural History Museum collision that served
the wrong narration for six and a half weeks. Left alone here because it is outside this PR,
but it is real and it is live.

## Next

1. Owner decides on Transnistria.
2. `backend/seed_from_toursjson.py` after merge — `get_catalog` is primary; the gh-pages mirror
   is only a fallback.
3. `check-place-candidates.py` — this batch leaves **two** candidates: the Manhattan Municipal
   Building (`@nyc` on Centre 360, `@nerdingoutonnyc` on the Dinkins Building) and Essanay
   Studios (`@vitavenute`, `@seeingcoolplaces`). Both are two angles on one coordinate.
4. The four pre-existing image faults above.

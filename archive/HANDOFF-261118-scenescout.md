# Handoff 2026-11-18: @scenescout_ triage batch, 32 filming-location pins

**Contributor:** arthur.yung (not Edward). **Creator:** TikTok @scenescout_, new to the catalogue, with 0 prior pins, so there were no duplicates to skip.

## What happened
- Triaged 32 vm.tiktok.com links with `triage-account.py` (31 SINGLE, 1 MULTI). #30, The Graduate church, was a false MULTI. TikTok oEmbed returns only the iframe now, so captions came through `make-link-pin.py`'s page fallback. Every caption carried a 📍 address. Each one was geocoded with Nominatim and the venue names were confirmed by web search or the cover frame.
- The contributor approved all 32, with #9 at the T&K gate and #5 approximate.
- Minted one at a time (`--title` / `--category` / `--tags` per pin), merged, validated (0 errors), filenames aligned, and 33 images (32 heroes and the avatar) pushed to gh-pages by plumbing, because `gh api` writes return 403 through the proxy. Ran the spine lookups (32/32).
- One title was renamed by the merge guard: "Dude, Where's My Car? Drive-Thru" became **"Habanero Mexican Grill (Dude, Where's My Car)"**. The venue was Steve's Burgers and is now Habanero at 2320 W Victory Blvd, Burbank.

## Judgement calls worth knowing
- **#5 T2 playground:** the caption only says "Elysian Park". Guides place the spot near Elysian Fields off Park Rd, where the playground is now a lookout. It is pinned approximately at Angels Point Road (34.08533, -118.24079).
- **#9 Fast & Furious, Johnny Tran stop:** the caption's "Hai Ba Trung Wy, Garden Grove" is on no map. The cover shows the T&K Food Market gateway, so the pin is at 9681 Bolsa Ave, with the city as **Westminster**.
- **#6 and #7:** both are at the Pink Motel / Cadillac Jack's. OSM places it at 34.24144, -118.39638. Nominatim's street-only answer for 9457 San Fernando Rd was about 3 km off, so the named OSM node was used.
- **#10 and #11 Frank's Restaurant:** sources disagree between 916 and 924 W Olive Ave. The cover shows the Frank's sign, so the pin uses the OSM node for Frank's Steak House.

## Owner-owed
- `status/owner/place-scenescout-pairs.md` asks four same-site place questions (Rialto, Cadillac Jack's, Frank's, Walter Reed), all at 0 m.

## Not done
- No places created or joined. Those questions are for Edward.


# Handoff 2026-10-29: 16-pin triage batch (@the.rjj.travel and three others)

A contributor pasted 20 links: 18 Instagram reels and 2 TikTok short links. Triaged first, then minted on their go-ahead.

## What shipped
**16 link pins.** 1 new creator (Instagram @the.rjj.travel), 10 new cities, no new country, no new place.

| Creator | Pins |
|---|---|
| @the.rjj.travel (new) | Guangwu Ming Great Wall, Chongfu Temple, Feiyunya, Queniao Village, Yunyan Temple (Mount Douchuan), Xumishan Grottoes, Yongtai Turtle City, Pingyao Ancient City, Jueyuan Temple + Qinglinkou Ancient Town, Shita Temple + Huojing Ancient Town |
| @igobart_ | Gwangtonggyo Bridge, Samil Building |
| @lucymcorban | Stravinsky Fountain |
| @jenniferdeborahwalker | Deák Mausoleum, Kerepesi Cemetery |

- **Two posts were exploded into two pins each**, on the contributor's instruction.
  - Jueyuan and Qinglinkou are in different cities, so they are keyed `#jiange` and `#jiangyou`.
  - Shita and Huojing are both in Qionglai, so they are keyed `#qionglai-<slug(title)>`. `merge-link-pins.py` enforces this form.
  - Each pair shares one hero.
- **14 heroes** went to gh-pages in one plumbing commit (`cadb88d`, 14 adds and nothing else). `upload-images.py` got a 403 from the proxy on the GitHub API, so the skill's git-plumbing fallback was used.
- **Checks:** the validator reported 0 errors. The new pins carry no warnings after Place-type tags were added (Stravinsky → Monument; Queniao and Yongtai → District). Neither place report lists a new pin.

## Skipped
- **Both TikToks**: @sashi_trip_tip's Villa Tugendhat and Leixões Cruise Terminal. They are the same videos already pinned. Triage missed this because they were `vm.tiktok.com` short links, which it does not resolve before its LIVE check.
- **@rebeltoursvienna, Vienna Central Cemetery.** The caption advertises their paid tour, so this is a policy question for Edward. Same site as the @architectphilipp Zentralfriedhof pin.

## Held: needs a coordinate
- **Changgou Catholic Church (长沟天主堂, Sacred Heart), Taiyuan** (@the.rjj.travel, `https://www.instagram.com/reel/DfAX7iCBgv9/`).
  - Identified from the cover frame and the caption's 1921 and 2009 dates.
  - It is in Changgou New Village, Zhongjianhe, Xinghualing District.
  - No WGS-84 point was found: OSM has no node for it, and the heritage register site is blocked from the web egress.
- **Paimo Village** (排莫村, Yangwu, Danzhai) and the **Dang Family Estate** (党氏庄园, Hejiashi, Baijiajian, Suide) were not in the go-ahead either. Same reason: no coordinate.

## For Edward
- **Kerepesi.** The existing pin "Kerepesi Cemetery (Kossuth mausoleum)" sits about 50 m from where OSM puts the *Deák* mausoleum, and about 200 m from OSM's Kossuth tomb. The new Deák pin uses OSM's Deák point. One of the two may be wrong.
- **Feiyunya** is placed from a travel blog's Google Earth reading (26.9521, 107.9852). It is the weakest coordinate in the batch.

## Tooling lesson
`triage-account.py` does not expand `vm.tiktok.com` short links before its LIVE check, so already-pinned posts read as SINGLE. Resolve them with `curl -L -w '%{url_effective}'` first.

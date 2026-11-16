# Handoff 2026-11-16: triage batch, 38 link pins

Contributor: arthur.yung. 45 links from 35 creators were triaged first and nothing was minted until the contributor approved.

## Outcome
- **38 pinned.** 21 new creators. 8 new cities: Yokohama, Nishinomiya, Eccles, Bursa, Gdańsk, Garway, Montreuil and Chenonceaux. No new country.
- **Skipped (contributor's word):** a Fukuoka bakery (@tillistour; caption, subtitles, location tag and cover all name nothing), TE TEA Shanghai (@hungrywolfgrams; no street number) and @madelainerascan "pilgrims" (a route).
- **Held:** MINEZO custom shoes, Tokyo (@sjparv, `DfFqBtDTepT`). No shop address found.
- **Already live from the same creator:** Graybar rats (@truetalesnyc) and Eltham Palace (@matter.by.millie).
- **Duplicate within the batch:** two vm.tiktok short links resolved to the same @ohfatti_travels video (7672369588545342738).
- **Place questions for Edward:** nine pins (2 joins, 7 new places), on `status/owner/place-triage-261116.md`. Nothing was joined or created.

## How the places were found
- **Video subtitles:** TikTok pages carry `subtitleInfos`; the WebVTT URL fetches with the page's cookies. That named Fukuoka Yagura and Villa Cavrois.
- **Cover frames (`fetch-cover.py`):** these named Fonda Margarita (its sign), Koshien, Tempelhof ("Berlin's last hope"), the Budapest Palace of Justice, the Unfinished Arch and Chenonceau.
- **Caption @handles and search:** A. Marchesan → Odengatan 100; SELECTION BY DU (菁禧荟, the caption's tag was blank) → Raffles City North Bund West Tower 56F.
- **Hikiniku to Come:** the chain's site lists Imaizumi as its only Fukuoka store.
- **Japanese addresses** were geocoded with GSI. **Overpass** was reset by the proxy again.
- **Matlı Stadyumu** is the current OSM name of Timsah Arena (40.2108, 29.0104), which agrees with Wikidata Q4818017.
- `spine-match.py` added no new DISAGREES or REVIEW findings.

## Mechanics
- The batch file cannot carry a per-line title, category or tags, so each pin was minted with a single `--url` run and the outputs were combined into one pins.json.
- **Two avatars for existing creators were not uploaded** (ninosbuildings, sashi_trip_tip). They were unreferenced, and uploading them would have overwritten live bytes.
- **gh-pages:** plumbing commit ec13da6, 42 additions and 0 modifications.

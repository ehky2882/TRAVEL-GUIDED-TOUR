# Shanghai batch 1: scripts staged

**13 single-stop scripts · staged 2026-10-12 · scripts only, no audio, no maker chosen yet**

The owner listed 13 Shanghai venues: cafés, restaurants, hotels, museums and one heritage house. Each venue is its own tour. Every script comes in three files:

- `.md`: the clean script, for reading
- `.txt`: the clean script, with the house header `ATLAS · SHANGHAI · NN · Title` then `---`
- `_TTS.txt`: the text to paste into the voice tool. Names are respelled in lowercase with no hyphens. `[beat]` is removed and replaced by a paragraph break, and every number is written as words.

`scripts/_clean.py` holds the source text, and `scripts/build.py` writes the three files. Edit the source, then re-run `build.py`. Never edit the generated files by hand.

🔴 **Strip the header before wiring.** `transcriptText`, `caption` and `shortDescription` must come from the text after the first `---`.

## 🔴 The coordinates were GCJ-02, not WGS-84

All 13 coordinates came from a Chinese map app, so they use **GCJ-02**, which is deliberately shifted by roughly 500 m. The proof: converted with `scripts/gcj02.py`, Rockbund lands on the museum's own OSM object (上海外滩美术馆, 20 Huqiu Rd), and Design Republic on 设计共和, 511 Jiangning Rd. Jean-Georges lands on 有利大楼, 3 Zhongshan E. 1st Rd. Unconverted, Ops sat on the High Court on Zhaojiabang Rd and the Sukhothai on the Yan'an Rd interchange.

**Use the WGS-84 column below, never the owner's raw numbers.**

| # | Venue | Slug | WGS-84 lat | lon | Check |
|---|---|---|---|---|---|
| 01 | Blue Bottle Zhang Yuan Café | `blue-bottle-zhang-yuan` | **31.23037** | **121.45605** | 🔴 **GROSS.** The given point is in Minhang (Lianhua Rd, Gumei), about 10 km away. It is wrong in either datum. The café is at W5-1A, 240 North Maoming Rd, inside Zhang Yuan. The figure shown is the OSM centroid of Zhang Yuan (张家花园), so it is about 100 m out at worst. **The owner should send an Amap pin of the café itself.** |
| 02 | Former Residence of Hotung | `hotung-residence-shanghai` | 31.23278 | 121.44803 | Shaanxi N. Rd, at 457 (Beijing W. Rd corner). OK |
| 03 | Jean-Georges & Mercato | `jean-georges-mercato-three-on-the-bund` | 31.23619 | 121.48628 | 有利大楼, 3 Zhongshan E. 1st Rd (Three on the Bund). OK |
| 04 | Jesse Restaurant | `jesse-restaurant-tianping-road` | 31.20506 | 121.43337 | Tianping Rd, at 41. OK |
| 05 | Meet the Bund | `meet-the-bund-bfc` | ? | ? | 🔴 **Unresolved.** Converted, the point is **59 Hong Kong Rd**, the former Shanghai Bankers' Club in Waitanyuan. No source puts Meet the Bund there. The verified branches are: **BFC South Block 3F**, 600 Zhongshan E. 2nd Rd (the Michelin-starred original, about 31.2286, 121.4934); **Skyline**, Raffles City The Bund West Tower 56F, Hongkou (already pinned as "Meet the Bund Skyline"); and **Xintiandi**, 338 Huangpi S. Rd. **The script is written for BFC.** Ask the owner which branch they mean before wiring. |
| 06 | Ops Cafe | `ops-cafe-taiyuan-road` | 31.20766 | 121.45076 | Taiyuan Rd near Yongjia Rd (Lane 177 No. 1). OK |
| 07 | Rockbund Art Museum | `rockbund-art-museum` | 31.24313 | 121.48305 | OSM object 上海外滩美术馆. OK |
| 08 | The PuLi Hotel and Spa | `the-puli-hotel-shanghai` | 31.22432 | 121.44375 | 1 Changde Rd, beside Jing'an Park. OK |
| 09 | The Shanghai EDITION | `the-shanghai-edition` | 31.24002 | 121.48142 | Nanjing E. Rd block (199). OK |
| 10 | The Sukhothai Shanghai | `the-sukhothai-shanghai` | 31.22925 | 121.45958 | Weihai Rd, near 380. OK |
| 11 | West Bund Museum | `west-bund-museum` | 31.17449 | 121.45810 | Longteng Ave (2600). OK |
| 12 | Xin Rong Ji | `xin-rong-ji-nanyang-road` | 31.23010 | 121.44600 | 170 Nanyang Rd, the Pei mansion. The given point was the GCJ shift of this, and it reverse-geocoded to Rong Zhai, 186 Shaanxi N. Rd. OK once converted |
| 13 | Design Republic | `design-republic-design-commune` | 31.23792 | 121.44614 | OSM object 设计共和, 511 Jiangning Rd. OK |

## Place questions for Edward (not decided here)

- **05 Meet the Bund ↔ the existing pin "Meet the Bund Skyline".** Same brand, different branch. A tenant is not the site and two branches are not one place, so this is probably not a place. It is listed only so it is seen.
- **02 Hotung, 12 Xin Rong Ji, and the existing pin "Mi Shang Prada Rong Zhai".** These are three different houses within about 400 m on Shaanxi N. Rd. They are not places, but the scripts cross-refer to each other.

## Facts that are perishable or single-source

These were checked on 2026-10-12. Re-check them before recording.

- **03 Mercato** is still listed on the sixth floor. I found no source confirming it is open in 2026.
- **05** The Michelin star and Asia's 50 Best ranking are worded loosely on purpose ("the name now sits high on…").
- **12** The Nanyang Rd flagship now appears in the Michelin Guide as *The House of Rong / 荣府宴*. The script says "lately it's also been listed under the name Rong Fu Yan". Its current star count differs between sources (two in 2018; one listing shows one in 2026), so the script only states the 2018 award.
- **04** "Since 2004" comes from a single guide (Rachel Gouk / Nomfluence). The script says "most guides agree".
- **01** The first electric lamp in China is a legend, and the script hedges it ("the story goes").

## Primary sources read (one per venue at least)

| # | Sources |
|---|---|
| 01 | thespaces.com (Blue Bottle Zhang Yuan); hospitalitydesign.com; english.shanghai.gov.cn (Jing'an winter walk) |
| 02 | thepaper.cn newsDetail_forward_3192049 (Hotung house history, Cihai); english.shanghai.gov.cn; en.wikipedia Robert Hotung |
| 03 | neriandhu.com Jean-Georges project page; architecturalrecord.com (Mercato) |
| 04 | rachelgouk.com Old Jesse listing; joinpearl.co |
| 05 | the50.com Meet the Bund; rachelgouk.com BFC listing; Michelin 2021 new stars; mariofung.com review |
| 06 | thepaper.cn newsDetail_forward_8604521 (founders, the O.P.S. name); sugarednspiced.com; davidwin.net (2026) |
| 07 | rockbundartmuseum.org/about-us; en.wikipedia Rockbund Art Museum; chinadaily (Waitanyuan, 11 buildings, 2023) |
| 08 | en.wikipedia The PuLi Hotel and Spa; asiatraveltips.com (2007 design brief) |
| 09 | hoteldesigns.net (EDITION opening); Marriott news release (1929, Power Company) |
| 10 | neriandhu.com *The Muted Landscape*; dezeen.com; wallpaper.com |
| 11 | davidchipperfield.com project page; centrepompidou.fr partnership page |
| 12 | baike.baidu.com (Xin Rong Ji history); Michelin Guide Nanyang Rd; postcard.inc (Pei mansion) |
| 13 | neriandhu.com Design Commune project page; dezeen.com; architecturalrecord.com |

## Images (2026-10-12): picker published, nothing picked yet

**Picker:** [Shanghai Image Picks](https://claude.ai/artifact/1EjYxPqJjtFygrGfRzH7aU). It holds 24 photos across 7 tours. Each source page and licence is listed in `image-candidates.tsv`, and every place to look further is in `IMAGE-LINKS.md`.

- **Only 03 has photos of the venue itself:** two CC0 photos of Three on the Bund. Every other photo is labelled `CONTEXT` on its card: the dish, the street, or the place the closing walk sends you.
- **No candidates at all for six tours:** 02 Hotung, 07 Rockbund, 10 Sukhothai, 11 West Bund, 12 Xin Rong Ji and 13 Design Republic. There are no public-domain, Pexels or Unsplash photos of these buildings. Commons has CC BY-SA photos, which need an owner OK and a credit. Otherwise the fallback is owner photos, or press images with the venue's permission.
- **Checks were done by eye.** Gemini could not run, because the "key" supplied was a Google Cloud project ID (`gen-lang-client-…`), not an API key. Both gates were applied as separate passes.
- **Unsplash returned `Rate Limit Exceeded` for the whole session**, so it contributed nothing.
- **Wikimedia rate-limits this egress IP** (429 "robot policy"). Only **standard thumbnail widths** (`/1280px-`) got through; Openverse's thumbnail proxy returns 424 for Commons files. The public-domain finds are therefore 1280 px on the long side, enough for a 1200×900 crop with no upscaling.

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
| 05 | Meet the Bund | `meet-the-bund-bfc` | 31.22861 | 121.49341 | **Owner confirmed BFC (2026-10-12).** The point is the OSM object for the Bund Finance Center complex (外滩金融中心, 600 Zhongshan E. 2nd Rd). The restaurant is S301, South Block 3F, inside that complex, so this is within about 150 m. The owner's original point was 59 Hong Kong Rd, and is not used. The Fosun Foundation (OSM way 520214798) is at 31.22888, 121.49358 |
| 06 | Ops Cafe | `ops-cafe-taiyuan-road` | 31.20766 | 121.45076 | Taiyuan Rd near Yongjia Rd (Lane 177 No. 1). OK |
| 07 | Rockbund Art Museum | `rockbund-art-museum` | 31.24313 | 121.48305 | OSM object 上海外滩美术馆. OK |
| 08 | The PuLi Hotel and Spa | `the-puli-hotel-shanghai` | 31.22432 | 121.44375 | 1 Changde Rd, beside Jing'an Park. OK |
| 09 | The Shanghai EDITION | `the-shanghai-edition` | 31.24002 | 121.48142 | Nanjing E. Rd block (199). OK |
| 10 | The Sukhothai Shanghai | `the-sukhothai-shanghai` | 31.22925 | 121.45958 | Weihai Rd, near 380. OK |
| 11 | West Bund Museum | `west-bund-museum` | 31.17449 | 121.45810 | Longteng Ave (2600). OK |
| 12 | Xin Rong Ji | `xin-rong-ji-nanyang-road` | 31.23010 | 121.44600 | 170 Nanyang Rd, the Pei mansion. The given point was the GCJ shift of this, and it reverse-geocoded to Rong Zhai, 186 Shaanxi N. Rd. OK once converted |
| 13 | Design Republic | `design-republic-design-commune` | 31.23792 | 121.44614 | OSM object 设计共和, 511 Jiangning Rd. OK |

## Place questions for Edward (not decided here)

- **05 Meet the Bund (BFC) ↔ the existing pin "Meet the Bund Skyline".** Same brand, different branch, about 3.0 km apart. A tenant is not the site and two branches are not one place, so this is probably not a place. It is listed only so it is seen.
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

## Images: picker v3 published 2026-10-13, nothing picked yet

**Picker:** [Shanghai Image Picks](https://claude.ai/artifact/1EjYxPqJjtFygrGfRzH7aU) (version 3). It holds **92 photos across 10 tours**. Each source page and licence is listed in `image-candidates.tsv`, and every place to look further is in `IMAGE-LINKS.md`.

- **Photos of the venue itself** (labelled `SUBJECT`): 02 Hotung (Commons *Hedong Gongguan*), 03 Three on the Bund (exterior plus actual Mercato dishes), 05 BFC / Fosun Foundation, 07 Rockbund (exterior, bagua windows, interior), 08 the PuLi (one tower shot), and 11 West Bund Museum. **04 Jesse now has Old Jesse's own dishes**, found by a Commons search for 老吉士: the scallion fish head and the red-braised pork the script names, among others. **08 now has the PuLi tower seen from Jing'an Park** (Free Art Licence). 01 has Zhang Yuan's lanes but not the café.
- **`CREDIT NEEDED`** marks Wikimedia CC BY / BY-SA photos. The app has no credit line, so each one needs the owner's OK and a `drafts/CREDITS.md` line before shipping. Public domain, CC0, Pexels and Openverse photos need nothing.
- **Still nothing of the venue itself** for 06 Ops (only a Taiyuan Road street view), 10 Sukhothai, 12 Xin Rong Ji or 13 Design Republic. Commons was searched by category and by file name, in English and Chinese. ⚠️ **Search file names in Chinese**: the Old Jesse dishes came up only under 老吉士.
- **How Commons was reached:** this egress IP gets HTTP 429 from Wikimedia's API and from `upload.wikimedia.org`. The route that worked was:
  - **PetScan** (`petscan.wmcloud.org`) to list a category's files;
  - **Toolforge commonsapi** (`magnus-toolserver.toolforge.org/commonsapi.php`) for each file's licence and size;
  - the **i0.wp.com image CDN** for the pixels, requesting the standard `/thumb/…/1280px-` URL.

  ⚠️ That CDN returns 404 to Python's urllib but 200 to curl, so download with curl.
- **Checks were done by eye.** Gemini could not run: the value supplied (`gen-lang-client-…`) is a Google Cloud project ID, not an API key. Unsplash returned "Rate Limit Exceeded" all session.

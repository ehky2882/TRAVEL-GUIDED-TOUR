# Geocoding status — @shivanidukhandee Hong Kong batch

Rows resolved so far: **116 / 116**

| outcome | count | what the pin would land on |
|---|---:|---|
| venue-precise | **54** | the actual shop/venue node in OSM |
| DISTRICT-ONLY | **45** | the district centroid — can be hundreds of metres out |
| unresolved | **17** | nothing at all |

## 🔴 This is the batch's one real problem

Only about **44% of these pins would land on the venue itself**. These are small
independent Hong Kong food shops and most are simply not in OpenStreetMap — the
documented COSM Atlanta case. A district-centroid pin is materially worse than the
catalogue norm for a batch whose whole value is *go to this specific shop*.

**The documented fallback is the venue's own published address**, which means real
per-venue lookups for the ~57 below. That work is NOT done.

## DISTRICT-ONLY (needs a real address)

- `C-SWfbwSimH` — Long Ping Strawberry Park Farm in Yuen Long
- `C-fMUPyyREC` — Natural Spices Shop, North Point
- `C-m11rJS6Fe` — New Patoy, North Point
- `C-ul4yHyzW8` — Kumachan Onsen, Tai Koo
- `C55gGJqyOeI` — Sino Center, Mong Kok
- `C9pM_X6yCtq` — Matchbox Cafe, Causeway Bay
- `C_SooDSSUtJ` — Chilli Club Wan Chai (🌱 Vegetarian Friendly)
- `DAdgU-fBag2` — Hara Station, Tsim Sha Tsui
- `DBYnXEky1Cb` — 九龍坎麻辣火鍋 469-471 Nathan Road, Yau Ma Tei (Kowloon Hum Hot Pot)
- `DEHxPxEyNev` — Bagel Gogo, Hung Hom
- `DEUqjTxSl-5` — Chi Ming Mahjong, 60 Fa Yuen Street, Mong Kok
- `DEpMD8VSH-g` — Francis West, Peel Street Central
- `DFKrS6EytYT` — Handcrafter, D2 Place Lai Chi Kok
- `DFNbpQxSeBF` — Yuk Kin Fast Food, Sheung Wan
- `DFz3e_nSs7D` — IONG’S Magic Shop, Macau
- `DGF99BjSo-y` — Books & Co Sai Ying Pun
- `DGSzsSiSHlq` — Vivienne Westwood Café, Fashion Walk, Causeway Bay
- `DH-4EjPSnPK` — SLO WOOD, Kennedy town
- `DJ9CBV4yR98` — Sai Wan Ho Rock Pools
- `DK9Z3dQyNe8` — Honolulu Coffee Shop, Wanchai
- `DKtzT5VSbe2` — Knockbox Cafe Mong Kok & Central
- `DLH6DC5S4QM` — commaa cafe sheung wan
- `DLXOqgDyUGo` — City Gate Outlet, Tung Chung
- `DLcVFHeyPxm` — Haidilao HotPot Tsim Sha Tsui
- `DLr4OsiSUJa` — Lucky 7 Stanley Market
- `DLuaIw6y47O` — Cuit, Sai Kung
- `DMFhntMS2BY` — Milkfill, Tsim Sha Tsui
- `DQ37PkcEajI` — Hang Sing LP Records, Sham Shui Po
- `DQG-MC3kY09` — Ice Bean, Quarry Bay Monster Building
- `DQ_t0ofkYOF` — no title, sheung wan
- `DQjVy1OEToA` — Hoopla, Lai Chi Kok D2 Place
- `DQrGXMKkdfj` — Dozy Cafe, To Kwa Wan
- `DQtqCSJkaEM` — Habo, San Po Kong
- `DRE25hIEYQ4` — Shun Sum Yuen Farm, San Tin
- `DRRn5T0EVjY` — The Hideout, Mui Wo
- `DRZh0HNkfTV` — The Hideout Mui Wo
- `DRewFgLEWdR` — Ming Heung Tea Co  in Kowloon City
- `DS4mQtpEay5` — Hikiniku to Come, Habour City Tsim Sha Tsui
- `DSw-2BXEW-b` — Long Run Beauty, Kwai Chung Plaza
- `DT-Osx0Ea7r` — Mermaid Hotpot, Causeway Bay
- `DT0FgGokTZI` — Yoajung, Olympic City
- `DTpmGYJker2` — cosme, tsim sha tsui or causeway bay
- `DTsJ9eAET-I` — Cookie Quartet, Mong Kok
- `DW1KgzhEReK` — Cookie Vission Tai Hang
- `DbQLTEhRSt1` — Haeundae Galbi 2-8 wellington street, central

## UNRESOLVED (no OSM hit at all)

- `C4pt56xSouI` — Kyung Yang Katsu
- `C_K7ST4SOT3` — Cheung Hing Tea Hong
- `C_QUmsoSyP3` — Nomi Ramen
- `DA3HyZFyuQv` — Vission Bakery
- `DCEjm3IN5cl` — Takimoto, Causway Bay
- `DCMNDJ6NmMj` — Yee Shun Milk Company
- `DE2BIp_S-ZP` — New Zealand Organic Farm
- `DEmklh4Sgcu` — Chi Lin Nunnery & Nan Lian Gardens
- `DFIKrVtSe70` — Nobu, The Regent
- `DK65cH2SfO8` — Bacha Coffee
- `DKzAegSSTqk` — Chicken Egg Boy
- `DLPtXqBSz3R` — 
- `DMc8XgHytj4` — CTMA Mall, Mong Kong
- `DMz6jSxy0u8` — Kowloon Hum Spicy Hotpot
- `DUIaMRxDD-N` — Elco Pani Puri, Bandra
- `DW_ZI8GESXl` — 
- `DcIzh9RR6j6` — COMMUNE MAISON

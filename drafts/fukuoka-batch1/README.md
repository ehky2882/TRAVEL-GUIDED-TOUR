# Fukuoka batch 1: Atlas Studio FUK (30 singles), wired 2026-11-08

Source: contributor drop (Dropbox, arthur.yung). 30 `output <Name> <lat>, <lon>` folders with scripts numbered 01–30.
Each folder holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt`, one MP3 (74–126 s, 128 kbps) and 1–6 photos at
1200×900 WebP (112 delivered, 112 shipped, no byte duplicates). The `·` in B·B·B arrived as a `#U00b7` escape, so the
assembler matches folders by **script number**.

`scripts/` holds both texts as delivered. `coordinates.tsv` lists slug · lat · lon · radius · category · city, as wired.

`tools/wire_fukuoka.py` is the assembler (`python3 -I wire_fukuoka.py <unzipped drop> <stage dir>`), adapted from
`drafts/mexico-city-batch1/tools/wire_mexico_city.py`. Run it once only: it refuses colliding tour ids. Slugs carry a
**`fuk-` prefix**: audio at `audio/fuk-<slug>.mp3`, images at `images/fuk-<slug>_hero.webp`, `_2.webp`, … in the drop's order.

- **Maker:** Atlas Studio FUK 🇯🇵, platform `dozent`, handle `atlas.fuk`, uuid5 `atlas-maker:fuk`
  = `48d15959-59f6-59e0-9c22-9ee589f4a0f5`.
- **Ids:** `atlas-tour:fuk:fuk-<slug>`, stops `atlas-stop:fuk:fuk-<slug>:1`.

## Coordinates
One folder-name coordinate was not at its venue and was corrected:

| Tour | Drop point | Wired point |
|---|---|---|
| Ishimura Manseido Main Store | 33.596945, 130.404241: Daikoku-dori in Komondo-machi, ~112 m north | 33.595943, 130.404434: GSI house-number point for 2-1 Suzaki-machi, the address the contributor confirmed |

`check-coordinates.py --drop` flagged four more as GROSS, all cleared by hand: manu coffee (the geocoder matched the
Daimyo branch; the point is 27 m from Border Tower, Watanabe-dori 3-11-2), Nakasu Yatai (sits on OSM's 屋台 way),
Tenjin Underground Mall (a 600 m mall; the point is under the Tenjin crossing) and Kyushu National Museum (on the
museum's own grounds). The 15 UNVERIFIABLE were checked against OSM by Japanese name or GSI by street address; all
within ~50 m except Grin Grin (beside the pond, where the script stands you) and Nexus World (several blocks; the
exact chōme could not be confirmed, so the point was not moved on a district centroid).

🔴 **BIAS: 12/13 north, median +18.9 m, p = 0.0034.** The upstream northward offset is still present.

## Wiring
- **City:** `Fukuoka` for 29; **`Dazaifu`** for the Kyushu National Museum (a new city). Country `Japan`.
- **Geofence:** 25 m for restaurants, cafés and shops; 30 m for Il Palazzo, Machiya Furusato-kan, the Guest House and
  Red Brick; 40 m for the Ritz, the museums, Kushida, TBC and Fukuoka Bank; 50 m for Sea Hawk, markets, yatai, the
  arcade, Shofukuji, ACROS and Grin Grin; 60 m for Kyushu National Museum, the underground mall, Canal City and Nexus
  World. No two of the 30 circles overlap.
- **Bilingual `English | 日本語`** on 27. manu coffee, REC COFFEE and B·B·B POTTERS keep their brand names.
- **Text:** `longDescription` = hook + paragraph 3, `shortDescription` cut at 145 characters, `[beat]` stripped.
  Captions written by hand from each script's orientation paragraph.

## Architect tags (Job 5): 14 new names, one line in each list
Jon Jerde (Canal City) · Kiyonori Kikutake (Kyushu National Museum) · Kume Sekkei (Kyushu National Museum, Ritz-Carlton
tower) · Emilio Ambasz, Nihon Sekkei (ACROS) · Shohei Shigematsu (Tenjin Business Center) · Kingo Tatsuno, Yasushi
Kataoka (Red Brick Cultural Center) · Arata Isozaki, Steven Holl, Mark Mack, Oscar Tusquets, Osamu Ishiyama (Nexus
World) · Shigeru Uchida (Il Palazzo interiors). Existing tags used: Aldo Rossi, César Pelli, Kunio Maekawa, Kisho
Kurokawa, Toyo Ito, Rem Koolhaas (TBC, Nexus World), Christian de Portzamparc.
**Not** tagged: Takenaka (ACROS contractor), Sottsass, Pesce and Kuramata (Il Palazzo bars), Kengo Kuma (the Starbucks
on the Dazaifu approach is mentioned, not the subject).

## Places
None created or joined. `check-place-candidates.py` and `join-places.py --max-move 100` raised nothing involving the
30 new tours.

## Content notes (audio already recorded)
Lines that will date: Books Kubrick's first shop "closed in July 2026", Tenjin Business Center II "opened in August
2026", and the Tenjin Underground Mall "is fifty years old this year". Kushida Shrine has a hero photo only.

## Script 31: Ocean & Resort Marizon (added 2026-11-08, second drop)
A separate Dropbox drop held this one tour as flat files: no `output <Name> <lat>, <lon>` folder, so **no coordinate
came with it**. Wired by `tools/wire_fukuoka_31.py` (reuses `wire_fukuoka.build()`), with the contributor's approval:
- **Point:** 33.5952679, 130.3511367, the centre of OSM's マリゾン polygon (the deck over Hakata Bay). The script stands
  the listener at the far (north) end by the ferry landing; the stop sits on the subject instead, with an **80 m**
  geofence covering the ~170 m deck end to end. No overlap with any other stop.
- **Title** `Ocean & Resort Marizon | オーシャン&リゾート マリゾン`, category Architecture, tags Waterfront, Venue,
  Architecture, Maritime, History, Contemporary, Viewpoint, Free to Visit. **No architect tag:** the script names none,
  and a Japanese search found no credited designer.
- Audio 133 s, 4 photos at 1200×900 (`fuk-ocean-and-resort-marizon_hero.webp`, `_2`–`_4`), gh-pages `6e7afb52`.

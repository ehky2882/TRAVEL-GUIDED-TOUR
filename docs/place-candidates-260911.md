# Place candidates — the live menu

**Regenerated 2026-09-23 00:48 UTC against `main` at `8a3022c2`.** Every number here is a reading of
`Tours.json` and goes stale the moment a pin batch merges. Regenerate it — do not patch it:

```bash
python3 scripts/make-place-menu.py
```

## Where this stands

A `Place` is a site that more than one entry describes: the site becomes the thing on the map
and the entries become its contents. The catalogue holds
**435 places covering 1066 entries**.

The 2026-09-11 sweep found 221 candidates and **45 became places** — 7 existing places gained
the 8 entries standing on them, 38 new places came from the 0 m rows, and both held groups
were resolved ([#801](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/801)). That took the sweep from **41 exact / 151 tight / 79 near**
to nearly nothing.

**Then `main` moved** — #804 and #805 changed pins and a new coincident group appeared. That is
the normal condition. What follows is what is open **right now**.

| | Finding | Act on it? |
|---|---|---|
| **§ 1** | **0 on an identical coordinate** — the catalogue's own identity rule | Yes, highest confidence |
| **§ 2** | **26 sites** with 2+ entries within 25 m | Owner picks |
| **§ 3** | 32 same-subject pairs 25–500 m apart | Read one at a time |
| **§ 4** | 35 groups **already declined** | Do not re-offer |

## 🔴 What creating one costs — it is never just a list entry

A place needs its own **name, description, address and a chosen coordinate**. And because a
place's identity is **exact coordinate equality** (`Place.swift`, enforced by `validate-tours`
at 1e-9°), every member is **snapped onto that coordinate** — all 1066 existing members sit
exactly on their place. Creating a place *moves things on the map*.

⚠️ **Check each move against the entry's own `triggerRadiusMeters` (30 m) first.** A move inside
that radius changes nothing about when a tour fires; a larger one silently relocates the
trigger, and nothing else in the pipeline would object.

## ⚠️ The false positives are real and permanent

1. **A dense block of separate venues.** Hong Kong's restaurant pins sit 10–20 m apart and are
   different restaurants. Same for Stockholm's bars and Sydney's.
2. **Coordinates rounded to four decimal places** (~11 m) can round two genuinely separate
   sites to within a few metres — Madrid's *El Retiro* lands 8 m from the *Puerta de Alcalá*.

Proximity is evidence, not proof. Nothing here auto-creates.

---

## § 2 — 26 sites with two or more entries within 25 m

Built only from hops of 25 m or less; the widest group is **25 m** end to end, so
none is a chain of separate sites strung together.

| # | City | Span | Entries |
|---|---|---|---|
| P1 | London | 5 m | `[pin]` Italian Bear Chocolate<br>`[pin]` The Broad Street Pump |
| P2 | New York | 7 m | `[pin]` Keith Haring's Carmine Street Mural<br>`[pin]` Tony Dapolito Recreation Center |
| P3 | New York | 9 m | `[pin]` Catch'N Ice Cream<br>`[pin]` The Bayard-Condict Building |
| P4 | New York | 10 m | `[pin]` Hoyt–Schermerhorn Streets Station<br>`[pin]` Schermerhorn Street: How Do You Say It? |
| P5 | Chicago | 11 m | `[pin]` St. Regis Chicago<br>`[pin]` Tre Dita |
| P6 | Los Angeles | 14 m | `[pin]` Eggslut<br>`[tour]` Grand Central Market |
| P7 | Rome | 14 m | `[pin]` Ara Pacis Museum<br>`[tour]` The Ara Pacis and the Mausoleum of Augustus |
| P8 | Paris | 14 m | `[pin]` Chez Ajia<br>`[pin]` Kura-ge |
| P9 | Paris | 15 m | `[pin]` Homer<br>`[pin]` Le Procope, Paris |
| P10 | Lisbon | 16 m | `[tour]` Pink Street<br>`[pin]` Sol e Pesca |
| P11 | New York | 21 m | `[pin]` Old Mates Pub<br>`[pin]` The Purple FDR Drive |
| P12 | Edinburgh | 21 m | `[pin]` Frankenstein's Bar<br>`[pin]` The Elephant House, Where Harry Potter Began |
| P13 | Taipei | 22 m | `[pin]` A Joy, Taipei 101<br>`[pin]` Taipei 101 |
| P14 | London | 22 m | `[tour]` Cutty Sark<br>`[tour]` Greenwich Foot Tunnel |
| P15 | Edinburgh | 23 m | `[pin]` Cafe Royal<br>`[pin]` Guildford Arms |
| P16 | New York | 23 m | `[pin]` 351 Riverside Drive<br>`[pin]` The Schinasi Mansion |
| P17 | Boston | 24 m | `[pin]` Green Dragon Tavern<br>`[pin]` The Bell in Hand Tavern |
| P18 | New York | 24 m | `[pin]` 111 West 57th Street (Steinway Tower)<br>`[pin]` Steinway Hall |
| P19 | New York | 24 m | `[pin]` Banh by Lauren<br>`[pin]` Golden Diner |
| P20 | Edinburgh | 24 m | `[pin]` Biddy Mulligan's<br>`[pin]` The Last Drop |
| P21 | Edinburgh | 25 m | `[pin]` Halfway House<br>`[pin]` The Scotsman Hotel |
| P22 | New York | 16 m | `[pin]` All'Antico Vinaio on Sullivan Street *(in All'Antico Vinaio on Sullivan Street)*<br>`[pin]` All'Antico Vinaio on Sullivan Street *(in All'Antico Vinaio on Sullivan Street)*<br>`[pin]` Eve's Hangout |
| P23 | Los Angeles | 18 m | `[tour]` Downtown LA: Bunker Hill to the Pueblo *(in Walt Disney Concert Hall)*<br>`[pin]` The Blue Ribbon Garden<br>`[tour]` Walt Disney Concert Hall *(in Walt Disney Concert Hall)* |
| P24 | New York | 18 m | `[pin]` Dead Rabbit<br>`[tour]` Fraunces Tavern *(in Fraunces Tavern)*<br>`[pin]` Fraunces Tavern *(in Fraunces Tavern)* |
| P25 | Queens | 19 m | `[pin]` Relics of the World's Fairs<br>`[tour]` The Unisphere *(in The Unisphere)*<br>`[pin]` The Unisphere *(in The Unisphere)* |
| P26 | New York | 24 m | `[pin]` Saigon Social<br>`[pin]` Una Pizza Napoletana *(in Una Pizza Napoletana)*<br>`[pin]` Una Pizza Napoletana *(in Una Pizza Napoletana)* |

## § 3 — 32 same-subject pairs 25–500 m apart

Related by name but not coincident. **Never auto-create these** — picking the one coordinate
is an editorial decision, and some are deliberately two subjects.

| # | City | Apart | Pair |
|---|---|---|---|
| N1 | Lisbon | 26 m | `[pin]` MAAT<br>`[tour]` MAAT — Museum of Art, Architecture and Technology |
| N2 | London | 30 m | `[pin]` Halcyon Gallery, Harrods<br>`[tour]` Harrods |
| N3 | Ahmedabad | 53 m | `[pin]` Lilavati Lalbhai Library, CEPT University<br>`[pin]` CEPT University |
| N4 | Paris | 58 m | `[pin]` Toilettes de la Madeleine<br>`[tour]` La Madeleine |
| N5 | Atlanta | 62 m | `[tour]` Oakland Cemetery<br>`[pin]` Historic Oakland Cemetery |
| N6 | Porto | 75 m | `[pin]` São Bento Railway Station<br>`[tour]` São Bento Station |
| N7 | Paris | 87 m | `[tour]` Place des Vosges<br>`[pin]` Carette, Place des Vosges |
| N8 | New York | 88 m | `[pin]` The Stacks Under Bryant Park *(in New York Public Library, Stephen A. Schwarzman Building)*<br>`[tour]` Bryant Park |
| N9 | New York | 89 m | `[tour]` Little Island, Southwest Overlook<br>`[pin]` Little Island |
| N10 | Seoul | 89 m | `[tour]` Cheonggyecheon \| 청계천<br>`[pin]` Cheonggyecheon Stream |
| N11 | Seoul | 100 m | `[pin]` Mrs. Cho's Noodles, Gwangjang Market<br>`[tour]` Gwangjang Market \| 광장시장 |
| N12 | London | 131 m | `[pin]` The Painted Hall<br>`[pin]` The Painted Hall, Greenwich |
| N13 | Chicago | 142 m | `[tour]` The Wrigley Building & Tribune Tower<br>`[pin]` Tribune Tower *(in Tribune Tower)* |
| N14 | Chicago | 142 m | `[tour]` The Wrigley Building & Tribune Tower<br>`[pin]` Tribune Tower *(in Tribune Tower)* |
| N15 | New York | 147 m | `[pin]` Times Square *(in Times Square)*<br>`[tour]` Times Square — The View from the Red Steps |
| N16 | Beverly Hills | 160 m | `[pin]` Tory Burch, Rodeo Drive<br>`[tour]` Rodeo Drive |
| N17 | Paris | 167 m | `[tour]` Louvre *(in Louvre)*<br>`[pin]` Musée du Louvre |
| N18 | New York | 173 m | `[pin]` The Times Square Mosaic Map<br>`[pin]` Times Square *(in Times Square)* |
| N19 | Dundee | 236 m | `[pin]` The Old Bank Bar<br>`[pin]` The Bank Bar |
| N20 | London | 237 m | `[pin]` Did you know there’s a 1970s laundrette in The Barbican?…<br>`[pin]` The Barbican *(in Barbican Centre)* |
| N21 | London | 243 m | `[pin]` Did you know there’s a 1970s laundrette in The Barbican?…<br>`[tour]` The Barbican *(in The Barbican)* |
| N22 | San Francisco | 257 m | `[tour]` Chinatown: The City That Refused to Move<br>`[pin]` Chinatown |
| N23 | Paris | 283 m | `[pin]` Petit Palais *(in Petit Palais)*<br>`[tour]` Pont Alexandre III & Petit Palais |
| N24 | Paris | 283 m | `[pin]` Petit Palais *(in Petit Palais)*<br>`[tour]` Pont Alexandre III & Petit Palais |
| N25 | Hong Kong | 289 m | `[pin]` Kowloon Park Stone Columns \| 九龍公園百年石柱<br>`[pin]` Kowloon Park |
| N26 | Stockholm | 301 m | `[tour]` Gamla stan 1859<br>`[tour]` Gamla stan *(in Gamla stan)* |
| N27 | London | 352 m | `[pin]` Choosing Keeping in Covent Garden<br>`[tour]` Covent Garden *(in Covent Garden)* |
| N28 | Brooklyn | 364 m | `[pin]` The Cyclone at Coney Island<br>`[tour]` Coney Island |
| N29 | New York | 368 m | `[pin]` Roy Lichtenstein's Times Square Mural<br>`[pin]` Times Square *(in Times Square)* |
| N30 | San Francisco | 395 m | `[tour]` Chinatown Dragon Gate<br>`[pin]` Chinatown |
| N31 | Kyoto | 418 m | `[pin]` Gion Kurashita, Hanamikoji, Gion, Kyoto<br>`[tour]` Gion \| 祇園 *(in Gion)* |
| N32 | Naoshima | 455 m | `[tour]` Benesse House Museum \| ベネッセハウス ミュージアム<br>`[tour]` Benesse House Museum Outdoor Works \| ベネッセハウスミュージアム屋外作品 |

## § 4 — declined, standing (35 groups + 1 named case)

🔴 **These are decided. The sweep still reports them because it cannot know a decision was
made — do not re-offer them as new candidates.**

| Held | The entry left out | Decided |
|---|---|---|
| *(no place)* | `[tour]` Gamla stan 1859<br>`[tour]` Kouthoofd Familie Winkel — one shopfront, two unrelated subjects | owner, 2026-09-11 |
| *(no place)* | `[pin]` Britain's Oldest Door<br>`[pin]` The Tomb of Elizabeth I — both are Westminster Abbey, already a place 17 m away — this would duplicate it | owner, 2026-09-11 |
| *(no place)* | `[tour]` Cafè de l'Arquitecte<br>`[tour]` Hotel Casa Sagnier — one building, but is the site the hotel or the building that holds both? | owner, 2026-09-11 |
| *(no place)* | `[tour]` El Retiro: The Garden Handed to Everyone<br>`[tour]` Puerta de Alcalá — two distinct monuments that only round together — BOTH coordinates are 4 dp (~11 m) | owner, 2026-09-11 |
| *(no place)* | `[tour]` Arc de Triomphe<br>`[pin]` The Tomb of the Unknown Soldier — owner: keep separate | owner, 2026-09-11 |
| *(no place)* | `[pin]` Handcrafter, D2 Place<br>`[pin]` Hoopla, D2 Place — two shops inside D2 Place; the site is the mall, which neither entry is named for | owner, 2026-09-11 |
| *(no place)* | `[pin]` Natural Spices Shop<br>`[pin]` New Patoy — dense block — two separate Hong Kong shops | owner, 2026-09-11 |
| *(no place)* | `[pin]` Little Bao<br>`[pin]` Primo Posto — dense block — two different Hong Kong restaurants | owner, 2026-09-11 |
| *(no place)* | `[pin]` The Fletcher-Sinclair House<br>`[pin]` The Venetian Room at Albertine — owner: keep separate — two adjacent mansions | owner, 2026-09-11 |
| *(no place)* | `[tour]` Bếp Mẹ Ỉn<br>`[tour]` STIR - Modern Classic Cocktail — dense block — two separate Ho Chi Minh City venues | owner, 2026-09-11 |
| *(no place)* | `[pin]` Haidilao Hot Pot, Carnarvon Road<br>`[pin]` Matsukiyo — dense block — a hotpot restaurant and a drugstore | owner, 2026-09-11 |
| *(no place)* | `[tour]` Fringe Club \| 藝穗會<br>`[pin]` Ho Lan Zheng — dense block — two separate Hong Kong venues | owner, 2026-09-11 |
| *(no place)* | `[tour]` ArkDes — Swedish Centre for Architecture and Design<br>`[tour]` Moderna Museet — owner: keep separate — they share a building on Skeppsholmen but are two institutions | owner, 2026-09-11 |
| *(no place)* | `[pin]` Lazy Suzy<br>`[pin]` Peng Leng Zheng — dense block — two separate Hong Kong venues | owner, 2026-09-11 |
| *(no place)* | `[tour]` Blue Bottle Studio Seoul \| 블루보틀 삼청 한옥<br>`[tour]` Kukje Gallery K3 \| 국제갤러리 K3 — dense block — a coffee studio and a gallery | owner, 2026-09-11 |
| *(no place)* | `[tour]` Diego Iluminado<br>`[tour]` Fundación Proa — owner: keep separate | owner, 2026-09-11 |
| *(no place)* | `[tour]` Bar Montan<br>`[tour]` Hosoi — dense block — two separate Stockholm bars | owner, 2026-09-11 |
| *(no place)* | `[tour]` Baan Plern Jitt \| บ้านเพลินจิตต์ ณ คลองบางหลวง<br>`[tour]` Khlong Bang Luang Floating Market \| ตลาดชุมชนคลองบางหลวง — owner: keep separate | owner, 2026-09-11 |
| *(no place)* | `[pin]` Social Goods<br>`[tour]` Stone Slab Street \| 石板街 — dense block — a shop on the street it stands in | owner, 2026-09-11 |
| *(no place)* | `[tour]` Palacio Barolo<br>`[tour]` Salón 1923 — owner: keep separate | owner, 2026-09-11 |
| *(no place)* | `[pin]` Heartwarming<br>`[pin]` Yu Chau Street — dense block — a shop on the street it stands in | owner, 2026-09-11 |
| *(no place)* | `[tour]` The Loop — Where the Skyscraper Was Born<br>`[tour]` The Rookery — owner: keep separate — a building and a walk that passes it | owner, 2026-09-11 |
| *(no place)* | `[tour]` Pellegrino 2000<br>`[tour]` The Rover — dense block — two separate Sydney venues | owner, 2026-09-11 |
| *(no place)* | `[pin]` Dieci<br>`[tour]` Kau Kee \| 九記牛腩<br>`[pin]` O'rm — owner: all separate — dense block, a noodle shop and two neighbours | owner, 2026-09-11 |
| Duddell Street Steps and Gas Lamps | `[pin]` Il Presidente | owner, 2026-09-11 |
| Westminster Abbey | `[pin]` The Cosmati Pavement<br>`[pin]` The Shrine of Edward the Confessor | owner, 2026-09-11 |
| Rockefeller Center | `[pin]` The Channel Gardens | owner, 2026-09-11 |
| **Tai Kwun** | `[pin]` Madame Fu — a restaurant *inside* a heritage compound is not the compound. It sits 27.4 m out, just past the TIGHT radius, so the sweep does not report it | owner, 2026-09-11 |
| *(no place)* | `[tour]` Tibidabo<br>`[tour]` Tibidabo Amusement Park — a mountain and a funfair are two subjects (#541) (48 m apart) | owner |
| *(no place)* | `[tour]` Fondazione Prada<br>`[pin]` Bar Luce at Fondazione Prada — owner: a restaurant inside a heritage compound is not the compound (Rule 4) (49 m apart) | owner |
| *(no place)* | `[tour]` Victoria Peak \| 太平山頂<br>`[pin]` Bakehouse at Victoria Peak — owner: a tenant is not the site (Rule 4) (129 m apart) | owner |
| *(no place)* | `[pin]` Big Ben<br>`[tour]` Houses of Parliament and Big Ben *(in Houses of Parliament)* — owner: declined as part-vs-whole (135 m apart) | owner |
| *(no place)* | `[pin]` The Red Room at One Wall Street<br>`[tour]` Wall Street *(in Wall Street)* — owner: keep the Red Room separate — One Wall Street is a different building (135 m apart) | owner |
| *(no place)* | `[pin]` The Red Room at One Wall Street<br>`[pin]` The Wall of Wall Street *(in Wall Street)* — owner: keep the Red Room separate — One Wall Street is a different building (135 m apart) | owner |
| *(no place)* | `[pin]` 111 West 57th Street (Steinway Tower)<br>`[pin]` Steinway Tower — owner 2026-09-22: keep separate AT LEAST FOR NOW — provisional, not a final ruling. Same building under two names, 145 m apart; revisit if the owner reopens it (145 m apart) | owner |
| *(no place)* | `[tour]` LACMA<br>`[pin]` LACMA's David Geffen Galleries — owner: all different — the pins were repaired instead (182 m apart) | owner |


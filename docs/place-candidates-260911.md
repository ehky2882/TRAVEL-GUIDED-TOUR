# Place candidates — the live menu

**Regenerated 2026-09-11 09:25 UTC against `main` at `7487176`.** Every number here is a reading of
`Tours.json` and goes stale the moment a pin batch merges. Regenerate it — do not patch it:

```bash
python3 scripts/make-place-menu.py
```

## Where this stands

A `Place` is a site that more than one entry describes: the site becomes the thing on the map
and the entries become its contents. The catalogue holds
**181 places covering 459 entries**.

The 2026-09-11 sweep found 221 candidates and **45 became places** — 7 existing places gained
the 8 entries standing on them, 38 new places came from the 0 m rows, and both held groups
were resolved ([#801](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/801)). That took the sweep from **41 exact / 151 tight / 79 near**
to nearly nothing.

**Then `main` moved** — #804 and #805 changed pins and a new coincident group appeared. That is
the normal condition. What follows is what is open **right now**.

| | Finding | Act on it? |
|---|---|---|
| **§ 1** | **1 on an identical coordinate** — the catalogue's own identity rule | Yes, highest confidence |
| **§ 2** | **96 sites** with 2+ entries within 25 m | Owner picks |
| **§ 3** | 79 same-subject pairs 25–500 m apart | Read one at a time |
| **§ 4** | 3 groups **already declined** | Do not re-offer |

## 🔴 What creating one costs — it is never just a list entry

A place needs its own **name, description, address and a chosen coordinate**. And because a
place's identity is **exact coordinate equality** (`Place.swift`, enforced by `validate-tours`
at 1e-9°), every member is **snapped onto that coordinate** — all 459 existing members sit
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

## § 1 — on an identical coordinate (1)

The catalogue's documented identity rule: provably one site, no editorial judgement.

| # | City | Entries |
|---|---|---|
| **Z1** | Chicago | `[pin]` The Art Institute of Chicago<br>`[pin]` The Trading Room of the Chicago Stock Exchange |

## § 2 — 96 sites with two or more entries within 25 m

Built only from hops of 25 m or less; the widest group is **30 m** end to end, so
none is a chain of separate sites strung together.

| # | City | Span | Entries |
|---|---|---|---|
| P1 | Wonju | 0 m | `[tour]` Museum SAN \| 뮤지엄 산<br>`[pin]` The Space of Light (Museum SAN) |
| P2 | New York | 0 m | `[pin]` $500 Billion of Gold Under 33 Liberty Street<br>`[pin]` The Federal Reserve Bank of New York |
| P3 | New York | 0 m | `[pin]` Hotel New Yorker: Nikola Tesla's Last Home<br>`[pin]` The Nikola Tesla Museum |
| P4 | New York | 0 m | `[pin]` Inside the Municipal Building<br>`[pin]` The Manhattan Municipal Building |
| P5 | Philadelphia | 0 m | `[pin]` Calder Gardens<br>`[pin]` Inside the New Calder Gardens |
| P6 | San Francisco | 0 m | `[pin]` One Maritime Plaza<br>`[pin]` One Maritime Plaza |
| P7 | San Francisco | 0 m | `[pin]` Portsmouth Square<br>`[pin]` Portsmouth Square Pedestrian Bridge |
| P8 | San Rafael | 0 m | `[pin]` Marin County Civic Center<br>`[pin]` Marin County Civic Center |
| P9 | Brooklyn | 0 m | `[pin]` The New York Transit Museum<br>`[pin]` The New York Transit Museum |
| P10 | Queens | 0 m | `[pin]` Queens County Farm<br>`[pin]` Queens County Farm Museum |
| P11 | San Francisco | 0 m | `[pin]` Cathedral of Saint Mary of the Assumption<br>`[pin]` Saint Mary's Cathedral |
| P12 | Oslo | 0 m | `[pin]` Deichman Bjørvika<br>`[pin]` Deichman Bjørvika<br>`[pin]` Inside Deichman Bjørvika |
| P13 | New York | 0 m | `[pin]` The Noguchi Museum<br>`[pin]` The Noguchi Museum |
| P14 | Toronto | 0 m | `[pin]` R.C. Harris Water Treatment Plant<br>`[pin]` R.C. Harris Water Treatment Plant |
| P15 | Toronto | 0 m | `[pin]` CIBC Square<br>`[pin]` The Rooftop Park at CIBC Square |
| P16 | Vatican City | 1 m | `[pin]` Is this a Renaissance diss track?! The Last Judgement by…<br>`[pin]` The Sistine Chapel |
| P17 | Los Angeles | 1 m | `[pin]` Hollyhock House<br>`[pin]` Hollyhock House |
| P18 | New York | 2 m | `[pin]` Sugar House Prison Window<br>`[pin]` The Sugar House Prison Window |
| P19 | Rome | 3 m | `[pin]` Bernini and Borromini in Piazza Navona<br>`[tour]` Piazza Navona |
| P20 | London | 4 m | `[tour]` St Paul's Cathedral<br>`[pin]` St Paul's Cathedral After the Great Fire |
| P21 | Stockholm | 4 m | `[tour]` Gamla stan 1859<br>`[tour]` Kouthoofd Familie Winkel |
| P22 | Sant Just Desvern | 4 m | `[pin]` Living in Walden 7<br>`[tour]` Walden 7 |
| P23 | Rome | 4 m | `[tour]` The Trevi Fountain<br>`[pin]` The Trevi Fountain |
| P24 | New York | 4 m | `[pin]` Hook & Ladder 8<br>`[pin]` The Ghostbusters Firehouse |
| P25 | Brooklyn | 4 m | `[pin]` Mount Prospect Park, Brooklyn<br>`[pin]` Mount Prospect and the Battle of Brooklyn |
| P26 | London | 5 m | `[pin]` Britain's Oldest Door<br>`[pin]` The Tomb of Elizabeth I |
| P27 | Chicago | 6 m | `[pin]` River City<br>`[pin]` River City |
| P28 | San Simeon | 6 m | `[pin]` Hearst Castle<br>`[pin]` Julia Morgan at Hearst Castle |
| P29 | Roquebrune-Cap-Martin | 6 m | `[pin]` Eileen Gray's Villa E-1027<br>`[pin]` Villa E-1027 |
| P30 | Paris | 7 m | `[pin]` Centre Pompidou<br>`[tour]` Centre Pompidou |
| P31 | London | 7 m | `[pin]` Leadenhall Market<br>`[tour]` Leadenhall Market |
| P32 | New York | 7 m | `[tour]` New Museum<br>`[pin]` The New Museum Expansion |
| P33 | Paris | 7 m | `[tour]` Eiffel Tower<br>`[pin]` The Eiffel Tower<br>`[pin]` The Eiffel Tower in the First World War |
| P34 | Kyoto | 7 m | `[pin]` Ando's Garden of Fine Art<br>`[tour]` Garden of Fine Arts Kyoto \| 京都府立陶板名画の庭 |
| P35 | Vence | 7 m | `[pin]` Matisse Chapel (Chapelle du Rosaire de Vence)<br>`[pin]` Matisse's Chapelle du Rosaire |
| P36 | Paris | 7 m | `[pin]` Gae Aulenti at the Musée d'Orsay<br>`[tour]` Musée d'Orsay |
| P37 | Barcelona | 8 m | `[tour]` Cafè de l'Arquitecte<br>`[tour]` Hotel Casa Sagnier |
| P38 | Chicago | 8 m | `[tour]` Cloud Gate (The Bean)<br>`[pin]` The Bean: Chicago's Million-Dollar Public Art<br>`[pin]` Under Cloud Gate |
| P39 | Chicago | 8 m | `[pin]` Chicago Water Tower<br>`[tour]` The Historic Water Tower |
| P40 | Madrid | 8 m | `[tour]` El Retiro: The Garden Handed to Everyone<br>`[tour]` Puerta de Alcalá |
| P41 | New York | 8 m | `[tour]` Chelsea Market<br>`[pin]` 👀 Oreos were first made in NYC! #nychistory #nyclife |
| P42 | Berlin | 9 m | `[tour]` The Reichstag<br>`[pin]` The Reichstag Dome |
| P43 | Hong Kong | 9 m | `[pin]` Handcrafter, D2 Place<br>`[pin]` Hoopla, D2 Place |
| P44 | New York | 9 m | `[pin]` Manhattan's Most Haunted House<br>`[pin]` The Merchant's House and the Underground Railroad |
| P45 | Humlebæk | 10 m | `[pin]` How Louisiana Became International<br>`[tour]` Louisiana Museum of Modern Art |
| P46 | Hong Kong | 10 m | `[pin]` Natural Spices Shop<br>`[pin]` New Patoy |
| P47 | Paris | 10 m | `[tour]` Arc de Triomphe<br>`[pin]` The Tomb of the Unknown Soldier |
| P48 | Florence | 10 m | `[pin]` All'Antico Vinaio<br>`[pin]` All'Antico Vinaio |
| P49 | New York | 11 m | `[tour]` Whitney Museum of American Art<br>`[pin]` Whitney Museum of American Art |
| P50 | New York | 12 m | `[pin]` Church of St Vincent de Paul<br>`[pin]` St. Vincent de Paul Church |
| P51 | Mechernich | 12 m | `[pin]` Bruder Klaus Field Chapel<br>`[pin]` Burning the Bruder Klaus Chapel |
| P52 | Queens | 12 m | `[tour]` Citi Field<br>`[pin]` How the Mets Got Their Name |
| P53 | Hong Kong | 14 m | `[pin]` Little Bao<br>`[pin]` Primo Posto |
| P54 | Madrid | 14 m | `[tour]` Palacio Real<br>`[tour]` Royal Madrid: The Ring of Green |
| P55 | Taipei | 14 m | `[pin]` NTU College of Social Sciences Library<br>`[pin]` NTU Social Sciences Library |
| P56 | New York | 14 m | `[pin]` Central Park<br>`[pin]` Central Park: How It Was Designed |
| P57 | Kyoto | 15 m | `[tour]` Face House \| フェイスハウス<br>`[pin]` The Face House of Kyoto |
| P58 | Tokyo | 15 m | `[pin]` The Glass Wave of the National Art Center<br>`[tour]` The National Art Center, Tokyo \| 国立新美術館 |
| P59 | New York | 15 m | `[tour]` Federal Hall<br>`[pin]` The Rotunda at Federal Hall |
| P60 | New York | 16 m | `[pin]` The Catacombs of Old St. Patrick's<br>`[pin]` The Godfather Baptism Church |
| P61 | Amsterdam | 16 m | `[tour]` Muntplein & the Munttoren<br>`[pin]` Munttoren |
| P62 | Chicago | 17 m | `[tour]` Marina City<br>`[tour]` Merchandise Mart |
| P63 | Barcelona | 17 m | `[tour]` Casa Amatller<br>`[tour]` Casa Batlló |
| P64 | San Juan | 17 m | `[pin]` Castillo San Felipe del Morro<br>`[pin]` The Sentry Box of Old San Juan |
| P65 | New York | 17 m | `[pin]` The Fletcher-Sinclair House<br>`[pin]` The Venetian Room at Albertine |
| P66 | Ho Chi Minh City | 17 m | `[tour]` Bếp Mẹ Ỉn<br>`[tour]` STIR - Modern Classic Cocktail |
| P67 | New York | 17 m | `[pin]` Conwell Coffee Hall<br>`[pin]` Inside Conwell Coffee Hall |
| P68 | Hong Kong | 17 m | `[pin]` Haidilao Hot Pot, Carnarvon Road<br>`[pin]` Matsukiyo |
| P69 | Hong Kong | 18 m | `[tour]` Fringe Club \| 藝穗會<br>`[pin]` Ho Lan Zheng |
| P70 | Saint-Paul-de-Vence | 18 m | `[pin]` La Colombe d'Or<br>`[pin]` La Colombe d'Or<br>`[pin]` The Art on the Walls at La Colombe d'Or |
| P71 | New York | 18 m | `[tour]` Apollo Theater<br>`[pin]` Inside the Apollo Theater |
| P72 | Stockholm | 18 m | `[tour]` ArkDes — Swedish Centre for Architecture and Design<br>`[tour]` Moderna Museet |
| P73 | New York | 20 m | `[tour]` Flatiron Building<br>`[pin]` Why the Flatiron Building Is Empty |
| P74 | Hong Kong | 20 m | `[pin]` Lazy Suzy<br>`[pin]` Peng Leng Zheng |
| P75 | New York | 20 m | `[pin]` The 1920 Wall Street Bombing<br>`[tour]` Wall Street |
| P76 | Berlin | 21 m | `[tour]` East Side Gallery<br>`[pin]` Two Sides of the Berlin Wall |
| P77 | New York | 21 m | `[pin]` The Dark Secret of Wall Street<br>`[pin]` The Red Room at One Wall Street |
| P78 | Saint-Paul-de-Vence | 21 m | `[pin]` Fondation Maeght<br>`[pin]` Fondation Maeght<br>`[pin]` How Fondation Maeght Was Built |
| P79 | New York | 22 m | `[tour]` Stonewall Inn<br>`[pin]` The Stonewall Inn |
| P80 | Seoul | 22 m | `[tour]` Blue Bottle Studio Seoul \| 블루보틀 삼청 한옥<br>`[tour]` Kukje Gallery K3 \| 국제갤러리 K3 |
| P81 | New York | 22 m | `[pin]` The Real Winnie-the-Pooh<br>`[pin]` The Wertheim Study at the New York Public Library |
| P82 | Buenos Aires | 22 m | `[tour]` Diego Iluminado<br>`[tour]` Fundación Proa |
| P83 | New York | 22 m | `[tour]` Bethesda Terrace<br>`[pin]` Bethesda Terrace: The Tiled Ceiling in Central Park |
| P84 | Stockholm | 22 m | `[tour]` Bar Montan<br>`[tour]` Hosoi |
| P85 | Bangkok | 22 m | `[tour]` Baan Plern Jitt \| บ้านเพลินจิตต์ ณ คลองบางหลวง<br>`[tour]` Khlong Bang Luang Floating Market \| ตลาดชุมชนคลองบางหลวง |
| P86 | Barcelona | 23 m | `[tour]` Sant Pau Recinte Modernista<br>`[pin]` The Forty-Eight Pavilions of Sant Pau |
| P87 | Hong Kong | 23 m | `[pin]` Social Goods<br>`[tour]` Stone Slab Street \| 石板街 |
| P88 | Buenos Aires | 23 m | `[tour]` Palacio Barolo<br>`[tour]` Salón 1923 |
| P89 | Hong Kong | 23 m | `[pin]` Heartwarming<br>`[pin]` Yu Chau Street |
| P90 | Chicago | 24 m | `[tour]` The Loop — Where the Skyscraper Was Born<br>`[tour]` The Rookery |
| P91 | Sydney | 24 m | `[tour]` Pellegrino 2000<br>`[tour]` The Rover |
| P92 | Uji | 25 m | `[pin]` The Keihan Uji Station<br>`[tour]` Uji Station \| 宇治駅 |
| P93 | New York | 25 m | `[pin]` 31 Canal Street<br>`[pin]` Loew's Canal Theater |
| P94 | Queens | 25 m | `[pin]` The Hell Gate Bridge<br>`[pin]` The Hell Gate Sabotage Plot<br>`[pin]` Why the Hell Gate Bridge Was Built |
| P95 | Los Angeles | 26 m | `[tour]` Academy Museum of Motion Pictures<br>`[pin]` Jeff Koons' Split-Rocker Edition<br>`[tour]` LACMA |
| P96 | Hong Kong | 30 m | `[pin]` Dieci<br>`[tour]` Kau Kee \| 九記牛腩<br>`[pin]` O'rm |

## § 3 — 79 same-subject pairs 25–500 m apart

Related by name but not coincident. **Never auto-create these** — picking the one coordinate
is an editorial decision, and some are deliberately two subjects.

| # | City | Apart | Pair |
|---|---|---|---|
| N1 | Hong Kong | 26 m | `[pin]` Man Mo Temple<br>`[tour]` Man Mo Temple \| 文武廟 |
| N2 | Hong Kong | 26 m | `[tour]` The Henderson \| 美利道2號<br>`[pin]` The Henderson |
| N3 | New York | 28 m | `[pin]` The Breuer Building<br>`[tour]` The Breuer Building |
| N4 | Tokyo | 29 m | `[tour]` Tokyo International Forum \| 東京国際フォーラム<br>`[pin]` The Glass Hall at Tokyo International Forum |
| N5 | Tokyo | 29 m | `[tour]` Prada Aoyama \| プラダ 青山店<br>`[pin]` Prada Aoyama Epicenter |
| N6 | Paris | 29 m | `[pin]` Sainte-Chapelle<br>`[tour]` Sainte-Chapelle |
| N7 | New York | 31 m | `[pin]` The Ansonia: Should We Build Like This Again?<br>`[tour]` The Ansonia |
| N8 | Bronx | 31 m | `[tour]` Yankee Stadium *(in Yankee Stadium)*<br>`[pin]` Yankee Stadium and a Baseball Anthem |
| N9 | Bronx | 31 m | `[pin]` Yankee Stadium *(in Yankee Stadium)*<br>`[pin]` Yankee Stadium and a Baseball Anthem |
| N10 | Hong Kong | 31 m | `[tour]` Upper Lascar Row Antique Street Market \| 摩羅上街古董露天市集<br>`[pin]` Upper Lascar Row |
| N11 | New York | 32 m | `[tour]` Washington Square Park *(in Washington Square Park)*<br>`[pin]` The 20,000 Skeletons Under Washington Square Park |
| N12 | New York | 34 m | `[pin]` The Port Authority Bus Terminal<br>`[pin]` Port Authority Bus Terminal |
| N13 | Copenhagen | 35 m | `[tour]` Frederik's Church - Marmorkirken (The Marble Church)<br>`[pin]` Frederik's Church (Marmorkirken) |
| N14 | London | 36 m | `[pin]` Abbey Road: The Conspiracy Theories<br>`[tour]` Abbey Road |
| N15 | New York | 39 m | `[pin]` Villa Charlotte Bronte<br>`[pin]` Villa Charlotte Bronte: English Villas in the Bronx |
| N16 | New York | 40 m | `[pin]` The Wall of Wall Street<br>`[pin]` The 1920 Wall Street Bombing |
| N17 | London | 40 m | `[tour]` Battersea Power Station<br>`[pin]` Battersea Power Station, Rebuilt |
| N18 | Toronto | 47 m | `[pin]` The Toronto Reference Library *(in Toronto Reference Library)*<br>`[pin]` Toronto Reference Library |
| N19 | Toronto | 47 m | `[pin]` Toronto Reference Library<br>`[pin]` Inside the Toronto Reference Library *(in Toronto Reference Library)* |
| N20 | Chicago | 47 m | `[pin]` Building Marina City<br>`[pin]` Marina City |
| N21 | Barcelona | 48 m | `[tour]` Tibidabo<br>`[tour]` Tibidabo Amusement Park |
| N22 | New York | 49 m | `[pin]` The Ford Foundation Building<br>`[tour]` Ford Foundation Building |
| N23 | Milan | 49 m | `[tour]` Fondazione Prada<br>`[pin]` Bar Luce at Fondazione Prada |
| N24 | Paris | 51 m | `[pin]` Place des Abbesses<br>`[tour]` Place des Abbesses & the Wall of Love |
| N25 | Chicago | 51 m | `[pin]` Obama Presidential Center<br>`[pin]` Obama Presidential Center |
| N26 | Toronto | 53 m | `[tour]` Graffiti Alley<br>`[pin]` Walking Graffiti Alley |
| N27 | New York | 54 m | `[pin]` The Wall of Wall Street<br>`[tour]` Wall Street |
| N28 | Chicago | 56 m | `[pin]` The Art Institute of Chicago<br>`[tour]` The Art Institute |
| N29 | New York | 58 m | `[tour]` The Oculus<br>`[pin]` The Oculus |
| N30 | New York | 62 m | `[pin]` The Apthorp<br>`[pin]` The Apthorp |
| N31 | New York | 65 m | `[pin]` The Times Square Mosaic Map<br>`[pin]` Times Square |
| N32 | New York | 68 m | `[pin]` Behind Trinity Church: New York's Old Red Light District<br>`[tour]` Trinity Church *(in Trinity Church)* |
| N33 | Atsugi | 79 m | `[pin]` KAIT Plaza and Workshop<br>`[pin]` KAIT Plaza *(in KAIT Plaza and Workshop)* |
| N34 | Atsugi | 79 m | `[pin]` KAIT Workshop and Plaza *(in KAIT Plaza and Workshop)*<br>`[pin]` KAIT Plaza and Workshop |
| N35 | Chicago | 85 m | `[tour]` The Monadnock Building<br>`[pin]` Monadnock Building |
| N36 | New York | 88 m | `[tour]` Wall Street<br>`[pin]` The Dark Secret of Wall Street |
| N37 | New York | 89 m | `[tour]` Little Island, Southwest Overlook<br>`[pin]` Little Island |
| N38 | Barcelona | 90 m | `[pin]` Why Millions Visit La Sagrada Família<br>`[tour]` Sagrada Família |
| N39 | London | 99 m | `[tour]` Covent Garden<br>`[pin]` Covent Garden: London's First Public Square |
| N40 | New York | 100 m | `[pin]` One Times Square *(in One Times Square)*<br>`[pin]` Times Square |
| N41 | Stockholm | 105 m | `[pin]` Vasa Museum<br>`[tour]` Vasa Museum |
| N42 | New York | 108 m | `[pin]` The Red Room at One Wall Street<br>`[tour]` Wall Street |
| N43 | Milan | 109 m | `[tour]` Bosco Verticale<br>`[pin]` Bosco Verticale |
| N44 | New York | 109 m | `[pin]` The Times Square Confetti Blizzard *(in Times Square)*<br>`[pin]` Times Square |
| N45 | New York | 109 m | `[pin]` The Hidden Hum of Times Square *(in Times Square)*<br>`[pin]` Times Square |
| N46 | New York | 127 m | `[tour]` Neue Galerie<br>`[pin]` The House Behind the Neue Galerie |
| N47 | Hong Kong | 129 m | `[tour]` Victoria Peak \| 太平山頂<br>`[pin]` Bakehouse at Victoria Peak |
| N48 | Kyoto | 130 m | `[tour]` Gion \| 祇園<br>`[pin]` Gion Ishi Sakashita Building |
| N49 | Queens | 135 m | `[pin]` Inside the Museum of the Moving Image *(in Museum of the Moving Image)*<br>`[tour]` Museum of the Moving Image |
| N50 | Queens | 135 m | `[pin]` Museum of the Moving Image, Astoria *(in Museum of the Moving Image)*<br>`[tour]` Museum of the Moving Image |
| N51 | London | 135 m | `[pin]` Big Ben<br>`[tour]` Houses of Parliament and Big Ben *(in Houses of Parliament)* |
| N52 | Amsterdam | 136 m | `[tour]` The Jordaan *(in Westerkerk)*<br>`[tour]` The Jordaan |
| N53 | New York | 142 m | `[pin]` The Wall of Wall Street<br>`[pin]` The Dark Secret of Wall Street |
| N54 | Chicago | 142 m | `[tour]` The Wrigley Building & Tribune Tower<br>`[pin]` Tribune Tower *(in Tribune Tower)* |
| N55 | Chicago | 142 m | `[tour]` The Wrigley Building & Tribune Tower<br>`[pin]` Tribune Tower *(in Tribune Tower)* |
| N56 | Bentonville | 152 m | `[pin]` Crystal Bridges Museum of American Art<br>`[pin]` Crystal Bridges Museum of American Art |
| N57 | Athens | 158 m | `[pin]` The Ancient Agora of Athens<br>`[pin]` The Agora of Athens |
| N58 | London | 161 m | `[tour]` Dennis Severs' House<br>`[pin]` Dennis Severs' House |
| N59 | New York | 162 m | `[pin]` The Red Room at One Wall Street<br>`[pin]` The Wall of Wall Street |
| N60 | Stockholm | 194 m | `[pin]` Stortorget, Gamla Stan<br>`[tour]` Gamla stan |
| N61 | Los Angeles | 212 m | `[tour]` LACMA<br>`[pin]` LACMA's David Geffen Galleries |
| N62 | Chicago | 214 m | `[tour]` Obama Presidential Center<br>`[pin]` Obama Presidential Center |
| N63 | New York | 256 m | `[pin]` Times Square<br>`[tour]` Times Square — The View from the Red Steps |
| N64 | San Francisco | 257 m | `[tour]` Chinatown: The City That Refused to Move<br>`[pin]` Chinatown |
| N65 | New York | 260 m | `[pin]` Roy Lichtenstein's Times Square Mural<br>`[pin]` Times Square |
| N66 | Chicago | 264 m | `[tour]` Obama Presidential Center<br>`[pin]` Obama Presidential Center |
| N67 | Paris | 276 m | `[pin]` Petit Palais<br>`[tour]` Pont Alexandre III & Petit Palais |
| N68 | Hong Kong | 289 m | `[pin]` Kowloon Park Stone Columns \| 九龍公園百年石柱<br>`[pin]` Kowloon Park |
| N69 | Stockholm | 301 m | `[tour]` Gamla stan 1859<br>`[tour]` Gamla stan |
| N70 | Pasadena | 343 m | `[pin]` The Gamble House<br>`[tour]` Gamble House |
| N71 | Brooklyn | 364 m | `[pin]` The Cyclone at Coney Island<br>`[tour]` Coney Island |
| N72 | San Francisco | 395 m | `[tour]` Chinatown Dragon Gate<br>`[pin]` Chinatown |
| N73 | New York | 424 m | `[pin]` Governors Island<br>`[tour]` Governors Island |
| N74 | Brooklyn | 428 m | `[tour]` Domino Park<br>`[pin]` Domino Park |
| N75 | Chicago | 445 m | `[tour]` Marina City<br>`[pin]` Building Marina City |
| N76 | Naoshima | 455 m | `[tour]` Benesse House Museum \| ベネッセハウス ミュージアム<br>`[tour]` Benesse House Museum Outdoor Works \| ベネッセハウスミュージアム屋外作品 |
| N77 | Chicago | 486 m | `[tour]` Marina City<br>`[pin]` Marina City |
| N78 | New York | 497 m | `[pin]` The Noguchi Museum<br>`[tour]` The Noguchi Museum |
| N79 | New York | 497 m | `[pin]` The Noguchi Museum<br>`[tour]` The Noguchi Museum |

## § 4 — declined, standing (3 groups + 2 named cases)

🔴 **These are decided. The sweep still reports them because it cannot know a decision was
made — do not re-offer them as new candidates.**

| Held | The entry left out | Decided |
|---|---|---|
| Duddell Street Steps and Gas Lamps | `[pin]` Il Presidente | owner, 2026-09-11 |
| Westminster Abbey | `[pin]` The Cosmati Pavement<br>`[pin]` The Shrine of Edward the Confessor | owner, 2026-09-11 |
| Rockefeller Center | `[pin]` The Channel Gardens | owner, 2026-09-11 |
| **Tai Kwun** | `[pin]` Madame Fu — a restaurant *inside* a heritage compound is not the compound. It sits 27.4 m out, just past the TIGHT radius, so the sweep does not report it | owner, 2026-09-11 |
| **Tibidabo** / **Tibidabo Amusement Park** | 48 m apart — a mountain and a funfair are two subjects | #541 |

